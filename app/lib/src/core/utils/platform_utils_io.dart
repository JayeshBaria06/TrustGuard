import 'dart:io' show Platform;

/// IO implementation of platform detection.
/// This file is used on mobile and desktop platforms.

bool get isAndroid => Platform.isAndroid;
bool get isIOS => Platform.isIOS;
bool get isMacOS => Platform.isMacOS;
bool get isWindows => Platform.isWindows;
bool get isLinux => Platform.isLinux;
bool get isTestEnvironment => Platform.environment.containsKey('FLUTTER_TEST');
