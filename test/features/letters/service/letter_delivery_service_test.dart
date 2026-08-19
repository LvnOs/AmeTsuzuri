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

  group('季節手紙から通年手紙へのフォールバック', () {
    test('anyがList上で先でも配信可能な現在季節の手紙を優先する', () {
      final selected = select([
        _letter('any', season: SeasonType.any),
        _letter('summer'),
      ]);

      expect(selected?.id, 'summer');
    });

    test('現在季節の手紙がList上で先ならその手紙を選ぶ', () {
      final selected = select([
        _letter('summer'),
        _letter('any', season: SeasonType.any),
      ]);

      expect(selected?.id, 'summer');
    });

    test('現在季節の手紙が既読なら未読のanyへフォールバックする', () {
      final selected = select([
        _letter('summer'),
        _letter('any', season: SeasonType.any),
      ], readIds: {'summer'});

      expect(selected?.id, 'any');
    });

    test('現在季節の手紙が天候不一致なら天候一致のanyへフォールバックする', () {
      final selected = select([
        _letter('summer-sunny', weather: WeatherType.sunny),
        _letter('any-rain', season: SeasonType.any),
      ]);

      expect(selected?.id, 'any-rain');
    });

    test('配信可能な現在季節の手紙同士ではList順先頭を選ぶ', () {
      final selected = select([
        _letter('summer-first'),
        _letter('summer-second'),
      ]);

      expect(selected?.id, 'summer-first');
    });

    test('季節候補がなければany手紙同士のList順先頭を選ぶ', () {
      final selected = select([
        _letter('any-first', season: SeasonType.any),
        _letter('any-second', season: SeasonType.any),
      ]);

      expect(selected?.id, 'any-first');
    });

    test('先頭にanyが複数あっても後方の現在季節候補を優先する', () {
      final selected = select([
        _letter('any-first', season: SeasonType.any),
        _letter('any-second', season: SeasonType.any),
        _letter('summer'),
      ]);

      expect(selected?.id, 'summer');
    });

    test('現在季節以外の季節手紙を無視してanyへフォールバックする', () {
      final selected = select([
        _letter('autumn', season: SeasonType.autumn),
        _letter('any', season: SeasonType.any),
      ]);

      expect(selected?.id, 'any');
    });

    test('現在季節候補もany候補もなければnullを返す', () {
      final selected = select([
        _letter('autumn', season: SeasonType.autumn),
        _letter('read-any', season: SeasonType.any),
      ], readIds: {'read-any'});

      expect(selected, isNull);
    });

    test('anyでも天候不一致なら選ばない', () {
      final selected = select([
        _letter(
          'any-sunny',
          season: SeasonType.any,
          weather: WeatherType.sunny,
        ),
      ]);

      expect(selected, isNull);
    });
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
