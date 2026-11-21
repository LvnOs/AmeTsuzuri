import 'dart:async';

import 'package:flutter/material.dart';

import '../../../shared/model/weather_type.dart';
import '../../../shared/provider/app_data_provider.dart';
import '../repository/weather_location_repository.dart';
import '../service/real_weather_service.dart';

enum RealWeatherSource { openMeteo }

enum RealWeatherFailure {
  denied,
  locationTimeout,
  unsupported,
  locationUnavailable,
  weatherUnavailable,
}

typedef RealWeatherSnapshot = ({
  WeatherType weather,
  RealWeatherSource source,
  DateTime date,
  DateTime fetchedAt,
});

class RealWeatherProvider extends ChangeNotifier {
  RealWeatherProvider(
    this._date,
    this._repository,
    this._service, {
    DateTime Function()? now,
  }) : _now = now ?? DateTime.now {
    _dateRevision = _date.dateRevision;
    _date.addListener(_onDateChanged);
  }

  static const cacheDuration = Duration(minutes: 30);
  final AppDateProvider _date;
  final WeatherLocationRepository _repository;
  final RealWeatherService _service;
  final DateTime Function() _now;
  WeatherLocationSetting _setting = WeatherLocationSetting.off;
  RealWeatherSnapshot? _cache;
  Timer? _expiry;
  Future<void> _pendingSave = Future.value();
  bool _loaded = false;
  bool _foreground = true;
  bool _disposed = false;
  bool _loading = false;
  bool _settingError = false;
  int _generation = 0;
  int _settingGeneration = 0;
  late int _dateRevision;
  RealWeatherFailure? _failure;

  bool get isLoaded => _loaded;
  bool get isEnabled => _setting != WeatherLocationSetting.off;
  bool get isLoading => _loading;
  bool get settingError => _settingError;
  RealWeatherFailure? get failure => _failure;
  bool get _canFetch =>
      _loaded &&
      _foreground &&
      _date.isLoaded &&
      !_date.isDebugDateEnabled &&
      isEnabled &&
      !_disposed;

  RealWeatherSnapshot? get current {
    final cache = _cache;
    if (!isEnabled || _date.isDebugDateEnabled || cache == null) return null;
    final now = _now();
    final age = now.difference(cache.fetchedAt);
    return DateUtils.isSameDay(cache.date, now) &&
            !age.isNegative &&
            age <= cacheDuration
        ? cache
        : null;
  }

  Future<void> load() async {
    try {
      final setting = await _repository.load();
      if (_disposed) return;
      _setting = setting;
      if (setting == WeatherLocationSetting.retryRequired) {
        _failure = RealWeatherFailure.denied;
      }
    } catch (_) {
      if (_disposed) return;
      _settingError = true;
    }
    _loaded = true;
    notifyListeners();
    unawaited(refresh());
  }

  void updateForeground(bool foreground) {
    if (_foreground == foreground) return;
    _foreground = foreground;
    if (foreground) {
      unawaited(refresh());
    } else {
      _invalidateRequest();
      notifyListeners();
    }
  }

  Future<void> enableOrRetry() {
    if (!_loaded ||
        _loading ||
        !_foreground ||
        !_date.isLoaded ||
        _date.isDebugDateEnabled ||
        _disposed) {
      return Future.value();
    }
    if (!isEnabled || _settingError) {
      _saveSetting(WeatherLocationSetting.enabled);
    }
    return refresh(force: true);
  }

  void disable() {
    _invalidateRequest();
    _clearCache();
    _failure = null;
    _saveSetting(WeatherLocationSetting.off);
    notifyListeners();
  }

  Future<void> refresh({bool force = false}) async {
    if (!_canFetch ||
        _loading ||
        (!force &&
            (_setting == WeatherLocationSetting.retryRequired ||
                current != null))) {
      return;
    }
    final generation = ++_generation;
    final date = DateUtils.dateOnly(_now());
    final revision = _date.dateRevision;
    bool isCurrent() =>
        generation == _generation &&
        _canFetch &&
        revision == _date.dateRevision &&
        DateUtils.isSameDay(date, _now());

    _loading = true;
    _failure = null;
    notifyListeners();
    try {
      if (!isCurrent()) return;
      final position = await _service.locate();
      if (!isCurrent()) return;
      if (_setting == WeatherLocationSetting.retryRequired) {
        _saveSetting(WeatherLocationSetting.enabled);
      }
      final weather = await _service.fetch(position);
      if (!isCurrent()) return;
      if (weather == null) {
        _failure = RealWeatherFailure.weatherUnavailable;
        return;
      }
      final fetchedAt = _now();
      _cache = (
        weather: weather,
        source: RealWeatherSource.openMeteo,
        date: date,
        fetchedAt: fetchedAt,
      );
      _expiry?.cancel();
      final midnight = DateTime(date.year, date.month, date.day + 1);
      final remainingDay = midnight.difference(fetchedAt);
      final cacheExpiry = cacheDuration + const Duration(milliseconds: 1);
      _expiry = Timer(
        remainingDay < cacheExpiry ? remainingDay : cacheExpiry,
        () {
          _clearCache();
          notifyListeners();
        },
      );
    } on LocationFailure catch (failure) {
      if (!isCurrent()) return;
      _failure = switch (failure) {
        LocationFailure.denied => RealWeatherFailure.denied,
        LocationFailure.timeout => RealWeatherFailure.locationTimeout,
        LocationFailure.unsupported => RealWeatherFailure.unsupported,
        LocationFailure.unavailable => RealWeatherFailure.locationUnavailable,
      };
      if (failure == LocationFailure.denied) {
        _saveSetting(WeatherLocationSetting.retryRequired);
      }
    } catch (_) {
      if (isCurrent()) _failure = RealWeatherFailure.weatherUnavailable;
    } finally {
      if (generation == _generation) {
        _loading = false;
        notifyListeners();
      }
    }
  }

  void _onDateChanged() {
    if (_dateRevision == _date.dateRevision) return;
    _dateRevision = _date.dateRevision;
    _invalidateRequest();
    _clearCache();
    _failure = _setting == WeatherLocationSetting.retryRequired
        ? RealWeatherFailure.denied
        : null;
    notifyListeners();
    unawaited(refresh());
  }

  void _invalidateRequest() {
    _generation++;
    _loading = false;
  }

  void _clearCache() {
    _expiry?.cancel();
    _expiry = null;
    _cache = null;
  }

  void _saveSetting(WeatherLocationSetting setting) {
    _setting = setting;
    _settingError = false;
    final generation = ++_settingGeneration;
    _pendingSave = _pendingSave.then((_) async {
      try {
        await _repository.save(setting);
      } catch (_) {
        if (!_disposed && generation == _settingGeneration) {
          _settingError = true;
          notifyListeners();
        }
      }
    });
  }

  @override
  void dispose() {
    _disposed = true;
    _invalidateRequest();
    _clearCache();
    _date.removeListener(_onDateChanged);
    super.dispose();
  }
}
