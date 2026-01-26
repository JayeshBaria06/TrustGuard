import 'dart:io';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:drift/native.dart';
import 'package:path/path.dart' as p;
import 'package:image/image.dart' as img;
import 'package:trustguard/src/core/models/group.dart' as model;
import 'package:trustguard/src/core/models/member.dart' as model;
import 'package:trustguard/src/core/models/transaction.dart' as model;
import 'package:trustguard/src/core/models/expense.dart' as model;
import 'package:trustguard/src/core/database/database.dart';
import 'package:trustguard/src/core/database/repositories/attachment_repository.dart';
import 'package:trustguard/src/core/database/repositories/group_repository.dart';
import 'package:trustguard/src/core/database/repositories/member_repository.dart';
import 'package:trustguard/src/core/database/repositories/transaction_repository.dart';
import 'package:trustguard/src/features/transactions/services/attachment_service.dart';
import 'package:uuid/uuid.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  late Directory tempDir;
  late AttachmentService attachmentService;
  late AttachmentRepository attachmentRepository;
  late GroupRepository groupRepository;
  late MemberRepository memberRepository;
  late TransactionRepository transactionRepository;
  late AppDatabase db;

  setUp(() async {
    tempDir = await Directory.systemTemp.createTemp('attachment_test');

    // Mock path_provider
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(
          const MethodChannel('plugins.flutter.io/path_provider'),
          (MethodCall methodCall) async {
            if (methodCall.method == 'getApplicationDocumentsDirectory') {
              return tempDir.path;
            }
            return null;
          },
        );

    attachmentService = AttachmentService();
    db = AppDatabase(NativeDatabase.memory());
    attachmentRepository = DriftAttachmentRepository(db);
    groupRepository = DriftGroupRepository(db);
    memberRepository = DriftMemberRepository(db);
    transactionRepository = DriftTransactionRepository(db, attachmentService);
  });

  tearDown(() async {
    await db.close();
    if (await tempDir.exists()) {
      await tempDir.delete(recursive: true);
    }
  });

  Future<File> createMockImage({int width = 100, int height = 100}) async {
    final image = img.Image(width: width, height: height);
    // Fill with some color
    img.fill(image, color: img.ColorRgb8(255, 0, 0));
    final bytes = img.encodeJpg(image);
    final file = File(p.join(tempDir.path, 'mock_image.jpg'));
    await file.writeAsBytes(bytes);
    return file;
  }

  Future<String> setupTransaction() async {
    final groupId = const Uuid().v4();
    final group = model.Group(
      id: groupId,
      name: 'Test Group',
      currencyCode: 'USD',
      createdAt: DateTime.now(),
    );
    await groupRepository.createGroup(group);

    final memberId = const Uuid().v4();
    final member = model.Member(
      id: memberId,
      groupId: groupId,
      displayName: 'Test Member',
      createdAt: DateTime.now(),
    );
    await memberRepository.createMember(member);

    final txId = const Uuid().v4();
    final transaction = model.Transaction(
      id: txId,
      groupId: groupId,
      note: 'Test Expense',
      type: model.TransactionType.expense,
      occurredAt: DateTime.now(),
      createdAt: DateTime.now(),
      updatedAt: DateTime.now(),
      expenseDetail: model.ExpenseDetail(
        payerMemberId: memberId,
        totalAmountMinor: 1000,
        splitType: model.SplitType.equal,
        participants: [
          model.ExpenseParticipant(memberId: memberId, owedAmountMinor: 1000),
        ],
      ),
    );
    await transactionRepository.createTransaction(transaction);
    return txId;
  }

  group('Attachment Functionality', () {
    test('saveAttachment creates file in correct directory', () async {
      final mockImage = await createMockImage();
      const txId = 'tx123';

      final savedPath = await attachmentService.saveAttachment(txId, mockImage);

      expect(File(savedPath).existsSync(), isTrue);
      expect(savedPath, contains(p.join('attachments', txId)));
    });

    test('getAttachments returns saved files', () async {
      final mockImage = await createMockImage();
      const txId = 'tx123';

      await attachmentService.saveAttachment(txId, mockImage);
      await attachmentService.saveAttachment(txId, mockImage);

      final attachments = await attachmentService.getAttachments(txId);
      expect(attachments, hasLength(2));
    });

    test('deleteAttachment removes file', () async {
      final mockImage = await createMockImage();
      const txId = 'tx123';

      final savedPath = await attachmentService.saveAttachment(txId, mockImage);
      expect(File(savedPath).existsSync(), isTrue);

      await attachmentService.deleteAttachment(savedPath);
      expect(File(savedPath).existsSync(), isFalse);
    });

    test('image compression reduces file size for large images', () async {
      // Create a "large" mock image
      final mockImage = await createMockImage(width: 2000, height: 2000);
      final originalSize = await mockImage.length();
      const txId = 'tx_large';

      final savedPath = await attachmentService.saveAttachment(txId, mockImage);
      final savedFile = File(savedPath);
      final savedSize = await savedFile.length();

      expect(savedSize, lessThan(originalSize));

      // Verify dimensions
      final savedImage = img.decodeImage(await savedFile.readAsBytes());
      expect(savedImage!.width, equals(1024));
    });

    test('getStorageUsage returns correct total', () async {
      final mockImage = await createMockImage();
      await attachmentService.saveAttachment('tx1', mockImage);
      await attachmentService.saveAttachment('tx2', mockImage);

      final usage = await attachmentService.getStorageUsage();
      expect(usage, greaterThan(0));

      final attachments1 = await attachmentService.getAttachments('tx1');
      final attachments2 = await attachmentService.getAttachments('tx2');
      final file1Size = await attachments1[0].length();
      final file2Size = await attachments2[0].length();

      expect(usage, equals(file1Size + file2Size));
    });

    test('Integration: deleteAttachment removes file and DB row', () async {
      final mockImage = await createMockImage();
      final txId = await setupTransaction();

      final savedPath = await attachmentService.saveAttachment(txId, mockImage);
      await attachmentRepository.createAttachment(
        txId,
        savedPath,
        'image/jpeg',
      );

      // Verify exists
      var dbAttachments = await attachmentRepository
          .getAttachmentsByTransaction(txId);
      expect(dbAttachments, hasLength(1));
      expect(File(savedPath).existsSync(), isTrue);

      final attachmentId = dbAttachments[0].id;

      // Delete
      await attachmentService.deleteAttachment(savedPath);
      await attachmentRepository.deleteAttachment(attachmentId);

      // Verify removed
      dbAttachments = await attachmentRepository.getAttachmentsByTransaction(
        txId,
      );
      expect(dbAttachments, isEmpty);
      expect(File(savedPath).existsSync(), isFalse);
    });

    test(
      'Integration: cascade delete removes all attachments for transaction',
      () async {
        final mockImage = await createMockImage();
        final txId = await setupTransaction();

        for (int i = 0; i < 3; i++) {
          final path = await attachmentService.saveAttachment(txId, mockImage);
          await attachmentRepository.createAttachment(txId, path, 'image/jpeg');
        }

        expect(await attachmentService.getAttachments(txId), hasLength(3));
        expect(
          await attachmentRepository.getAttachmentsByTransaction(txId),
          hasLength(3),
        );

        // Cascade delete
        await attachmentService.deleteAllAttachments(txId);
        await attachmentRepository.deleteAttachmentsByTransaction(txId);

        expect(await attachmentService.getAttachments(txId), isEmpty);
        expect(
          await attachmentRepository.getAttachmentsByTransaction(txId),
          isEmpty,
        );
      },
    );
  });
}
