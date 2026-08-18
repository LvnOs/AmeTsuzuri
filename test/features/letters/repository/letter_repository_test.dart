import 'dart:convert';

import 'package:ame_tsuzuri/features/letters/repository/letter_repository.dart';
import 'package:ame_tsuzuri/shared/model/weather_type.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('weatherと既存フィールドをYAMLから読み込む', () async {
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
    expect(letter.date, DateTime(2026, 8, 7));
    expect(letter.title, 'テストの手紙');
    expect(letter.body, '手紙の本文');
    expect(letter.requiredWeather, WeatherType.rain);
  });

  test('getByDateは天候条件を保持した従来どおりの手紙を返す', () async {
    final repository = LetterRepository(
      assetBundle: _MemoryAssetBundle({
        'assets/data/letters.yaml': _yamlWithWeather('rain'),
        'assets/letters/test.md': '手紙の本文',
      }),
    );

    final letter = await repository.getByDate(DateTime(2026, 8, 7, 12));

    expect(letter, isNotNull);
    expect(letter!.id, 'letter_test');
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
}

String _yamlWithWeather(String weather) => '''
letters:
  - id: letter_test
    date: "2026-08-07"
    title: "テストの手紙"
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
