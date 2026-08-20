import 'package:flutter/material.dart';

import '../model/weather_type.dart';
import '../repository/weather_repository.dart';

class WeatherProvider extends ChangeNotifier {
  WeatherProvider(this._repository);

  final WeatherRepository _repository;
  WeatherType? _currentWeather;
  DateTime? _loadedDate;
  DateTime? _loadingDate;
  Future<void>? _loadingFuture;
  bool _isLoaded = false;
  int _loadGeneration = 0;

  WeatherType? get currentWeather => _currentWeather;
  DateTime? get loadedDate => _loadedDate;
  bool get isLoaded => _isLoaded;

  Future<void> loadForDate(DateTime date) {
    final targetDate = DateTime(date.year, date.month, date.day);
    if (_isLoaded && _loadedDate == targetDate) {
      return Future.value();
    }
    if (_loadingDate == targetDate) {
      return _loadingFuture!;
    }

    final generation = ++_loadGeneration;
    _currentWeather = null;
    _loadedDate = null;
    _isLoaded = false;
    _loadingDate = targetDate;
    notifyListeners();

    final future = _load(targetDate, generation);
    _loadingFuture = future;
    return future;
  }

  Future<void> _load(DateTime targetDate, int generation) async {
    try {
      final weather = await _repository.getByDate(targetDate);
      if (generation != _loadGeneration) {
        return;
      }

      _currentWeather = weather;
      _loadedDate = targetDate;
      _isLoaded = true;
      notifyListeners();
    } finally {
      if (generation == _loadGeneration) {
        _loadingDate = null;
        _loadingFuture = null;
      }
    }
  }
}
