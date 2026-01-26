import 'package:flutter/services.dart';

/// Utilities for providing haptic feedback.
class HapticsService {
  /// Light tap for selection changes.
  static Future<void> lightTap() async {
    await HapticFeedback.lightImpact();
  }

  /// Success feedback for successful operations.
  static Future<void> success() async {
    await HapticFeedback.mediumImpact();
  }

  /// Warning feedback for confirmations or errors.
  static Future<void> warning() async {
    await HapticFeedback.heavyImpact();
  }

  /// Selection feedback for switches/toggles.
  static Future<void> selection() async {
    await HapticFeedback.selectionClick();
  }
}
