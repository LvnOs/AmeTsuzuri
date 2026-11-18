import '../../../shared/model/season_type.dart';
import '../../../shared/model/weather_type.dart';
import '../repository/letter_repository.dart';

class LetterDeliveryService {
  const LetterDeliveryService();

  LetterSummary? selectLetter({
    required List<LetterSummary> letters,
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

  LetterSummary? _selectFirstMatching({
    required List<LetterSummary> letters,
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
