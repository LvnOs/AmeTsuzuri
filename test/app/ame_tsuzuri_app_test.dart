import 'dart:async';

import 'package:ame_tsuzuri/app/ame_tsuzuri_app.dart';
import 'package:ame_tsuzuri/features/ambient_sound/provider/ambient_sound_provider.dart';
import 'package:ame_tsuzuri/features/ambient_sound/repository/ambient_sound_repository.dart';
import 'package:ame_tsuzuri/features/ambient_sound/service/ambient_audio_platform.dart';
import 'package:ame_tsuzuri/features/ambient_sound/service/ambient_audio_service.dart';
import 'package:ame_tsuzuri/features/bookshelf/presentation/bookshelf_page.dart';
import 'package:ame_tsuzuri/features/furniture/presentation/catalog_page.dart';
import 'package:ame_tsuzuri/features/letters/model/letter.dart';
import 'package:ame_tsuzuri/features/letters/presentation/letter_page.dart';
import 'package:ame_tsuzuri/features/letters/provider/read_letter_provider.dart';
import 'package:ame_tsuzuri/features/real_weather/provider/real_weather_provider.dart';
import 'package:ame_tsuzuri/features/real_weather/service/real_weather_service.dart';
import 'package:ame_tsuzuri/features/room/presentation/prototype_controls.dart';
import 'package:ame_tsuzuri/features/room/presentation/widgets/last_raindrop.dart';
import 'package:ame_tsuzuri/shared/model/season_type.dart';
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

  testWidgets('Prototypeの日付変更で未確定を挟む場合は再生操作を待つ', (tester) async {
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
          provider.uiState == AmbientSoundUiState.resumeRequired,
    );
    expect(platform.startCount, 1);
  });

  testWidgets('Prototypeの雨上がりとOverrideは通常モードに引き継がない', (tester) async {
    final today = DateTime(2026, 8, 7);
    await tester.pumpWidget(
      AmeTsuzuriApp(
        now: () => today,
        weatherRepository: _DateWeatherRepository({
          DateTime(2026, 8, 6): WeatherType.rain,
          today: WeatherType.sunny,
        }),
      ),
    );
    final controls = find.byType(PrototypeControls);
    final context = tester.element(controls);
    final date = context.read<AppDateProvider>();
    final ambient = context.read<AmbientSoundProvider>();
    await _pumpUntil(
      tester,
      () => ambient.effectiveWeather == WeatherType.sunny,
    );
    expect(find.byType(LastRaindrop), findsOneWidget);
    tester
        .widget<PrototypeControls>(controls)
        .onWeatherChanged(WeatherType.rain);
    await tester.pump();
    expect(ambient.effectiveWeather, WeatherType.rain);

    await date.setPrototypeMode(false);
    await tester.pump();
    expect(ambient.effectiveWeather, isNull);
    expect(find.byType(LastRaindrop), findsNothing);
    await date.setPrototypeMode(true);
    await tester.pump();
    expect(ambient.effectiveWeather, WeatherType.rain);
  });

  for (final (description, elapsed, page) in [
    (
      '手紙でのキャッシュ期限切れ',
      const Duration(minutes: 31),
      const LetterPage(
        letter: Letter(
          id: 'test',
          title: '手紙',
          body: '本文',
          requiredSeason: SeasonType.any,
          requiredWeather: WeatherType.rain,
        ),
      ),
    ),
    ('目録でのキャッシュ期限切れ', const Duration(minutes: 31), const CatalogPage()),
    ('本棚での日付跨ぎ', const Duration(minutes: 2), const BookshelfPage()),
  ]) {
    testWidgets('$description後に旧い雨音を再開しない', (tester) async {
      SharedPreferences.setMockInitialValues({
        'weatherLocationSetting': 'enabled',
      });
      var now = DateTime(2026, 8, 7, 23, elapsed.inMinutes == 2 ? 59 : 0);
      final platform = _FakeAudioPlatform();
      var fetches = 0;
      final staleResponse = Completer<WeatherResponse>();
      final nextResponse = Completer<WeatherResponse>();
      await tester.pumpWidget(
        AmeTsuzuriApp(
          now: () => now,
          ambientSoundRepository: _CountingAmbientSoundRepository(),
          ambientAudioService: AmbientAudioService.withPlatform(platform),
          realWeatherService: RealWeatherService(
            locate: () async => (latitude: 35.0, longitude: 139.0),
            request: (_) async {
              fetches++;
              if (fetches == 2) return staleResponse.future;
              if (fetches == 3) return nextResponse.future;
              return (
                status: 200,
                body: '{"current":{"weather_code":61,"rain":1,"showers":0}}',
              );
            },
          ),
        ),
      );
      final ambient = _ambientSoundProvider(tester);
      await _pumpUntil(
        tester,
        () => ambient.isLoaded && ambient.effectiveWeather == WeatherType.rain,
      );
      await ambient.handleUserTap();
      expect(platform.startCount, 1);

      final roomContext = tester.element(find.byType(PrototypeControls));
      unawaited(
        Navigator.of(
          roomContext,
        ).push(MaterialPageRoute<void>(builder: (_) => page)),
      );
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 350));
      expect(find.byType(page.runtimeType), findsOneWidget);
      expect(ambient.uiState, AmbientSoundUiState.playing);

      final weather = roomContext.read<RealWeatherProvider>();
      final stale = weather.refresh(force: true);
      await tester.pump();
      expect(fetches, 2);
      tester.binding.handleAppLifecycleStateChanged(AppLifecycleState.hidden);
      // Advance the clock without pumping a frame or the expiry timer.
      now = now.add(elapsed);
      tester.binding.handleAppLifecycleStateChanged(AppLifecycleState.resumed);
      await tester.pump();
      expect(ambient.effectiveWeather, isNull);
      expect(ambient.uiState, AmbientSoundUiState.weatherPaused);
      expect(platform.startCount, 1);
      expect(fetches, 3);
      staleResponse.complete((
        status: 200,
        body: '{"current":{"weather_code":0,"rain":0,"showers":0}}',
      ));
      await stale;
      await tester.pump();
      expect(ambient.effectiveWeather, isNull);

      nextResponse.complete((
        status: 200,
        body: '{"current":{"weather_code":61,"rain":1,"showers":0}}',
      ));
      await _pumpUntil(
        tester,
        () => ambient.effectiveWeather == WeatherType.rain,
      );
      expect(ambient.uiState, AmbientSoundUiState.resumeRequired);
      expect(platform.startCount, 1);
      await tester.pumpWidget(const SizedBox());
    });
  }
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
