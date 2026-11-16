import 'dart:async';

import 'package:ame_tsuzuri/features/ambient_sound/provider/ambient_sound_provider.dart';
import 'package:ame_tsuzuri/features/ambient_sound/repository/ambient_sound_repository.dart';
import 'package:ame_tsuzuri/features/ambient_sound/service/ambient_audio_platform.dart';
import 'package:ame_tsuzuri/features/ambient_sound/service/ambient_audio_service.dart';
import 'package:ame_tsuzuri/shared/model/weather_type.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('load and initial weather', () {
    for (final testCase in [
      (
        enabled: false,
        weather: WeatherType.rain,
        expected: AmbientSoundUiState.off,
      ),
      (
        enabled: false,
        weather: WeatherType.sunny,
        expected: AmbientSoundUiState.off,
      ),
      (
        enabled: true,
        weather: WeatherType.rain,
        expected: AmbientSoundUiState.resumeRequired,
      ),
      (
        enabled: true,
        weather: WeatherType.sunny,
        expected: AmbientSoundUiState.weatherPaused,
      ),
    ]) {
      test(
        'enabled=${testCase.enabled}, weather=${testCase.weather.name}',
        () async {
          final harness = _ProviderHarness(savedEnabled: testCase.enabled);
          addTearDown(harness.provider.dispose);

          await harness.provider.updateEffectiveWeather(testCase.weather);
          await harness.provider.load();

          expect(harness.provider.isLoaded, isTrue);
          expect(harness.provider.isEnabled, testCase.enabled);
          expect(harness.provider.uiState, testCase.expected);
          expect(harness.audioPlatform.startCount, 0);
        },
      );
    }
  });

  test('ON操作は保存を待つ前にplayを開始する', () async {
    late final _ProviderHarness harness;
    harness = _ProviderHarness(
      onSave: (_) {
        expect(harness.audioPlatform.activateCount, 1);
      },
    );
    addTearDown(harness.provider.dispose);
    await harness.provider.load();
    await harness.provider.updateEffectiveWeather(WeatherType.rain);

    await harness.provider.handleUserTap();

    expect(harness.repository.savedEnabled, isTrue);
    expect(harness.provider.isEnabled, isTrue);
    expect(harness.provider.uiState, AmbientSoundUiState.playing);
    expect(harness.audioPlatform.startCount, 1);
  });

  test('sunny中のONは保存だけ行いrainへの変化でplayを試みる', () async {
    final harness = _ProviderHarness();
    addTearDown(harness.provider.dispose);
    await harness.provider.load();
    await harness.provider.updateEffectiveWeather(WeatherType.sunny);

    await harness.provider.handleUserTap();

    expect(harness.provider.uiState, AmbientSoundUiState.weatherPaused);
    expect(harness.audioPlatform.startCount, 0);

    await harness.provider.updateEffectiveWeather(WeatherType.rain);

    expect(harness.audioPlatform.startCount, 1);
    expect(harness.provider.uiState, AmbientSoundUiState.playing);
  });

  test('reload直後のresumeRequired tapはOFFにせず再生を試す', () async {
    final harness = _ProviderHarness(savedEnabled: true);
    addTearDown(harness.provider.dispose);
    await harness.provider.updateEffectiveWeather(WeatherType.rain);
    await harness.provider.load();

    await harness.provider.handleUserTap();

    expect(harness.repository.saveCount, 0);
    expect(harness.provider.isEnabled, isTrue);
    expect(harness.provider.uiState, AmbientSoundUiState.playing);
    expect(harness.audioPlatform.startCount, 1);
  });

  test('play中のOFF操作は即時停止してfalseを保存する', () async {
    final harness = _ProviderHarness();
    addTearDown(harness.provider.dispose);
    await harness.provider.load();
    await harness.provider.updateEffectiveWeather(WeatherType.rain);
    await harness.provider.handleUserTap();

    final stopCountBefore = harness.audioPlatform.stopCount;
    await harness.provider.handleUserTap();

    expect(harness.audioPlatform.stopCount, greaterThan(stopCountBefore));
    expect(harness.repository.savedEnabled, isFalse);
    expect(harness.provider.isEnabled, isFalse);
    expect(harness.provider.uiState, AmbientSoundUiState.off);
  });

  test('連打は同じ保存操作を共有して二重playしない', () async {
    final saveCompleter = Completer<void>();
    final harness = _ProviderHarness(saveCompleter: saveCompleter);
    addTearDown(harness.provider.dispose);
    await harness.provider.load();
    await harness.provider.updateEffectiveWeather(WeatherType.rain);

    final firstTap = harness.provider.handleUserTap();
    final secondTap = harness.provider.handleUserTap();
    saveCompleter.complete();
    await Future.wait([firstTap, secondTap]);

    expect(harness.repository.saveCount, 1);
    expect(harness.audioPlatform.activateCount, 1);
    expect(harness.audioPlatform.startCount, 1);
  });

  test('同じWeatherの繰り返し通知ではplayを増やさない', () async {
    final harness = _ProviderHarness(savedEnabled: true);
    addTearDown(harness.provider.dispose);
    await harness.provider.load();
    await harness.provider.updateEffectiveWeather(WeatherType.sunny);
    await harness.provider.updateEffectiveWeather(WeatherType.rain);

    await harness.provider.updateEffectiveWeather(WeatherType.rain);

    expect(harness.audioPlatform.startCount, 1);
  });

  test('rainからsunnyへの変化は停止してweatherPausedになる', () async {
    final harness = _ProviderHarness();
    addTearDown(harness.provider.dispose);
    await harness.provider.load();
    await harness.provider.updateEffectiveWeather(WeatherType.rain);
    await harness.provider.handleUserTap();

    await harness.provider.updateEffectiveWeather(WeatherType.sunny);

    expect(harness.audioService.state.isPlaying, isFalse);
    expect(harness.provider.isEnabled, isTrue);
    expect(harness.provider.uiState, AmbientSoundUiState.weatherPaused);
  });

  test('sunnyからrainへの変化は保存ONならplayを試す', () async {
    final harness = _ProviderHarness(savedEnabled: true);
    addTearDown(harness.provider.dispose);
    await harness.provider.load();
    await harness.provider.updateEffectiveWeather(WeatherType.sunny);

    await harness.provider.updateEffectiveWeather(WeatherType.rain);

    expect(harness.audioPlatform.activateCount, 1);
    expect(harness.provider.uiState, AmbientSoundUiState.playing);
  });

  test('hiddenでpauseしresumedで許可済み再生を再開する', () async {
    final harness = _ProviderHarness();
    addTearDown(harness.provider.dispose);
    await harness.provider.load();
    await harness.provider.updateEffectiveWeather(WeatherType.rain);
    await harness.provider.handleUserTap();

    await harness.provider.updateVisibility(false);

    expect(harness.audioService.state.status, AmbientAudioStatus.paused);
    expect(harness.provider.uiState, AmbientSoundUiState.temporarilyPaused);

    await harness.provider.updateVisibility(true);

    expect(harness.audioPlatform.startCount, 2);
    expect(harness.provider.uiState, AmbientSoundUiState.playing);
  });

  test('reload直後の未許可状態ではhiddenからresumedでも再生しない', () async {
    final harness = _ProviderHarness(savedEnabled: true);
    addTearDown(harness.provider.dispose);
    await harness.provider.updateEffectiveWeather(WeatherType.rain);
    await harness.provider.load();

    await harness.provider.updateVisibility(false);
    await harness.provider.updateVisibility(true);

    expect(harness.audioPlatform.startCount, 0);
    expect(harness.provider.uiState, AmbientSoundUiState.resumeRequired);
  });

  test('再生拒否でもONを維持してresumeRequiredになる', () async {
    final error = StateError('autoplay rejected');
    final harness = _ProviderHarness(activateError: error);
    addTearDown(harness.provider.dispose);
    await harness.provider.load();
    await harness.provider.updateEffectiveWeather(WeatherType.rain);

    await harness.provider.handleUserTap();

    expect(harness.repository.savedEnabled, isTrue);
    expect(harness.provider.isEnabled, isTrue);
    expect(harness.provider.requiresUserResume, isTrue);
    expect(harness.provider.lastError, same(error));
    expect(harness.provider.uiState, AmbientSoundUiState.resumeRequired);
  });

  test('ON保存失敗時は再生を止めてOFFを維持する', () async {
    final harness = _ProviderHarness(failSave: true);
    addTearDown(harness.provider.dispose);
    await harness.provider.load();
    await harness.provider.updateEffectiveWeather(WeatherType.rain);

    await expectLater(harness.provider.handleUserTap(), throwsStateError);

    expect(harness.provider.isEnabled, isFalse);
    expect(harness.audioService.state.isPlaying, isFalse);
    expect(harness.provider.uiState, AmbientSoundUiState.off);
  });

  test('OFF保存失敗時はONを維持してresumeRequiredになる', () async {
    final harness = _ProviderHarness();
    addTearDown(harness.provider.dispose);
    await harness.provider.load();
    await harness.provider.updateEffectiveWeather(WeatherType.rain);
    await harness.provider.handleUserTap();
    harness.repository.failSave = true;

    await expectLater(harness.provider.handleUserTap(), throwsStateError);

    expect(harness.provider.isEnabled, isTrue);
    expect(harness.audioService.state.isPlaying, isFalse);
    expect(harness.provider.uiState, AmbientSoundUiState.resumeRequired);
  });

  test('load中のWeather変更は保存ONの自動再生を開始しない', () async {
    final loadCompleter = Completer<bool>();
    final harness = _ProviderHarness(loadCompleter: loadCompleter);
    addTearDown(harness.provider.dispose);

    final loadFuture = harness.provider.load();
    await harness.provider.updateEffectiveWeather(WeatherType.sunny);
    await harness.provider.updateEffectiveWeather(WeatherType.rain);
    loadCompleter.complete(true);
    await loadFuture;

    expect(harness.audioPlatform.startCount, 0);
    expect(harness.provider.uiState, AmbientSoundUiState.resumeRequired);
  });

  test('dispose中にloadが完了しても状態を反映しない', () async {
    final loadCompleter = Completer<bool>();
    final harness = _ProviderHarness(loadCompleter: loadCompleter);

    final loadFuture = harness.provider.load();
    harness.provider.dispose();
    loadCompleter.complete(true);
    await loadFuture;
    await Future<void>.delayed(Duration.zero);

    expect(harness.provider.isLoaded, isFalse);
    expect(harness.audioPlatform.disposeCount, 1);
    expect(harness.audioPlatform.startCount, 0);
  });
}

