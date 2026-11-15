abstract interface class AmbientAudioPlatform {
  Future<void> activate();

  Future<void> prepare();

  void startLoop();

  void stop();

  Future<void> dispose();
}
