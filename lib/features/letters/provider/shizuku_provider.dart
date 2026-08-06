import 'package:flutter/material.dart';
import '../repository/shizuku_repository.dart';

class ShizukuProvider extends ChangeNotifier {
  ShizukuProvider(this._repository);
  final ShizukuRepository _repository;
  int _currentShizuku = 0;
  int get currentShizuku => _currentShizuku;

  Future<void> load() async {
    _currentShizuku = await _repository.loadCurrentShizuku();

    notifyListeners();
  }

  Future<void> addShizuku(int amount) async {
    _currentShizuku += amount;

    await _repository.saveCurrentShizuku(_currentShizuku);

    notifyListeners();
  }

  Future<bool> consumeShizuku(int amount) async {
    if (amount <= 0) {
      return false;
    }

    if (_currentShizuku < amount) {
      return false;
    }
    _currentShizuku -= amount;

    await _repository.saveCurrentShizuku(_currentShizuku);

    notifyListeners();
    return true;
  }

  Future<void> reset() async {
    await _repository.clear();
    _currentShizuku = 0;
    notifyListeners();
  }
}
