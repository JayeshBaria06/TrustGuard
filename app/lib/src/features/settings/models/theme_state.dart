import 'package:freezed_annotation/freezed_annotation.dart';
import '../services/theme_service.dart';

part 'theme_state.freezed.dart';
part 'theme_state.g.dart';

@freezed
abstract class ThemeState with _$ThemeState {
  const factory ThemeState({
    @Default(ThemeModePreference.system) ThemeModePreference currentMode,
  }) = _ThemeState;

  factory ThemeState.fromJson(Map<String, dynamic> json) =>
      _$ThemeStateFromJson(json);
}
