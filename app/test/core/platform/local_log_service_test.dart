import 'dart:io';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:trustguard/src/core/platform/local_log_service.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  late Directory tempDir;
  late LocalLogService logService;

  setUp(() async {
    tempDir = await Directory.systemTemp.createTemp('local_log_service_test');

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

    logService = LocalLogService();
    // Since it's a singleton, we need to clear state if possible or handle it
    // The init() method will re-initialize the file path
    await logService.init();
    await logService.clearLogs();
  });

  tearDown(() async {
    if (await tempDir.exists()) {
      await tempDir.delete(recursive: true);
    }
  });

  group('LocalLogService', () {
    test('writeLog creates file and appends content', () async {
      final entry = LogEntry(
        timestamp: DateTime.now(),
        level: LogLevel.info,
        message: 'Test message',
      );

      await logService.writeLog(entry);

      final logs = await logService.readLogs();
      expect(logs, hasLength(1));

      final savedEntry = LogEntry.fromJson(logs[0]);
      expect(savedEntry.message, equals('Test message'));
      expect(savedEntry.level, equals(LogLevel.info));
    });

    test('multiple writes append in order', () async {
      await logService.info('Message 1');
      await logService.warning('Message 2');
      await logService.error('Message 3');

      final logs = await logService.readLogs();
      expect(logs, hasLength(3));

      expect(LogEntry.fromJson(logs[0]).message, equals('Message 1'));
      expect(LogEntry.fromJson(logs[1]).message, equals('Message 2'));
      expect(LogEntry.fromJson(logs[2]).message, equals('Message 3'));
    });

    test('clearLogs deletes files', () async {
      await logService.info('Test');
      expect(await logService.readLogs(), isNotEmpty);

      await logService.clearLogs();
      expect(await logService.readLogs(), isEmpty);
    });

    test('readLogs returns last 500 lines', () async {
      for (int i = 0; i < 600; i++) {
        // We write directly to the log file to speed up the test
        // avoiding too many DateTime.now() calls and rotation checks
        // but let's just use the API to be safe
        await logService.info('Message $i');
      }

      final logs = await logService.readLogs();
      expect(logs, hasLength(500));
      expect(LogEntry.fromJson(logs[0]).message, equals('Message 100'));
      expect(LogEntry.fromJson(logs[499]).message, equals('Message 599'));
    });

    test('file rotation occurs at 1MB threshold', () async {
      // Create a large log entry to reach 1MB quickly
      final largeString = 'A' * 1024; // 1KB
      final entry = LogEntry(
        timestamp: DateTime.now(),
        level: LogLevel.debug,
        message: largeString,
      );

      // Write enough to exceed 1MB (1024 KB)
      for (int i = 0; i < 1100; i++) {
        await logService.writeLog(entry);
      }

      final logFile = await logService.exportLogs();
      expect(logFile, isNotNull);

      // The current log file should be smaller than 1MB because it just rotated
      expect(await logFile!.length(), lessThan(1024 * 1024));

      // The old log file should exist
      final oldLogFile = File('${logFile.path}.old');
      expect(await oldLogFile.exists(), isTrue);
      expect(await oldLogFile.length(), greaterThan(1024 * 1024));
    });

    test('exportLogs returns valid file', () async {
      await logService.info('Export test');
      final file = await logService.exportLogs();

      expect(file, isNotNull);
      expect(await file!.exists(), isTrue);
      expect(file.path, contains('trustguard_logs.txt'));
    });
  });
}
