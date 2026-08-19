import 'package:flutter/services.dart';
import 'package:yaml/yaml.dart';

import '../../../shared/model/season_type.dart';
import '../../../shared/model/weather_type.dart';
import '../model/letter.dart';

class LetterRepository {
  LetterRepository({AssetBundle? assetBundle})
    : _assetBundle = assetBundle ?? rootBundle;

  final AssetBundle _assetBundle;

  Future<List<Letter>> getAll() async {
    final yamlString = await _assetBundle.loadString(
      'assets/data/letters.yaml',
    );
    // YAMLファイルの構造上、以下の取得方法となる
    final yaml = loadYaml(yamlString)["letters"];

    final List<Letter> letters = [];

    for (final item in yaml) {
      final bodyFile = item['body_file'] as String;
      final body = await _assetBundle.loadString('assets/$bodyFile');

      letters.add(
        Letter(
          id: item["id"],
          title: item["title"],
          date: DateTime.parse(item["date"]),
          body: body,
          requiredSeason: SeasonType.fromYaml(item['season'] as String),
          requiredWeather: WeatherType.fromYaml(item['weather'] as String),
        ),
      );
    }
    return letters;
  }
}
