import 'package:animations/animations.dart';
import 'package:confetti/confetti.dart';
import 'package:drift/native.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:trustguard/src/app/app.dart';
import 'package:trustguard/src/app/providers.dart';
import 'package:trustguard/src/core/database/database.dart';
import 'package:trustguard/src/features/analytics/presentation/widgets/spending_pie_chart.dart';
import 'package:trustguard/src/features/analytics/presentation/widgets/spending_trend_chart.dart';
import 'package:trustguard/src/features/import/models/import_result.dart';
import 'package:trustguard/src/features/import/providers/import_providers.dart';
import 'package:trustguard/src/features/import/services/csv_import_service.dart';
import 'package:trustguard/src/features/ocr/models/receipt_data.dart';
import 'package:trustguard/src/features/ocr/providers/ocr_providers.dart';
import 'package:trustguard/src/features/ocr/services/receipt_scanner_service.dart';
import 'package:trustguard/src/features/transactions/presentation/widgets/date_group_header.dart';
import 'package:trustguard/src/ui/components/rolling_number_text.dart';
import 'package:trustguard/src/ui/animations/shake_widget.dart';
import 'package:trustguard/src/ui/components/amount_input_field.dart';
import 'package:trustguard/src/ui/components/numeric_keypad.dart';
import 'package:uuid/uuid.dart';

class MockReceiptScannerService extends Mock implements ReceiptScannerService {}

class MockCsvImportService extends Mock implements CsvImportService {}

