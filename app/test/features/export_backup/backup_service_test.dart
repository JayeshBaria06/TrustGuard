import 'dart:convert';
import 'dart:io';
import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:trustguard/src/core/database/database.dart';
import 'package:trustguard/src/core/database/repositories/group_repository.dart';
import 'package:trustguard/src/core/database/repositories/member_repository.dart';
import 'package:trustguard/src/core/database/repositories/transaction_repository.dart';
import 'package:trustguard/src/core/database/repositories/tag_repository.dart';
import 'package:trustguard/src/core/database/repositories/reminder_repository.dart';
import 'package:trustguard/src/features/export_backup/services/backup_service.dart';
import 'package:trustguard/src/core/models/group.dart' as model;
import 'package:trustguard/src/core/models/member.dart' as model;
import 'package:trustguard/src/core/models/transaction.dart' as model;
import 'package:trustguard/src/core/models/expense.dart' as model;
import 'package:trustguard/src/core/models/tag.dart' as model;
import 'package:trustguard/src/core/models/reminder_settings.dart' as model;
import 'package:trustguard/src/core/models/backup.dart' as model;

class MockFile extends Mock implements File {}

void main() {
  late AppDatabase db;
  late BackupService backupService;
  late GroupRepository groupRepository;
  late MemberRepository memberRepository;
  late TransactionRepository transactionRepository;
  late TagRepository tagRepository;
  late ReminderRepository reminderRepository;

  setUp(() {
    db = AppDatabase(NativeDatabase.memory());
    groupRepository = DriftGroupRepository(db);
    memberRepository = DriftMemberRepository(db);
    transactionRepository = DriftTransactionRepository(db);
    tagRepository = DriftTagRepository(db);
    reminderRepository = DriftReminderRepository(db);

    backupService = BackupService(
      database: db,
      groupRepository: groupRepository,
      memberRepository: memberRepository,
      transactionRepository: transactionRepository,
      tagRepository: tagRepository,
      reminderRepository: reminderRepository,
    );
  });

  tearDown(() async {
    await db.close();
  });

  test('createBackup returns a complete backup object', () async {
    // Arrange
    final now = DateTime(2026, 1, 26, 12, 0);
    final group = model.Group(
      id: 'g1',
      name: 'Test Group',
      currencyCode: 'USD',
      createdAt: now,
    );
    await groupRepository.createGroup(group);

    final member = model.Member(
      id: 'm1',
      groupId: 'g1',
      displayName: 'Member 1',
      createdAt: now,
    );
    await memberRepository.createMember(member);

    final transaction = model.Transaction(
      id: 't1',
      groupId: 'g1',
      type: model.TransactionType.expense,
      occurredAt: now,
      note: 'Test Tx',
      createdAt: now,
      updatedAt: now,
      expenseDetail: const model.ExpenseDetail(
        payerMemberId: 'm1',
        totalAmountMinor: 1000,
        splitType: model.SplitType.equal,
        participants: [
          model.ExpenseParticipant(memberId: 'm1', owedAmountMinor: 1000),
        ],
      ),
    );
    await transactionRepository.createTransaction(transaction);

    final tag = const model.Tag(id: 'tag1', groupId: 'g1', name: 'Tag 1');
    await tagRepository.createTag(tag);
    await tagRepository.assignTagsToTransaction('t1', ['tag1']);

    final reminder = const model.ReminderSettings(
      groupId: 'g1',
      enabled: true,
      schedule: model.ReminderSchedule.daily,
    );
    await reminderRepository.upsertReminderSettings(reminder);

    // Act
    final backup = await backupService.createBackup();

    // Assert
    expect(backup.schemaVersion, 1);
    expect(backup.groups.length, 1);
    expect(backup.groups.first.name, 'Test Group');
    expect(backup.members.length, 1);
    expect(backup.transactions.length, 1);
    expect(backup.transactions.first.expenseDetail?.payerMemberId, 'm1');
    expect(backup.tags.length, 1);
    expect(backup.reminderSettings.length, 1);

    // Test serialization roundtrip
    final jsonString = jsonEncode(backup.toJson());
    final decodedJson = jsonDecode(jsonString);
    expect(decodedJson['schemaVersion'], 1);
    expect(decodedJson['groups'], isA<List<dynamic>>());
  });

  test('restoreFromBackup imports data with new UUIDs', () async {
    // Arrange
    final now = DateTime(2026, 1, 26, 12, 0);
    final group = model.Group(
      id: 'old-g1',
      name: 'Original Group',
      currencyCode: 'USD',
      createdAt: now,
    );
    final member = model.Member(
      id: 'old-m1',
      groupId: 'old-g1',
      displayName: 'Original Member',
      createdAt: now,
    );
    final transaction = model.Transaction(
      id: 'old-t1',
      groupId: 'old-g1',
      type: model.TransactionType.expense,
      occurredAt: now,
      note: 'Original Tx',
      createdAt: now,
      updatedAt: now,
      expenseDetail: const model.ExpenseDetail(
        payerMemberId: 'old-m1',
        totalAmountMinor: 1000,
        splitType: model.SplitType.equal,
        participants: [
          model.ExpenseParticipant(memberId: 'old-m1', owedAmountMinor: 1000),
        ],
      ),
      tags: [
        const model.Tag(
          id: 'old-tag1',
          groupId: 'old-g1',
          name: 'Original Tag',
        ),
      ],
    );
    final tag = const model.Tag(
      id: 'old-tag1',
      groupId: 'old-g1',
      name: 'Original Tag',
    );
    final reminder = const model.ReminderSettings(
      groupId: 'old-g1',
      enabled: true,
      schedule: model.ReminderSchedule.daily,
    );

    final backup = model.Backup(
      schemaVersion: 1,
      createdAt: now,
      groups: [group],
      members: [member],
      transactions: [transaction],
      tags: [tag],
      reminderSettings: [reminder],
    );

    final jsonString = jsonEncode(backup.toJson());
    final mockFile = MockFile();
    when(() => mockFile.readAsString()).thenAnswer((_) async => jsonString);

    // Act
    await backupService.restoreFromBackup(mockFile);

    // Assert
    final restoredGroups = await groupRepository.getAllGroups();
    expect(restoredGroups.length, 1);
    expect(restoredGroups.first.name, 'Original Group');
    expect(restoredGroups.first.id, isNot('old-g1'));

    final newGroupId = restoredGroups.first.id;

    final restoredMembers = await memberRepository.getAllMembers();
    expect(restoredMembers.length, 1);
    expect(restoredMembers.first.groupId, newGroupId);
    expect(restoredMembers.first.id, isNot('old-m1'));

    final newMemberId = restoredMembers.first.id;

    final restoredTransactions = await transactionRepository
        .getAllTransactions();
    expect(restoredTransactions.length, 1);
    expect(restoredTransactions.first.groupId, newGroupId);
    expect(
      restoredTransactions.first.expenseDetail?.payerMemberId,
      newMemberId,
    );
    expect(
      restoredTransactions.first.expenseDetail?.participants.first.memberId,
      newMemberId,
    );
    expect(restoredTransactions.first.tags.length, 1);
    expect(restoredTransactions.first.tags.first.name, 'Original Tag');
    expect(restoredTransactions.first.tags.first.id, isNot('old-tag1'));

    final restoredReminders = await reminderRepository.getAllReminderSettings();
    expect(restoredReminders.length, 1);
    expect(restoredReminders.first.groupId, newGroupId);
  });
}
