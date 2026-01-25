import 'package:freezed_annotation/freezed_annotation.dart';

part 'transfer.freezed.dart';
part 'transfer.g.dart';

@freezed
class TransferDetail with _$TransferDetail {
  const factory TransferDetail({
    required String fromMemberId,
    required String toMemberId,
    required int amountMinor,
  }) = _TransferDetail;

  factory TransferDetail.fromJson(Map<String, dynamic> json) =>
      _$TransferDetailFromJson(json);
}
