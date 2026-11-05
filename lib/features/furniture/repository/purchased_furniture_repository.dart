import 'package:shared_preferences/shared_preferences.dart';

typedef SetStringListOverride =
    Future<bool> Function(String key, List<String> value);

class PurchasedFurnitureRepository {
  PurchasedFurnitureRepository({this.setStringListOverride});

  static const String _key = 'purchasedFurnitureIds';

  final SetStringListOverride? setStringListOverride;

  Future<Set<String>> loadPurchasedFurnitureIds() async {
    final prefs = await SharedPreferences.getInstance();

    final ids = prefs.getStringList(_key) ?? [];

    return ids.toSet();
  }

  Future<void> savePurchasedFurnitureIds(Set<String> furnitureIds) async {
    final ids = furnitureIds.toList();
    final didSave = setStringListOverride != null
        ? await setStringListOverride!(_key, ids)
        : await (await SharedPreferences.getInstance()).setStringList(
            _key,
            ids,
          );
    if (!didSave) {
      throw StateError('Failed to save purchased furniture ids.');
    }
  }

  Future<void> clear() async {
    final prefs = await SharedPreferences.getInstance();

    await prefs.remove(_key);
  }
}
