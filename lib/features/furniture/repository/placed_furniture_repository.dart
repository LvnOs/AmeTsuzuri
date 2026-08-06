import 'dart:convert';

import 'package:shared_preferences/shared_preferences.dart';

class PlacedFurnitureRepository {
  static const String _key = 'placedFurnitureIds';

  Future<Map<String, String>> loadPlacedFurnitureIds() async {
    final prefs = await SharedPreferences.getInstance();

    final jsonString = prefs.getString(_key);

    if (jsonString == null || jsonString.isEmpty) {
      return {};
    }

    final decoded = jsonDecode(jsonString);

    if (decoded is! Map<String, dynamic>) {
      return {};
    }

    return decoded.map(
      (slotId, furnitureId) => MapEntry(slotId, furnitureId as String),
    );
  }

  Future<void> savePlacedFurnitureIds(
    Map<String, String> placedFurnitureIds,
  ) async {
    final prefs = await SharedPreferences.getInstance();

    final jsonString = jsonEncode(placedFurnitureIds);

    await prefs.setString(_key, jsonString);
  }

  Future<void> clear() async {
    final prefs = await SharedPreferences.getInstance();

    await prefs.remove(_key);
  }
}
