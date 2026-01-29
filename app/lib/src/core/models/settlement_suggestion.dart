import 'package:freezed_annotation/freezed_annotation.dart';

import 'member.dart';

part 'settlement_suggestion.freezed.dart';
part 'settlement_suggestion.g.dart';

@freezed
abstract class SettlementSuggestion with _$SettlementSuggestion {
  const factory SettlementSuggestion({
    required String fromMemberId,
    required String fromMemberName,
    required String toMemberId,
    required String toMemberName,
    required int amountMinor,
    Member? fromMember,
    Member? toMember,
  }) = _SettlementSuggestion;

  factory SettlementSuggestion.fromJson(Map<String, dynamic> json) =>
      _$SettlementSuggestionFromJson(json);
}
