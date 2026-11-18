import 'dart:async';

import 'package:ame_tsuzuri/app/ame_tsuzuri_app.dart';
import 'package:ame_tsuzuri/features/ambient_sound/provider/ambient_sound_provider.dart';
import 'package:ame_tsuzuri/features/ambient_sound/repository/ambient_sound_repository.dart';
import 'package:ame_tsuzuri/features/ambient_sound/service/ambient_audio_platform.dart';
import 'package:ame_tsuzuri/features/ambient_sound/service/ambient_audio_service.dart';
import 'package:ame_tsuzuri/features/letters/provider/read_letter_provider.dart';
import 'package:ame_tsuzuri/features/room/presentation/prototype_controls.dart';
import 'package:ame_tsuzuri/shared/model/weather_type.dart';
import 'package:ame_tsuzuri/shared/provider/app_data_provider.dart';
import 'package:ame_tsuzuri/shared/repository/weather_repository.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUp(() {
    SharedPreferences.setMockInitialValues({
      'prototypeDateModeEnabled': true,
      'prototypeDate': DateTime(2026, 8, 7).toIso8601String(),
    });
  });

  testWidgets('新規ユーザーには端末の日付でチュートリアルの手紙が届く', (tester) async {
    SharedPreferences.setMockInitialValues({});
    await tester.pumpWidget(
      AmeTsuzuriApp(
        ambientAudioService: AmbientAudioService.withPlatform(
          _FakeAudioPlatform(),
        ),
        weatherRepository: _RainWeatherRepository(),
      ),
    );
    final context = tester.element(find.byType(PrototypeControls));
    final dateProvider = context.read<AppDateProvider>();
    final read = context.read<ReadLetterProvider>();

    await _pumpUntil(
      tester,
      () => read.hasDeliveredLetterOn(dateProvider.today),
    );
    expect(dateProvider.isDebugDateEnabled, isFalse);
    expect(dateProvider.today, DateUtils.dateOnly(DateTime.now()));
    expect(read.deliveredLetterIdOn(dateProvider.today), 'tutorial_001');
    expect(find.text('通常プレイの日付について'), findsNothing);
  });

  testWidgets('rootで単一Providerを生成しload一回とdisposeを管理する', (tester) async {
    final repository = _CountingAmbientSoundRepository();
    final service = AmbientAudioService.withPlatform(_FakeAudioPlatform());
    final app = AmeTsuzuriApp(
      ambientSoundRepository: repository,
      ambientAudioService: service,
      weatherRepository: _RainWeatherRepository(),
    );

    await tester.pumpWidget(app);
    final firstProvider = _ambientSoundProvider(tester);
    await _pumpUntil(tester, () => firstProvider.isLoaded);
    expect(firstProvider.isLoaded, isTrue);
    expect(repository.loadCount, 1);

    await tester.pumpWidget(app);
    await tester.pump();

    expect(_ambientSoundProvider(tester), same(firstProvider));
    expect(repository.loadCount, 1);

    await tester.pumpWidget(const SizedBox());
    await tester.pump();

    expect(service.state.status, AmbientAudioStatus.disposed);
  });

  testWidgets('effectiveWeatherを初回・override・画面遷移中も同期する', (tester) async {
    final repository = _CountingAmbientSoundRepository();
    final service = AmbientAudioService.withPlatform(_FakeAudioPlatform());

    await tester.pumpWidget(
      AmeTsuzuriApp(
        ambientSoundRepository: repository,
        ambientAudioService: service,
        weatherRepository: _RainWeatherRepository(),
      ),
    );
    final ambientSoundProvider = _ambientSoundProvider(tester);
    await _pumpUntil(
      tester,
      () => ambientSoundProvider.effectiveWeather != null,
    );
    expect(ambientSoundProvider.effectiveWeather, WeatherType.rain);

    final controls = tester.widget<PrototypeControls>(
      find.byType(PrototypeControls),
    );
    controls.onWeatherChanged(WeatherType.sunny);
    await tester.pump();
    await tester.pump();
    expect(ambientSoundProvider.effectiveWeather, WeatherType.sunny);

    final roomContext = tester.element(find.byType(PrototypeControls));
    unawaited(
      Navigator.of(
        roomContext,
      ).push(MaterialPageRoute<void>(builder: (_) => const Scaffold())),
    );
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 300));

    controls.onWeatherChanged(WeatherType.rain);
    await tester.pump();
    await tester.pump();
    expect(ambientSoundProvider.effectiveWeather, WeatherType.rain);
  });

  testWidgets('hiddenでpauseしresumedで許可済み再生を再開する', (tester) async {
    final repository = _CountingAmbientSoundRepository(isEnabled: true);
    final platform = _FakeAudioPlatform();
    final service = AmbientAudioService.withPlatform(platform);

    await tester.pumpWidget(
      AmeTsuzuriApp(
        ambientSoundRepository: repository,
        ambientAudioService: service,
        weatherRepository: _RainWeatherRepository(),
      ),
    );
    final provider = _ambientSoundProvider(tester);
    await _pumpUntil(
      tester,
      () => provider.isLoaded && provider.effectiveWeather != null,
    );
    expect(provider.uiState, AmbientSoundUiState.resumeRequired);
    await provider.handleUserTap();
    expect(provider.uiState, AmbientSoundUiState.playing);
    expect(platform.startCount, 1);

    tester.binding.handleAppLifecycleStateChanged(AppLifecycleState.hidden);
    await tester.pump();
    expect(provider.isVisible, isFalse);
    expect(provider.uiState, AmbientSoundUiState.temporarilyPaused);

    tester.binding.handleAppLifecycleStateChanged(AppLifecycleState.resumed);
    await tester.pump();
    await tester.pump();
    expect(provider.isVisible, isTrue);
    expect(provider.uiState, AmbientSoundUiState.playing);
    expect(platform.startCount, 2);

    await tester.pumpWidget(const SizedBox());
    tester.binding.handleAppLifecycleStateChanged(AppLifecycleState.hidden);
    await tester.pump();
    expect(tester.takeException(), isNull);
  });

  testWidgets('Weather読込中のnullを挟んでもrain→sunny→rainを維持する', (tester) async {
    final repository = _CountingAmbientSoundRepository(isEnabled: true);
    final platform = _FakeAudioPlatform();
    final service = AmbientAudioService.withPlatform(platform);

    await tester.pumpWidget(
      AmeTsuzuriApp(
        ambientSoundRepository: repository,
        ambientAudioService: service,
        weatherRepository: _DateWeatherRepository({
          DateTime(2026, 8, 7): WeatherType.rain,
          DateTime(2026, 8, 8): WeatherType.sunny,
          DateTime(2026, 8, 9): WeatherType.rain,
        }),
      ),
    );
    final provider = _ambientSoundProvider(tester);
    await _pumpUntil(
      tester,
      () => provider.effectiveWeather == WeatherType.rain,
    );

    await provider.handleUserTap();
    expect(platform.startCount, 1);

    final context = tester.element(find.byType(MaterialApp));
    final dateProvider = context.read<AppDateProvider>();
    await dateProvider.setDebugDate(DateTime(2026, 8, 8));
    await _pumpUntil(
      tester,
      () => provider.effectiveWeather == WeatherType.sunny,
    );
    expect(provider.uiState, AmbientSoundUiState.weatherPaused);

    await dateProvider.setDebugDate(DateTime(2026, 8, 9));
    await _pumpUntil(
      tester,
      () =>
          provider.effectiveWeather == WeatherType.rain &&
          provider.uiState == AmbientSoundUiState.playing,
    );
    expect(platform.startCount, 2);
  });
}

