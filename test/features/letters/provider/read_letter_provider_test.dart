import 'dart:async';

import 'package:ame_tsuzuri/features/letters/model/read_letter_state.dart';
import 'package:ame_tsuzuri/features/letters/provider/read_letter_provider.dart';
import 'package:ame_tsuzuri/features/letters/repository/read_letter_repository.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('進行中のloadは同じFutureを共有してRepositoryを一度だけ読む', () async {
    final repository = _BlockingLoadReadLetterRepository();
    final provider = ReadLetterProvider(repository);

    final first = provider.load();
    final second = provider.load();

    expect(identical(first, second), isTrue);
    expect(repository.loadCallCount, 1);

    repository.completeLoad(_emptyState());
    await Future.wait([first, second]);

    expect(provider.isLoaded, isTrue);
  });

  test('load失敗後は再度Repositoryを読み込める', () async {
    final repository = _BlockingLoadReadLetterRepository();
    final provider = ReadLetterProvider(repository);

    final failedLoad = provider.load();
    repository.failLoad(StateError('load failed'));
    await expectLater(failedLoad, throwsA(isA<StateError>()));

    expect(provider.isLoaded, isFalse);

    final retry = provider.load();
    expect(repository.loadCallCount, 2);
    repository.completeLoad(
      ReadLetterState(
        receivedLetters: {'letterA': DateTime(2026, 8, 8)},
      ),
    );
    await retry;

    expect(provider.isLoaded, isTrue);
    expect(provider.readLetterIds, {'letterA'});
  });

  test('受取日ありと不明のStateをロードする', () async {
    final repository = _FakeReadLetterRepository(
      ReadLetterState(
        receivedLetters: {
          'letterA': DateTime(2026, 8, 8),
          'legacy': null,
        },
      ),
    );
    final provider = ReadLetterProvider(repository);

    await provider.load();

    expect(provider.isLoaded, isTrue);
    expect(provider.readLetterIds, {'letterA', 'legacy'});
    expect(provider.receivedDateFor('letterA'), DateTime(2026, 8, 8));
    expect(provider.receivedDateFor('legacy'), isNull);
  });

  test('ロード失敗時は既存状態を維持して例外を伝える', () async {
    final repository = _FakeReadLetterRepository(
      ReadLetterState(receivedLetters: {'letterA': DateTime(2026, 8, 8)}),
    );
    final provider = await _loadProvider(repository);
    repository.failLoad = true;

    await expectLater(provider.load(), throwsA(isA<StateError>()));

    expect(provider.isLoaded, isTrue);
    expect(provider.readLetterIds, {'letterA'});
    expect(provider.receivedDateFor('letterA'), DateTime(2026, 8, 8));
  });

  test('新規手紙の日付を正規化して保存成功後に反映する', () async {
    final repository = _FakeReadLetterRepository(_emptyState());
    final provider = await _loadProvider(repository);
    var notificationCount = 0;
    provider.addListener(() => notificationCount++);

    final result = await provider.markAsRead(
      'letterA',
      receivedDate: DateTime(2026, 8, 8, 23, 59),
    );

    expect(result, isTrue);
    expect(provider.readLetterIds, {'letterA'});
    expect(provider.receivedDateFor('letterA'), DateTime(2026, 8, 8));
    expect(repository.state.receivedLetters, {
      'letterA': DateTime(2026, 8, 8),
    });
    expect(repository.saveCallCount, 1);
    expect(notificationCount, 1);
  });

  test('既読手紙は保存・通知・受取日の上書きをしない', () async {
    final repository = _FakeReadLetterRepository(
      ReadLetterState(receivedLetters: {'letterA': DateTime(2026, 8, 8)}),
    );
    final provider = await _loadProvider(repository);
    var notificationCount = 0;
    provider.addListener(() => notificationCount++);

    final result = await provider.markAsRead(
      'letterA',
      receivedDate: DateTime(2026, 8, 12),
    );

    expect(result, isFalse);
    expect(provider.receivedDateFor('letterA'), DateTime(2026, 8, 8));
    expect(repository.saveCallCount, 0);
    expect(notificationCount, 0);
  });

  test('受取日不明の既読手紙も新しい日付で上書きしない', () async {
    final repository = _FakeReadLetterRepository(
      ReadLetterState(receivedLetters: {'legacy': null}),
    );
    final provider = await _loadProvider(repository);

    final result = await provider.markAsRead(
      'legacy',
      receivedDate: DateTime(2026, 8, 12),
    );

    expect(result, isFalse);
    expect(provider.readLetterIds, {'legacy'});
    expect(provider.receivedLetters.containsKey('legacy'), isTrue);
    expect(provider.receivedDateFor('legacy'), isNull);
    expect(repository.saveCallCount, 0);
  });

  test('新しい手紙を追加しても既存手紙を維持する', () async {
    final repository = _FakeReadLetterRepository(
      ReadLetterState(receivedLetters: {'letterA': DateTime(2026, 8, 8)}),
    );
    final provider = await _loadProvider(repository);

    await provider.markAsRead(
      'letterB',
      receivedDate: DateTime(2026, 8, 10),
    );

    expect(provider.receivedLetters, {
      'letterA': DateTime(2026, 8, 8),
      'letterB': DateTime(2026, 8, 10),
    });
  });

  test('保存失敗時は新規手紙を反映せず既存状態を維持する', () async {
    final repository = _FakeReadLetterRepository(
      ReadLetterState(receivedLetters: {'letterA': DateTime(2026, 8, 8)}),
    )..failSave = true;
    final provider = await _loadProvider(repository);
    var notificationCount = 0;
    provider.addListener(() => notificationCount++);

    await expectLater(
      provider.markAsRead(
        'letterB',
        receivedDate: DateTime(2026, 8, 10),
      ),
      throwsA(isA<StateError>()),
    );

    expect(provider.readLetterIds, {'letterA'});
    expect(provider.receivedDateFor('letterA'), DateTime(2026, 8, 8));
    expect(provider.receivedLetters.containsKey('letterB'), isFalse);
    expect(repository.state.receivedLetters.keys, {'letterA'});
    expect(notificationCount, 0);
  });

  test('resetはRepository成功後に空Stateへ変更してロード済みを維持する', () async {
    final repository = _FakeReadLetterRepository(
      ReadLetterState(receivedLetters: {'letterA': DateTime(2026, 8, 8)}),
    );
    final provider = await _loadProvider(repository);
    var notificationCount = 0;
    provider.addListener(() => notificationCount++);

    await provider.reset();

    expect(provider.isLoaded, isTrue);
    expect(provider.readLetterIds, isEmpty);
    expect(provider.receivedLetters, isEmpty);
    expect(provider.receivedDateFor('letterA'), isNull);
    expect(repository.resetCallCount, 1);
    expect(notificationCount, 1);
  });

  test('受取履歴と既読集合を外部から変更できない', () async {
    final provider = await _loadProvider(
      _FakeReadLetterRepository(
        ReadLetterState(receivedLetters: {'letterA': DateTime(2026, 8, 8)}),
      ),
    );

    expect(
      () => provider.receivedLetters['letterB'] = DateTime(2026, 8, 9),
      throwsUnsupportedError,
    );
    expect(() => provider.readLetterIds.add('letterB'), throwsUnsupportedError);
  });

  group('receivedLetterIdOn', () {
    test('指定日に受け取ったLetter IDを返し時刻は無視する', () async {
      final provider = await _loadProvider(
        _FakeReadLetterRepository(
          ReadLetterState(
            receivedLetters: {'letterA': DateTime(2026, 8, 8)},
          ),
        ),
      );

      expect(
        provider.receivedLetterIdOn(DateTime(2026, 8, 8, 23, 59)),
        'letterA',
      );
    });

    test('別日の履歴とnull受取日は該当しない', () async {
      final provider = await _loadProvider(
        _FakeReadLetterRepository(
          ReadLetterState(
            receivedLetters: {
              'letterA': DateTime(2026, 8, 7),
              'legacy': null,
            },
          ),
        ),
      );

      expect(provider.receivedLetterIdOn(DateTime(2026, 8, 8)), isNull);
    });

    test('複数履歴から同日のIDを返す', () async {
      final provider = await _loadProvider(
        _FakeReadLetterRepository(
          ReadLetterState(
            receivedLetters: {
              'letterA': DateTime(2026, 8, 7),
              'letterB': DateTime(2026, 8, 8),
              'legacy': null,
            },
          ),
        ),
      );

      expect(
        provider.receivedLetterIdOn(DateTime(2026, 8, 8)),
        'letterB',
      );
    });

    test('同日に複数履歴があればMap順の最初のIDを返す', () async {
      final provider = await _loadProvider(
        _FakeReadLetterRepository(
          ReadLetterState(
            receivedLetters: {
              'first': DateTime(2026, 8, 8),
              'second': DateTime(2026, 8, 8),
            },
          ),
        ),
      );

      expect(provider.receivedLetterIdOn(DateTime(2026, 8, 8)), 'first');
    });

    test('問い合わせで状態変更・保存・通知をしない', () async {
      final repository = _FakeReadLetterRepository(
        ReadLetterState(
          receivedLetters: {'letterA': DateTime(2026, 8, 8)},
        ),
      );
      final provider = await _loadProvider(repository);
      var notificationCount = 0;
      provider.addListener(() => notificationCount++);

      expect(provider.receivedLetterIdOn(DateTime(2026, 8, 8)), 'letterA');
      expect(provider.receivedLetters, {
        'letterA': DateTime(2026, 8, 8),
      });
      expect(repository.saveCallCount, 0);
      expect(notificationCount, 0);
    });
  });

  group('hasReceivedLetterOn', () {
    test('同じ年月日の受取履歴があればtrueを返す', () async {
      final provider = await _loadProvider(
        _FakeReadLetterRepository(
          ReadLetterState(
            receivedLetters: {'letterA': DateTime(2026, 8, 8)},
          ),
        ),
      );

      expect(
        provider.hasReceivedLetterOn(DateTime(2026, 8, 8, 23, 59)),
        isTrue,
      );
    });

    test('別日の受取履歴だけならfalseを返す', () async {
      final provider = await _loadProvider(
        _FakeReadLetterRepository(
          ReadLetterState(
            receivedLetters: {'letterA': DateTime(2026, 8, 7)},
          ),
        ),
      );

      expect(provider.hasReceivedLetterOn(DateTime(2026, 8, 8)), isFalse);
    });

    test('受取日がnullの旧履歴は判定対象外', () async {
      final provider = await _loadProvider(
        _FakeReadLetterRepository(
          ReadLetterState(receivedLetters: {'legacy': null}),
        ),
      );

      expect(provider.hasReceivedLetterOn(DateTime(2026, 8, 8)), isFalse);
    });

    test('複数履歴のうち1件でも同日ならtrueを返す', () async {
      final provider = await _loadProvider(
        _FakeReadLetterRepository(
          ReadLetterState(
            receivedLetters: {
              'letterA': DateTime(2026, 8, 7),
              'letterB': DateTime(2026, 8, 8),
              'legacy': null,
            },
          ),
        ),
      );

      expect(provider.hasReceivedLetterOn(DateTime(2026, 8, 8)), isTrue);
    });

    test('問い合わせでは状態変更も通知も行わない', () async {
      final provider = await _loadProvider(
        _FakeReadLetterRepository(
          ReadLetterState(
            receivedLetters: {'letterA': DateTime(2026, 8, 8)},
          ),
        ),
      );
      var notificationCount = 0;
      provider.addListener(() => notificationCount++);

      expect(provider.hasReceivedLetterOn(DateTime(2026, 8, 8)), isTrue);
      expect(provider.receivedLetters, {
        'letterA': DateTime(2026, 8, 8),
      });
      expect(notificationCount, 0);
    });
  });
  group('delivery state', () {
    test('配達前は未配達で、deliver後は指定日のIDを返す', () async {
      final repository = _FakeReadLetterRepository(_emptyState());
      final provider = await _loadProvider(repository);

      expect(provider.hasDeliveredLetterOn(DateTime(2026, 8, 8)), isFalse);
      expect(provider.deliveredLetterIdOn(DateTime(2026, 8, 8)), isNull);

      final delivered = await provider.deliver(
        'letterA',
        deliveredDate: DateTime(2026, 8, 8, 23, 59),
      );

      expect(delivered, isTrue);
      expect(provider.hasDeliveredLetterOn(DateTime(2026, 8, 8)), isTrue);
      expect(provider.deliveredLetterIdOn(DateTime(2026, 8, 8, 1)), 'letterA');
      expect(provider.hasDeliveredLetterOn(DateTime(2026, 8, 9)), isFalse);
      expect(repository.state.deliveredLetters, {
        '2026-08-08': 'letterA',
      });
    });

    test('同じ日への重複配達は同じIDでも別IDでも上書きしない', () async {
      final repository = _FakeReadLetterRepository(_emptyState());
      final provider = await _loadProvider(repository);

      expect(
        await provider.deliver(
          'letterA',
          deliveredDate: DateTime(2026, 8, 8),
        ),
        isTrue,
      );
      expect(
        await provider.deliver(
          'letterA',
          deliveredDate: DateTime(2026, 8, 8, 12),
        ),
        isFalse,
      );
      expect(
        await provider.deliver(
          'letterB',
          deliveredDate: DateTime(2026, 8, 8),
        ),
        isFalse,
      );

      expect(provider.deliveredLetterIdOn(DateTime(2026, 8, 8)), 'letterA');
      expect(repository.saveCallCount, 1);
    });

    test('配達保存失敗時はProvider状態を変更しない', () async {
      final repository = _FakeReadLetterRepository(_emptyState())
        ..failSave = true;
      final provider = await _loadProvider(repository);

      await expectLater(
        provider.deliver(
          'letterA',
          deliveredDate: DateTime(2026, 8, 8),
        ),
        throwsA(isA<StateError>()),
      );

      expect(provider.deliveredLetters, isEmpty);
    });

    test('配達後のmarkAsReadは配達状態を維持する', () async {
      final repository = _FakeReadLetterRepository(_emptyState());
      final provider = await _loadProvider(repository);

      await provider.deliver(
        'letterA',
        deliveredDate: DateTime(2026, 8, 8),
      );
      expect(provider.readLetterIds, isNot(contains('letterA')));

      await provider.markAsRead(
        'letterA',
        receivedDate: DateTime(2026, 8, 8),
      );

      expect(provider.deliveredLetterIdOn(DateTime(2026, 8, 8)), 'letterA');
      expect(provider.readLetterIds, contains('letterA'));
    });

    test('resetで既読と配達の両方を消す', () async {
      final repository = _FakeReadLetterRepository(
        ReadLetterState(
          receivedLetters: {'letterA': DateTime(2026, 8, 8)},
          deliveredLetters: {'2026-08-08': 'letterA'},
        ),
      );
      final provider = await _loadProvider(repository);

      await provider.reset();

      expect(provider.receivedLetters, isEmpty);
      expect(provider.deliveredLetters, isEmpty);
    });
  });
}

