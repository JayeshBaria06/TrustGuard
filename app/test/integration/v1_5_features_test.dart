import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:trustguard/src/app/app.dart';
import 'package:trustguard/src/app/providers.dart';
import 'package:trustguard/src/core/database/database.dart';
import 'package:trustguard/src/core/models/transaction.dart' as tx_model;
import 'package:trustguard/src/core/models/expense.dart' as exp_model;
import 'package:trustguard/src/core/platform/notification_service.dart';
import 'package:trustguard/src/features/sharing/presentation/share_expense_sheet.dart';
import 'package:trustguard/src/features/members/presentation/avatar_picker.dart';
import 'package:trustguard/src/features/budget/presentation/budget_settings_screen.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:drift/native.dart';
import 'package:mocktail/mocktail.dart';

class MockNotificationService extends Mock implements NotificationService {}

void main() {
  group('v1.5 Features Integration Test', () {
    late AppDatabase db;
    late MockNotificationService mockNotificationService;

    setUp(() {
      db = AppDatabase(NativeDatabase.memory());
      mockNotificationService = MockNotificationService();

      when(() => mockNotificationService.init()).thenAnswer((_) async {});
      when(
        () => mockNotificationService.requestPermissions(),
      ).thenAnswer((_) async => true);
      when(
        () => mockNotificationService.isPermissionGranted(),
      ).thenAnswer((_) async => true);

      // Mock path_provider
      TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
          .setMockMethodCallHandler(
            const MethodChannel('plugins.flutter.io/path_provider'),
            (methodCall) async {
              if (methodCall.method == 'getApplicationDocumentsDirectory') {
                return '.';
              }
              return null;
            },
          );

      // Mock home_widget
      TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
          .setMockMethodCallHandler(
            const MethodChannel('home_widget'),
            (methodCall) async => null,
          );
    });

    tearDown(() async {
      await db.close();
    });

    testWidgets('Verify Accessibility and High Contrast', (tester) async {
      SharedPreferences.setMockInitialValues({'onboarding_complete': true});
      final prefs = await SharedPreferences.getInstance();

      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            databaseProvider.overrideWithValue(db),
            sharedPreferencesProvider.overrideWithValue(prefs),
            notificationServiceProvider.overrideWithValue(
              mockNotificationService,
            ),
          ],
          child: const TrustGuardApp(),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.bySemanticsLabel('Open speed dial'), findsOneWidget);
      expect(find.text('Your Overview'), findsOneWidget);

      await tester.tap(find.byIcon(Icons.settings));
      await tester.pumpAndSettle();
      await tester.tap(find.text('High Contrast Mode'));
      await tester.pumpAndSettle();

      final SwitchListTile switchTile = tester.widget(
        find.widgetWithText(SwitchListTile, 'High Contrast Mode'),
      );
      expect(switchTile.value, true);

      await db.close();
      await tester.pump(Duration.zero);
    });

    testWidgets('Verify Budget Settings Rendering', (tester) async {
      SharedPreferences.setMockInitialValues({'onboarding_complete': true});
      final prefs = await SharedPreferences.getInstance();

      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            databaseProvider.overrideWithValue(db),
            sharedPreferencesProvider.overrideWithValue(prefs),
            notificationServiceProvider.overrideWithValue(
              mockNotificationService,
            ),
          ],
          child: const MaterialApp(home: BudgetSettingsScreen(groupId: 'g1')),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text('New Budget'), findsOneWidget);
      await tester.enterText(find.byType(TextFormField).at(0), 'Test Budget');
      await tester.enterText(find.byType(TextFormField).at(1), '100');

      expect(find.text('Save'), findsOneWidget);

      await db.close();
      await tester.pump(Duration.zero);
    });

    testWidgets('Verify Member Avatar Selection', (tester) async {
      SharedPreferences.setMockInitialValues({'onboarding_complete': true});
      final prefs = await SharedPreferences.getInstance();

      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            databaseProvider.overrideWithValue(db),
            sharedPreferencesProvider.overrideWithValue(prefs),
            notificationServiceProvider.overrideWithValue(
              mockNotificationService,
            ),
          ],
          child: MaterialApp(
            home: Scaffold(body: AvatarPicker(onSelectionChanged: (p, c) {})),
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text('Or select a color'), findsOneWidget);
      await tester.tap(find.byType(GestureDetector).at(5));
      await tester.pumpAndSettle();

      await db.close();
      await tester.pump(Duration.zero);
    });

    testWidgets('Verify QR Share Sheet', (tester) async {
      SharedPreferences.setMockInitialValues({'onboarding_complete': true});
      final prefs = await SharedPreferences.getInstance();

      final tx = tx_model.Transaction(
        id: 't1',
        groupId: 'g1',
        type: tx_model.TransactionType.expense,
        occurredAt: DateTime.now(),
        note: 'Test item',
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
        expenseDetail: const exp_model.ExpenseDetail(
          payerMemberId: 'm1',
          totalAmountMinor: 1000,
          splitType: exp_model.SplitType.equal,
          participants: [],
        ),
      );

      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            databaseProvider.overrideWithValue(db),
            sharedPreferencesProvider.overrideWithValue(prefs),
            notificationServiceProvider.overrideWithValue(
              mockNotificationService,
            ),
          ],
          child: MaterialApp(
            home: Scaffold(body: ShareExpenseSheet(transaction: tx)),
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text('Share Expense'), findsOneWidget);
      expect(find.byType(ShareExpenseSheet), findsOneWidget);

      await db.close();
      await tester.pump(Duration.zero);
    });
  });
}
