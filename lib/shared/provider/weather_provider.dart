import 'package:flutter/material.dart';

import '../model/weather_type.dart';
import '../repository/weather_repository.dart';

class WeatherProvider extends ChangeNotifier {
  WeatherProvider(this._repository);

  final WeatherRepository _repository;
  WeatherType? _currentWeather;
  bool _isLoaded = false;
  int _loadGeneration = 0;

  WeatherType? get currentWeather => _currentWeather;
  bool get isLoaded => _isLoaded;

  Future<void> loadForDate(DateTime date) async {
    final generation = ++_loadGeneration;
    _currentWeather = null;
    _isLoaded = false;
    notifyListeners();

    final weather = await _repository.getByDate(date);
    if (generation != _loadGeneration) {
      return;
    }

    _currentWeather = weather;
    _isLoaded = true;
    notifyListeners();
  }
}
