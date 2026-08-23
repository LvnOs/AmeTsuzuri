import 'package:flutter/material.dart';

import '../model/shizuku_state.dart';
import '../repository/shizuku_repository.dart';

enum LetterRewardStatus { rewarded, alreadyRewarded }

class LetterRewardResult {
  const LetterRewardResult({required this.status, required this.amount});

  final LetterRewardStatus status;
  final int amount;
}

class ShizukuProvider extends ChangeNotifier {
  ShizukuProvider(this._repository);
  static const String _tutorialLetterId = 'tutorial_001';
  static const int _tutorialLetterReward = 30;
  static const int _normalLetterReward = 10;
  static const String _prototypeBottleTestIdPrefix = '__prototype_bottle_test_';

  final ShizukuRepository _repository;
  int _currentShizuku = 0;
  Set<String> _rewardedLetterIds = {};
  bool _isLoaded = false;
  final Map<String, Future<LetterRewardResult>> _pendingLetterRewards = {};

  int get currentShizuku => _currentShizuku;
  Set<String> get rewardedLetterIds => Set.unmodifiable(_rewardedLetterIds);
  bool get isLoaded => _isLoaded;
  int get bottleRecordCount => _rewardedLetterIds.length;
  int get fullBottleCount => bottleRecordCount ~/ 30;
  int get currentBottleProgress => bottleRecordCount % 30;

  Future<void> load() async {
    final state = await _repository.loadState();
    _currentShizuku = state.currentShizuku;
    _rewardedLetterIds = Set.of(state.rewardedLetterIds);
    _isLoaded = true;

    notifyListeners();
  }

  Future<void> addShizuku(int amount) async {
    final nextState = ShizukuState(
      currentShizuku: _currentShizuku + amount,
      rewardedLetterIds: Set.of(_rewardedLetterIds),
    );

    await _repository.saveState(nextState);

    _applyState(nextState);
    notifyListeners();
  }

  Future<void> prepareNextBottleForPrototype() async {
    if (currentBottleProgress == 29) {
      return;
    }

    final nextRewardedLetterIds = Set<String>.of(_rewardedLetterIds);
    final targetCount = (bottleRecordCount ~/ 30) * 30 + 29;
    var index = 0;

    while (nextRewardedLetterIds.length < targetCount) {
      final suffix = index.toString().padLeft(3, '0');
      nextRewardedLetterIds.add('$_prototypeBottleTestIdPrefix${suffix}__');
      index++;
    }

    final nextState = ShizukuState(
      currentShizuku: _currentShizuku,
      rewardedLetterIds: nextRewardedLetterIds,
    );

    await _repository.saveState(nextState);

    _applyState(nextState);
    notifyListeners();
  }

  Future<LetterRewardResult> rewardForLetter(String letterId) {
    if (_rewardedLetterIds.contains(letterId)) {
      return Future.value(
        const LetterRewardResult(
          status: LetterRewardStatus.alreadyRewarded,
          amount: 0,
        ),
      );
    }

    final pendingReward = _pendingLetterRewards[letterId];
    if (pendingReward != null) {
      return pendingReward;
    }

    final operation = _rewardForLetterWithCleanup(letterId);
    _pendingLetterRewards[letterId] = operation;
    return operation;
  }

  Future<LetterRewardResult> _rewardForLetterWithCleanup(
    String letterId,
  ) async {
    try {
      return await _saveLetterReward(letterId);
    } finally {
      _pendingLetterRewards.remove(letterId);
    }
  }

  Future<LetterRewardResult> _saveLetterReward(String letterId) async {
    final amount = letterId == _tutorialLetterId
        ? _tutorialLetterReward
        : _normalLetterReward;
    final nextRewardedLetterIds = Set<String>.of(_rewardedLetterIds)
      ..add(letterId);
    final nextState = ShizukuState(
      currentShizuku: _currentShizuku + amount,
      rewardedLetterIds: nextRewardedLetterIds,
    );

    await _repository.saveState(nextState);

    _applyState(nextState);
    notifyListeners();

    return LetterRewardResult(
      status: LetterRewardStatus.rewarded,
      amount: amount,
    );
  }

  Future<bool> consumeShizuku(int amount) async {
    if (amount <= 0) {
      return false;
    }

    if (_currentShizuku < amount) {
      return false;
    }
    final nextState = ShizukuState(
      currentShizuku: _currentShizuku - amount,
      rewardedLetterIds: Set.of(_rewardedLetterIds),
    );

    await _repository.saveState(nextState);

    _applyState(nextState);
    notifyListeners();
    return true;
  }

  Future<void> reset() async {
    await _repository.resetState();
    _applyState(
      const ShizukuState(
        currentShizuku: ShizukuRepository.initialShizuku,
        rewardedLetterIds: {},
      ),
    );
    notifyListeners();
  }

  void _applyState(ShizukuState state) {
    _currentShizuku = state.currentShizuku;
    _rewardedLetterIds = Set.of(state.rewardedLetterIds);
  }
}
