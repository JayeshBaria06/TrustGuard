import 'dart:convert';
import 'dart:io';
import 'package:freezed_annotation/freezed_annotation.dart';

part 'shareable_expense.freezed.dart';
part 'shareable_expense.g.dart';

enum ShareableType { expense, transfer, batch }

@freezed
abstract class ShareableParticipant with _$ShareableParticipant {
  const factory ShareableParticipant({
    required String name,
    required int amountMinor,
  }) = _ShareableParticipant;

  factory ShareableParticipant.fromJson(Map<String, dynamic> json) =>
      _$ShareableParticipantFromJson(json);
}

@freezed
abstract class ShareableExpense with _$ShareableExpense {
  const ShareableExpense._(); // Added for custom methods if needed

  const factory ShareableExpense({
    @Default(1) int version,
    required ShareableType type,
    required String description,
    required int amountMinor,
    required String currencyCode,
    required DateTime date,
    required String payerName,
    required List<ShareableParticipant> participants,
    @Default([]) List<String> tags,
    String? sourceId,
  }) = _ShareableExpense;

  factory ShareableExpense.fromJson(Map<String, dynamic> json) =>
      _$ShareableExpenseFromJson(json);

  String toCompressedString() {
    final jsonString = jsonEncode(toJson());
    final bytes = utf8.encode(jsonString);
    final compressed = gzip.encode(bytes);
    return base64Encode(compressed);
  }

  static ShareableExpense fromCompressedString(String data) {
    final compressed = base64Decode(data);
    final bytes = gzip.decode(compressed);
    final jsonString = utf8.decode(bytes);
    return ShareableExpense.fromJson(
      jsonDecode(jsonString) as Map<String, dynamic>,
    );
  }
}

@freezed
abstract class ShareableBatch with _$ShareableBatch {
  const ShareableBatch._();

  const factory ShareableBatch({
    required String groupName,
    required List<ShareableExpense> expenses,
  }) = _ShareableBatch;

  factory ShareableBatch.fromJson(Map<String, dynamic> json) =>
      _$ShareableBatchFromJson(json);

  String toCompressedString() {
    final jsonString = jsonEncode(toJson());
    final bytes = utf8.encode(jsonString);
    final compressed = gzip.encode(bytes);
    return base64Encode(compressed);
  }

  static ShareableBatch fromCompressedString(String data) {
    final compressed = base64Decode(data);
    final bytes = gzip.decode(compressed);
    final jsonString = utf8.decode(bytes);
    return ShareableBatch.fromJson(
      jsonDecode(jsonString) as Map<String, dynamic>,
    );
  }
}
