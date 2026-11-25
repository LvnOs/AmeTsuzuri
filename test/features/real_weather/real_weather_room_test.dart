import 'dart:async';
import 'dart:convert';

import 'package:ame_tsuzuri/app/ame_tsuzuri_app.dart';
import 'package:ame_tsuzuri/features/ambient_sound/provider/ambient_sound_provider.dart';
import 'package:ame_tsuzuri/features/letters/provider/read_letter_provider.dart';
import 'package:ame_tsuzuri/features/real_weather/presentation/real_weather_panel.dart';
import 'package:ame_tsuzuri/features/real_weather/provider/real_weather_provider.dart';
import 'package:ame_tsuzuri/features/real_weather/service/real_weather_service.dart';
import 'package:ame_tsuzuri/features/room/presentation/prototype_controls.dart';
import 'package:ame_tsuzuri/features/room/presentation/widgets/last_raindrop.dart';
import 'package:ame_tsuzuri/features/room/presentation/widgets/rain_overlay.dart';
import 'package:ame_tsuzuri/features/room/presentation/widgets/soft_sunlight.dart';
import 'package:ame_tsuzuri/shared/model/weather_type.dart';
import 'package:ame_tsuzuri/shared/provider/app_data_provider.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';

Future<void> _until(WidgetTester tester, bool Function() ready) async {
  for (var i = 0; i < 70 && !ready(); i++) {
    await tester.pump(const Duration(milliseconds: 50));
  }
  expect(ready(), isTrue);
}

