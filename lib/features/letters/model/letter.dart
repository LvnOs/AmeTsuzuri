import '../../../shared/model/weather_type.dart';

class Letter {
  const Letter({
    required this.id,
    required this.title,
    required this.date,
    required this.body,
    required this.requiredWeather,
  });

  final String id;
  final DateTime date;
  final String title;
  final String body;
  final WeatherType requiredWeather;
}
