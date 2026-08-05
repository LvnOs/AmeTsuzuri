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

  Future<void> markAsRead(String letterId) async {
    _readLetterIds.add(letterId);

    await _repository.saveReadLetterIds(_readLetterIds);

    notifyListeners();
  }
}
