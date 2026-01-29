import 'package:freezed_annotation/freezed_annotation.dart';

import 'member.dart';

part 'balance.freezed.dart';
part 'balance.g.dart';

@freezed
abstract class MemberBalance with _$MemberBalance {
  const factory MemberBalance({
    required String memberId,
    required String memberName,
    required int netAmountMinor,
    required bool isCreditor,
    Member? member,
  }) = _MemberBalance;

  factory MemberBalance.fromJson(Map<String, dynamic> json) =>
      _$MemberBalanceFromJson(json);
}
