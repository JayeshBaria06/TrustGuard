import 'package:flutter/material.dart';

class ChartTheme {
  // Animation durations
  static const Duration defaultAnimationDuration = Duration(milliseconds: 300);
  static const Duration longAnimationDuration = Duration(milliseconds: 500);

  // Colors for chart segments - high contrast and distinct
  static const List<Color> _baseSegmentColors = [
    Color(0xFF6750A4), // Primary Purple
    Color(0xFF03A9F4), // Light Blue
    Color(0xFF4CAF50), // Green
    Color(0xFFFF9800), // Orange
    Color(0xFFE91E63), // Pink
    Color(0xFF009688), // Teal
    Color(0xFFFFC107), // Amber
    Color(0xFF795548), // Brown (was Purple)
  ];

  static List<Color> getChartColors(ThemeData theme) {
    // These colors are designed to work in both light and dark themes.
    return _baseSegmentColors;
  }

  static Color getGridLineColor(ThemeData theme) {
    return theme.dividerColor.withValues(alpha: 0.2);
  }

  static TextStyle getLabelStyle(ThemeData theme) {
    return theme.textTheme.labelSmall!.copyWith(
      fontWeight: FontWeight.bold,
      color: theme.colorScheme.onSurface,
    );
  }

  static TextStyle getLegendStyle(ThemeData theme) {
    return theme.textTheme.bodySmall!;
  }

  static TextStyle getTooltipStyle(ThemeData theme) {
    return theme.textTheme.bodyMedium!.copyWith(fontWeight: FontWeight.bold);
  }
}
