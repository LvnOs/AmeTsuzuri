import 'package:flutter/material.dart';

import '../repository/placed_furniture_repository.dart';

class PlacedFurnitureProvider extends ChangeNotifier {
  PlacedFurnitureProvider(this._repository);

  final PlacedFurnitureRepository _repository;

  Map<String, String> _placedFurnitureIds = {};

  Map<String, String> get placedFurnitureIds =>
      Map.unmodifiable(_placedFurnitureIds);

  Future<void> load() async {
    _placedFurnitureIds = await _repository.loadPlacedFurnitureIds();

    notifyListeners();
  }

  Future<void> place({
    required String slotId,
    required String furnitureId,
  }) async {
    _placedFurnitureIds[slotId] = furnitureId;

    await _repository.savePlacedFurnitureIds(_placedFurnitureIds);

    notifyListeners();
  }

  Future<void> reset() async {
    await _repository.clear();

    _placedFurnitureIds = {};

    notifyListeners();
  }
}
