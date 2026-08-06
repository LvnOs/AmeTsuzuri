import 'package:flutter/material.dart';

import '../../letters/provider/shizuku_provider.dart';
import '../model/furniture.dart';
import '../repository/purchased_furniture_repository.dart';

enum FurniturePurchaseResult { success, alreadyPurchased, notEnoughShizuku }

class CatalogProvider extends ChangeNotifier {
  CatalogProvider(this._repository);

  final PurchasedFurnitureRepository _repository;

  Set<String> _purchasedFurnitureIds = {};

  Set<String> get purchasedFurnitureIds =>
      Set.unmodifiable(_purchasedFurnitureIds);

  bool isPurchased(String furnitureId) {
    return _purchasedFurnitureIds.contains(furnitureId);
  }

  Future<void> load() async {
    _purchasedFurnitureIds = await _repository.loadPurchasedFurnitureIds();

    notifyListeners();
  }

  Future<FurniturePurchaseResult> buy({
    required Furniture furniture,
    required ShizukuProvider shizukuProvider,
  }) async {
    if (isPurchased(furniture.id)) {
      return FurniturePurchaseResult.alreadyPurchased;
    }

    final paymentSucceeded = await shizukuProvider.consumeShizuku(
      furniture.price,
    );

    if (!paymentSucceeded) {
      return FurniturePurchaseResult.notEnoughShizuku;
    }

    _purchasedFurnitureIds.add(furniture.id);

    await _repository.savePurchasedFurnitureIds(_purchasedFurnitureIds);

    notifyListeners();

    return FurniturePurchaseResult.success;
  }

  Future<void> reset() async {
    await _repository.clear();

    _purchasedFurnitureIds = {};

    notifyListeners();
  }
}
