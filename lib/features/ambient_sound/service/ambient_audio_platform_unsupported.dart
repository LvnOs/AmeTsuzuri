import 'ambient_audio_platform.dart';

// Compile-time fallback only. Step 1 does not provide native audio playback.
AmbientAudioPlatform createAmbientAudioPlatform() {
  return _UnsupportedAmbientAudioPlatform();
}

class _UnsupportedAmbientAudioPlatform implements AmbientAudioPlatform {
  UnsupportedError get _error =>
      UnsupportedError('AmbientAudioService is only available on Flutter Web.');

  @override
  Future<void> activate() => Future<void>.error(_error);

  @override
  Future<void> prepare() => Future<void>.error(_error);

  @override
  void startLoop() => throw _error;

  @override
  void stop() {}

  @override
  Future<void> dispose() async {}
}
