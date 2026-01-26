import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:mocktail/mocktail.dart';
import 'package:trustguard/src/app/providers.dart';
import 'package:trustguard/src/features/export_backup/presentation/backup_screen.dart';
import 'package:trustguard/src/features/export_backup/services/backup_service.dart';

class MockBackupService extends Mock implements BackupService {}

void main() {
  late MockBackupService mockBackupService;

  setUp(() {
    mockBackupService = MockBackupService();
    registerFallbackValue(File(''));
  });

  Widget createWidget() {
    return ProviderScope(
      overrides: [backupServiceProvider.overrideWithValue(mockBackupService)],
      child: const MaterialApp(home: BackupScreen()),
    );
  }

  testWidgets('BackupScreen displays cards for backup and restore', (
    tester,
  ) async {
    await tester.pumpWidget(createWidget());

    expect(find.text('Backup & Restore'), findsOneWidget);
    expect(find.text('Create Backup'), findsOneWidget);
    expect(find.text('Restore from Backup'), findsOneWidget);
    expect(find.text('Create and Share Backup'), findsOneWidget);
    expect(find.text('Select Backup File'), findsOneWidget);
  });

  testWidgets('tapping Create Backup calls shareBackup', (tester) async {
    when(() => mockBackupService.shareBackup()).thenAnswer((_) async {});

    await tester.pumpWidget(createWidget());

    await tester.tap(find.text('Create and Share Backup'));
    await tester.pump();

    verify(() => mockBackupService.shareBackup()).called(1);
    expect(find.textContaining('Backup created at'), findsOneWidget);
  });

  testWidgets('shows error snackbar if backup fails', (tester) async {
    when(
      () => mockBackupService.shareBackup(),
    ).thenThrow(Exception('Export failed'));

    await tester.pumpWidget(createWidget());

    await tester.tap(find.text('Create and Share Backup'));
    await tester.pumpAndSettle();

    expect(find.textContaining('Export failed'), findsOneWidget);
  });
}
