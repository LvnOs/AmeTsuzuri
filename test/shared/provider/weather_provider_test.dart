import 'package:ame_tsuzuri/shared/model/weather_type.dart';
import 'package:ame_tsuzuri/shared/provider/weather_provider.dart';
import 'package:ame_tsuzuri/shared/repository/weather_repository.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('ロード前は未ロードで天候もない', () {
    final provider = WeatherProvider(_FakeWeatherRepository({}));

    expect(provider.isLoaded, isFalse);
    expect(provider.currentWeather, isNull);
  });

  test('定義済み日付をロードすると天候を保持する', () async {
    final provider = WeatherProvider(
      _FakeWeatherRepository({DateTime(2026, 8, 7): WeatherType.rain}),
    );

    await provider.loadForDate(DateTime(2026, 8, 7));

    expect(provider.isLoaded, isTrue);
    expect(provider.currentWeather, WeatherType.rain);
  });

  test('未定義日付のロード完了後は天候がnullになる', () async {
    final provider = WeatherProvider(_FakeWeatherRepository({}));

    await provider.loadForDate(DateTime(2026, 8, 20));

    expect(provider.isLoaded, isTrue);
    expect(provider.currentWeather, isNull);
  });

  test('同じProviderで別の日付を再ロードできる', () async {
    final provider = WeatherProvider(
      _FakeWeatherRepository({
        DateTime(2026, 8, 7): WeatherType.rain,
        DateTime(2026, 8, 8): WeatherType.rain,
      }),
    );

    await provider.loadForDate(DateTime(2026, 8, 7));
    await provider.loadForDate(DateTime(2026, 8, 8));

    expect(provider.isLoaded, isTrue);
    expect(provider.currentWeather, WeatherType.rain);
  });

  test('定義済み日付から未定義日付へ移ると古い天候を消す', () async {
    final provider = WeatherProvider(
      _FakeWeatherRepository({DateTime(2026, 8, 7): WeatherType.rain}),
    );

    await provider.loadForDate(DateTime(2026, 8, 7));
    await provider.loadForDate(DateTime(2026, 8, 20));

    expect(provider.isLoaded, isTrue);
    expect(provider.currentWeather, isNull);
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
