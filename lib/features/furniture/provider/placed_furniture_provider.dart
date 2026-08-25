import 'package:flutter/material.dart';

import '../repository/placed_furniture_repository.dart';

enum PlaceFurnitureResult { success, notPurchased, invalidSlot }

class PlacedFurnitureProvider extends ChangeNotifier {
  PlacedFurnitureProvider(this._repository);

  final PlacedFurnitureRepository _repository;

  Map<String, String> _placedFurnitureIds = {};
  bool _isLoaded = false;
  Future<void>? _loadFuture;

  Map<String, String> get placedFurnitureIds =>
      Map.unmodifiable(_placedFurnitureIds);
  bool get isLoaded => _isLoaded;

  Future<void> load() {
    if (_isLoaded) {
      return Future.value();
    }
    final pendingLoad = _loadFuture;
    if (pendingLoad != null) {
      return pendingLoad;
    }

    late final Future<void> operation;
    operation = _loadInternal().whenComplete(() {
      if (identical(_loadFuture, operation)) {
        _loadFuture = null;
      }
    });
    _loadFuture = operation;
    return operation;
  }

  Future<void> _loadInternal() async {
    _placedFurnitureIds = await _repository.loadPlacedFurnitureIds();
    _isLoaded = true;

    notifyListeners();
  }

  Future<PlaceFurnitureResult> place({
    required String slotId,
    required String furnitureId,
    required bool isPurchased,
    required List<String> allowedSlotIds,
  }) async {
    if (!isPurchased) {
      return PlaceFurnitureResult.notPurchased;
    }

    if (!allowedSlotIds.contains(slotId)) {
      return PlaceFurnitureResult.invalidSlot;
    }

    final currentSlotIds = _placedFurnitureIds.entries
        .where((entry) => entry.value == furnitureId)
        .map((entry) => entry.key)
        .toList();
    if (currentSlotIds.length == 1 && currentSlotIds.single == slotId) {
      return PlaceFurnitureResult.success;
    }

    final updatedPlacedFurnitureIds = Map<String, String>.from(
      _placedFurnitureIds,
    );

    updatedPlacedFurnitureIds.removeWhere(
      (_, placedFurnitureId) => placedFurnitureId == furnitureId,
    );

    updatedPlacedFurnitureIds[slotId] = furnitureId;

    await _repository.savePlacedFurnitureIds(updatedPlacedFurnitureIds);

    _placedFurnitureIds = updatedPlacedFurnitureIds;

    notifyListeners();

    return PlaceFurnitureResult.success;
  }

  Future<void> remove(String furnitureId) async {
    final slotId = getSlotIdByFurnitureId(furnitureId);
    if (slotId == null) {
      return;
    }

    final updatedPlacedFurnitureIds = Map<String, String>.from(
      _placedFurnitureIds,
    )..remove(slotId);

    await _repository.savePlacedFurnitureIds(updatedPlacedFurnitureIds);

    _placedFurnitureIds = updatedPlacedFurnitureIds;

    notifyListeners();
  }

  String? getSlotIdByFurnitureId(String furnitureId) {
    for (final entry in _placedFurnitureIds.entries) {
      if (entry.value == furnitureId) {
        return entry.key;
      }
    }

    return null;
  }

  Future<void> reset() async {
    await _repository.clear();

    _placedFurnitureIds = {};

    notifyListeners();
  }
}
