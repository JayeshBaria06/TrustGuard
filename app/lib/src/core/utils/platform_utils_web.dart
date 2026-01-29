// Web implementation of platform detection.
// This file is used on web platform where dart:io is not available.
// All platform checks return false on web.

bool get isAndroid => false;
bool get isIOS => false;
bool get isMacOS => false;
bool get isWindows => false;
bool get isLinux => false;
bool get isTestEnvironment => false;
