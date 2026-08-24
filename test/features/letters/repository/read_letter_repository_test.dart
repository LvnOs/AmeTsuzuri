import 'dart:convert';

import 'package:ame_tsuzuri/features/letters/model/read_letter_state.dart';
import 'package:ame_tsuzuri/features/letters/repository/read_letter_repository.dart';
import 'package:ame_tsuzuri/features/letters/repository/shizuku_repository.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  const stateKey = 'readLetterState';
  const legacyKey = 'readLetterIds';

  setUp(() {
    SharedPreferences.setMockInitialValues({});
  });

  test('配達IDを保存して再ロードできる', () async {
    final repository = ReadLetterRepository();
    await repository.saveState(
      ReadLetterState(
        receivedLetters: {},
        deliveredLetters: {'2026-08-08': 'letterA', '2026-08-09': 'letterB'},
      ),
    );

    final prefs = await SharedPreferences.getInstance();
    final saved = jsonDecode(prefs.getString(stateKey)!);
    expect(saved['version'], 3);
    expect(saved['deliveredLetters'], {
      '2026-08-08': 'letterA',
      '2026-08-09': 'letterB',
    });

    final reloaded = await repository.loadState();
    expect(reloaded.deliveredLetters, {
      '2026-08-08': 'letterA',
      '2026-08-09': 'letterB',
    });
  });

  test('version 3でチュートリアル状態を保存して再ロードできる', () async {
    final repository = ReadLetterRepository();
    await repository.saveState(
      ReadLetterState(
        receivedLetters: {'tutorial_001': DateTime(2026, 8, 7)},
        deliveredLetters: {'2026-08-07': 'tutorial_001'},
        hasOpenedTutorialBottle: true,
        tutorialCompleted: true,
      ),
    );

    final prefs = await SharedPreferences.getInstance();
    final saved = jsonDecode(prefs.getString(stateKey)!);
    expect(saved, {
      'version': 3,
      'receivedLetters': {'tutorial_001': '2026-08-07'},
      'deliveredLetters': {'2026-08-07': 'tutorial_001'},
      'hasOpenedTutorialBottle': true,
      'tutorialCompleted': true,
    });

    final reloaded = await repository.loadState();
    expect(reloaded.hasOpenedTutorialBottle, isTrue);
    expect(reloaded.tutorialCompleted, isTrue);
  });

  test('version 2データではチュートリアル状態をfalseとして読む', () async {
    SharedPreferences.setMockInitialValues({
      stateKey: jsonEncode({
        'version': 2,
        'receivedLetters': {'tutorial_001': '2026-08-07'},
        'deliveredLetters': {'2026-08-07': 'tutorial_001'},
      }),
    });

    final state = await ReadLetterRepository().loadState();

    expect(state.receivedLetters, {'tutorial_001': DateTime(2026, 8, 7)});
    expect(state.deliveredLetters, {'2026-08-07': 'tutorial_001'});
    expect(state.hasOpenedTutorialBottle, isFalse);
    expect(state.tutorialCompleted, isFalse);
  });

  test('旧version 1形式は受取日から日ごとの配達IDを復元する', () async {
    SharedPreferences.setMockInitialValues({
      stateKey: jsonEncode({
        'version': 1,
        'receivedLetters': {
          'first': '2026-08-08',
          'second': '2026-08-08',
          'otherDay': '2026-08-09',
          'legacy': null,
        },
      }),
    });

    final state = await ReadLetterRepository().loadState();

    expect(state.receivedLetters.keys, {
      'first',
      'second',
      'otherDay',
      'legacy',
    });
    expect(state.deliveredLetters, {
      '2026-08-08': 'first',
      '2026-08-09': 'otherDay',
    });
    expect(state.hasOpenedTutorialBottle, isFalse);
    expect(state.tutorialCompleted, isFalse);
  });

  test('version 3でもチュートリアルフィールド欠落時はfalseとして読む', () async {
    SharedPreferences.setMockInitialValues({
      stateKey: jsonEncode({
        'version': 3,
        'receivedLetters': {},
        'deliveredLetters': {},
      }),
    });

    final state = await ReadLetterRepository().loadState();

    expect(state.hasOpenedTutorialBottle, isFalse);
    expect(state.tutorialCompleted, isFalse);
  });

  test('resetStateは既読と配達の両方を消す', () async {
    final repository = ReadLetterRepository();
    await repository.saveState(
      ReadLetterState(
        receivedLetters: {'letterA': DateTime(2026, 8, 8)},
        deliveredLetters: {'2026-08-08': 'letterA'},
        hasOpenedTutorialBottle: true,
        tutorialCompleted: true,
      ),
    );

    await repository.resetState();

    final state = await repository.loadState();
    expect(state.receivedLetters, isEmpty);
    expect(state.deliveredLetters, isEmpty);
    expect(state.hasOpenedTutorialBottle, isFalse);
    expect(state.tutorialCompleted, isFalse);
  });

  test('新旧データがなければ空Stateを保存して返す', () async {
    final state = await ReadLetterRepository().loadState();

    expect(state.receivedLetters, isEmpty);
    final prefs = await SharedPreferences.getInstance();
    expect(prefs.getString(stateKey), isNotNull);
  });

  test('旧既読IDを受取日不明で移行し旧キーを残す', () async {
    SharedPreferences.setMockInitialValues({
      legacyKey: ['letterA', 'letterB'],
    });

    final state = await ReadLetterRepository().loadState();

    expect(state.receivedLetters, {'letterA': null, 'letterB': null});
    final prefs = await SharedPreferences.getInstance();
    final saved = jsonDecode(prefs.getString(stateKey)!);
    expect(saved['version'], 3);
    expect(saved['receivedLetters'], {'letterA': null, 'letterB': null});
    expect(saved['deliveredLetters'], isEmpty);
    expect(prefs.getStringList(legacyKey), ['letterA', 'letterB']);
  });

  test('日付とnullをYYYY-MM-DD形式で保存して再ロードする', () async {
    final repository = ReadLetterRepository();
    await repository.saveState(
      ReadLetterState(
        receivedLetters: {
          'dated': DateTime(2026, 8, 8, 23, 59),
          'unknown': null,
        },
      ),
    );

    final prefs = await SharedPreferences.getInstance();
    final saved = jsonDecode(prefs.getString(stateKey)!);
    expect(saved['receivedLetters']['dated'], '2026-08-08');
    expect(saved['receivedLetters']['unknown'], isNull);

    final reloaded = await repository.loadState();
    expect(reloaded.receivedLetters['dated'], DateTime(2026, 8, 8));
    expect(reloaded.receivedLetters.containsKey('unknown'), isTrue);
    expect(reloaded.receivedLetters['unknown'], isNull);
  });

  test('有効な新Stateは旧既読IDより優先する', () async {
    SharedPreferences.setMockInitialValues({
      stateKey: jsonEncode({
        'version': 1,
        'receivedLetters': {'newLetter': '2026-08-10'},
      }),
      legacyKey: ['legacyLetter'],
    });

    final state = await ReadLetterRepository().loadState();

    expect(state.receivedLetters, {'newLetter': DateTime(2026, 8, 10)});
  });

  test('破損JSONは旧既読IDから再構築する', () async {
    SharedPreferences.setMockInitialValues({
      stateKey: '{broken json',
      legacyKey: ['legacyLetter'],
    });

    final state = await ReadLetterRepository().loadState();

    expect(state.receivedLetters, {'legacyLetter': null});
  });

  test('ルートやreceivedLettersが不正なら旧既読IDへフォールバックする', () async {
    for (final invalidState in [
      jsonEncode([]),
      jsonEncode({'version': 1}),
      jsonEncode({'version': 1, 'receivedLetters': []}),
    ]) {
      SharedPreferences.setMockInitialValues({
        stateKey: invalidState,
        legacyKey: ['legacyLetter'],
      });

      final state = await ReadLetterRepository().loadState();

      expect(state.receivedLetters, {'legacyLetter': null});
    }
  });

  test('不正日付と文字列・null以外の値だけを除外する', () async {
    SharedPreferences.setMockInitialValues({
      stateKey: jsonEncode({
        'version': 1,
        'receivedLetters': {
          'valid': '2026-08-08',
          'unknown': null,
          'invalidFormat': '08/09/2026',
          'invalidCalendarDate': '2026-02-30',
          'invalidType': 10,
        },
      }),
    });

    final state = await ReadLetterRepository().loadState();

    expect(state.receivedLetters, {
      'valid': DateTime(2026, 8, 8),
      'unknown': null,
    });
  });

  test('setStringがfalseならsaveStateは例外にする', () async {
    final repository = ReadLetterRepository(
      setStringOverride: (_, _) async => false,
    );

    await expectLater(
      repository.saveState(ReadLetterState(receivedLetters: {})),
      throwsA(isA<StateError>()),
    );
  });

  test('resetStateは空の新Stateを保存し旧キーも削除する', () async {
    SharedPreferences.setMockInitialValues({
      legacyKey: ['legacyLetter'],
    });
    final repository = ReadLetterRepository();
    await repository.saveState(
      ReadLetterState(receivedLetters: {'newLetter': DateTime(2026, 8, 8)}),
    );

    await repository.resetState();

    expect((await repository.loadState()).receivedLetters, isEmpty);
    final prefs = await SharedPreferences.getInstance();
    expect(prefs.containsKey(legacyKey), isFalse);
  });

  test('旧API保存は既存受取日を維持し新規IDをnullで追加する', () async {
    final repository = ReadLetterRepository();
    await repository.saveState(
      ReadLetterState(
        receivedLetters: {'dated': DateTime(2026, 8, 8)},
        hasOpenedTutorialBottle: true,
        tutorialCompleted: true,
      ),
    );

    await repository.saveReadLetterIds({'dated', 'newLetter'});

    final state = await repository.loadState();
    expect(state.receivedLetters, {
      'dated': DateTime(2026, 8, 8),
      'newLetter': null,
    });
    expect(await repository.loadReadLetterIds(), {'dated', 'newLetter'});
    expect(state.hasOpenedTutorialBottle, isTrue);
    expect(state.tutorialCompleted, isTrue);
  });

  test('移行後もShizukuRepositoryが旧既読IDを移行元にできる', () async {
    SharedPreferences.setMockInitialValues({
      'currentShizuku': 40,
      legacyKey: ['letterA'],
    });

    await ReadLetterRepository().loadState();
    final shizukuState = await ShizukuRepository().loadState();

    expect(shizukuState.currentShizuku, 40);
    expect(shizukuState.rewardedLetterIds, {'letterA'});
  });

  test('StateのMapと導出した既読集合は外部から変更できない', () {
    final source = <String, DateTime?>{'letterA': DateTime(2026, 8, 8)};
    final state = ReadLetterState(receivedLetters: source);
    source['letterB'] = null;

    expect(state.receivedLetters.keys, {'letterA'});
    expect(
      () => state.receivedLetters['letterB'] = null,
      throwsUnsupportedError,
    );
    expect(() => state.readLetterIds.add('letterB'), throwsUnsupportedError);
  });
}
