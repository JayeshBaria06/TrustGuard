import 'package:freezed_annotation/freezed_annotation.dart';

part 'widget_data.freezed.dart';
part 'widget_data.g.dart';

@freezed
abstract class WidgetData with _$WidgetData {
  const factory WidgetData({
    required int totalOwedToMe,
    required int totalOwedByMe,
    required int netBalance,
    required String currencyCode,
    required int activeGroupCount,
    required DateTime lastUpdated,
  }) = _WidgetData;

  factory WidgetData.fromJson(Map<String, dynamic> json) =>
      _$WidgetDataFromJson(json);
}
