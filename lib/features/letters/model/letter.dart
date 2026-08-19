import '../../../shared/model/weather_type.dart';
import '../../../shared/model/season_type.dart';

class Letter {
  const Letter({
    required this.id,
    required this.title,
    required this.body,
    required this.requiredSeason,
    required this.requiredWeather,
  });

  final String id;
  final String title;
  final String body;
  final SeasonType requiredSeason;
  final WeatherType requiredWeather;
}
