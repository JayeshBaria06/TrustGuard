import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../app/providers.dart';
import '../models/spending_data.dart';
import '../services/spending_analytics_service.dart';

enum AnalyticsPeriod {
  last3Months(3),
  last6Months(6),
  last12Months(12);

  final int months;
  const AnalyticsPeriod(this.months);
}

final analyticsPeriodProvider = StateProvider<AnalyticsPeriod>(
  (ref) => AnalyticsPeriod.last6Months,
);

final analyticsDateRangeProvider = Provider<({DateTime? start, DateTime? end})>(
  (ref) {
    final period = ref.watch(analyticsPeriodProvider);
    final now = DateTime.now();
    // Start from the beginning of the N-th month ago
    final start = DateTime(now.year, now.month - period.months + 1, 1);
    return (start: start, end: now);
  },
);

final spendingAnalyticsServiceProvider = Provider<SpendingAnalyticsService>((
  ref,
) {
  final transactionRepository = ref.watch(transactionRepositoryProvider);
  final memberRepository = ref.watch(memberRepositoryProvider);
  return SpendingAnalyticsService(
    transactionRepository: transactionRepository,
    memberRepository: memberRepository,
  );
});

final spendingByTagProvider = FutureProvider.family<Map<String, int>, String>((
  ref,
  groupId,
) {
  final service = ref.watch(spendingAnalyticsServiceProvider);
  final range = ref.watch(analyticsDateRangeProvider);
  return service.getSpendingByTag(
    groupId,
    startDate: range.start,
    endDate: range.end,
  );
});

final spendingByMemberProvider =
    FutureProvider.family<Map<String, int>, String>((ref, groupId) {
      final service = ref.watch(spendingAnalyticsServiceProvider);
      final range = ref.watch(analyticsDateRangeProvider);
      return service.getSpendingByMember(
        groupId,
        startDate: range.start,
        endDate: range.end,
      );
    });

final monthlyTrendProvider =
    FutureProvider.family<List<MonthlySpending>, String>((ref, groupId) {
      final service = ref.watch(spendingAnalyticsServiceProvider);
      final period = ref.watch(analyticsPeriodProvider);
      return service.getMonthlyTrend(groupId, period.months);
    });
