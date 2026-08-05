import 'package:shared_preferences/shared_preferences.dart';

class ReadLetterRepository {
  static const String _key = 'readLetterIds';

  Future<Set<String>> loadReadLetterIds() async {
    final prefs = await SharedPreferences.getInstance();
    final ids = prefs.getStringList(_key) ?? [];

    return ids.toSet();
  }

  Future<void> saveReadLetterIds(Set<String> ids) async {
    final prefs = await SharedPreferences.getInstance();

    await prefs.setStringList(_key, ids.toList());
  }
}
