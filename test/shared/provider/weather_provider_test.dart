import 'dart:async';

import 'package:ame_tsuzuri/shared/model/weather_type.dart';
import 'package:ame_tsuzuri/shared/provider/weather_provider.dart';
import 'package:ame_tsuzuri/shared/repository/weather_repository.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('ロード前は未ロードで天候もない', () {
    final provider = WeatherProvider(_FakeWeatherRepository({}));

    expect(provider.isLoaded, isFalse);
    expect(provider.currentWeather, isNull);
    expect(provider.previousWeather, isNull);
  });

  test('今日sunnyと前日rainを同時に保持する', () async {
    final provider = WeatherProvider(
      _FakeWeatherRepository({
        DateTime(2026, 8, 6): WeatherType.rain,
        DateTime(2026, 8, 7): WeatherType.sunny,
      }),
    );

    await provider.loadForDate(DateTime(2026, 8, 7));

    expect(provider.isLoaded, isTrue);
    expect(provider.currentWeather, WeatherType.sunny);
    expect(provider.previousWeather, WeatherType.rain);
    expect(provider.loadedDate, DateTime(2026, 8, 7));
  });

  test('前日が未定義ならpreviousWeatherはnullになる', () async {
    final provider = WeatherProvider(
      _FakeWeatherRepository({DateTime(2026, 8, 7): WeatherType.sunny}),
    );

    await provider.loadForDate(DateTime(2026, 8, 7));

    expect(provider.currentWeather, WeatherType.sunny);
    expect(provider.previousWeather, isNull);
  });

  test('未定義日付のロード完了後は天候がnullになる', () async {
    final provider = WeatherProvider(_FakeWeatherRepository({}));

    await provider.loadForDate(DateTime(2026, 8, 20));

    expect(provider.isLoaded, isTrue);
    expect(provider.currentWeather, isNull);
    expect(provider.previousWeather, isNull);
    expect(provider.loadedDate, DateTime(2026, 8, 20));
  });

  test('同じProviderでrainからsunnyを経てrainへ再ロードできる', () async {
    final provider = WeatherProvider(
      _FakeWeatherRepository({
        DateTime(2026, 8, 6): WeatherType.sunny,
        DateTime(2026, 8, 7): WeatherType.rain,
        DateTime(2026, 8, 8): WeatherType.sunny,
        DateTime(2026, 8, 9): WeatherType.rain,
      }),
    );

    await provider.loadForDate(DateTime(2026, 8, 7));
    expect(provider.currentWeather, WeatherType.rain);

    await provider.loadForDate(DateTime(2026, 8, 8));
    expect(provider.currentWeather, WeatherType.sunny);

    await provider.loadForDate(DateTime(2026, 8, 9));

    expect(provider.isLoaded, isTrue);
    expect(provider.currentWeather, WeatherType.rain);
    expect(provider.previousWeather, WeatherType.sunny);
    expect(provider.loadedDate, DateTime(2026, 8, 9));
  });

  test('定義済み日付から未定義日付へ移ると古い天候を消す', () async {
    final provider = WeatherProvider(
      _FakeWeatherRepository({DateTime(2026, 8, 7): WeatherType.rain}),
    );

    await provider.loadForDate(DateTime(2026, 8, 7));
    await provider.loadForDate(DateTime(2026, 8, 20));

    expect(provider.isLoaded, isTrue);
    expect(provider.currentWeather, isNull);
    expect(provider.previousWeather, isNull);
  });

  test('日付変更時はロード完了前に古い今日と前日の天候を消す', () async {
    final delayed = Completer<WeatherType?>();
    final provider = WeatherProvider(_DelayedWeatherRepository(delayed.future));

    final firstLoad = provider.loadForDate(DateTime(2026, 8, 7));
    await Future<void>.delayed(Duration.zero);
    final secondLoad = provider.loadForDate(DateTime(2026, 8, 8));

    expect(provider.currentWeather, isNull);
    expect(provider.previousWeather, isNull);
    expect(provider.loadedDate, isNull);

    delayed.complete(WeatherType.rain);
    await Future.wait([firstLoad, secondLoad]);

    expect(provider.loadedDate, DateTime(2026, 8, 8));
    expect(provider.currentWeather, WeatherType.sunny);
    expect(provider.previousWeather, WeatherType.rain);
  });

  test('日付変更前の古い非同期結果を採用しない', () async {
    final delayed = Completer<WeatherType?>();
    final provider = WeatherProvider(_DelayedWeatherRepository(delayed.future));

    final oldLoad = provider.loadForDate(DateTime(2026, 8, 7));
    await Future<void>.delayed(Duration.zero);
    final currentLoad = provider.loadForDate(DateTime(2026, 8, 8));
    delayed.complete(WeatherType.rain);
    await Future.wait([oldLoad, currentLoad]);

    expect(provider.loadedDate, DateTime(2026, 8, 8));
    expect(provider.currentWeather, WeatherType.sunny);
  });
}

class _FakeWeatherRepository extends WeatherRepository {
  _FakeWeatherRepository(this.weatherByDate);

  final Map<DateTime, WeatherType> weatherByDate;

  @override
  Future<WeatherType?> getByDate(DateTime date) async {
    return weatherByDate[DateTime(date.year, date.month, date.day)];
  }
}

class _DelayedWeatherRepository extends WeatherRepository {
  _DelayedWeatherRepository(this.delayedRain);

  final Future<WeatherType?> delayedRain;

  @override
  Future<WeatherType?> getByDate(DateTime date) {
    final normalized = DateTime(date.year, date.month, date.day);
    if (normalized == DateTime(2026, 8, 8)) {
      return Future.value(WeatherType.sunny);
    }
    if (normalized == DateTime(2026, 8, 7)) {
      return delayedRain;
    }
    return Future.value();
  }
}
