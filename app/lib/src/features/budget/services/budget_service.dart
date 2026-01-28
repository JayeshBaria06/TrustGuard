import 'package:intl/intl.dart';
import '../../../core/database/repositories/budget_repository.dart';
import '../../../core/database/repositories/transaction_repository.dart';
import '../../../core/models/budget.dart';
import '../../../core/models/budget_progress.dart';
import '../../../core/models/transaction_filter.dart';

class BudgetService {
  final BudgetRepository _budgetRepository;
  final TransactionRepository _transactionRepository;

  BudgetService(this._budgetRepository, this._transactionRepository);

  /// Calculates the start and end dates for the current period of the budget.
  (DateTime start, DateTime end) calculatePeriodBounds(Budget budget) {
    final now = DateTime.now();
    // Use user-local time for boundaries to align with their day start/end

    switch (budget.period) {
      case BudgetPeriod.custom:
        return (budget.startDate, budget.endDate ?? budget.startDate);

      case BudgetPeriod.weekly:
        // Assume Monday start
        final currentWeekday = now.weekday;
        final daysToSubtract = currentWeekday - 1;
        final start = DateTime(now.year, now.month, now.day - daysToSubtract);
        final end = start.add(
          const Duration(days: 6, hours: 23, minutes: 59, seconds: 59),
        );
        return (start, end);

      case BudgetPeriod.monthly:
        final start = DateTime(now.year, now.month, 1);
        final lastDay = DateTime(now.year, now.month + 1, 0);
        final end = DateTime(
          lastDay.year,
          lastDay.month,
          lastDay.day,
          23,
          59,
          59,
        );
        return (start, end);

      case BudgetPeriod.yearly:
        final start = DateTime(now.year, 1, 1);
        final end = DateTime(now.year, 12, 31, 23, 59, 59);
        return (start, end);
    }
  }

  /// Calculates total spending for the budget in the current period.
  Future<int> getSpendingForBudget(Budget budget) async {
    final (start, end) = calculatePeriodBounds(budget);

    final filter = TransactionFilter(
      startDate: start,
      endDate: end,
      tagIds: budget.tagId != null ? {budget.tagId!} : null,
    );

    // Fetch transactions for the group within range and optional tag
    final transactions = await _transactionRepository.getTransactionsByGroup(
      budget.groupId,
      filter: filter,
    );

    int totalSpent = 0;
    for (final tx in transactions) {
      // Only count expenses, not transfers
      // Transaction model: if expenseDetail != null -> expense
      // Assuming Transaction repository returns hydrated models
      if (tx.expenseDetail != null) {
        // If budget is tag-specific, the repository filter handles it.
        // But we should double check if the transaction amount logic is correct.
        // Usually budget tracks total expense amount.
        totalSpent += tx.expenseDetail!.totalAmountMinor;
      }
    }

    return totalSpent;
  }

  /// Calculates comprehensive progress for a budget.
  Future<BudgetProgress> getBudgetProgress(Budget budget) async {
    final spent = await getSpendingForBudget(budget);
    final remaining = budget.limitMinor - spent;
    final percent = budget.limitMinor > 0 ? spent / budget.limitMinor : 0.0;
    final isOver = spent > budget.limitMinor;

    final (start, end) = calculatePeriodBounds(budget);
    String label;
    final dateFormat = DateFormat.yMMMd();

    switch (budget.period) {
      case BudgetPeriod.monthly:
        label = DateFormat.yMMM().format(start);
        break;
      case BudgetPeriod.yearly:
        label = DateFormat.y().format(start);
        break;
      default:
        label = '${dateFormat.format(start)} - ${dateFormat.format(end)}';
    }

    return BudgetProgress(
      budget: budget.copyWith(currentAmount: spent),
      spentMinor: spent,
      remainingMinor: remaining,
      percentUsed: percent,
      isOverBudget: isOver,
      periodLabel: label,
    );
  }

  /// Checks for budgets that have exceeded their alert threshold.
  Future<List<BudgetProgress>> checkBudgetAlerts(String groupId) async {
    final activeBudgets = await _budgetRepository.getBudgetsByGroup(groupId);
    final active = activeBudgets.where((b) => b.isActive).toList();

    final alerts = <BudgetProgress>[];

    for (final budget in active) {
      final progress = await getBudgetProgress(budget);
      // Check if usage >= threshold %
      // threshold is int 0-100
      final thresholdPercent = budget.alertThreshold / 100.0;

      if (progress.percentUsed >= thresholdPercent) {
        alerts.add(progress);
      }
    }

    return alerts;
  }
}
