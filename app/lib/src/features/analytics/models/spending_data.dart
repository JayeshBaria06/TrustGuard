import 'package:freezed_annotation/freezed_annotation.dart';

part 'spending_data.freezed.dart';
part 'spending_data.g.dart';

@freezed
abstract class MonthlySpending with _$MonthlySpending {
  const factory MonthlySpending({
    required DateTime month,
    required int totalAmountMinor,
  }) = _MonthlySpending;

  factory MonthlySpending.fromJson(Map<String, dynamic> json) =>
      _$MonthlySpendingFromJson(json);
}
