import 'package:shared_preferences/shared_preferences.dart';

class PurchasedFurnitureRepository {
  static const String _key = 'purchasedFurnitureIds';

  Future<Set<String>> loadPurchasedFurnitureIds() async {
    final prefs = await SharedPreferences.getInstance();

    final ids = prefs.getStringList(_key) ?? [];

    return ids.toSet();
  }

  Future<void> savePurchasedFurnitureIds(Set<String> furnitureIds) async {
    final prefs = await SharedPreferences.getInstance();

    await prefs.setStringList(_key, furnitureIds.toList());
  }

  Future<void> clear() async {
    final prefs = await SharedPreferences.getInstance();

    await prefs.remove(_key);
  }
}
