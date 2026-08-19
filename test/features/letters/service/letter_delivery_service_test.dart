import 'package:ame_tsuzuri/features/letters/model/letter.dart';
import 'package:ame_tsuzuri/features/letters/service/letter_delivery_service.dart';
import 'package:ame_tsuzuri/shared/model/season_type.dart';
import 'package:ame_tsuzuri/shared/model/weather_type.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  const service = LetterDeliveryService();

  Letter? select(
    List<Letter> letters, {
    SeasonType season = SeasonType.summer,
    WeatherType weather = WeatherType.rain,
    Set<String> readIds = const {},
  }) {
    return service.selectLetter(
      letters: letters,
      currentSeason: season,
      currentWeather: weather,
      readLetterIds: readIds,
    );
  }

  test('未読かつ季節・天候一致の手紙を選ぶ', () {
    expect(select([_letter('matching')])?.id, 'matching');
  });

  test('既読の手紙を選ばない', () {
    expect(select([_letter('read')], readIds: {'read'}), isNull);
  });

  test('季節不一致の手紙を選ばない', () {
    expect(select([_letter('winter', season: SeasonType.winter)]), isNull);
  });

  test('anyの手紙はどの現在季節でも候補になる', () {
    for (final season in [
      SeasonType.spring,
      SeasonType.summer,
      SeasonType.autumn,
      SeasonType.winter,
    ]) {
      expect(
        select([_letter('any', season: SeasonType.any)], season: season)?.id,
        'any',
      );
    }
  });

  test('天候不一致の手紙を選ばない', () {
    expect(select([_letter('sunny', weather: WeatherType.sunny)]), isNull);
  });

  test('候補がなければnullを返す', () {
    expect(select(const []), isNull);
  });

  test('複数候補では元List順で最初の手紙を選ぶ', () {
    final selected = select([
      _letter('first'),
      _letter('second'),
    ]);

    expect(selected?.id, 'first');
  });

  test('先頭が既読なら次の条件一致手紙を選ぶ', () {
    final selected = select([
      _letter('read'),
      _letter('next'),
    ], readIds: {'read'});

    expect(selected?.id, 'next');
  });

  test('先頭が季節不一致なら次の条件一致手紙を選ぶ', () {
    final selected = select([
      _letter('winter', season: SeasonType.winter),
      _letter('summer'),
    ]);

    expect(selected?.id, 'summer');
  });

  test('先頭が天候不一致なら次の条件一致手紙を選ぶ', () {
    final selected = select([
      _letter('sunny', weather: WeatherType.sunny),
      _letter('rain'),
    ]);

    expect(selected?.id, 'rain');
  });

}

Letter _letter(
  String id, {
  SeasonType season = SeasonType.summer,
  WeatherType weather = WeatherType.rain,
}) {
  return Letter(
    id: id,
    title: id,
    body: id,
    requiredSeason: season,
    requiredWeather: weather,
  );
}
