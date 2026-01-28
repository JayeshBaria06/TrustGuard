import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../app/providers.dart';
import '../models/theme_state.dart';
import '../services/theme_service.dart';

/// Provider for [ThemeService].
final themeServiceProvider = Provider<ThemeService>((ref) {
  final prefs = ref.watch(sharedPreferencesProvider);
  return ThemeService(prefs);
});

/// Provider for [ThemeState] managed by [ThemeNotifier].
final themeStateProvider = StateNotifierProvider<ThemeNotifier, ThemeState>((
  ref,
) {
  final themeService = ref.watch(themeServiceProvider);
  return ThemeNotifier(themeService);
});

/// Notifier for managing app theme state.
class ThemeNotifier extends StateNotifier<ThemeState> {
  final ThemeService _themeService;

  ThemeNotifier(this._themeService)
    : super(
        ThemeState(
          currentMode: _themeService.getThemeMode(),
          isHighContrast: _themeService.getHighContrast(),
        ),
      );

  /// Updates the current theme mode and persists the preference.
  Future<void> setThemeMode(ThemeModePreference mode) async {
    await _themeService.setThemeMode(mode);
    state = state.copyWith(currentMode: mode);
  }

  /// Toggles high contrast mode and persists the preference.
  Future<void> toggleHighContrast(bool enabled) async {
    await _themeService.setHighContrast(enabled);
    state = state.copyWith(isHighContrast: enabled);
  }

  /// Returns the current [ThemeModePreference].
  ThemeModePreference get currentThemeMode => state.currentMode;
}