AmbientSoundProvider _ambientSoundProvider(WidgetTester tester) {
  final context = tester.element(find.byType(MaterialApp));
  return context.read<AmbientSoundProvider>();
}

Future<void> _pumpUntil(WidgetTester tester, bool Function() condition) async {
  for (var index = 0; index < 100 && !condition(); index++) {
    await tester.pump(const Duration(milliseconds: 10));
  }
  expect(condition(), isTrue);
}

class _CountingAmbientSoundRepository extends AmbientSoundRepository {
  _CountingAmbientSoundRepository({this.isEnabled = false});

  bool isEnabled;
  int loadCount = 0;

  @override
  Future<bool> loadEnabled() async {
    loadCount++;
    return isEnabled;
  }

  @override
  Future<void> saveEnabled(bool isEnabled) async {
    this.isEnabled = isEnabled;
  }
}

class _FakeAudioPlatform implements AmbientAudioPlatform {
  int startCount = 0;

  @override
  Future<void> activate() async {}

  @override
  Future<void> prepare() async {}

  @override
  void startLoop() {
    startCount++;
  }

  @override
  void stop() {}

  @override
  Future<void> dispose() async {}
}

class _RainWeatherRepository extends WeatherRepository {
  @override
  Future<WeatherType?> getByDate(DateTime date) async => WeatherType.rain;
}

class _DateWeatherRepository extends WeatherRepository {
  _DateWeatherRepository(this.weatherByDate);

  final Map<DateTime, WeatherType> weatherByDate;

  @override
  Future<WeatherType?> getByDate(DateTime date) async {
    return weatherByDate[DateTime(date.year, date.month, date.day)];
  }
}
