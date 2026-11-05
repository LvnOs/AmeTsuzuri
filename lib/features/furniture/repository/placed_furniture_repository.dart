import 'dart:convert';

import 'package:shared_preferences/shared_preferences.dart';

typedef PlacedFurnitureSetStringOverride =
    Future<bool> Function(String key, String value);
typedef PlacedFurnitureRemoveOverride = Future<bool> Function(String key);

class PlacedFurnitureRepository {
  PlacedFurnitureRepository({this.setStringOverride, this.removeOverride});

  static const String _key = 'placedFurnitureIds';

  final PlacedFurnitureSetStringOverride? setStringOverride;
  final PlacedFurnitureRemoveOverride? removeOverride;

  Future<Map<String, String>> loadPlacedFurnitureIds() async {
    final prefs = await SharedPreferences.getInstance();

    final savedValue = prefs.get(_key);

    if (savedValue is! String || savedValue.isEmpty) {
      return {};
    }

    late final Object? decoded;
    try {
      decoded = jsonDecode(savedValue);
    } on FormatException {
      return {};
    }

    if (decoded is! Map) {
      return {};
    }

    return {
      for (final entry in decoded.entries)
        if (entry.key is String && entry.value is String)
          entry.key as String: entry.value as String,
    };
  }

  Future<void> savePlacedFurnitureIds(
    Map<String, String> placedFurnitureIds,
  ) async {
    final jsonString = jsonEncode(placedFurnitureIds);
    final didSave = setStringOverride != null
        ? await setStringOverride!(_key, jsonString)
        : await (await SharedPreferences.getInstance()).setString(
            _key,
            jsonString,
          );
    if (!didSave) {
      throw StateError('Failed to save placed furniture ids.');
    }
  }

  Future<void> clear() async {
    final didClear = removeOverride != null
        ? await removeOverride!(_key)
        : await (await SharedPreferences.getInstance()).remove(_key);
    if (!didClear) {
      throw StateError('Failed to clear placed furniture ids.');
    }
  }
}
