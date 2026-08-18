import 'package:flutter/material.dart';

import '../model/season_type.dart';
import '../repository/app_date_repository.dart';

class AppDateProvider extends ChangeNotifier {
  AppDateProvider(this._repository);

  final AppDateRepository _repository;
  DateTime? _debugDate;
  bool _isLoaded = false;

  DateTime get today => _debugDate ?? DateTime.now();
  SeasonType get currentSeason => SeasonType.fromDate(today);

  bool get isDebugDateEnabled => _debugDate != null;
  bool get isLoaded => _isLoaded;

  Future<void> load() async {
    _debugDate = await _repository.load();
    _isLoaded = true;
    notifyListeners();
  }

  Future<void> setDebugDate(DateTime date) async {
    final nextDate = DateTime(date.year, date.month, date.day);
    await _repository.save(nextDate);
    _debugDate = nextDate;
    notifyListeners();
  }

  Future<void> moveToNextDay() async {
    final current = today;
    final nextDate = DateTime(current.year, current.month, current.day + 1);

    await _repository.save(nextDate);
    _debugDate = nextDate;
    notifyListeners();
  }

  Future<void> startPrototypePeriod() async {
    final nextDate = DateTime(2026, 8, 7);
    await _repository.save(nextDate);
    _debugDate = nextDate;
    notifyListeners();
  }

  Future<void> clearDebugDate() async {
    await _repository.clear();
    _debugDate = null;
    notifyListeners();
  }
}
