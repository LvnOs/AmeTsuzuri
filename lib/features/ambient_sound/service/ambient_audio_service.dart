import 'package:flutter/foundation.dart';

import 'ambient_audio_platform.dart';
import 'ambient_audio_platform_unsupported.dart'
    if (dart.library.js_interop) 'ambient_audio_platform_web.dart'
    as platform;

enum AmbientAudioStatus { stopped, loading, playing, paused, error, disposed }

@immutable
class AmbientAudioState {
  const AmbientAudioState({required this.status, this.error, this.stackTrace});

  const AmbientAudioState.stopped()
    : status = AmbientAudioStatus.stopped,
      error = null,
      stackTrace = null;

  final AmbientAudioStatus status;
  final Object? error;
  final StackTrace? stackTrace;

  bool get isPlaying => status == AmbientAudioStatus.playing;
}

class AmbientAudioService {
  AmbientAudioService() : _platform = platform.createAmbientAudioPlatform();

  @visibleForTesting
  AmbientAudioService.withPlatform(this._platform);

  final AmbientAudioPlatform _platform;
  final ValueNotifier<AmbientAudioState> _stateNotifier =
      ValueNotifier<AmbientAudioState>(const AmbientAudioState.stopped());

  int _operationGeneration = 0;
  bool _isDisposed = false;
  bool _isStateNotifierDisposed = false;
  Future<void>? _disposeFuture;

  AmbientAudioState get state => _stateNotifier.value;

  ValueListenable<AmbientAudioState> get stateListenable => _stateNotifier;

  Future<void> play() => _startPlayback();

  void stop() {
    if (_isDisposed) {
      return;
    }
    _operationGeneration++;
    _platform.stop();
    _setState(const AmbientAudioState(status: AmbientAudioStatus.stopped));
  }

  void pause() {
    if (_isDisposed) {
      return;
    }
    _operationGeneration++;
    _platform.stop();
    _setState(const AmbientAudioState(status: AmbientAudioStatus.paused));
  }

  Future<void> resume() => _startPlayback();

  Future<void> dispose() {
    final disposeFuture = _disposeFuture;
    if (disposeFuture != null) {
      return disposeFuture;
    }

    _isDisposed = true;
    _operationGeneration++;
    _platform.stop();
    _setState(const AmbientAudioState(status: AmbientAudioStatus.disposed));

    final future = _disposePlatform();
    _disposeFuture = future;
    return future;
  }

  Future<void> _startPlayback() async {
    if (_isDisposed) {
      throw StateError('AmbientAudioService has been disposed.');
    }

    final generation = ++_operationGeneration;
    _platform.stop();
    _setState(const AmbientAudioState(status: AmbientAudioStatus.loading));

    try {
      // activate() invokes AudioContext.resume() synchronously. Do not add an
      // await before this call or it may leave the browser user gesture.
      final activationFuture = _platform.activate();
      await activationFuture;
      await _platform.prepare();
      if (!_isCurrent(generation)) {
        return;
      }

      _platform.startLoop();
      if (!_isCurrent(generation)) {
        _platform.stop();
        return;
      }
      _setState(const AmbientAudioState(status: AmbientAudioStatus.playing));
    } catch (error, stackTrace) {
      if (!_isCurrent(generation)) {
        return;
      }
      _platform.stop();
      _setState(
        AmbientAudioState(
          status: AmbientAudioStatus.error,
          error: error,
          stackTrace: stackTrace,
        ),
      );
      Error.throwWithStackTrace(error, stackTrace);
    }
  }

  bool _isCurrent(int generation) {
    return !_isDisposed && generation == _operationGeneration;
  }

  void _setState(AmbientAudioState state) {
    if (_isStateNotifierDisposed) {
      return;
    }
    _stateNotifier.value = state;
  }

  Future<void> _disposePlatform() async {
    try {
      await _platform.dispose();
    } finally {
      _isStateNotifierDisposed = true;
      _stateNotifier.dispose();
    }
  }
}
