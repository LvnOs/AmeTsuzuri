import 'dart:convert';

import 'package:ame_tsuzuri/features/letters/model/shizuku_state.dart';
import 'package:ame_tsuzuri/features/letters/repository/shizuku_repository.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  const stateKey = 'shizukuState';

  setUp(() {
    SharedPreferences.setMockInitialValues({});
  });

  test('新旧データがない場合は空の新状態を作成する', () async {
    final repository = ShizukuRepository();

    final state = await repository.loadState();

    expect(state.currentShizuku, 0);
    expect(state.rewardedLetterIds, isEmpty);

    final prefs = await SharedPreferences.getInstance();
    expect(prefs.getString(stateKey), isNotNull);
  });

  test('旧残高と既読IDから新状態へ移行する', () async {
    SharedPreferences.setMockInitialValues({
      'currentShizuku': 40,
      'readLetterIds': ['letterA', 'letterB'],
    });
    final repository = ShizukuRepository();

    final state = await repository.loadState();

    expect(state.currentShizuku, 40);
    expect(state.rewardedLetterIds, {'letterA', 'letterB'});

    final prefs = await SharedPreferences.getInstance();
    final savedJson = jsonDecode(prefs.getString(stateKey)!);
    expect(savedJson['version'], 1);
    expect(savedJson['currentShizuku'], 40);
    expect(savedJson['rewardedLetterIds'], containsAll(['letterA', 'letterB']));
    expect(prefs.getInt('currentShizuku'), 40);
  });

  test('新状態を保存して再読込できる', () async {
    final repository = ShizukuRepository();
    await repository.saveState(
      const ShizukuState(currentShizuku: 50, rewardedLetterIds: {'letterA'}),
    );

    final state = await repository.loadState();

    expect(state.currentShizuku, 50);
    expect(state.rewardedLetterIds, {'letterA'});
  });

  test('新状態が存在する場合は旧データより優先する', () async {
    SharedPreferences.setMockInitialValues({
      stateKey: jsonEncode({
        'version': 1,
        'currentShizuku': 50,
        'rewardedLetterIds': ['letterA'],
      }),
      'currentShizuku': 999,
      'readLetterIds': ['legacyLetter'],
    });
    final repository = ShizukuRepository();

    final state = await repository.loadState();

    expect(state.currentShizuku, 50);
    expect(state.rewardedLetterIds, {'letterA'});
  });

  test('破損JSONは旧データから再構築する', () async {
    SharedPreferences.setMockInitialValues({
      stateKey: '{broken json',
      'currentShizuku': 40,
      'readLetterIds': ['letterA'],
    });
    final repository = ShizukuRepository();

    final state = await repository.loadState();

    expect(state.currentShizuku, 40);
    expect(state.rewardedLetterIds, {'letterA'});
  });

  test('文字列以外の報酬IDを無視し、不足フィールドは初期値にする', () async {
    SharedPreferences.setMockInitialValues({
      stateKey: jsonEncode({
        'version': 1,
        'rewardedLetterIds': ['letterA', 10, null],
      }),
    });
    final repository = ShizukuRepository();

    final state = await repository.loadState();

    expect(state.currentShizuku, 0);
    expect(state.rewardedLetterIds, {'letterA'});
  });

  test('リセット後は空の新状態になり、旧残高も削除する', () async {
    SharedPreferences.setMockInitialValues({'currentShizuku': 40});
    final repository = ShizukuRepository();
    await repository.saveState(
      const ShizukuState(currentShizuku: 50, rewardedLetterIds: {'letterA'}),
    );

    await repository.resetState();
    final state = await repository.loadState();

    expect(state.currentShizuku, 0);
    expect(state.rewardedLetterIds, isEmpty);

    final prefs = await SharedPreferences.getInstance();
    expect(prefs.containsKey('currentShizuku'), isFalse);
  });

  test('旧APIは新状態の報酬IDを維持する', () async {
    final repository = ShizukuRepository();
    await repository.saveState(
      const ShizukuState(currentShizuku: 40, rewardedLetterIds: {'letterA'}),
    );

    await repository.saveCurrentShizuku(50);

    expect(await repository.loadCurrentShizuku(), 50);
    expect((await repository.loadState()).rewardedLetterIds, {'letterA'});
  });
}
