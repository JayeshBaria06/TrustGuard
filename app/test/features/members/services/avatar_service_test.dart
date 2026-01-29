import 'dart:io';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:path/path.dart' as p;
import 'package:image/image.dart' as img;
import 'package:trustguard/src/features/members/services/avatar_service.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  late Directory tempDir;
  late AvatarService avatarService;

  setUp(() async {
    tempDir = await Directory.systemTemp.createTemp('avatar_service_test');

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

    avatarService = AvatarService();
  });

  tearDown(() async {
    if (await tempDir.exists()) {
      await tempDir.delete(recursive: true);
    }
  });

  Future<File> createMockImage({int width = 512, int height = 512}) async {
    final image = img.Image(width: width, height: height);
    img.fill(image, color: img.ColorRgb8(255, 0, 0));
    final bytes = img.encodeJpg(image);
    final file = File(p.join(tempDir.path, 'mock_image.jpg'));
    await file.writeAsBytes(bytes);
    return file;
  }

  group('AvatarService', () {
    test('saveAvatar resizes and compresses image', () async {
      final mockImage = await createMockImage(width: 1000, height: 1000);
      const memberId = 'm1';

      final savedPath = await avatarService.saveAvatar(memberId, mockImage);
      final savedFile = File(savedPath);

      expect(savedFile.existsSync(), isTrue);
      expect(savedPath, contains(p.join('avatars', '$memberId.jpg')));

      // Verify dimensions
      final savedImage = img.decodeImage(await savedFile.readAsBytes());
      expect(savedImage!.width, lessThanOrEqualTo(256));
      expect(savedImage.height, lessThanOrEqualTo(256));
    });

    test('deleteAvatar removes file', () async {
      final mockImage = await createMockImage();
      const memberId = 'm1';

      final savedPath = await avatarService.saveAvatar(memberId, mockImage);
      expect(File(savedPath).existsSync(), isTrue);

      await avatarService.deleteAvatar(memberId);
      expect(File(savedPath).existsSync(), isFalse);
    });

    test('getAvatarFile returns File if exists', () async {
      final mockImage = await createMockImage();
      const memberId = 'm1';

      final savedPath = await avatarService.saveAvatar(memberId, mockImage);

      final file = avatarService.getAvatarFile(savedPath);
      expect(file, isNotNull);
      expect(file!.path, equals(savedPath));
      expect(file.existsSync(), isTrue);
    });

    test('getAvatarFile returns null if path is null or file missing', () {
      expect(avatarService.getAvatarFile(null), isNull);
      expect(avatarService.getAvatarFile('non_existent_path.jpg'), isNull);
    });
  });
}
