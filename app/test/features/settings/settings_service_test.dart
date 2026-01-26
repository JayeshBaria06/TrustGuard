import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:trustguard/src/features/settings/services/settings_service.dart';

void main() {
  late SettingsService settingsService;
  late SharedPreferences prefs;

  setUp(() async {
    SharedPreferences.setMockInitialValues({});
    prefs = await SharedPreferences.getInstance();
    settingsService = SettingsService(prefs);
  });

  group('SettingsService', () {
    test('getRoundingDecimalPlaces returns default value of 2', () {
      expect(settingsService.getRoundingDecimalPlaces(), 2);
    });

    test('setRoundingDecimalPlaces updates value', () async {
      await settingsService.setRoundingDecimalPlaces(1);
      expect(settingsService.getRoundingDecimalPlaces(), 1);
      expect(prefs.getInt('rounding_decimal_places'), 1);
    });

    test('getRoundingDecimalPlaces returns stored value', () async {
      await prefs.setInt('rounding_decimal_places', 0);
      expect(settingsService.getRoundingDecimalPlaces(), 0);
    });
  });
}
