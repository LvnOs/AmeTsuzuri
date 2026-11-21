import 'dart:convert';

import '../../../shared/model/weather_type.dart';
import 'weather_platform_stub.dart'
    if (dart.library.js_interop) 'weather_platform_web.dart'
    as platform;

typedef Coordinates = ({double latitude, double longitude});
typedef WeatherResponse = ({int status, String body});

enum LocationFailure { denied, timeout, unsupported, unavailable }

class RealWeatherService {
  RealWeatherService({
    Future<Coordinates> Function()? locate,
    Future<WeatherResponse> Function(Uri)? request,
  }) : _locate = locate ?? platform.locate,
       _request = request ?? platform.request;

  static const timeout = Duration(seconds: 10);
  final Future<Coordinates> Function() _locate;
  final Future<WeatherResponse> Function(Uri) _request;

  Future<Coordinates> locate() async {
    final position = await _locate().timeout(
      timeout,
      onTimeout: () => throw LocationFailure.timeout,
    );
    final (:latitude, :longitude) = position;
    if (!latitude.isFinite ||
        latitude.abs() > 90 ||
        !longitude.isFinite ||
        longitude.abs() > 180) {
      throw LocationFailure.unavailable;
    }
    return position;
  }

  Future<WeatherType?> fetch(Coordinates position) async {
    final uri = Uri.https('api.open-meteo.com', '/v1/forecast', {
      'latitude': position.latitude.toString(),
      'longitude': position.longitude.toString(),
      'current': 'weather_code,rain,showers',
    });
    final response = await _request(uri).timeout(timeout);
    if (response.status != 200) return null;
    try {
      return _classify(jsonDecode(response.body));
    } on FormatException {
      return null;
    }
  }

  static WeatherType? _classify(Object? data) {
    if (data case {
      'current': {
        'weather_code': final int code,
        'rain': final num rain,
        'showers': final num showers,
      },
    } when rain.isFinite && showers.isFinite && rain >= 0 && showers >= 0) {
      final hasLiquidRain = rain > 0 || showers > 0;
      // Open-Meteo's WMO table. Accumulated rain and the current code have
      // different time semantics, so a rain code can have zero accumulation.
      return switch (code) {
        51 ||
        53 ||
        55 ||
        56 ||
        57 ||
        61 ||
        63 ||
        65 ||
        66 ||
        67 ||
        80 ||
        81 ||
        82 => WeatherType.rain,
        95 || 96 || 99 => hasLiquidRain ? WeatherType.rain : null,
        0 ||
        1 ||
        2 ||
        3 ||
        45 ||
        48 ||
        71 ||
        73 ||
        75 ||
        77 ||
        85 ||
        86 => hasLiquidRain ? null : WeatherType.sunny,
        _ => null,
      };
    }
    return null;
  }
}
