import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:trustguard/src/features/dashboard/presentation/widgets/dashboard_card.dart';
import 'package:trustguard/src/features/dashboard/models/global_balance_summary.dart';
import 'package:trustguard/src/features/dashboard/providers/dashboard_providers.dart';
import 'package:trustguard/src/ui/components/balance_progress_bar.dart';
import '../../../../helpers/localization_helper.dart';
import '../../../../helpers/shared_prefs_helper.dart';

void main() {
  testWidgets('DashboardCard shows progress bars when data is loaded', (
    WidgetTester tester,
  ) async {
    const summary = GlobalBalanceSummary(
      totalOwedByMe: 5000,
      totalOwedToMe: 10000,
      groupCount: 2,
      unsettledGroupCount: 1,
    );

    final prefsOverrides = await getSharedPrefsOverride();

    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          globalBalanceSummaryProvider.overrideWith(
            (ref) => Stream.value(summary),
          ),
          ...prefsOverrides,
        ],
        child: wrapWithLocalization(const Scaffold(body: DashboardCard())),
      ),
    );

    await tester.pumpAndSettle();

    // Verify progress bars are present
    // Should be 2 (one for "You Owe", one for "Owed To You")
    expect(find.byType(BalanceProgressBar), findsNWidgets(2));

    // Check if labels are hidden as requested in DashboardCard
    final bars = tester.widgetList<BalanceProgressBar>(
      find.byType(BalanceProgressBar),
    );
    for (final bar in bars) {
      expect(bar.showLabel, isFalse);
      expect(bar.height, equals(4.0));
    }

    // Check amounts
    // You Owe (barAmount should be -5000)
    expect(bars.any((b) => b.amount == -5000), isTrue);
    // Owed To You (barAmount should be 10000)
    expect(bars.any((b) => b.amount == 10000), isTrue);
    // maxAmount should be 10000
    for (final bar in bars) {
      expect(bar.maxAmount, equals(10000));
    }
  });
}
