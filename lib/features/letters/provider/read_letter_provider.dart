import 'package:flutter/material.dart';
import '../repository/read_letter_repository.dart';

class ReadLetterProvider extends ChangeNotifier {
  ReadLetterProvider(this._repository);

  final ReadLetterRepository _repository;

  Set<String> _readLetterIds = {};

  Set<String> get readLetterIds => _readLetterIds;

  Future<void> load() async {
    _readLetterIds = await _repository.loadReadLetterIds();

    notifyListeners();
  }

  Future<bool> markAsRead(String letterId) async {
    if (_readLetterIds.contains(letterId)) {
      return false;
    }

    _readLetterIds.add(letterId);

    await _repository.saveReadLetterIds(_readLetterIds);

    notifyListeners();

    return true;
  }

  Future<void> reset() async {
    await _repository.clear();
    _readLetterIds = {};
    notifyListeners();
  }
}
