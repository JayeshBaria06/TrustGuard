import 'package:flutter/foundation.dart' show kIsWeb;

// Conditionally import dart:io only on non-web platforms
import 'platform_utils_io.dart'
    if (dart.library.html) 'platform_utils_web.dart'
    as platform_impl;

/// Safe platform detection utilities that work across all platforms including web.
///
/// These utilities prevent crashes on web where dart:io's Platform class
/// is not available.
class PlatformUtils {
  PlatformUtils._();

  /// Whether the app is running on the web platform.
  static bool get isWeb => kIsWeb;

  /// Whether the app is running on Android.
  /// Returns false on web.
  static bool get isAndroid => platform_impl.isAndroid;

  /// Whether the app is running on iOS.
  /// Returns false on web.
  static bool get isIOS => platform_impl.isIOS;

  /// Whether the app is running on macOS.
  /// Returns false on web.
  static bool get isMacOS => platform_impl.isMacOS;

  /// Whether the app is running on Windows.
  /// Returns false on web.
  static bool get isWindows => platform_impl.isWindows;

  /// Whether the app is running on Linux.
  /// Returns false on web.
  static bool get isLinux => platform_impl.isLinux;

  /// Whether the app is running on a mobile platform (Android or iOS).
  /// Returns false on web.
  static bool get isMobile => !kIsWeb && (isAndroid || isIOS);

  /// Whether the app is running on a desktop platform (macOS, Windows, or Linux).
  /// Returns false on web.
  static bool get isDesktop => !kIsWeb && (isMacOS || isWindows || isLinux);

  /// Whether the platform supports camera-based features (QR scanning, OCR).
  /// Currently only mobile platforms have full camera support.
  static bool get supportsCameraFeatures => isMobile;

  /// Whether the platform supports home screen widgets.
  /// Currently only Android and iOS.
  static bool get supportsHomeWidgets => isMobile;

  /// Whether the platform supports local notifications.
  /// Desktop support is limited.
  static bool get supportsNotifications => isMobile || isDesktop;

  /// Whether the platform supports biometric authentication.
  static bool get supportsBiometrics => isMobile || isWindows || isMacOS;

  /// Whether the platform supports native file system access.
  static bool get supportsFileSystem => !kIsWeb;

  /// Safely checks if the app is running in a Flutter test environment.
  /// Returns false on web (where Platform.environment is not available).
  static bool get isTestEnvironment => platform_impl.isTestEnvironment;
}
