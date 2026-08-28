import 'dart:convert';

import 'package:ame_tsuzuri/shared/model/weather_type.dart';
import 'package:ame_tsuzuri/shared/repository/weather_repository.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:yaml/yaml.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  test('本番固定天候は9月1日から10日までFIX配列を重複なく保持する', () async {
    const expected = <String, WeatherType>{
      '2026-09-01': WeatherType.rain,
      '2026-09-02': WeatherType.sunny,
      '2026-09-03': WeatherType.rain,
      '2026-09-04': WeatherType.rain,
      '2026-09-05': WeatherType.sunny,
      '2026-09-06': WeatherType.rain,
      '2026-09-07': WeatherType.sunny,
      '2026-09-08': WeatherType.rain,
      '2026-09-09': WeatherType.rain,
      '2026-09-10': WeatherType.sunny,
    };
    final yamlString = await rootBundle.loadString('assets/data/weather.yaml');
    final yaml = loadYaml(yamlString) as YamlMap;
    final septemberEntries = (yaml['weather'] as YamlList)
        .where((entry) => (entry['date'] as String).startsWith('2026-09-'))
        .toList();
    final dates = septemberEntries
        .map((entry) => entry['date'] as String)
        .toList();

    expect(septemberEntries, hasLength(10));
    expect(dates.toSet(), hasLength(10));
    expect(dates, expected.keys.toList());

    final repository = WeatherRepository();
    final actual = <WeatherType>[];
    for (final entry in expected.entries) {
      final weather = await repository.getByDate(DateTime.parse(entry.key));
      expect(weather, entry.value, reason: entry.key);
      actual.add(weather!);
    }

    expect(
      actual.where((weather) => weather == WeatherType.rain),
      hasLength(6),
    );
    expect(
      actual.where((weather) => weather == WeatherType.sunny),
      hasLength(4),
    );
    expect(actual.toSet(), {WeatherType.rain, WeatherType.sunny});
    expect(await repository.getByDate(DateTime(2026, 9, 11)), isNull);
  });

  test('本番固定天候は8月プロトタイプ期間の全日がrain', () async {
    final repository = WeatherRepository();

    for (var day = 7; day <= 16; day++) {
      expect(
        await repository.getByDate(DateTime(2026, 8, day)),
        WeatherType.rain,
        reason: '2026-08-${day.toString().padLeft(2, '0')}',
      );
    }
  });

  test('定義された開始日と終了日の天候を読み込む', () async {
    final repository = _repositoryWithWeather('''
weather:
  - date: "2026-08-07"
    weather: rain
  - date: "2026-08-16"
    weather: rain
''');

    expect(await repository.getByDate(DateTime(2026, 8, 7)), WeatherType.rain);
    expect(await repository.getByDate(DateTime(2026, 8, 16)), WeatherType.rain);
  });

  test('定義されていない日付はnullを返す', () async {
    final repository = _repositoryWithWeather('''
weather:
  - date: "2026-08-07"
    weather: rain
''');

    expect(await repository.getByDate(DateTime(2026, 8, 8)), isNull);
  });

  test('時刻を無視して年月日で照合する', () async {
    final repository = _repositoryWithWeather('''
weather:
  - date: "2026-08-07"
    weather: rain
''');

    expect(
      await repository.getByDate(DateTime(2026, 8, 7, 23, 59)),
      WeatherType.rain,
    );
  });

  test('未対応のweather値はFormatExceptionになる', () async {
    final repository = _repositoryWithWeather('''
weather:
  - date: "2026-08-07"
    weather: storm
''');

    await expectLater(
      repository.getByDate(DateTime(2026, 8, 7)),
      throwsA(isA<FormatException>()),
    );
  });
}

WeatherRepository _repositoryWithWeather(String yaml) {
  return WeatherRepository(
    assetBundle: _MemoryAssetBundle({'assets/data/weather.yaml': yaml}),
  );
}

class _MemoryAssetBundle extends CachingAssetBundle {
  _MemoryAssetBundle(this.assets);

  final Map<String, String> assets;

  @override
  Future<ByteData> load(String key) async {
    final value = assets[key];
    if (value == null) {
      throw StateError('Missing test asset: $key');
    }
    return ByteData.sublistView(Uint8List.fromList(utf8.encode(value)));
  }
}
