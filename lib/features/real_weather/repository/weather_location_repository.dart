import 'package:shared_preferences/shared_preferences.dart';

enum WeatherLocationSetting { off, enabled, retryRequired }

class WeatherLocationRepository {
  static const _key = 'weatherLocationSetting';

  Future<WeatherLocationSetting> load() async {
    final prefs = await SharedPreferences.getInstance();
    final saved = prefs.get(_key);
    return WeatherLocationSetting.values.firstWhere(
      (setting) => setting.name == saved,
      orElse: () => WeatherLocationSetting.off,
    );
  }

  Future<void> save(WeatherLocationSetting setting) async {
    final prefs = await SharedPreferences.getInstance();
    if (!await prefs.setString(_key, setting.name)) {
      throw StateError('Failed to save the weather location setting.');
    }
  }
}
