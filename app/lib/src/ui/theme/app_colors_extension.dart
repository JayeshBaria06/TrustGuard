import 'package:flutter/material.dart';

class AppColorsExtension extends ThemeExtension<AppColorsExtension> {
  const AppColorsExtension({required this.success, required this.onSuccess});

  final Color success;
  final Color onSuccess;

  @override
  ThemeExtension<AppColorsExtension> copyWith({
    Color? success,
    Color? onSuccess,
  }) {
    return AppColorsExtension(
      success: success ?? this.success,
      onSuccess: onSuccess ?? this.onSuccess,
    );
  }

  @override
  ThemeExtension<AppColorsExtension> lerp(
    ThemeExtension<AppColorsExtension>? other,
    double t,
  ) {
    if (other is! AppColorsExtension) {
      return this;
    }
    return AppColorsExtension(
      success: Color.lerp(success, other.success, t)!,
      onSuccess: Color.lerp(onSuccess, other.onSuccess, t)!,
    );
  }

  // Static constant for light theme
  static const light = AppColorsExtension(
    success: Color(0xFF1B5E20), // Green 900 - High contrast on white
    onSuccess: Colors.white,
  );

  // Static constant for dark theme
  static const dark = AppColorsExtension(
    success: Color(0xFF81C784), // Green 300 - High contrast on dark surface
    onSuccess: Colors.black,
  );

  // Static constant for high contrast light theme
  static const highContrastLight = AppColorsExtension(
    success: Color(0xFF004D40), // Dark Teal - Very high contrast
    onSuccess: Colors.white,
  );

  // Static constant for high contrast dark theme
  static const highContrastDark = AppColorsExtension(
    success: Color(0xFF69F0AE), // Green A200 - Very high contrast
    onSuccess: Colors.black,
  );
}
