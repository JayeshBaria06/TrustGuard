import 'package:freezed_annotation/freezed_annotation.dart';
import '../../../core/models/transaction.dart';

part 'import_result.freezed.dart';
part 'import_result.g.dart';

@freezed
abstract class ImportError with _$ImportError {
  const factory ImportError({required int rowNumber, required String message}) =
      _ImportError;

  factory ImportError.fromJson(Map<String, dynamic> json) =>
      _$ImportErrorFromJson(json);
}

@freezed
abstract class ImportResult with _$ImportResult {
  const factory ImportResult({
    required int successCount,
    required int failedCount,
    required List<ImportError> errors,
    required List<Transaction> transactions,
  }) = _ImportResult;

  factory ImportResult.fromJson(Map<String, dynamic> json) =>
      _$ImportResultFromJson(json);
}