Future<ReadLetterProvider> _loadProvider(
  ReadLetterRepository repository,
) async {
  final provider = ReadLetterProvider(repository);
  await provider.load();
  return provider;
}

ReadLetterState _emptyState() => ReadLetterState(receivedLetters: {});

class _FakeReadLetterRepository extends ReadLetterRepository {
  _FakeReadLetterRepository(this.state);

  ReadLetterState state;
  bool failLoad = false;
  bool failSave = false;
  int saveCallCount = 0;
  int resetCallCount = 0;

  @override
  Future<ReadLetterState> loadState() async {
    if (failLoad) {
      throw StateError('load failed');
    }
    return state;
  }

  @override
  Future<void> saveState(ReadLetterState nextState) async {
    saveCallCount++;
    if (failSave) {
      throw StateError('save failed');
    }
    state = nextState;
  }

  @override
  Future<void> resetState() async {
    resetCallCount++;
    state = _emptyState();
  }
}

class _BlockingLoadReadLetterRepository extends ReadLetterRepository {
  Completer<ReadLetterState>? _loadCompleter;
  int loadCallCount = 0;

  @override
  Future<ReadLetterState> loadState() {
    loadCallCount++;
    _loadCompleter = Completer<ReadLetterState>();
    return _loadCompleter!.future;
  }

  void completeLoad(ReadLetterState state) {
    _loadCompleter!.complete(state);
  }

  void failLoad(Object error) {
    _loadCompleter!.completeError(error);
  }
}
