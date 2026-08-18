import 'package:flutter/services.dart';
import 'package:yaml/yaml.dart';

import '../model/weather_type.dart';

class WeatherRepository {
  WeatherRepository({AssetBundle? assetBundle})
    : _assetBundle = assetBundle ?? rootBundle;

  final AssetBundle _assetBundle;

  Future<WeatherType?> getByDate(DateTime date) async {
    final yamlString = await _assetBundle.loadString('assets/data/weather.yaml');
    final weatherEntries = loadYaml(yamlString)['weather'];

    for (final entry in weatherEntries) {
      final entryDate = DateTime.parse(entry['date'] as String);
      if (_isSameDate(entryDate, date)) {
        return WeatherType.fromYaml(entry['weather'] as String);
      }
    }

    return null;
  }

  bool _isSameDate(DateTime a, DateTime b) {
    return a.year == b.year && a.month == b.month && a.day == b.day;
  }
}
