import 'package:freezed_annotation/freezed_annotation.dart';
import 'budget.dart';

part 'budget_progress.freezed.dart';

@freezed
abstract class BudgetProgress with _$BudgetProgress {
  const factory BudgetProgress({
    required Budget budget,
    required int spentMinor,
    required int remainingMinor,
    required double percentUsed,
    required bool isOverBudget,
    required String periodLabel,
  }) = _BudgetProgress;
}
