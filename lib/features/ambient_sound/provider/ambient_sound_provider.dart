import 'dart:async';

import 'package:flutter/foundation.dart';

import '../../../shared/model/weather_type.dart';
import '../repository/ambient_sound_repository.dart';
import '../service/ambient_audio_service.dart';

enum AmbientSoundUiState {
  off,
  playing,
  weatherPaused,
  resumeRequired,
  temporarilyPaused,
}

class AmbientSoundProvider extends ChangeNotifier {
  AmbientSoundProvider(this._repository, this._audioService) {
    _audioService.stateListenable.addListener(_handleAudioStateChanged);
  }

  final AmbientSoundRepository _repository;
  final AmbientAudioService _audioService;

  bool _isLoaded = false;
  bool _isEnabled = false;
  WeatherType? _effectiveWeather;
  bool _isVisible = true;
  bool _requiresUserResume = false;
  bool _hasSessionPlaybackPermission = false;
  Object? _lastError;
  Future<void>? _loadFuture;
  Future<void>? _userActionFuture;
  Future<void>? _playbackFuture;
  int _playbackGeneration = 0;
  bool _isDisposed = false;

  bool get isLoaded => _isLoaded;
  bool get isEnabled => _isEnabled;
  WeatherType? get effectiveWeather => _effectiveWeather;
  bool get isVisible => _isVisible;
  bool get requiresUserResume => _requiresUserResume;
  Object? get lastError => _lastError;

  AmbientSoundUiState get uiState {
    if (!_isLoaded || !_isEnabled) {
      return AmbientSoundUiState.off;
    }
    if (_effectiveWeather != WeatherType.rain) {
      return AmbientSoundUiState.weatherPaused;
    }
    if (_requiresUserResume) {
      return AmbientSoundUiState.resumeRequired;
    }
    if (!_isVisible ||
        _audioService.state.status == AmbientAudioStatus.loading) {
      return AmbientSoundUiState.temporarilyPaused;
    }
    if (_audioService.state.status == AmbientAudioStatus.playing) {
      return AmbientSoundUiState.playing;
    }
    return AmbientSoundUiState.resumeRequired;
  }

  Future<void> load() {
    if (_isLoaded) {
      return Future<void>.value();
    }
    final pendingLoad = _loadFuture;
    if (pendingLoad != null) {
      return pendingLoad;
    }

    late final Future<void> operation;
    operation = _loadInternal().whenComplete(() {
      if (identical(_loadFuture, operation)) {
        _loadFuture = null;
      }
    });
    _loadFuture = operation;
    return operation;
  }

  Future<void> handleUserTap() {
    if (!_isLoaded) {
      return Future<void>.error(
        StateError('AmbientSoundProvider has not been loaded.'),
      );
    }
    final pendingAction = _userActionFuture;
    if (pendingAction != null) {
      return pendingAction;
    }

    late final Future<void> operation;
    operation = _handleUserTapInternal().whenComplete(() {
      if (identical(_userActionFuture, operation)) {
        _userActionFuture = null;
      }
    });
    _userActionFuture = operation;
    return operation;
  }

  Future<void> updateEffectiveWeather(WeatherType? weather) async {
    if (_isDisposed || weather == _effectiveWeather) {
      return;
    }

    final previousWeather = _effectiveWeather;
    _effectiveWeather = weather;

    if (weather != WeatherType.rain) {
      _cancelPlayback(pause: false);
      _notifyListeners();
      return;
    }

    if (previousWeather == WeatherType.sunny && _canResumeAutomatically) {
      await _attemptPlayback(resume: false);
      return;
    }

    if (_isLoaded && _isEnabled && previousWeather == null) {
      _requiresUserResume = true;
    }
    _notifyListeners();
  }

  Future<void> updateVisibility(bool isVisible) async {
    if (_isDisposed || isVisible == _isVisible) {
      return;
    }

    _isVisible = isVisible;
    if (!isVisible) {
      _cancelPlayback(pause: true);
      _notifyListeners();
      return;
    }

    _notifyListeners();
    if (_canResumeAutomatically) {
      await _attemptPlayback(resume: true);
    }
  }

  bool get _canResumeAutomatically =>
      _isLoaded &&
      _isEnabled &&
      _isVisible &&
      _effectiveWeather == WeatherType.rain &&
      _hasSessionPlaybackPermission &&
      !_requiresUserResume;

  Future<void> _loadInternal() async {
    try {
      final isEnabled = await _repository.loadEnabled();
      if (_isDisposed) {
        return;
      }

      _isEnabled = isEnabled;
      _isLoaded = true;
      _requiresUserResume = isEnabled;
      _hasSessionPlaybackPermission = false;
      _lastError = null;
      _notifyListeners();
    } catch (error) {
      if (!_isDisposed) {
        _lastError = error;
        _notifyListeners();
      }
      rethrow;
    }
  }

