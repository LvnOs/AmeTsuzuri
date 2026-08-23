import 'dart:async';

import 'package:ame_tsuzuri/features/letters/model/shizuku_state.dart';
import 'package:ame_tsuzuri/features/letters/provider/shizuku_provider.dart';
import 'package:ame_tsuzuri/features/letters/repository/shizuku_repository.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('進行中のloadは同じFutureを共有してRepositoryを一度だけ読む', () async {
    final repository = _BlockingLoadShizukuRepository();
    final provider = ShizukuProvider(repository);

    final first = provider.load();
    final second = provider.load();

    expect(identical(first, second), isTrue);
    expect(repository.loadCallCount, 1);

    repository.completeLoad(_initialState);
    await Future.wait([first, second]);

    expect(provider.isLoaded, isTrue);
  });

  test('load失敗後は再度Repositoryを読み込める', () async {
    final repository = _BlockingLoadShizukuRepository();
    final provider = ShizukuProvider(repository);

    final failedLoad = provider.load();
    repository.failLoad(StateError('load failed'));
    await expectLater(failedLoad, throwsA(isA<StateError>()));

    expect(provider.isLoaded, isFalse);

    final retry = provider.load();
    expect(repository.loadCallCount, 2);
    repository.completeLoad(
      const ShizukuState(currentShizuku: 40, rewardedLetterIds: {'letterA'}),
    );
    await retry;

    expect(provider.isLoaded, isTrue);
    expect(provider.currentShizuku, 40);
    expect(provider.rewardedLetterIds, {'letterA'});
  });

  test('load成功後の再呼び出しではRepositoryを再読込しない', () async {
    final repository = _FakeShizukuRepository(_initialState);
    final provider = ShizukuProvider(repository);

    await provider.load();
    await provider.load();

    expect(repository.loadCallCount, 1);
    expect(provider.isLoaded, isTrue);
  });

  test('新規状態を0滴でロードする', () async {
    final provider = await _loadProvider(_FakeShizukuRepository(_initialState));

    expect(provider.currentShizuku, 0);
    expect(provider.rewardedLetterIds, isEmpty);
  });

  test('loadで残高と報酬受取済みIDを読み込む', () async {
    final repository = _FakeShizukuRepository(
      const ShizukuState(currentShizuku: 40, rewardedLetterIds: {'letterA'}),
    );
    final provider = ShizukuProvider(repository);

    await provider.load();

    expect(provider.currentShizuku, 40);
    expect(provider.rewardedLetterIds, {'letterA'});
    expect(provider.isLoaded, isTrue);
  });

  test('最初の手紙には10滴を1回の保存で付与する', () async {
    final repository = _FakeShizukuRepository(_initialState);
    final provider = await _loadProvider(repository);

    final result = await provider.rewardForLetter('letterA');

    expect(result.status, LetterRewardStatus.rewarded);
    expect(result.amount, 10);
    expect(provider.currentShizuku, 10);
    expect(provider.rewardedLetterIds, {'letterA'});
    expect(repository.saveCallCount, 1);
  });

  test('tutorial_001の初回報酬は30滴で瓶進捗は1通分になる', () async {
    final repository = _FakeShizukuRepository(_initialState);
    final provider = await _loadProvider(repository);

    final result = await provider.rewardForLetter('tutorial_001');

    expect(result.status, LetterRewardStatus.rewarded);
    expect(result.amount, 30);
    expect(provider.currentShizuku, 30);
    expect(provider.rewardedLetterIds, {'tutorial_001'});
    expect(provider.bottleRecordCount, 1);
    expect(provider.currentBottleProgress, 1);
    expect(repository.saveCallCount, 1);
  });

  test('tutorial_001の再報酬は0滴で状態を変更しない', () async {
    final repository = _FakeShizukuRepository(
      const ShizukuState(
        currentShizuku: 30,
        rewardedLetterIds: {'tutorial_001'},
      ),
    );
    final provider = await _loadProvider(repository);

    final result = await provider.rewardForLetter('tutorial_001');

    expect(result.status, LetterRewardStatus.alreadyRewarded);
    expect(result.amount, 0);
    expect(provider.currentShizuku, 30);
    expect(provider.rewardedLetterIds, {'tutorial_001'});
    expect(repository.saveCallCount, 0);
  });

  test('tutorial_001と通常手紙の初回報酬は合計40滴になる', () async {
    final repository = _FakeShizukuRepository(_initialState);
    final provider = await _loadProvider(repository);

    await provider.rewardForLetter('tutorial_001');
    await provider.rewardForLetter('letterA');

    expect(provider.currentShizuku, 40);
    expect(provider.rewardedLetterIds, {'tutorial_001', 'letterA'});
    expect(provider.bottleRecordCount, 2);
    expect(repository.saveCallCount, 2);
  });

  test('tutorial_001の報酬保存失敗時は状態を変更しない', () async {
    final repository = _FakeShizukuRepository(_initialState)
      ..saveError = StateError('save failed');
    final provider = await _loadProvider(repository);

    await expectLater(
      provider.rewardForLetter('tutorial_001'),
      throwsA(isA<StateError>()),
    );

    expect(provider.currentShizuku, 0);
    expect(provider.rewardedLetterIds, isEmpty);
    expect(provider.bottleRecordCount, 0);
  });

  test('tutorial_001の並行報酬は30滴を二重付与しない', () async {
    final repository = _BlockingShizukuRepository();
    final provider = await _loadProvider(repository);

    final first = provider.rewardForLetter('tutorial_001');
    final second = provider.rewardForLetter('tutorial_001');

    expect(repository.saveCallCount, 1);
    repository.completeSave();

    final results = await Future.wait([first, second]);
    expect(results.every((result) => result.amount == 30), isTrue);
    expect(provider.currentShizuku, 30);
    expect(provider.rewardedLetterIds, {'tutorial_001'});
    expect(repository.saveCallCount, 1);
  });

  test('2通目の手紙には10滴を付与する', () async {
    final repository = _FakeShizukuRepository(
      const ShizukuState(currentShizuku: 40, rewardedLetterIds: {'letterA'}),
    );
    final provider = await _loadProvider(repository);

    final result = await provider.rewardForLetter('letterB');

    expect(result.status, LetterRewardStatus.rewarded);
    expect(result.amount, 10);
    expect(provider.currentShizuku, 50);
    expect(provider.rewardedLetterIds, {'letterA', 'letterB'});
    expect(repository.saveCallCount, 1);
  });

  test('3通目の手紙にも10滴を付与する', () async {
    final repository = _FakeShizukuRepository(
      const ShizukuState(
        currentShizuku: 50,
        rewardedLetterIds: {'letterA', 'letterB'},
      ),
    );
    final provider = await _loadProvider(repository);

    final result = await provider.rewardForLetter('letterC');

    expect(result.amount, 10);
    expect(provider.currentShizuku, 60);
    expect(provider.rewardedLetterIds, {'letterA', 'letterB', 'letterC'});
  });

  for (final entry in const {
    0: (0, 0),
    1: (0, 1),
    29: (0, 29),
    30: (1, 0),
    31: (1, 1),
    59: (1, 29),
    60: (2, 0),
  }.entries) {
    test('瓶進行を報酬済み${entry.key}件から導出する', () async {
      final ids = {
        for (var index = 0; index < entry.key; index++) 'letter$index',
      };
      final provider = await _loadProvider(
        _FakeShizukuRepository(
          ShizukuState(currentShizuku: 30, rewardedLetterIds: ids),
        ),
      );

      expect(provider.bottleRecordCount, entry.key);
      expect(provider.fullBottleCount, entry.value.$1);
      expect(provider.currentBottleProgress, entry.value.$2);
    });
  }

  test('瓶テスト準備は実在IDと雫残高を維持して29件を保存する', () async {
    final realIds = {for (var index = 0; index < 10; index++) 'letter_$index'};
    final repository = _FakeShizukuRepository(
      ShizukuState(currentShizuku: 75, rewardedLetterIds: realIds),
    );
    final provider = await _loadProvider(repository);

    await provider.prepareNextBottleForPrototype();

    expect(provider.currentShizuku, 75);
    expect(provider.bottleRecordCount, 29);
    expect(provider.currentBottleProgress, 29);
    expect(provider.rewardedLetterIds, containsAll(realIds));
    final addedIds = provider.rewardedLetterIds.difference(realIds);
    expect(addedIds, hasLength(19));
    expect(
      addedIds.every((id) => id.startsWith('__prototype_bottle_test_')),
      isTrue,
    );
    expect(repository.savedStates.single.currentShizuku, 75);
    expect(repository.savedStates.single.rewardedLetterIds, hasLength(29));

    await provider.prepareNextBottleForPrototype();

    expect(provider.bottleRecordCount, 29);
    expect(repository.saveCallCount, 1);
  });

  test('瓶テスト準備後の新規実在手紙は10滴と29から30件になる', () async {
    final repository = _FakeShizukuRepository(
      const ShizukuState(
        currentShizuku: 40,
        rewardedLetterIds: {'letter_already_rewarded'},
      ),
    );
    final provider = await _loadProvider(repository);

    await provider.prepareNextBottleForPrototype();
    final duplicateResult = await provider.rewardForLetter(
      'letter_already_rewarded',
    );
    final newResult = await provider.rewardForLetter('letter_new');

    expect(duplicateResult.status, LetterRewardStatus.alreadyRewarded);
    expect(duplicateResult.amount, 0);
    expect(newResult.status, LetterRewardStatus.rewarded);
    expect(newResult.amount, 10);
    expect(provider.currentShizuku, 50);
    expect(provider.bottleRecordCount, 30);
    expect(provider.fullBottleCount, 1);
    expect(provider.currentBottleProgress, 0);
    expect(provider.rewardedLetterIds, contains('letter_new'));

    await provider.reset();

    expect(provider.currentShizuku, 0);
    expect(provider.rewardedLetterIds, isEmpty);
    expect(provider.bottleRecordCount, 0);
  });

  for (final entry in const {30: 59, 31: 59, 58: 59, 59: 59, 60: 89}.entries) {
    test('瓶テスト準備は${entry.key}件を${entry.value}件にする', () async {
      final repository = _FakeShizukuRepository(
        ShizukuState(
          currentShizuku: 30,
          rewardedLetterIds: {
            for (var index = 0; index < entry.key; index++) 'letter_$index',
          },
        ),
      );
      final provider = await _loadProvider(repository);

      await provider.prepareNextBottleForPrototype();

      expect(provider.bottleRecordCount, entry.value);
      expect(provider.currentBottleProgress, 29);
      expect(
        provider.rewardedLetterIds,
        containsAll({
          for (var index = 0; index < entry.key; index++) 'letter_$index',
        }),
      );
      expect(repository.saveCallCount, entry.key == 59 ? 0 : 1);
    });
  }

  test('瓶テスト準備の保存失敗時はメモリ状態を変更しない', () async {
    final repository = _FakeShizukuRepository(
      const ShizukuState(currentShizuku: 40, rewardedLetterIds: {'letterA'}),
    )..saveError = StateError('save failed');
    final provider = await _loadProvider(repository);

    await expectLater(
      provider.prepareNextBottleForPrototype(),
      throwsA(isA<StateError>()),
    );

    expect(provider.currentShizuku, 40);
    expect(provider.rewardedLetterIds, {'letterA'});
    expect(provider.bottleRecordCount, 1);
  });

  test('報酬受取済みの手紙は保存も状態変更もしない', () async {
    final repository = _FakeShizukuRepository(
      const ShizukuState(currentShizuku: 30, rewardedLetterIds: {'letterA'}),
    );
    final provider = await _loadProvider(repository);
    var notificationCount = 0;
    provider.addListener(() => notificationCount++);

    final result = await provider.rewardForLetter('letterA');

    expect(result.status, LetterRewardStatus.alreadyRewarded);
    expect(result.amount, 0);
    expect(provider.currentShizuku, 30);
    expect(provider.rewardedLetterIds, {'letterA'});
    expect(repository.saveCallCount, 0);
    expect(notificationCount, 0);
  });

  test('報酬保存失敗時はメモリ状態を変更しない', () async {
    final repository = _FakeShizukuRepository(_initialState)
      ..saveError = StateError('save failed');
    final provider = await _loadProvider(repository);

    await expectLater(
      provider.rewardForLetter('letterA'),
      throwsA(isA<StateError>()),
    );

    expect(provider.currentShizuku, 0);
    expect(provider.rewardedLetterIds, isEmpty);
    expect(provider.bottleRecordCount, 0);
  });

  test('consumeShizukuは報酬受取済みIDを維持する', () async {
    final repository = _FakeShizukuRepository(
      const ShizukuState(currentShizuku: 40, rewardedLetterIds: {'letterA'}),
    );
    final provider = await _loadProvider(repository);

    expect(await provider.consumeShizuku(10), isTrue);

    expect(provider.currentShizuku, 30);
    expect(provider.rewardedLetterIds, {'letterA'});
    expect(repository.savedStates.single.rewardedLetterIds, {'letterA'});
    expect(provider.bottleRecordCount, 1);
    expect(provider.fullBottleCount, 0);
    expect(provider.currentBottleProgress, 1);
  });

  test('addShizukuは報酬受取済みIDを維持する', () async {
    final repository = _FakeShizukuRepository(
      const ShizukuState(currentShizuku: 30, rewardedLetterIds: {'letterA'}),
    );
    final provider = await _loadProvider(repository);

    await provider.addShizuku(10);

    expect(provider.currentShizuku, 40);
    expect(provider.rewardedLetterIds, {'letterA'});
    expect(provider.bottleRecordCount, 1);
    expect(provider.fullBottleCount, 0);
    expect(provider.currentBottleProgress, 1);
  });

  test('resetは残高と報酬受取済みIDを空にする', () async {
    final repository = _FakeShizukuRepository(
      const ShizukuState(currentShizuku: 40, rewardedLetterIds: {'letterA'}),
    );
    final provider = await _loadProvider(repository);

    await provider.reset();

    expect(provider.currentShizuku, 0);
    expect(provider.rewardedLetterIds, isEmpty);
    expect(provider.bottleRecordCount, 0);
    expect(provider.fullBottleCount, 0);
    expect(provider.currentBottleProgress, 0);
    expect(provider.isLoaded, isTrue);
    expect(repository.resetCallCount, 1);
  });

  test('同じ手紙の並行報酬は同じ処理を共有して二重付与しない', () async {
    final repository = _BlockingShizukuRepository();
    final provider = await _loadProvider(repository);

    final first = provider.rewardForLetter('letterA');
    final second = provider.rewardForLetter('letterA');

    expect(repository.saveCallCount, 1);
    repository.completeSave();

    final results = await Future.wait([first, second]);
    expect(results.every((result) => result.amount == 10), isTrue);
    expect(provider.currentShizuku, 10);
    expect(provider.rewardedLetterIds, {'letterA'});
    expect(repository.saveCallCount, 1);
  });
}

