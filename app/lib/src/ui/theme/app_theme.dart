import 'package:flutter/material.dart';
import 'app_colors_extension.dart';

class AppTheme {
  // Spacing constants
  static const double space4 = 4.0;
  static const double space8 = 8.0;
  static const double space12 = 12.0;
  static const double space16 = 16.0;
  static const double space24 = 24.0;
  static const double space32 = 32.0;

  // Accessibility
  static const double minTouchTarget = 48.0;

  // Colors
  static const Color _seedColor = Color(0xFF6750A4); // Indigo/Purple seed

  static ThemeData get lightTheme {
    return ThemeData(
      useMaterial3: true,
      colorScheme: ColorScheme.fromSeed(
        seedColor: _seedColor,
        brightness: Brightness.light,
        // Ensure error is high contrast
        error: const Color(0xFFB3261E),
      ),
      appBarTheme: const AppBarTheme(centerTitle: true),
      extensions: [AppColorsExtension.light],
    );
  }

  static ThemeData get darkTheme {
    return ThemeData(
      useMaterial3: true,
      colorScheme: ColorScheme.fromSeed(
        seedColor: _seedColor,
        brightness: Brightness.dark,
        // Ensure error is high contrast
        error: const Color(0xFFF2B8B5),
      ),
      appBarTheme: const AppBarTheme(centerTitle: true),
      extensions: [AppColorsExtension.dark],
    );
  }
}