void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  group('v1.3 Features Integration Test', () {
    late MockReceiptScannerService mockOcr;
    late MockCsvImportService mockImport;
    late AppDatabase db;

    setUpAll(() {
      registerFallbackValue(DateTime.now());
    });

    setUp(() {
      mockOcr = MockReceiptScannerService();
      mockImport = MockCsvImportService();
      db = AppDatabase(NativeDatabase.memory());

      SharedPreferences.setMockInitialValues({
        'onboarding_complete': true,
        'theme_mode': 'light',
        'rounding_decimal_places': 2,
        'use_custom_keypad': true,
      });
    });

    tearDown(() async {
      await db.close();
    });

    testWidgets('Full v1.3 Feature Flow', (WidgetTester tester) async {
      // 1. Initial Setup: Create Group and Member
      final groupId = const Uuid().v4();
      await db
          .into(db.groups)
          .insert(
            GroupsCompanion.insert(
              id: groupId,
              name: 'Integration Test Group',
              currencyCode: 'USD',
              createdAt: DateTime.now(),
            ),
          );

      final memberId = const Uuid().v4();
      await db
          .into(db.members)
          .insert(
            MembersCompanion.insert(
              id: memberId,
              groupId: groupId,
              displayName: 'Test User',
              createdAt: DateTime.now(),
            ),
          );

      // Mock OCR Response
      when(() => mockOcr.scanReceipt(any())).thenAnswer(
        (_) async => ReceiptData(
          suggestedAmount: 42.50,
          suggestedMerchant: 'Integration Store',
          suggestedDate: DateTime(2026, 1, 27),
          rawText: 'Total: 42.50',
          confidence: 0.9,
        ),
      );

      // Mock Import Response
      when(
        () => mockImport.detectCsvFormat(any()),
      ).thenReturn(CsvFormat.splitwise);
      when(
        () => mockImport.getMemberNamesFromCsv(any()),
      ).thenAnswer((_) async => ['External User']);
      when(
        () => mockImport.importCsv(
          any(),
          any(),
          memberMapping: any(named: 'memberMapping'),
        ),
      ).thenAnswer(
        (_) async => const ImportResult(
          successCount: 1,
          failedCount: 0,
          errors: [],
          transactions: [],
        ),
      );

      final prefs = await SharedPreferences.getInstance();

      // Start the App
      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            databaseProvider.overrideWithValue(db),
            sharedPreferencesProvider.overrideWithValue(prefs),
            receiptScannerServiceProvider.overrideWithValue(mockOcr),
            csvImportServiceProvider.overrideWithValue(mockImport),
          ],
          child: const TrustGuardApp(),
        ),
      );

      await tester.pumpAndSettle();

      // Navigate to Group
      await tester.tap(find.text('Integration Test Group'));
      await tester.pumpAndSettle();

      // --- Task 10.1: Analytics (Requirement 1) ---
      await tester.tap(find.text('Analytics'));
      await tester.pumpAndSettle();
      expect(find.byType(SpendingPieChart), findsWidgets);
      expect(find.byType(SpendingTrendChart), findsOneWidget);
      await tester.pageBack();
      await tester.pumpAndSettle();

      // --- Task 10.5: Custom Keypad & OCR (Requirements 2 & 9) ---
      // Navigate to Add Expense
      await tester.tap(find.text('Add Expense'));
      await tester.pumpAndSettle();

      // Verify custom keypad (Requirement 9)
      expect(find.byType(NumericKeypad), findsOneWidget);
      expect(find.byType(AmountInputField), findsOneWidget);

      // Enter amount using keypad
      await tester.tap(find.text('4'));
      await tester.tap(find.text('2'));
      await tester.tap(find.text('.'));
      await tester.tap(find.text('5'));
      await tester.tap(find.text('0'));
      await tester.pump();
      expect(find.textContaining('42.50'), findsWidgets);

      // Test OCR (Requirement 2)
      await tester.tap(find.byIcon(Icons.document_scanner));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Take Photo'));
      await tester.pumpAndSettle();

      expect(find.text('Integration Store'), findsOneWidget);
      await tester.tap(find.text('Apply'));
      await tester.pumpAndSettle();
      expect(find.text('Integration Store'), findsOneWidget); // Note pre-filled

      // --- Task 10.2: Recurring Transactions (Requirement 3) ---
      await tester.ensureVisible(find.text('Repeat'));
      await tester.tap(find.text('Repeat'));
      await tester.pumpAndSettle();
      expect(find.text('Frequency'), findsOneWidget);

      // Save Expense
      final saveButton = find.widgetWithText(ElevatedButton, 'Add Expense');
      await tester.ensureVisible(saveButton);
      await tester.tap(saveButton);
      await tester.pumpAndSettle();

      // --- Task 10.4: Animations & Glassmorphism (Requirements 5, 6, 7, 10) ---

      // Transaction List & Container Transform (Requirement 5)
      await tester.tap(find.text('Transactions'));
      await tester.pumpAndSettle();
      expect(find.byType(OpenContainer), findsWidgets);

      // Glassmorphism (Requirement 10)
      expect(find.byType(DateGroupHeader), findsOneWidget);
      expect(
        find.descendant(
          of: find.byType(DateGroupHeader),
          matching: find.byType(BackdropFilter),
        ),
        findsOneWidget,
      );

      await tester.pageBack();
      await tester.pumpAndSettle();

      // Dashboard & Rolling Numbers (Requirement 6)
      await tester.pageBack();
      await tester.pumpAndSettle();
      expect(find.byType(RollingNumberText), findsWidgets);

      // Shake Animation (Requirement 7)
      // Trigger validation error on "Add Expense" screen
      await tester.tap(find.text('Integration Test Group'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Add Expense'));
      await tester.pumpAndSettle();

      // Clear amount and try to save
      await tester.tap(find.text('Clear'));
      await tester.pump();
      await tester.tap(find.widgetWithText(ElevatedButton, 'Add Expense'));
      await tester.pump();

      // Verify ShakeWidget exists
      expect(find.byType(ShakeWidget), findsWidgets);

      await tester.pageBack();
      await tester.pumpAndSettle();

      // --- Task 10.3: CSV Import (Requirement 4) ---
      await tester.tap(find.text('Import Data'));
      await tester.pumpAndSettle();

      await tester.tap(find.text('Select CSV File'));
      await tester.pumpAndSettle();
      // Since FilePicker is mocked via CsvImportService, we expect preview to show
      expect(find.textContaining('External User'), findsWidgets);

      await tester.pageBack();
      await tester.pumpAndSettle();

      // --- Task 10.4.6: Confetti (Requirement 8) ---
      await tester.tap(find.text('Balances'));
      await tester.pumpAndSettle();
      // Verify confetti widget is present
      expect(find.byType(ConfettiWidget), findsOneWidget);
    });
  });
}
