import 'package:shared_preferences/shared_preferences.dart';

class SettingsService {
  final SharedPreferences _prefs;

  SettingsService(this._prefs);

  static const String _roundingKey = 'rounding_decimal_places';
  static const String _customKeypadKey = 'custom_keypad_enabled';
  static const String _widgetUpdateEnabledKey = 'widget_update_enabled';

  int getRoundingDecimalPlaces() {
    return _prefs.getInt(_roundingKey) ?? 2;
  }

  Future<void> setRoundingDecimalPlaces(int value) async {
    await _prefs.setInt(_roundingKey, value);
  }

  bool isCustomKeypadEnabled() {
    return _prefs.getBool(_customKeypadKey) ?? true;
  }

  Future<void> setCustomKeypadEnabled(bool value) async {
    await _prefs.setBool(_customKeypadKey, value);
  }

  bool isWidgetUpdateEnabled() {
    return _prefs.getBool(_widgetUpdateEnabledKey) ?? true;
  }

  Future<void> setWidgetUpdateEnabled(bool value) async {
    await _prefs.setBool(_widgetUpdateEnabledKey, value);
  }
}
