import '../../../shared/model/season_type.dart';
import '../../../shared/model/weather_type.dart';
import '../model/letter.dart';

class LetterDeliveryService {
  const LetterDeliveryService();

  Letter? selectLetter({
    required List<Letter> letters,
    required SeasonType currentSeason,
    required WeatherType currentWeather,
    required Set<String> readLetterIds,
  }) {
    for (final letter in letters) {
      if (readLetterIds.contains(letter.id) ||
          !_matchesSeason(letter.requiredSeason, currentSeason) ||
          letter.requiredWeather != currentWeather) {
        continue;
      }

      return letter;
    }

    return null;
  }

  bool _matchesSeason(SeasonType required, SeasonType current) {
    return required == SeasonType.any || required == current;
  }
}
