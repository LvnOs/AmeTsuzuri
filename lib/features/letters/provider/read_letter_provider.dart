import 'package:flutter/material.dart';

import '../model/read_letter_state.dart';
import '../repository/read_letter_repository.dart';

class ReadLetterProvider extends ChangeNotifier {
  ReadLetterProvider(this._repository);

  final ReadLetterRepository _repository;

  ReadLetterState _state = ReadLetterState(receivedLetters: {});
  bool _isLoaded = false;

  Set<String> get readLetterIds => _state.readLetterIds;
  Map<String, DateTime?> get receivedLetters => _state.receivedLetters;
  DateTime? receivedDateFor(String letterId) => receivedLetters[letterId];
  bool get isLoaded => _isLoaded;

  bool hasReceivedLetterOn(DateTime date) {
    return _state.receivedLetters.values.any((receivedDate) {
      return receivedDate != null &&
          receivedDate.year == date.year &&
          receivedDate.month == date.month &&
          receivedDate.day == date.day;
    });
  }

  Future<void> load() async {
    final state = await _repository.loadState();
    _state = state;
    _isLoaded = true;

    notifyListeners();
  }

  Future<bool> markAsRead(
    String letterId, {
    required DateTime receivedDate,
  }) async {
    if (_state.receivedLetters.containsKey(letterId)) {
      return false;
    }

    final normalizedDate = DateTime(
      receivedDate.year,
      receivedDate.month,
      receivedDate.day,
    );
    final nextState = ReadLetterState(
      receivedLetters: {
        ..._state.receivedLetters,
        letterId: normalizedDate,
      },
    );

    await _repository.saveState(nextState);

    _state = nextState;
    notifyListeners();

    return true;
  }

  Future<void> reset() async {
    await _repository.resetState();
    _state = ReadLetterState(receivedLetters: {});
    notifyListeners();
  }
}
