import 'dart:async';

import 'package:ame_tsuzuri/features/real_weather/service/real_weather_service.dart';
import 'package:ame_tsuzuri/shared/model/weather_type.dart';
import 'package:flutter_test/flutter_test.dart';

const _position = (latitude: 35.0, longitude: 139.0);

void main() {
  test('validates coordinates, including the inclusive boundaries', () async {
    const edge = (latitude: -90.0, longitude: 180.0);
    expect(await RealWeatherService(locate: () async => edge).locate(), edge);
    for (final invalid in [
      (latitude: 90.01, longitude: 0.0),
      (latitude: 0.0, longitude: -180.01),
      (latitude: double.nan, longitude: double.infinity),
    ]) {
      await expectLater(
        RealWeatherService(locate: () async => invalid).locate(),
        throwsA(LocationFailure.unavailable),
      );
    }
  });

  test(
    'requests current conditions and classifies documented WMO codes',
    () async {
      for (final (code, rain, showers, expected) in [
        (51, 0, 0, WeatherType.rain),
        (57, 0, 0, WeatherType.rain),
        (61, 1, 0, WeatherType.rain),
        (67, 0, 0, WeatherType.rain),
        (82, 0, 1, WeatherType.rain),
        (95, 0, 1, WeatherType.rain),
        (99, 0, 0, null),
        (0, 0, 0, WeatherType.sunny),
        (3, 0, 0, WeatherType.sunny),
        (48, 0, 0, WeatherType.sunny),
        (71, 0, 0, WeatherType.sunny),
        (86, 0, 0, WeatherType.sunny),
        (75, 1, 0, null),
        (0, 0, 1, null),
        (1, -1, 0, null),
        (52, 1, 1, null),
      ]) {
        final service = RealWeatherService(
          request: (uri) async {
            expect(uri.scheme, 'https');
            expect(uri.host, 'api.open-meteo.com');
            expect(uri.path, '/v1/forecast');
            expect(uri.queryParameters, {
              'latitude': '35.0',
              'longitude': '139.0',
              'current': 'weather_code,rain,showers',
            });
            return (
              status: 200,
              body:
                  '{"current":{"weather_code":$code,"rain":$rain,"showers":$showers}}',
            );
          },
        );
        expect(await service.fetch(_position), expected, reason: 'WMO $code');
      }
    },
  );

  test(
    'invalid JSON, missing fields, improper types and HTTP errors stay unknown',
    () async {
      for (final (status, body) in [
        (200, '{'),
        (200, '[]'),
        (200, '{}'),
        (200, '{"current":{"weather_code":0,"rain":0}}'),
        (200, '{"current":{"weather_code":"0","rain":0,"showers":0}}'),
        (200, '{"current":{"weather_code":0,"rain":1e999,"showers":0}}'),
        (503, '{"current":{"weather_code":0,"rain":0,"showers":0}}'),
      ]) {
        final service = RealWeatherService(
          request: (_) async => (status: status, body: body),
        );
        expect(await service.fetch(_position), isNull);
      }
    },
  );

  testWidgets('location and HTTP each time out after ten seconds', (
    tester,
  ) async {
    final service = RealWeatherService(
      locate: () => Completer<Coordinates>().future,
      request: (_) => Completer<WeatherResponse>().future,
    );
    final location = expectLater(
      service.locate(),
      throwsA(LocationFailure.timeout),
    );
    final response = expectLater(
      service.fetch(_position),
      throwsA(isA<TimeoutException>()),
    );
    await tester.pump(const Duration(seconds: 10));
    await location;
    await response;
  });
}
