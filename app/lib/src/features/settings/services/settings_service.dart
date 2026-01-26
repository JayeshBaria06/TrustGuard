import 'package:shared_preferences/shared_preferences.dart';

class SettingsService {
  final SharedPreferences _prefs;

  SettingsService(this._prefs);

  static const String _roundingKey = 'rounding_decimal_places';

  int getRoundingDecimalPlaces() {
    return _prefs.getInt(_roundingKey) ?? 2;
  }

  Future<void> setRoundingDecimalPlaces(int value) async {
    await _prefs.setInt(_roundingKey, value);
  }
}
