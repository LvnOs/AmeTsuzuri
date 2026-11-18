import 'package:flutter/services.dart';
import 'package:yaml/yaml.dart';

import '../../../shared/model/season_type.dart';
import '../../../shared/model/weather_type.dart';
import '../model/letter.dart';

class LetterSummary {
  const LetterSummary({
    required this.id,
    required this.title,
    required this.requiredSeason,
    required this.requiredWeather,
    required this.bodyAssetPath,
  });

  final String id;
  final String title;
  final SeasonType requiredSeason;
  final WeatherType requiredWeather;
  final String bodyAssetPath;
}

class LetterRepository {
  LetterRepository({AssetBundle? assetBundle})
    : _assetBundle = assetBundle ?? rootBundle;

  final AssetBundle _assetBundle;

  Future<List<LetterSummary>> getSummaries() async {
    final yamlString = await _assetBundle.loadString(
      'assets/data/letters.yaml',
    );
    final items = loadYaml(yamlString)['letters'] as YamlList;

    return [
      for (final item in items)
        LetterSummary(
          id: item['id'] as String,
          title: item['title'] as String,
          requiredSeason: SeasonType.fromYaml(item['season'] as String),
          requiredWeather: WeatherType.fromYaml(item['weather'] as String),
          bodyAssetPath: "assets/${item['body_file'] as String}",
        ),
    ];
  }

  Future<Letter> loadLetter(LetterSummary summary) async {
    final String body;
    try {
      body = await _assetBundle.loadString(summary.bodyAssetPath);
    } catch (_) {
      // CachingAssetBundle also keeps failed futures. Let the next tap retry.
      _assetBundle.evict(summary.bodyAssetPath);
      rethrow;
    }

    return Letter(
      id: summary.id,
      title: summary.title,
      body: body,
      requiredSeason: summary.requiredSeason,
      requiredWeather: summary.requiredWeather,
    );
  }

  Future<List<Letter>> getAll() async {
    final summaries = await getSummaries();
    return [for (final summary in summaries) await loadLetter(summary)];
  }
}
