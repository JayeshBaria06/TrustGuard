import 'package:freezed_annotation/freezed_annotation.dart';

part 'recurring_transaction.freezed.dart';
part 'recurring_transaction.g.dart';

enum RecurrenceFrequency { daily, weekly, biweekly, monthly, yearly }

@freezed
abstract class RecurringTransaction with _$RecurringTransaction {
  const factory RecurringTransaction({
    required String id,
    required String groupId,
    required String templateTransactionId,
    required RecurrenceFrequency frequency,
    required DateTime nextOccurrence,
    DateTime? endDate,
    @Default(true) bool isActive,
    required DateTime createdAt,
  }) = _RecurringTransaction;

  factory RecurringTransaction.fromJson(Map<String, dynamic> json) =>
      _$RecurringTransactionFromJson(json);
}
