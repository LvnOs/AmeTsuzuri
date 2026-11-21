import 'dart:async';

import 'package:ame_tsuzuri/features/real_weather/provider/real_weather_provider.dart';
import 'package:ame_tsuzuri/features/real_weather/repository/weather_location_repository.dart';
import 'package:ame_tsuzuri/features/real_weather/service/real_weather_service.dart';
import 'package:ame_tsuzuri/shared/model/weather_type.dart';
import 'package:ame_tsuzuri/shared/provider/app_data_provider.dart';
import 'package:ame_tsuzuri/shared/repository/app_date_repository.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

const _position = (latitude: 35.0, longitude: 139.0);
const _rain = (
  status: 200,
  body: '{"current":{"weather_code":61,"rain":1,"showers":0}}',
);
const _sunny = (
  status: 200,
  body: '{"current":{"weather_code":0,"rain":0,"showers":0}}',
);
const _error = (status: 503, body: '');

Future<void> _flush() => Future<void>.delayed(Duration.zero);

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  late DateTime now;
  late AppDateProvider date;
  late WeatherLocationRepository settings;

  setUp(() async {
    SharedPreferences.setMockInitialValues({});
    now = DateTime(2026, 11, 21, 23);
    date = AppDateProvider(AppDateRepository(), now: () => now);
    settings = WeatherLocationRepository();
    await date.load();
    addTearDown(date.dispose);
  });

  RealWeatherProvider make(RealWeatherService service) =>
      RealWeatherProvider(date, settings, service, now: () => now);

  test(
    'initial OFF, single in-flight request, persistence and automatic revisit',
    () async {
      var locations = 0;
      final response = Completer<WeatherResponse>();
      final service = RealWeatherService(
        locate: () async {
          locations++;
          return _position;
        },
        request: (_) => response.future,
      );
      final weather = make(service);
      await weather.load();
      expect(locations, 0);
      final first = weather.enableOrRetry();
      expect(weather.isLoading, isTrue);
      await weather.enableOrRetry();
      await weather.refresh(force: true);
      expect(locations, 1);
      response.complete(_rain);
      await first;
      await _flush();
      expect(weather.current?.weather, WeatherType.rain);
      expect(await settings.load(), WeatherLocationSetting.enabled);
      weather.dispose();

      final reopened = make(service);
      addTearDown(reopened.dispose);
      await reopened.load();
      await _flush();
      expect(locations, 2);
      expect(reopened.current?.weather, WeatherType.rain);
      reopened.disable();
      await reopened.refresh();
      await _flush();
      expect(locations, 2);
      expect(reopened.current, isNull);
      expect(await settings.load(), WeatherLocationSetting.off);
    },
  );

  test(
    'denial persists and only a manual retry requests location again',
    () async {
      var attempts = 0;
      final service = RealWeatherService(
        locate: () async {
          if (++attempts == 1) throw LocationFailure.denied;
          return _position;
        },
        request: (_) async => _rain,
      );
      final weather = make(service);
      await weather.load();
      await weather.enableOrRetry();
      expect(weather.failure, RealWeatherFailure.denied);
      expect(weather.current, isNull);
      await _flush();
      expect(await settings.load(), WeatherLocationSetting.retryRequired);
      weather.dispose();

      final reopened = make(service);
      addTearDown(reopened.dispose);
      await reopened.load();
      reopened.updateForeground(false);
      reopened.updateForeground(true);
      await _flush();
      expect(attempts, 1);
      await reopened.enableOrRetry();
      expect(attempts, 2);
      expect(reopened.current?.weather, WeatherType.rain);
      await _flush();
      expect(await settings.load(), WeatherLocationSetting.enabled);
    },
  );

  test(
    'location timeout and unsupported browser have separate failure states',
    () async {
      for (final (cause, expected) in [
        (LocationFailure.timeout, RealWeatherFailure.locationTimeout),
        (LocationFailure.unsupported, RealWeatherFailure.unsupported),
      ]) {
        final weather = make(
          RealWeatherService(locate: () async => throw cause),
        );
        await weather.load();
        await weather.enableOrRetry();
        expect(weather.current, isNull);
        expect(weather.failure, expected);
        weather.disable();
        await _flush();
        weather.dispose();
      }
    },
  );

  test(
    'same-day cache, inclusive TTL, stale refresh and failure fallback',
    () async {
      var requests = 0;
      final weather = make(
        RealWeatherService(
          locate: () async => _position,
          request: (_) async => ++requests == 1 ? _rain : _error,
        ),
      );
      addTearDown(weather.dispose);
      await weather.load();
      await weather.enableOrRetry();
      final success = weather.current;
      expect(success?.source, RealWeatherSource.openMeteo);
      expect(success?.date, DateTime(2026, 11, 21));
      expect(success?.fetchedAt, now);
      now = now.add(const Duration(minutes: 30));
      await weather.refresh();
      expect(requests, 1);
      expect(weather.current, success);
      await weather.refresh(force: true);
      expect(weather.failure, RealWeatherFailure.weatherUnavailable);
      expect(weather.current, success);
      now = now.add(const Duration(milliseconds: 1));
      expect(weather.current, isNull);
      await weather.refresh();
      expect(requests, 3);
      expect(weather.current, isNull);
    },
  );

  test(
    'midnight and mode changes discard old requests even after a newer success',
    () async {
      now = DateTime(2026, 11, 21, 23, 58);
      final responses = List.generate(4, (_) => Completer<WeatherResponse>());
      var requests = 0;
      final weather = make(
        RealWeatherService(
          locate: () async => _position,
          request: (_) => responses[requests++].future,
        ),
      );
      addTearDown(weather.dispose);
      await weather.load();
      final first = weather.enableOrRetry();
      await _flush();
      responses[0].complete(_rain);
      await first;
      final oldDay = weather.refresh(force: true);
      await _flush();
      now = now.add(const Duration(minutes: 2));
      expect(weather.current, isNull);
      date.refreshLocalDate();
      await _flush();
      expect(requests, 3);
      await date.setPrototypeMode(true);
      expect(weather.isLoading, isFalse);
      expect(weather.current, isNull);
      await date.setPrototypeMode(false);
      await _flush();
      expect(requests, 4);

      responses[3].complete(_sunny);
      await _flush();
      responses[1].complete(_rain);
      responses[2].complete(_rain);
      await oldDay;
      await _flush();
      expect(weather.current?.weather, WeatherType.sunny);
      expect(weather.current?.date, DateTime(2026, 11, 22));
    },
  );

  test('tab resume reuses fresh cache and fetches only when expired', () async {
    var calls = 0;
    final weather = make(
      RealWeatherService(
        locate: () async {
          calls++;
          return _position;
        },
        request: (_) async => _rain,
      ),
    );
    addTearDown(weather.dispose);
    await weather.load();
    await weather.enableOrRetry();
    weather.updateForeground(false);
    now = now.add(const Duration(minutes: 30));
    await weather.refresh(force: true);
    expect(calls, 1);
    weather.updateForeground(true);
    await _flush();
    expect(calls, 1);
    weather.updateForeground(false);
    now = now.add(const Duration(seconds: 1));
    weather.updateForeground(true);
    await _flush();
    expect(calls, 2);
    expect(weather.current?.fetchedAt, now);
  });

  test(
    'OFF during location acquisition prevents sending coordinates',
    () async {
      var requests = 0;
      final location = Completer<Coordinates>();
      final weather = make(
        RealWeatherService(
          locate: () => location.future,
          request: (_) async {
            requests++;
            return _rain;
          },
        ),
      );
      addTearDown(weather.dispose);
      await weather.load();
      final pending = weather.enableOrRetry();
      weather.disable();
      location.complete(_position);
      await pending;
      expect(requests, 0);
      expect(weather.current, isNull);
      await _flush();
      expect(await settings.load(), WeatherLocationSetting.off);
    },
  );

  test('OFF and dispose discard late responses', () async {
    for (final dispose in [false, true]) {
      final response = Completer<WeatherResponse>();
      final weather = make(
        RealWeatherService(
          locate: () async => _position,
          request: (_) => response.future,
        ),
      );
      await weather.load();
      final pending = weather.enableOrRetry();
      await _flush();
      if (dispose) {
        weather.dispose();
      } else {
        weather.disable();
      }
      response.complete(_rain);
      await pending;
      expect(weather.current, isNull);
      if (!dispose) weather.dispose();
      await settings.save(WeatherLocationSetting.off);
    }
  });
}
