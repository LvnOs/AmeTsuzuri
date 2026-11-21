import 'real_weather_service.dart';

Future<Coordinates> locate() async => throw LocationFailure.unsupported;

Future<WeatherResponse> request(Uri uri) async =>
    throw UnsupportedError('Weather requires a browser.');

void openCredit(String url) {}
