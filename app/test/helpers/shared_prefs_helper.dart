import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:trustguard/src/app/providers.dart';

Future<List<Override>> getSharedPrefsOverride({
  bool onboardingComplete = true,
}) async {
  SharedPreferences.setMockInitialValues({
    'onboarding_complete': onboardingComplete,
  });
  final prefs = await SharedPreferences.getInstance();
  return [sharedPreferencesProvider.overrideWithValue(prefs)];
}
