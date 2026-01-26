import 'package:confetti/confetti.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:trustguard/src/app/providers.dart';
import 'package:trustguard/src/core/models/group.dart';
import 'package:trustguard/src/core/models/settlement_suggestion.dart';
import 'package:trustguard/src/features/balances/presentation/settlements_screen.dart';
import 'package:trustguard/src/features/balances/providers/balance_providers.dart';
import 'package:trustguard/src/features/balances/services/balance_service.dart';
import 'package:trustguard/src/features/groups/presentation/groups_providers.dart';
import 'package:trustguard/src/generated/app_localizations.dart';

void main() {
  const groupId = 'group-1';

  Widget wrapWithLocalization(Widget child) {
    return MaterialApp(
      localizationsDelegates: AppLocalizations.localizationsDelegates,
      supportedLocales: AppLocalizations.supportedLocales,
      home: child,
    );
  }

  testWidgets('Confetti triggers when group becomes fully settled', (
    WidgetTester tester,
  ) async {
    SharedPreferences.setMockInitialValues({});
    final prefs = await SharedPreferences.getInstance();

    // Initial state: not settled
    final suggestions = [
      const SettlementSuggestion(
        fromMemberId: 'm1',
        fromMemberName: 'Alice',
        toMemberId: 'm2',
        toMemberName: 'Bob',
        amountMinor: 1000,
      ),
    ];

    final suggestionsProvider = StateProvider<List<SettlementSuggestion>>(
      (ref) => suggestions,
    );

    final container = ProviderContainer(
      overrides: [
        groupBalancesProvider(
          groupId,
        ).overrideWith((ref) => const Stream.empty()),
        groupStreamProvider(groupId).overrideWith(
          (ref) => Stream.value(
            Group(
              id: groupId,
              name: 'Test Group',
              currencyCode: 'USD',
              createdAt: DateTime.now(),
            ),
          ),
        ),
        membersByGroupProvider(groupId).overrideWith((ref) => Stream.value([])),
        groupSelfMemberProvider(
          groupId,
        ).overrideWith((ref) => GroupSelfMemberNotifier(prefs, groupId)),
        moneyFormatterProvider.overrideWithValue(
          (int amount, {String currencyCode = 'USD', String? locale}) =>
              '$amount',
        ),
        settlementSuggestionsProvider(
          groupId,
        ).overrideWith((ref) => ref.watch(suggestionsProvider)),
      ],
    );

    await tester.pumpWidget(
      UncontrolledProviderScope(
        container: container,
        child: wrapWithLocalization(const SettlementsScreen(groupId: groupId)),
      ),
    );

    // Verify ConfettiWidget is present and not playing
    final confettiWidget = tester.widget<ConfettiWidget>(
      find.byType(ConfettiWidget),
    );
    expect(
      confettiWidget.confettiController.state,
      ConfettiControllerState.stopped,
    );

    // Update state to fully settled
    container.read(suggestionsProvider.notifier).state = [];

    await tester.pump(); // Trigger listener

    // Verify ConfettiController is now playing
    expect(
      confettiWidget.confettiController.state,
      ConfettiControllerState.playing,
    );
  });

  testWidgets('Confetti does not trigger on initial load if already settled', (
    WidgetTester tester,
  ) async {
    SharedPreferences.setMockInitialValues({});
    final prefs = await SharedPreferences.getInstance();

    final container = ProviderContainer(
      overrides: [
        groupBalancesProvider(
          groupId,
        ).overrideWith((ref) => const Stream.empty()),
        groupStreamProvider(groupId).overrideWith(
          (ref) => Stream.value(
            Group(
              id: groupId,
              name: 'Test Group',
              currencyCode: 'USD',
              createdAt: DateTime.now(),
            ),
          ),
        ),
        membersByGroupProvider(groupId).overrideWith((ref) => Stream.value([])),
        groupSelfMemberProvider(
          groupId,
        ).overrideWith((ref) => GroupSelfMemberNotifier(prefs, groupId)),
        moneyFormatterProvider.overrideWithValue(
          (int amount, {String currencyCode = 'USD', String? locale}) =>
              '$amount',
        ),
        settlementSuggestionsProvider(groupId).overrideWith((ref) => []),
      ],
    );

    await tester.pumpWidget(
      UncontrolledProviderScope(
        container: container,
        child: wrapWithLocalization(const SettlementsScreen(groupId: groupId)),
      ),
    );

    // Verify ConfettiWidget is present and not playing
    final confettiWidget = tester.widget<ConfettiWidget>(
      find.byType(ConfettiWidget),
    );
    expect(
      confettiWidget.confettiController.state,
      ConfettiControllerState.stopped,
    );
  });
}
