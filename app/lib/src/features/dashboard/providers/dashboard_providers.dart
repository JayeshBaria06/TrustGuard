import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../app/providers.dart';
import '../../../core/models/transaction.dart';
import '../models/global_balance_summary.dart';
import '../services/dashboard_service.dart';

/// Provider for [DashboardService].
final dashboardServiceProvider = Provider<DashboardService>((ref) {
  return DashboardService(
    groupRepository: ref.watch(groupRepositoryProvider),
    memberRepository: ref.watch(memberRepositoryProvider),
    transactionRepository: ref.watch(transactionRepositoryProvider),
  );
});

/// Provider for watching all transactions across all groups.
final allTransactionsProvider = StreamProvider<List<Transaction>>((ref) {
  return ref.watch(transactionRepositoryProvider).watchAllTransactions();
});

/// Provider for watching all active groups.
final activeGroupsProvider = StreamProvider((ref) {
  return ref.watch(groupRepositoryProvider).watchGroups(includeArchived: false);
});

/// Provider for the global balance summary.
/// Reacts to changes in groups or transactions.
final globalBalanceSummaryProvider = StreamProvider<GlobalBalanceSummary>((
  ref,
) async* {
  final dashboardService = ref.watch(dashboardServiceProvider);

  // Watch active groups and all transactions to trigger recalculation
  ref.watch(activeGroupsProvider);
  ref.watch(allTransactionsProvider);

  // Recalculate summary
  // For MVP: aggregate all member balances across groups (not user-specific)
  yield await dashboardService.getGlobalSummary(null);
});

/// Provider for the last 5 transactions across all groups.
final recentActivityProvider = FutureProvider<List<Transaction>>((ref) {
  // Watch all transactions to keep it reactive
  final allTransactions = ref.watch(allTransactionsProvider).value ?? [];

  // Sort by occurredAt descending and take top 5
  final sorted = List<Transaction>.from(allTransactions)
    ..sort((a, b) => b.occurredAt.compareTo(a.occurredAt));

  return sorted.take(5).toList();
});
