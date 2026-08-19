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
    final seasonalLetter = _selectFirstMatching(
      letters: letters,
      requiredSeason: currentSeason,
      currentWeather: currentWeather,
      readLetterIds: readLetterIds,
    );
    if (seasonalLetter != null) {
      return seasonalLetter;
    }

    return _selectFirstMatching(
      letters: letters,
      requiredSeason: SeasonType.any,
      currentWeather: currentWeather,
      readLetterIds: readLetterIds,
    );
  }

  Letter? _selectFirstMatching({
    required List<Letter> letters,
    required SeasonType requiredSeason,
    required WeatherType currentWeather,
    required Set<String> readLetterIds,
  }) {
    for (final letter in letters) {
      if (readLetterIds.contains(letter.id) ||
          letter.requiredSeason != requiredSeason ||
          letter.requiredWeather != currentWeather) {
        continue;
      }

      return letter;
    }

    return null;
  }
}
