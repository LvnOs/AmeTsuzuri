import 'package:ame_tsuzuri/features/ambient_sound/repository/ambient_sound_repository.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  setUp(() {
    SharedPreferences.setMockInitialValues({});
  });

  test('保存値がなければ初期値falseを返す', () async {
    final repository = AmbientSoundRepository();

    expect(await repository.loadEnabled(), isFalse);
  });

  test('ambientSoundEnabledを保存して復元できる', () async {
    final repository = AmbientSoundRepository();

    await repository.saveEnabled(true);
    expect(await repository.loadEnabled(), isTrue);

    await repository.saveEnabled(false);
    expect(await repository.loadEnabled(), isFalse);
  });

  test('既存キーへ触れずにbool設定だけを保存する', () async {
    SharedPreferences.setMockInitialValues({'existingKey': 'keep'});
    final repository = AmbientSoundRepository();

    await repository.saveEnabled(true);

    final prefs = await SharedPreferences.getInstance();
    expect(prefs.getString('existingKey'), 'keep');
    expect(prefs.getBool('ambientSoundEnabled'), isTrue);
  });

  test('保存APIがfalseを返したら例外にする', () async {
    final repository = AmbientSoundRepository(
      setEnabledOverride: (_, _) async => false,
    );

    await expectLater(repository.saveEnabled(true), throwsStateError);
  });
}
