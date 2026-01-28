import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:trustguard/src/app/providers.dart';
import 'package:trustguard/src/core/models/budget.dart';
import 'package:trustguard/src/core/models/budget_progress.dart';
import 'package:trustguard/src/features/budget/presentation/widgets/budget_progress_card.dart';
import 'package:trustguard/src/ui/theme/app_theme.dart';

void main() {
  final budget = Budget(
    id: '1',
    groupId: 'g1',
    name: 'Groceries',
    limitMinor: 10000, // 100.00
    currencyCode: 'USD',
    period: BudgetPeriod.monthly,
    startDate: DateTime.now(),
    alertThreshold: 80,
    isActive: true,
    createdAt: DateTime.now(),
  );

  String mockFormatter(int minor, {String? currencyCode, String? locale}) {
    final amount = minor / 100.0;
    return '\$${amount.toStringAsFixed(2)}';
  }

  Future<void> pumpCard(WidgetTester tester, BudgetProgress progress) async {
    await tester.pumpWidget(
      ProviderScope(
        overrides: [moneyFormatterProvider.overrideWithValue(mockFormatter)],
        child: MaterialApp(
          theme: AppTheme.lightTheme,
          home: Scaffold(
            body: Padding(
              padding: const EdgeInsets.all(16.0),
              child: BudgetProgressCard(progress: progress),
            ),
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();
  }

  group('BudgetProgressCard', () {
    testWidgets('renders correctly under threshold', (tester) async {
      final progress = BudgetProgress(
        budget: budget,
        spentMinor: 2000, // 20.00
        remainingMinor: 8000,
        percentUsed: 0.2,
        isOverBudget: false,
        periodLabel: 'Jan 2024',
      );

      await pumpCard(tester, progress);

      expect(find.text('Groceries'), findsOneWidget);
      expect(find.text('\$20.00'), findsOneWidget);
      expect(find.text('of \$100.00'), findsOneWidget);
      expect(find.text('Jan 2024'), findsOneWidget);
      // Warning icon should not be present
      expect(find.byIcon(Icons.warning_amber_rounded), findsNothing);
    });

    testWidgets('renders warning color over threshold', (tester) async {
      final progress = BudgetProgress(
        budget: budget,
        spentMinor: 8500, // 85.00 (85% > 80%)
        remainingMinor: 1500,
        percentUsed: 0.85,
        isOverBudget: false,
        periodLabel: 'Jan 2024',
      );

      await pumpCard(tester, progress);

      // Warning icon should be present
      expect(find.byIcon(Icons.warning_amber_rounded), findsOneWidget);

      // We can't easily check color of text/bar without deeper inspection,
      // but finding the icon confirms the logic branch.
    });

    testWidgets('renders error color when over budget', (tester) async {
      final progress = BudgetProgress(
        budget: budget,
        spentMinor: 11000, // 110.00 (110%)
        remainingMinor: -1000,
        percentUsed: 1.1,
        isOverBudget: true,
        periodLabel: 'Jan 2024',
      );

      await pumpCard(tester, progress);

      expect(find.byIcon(Icons.warning_amber_rounded), findsOneWidget);
    });

    testWidgets('compact mode renders simplified view', (tester) async {
      final progress = BudgetProgress(
        budget: budget,
        spentMinor: 5000,
        remainingMinor: 5000,
        percentUsed: 0.5,
        isOverBudget: false,
        periodLabel: 'Jan 2024',
      );

      await tester.pumpWidget(
        ProviderScope(
          overrides: [moneyFormatterProvider.overrideWithValue(mockFormatter)],
          child: MaterialApp(
            theme: AppTheme.lightTheme,
            home: Scaffold(
              body: Padding(
                padding: const EdgeInsets.all(16.0),
                child: BudgetProgressCard(progress: progress, compact: true),
              ),
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text('\$50.00 / \$100.00'), findsOneWidget);
      expect(
        find.text('of \$100.00'),
        findsNothing,
      ); // Compact doesn't show "of ..."
    });
  });
}