void main() {
  testWidgets('first visit delivers the tutorial without requesting location', (
    tester,
  ) async {
    SharedPreferences.setMockInitialValues({});
    var calls = 0;
    await tester.pumpWidget(
      AmeTsuzuriApp(
        realWeatherService: RealWeatherService(
          locate: () async {
            calls++;
            throw LocationFailure.denied;
          },
        ),
      ),
    );
    final context = tester.element(find.byType(PrototypeControls));
    final read = context.read<ReadLetterProvider>();
    final date = context.read<AppDateProvider>();
    await _until(tester, () => read.hasDeliveredLetterOn(date.today));
    expect(read.deliveredLetterIdOn(date.today), 'tutorial_001');
    expect(find.byType(RealWeatherPanel), findsNothing);
    expect(calls, 0);
  });

  for (final size in const [
    Size(320, 640),
    Size(320, 700),
    Size(375, 640),
    Size(390, 700),
    Size(430, 700),
    Size(320, 360),
    Size(1280, 800),
  ]) {
    testWidgets('設定を開閉してもRoomの配置を保つ $size', (tester) async {
      tester.view.devicePixelRatio = 1;
      tester.view.physicalSize = size;
      tester.view.padding = const FakeViewPadding(top: 24, bottom: 16);
      tester.platformDispatcher.textScaleFactorTestValue = 1.5;
      addTearDown(tester.view.reset);
      addTearDown(tester.platformDispatcher.clearTextScaleFactorTestValue);
      SharedPreferences.setMockInitialValues({
        'readLetterState': jsonEncode({
          'version': 3,
          'receivedLetters': {'tutorial_001': null},
          'deliveredLetters': <String, String>{},
          'hasOpenedTutorialBottle': true,
          'tutorialCompleted': true,
        }),
      });
      await tester.pumpWidget(
        AmeTsuzuriApp(
          realWeatherService: RealWeatherService(
            locate: () async => (latitude: 35.0, longitude: 139.0),
            request: (_) async => (
              status: 200,
              body: '{"current":{"weather_code":0,"rain":0,"showers":0}}',
            ),
          ),
        ),
      );
      final controls = find.byType(PrototypeControls);
      await _until(
        tester,
        () => tester.widget<PrototypeControls>(controls).showWeather,
      );
      final audio = tester.element(controls).read<AmbientSoundProvider>();
      final sound = find.byKey(const ValueKey('ambientSoundButton'));
      final settings = find.byKey(const ValueKey('roomSettings'));
      final scene = find.byWidgetPredicate(
        (w) => w is AspectRatio && (w.aspectRatio - 390 / 700).abs() < 0.0001,
      );
      final rect = tester.getRect(scene);
      expect(settings.hitTestable(), findsOneWidget);
      expect(sound.hitTestable(), findsOneWidget);
      expect(tester.getRect(settings).overlaps(tester.getRect(sound)), isFalse);
      final post = find.byKey(const ValueKey('postTapArea'));
      expect(post.hitTestable(), findsOneWidget);
      await tester.tap(settings);
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 500));
      expect(tester.getRect(scene), rect);
      expect(post.hitTestable(), findsNothing);
      final entry = find.text('Prototypeモードに切り替える');
      await tester.ensureVisible(entry);
      expect(entry.hitTestable(), findsOneWidget);
      if (size.height >= 700) {
        await tester.tapAt(const Offset(8, 30));
      } else {
        await tester.binding.handlePopRoute();
      }
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 500));
      expect(tester.getRect(scene), rect);
      expect(post.hitTestable(), findsOneWidget);
      expect(audio.uiState, AmbientSoundUiState.off);
      final credit = find.text('天気データ：Open-Meteo');
      expect(credit, findsNothing);
      final weather = tester.element(controls).read<RealWeatherProvider>();
      unawaited(weather.enableOrRetry());
      await _until(tester, () => credit.evaluate().isNotEmpty);
      expect(credit.hitTestable(), findsOneWidget);
      expect(tester.getRect(scene), rect);
      final link = find.ancestor(
        of: credit,
        matching: find.byWidgetPredicate(
          (widget) => widget is Semantics && widget.properties.link == true,
        ),
      );
      expect(
        tester.widget<Semantics>(link).properties.linkUrl,
        Uri.parse('https://open-meteo.com/'),
      );
      final creditRect = tester.getRect(
        find.ancestor(of: credit, matching: find.byType(InkWell)).first,
      );
      for (final target in [
        sound,
        settings,
        find.byKey(const ValueKey('rearrangeModeButton')),
        post,
        find.byKey(const ValueKey('bookshelfTapArea')),
        find.byKey(const ValueKey('bottleTapArea')),
      ]) {
        expect(
          creditRect.overlaps(tester.getRect(target)),
          isFalse,
          reason: '$target: ${tester.getRect(target)} overlaps $creditRect',
        );
      }
      expect(rect.contains(creditRect.center), isTrue);
      expect(creditRect.center.dx, closeTo(rect.center.dx, .01));
      expect(creditRect.bottom, lessThan(rect.top + rect.height * .29));
      expect(creditRect.height, closeTo(31, .01));
      final date = tester.element(controls).read<AppDateProvider>();
      await date.setPrototypeMode(true);
      await tester.pump();
      expect(credit, findsNothing);
      expect(tester.takeException(), isNull);
    });
  }

  testWidgets(
    '320 px room: weather transitions preserve controls and stop on opt-out',
    (tester) async {
      tester.view.devicePixelRatio = 1;
      tester.view.physicalSize = const Size(320, 640);
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);
      SharedPreferences.setMockInitialValues({
        'readLetterState': jsonEncode({
          'version': 3,
          'receivedLetters': {'tutorial_001': null},
          'deliveredLetters': <String, String>{},
          'hasOpenedTutorialBottle': true,
          'tutorialCompleted': true,
        }),
      });
      var calls = 0;
      final response = Completer<WeatherResponse>();
      const rain = (
        status: 200,
        body: '{"current":{"weather_code":61,"rain":1,"showers":0}}',
      );
      var responseCount = 0;
      await tester.pumpWidget(
        AmeTsuzuriApp(
          now: () => DateTime(2026, 8, 7),
          realWeatherService: RealWeatherService(
            locate: () async {
              calls++;
              if (calls >= 3) throw LocationFailure.denied;
              return (latitude: 35.0, longitude: 139.0);
            },
            request: (_) async => responseCount++ == 0 ? response.future : rain,
          ),
        ),
      );
      final context = tester.element(find.byType(PrototypeControls));
      final read = context.read<ReadLetterProvider>();
      final date = context.read<AppDateProvider>();
      final audio = context.read<AmbientSoundProvider>();
      final settings = find.byKey(const ValueKey('roomSettings'));
      await _until(
        tester,
        () => tester
            .widget<PrototypeControls>(find.byType(PrototypeControls))
            .showWeather,
      );
      expect(calls, 0);
      await tester.tap(settings);
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 500));
      expect(calls, 0);
      expect(find.text('Open-Meteo'), findsOneWidget);
      expect(find.text('CC BY 4.0'), findsOneWidget);
      expect(find.textContaining('座標を Open-Meteo'), findsOneWidget);
      final start = find.text('現在地の天気を使う');
      await tester.ensureVisible(start);
      await tester.tap(start);
      await tester.pump();
      expect(find.textContaining('現在地の天気を確認中'), findsOneWidget);
      expect(calls, 1);

      expect(find.byType(RainOverlay), findsNothing);
      expect(find.byType(SoftSunlight), findsNothing);
      expect(audio.effectiveWeather, isNull);
      expect(read.hasDeliveredLetterOn(date.today), isFalse);

      response.complete((
        status: 200,
        body: '{"current":{"weather_code":0,"rain":0,"showers":0}}',
      ));
      await _until(tester, () => audio.effectiveWeather == WeatherType.sunny);
      expect(find.byType(SoftSunlight), findsOneWidget);
      expect(find.byType(RainOverlay), findsNothing);
      expect(find.byType(LastRaindrop), findsNothing);
      expect(read.hasDeliveredLetterOn(date.today), isFalse);

      // Keep the asset future independent of the previous test's fake clock.
      rootBundle.evict('assets/data/letters.yaml');
      await tester.runAsync(
        () => rootBundle.loadString('assets/data/letters.yaml'),
      );
      final refresh = find.text('天気を更新する');
      await tester.ensureVisible(refresh);
      await tester.pump();
      await tester.tap(refresh);
      await _until(tester, () => audio.effectiveWeather == WeatherType.rain);
      // Let the platform AssetBundle complete the scheduled summary read.
      await tester.runAsync(() async {});
      await _until(tester, () => read.hasDeliveredLetterOn(date.today));
      final letter = read.deliveredLetterIdOn(date.today);
      expect(letter, isNot('tutorial_001'));
      expect(find.byType(RainOverlay), findsOneWidget);
      expect(find.byType(SoftSunlight), findsNothing);
      expect(audio.effectiveWeather, WeatherType.rain);
      expect(audio.uiState, AmbientSoundUiState.off);
      await tester.pump(const Duration(seconds: 5));

      final weather = context.read<RealWeatherProvider>();
      await weather.refresh(force: true);
      await tester.pump();
      expect(read.deliveredLetters, {'2026-08-07': letter});
      expect(find.text('現在の天気：雨'), findsOneWidget);
      expect(find.text('天気データ：Open-Meteo'), findsOneWidget);
      expect(find.text('ブラウザで位置情報が許可されていません'), findsOneWidget);
      expect(find.text('再試行'), findsOneWidget);
      expect(find.byType(PrototypeControls), findsOneWidget);
      expect(
        find.byKey(const ValueKey('bookshelfTapArea')).hitTestable(),
        findsNothing,
      );
      final stop = find.text('天気の利用をやめる');
      await tester.ensureVisible(stop);
      await tester.pump();
      await tester.tap(stop);
      await tester.pump();
      expect(start, findsOneWidget);
      expect(find.text('天気データ：Open-Meteo'), findsNothing);
      expect(find.byType(RainOverlay), findsNothing);
      expect(find.byType(SoftSunlight), findsNothing);
      expect(audio.effectiveWeather, isNull);
      expect(read.deliveredLetters, {'2026-08-07': letter});
      expect(tester.takeException(), isNull);

      await tester.ensureVisible(start);
      await tester.tap(start);
      await tester.pump();
      expect(find.text('現在地の天気は未確定です'), findsOneWidget);
      expect(find.text('ブラウザで位置情報が許可されていません'), findsOneWidget);
      await tester.ensureVisible(find.byType(CloseButton));
      await tester.tap(find.byType(CloseButton));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 500));
      await date.setPrototypeMode(true);
      await tester.pump();
      expect(find.byType(RealWeatherPanel), findsNothing);
      expect(calls, 4);
      await tester.pumpWidget(const SizedBox());
    },
  );
}
