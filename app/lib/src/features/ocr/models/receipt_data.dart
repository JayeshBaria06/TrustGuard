import 'package:freezed_annotation/freezed_annotation.dart';

part 'receipt_data.freezed.dart';
part 'receipt_data.g.dart';

@freezed
abstract class ReceiptData with _$ReceiptData {
  const factory ReceiptData({
    double? suggestedAmount,
    DateTime? suggestedDate,
    String? suggestedMerchant,
    required String rawText,
    required double confidence,
  }) = _ReceiptData;

  factory ReceiptData.fromJson(Map<String, dynamic> json) =>
      _$ReceiptDataFromJson(json);
}