  Future<void> _handleUserTapInternal() async {
    if (_isEnabled &&
        _requiresUserResume &&
        _effectiveWeather == WeatherType.rain) {
      await _attemptPlayback(resume: false);
      return;
    }
    if (_isEnabled) {
      await _disableFromUserAction();
      return;
    }
    await _enableFromUserAction();
  }

  Future<void> _enableFromUserAction() async {
    _lastError = null;
    final shouldPlayNow = _effectiveWeather == WeatherType.rain && _isVisible;

    // Start playback before awaiting persistence so AudioContext.resume()
    // remains in the browser's user gesture.
    final playbackFuture = shouldPlayNow
        ? _attemptPlayback(resume: false)
        : null;

    try {
      await _repository.saveEnabled(true);
    } catch (error) {
      _cancelPlayback(pause: false);
      if (!_isDisposed) {
        _isEnabled = false;
        _requiresUserResume = false;
        _hasSessionPlaybackPermission = false;
        _lastError = error;
        _notifyListeners();
      }
      rethrow;
    }

    if (_isDisposed) {
      return;
    }

    _isEnabled = true;
    if (playbackFuture == null) {
      _hasSessionPlaybackPermission = true;
      _requiresUserResume = _effectiveWeather == WeatherType.rain;
      _notifyListeners();
      return;
    }

    await playbackFuture;
    if (_isDisposed) {
      return;
    }
    // A pending save can outlast a rejected or cancelled playback attempt.
    if (!_hasSessionPlaybackPermission ||
        (_effectiveWeather == WeatherType.rain &&
            _isVisible &&
            !_audioService.state.isPlaying)) {
      _requiresUserResume = true;
    }
    _notifyListeners();
  }

  Future<void> _disableFromUserAction() async {
    _cancelPlayback(pause: false);
    _requiresUserResume = true;
    _notifyListeners();

    try {
      await _repository.saveEnabled(false);
    } catch (error) {
      if (!_isDisposed) {
        _lastError = error;
        _notifyListeners();
      }
      rethrow;
    }

    if (_isDisposed) {
      return;
    }
    _isEnabled = false;
    _requiresUserResume = false;
    _hasSessionPlaybackPermission = false;
    _lastError = null;
    _notifyListeners();
  }

  Future<void> _attemptPlayback({required bool resume}) {
    final pendingPlayback = _playbackFuture;
    if (pendingPlayback != null) {
      return pendingPlayback;
    }

    final generation = ++_playbackGeneration;
    _requiresUserResume = false;
    _lastError = null;

    // Keep this call before any await to preserve a user gesture when this
    // method is reached from handleUserTap().
    final serviceFuture = resume
        ? _audioService.resume()
        : _audioService.play();

    late final Future<void> operation;
    operation = _completePlayback(serviceFuture, generation).whenComplete(() {
      if (identical(_playbackFuture, operation)) {
        _playbackFuture = null;
      }
    });
    _playbackFuture = operation;
    _notifyListeners();
    return operation;
  }

  Future<void> _completePlayback(
    Future<void> serviceFuture,
    int generation,
  ) async {
    try {
      await serviceFuture;
      if (!_isCurrentPlayback(generation)) {
        return;
      }
      final isPlaying =
          _audioService.state.status == AmbientAudioStatus.playing;
      _requiresUserResume = !isPlaying;
      _hasSessionPlaybackPermission = isPlaying;
    } catch (error) {
      if (!_isCurrentPlayback(generation)) {
        return;
      }
      _requiresUserResume = true;
      _hasSessionPlaybackPermission = false;
      _lastError = error;
    }
    _notifyListeners();
  }

  void _cancelPlayback({required bool pause}) {
    _playbackGeneration++;
    _playbackFuture = null;
    if (pause) {
      _audioService.pause();
    } else {
      _audioService.stop();
    }
  }

  bool _isCurrentPlayback(int generation) {
    return !_isDisposed && generation == _playbackGeneration;
  }

  void _handleAudioStateChanged() {
    if (_isDisposed) {
      return;
    }

    final audioState = _audioService.state;
    if (audioState.status == AmbientAudioStatus.playing &&
        _isEnabled &&
        _effectiveWeather == WeatherType.rain &&
        _isVisible) {
      _requiresUserResume = false;
      _hasSessionPlaybackPermission = true;
      _lastError = null;
    } else if (audioState.status == AmbientAudioStatus.error) {
      if (_isEnabled && _effectiveWeather == WeatherType.rain) {
        _requiresUserResume = true;
      }
      _hasSessionPlaybackPermission = false;
      _lastError = audioState.error;
    }
    _notifyListeners();
  }

  void _notifyListeners() {
    if (!_isDisposed) {
      notifyListeners();
    }
  }

  @override
  void dispose() {
    if (_isDisposed) {
      return;
    }
    _isDisposed = true;
    _playbackGeneration++;
    _playbackFuture = null;
    _audioService.stateListenable.removeListener(_handleAudioStateChanged);
    _audioService.stop();
    unawaited(_audioService.dispose());
    super.dispose();
  }
}