class _ProviderHarness {
  _ProviderHarness({
    bool savedEnabled = false,
    Completer<bool>? loadCompleter,
    Completer<void>? saveCompleter,
    bool failSave = false,
    Object? activateError,
    void Function(bool)? onSave,
  }) : repository = _FakeAmbientSoundRepository(
         savedEnabled: savedEnabled,
         loadCompleter: loadCompleter,
         saveCompleter: saveCompleter,
         failSave: failSave,
         onSave: onSave,
       ),
       audioPlatform = _FakeAmbientAudioPlatform(activateError: activateError) {
    audioService = AmbientAudioService.withPlatform(audioPlatform);
    provider = AmbientSoundProvider(repository, audioService);
  }

  final _FakeAmbientSoundRepository repository;
  final _FakeAmbientAudioPlatform audioPlatform;
  late final AmbientAudioService audioService;
  late final AmbientSoundProvider provider;
}

class _FakeAmbientSoundRepository extends AmbientSoundRepository {
  _FakeAmbientSoundRepository({
    required this.savedEnabled,
    this.loadCompleter,
    this.saveCompleter,
    this.failSave = false,
    this.onSave,
  });

  bool savedEnabled;
  final Completer<bool>? loadCompleter;
  final Completer<void>? saveCompleter;
  bool failSave;
  final void Function(bool)? onSave;
  int loadCount = 0;
  int saveCount = 0;

  @override
  Future<bool> loadEnabled() {
    loadCount++;
    return loadCompleter?.future ?? Future<bool>.value(savedEnabled);
  }

  @override
  Future<void> saveEnabled(bool isEnabled) async {
    saveCount++;
    onSave?.call(isEnabled);
    if (failSave) {
      throw StateError('save failed');
    }
    await saveCompleter?.future;
    savedEnabled = isEnabled;
  }
}

class _FakeAmbientAudioPlatform implements AmbientAudioPlatform {
  _FakeAmbientAudioPlatform({this.activateError});

  final Object? activateError;
  int activateCount = 0;
  int prepareCount = 0;
  int startCount = 0;
  int stopCount = 0;
  int disposeCount = 0;

  @override
  Future<void> activate() {
    activateCount++;
    final error = activateError;
    return error == null ? Future<void>.value() : Future<void>.error(error);
  }

  @override
  Future<void> prepare() async {
    prepareCount++;
  }

  @override
  void startLoop() {
    startCount++;
  }

  @override
  void stop() {
    stopCount++;
  }

  @override
  Future<void> dispose() async {
    disposeCount++;
  }
}
