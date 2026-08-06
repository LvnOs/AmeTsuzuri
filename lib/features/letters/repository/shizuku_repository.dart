import 'package:shared_preferences/shared_preferences.dart';

class ShizukuRepository {
  static const String _key = 'currentShizuku';

  Future<int> loadCurrentShizuku() async {
    final prefs = await SharedPreferences.getInstance();
    final currentShizuku = prefs.getInt(_key) ?? 0;

    return currentShizuku;
  }

  Future<void> saveCurrentShizuku(int shizuku) async {
    final prefs = await SharedPreferences.getInstance();

    await prefs.setInt(_key, shizuku);
  }

  Future<void> clear() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_key);
  }
}
