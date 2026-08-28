import 'dart:convert';

import 'package:ame_tsuzuri/features/letters/repository/letter_repository.dart';
import 'package:ame_tsuzuri/features/letters/service/letter_delivery_service.dart';
import 'package:ame_tsuzuri/shared/model/season_type.dart';
import 'package:ame_tsuzuri/shared/model/weather_type.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  test('実データからtutorial_001と正式本文を読み込める', () async {
    final letters = await LetterRepository().getAll();
    final tutorial = letters.singleWhere(
      (letter) => letter.id == 'tutorial_001',
    );

    expect(tutorial.title, '雨つづり。へようこそ');
    expect(tutorial.body, contains('この部屋には、雨の日になると手紙が届きます。'));
    expect(tutorial.body, contains('まずは、この手紙といっしょに30滴をどうぞ。'));
    expect(tutorial.body, contains('雫は、この部屋に置く家具と交換することができます。'));
    expect(tutorial.body, isNot(contains('窓辺の瓶を開くと')));
    expect(tutorial.body, isNot(contains('本棚からいつでも読み返せます')));
  });

  test('実データはtutorial 1件・summer 10件・autumn 10件を重複なく読み込む', () async {
    final letters = await LetterRepository().getAll();
    final ids = letters.map((letter) => letter.id).toList();
    final summerLetters = letters
        .where((letter) => letter.requiredSeason == SeasonType.summer)
        .toList();
    final autumnLetters = letters
        .where((letter) => letter.requiredSeason == SeasonType.autumn)
        .toList();

    expect(letters, hasLength(21));
    expect(ids.toSet(), hasLength(21));
    expect(
      letters.where((letter) => letter.id == 'tutorial_001'),
      hasLength(1),
    );
    expect(summerLetters, hasLength(10));
    expect(autumnLetters, hasLength(10));
    expect(autumnLetters.map((letter) => letter.id), const [
      'letter_20260817',
      'letter_20260818',
      'letter_20260819',
      'letter_20260820',
      'letter_20260821',
      'letter_20260822',
      'letter_20260823',
      'letter_20260824',
      'letter_20260825',
      'letter_20260826',
    ]);
    expect(
      autumnLetters.every(
        (letter) => letter.requiredWeather == WeatherType.rain,
      ),
      isTrue,
    );
    expect(
      autumnLetters.every((letter) => letter.body.trim().isNotEmpty),
      isTrue,
    );
  });

  test('実データのsummerとautumnを季節ごとのYAML順で選択する', () async {
    final letters = (await LetterRepository().getAll())
        .where((letter) => letter.id != 'tutorial_001')
        .toList();
    const service = LetterDeliveryService();

    void expectSelectionOrder(SeasonType season, List<String> expectedIds) {
      final readIds = <String>{};
      for (final expectedId in expectedIds) {
        final selected = service.selectLetter(
          letters: letters,
          currentSeason: season,
          currentWeather: WeatherType.rain,
          readLetterIds: readIds,
        );
        expect(selected?.id, expectedId);
        readIds.add(expectedId);
      }
      expect(
        service.selectLetter(
          letters: letters,
          currentSeason: season,
          currentWeather: WeatherType.rain,
          readLetterIds: readIds,
        ),
        isNull,
      );
    }

    expectSelectionOrder(SeasonType.summer, const [
      'letter_20260807',
      'letter_20260808',
      'letter_20260809',
      'letter_20260810',
      'letter_20260811',
      'letter_20260812',
      'letter_20260813',
      'letter_20260814',
      'letter_20260815',
      'letter_20260816',
    ]);
    expectSelectionOrder(SeasonType.autumn, const [
      'letter_20260817',
      'letter_20260818',
      'letter_20260819',
      'letter_20260820',
      'letter_20260821',
      'letter_20260822',
      'letter_20260823',
      'letter_20260824',
      'letter_20260825',
      'letter_20260826',
    ]);
  });

  test('dateなしYAMLから配信と表示に必要なフィールドを読み込む', () async {
    final repository = LetterRepository(
      assetBundle: _MemoryAssetBundle({
        'assets/data/letters.yaml': _yamlWithWeather('rain'),
        'assets/letters/test.md': '手紙の本文',
      }),
    );

    final letters = await repository.getAll();

    expect(letters, hasLength(1));
    final letter = letters.single;
    expect(letter.id, 'letter_test');
    expect(letter.title, 'テストの手紙');
    expect(letter.body, '手紙の本文');
    expect(letter.requiredSeason, SeasonType.summer);
    expect(letter.requiredWeather, WeatherType.rain);
  });

  test('未対応のweather値はFormatExceptionになる', () async {
    final repository = LetterRepository(
      assetBundle: _MemoryAssetBundle({
        'assets/data/letters.yaml': _yamlWithWeather('storm'),
        'assets/letters/test.md': '手紙の本文',
      }),
    );

    await expectLater(repository.getAll(), throwsA(isA<FormatException>()));
  });

  test('未対応のseason値はFormatExceptionになる', () async {
    final repository = LetterRepository(
      assetBundle: _MemoryAssetBundle({
        'assets/data/letters.yaml': _yamlWithWeather('rain', season: 'monsoon'),
        'assets/letters/test.md': '手紙の本文',
      }),
    );

    await expectLater(repository.getAll(), throwsA(isA<FormatException>()));
  });
}

String _yamlWithWeather(String weather, {String season = 'summer'}) =>
    '''
letters:
  - id: letter_test
    title: "テストの手紙"
    season: $season
    weather: $weather
    body_file: letters/test.md
''';

class _MemoryAssetBundle extends CachingAssetBundle {
  _MemoryAssetBundle(this.assets);

  final Map<String, String> assets;

  @override
  Future<ByteData> load(String key) async {
    final value = assets[key];
    if (value == null) {
      throw StateError('Missing test asset: $key');
    }
    final bytes = Uint8List.fromList(utf8.encode(value));
    return ByteData.sublistView(bytes);
  }
}
