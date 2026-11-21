import 'dart:async';
import 'dart:js_interop';
import 'dart:js_interop_unsafe';

import 'package:web/web.dart' as web;

import 'real_weather_service.dart';

Future<Coordinates> locate() {
  final navigator = web.window.navigator;
  if (!web.window.isSecureContext || !navigator.has('geolocation')) {
    return Future.error(LocationFailure.unsupported);
  }
  final result = Completer<Coordinates>();
  navigator.geolocation.getCurrentPosition(
    ((web.GeolocationPosition position) {
      result.complete((
        latitude: position.coords.latitude,
        longitude: position.coords.longitude,
      ));
    }).toJS,
    ((web.GeolocationPositionError error) {
      result.completeError(switch (error.code) {
        1 => LocationFailure.denied,
        3 => LocationFailure.timeout,
        _ => LocationFailure.unavailable,
      });
    }).toJS,
    web.PositionOptions(timeout: RealWeatherService.timeout.inMilliseconds),
  );
  return result.future;
}

Future<WeatherResponse> request(Uri uri) async {
  final controller = web.AbortController();
  final timeout = Timer(RealWeatherService.timeout, () => controller.abort());
  try {
    final response = await web.window
        .fetch(
          uri.toString().toJS,
          web.RequestInit(signal: controller.signal, cache: 'no-store'),
        )
        .toDart;
    return (
      status: response.status,
      body: response.ok ? (await response.text().toDart).toDart : '',
    );
  } finally {
    timeout.cancel();
  }
}

void openCredit(String url) {
  web.window.open(url, '_blank', 'noopener,noreferrer');
}
