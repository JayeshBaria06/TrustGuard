import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

enum ThemeModePreference { system, light, dark }

class ThemeService {
  final SharedPreferences _prefs;
  static const String _themeModeKey = 'theme_mode';

  ThemeService(this._prefs);

  ThemeModePreference getThemeMode() {
    final modeString = _prefs.getString(_themeModeKey);
    if (modeString == null) return ThemeModePreference.system;

    return ThemeModePreference.values.firstWhere(
      (e) => e.name == modeString,
      orElse: () => ThemeModePreference.system,
    );
  }

  Future<void> setThemeMode(ThemeModePreference mode) async {
    await _prefs.setString(_themeModeKey, mode.name);
  }

  ThemeMode toFlutterThemeMode(ThemeModePreference preference) {
    switch (preference) {
      case ThemeModePreference.system:
        return ThemeMode.system;
      case ThemeModePreference.light:
        return ThemeMode.light;
      case ThemeModePreference.dark:
        return ThemeMode.dark;
    }
  }
}
