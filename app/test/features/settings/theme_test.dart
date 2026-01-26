import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:trustguard/src/features/settings/services/theme_service.dart';
import 'package:trustguard/src/features/settings/providers/theme_providers.dart';
import 'package:trustguard/src/app/providers.dart';

void main() {
  group('ThemeMode functionality', () {
    late SharedPreferences prefs;
    late ThemeService themeService;

    setUp(() async {
      SharedPreferences.setMockInitialValues({});
      prefs = await SharedPreferences.getInstance();
      themeService = ThemeService(prefs);
    });

    group('ThemeService', () {
      test('getThemeMode returns system by default', () {
        expect(themeService.getThemeMode(), ThemeModePreference.system);
      });

      test('setThemeMode stores the value in SharedPreferences', () async {
        await themeService.setThemeMode(ThemeModePreference.dark);
        expect(prefs.getString('theme_mode'), 'dark');
      });

      test('getThemeMode returns the stored value', () async {
        await prefs.setString('theme_mode', 'light');
        expect(themeService.getThemeMode(), ThemeModePreference.light);
      });

      test('getThemeMode returns system if stored value is invalid', () async {
        await prefs.setString('theme_mode', 'invalid');
        expect(themeService.getThemeMode(), ThemeModePreference.system);
      });

      test('toFlutterThemeMode converts correctly', () {
        expect(
          themeService.toFlutterThemeMode(ThemeModePreference.system),
          ThemeMode.system,
        );
        expect(
          themeService.toFlutterThemeMode(ThemeModePreference.light),
          ThemeMode.light,
        );
        expect(
          themeService.toFlutterThemeMode(ThemeModePreference.dark),
          ThemeMode.dark,
        );
      });
    });

    group('ThemeProviders', () {
      test('themeStateProvider initializes with default value', () async {
        final container = ProviderContainer(
          overrides: [sharedPreferencesProvider.overrideWithValue(prefs)],
        );
        addTearDown(container.dispose);

        expect(
          container.read(themeStateProvider).currentMode,
          ThemeModePreference.system,
        );
      });

      test('themeStateProvider initializes with stored value', () async {
        await prefs.setString('theme_mode', 'dark');

        final container = ProviderContainer(
          overrides: [sharedPreferencesProvider.overrideWithValue(prefs)],
        );
        addTearDown(container.dispose);

        expect(
          container.read(themeStateProvider).currentMode,
          ThemeModePreference.dark,
        );
      });

      test('setThemeMode updates state and persists', () async {
        final container = ProviderContainer(
          overrides: [sharedPreferencesProvider.overrideWithValue(prefs)],
        );
        addTearDown(container.dispose);

        await container
            .read(themeStateProvider.notifier)
            .setThemeMode(ThemeModePreference.light);

        expect(
          container.read(themeStateProvider).currentMode,
          ThemeModePreference.light,
        );
        expect(prefs.getString('theme_mode'), 'light');
      });
    });

    group('Theme Integration', () {
      testWidgets('MaterialApp receives correct ThemeMode from provider', (
        tester,
      ) async {
        SharedPreferences.setMockInitialValues({'theme_mode': 'dark'});
        final prefs = await SharedPreferences.getInstance();

        await tester.pumpWidget(
          ProviderScope(
            overrides: [sharedPreferencesProvider.overrideWithValue(prefs)],
            child: Consumer(
              builder: (context, ref, child) {
                final themeModePref = ref.watch(themeStateProvider).currentMode;
                final themeService = ref.read(themeServiceProvider);
                return MaterialApp(
                  themeMode: themeService.toFlutterThemeMode(themeModePref),
                  home: const Scaffold(),
                );
              },
            ),
          ),
        );

        final MaterialApp app = tester.widget(find.byType(MaterialApp));
        expect(app.themeMode, ThemeMode.dark);

        // Update theme
        final container = ProviderScope.containerOf(
          tester.element(find.byType(Scaffold)),
        );
        await container
            .read(themeStateProvider.notifier)
            .setThemeMode(ThemeModePreference.light);
        await tester.pump();

        final MaterialApp appUpdated = tester.widget(find.byType(MaterialApp));
        expect(appUpdated.themeMode, ThemeMode.light);
      });
    });
  });
}
