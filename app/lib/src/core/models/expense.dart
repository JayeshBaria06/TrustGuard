import 'package:freezed_annotation/freezed_annotation.dart';

part 'expense.freezed.dart';
part 'expense.g.dart';

enum SplitType { equal, custom }

@freezed
abstract class ExpenseParticipant with _$ExpenseParticipant {
  const factory ExpenseParticipant({
    required String memberId,
    required int owedAmountMinor,
  }) = _ExpenseParticipant;

  factory ExpenseParticipant.fromJson(Map<String, dynamic> json) =>
      _$ExpenseParticipantFromJson(json);
}

@freezed
abstract class ExpenseDetail with _$ExpenseDetail {
  const factory ExpenseDetail({
    required String payerMemberId,
    required int totalAmountMinor,
    required SplitType splitType,
    required List<ExpenseParticipant> participants,
    String? splitMetaJson,
    double? exchangeRate,
    String? originalCurrencyCode,
    int? originalAmountMinor,
  }) = _ExpenseDetail;

  factory ExpenseDetail.fromJson(Map<String, dynamic> json) =>
      _$ExpenseDetailFromJson(json);
}
