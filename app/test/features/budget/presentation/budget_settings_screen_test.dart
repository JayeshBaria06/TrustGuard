import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:trustguard/src/app/providers.dart';
import 'package:trustguard/src/core/database/repositories/budget_repository.dart';
import 'package:trustguard/src/core/database/repositories/group_repository.dart';
import 'package:trustguard/src/core/database/repositories/tag_repository.dart';
import 'package:trustguard/src/core/models/budget.dart';
import 'package:trustguard/src/core/models/group.dart';
import 'package:trustguard/src/features/budget/presentation/budget_settings_screen.dart';
import 'package:trustguard/src/ui/theme/app_theme.dart';

class MockBudgetRepository extends Mock implements BudgetRepository {}

class MockGroupRepository extends Mock implements GroupRepository {}

class MockTagRepository extends Mock implements TagRepository {}

void main() {
  late MockBudgetRepository mockBudgetRepo;
  late MockGroupRepository mockGroupRepo;
  late MockTagRepository mockTagRepo;

  setUp(() {
    mockBudgetRepo = MockBudgetRepository();
    mockGroupRepo = MockGroupRepository();
    mockTagRepo = MockTagRepository();

    registerFallbackValue(
      Budget(
        id: 'fallback',
        groupId: 'fallback',
        name: 'fallback',
        limitMinor: 0,
        currencyCode: 'USD',
        period: BudgetPeriod.monthly,
        startDate: DateTime.now(),
        alertThreshold: 80,
        isActive: true,
        createdAt: DateTime.now(),
      ),
    );
  });

  Future<void> pumpScreen(WidgetTester tester) async {
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          budgetRepositoryProvider.overrideWithValue(mockBudgetRepo),
          groupRepositoryProvider.overrideWithValue(mockGroupRepo),
          tagRepositoryProvider.overrideWithValue(mockTagRepo),
        ],
        child: MaterialApp(
          theme: AppTheme.lightTheme,
          home: const BudgetSettingsScreen(groupId: 'group1'),
        ),
      ),
    );
    await tester.pumpAndSettle();
  }

  group('BudgetSettingsScreen', () {
    setUp(() {
      when(() => mockGroupRepo.watchGroupById('group1')).thenAnswer(
        (_) => Stream.value(
          Group(
            id: 'group1',
            name: 'Test Group',
            currencyCode: 'USD',
            createdAt: DateTime.now(),
          ),
        ),
      );

      when(
        () => mockTagRepo.watchTagsByGroup('group1'),
      ).thenAnswer((_) => Stream.value([]));
    });

    testWidgets('validates required fields', (tester) async {
      await pumpScreen(tester);

      // Tap save without entering anything
      await tester.tap(find.text('Save'));
      await tester.pump();

      expect(find.text('Required'), findsNWidgets(2)); // Name and Limit
    });

    testWidgets('creates budget on valid input', (tester) async {
      when(() => mockBudgetRepo.createBudget(any())).thenAnswer((_) async {});

      await pumpScreen(tester);

      // Enter name
      await tester.enterText(
        find.widgetWithText(TextFormField, 'Budget Name'),
        'Groceries',
      );

      // Enter limit
      await tester.enterText(
        find.widgetWithText(TextFormField, 'Limit Amount'),
        '500',
      );

      // Tap save
      await tester.tap(find.text('Save'));
      await tester.pump();

      verify(() => mockBudgetRepo.createBudget(any())).called(1);
    });

    testWidgets('validates custom period end date', (tester) async {
      await pumpScreen(tester);

      // Select Custom period
      await tester.tap(find.text('Monthly'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Custom').last);
      await tester.pumpAndSettle();

      // Enter other fields to pass their validation
      await tester.enterText(
        find.widgetWithText(TextFormField, 'Budget Name'),
        'Trip',
      );
      await tester.enterText(
        find.widgetWithText(TextFormField, 'Limit Amount'),
        '1000',
      );

      // Tap save (End Date is null by default)
      await tester.tap(find.text('Save'));
      await tester.pump();

      expect(
        find.text('Please select an end date for custom period'),
        findsOneWidget,
      );
    });
  });
}
