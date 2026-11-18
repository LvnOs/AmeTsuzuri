import 'package:shared_preferences/shared_preferences.dart';

class AppDateRepository {
  static const String _key = 'prototypeDate';
  static const String _modeKey = 'prototypeDateModeEnabled';

  Future<DateTime?> load() async {
    final prefs = await SharedPreferences.getInstance();
    final savedDate = prefs.getString(_key);
    if (savedDate == null) {
      return null;
    }

    final date = DateTime.tryParse(savedDate);
    if (date == null) {
      return null;
    }

    return DateTime(date.year, date.month, date.day);
  }

  Future<void> save(DateTime date) async {
    final prefs = await SharedPreferences.getInstance();
    final normalizedDate = DateTime(date.year, date.month, date.day);
    final didSave = await prefs.setString(
      _key,
      normalizedDate.toIso8601String(),
    );
    if (!didSave) {
      throw StateError('Failed to save prototype date.');
    }
  }

  Future<bool?> loadPrototypeMode() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getBool(_modeKey);
  }

  Future<void> savePrototypeMode(bool enabled) async {
    final prefs = await SharedPreferences.getInstance();
    if (!await prefs.setBool(_modeKey, enabled)) {
      throw StateError('Failed to save date mode.');
    }
  }
}
