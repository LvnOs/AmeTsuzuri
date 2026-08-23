import 'package:flutter/material.dart';

import '../model/read_letter_state.dart';
import '../repository/read_letter_repository.dart';

class ReadLetterProvider extends ChangeNotifier {
  ReadLetterProvider(this._repository);

  final ReadLetterRepository _repository;

  ReadLetterState _state = ReadLetterState(receivedLetters: {});
  bool _isLoaded = false;
  Future<void>? _loadFuture;

  Set<String> get readLetterIds => _state.readLetterIds;
  Map<String, DateTime?> get receivedLetters => _state.receivedLetters;
  Map<String, String> get deliveredLetters => _state.deliveredLetters;
  DateTime? receivedDateFor(String letterId) => receivedLetters[letterId];
  bool get isLoaded => _isLoaded;

  String? deliveredLetterIdOn(DateTime date) {
    return _state.deliveredLetters[_formatDate(date)];
  }

  bool hasDeliveredLetterOn(DateTime date) {
    return deliveredLetterIdOn(date) != null;
  }

  String? receivedLetterIdOn(DateTime date) {
    for (final entry in _state.receivedLetters.entries) {
      final receivedDate = entry.value;
      if (receivedDate != null &&
          receivedDate.year == date.year &&
          receivedDate.month == date.month &&
          receivedDate.day == date.day) {
        return entry.key;
      }
    }
    return null;
  }

  bool hasReceivedLetterOn(DateTime date) {
    return receivedLetterIdOn(date) != null;
  }

  Future<void> load() {
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
      deliveredLetters: _state.deliveredLetters,
    );

    await _repository.saveState(nextState);

    _state = nextState;
    notifyListeners();

    return true;
  }

  Future<bool> deliver(
    String letterId, {
    required DateTime deliveredDate,
  }) async {
    final dateKey = _formatDate(deliveredDate);
    if (_state.deliveredLetters.containsKey(dateKey)) {
      return false;
    }

    final nextState = ReadLetterState(
      receivedLetters: _state.receivedLetters,
      deliveredLetters: {..._state.deliveredLetters, dateKey: letterId},
    );

    await _repository.saveState(nextState);

    _state = nextState;
    notifyListeners();

    return true;
  }

  Future<void> reset() async {
    await _repository.resetState();
    _state = ReadLetterState(receivedLetters: {}, deliveredLetters: {});
    notifyListeners();
  }

  String _formatDate(DateTime date) {
    final year = date.year.toString().padLeft(4, '0');
    final month = date.month.toString().padLeft(2, '0');
    final day = date.day.toString().padLeft(2, '0');
    return '$year-$month-$day';
  }
}
