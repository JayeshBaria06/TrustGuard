import '../../../core/database/repositories/transaction_repository.dart';
import '../../../core/database/repositories/member_repository.dart';
import '../../../core/models/transaction.dart';
import '../../../core/models/transaction_filter.dart';
import '../models/spending_data.dart';

class SpendingAnalyticsService {
  final TransactionRepository _transactionRepository;
  final MemberRepository _memberRepository;

  SpendingAnalyticsService({
    required TransactionRepository transactionRepository,
    required MemberRepository memberRepository,
  }) : _transactionRepository = transactionRepository,
       _memberRepository = memberRepository;

  Future<Map<String, int>> getSpendingByTag(
    String groupId, {
    DateTime? startDate,
    DateTime? endDate,
  }) async {
    final transactions = await _transactionRepository.getTransactionsByGroup(
      groupId,
      filter: TransactionFilter(startDate: startDate, endDate: endDate),
    );

    final spendingByTag = <String, int>{};

    for (final tx in transactions) {
      if (tx.type != TransactionType.expense || tx.expenseDetail == null) {
        continue;
      }

      final amount = tx.expenseDetail!.totalAmountMinor;
      if (tx.tags.isEmpty) {
        spendingByTag.update(
          'Other',
          (value) => value + amount,
          ifAbsent: () => amount,
        );
      } else {
        // Use the first tag for categorization to avoid double counting in charts
        final tagName = tx.tags.first.name;
        spendingByTag.update(
          tagName,
          (value) => value + amount,
          ifAbsent: () => amount,
        );
      }
    }

    return spendingByTag;
  }

  Future<Map<String, int>> getSpendingByMember(
    String groupId, {
    DateTime? startDate,
    DateTime? endDate,
  }) async {
    final transactions = await _transactionRepository.getTransactionsByGroup(
      groupId,
      filter: TransactionFilter(startDate: startDate, endDate: endDate),
    );

    final members = await _memberRepository.getMembersByGroup(
      groupId,
      includeRemoved: true,
    );
    final memberMap = {for (var m in members) m.id: m.displayName};

    final spendingByMember = <String, int>{};

    for (final tx in transactions) {
      if (tx.type != TransactionType.expense || tx.expenseDetail == null) {
        continue;
      }

      final amount = tx.expenseDetail!.totalAmountMinor;
      final payerId = tx.expenseDetail!.payerMemberId;
      final memberName = memberMap[payerId] ?? 'Unknown';

      spendingByMember.update(
        memberName,
        (value) => value + amount,
        ifAbsent: () => amount,
      );
    }

    return spendingByMember;
  }

  Future<List<MonthlySpending>> getMonthlyTrend(
    String groupId,
    int months,
  ) async {
    final now = DateTime.now();
    // Start from the beginning of the N-th month ago
    final startDate = DateTime(now.year, now.month - months + 1, 1);

    final transactions = await _transactionRepository.getTransactionsByGroup(
      groupId,
      filter: TransactionFilter(startDate: startDate, endDate: now),
    );

    final monthlyData = <DateTime, int>{};

    // Initialize months with 0 to ensure we have data points for all months
    for (int i = 0; i < months; i++) {
      final month = DateTime(now.year, now.month - i, 1);
      monthlyData[month] = 0;
    }

    for (final tx in transactions) {
      if (tx.type != TransactionType.expense || tx.expenseDetail == null) {
        continue;
      }

      final month = DateTime(tx.occurredAt.year, tx.occurredAt.month, 1);
      if (monthlyData.containsKey(month)) {
        monthlyData[month] =
            monthlyData[month]! + tx.expenseDetail!.totalAmountMinor;
      }
    }

    final result = monthlyData.entries
        .map((e) => MonthlySpending(month: e.key, totalAmountMinor: e.value))
        .toList();

    // Sort by date ascending
    result.sort((a, b) => a.month.compareTo(b.month));

    return result;
  }
}
