import 'package:flutter/material.dart';

import '../../letters/provider/shizuku_provider.dart';
import '../model/furniture.dart';
import '../repository/purchased_furniture_repository.dart';

enum FurniturePurchaseResult {
  success,
  alreadyPurchased,
  notEnoughShizuku,
  purchaseInProgress,
}

class CatalogProvider extends ChangeNotifier {
  CatalogProvider(this._repository);

  final PurchasedFurnitureRepository _repository;

  Set<String> _purchasedFurnitureIds = {};
  bool _isLoaded = false;
  Future<void>? _loadFuture;
  bool _isPurchasing = false;
  String? _purchasingFurnitureId;

  Set<String> get purchasedFurnitureIds =>
      Set.unmodifiable(_purchasedFurnitureIds);
  bool get isLoaded => _isLoaded;
  bool get isPurchasing => _isPurchasing;
  String? get purchasingFurnitureId => _purchasingFurnitureId;

  bool isPurchased(String furnitureId) {
    return _purchasedFurnitureIds.contains(furnitureId);
  }

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
    _purchasedFurnitureIds = await _repository.loadPurchasedFurnitureIds();
    _isLoaded = true;

    notifyListeners();
  }

  Future<FurniturePurchaseResult> buy({
    required Furniture furniture,
    required ShizukuProvider shizukuProvider,
  }) async {
    if (_isPurchasing) {
      return FurniturePurchaseResult.purchaseInProgress;
    }

    if (isPurchased(furniture.id)) {
      return FurniturePurchaseResult.alreadyPurchased;
    }

    _isPurchasing = true;
    _purchasingFurnitureId = furniture.id;
    notifyListeners();

    try {
      final paymentSucceeded = await shizukuProvider.consumeShizuku(
        furniture.price,
      );

      if (!paymentSucceeded) {
        return FurniturePurchaseResult.notEnoughShizuku;
      }

      _purchasedFurnitureIds.add(furniture.id);

      await _repository.savePurchasedFurnitureIds(_purchasedFurnitureIds);

      return FurniturePurchaseResult.success;
    } finally {
      _isPurchasing = false;
      _purchasingFurnitureId = null;
      notifyListeners();
    }
  }

  Future<void> reset() async {
    await _repository.clear();

    _purchasedFurnitureIds = {};

    notifyListeners();
  }
}
