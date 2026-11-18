import 'package:flutter/material.dart';

import '../model/season_type.dart';
import '../repository/app_date_repository.dart';

class AppDateProvider extends ChangeNotifier {
  AppDateProvider(this._repository, {DateTime Function()? now})
    : _now = now ?? DateTime.now {
    _realDate = DateUtils.dateOnly(_now());
  }

  static final DateTime _prototypeStartDate = DateTime(2026, 8, 7);

  final AppDateRepository _repository;
  final DateTime Function() _now;
  late DateTime _realDate;
  DateTime? _prototypeDate;
  bool _isPrototypeMode = false;
  bool _needsMigrationNotice = false;
  bool _isLoaded = false;
  int _dateRevision = 0;

  DateTime get today =>
      _isPrototypeMode ? _prototypeDate ?? _prototypeStartDate : _realDate;
  SeasonType get currentSeason => SeasonType.fromDate(today);

  bool get isDebugDateEnabled => _isPrototypeMode;
  bool get needsMigrationNotice => _needsMigrationNotice;
  bool get isLoaded => _isLoaded;
  int get dateRevision => _dateRevision;

  Future<void> load() async {
    final savedDate = await _repository.load();
    final savedMode = await _repository.loadPrototypeMode();
    _realDate = DateUtils.dateOnly(_now());
    _prototypeDate = savedDate;
    _isPrototypeMode = savedMode ?? false;
    _needsMigrationNotice = savedMode == null && savedDate != null;
    _isLoaded = true;
    _dateRevision++;
    notifyListeners();
  }

  void refreshLocalDate() {
    final nextDate = DateUtils.dateOnly(_now());
    if (nextDate == _realDate) {
      return;
    }
    _realDate = nextDate;
    if (_isLoaded && !_isPrototypeMode) {
      _dateRevision++;
      notifyListeners();
    }
  }

  Future<void> setPrototypeMode(bool enabled) async {
    if (_isPrototypeMode == enabled && !_needsMigrationNotice) {
      return;
    }
    await _repository.savePrototypeMode(enabled);
    final previousDate = today;
    final modeChanged = _isPrototypeMode != enabled;
    _isPrototypeMode = enabled;
    _needsMigrationNotice = false;
    _realDate = DateUtils.dateOnly(_now());
    if (modeChanged || today != previousDate) {
      _dateRevision++;
    }
    notifyListeners();
  }

  Future<void> setDebugDate(DateTime date) async {
    final nextDate = DateUtils.dateOnly(date);
    await _repository.save(nextDate);
    if (!_isPrototypeMode) {
      await _repository.savePrototypeMode(true);
    }
    if (!_isPrototypeMode || today != nextDate) {
      _dateRevision++;
    }
    _prototypeDate = nextDate;
    _isPrototypeMode = true;
    _needsMigrationNotice = false;
    notifyListeners();
  }

  Future<void> moveToNextDay() async {
    if (!_isPrototypeMode) {
      return;
    }
    final current = today;
    await setDebugDate(DateTime(current.year, current.month, current.day + 1));
  }

  Future<void> startPrototypePeriod() => setDebugDate(_prototypeStartDate);
}
