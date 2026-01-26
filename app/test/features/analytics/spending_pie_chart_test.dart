import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:trustguard/src/app/providers.dart';
import 'package:trustguard/src/features/analytics/presentation/widgets/spending_pie_chart.dart';

void main() {
  testWidgets('SpendingPieChart renders with valid data', (tester) async {
    final data = {'Food': 1000, 'Transport': 500};

    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          moneyFormatterProvider.overrideWithValue(
            (int amount, {String currencyCode = 'USD', String? locale}) =>
                '\$${(amount / 100).toStringAsFixed(2)}',
          ),
        ],
        child: MaterialApp(
          home: Scaffold(
            body: SpendingPieChart(data: data, title: 'Spending Breakdown'),
          ),
        ),
      ),
    );

    expect(find.text('Spending Breakdown'), findsOneWidget);
    expect(find.byType(PieChart), findsOneWidget);

    // Total in the center
    expect(find.text('Total'), findsOneWidget);
    expect(find.text('\$15.00'), findsOneWidget); // 1000 + 500 = 1500 -> 15.00
  });

  testWidgets('SpendingPieChart shows empty state when no data', (
    tester,
  ) async {
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          moneyFormatterProvider.overrideWithValue(
            (int amount, {String currencyCode = 'USD', String? locale}) =>
                '\$${amount / 100}',
          ),
        ],
        child: const MaterialApp(
          home: Scaffold(
            body: SpendingPieChart(data: {}, title: 'Spending'),
          ),
        ),
      ),
    );

    expect(find.text('No data for this period'), findsOneWidget);
    expect(find.byType(PieChart), findsNothing);
  });

  testWidgets('SpendingPieChart legend displays correct labels and amounts', (
    tester,
  ) async {
    final data = {'Food': 1250, 'Transport': 750};

    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          moneyFormatterProvider.overrideWithValue(
            (int amount, {String currencyCode = 'USD', String? locale}) =>
                '\$${(amount / 100).toStringAsFixed(2)}',
          ),
        ],
        child: MaterialApp(
          home: Scaffold(
            body: SpendingPieChart(data: data, title: 'Spending'),
          ),
        ),
      ),
    );

    expect(find.text('Food: \$12.50'), findsOneWidget);
    expect(find.text('Transport: \$7.50'), findsOneWidget);
  });
}