const _initialState = ShizukuState(currentShizuku: 0, rewardedLetterIds: {});

Future<ShizukuProvider> _loadProvider(ShizukuRepository repository) async {
  final provider = ShizukuProvider(repository);
  await provider.load();
  return provider;
}

class _FakeShizukuRepository extends ShizukuRepository {
  _FakeShizukuRepository(this.state);

  ShizukuState state;
  Object? saveError;
  int saveCallCount = 0;
  int resetCallCount = 0;
  int loadCallCount = 0;
  final List<ShizukuState> savedStates = [];

  @override
  Future<ShizukuState> loadState() async {
    loadCallCount++;
    return state;
  }

  @override
  Future<void> saveState(ShizukuState nextState) async {
    saveCallCount++;
    if (saveError case final error?) {
      throw error;
    }
    state = nextState;
    savedStates.add(nextState);
  }

  @override
  Future<void> resetState() async {
    resetCallCount++;
    state = _initialState;
  }
}

class _BlockingLoadShizukuRepository extends ShizukuRepository {
  Completer<ShizukuState>? _loadCompleter;
  int loadCallCount = 0;

  @override
  Future<ShizukuState> loadState() {
    loadCallCount++;
    _loadCompleter = Completer<ShizukuState>();
    return _loadCompleter!.future;
  }

  void completeLoad(ShizukuState state) {
    _loadCompleter!.complete(state);
  }

  void failLoad(Object error) {
    _loadCompleter!.completeError(error);
  }
}

class _BlockingShizukuRepository extends ShizukuRepository {
  final Completer<void> _saveCompleter = Completer<void>();
  int saveCallCount = 0;

  @override
  Future<ShizukuState> loadState() async => _initialState;

  @override
  Future<void> saveState(ShizukuState state) {
    saveCallCount++;
    return _saveCompleter.future;
  }

  void completeSave() => _saveCompleter.complete();
}
