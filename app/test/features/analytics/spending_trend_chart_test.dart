import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:trustguard/src/app/providers.dart';
import 'package:trustguard/src/features/analytics/models/spending_data.dart';
import 'package:trustguard/src/features/analytics/presentation/widgets/spending_trend_chart.dart';

void main() {
  testWidgets('SpendingTrendChart renders with valid data', (tester) async {
    final data = [
      MonthlySpending(month: DateTime(2023, 1, 1), totalAmountMinor: 1000),
      MonthlySpending(month: DateTime(2023, 2, 1), totalAmountMinor: 2000),
      MonthlySpending(month: DateTime(2023, 3, 1), totalAmountMinor: 1500),
    ];

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
            body: SpendingTrendChart(data: data, title: 'Spending Trend'),
          ),
        ),
      ),
    );

    expect(find.text('Spending Trend'), findsOneWidget);
    expect(find.byType(LineChart), findsOneWidget);
  });

  testWidgets('SpendingTrendChart shows insufficient data state', (
    tester,
  ) async {
    final data = [
      MonthlySpending(month: DateTime(2023, 1, 1), totalAmountMinor: 1000),
    ];

    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          moneyFormatterProvider.overrideWithValue(
            (int amount, {String currencyCode = 'USD', String? locale}) =>
                '\$${amount / 100}',
          ),
        ],
        child: MaterialApp(
          home: Scaffold(
            body: SpendingTrendChart(data: data, title: 'Spending'),
          ),
        ),
      ),
    );

    expect(
      find.text('Trend requires at least 2 months of data'),
      findsOneWidget,
    );
    expect(find.byType(LineChart), findsNothing);
  });

  testWidgets('SpendingTrendChart period selector triggers callback', (
    tester,
  ) async {
    final data = [
      MonthlySpending(month: DateTime(2023, 1, 1), totalAmountMinor: 1000),
      MonthlySpending(month: DateTime(2023, 2, 1), totalAmountMinor: 2000),
    ];
    int? selectedPeriod;

    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          moneyFormatterProvider.overrideWithValue(
            (int amount, {String currencyCode = 'USD', String? locale}) =>
                '\$${amount / 100}',
          ),
        ],
        child: MaterialApp(
          home: Scaffold(
            body: SpendingTrendChart(
              data: data,
              title: 'Spending',
              selectedMonths: 6,
              onPeriodChanged: (val) => selectedPeriod = val,
            ),
          ),
        ),
      ),
    );

    await tester.tap(find.text('3M'));
    await tester.pumpAndSettle();

    expect(selectedPeriod, 3);
  });
}
