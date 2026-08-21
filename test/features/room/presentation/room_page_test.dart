import 'dart:async';

import 'package:ame_tsuzuri/features/furniture/provider/catalog_provider.dart';
import 'package:ame_tsuzuri/features/furniture/provider/placed_furniture_provider.dart';
import 'package:ame_tsuzuri/features/furniture/repository/placed_furniture_repository.dart';
import 'package:ame_tsuzuri/features/furniture/repository/purchased_furniture_repository.dart';
import 'package:ame_tsuzuri/features/letters/model/letter.dart';
import 'package:ame_tsuzuri/features/letters/model/read_letter_state.dart';
import 'package:ame_tsuzuri/features/letters/model/shizuku_state.dart';
import 'package:ame_tsuzuri/features/letters/presentation/letter_page.dart';
import 'package:ame_tsuzuri/features/letters/provider/read_letter_provider.dart';
import 'package:ame_tsuzuri/features/letters/provider/shizuku_provider.dart';
import 'package:ame_tsuzuri/features/letters/repository/letter_repository.dart';
import 'package:ame_tsuzuri/features/letters/repository/read_letter_repository.dart';
import 'package:ame_tsuzuri/features/letters/repository/shizuku_repository.dart';
import 'package:ame_tsuzuri/features/room/presentation/room_page.dart';
import 'package:ame_tsuzuri/shared/provider/app_data_provider.dart';
import 'package:ame_tsuzuri/shared/model/weather_type.dart';
import 'package:ame_tsuzuri/shared/model/season_type.dart';
import 'package:ame_tsuzuri/shared/provider/weather_provider.dart';
import 'package:ame_tsuzuri/shared/repository/app_date_repository.dart';
import 'package:ame_tsuzuri/shared/repository/weather_repository.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';

void main() {
  const roomHint = '机や本棚など、気になる場所をタップしてみてください';

  testWidgets('AppDateProvider未ロード中は読み込み表示にする', (tester) async {
    await _pumpRoom(tester, loadAppDateProvider: false);

    expect(find.text('読み込み中です…'), findsOneWidget);
    expect(find.text(roomHint), findsNothing);
  });

  testWidgets('ReadLetterProvider未ロード中は読み込み表示にする', (tester) async {
    await _pumpRoom(tester, loadReadLetterProvider: false);

    expect(find.text('読み込み中です…'), findsOneWidget);
    expect(find.text(roomHint), findsNothing);
  });

  testWidgets('ShizukuProvider未ロード中は読み込み表示にする', (tester) async {
    await _pumpRoom(tester, loadShizukuProvider: false);

    expect(find.text('読み込み中です…'), findsOneWidget);
    expect(find.text(roomHint), findsNothing);
  });

  testWidgets('必要な3 Providerの一部だけロード済みでも読み込み表示を維持する', (tester) async {
    await _pumpRoom(
      tester,
      loadReadLetterProvider: false,
      loadShizukuProvider: false,
    );

    expect(find.text('読み込み中です…'), findsOneWidget);
    expect(find.text(roomHint), findsNothing);
  });

  testWidgets('必要な3 Providerがロード済みなら操作ヒントを表示する', (tester) async {
    await _pumpRoom(tester);

    expect(find.text(roomHint), findsOneWidget);
    expect(find.text('読み込み中です…'), findsNothing);
  });

  testWidgets('Providerのload完了通知で読み込み表示から操作ヒントへ切り替わる', (tester) async {
    final harness = await _pumpRoom(tester, loadProviders: false);

    expect(find.text('読み込み中です…'), findsOneWidget);

    await Future.wait([
      harness.dateProvider.load(),
      harness.readLetterProvider.load(),
      harness.shizukuProvider.load(),
    ]);
    await tester.pump();

    expect(find.text('読み込み中です…'), findsNothing);
    expect(find.text(roomHint), findsOneWidget);
  });

  testWidgets('WeatherProviderが未ロードでも操作ヒントを表示する', (tester) async {
    await _pumpRoom(tester);

    expect(find.text(roomHint), findsOneWidget);
  });

  testWidgets('天候ロード失敗はRoomの操作ヒント表示を妨げない', (tester) async {
    await _pumpRoom(tester, failNextWeatherLoad: true);
    await tester.pumpAndSettle();

    expect(find.text(roomHint), findsOneWidget);
    expect(find.text('読み込み中です…'), findsNothing);
  });

  testWidgets('CatalogとPlacedFurnitureが未ロードでも操作ヒントを表示する', (tester) async {
    await _pumpRoom(
      tester,
      loadCatalogProvider: false,
      loadPlacedFurnitureProvider: false,
    );

    expect(find.text(roomHint), findsOneWidget);
    expect(find.text('読み込み中です…'), findsNothing);
  });

  for (final size in const [Size(320, 700), Size(390, 844)]) {
    testWidgets('スマホ${size.width.toInt()}px幅で3つのテストボタンを表示できる', (tester) async {
      tester.view.devicePixelRatio = 1;
      tester.view.physicalSize = size;
      addTearDown(() {
        tester.view.resetDevicePixelRatio();
        tester.view.resetPhysicalSize();
      });

      final harness = await _pumpRoom(tester);

      expect(find.text('翌日'), findsOneWidget);
      expect(find.text('リセット'), findsOneWidget);
      expect(find.text('瓶テスト'), findsOneWidget);
      expect(tester.takeException(), isNull);

      await tester.tap(find.text('翌日'));
      await tester.pumpAndSettle();

      expect(harness.dateProvider.today, DateTime(2026, 8, 8));
      expect(tester.takeException(), isNull);
    });
  }

  testWidgets('Shizuku未ロード中は瓶テストボタンを無効にする', (tester) async {
    await _pumpRoom(tester, loadShizukuProvider: false);

    final button = tester.widget<ElevatedButton>(
      find.widgetWithText(ElevatedButton, '瓶テスト'),
    );
    expect(button.onPressed, isNull);
  });

  testWidgets('瓶テストは雫と既読を変えず29件に準備する', (tester) async {
    final harness = await _pumpRoom(tester, initialRewardedCount: 10);
    final beforeShizuku = harness.shizukuProvider.currentShizuku;

    final button = tester.widget<ElevatedButton>(
      find.widgetWithText(ElevatedButton, '瓶テスト'),
    );
    expect(button.onPressed, isNotNull);

    await tester.tap(find.text('瓶テスト'));
    await tester.pumpAndSettle();

    expect(find.text('29/30'), findsOneWidget);
    expect(harness.shizukuProvider.bottleRecordCount, 29);
    expect(harness.shizukuProvider.currentShizuku, beforeShizuku);
    expect(harness.readLetterProvider.readLetterIds, isEmpty);
    expect(harness.readLetterProvider.receivedLetters, isEmpty);
    expect(find.text('次の新しい手紙で瓶が満杯になります'), findsOneWidget);
  });

  testWidgets('瓶テスト後の新規手紙で29から30の満杯演出を表示する', (tester) async {
    final harness = await _pumpRoom(tester, initialRewardedCount: 10);

    await tester.tap(find.text('瓶テスト'));
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const ValueKey('deskTapArea')));
    await tester.pump();

    expect(find.text('30/30', skipOffstage: false), findsOneWidget);
    expect(harness.shizukuProvider.currentShizuku, 40);
    expect(harness.shizukuProvider.fullBottleCount, 1);
    expect(harness.shizukuProvider.rewardedLetterIds, contains('letterA'));
    expect(harness.readLetterProvider.readLetterIds, {'letterA'});
    expect(
      harness.readLetterProvider.receivedDateFor('letterA'),
      DateTime(2026, 8, 7),
    );
    expect(
      harness.readLetterProvider.readLetterIds.any(
        (id) => id.startsWith('__prototype_bottle_test_'),
      ),
      isFalse,
    );

    await tester.pump(const Duration(milliseconds: 699));
    expect(find.text('30/30', skipOffstage: false), findsOneWidget);

    await tester.pump(const Duration(milliseconds: 1));
    expect(find.text('0/30', skipOffstage: false), findsOneWidget);
  });

  testWidgets('瓶テスト状態は既存リセットで0件と30滴に戻る', (tester) async {
    final harness = await _pumpRoom(tester, initialRewardedCount: 10);

    await tester.tap(find.text('瓶テスト'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('リセット'));
    await tester.pumpAndSettle();

    expect(find.text('0/30'), findsOneWidget);
    expect(harness.shizukuProvider.currentShizuku, 30);
    expect(harness.shizukuProvider.rewardedLetterIds, isEmpty);
  });

  for (final progress in const [0, 1, 15, 29]) {
    testWidgets('報酬済み$progress件の瓶水位を表示する', (tester) async {
      await _pumpRoom(tester, initialRewardedCount: progress);

      expect(find.text('$progress/30'), findsOneWidget);
    });
  }

  testWidgets('30件ロード済みでは満杯演出なしで空瓶を表示する', (tester) async {
    await _pumpRoom(tester, initialRewardedCount: 30);

    expect(find.text('0/30'), findsOneWidget);
    expect(find.text('30/30'), findsNothing);
  });

  testWidgets('29件から30件になると満杯を短く表示して空瓶へ切り替える', (tester) async {
    final harness = await _pumpRoom(tester, initialRewardedCount: 29);

    await harness.shizukuProvider.rewardForLetter('letter29');
    await tester.pump();
    expect(find.text('30/30'), findsOneWidget);

    await tester.pump(const Duration(milliseconds: 700));
    expect(find.text('0/30'), findsOneWidget);
  });

  testWidgets('30件から31件では通常の1/30を表示する', (tester) async {
    final harness = await _pumpRoom(tester, initialRewardedCount: 30);

    await harness.shizukuProvider.rewardForLetter('letter30');
    await tester.pump();

    expect(find.text('1/30'), findsOneWidget);
    expect(find.text('30/30'), findsNothing);
  });

  testWidgets('59件から60件でも満杯演出を表示する', (tester) async {
    final harness = await _pumpRoom(tester, initialRewardedCount: 59);

    await harness.shizukuProvider.rewardForLetter('letter59');
    await tester.pump();

    expect(find.text('30/30'), findsOneWidget);
  });

  testWidgets('雫の消費と加算では瓶水位が変わらない', (tester) async {
    final harness = await _pumpRoom(tester, initialRewardedCount: 15);

    await harness.shizukuProvider.consumeShizuku(10);
    await tester.pump();
    expect(find.text('15/30'), findsOneWidget);

    await harness.shizukuProvider.addShizuku(20);
    await tester.pump();
    expect(find.text('15/30'), findsOneWidget);
  });

  testWidgets('同じ日は2通目を配信せず今日の手紙を再読する', (tester) async {
    final harness = await _pumpRoom(tester);

    await _openDesk(tester);
    expect(harness.shizukuProvider.currentShizuku, 40);
    expect(harness.shizukuProvider.rewardedLetterIds, {'letterA'});
    expect(harness.readLetterProvider.readLetterIds, {'letterA'});
    expect(find.byType(LetterPage), findsOneWidget);

    await tester.pageBack();
    await tester.pumpAndSettle();
    final receivedLettersBeforeReread = Map.of(
      harness.readLetterProvider.receivedLetters,
    );
    final bottleRecordCountBeforeReread =
        harness.shizukuProvider.bottleRecordCount;
    await _openDesk(tester);
    expect(harness.shizukuProvider.currentShizuku, 40);
    expect(harness.shizukuProvider.rewardedLetterIds, {'letterA'});
    expect(harness.readLetterProvider.readLetterIds, {'letterA'});
    expect(harness.shizukuRepository.saveCallCount, 1);
    expect(harness.readLetterRepository.saveCallCount, 1);
    expect(
      harness.readLetterProvider.receivedLetters,
      receivedLettersBeforeReread,
    );
    expect(
      harness.shizukuProvider.bottleRecordCount,
      bottleRecordCountBeforeReread,
    );
    expect(
      harness.readLetterProvider.receivedDateFor('letterA'),
      DateTime(2026, 8, 7),
    );
    expect(harness.weatherRepository.requestedDates, [DateTime(2026, 8, 7)]);
    expect(harness.letterRepository.getAllCallCount, 2);
    expect(find.byType(LetterPage), findsOneWidget);
    expect(find.text('letterA'), findsWidgets);
  });

  testWidgets('受取履歴の再ロード後も同日の手紙を再読する', (tester) async {
    final harness = await _pumpRoom(tester);

    await _openDesk(tester);
    await tester.pageBack();
    await tester.pumpAndSettle();
    await harness.readLetterProvider.load();
    await _openDesk(tester);

    expect(harness.readLetterProvider.readLetterIds, {'letterA'});
    expect(harness.shizukuProvider.currentShizuku, 40);
    expect(harness.shizukuProvider.rewardedLetterIds, {'letterA'});
    expect(harness.shizukuRepository.saveCallCount, 1);
    expect(harness.readLetterRepository.saveCallCount, 1);
    expect(harness.weatherRepository.requestedDates, [DateTime(2026, 8, 7)]);
    expect(harness.letterRepository.getAllCallCount, 2);
    expect(find.byType(LetterPage), findsOneWidget);
    expect(find.text('letterA'), findsWidgets);
  });

  testWidgets('保存済み受取履歴と日付のロード相当でも当日再読できる', (tester) async {
    final harness = await _pumpRoom(
      tester,
      date: DateTime(2026, 8, 7),
      initialReadState: ReadLetterState(
        receivedLetters: {'letterA': DateTime(2026, 8, 7)},
      ),
      initialShizukuState: const ShizukuState(
        currentShizuku: 40,
        rewardedLetterIds: {'letterA'},
      ),
    );

    await _openDesk(tester);

    expect(find.text('letterA'), findsWidgets);
    expect(harness.shizukuProvider.currentShizuku, 40);
    expect(harness.shizukuRepository.saveCallCount, 0);
    expect(harness.readLetterRepository.saveCallCount, 0);
    expect(
      harness.readLetterProvider.receivedDateFor('letterA'),
      DateTime(2026, 8, 7),
    );
  });

  testWidgets('当日再読は天候に依存せず次の未読手紙を配信しない', (tester) async {
    final harness = await _pumpRoom(tester);

    await _openDesk(tester);
    await tester.pageBack();
    await tester.pumpAndSettle();
    harness.weatherRepository.failNextLoad = true;
    await _openDesk(tester);

    expect(find.text('letterA'), findsWidgets);
    expect(harness.readLetterProvider.readLetterIds, {'letterA'});
    expect(harness.shizukuProvider.rewardedLetterIds, {'letterA'});
    expect(harness.weatherRepository.requestedDates, [DateTime(2026, 8, 7)]);
  });

  testWidgets('当日受取IDがLetterマスタになければ副作用なしで終了する', (tester) async {
    final harness = await _pumpRoom(tester);

    await _openDesk(tester);
    await tester.pageBack();
    await tester.pumpAndSettle();
    harness.letterRepository.letters.clear();
    await _openDesk(tester);

    expect(find.text('今日の手紙を読み込めませんでした'), findsOneWidget);
    expect(find.byType(LetterPage), findsNothing);
    expect(harness.shizukuRepository.saveCallCount, 1);
    expect(harness.readLetterRepository.saveCallCount, 1);
    expect(harness.readLetterProvider.readLetterIds, {'letterA'});
  });

  testWidgets('当日再読のLetter読み込み失敗で新規配信へ進まない', (tester) async {
    final harness = await _pumpRoom(tester);

    await _openDesk(tester);
    await tester.pageBack();
    await tester.pumpAndSettle();
    harness.letterRepository.failNextLoad = true;
    await _openDesk(tester);

    expect(find.text('今日の手紙を読み込めませんでした'), findsOneWidget);
    expect(find.byType(LetterPage), findsNothing);
    expect(harness.shizukuRepository.saveCallCount, 1);
    expect(harness.readLetterRepository.saveCallCount, 1);
    expect(harness.readLetterProvider.readLetterIds, {'letterA'});
  });

  testWidgets('当日再読中の連打でLetterPageを多重pushしない', (tester) async {
    final harness = await _pumpRoom(tester);

    await _openDesk(tester);
    await tester.pageBack();
    await tester.pumpAndSettle();
    harness.letterRepository.blockNextLoad = true;

    await tester.tap(find.byKey(const ValueKey('deskTapArea')));
    await tester.pump();
    await tester.tap(find.byKey(const ValueKey('deskTapArea')));
    await tester.pump();
    expect(harness.letterRepository.getAllCallCount, 2);

    harness.letterRepository.completeLoad();
    await tester.pumpAndSettle();
    expect(find.byType(LetterPage), findsOneWidget);
  });

  testWidgets('履歴をresetすると同じ日でも再び1通受け取れる', (tester) async {
    final harness = await _pumpRoom(tester);

    await _openDesk(tester);
    await tester.pageBack();
    await tester.pumpAndSettle();
    await harness.readLetterProvider.reset();
    await _openDesk(tester);

    expect(harness.readLetterProvider.readLetterIds, {'letterA'});
    expect(find.byType(LetterPage), findsOneWidget);
    expect(harness.weatherRepository.requestedDates, [DateTime(2026, 8, 7)]);
  });

  testWidgets('報酬保存失敗時は既読保存と画面遷移を行わず再試行できる', (tester) async {
    final harness = await _pumpRoom(tester);
    harness.shizukuRepository.failNextSave = true;

    await _openDesk(tester);

    expect(find.text('雫の受け取りに失敗しました'), findsOneWidget);
    expect(find.byType(LetterPage), findsNothing);
    expect(harness.readLetterRepository.saveCallCount, 0);
    expect(harness.shizukuProvider.currentShizuku, 30);

    await _openDesk(tester);
    expect(find.byType(LetterPage), findsOneWidget);
    expect(harness.shizukuProvider.currentShizuku, 40);
    expect(harness.readLetterProvider.readLetterIds, {'letterA'});
  });

  testWidgets('既読保存失敗後は追加報酬なしで既読保存を再試行する', (tester) async {
    final harness = await _pumpRoom(tester);
    harness.readLetterRepository.failNextSave = true;

    await _openDesk(tester);

    expect(find.text('手紙の保存に失敗しました'), findsOneWidget);
    expect(find.byType(LetterPage), findsNothing);
    expect(harness.shizukuProvider.currentShizuku, 40);
    expect(harness.readLetterProvider.readLetterIds, isEmpty);

    await _openDesk(tester);
    expect(find.byType(LetterPage), findsOneWidget);
    expect(harness.shizukuProvider.currentShizuku, 40);
    expect(harness.shizukuRepository.saveCallCount, 1);
    expect(harness.readLetterProvider.readLetterIds, {'letterA'});
  });

  testWidgets('ロード完了前は報酬処理と既読保存を開始しない', (tester) async {
    final harness = await _pumpRoom(tester, loadProviders: false);

    await _openDesk(tester);

    expect(find.text('読み込み中です'), findsOneWidget);
    expect(harness.shizukuRepository.saveCallCount, 0);
    expect(harness.readLetterRepository.saveCallCount, 0);
    expect(find.byType(LetterPage), findsNothing);
  });

  testWidgets('手紙処理中の連打で報酬保存と画面遷移を多重実行しない', (tester) async {
    final harness = await _pumpRoom(tester, blockRewardSave: true);

    await tester.tap(find.byKey(const ValueKey('deskTapArea')));
    await tester.pump();
    await tester.tap(find.byKey(const ValueKey('deskTapArea')));
    await tester.pump();

    expect(harness.shizukuRepository.saveCallCount, 1);
    harness.shizukuRepository.completeSave();
    await tester.pumpAndSettle();

    expect(harness.shizukuProvider.currentShizuku, 40);
    expect(find.byType(LetterPage), findsOneWidget);
  });

  testWidgets('雨の日は雨条件の手紙を開いて報酬と既読を保存する', (tester) async {
    final harness = await _pumpRoom(tester);

    await _openDesk(tester);

    expect(harness.weatherRepository.requestedDates, [DateTime(2026, 8, 7)]);
    expect(harness.shizukuProvider.currentShizuku, 40);
    expect(harness.readLetterProvider.readLetterIds, {'letterA'});
    expect(find.byType(LetterPage), findsOneWidget);
  });

  testWidgets('AppDateProvider.todayを年月日の受取日として保存する', (tester) async {
    final harness = await _pumpRoom(tester, date: DateTime(2026, 8, 10));

    await _openDesk(tester);

    expect(
      harness.readLetterProvider.receivedDateFor('letterA'),
      DateTime(2026, 8, 10),
    );
    expect(
      harness.readLetterRepository.state.receivedLetters['letterA'],
      DateTime(2026, 8, 10),
    );
  });

  testWidgets('晴れの日は雨条件の手紙を開かず副作用を起こさない', (tester) async {
    final harness = await _pumpRoom(tester, weather: WeatherType.sunny);

    await _openDesk(tester);

    expect(find.text('今日の手紙はまだ届いていません'), findsOneWidget);
    expect(harness.shizukuRepository.saveCallCount, 0);
    expect(harness.readLetterRepository.saveCallCount, 0);
    expect(find.byType(LetterPage), findsNothing);
  });

  testWidgets('天候データがない日は副作用を起こさず遷移しない', (tester) async {
    final harness = await _pumpRoom(tester, weather: null);

    await _openDesk(tester);

    expect(find.text('今日の天候を確認できませんでした'), findsOneWidget);
    expect(harness.shizukuRepository.saveCallCount, 0);
    expect(harness.readLetterRepository.saveCallCount, 0);
    expect(harness.letterRepository.getAllCallCount, 0);
    expect(find.byType(LetterPage), findsNothing);
  });

  testWidgets('天候ロード失敗後は副作用なしで再操作できる', (tester) async {
    final harness = await _pumpRoom(tester, failNextWeatherLoad: true);

    await _openDesk(tester);

    expect(find.byType(LetterPage), findsOneWidget);
    expect(harness.shizukuProvider.currentShizuku, 40);
    expect(harness.weatherRepository.requestedDates, [
      DateTime(2026, 8, 7),
      DateTime(2026, 8, 7),
    ]);
  });

  testWidgets('日付変更後は新しい日付を天候取得と次の手紙の受取日に使う', (tester) async {
    final harness = await _pumpRoom(tester);

    await _openDesk(tester);
    await tester.pageBack();
    await tester.pumpAndSettle();
    await _openDesk(tester);
    expect(find.text('letterA'), findsWidgets);
    await tester.pageBack();
    await tester.pumpAndSettle();
    await harness.dateProvider.setDebugDate(DateTime(2026, 8, 8));
    await _openDesk(tester);

    expect(harness.weatherRepository.requestedDates, [
      DateTime(2026, 8, 7),
      DateTime(2026, 8, 8),
    ]);
    expect(
      harness.readLetterProvider.receivedDateFor('letterA'),
      DateTime(2026, 8, 7),
    );
    expect(
      harness.readLetterProvider.receivedDateFor('letterB'),
      DateTime(2026, 8, 8),
    );
    expect(find.byType(LetterPage), findsOneWidget);
  });

  testWidgets('手紙操作では表示中の日付の天候を再ロードしない', (tester) async {
    final harness = await _pumpRoom(tester, weather: WeatherType.sunny);

    await _openDesk(tester);
    expect(find.byType(LetterPage), findsNothing);

    harness.weatherRepository.weather = WeatherType.rain;
    await _openDesk(tester);

    expect(find.byType(LetterPage), findsNothing);
    expect(harness.shizukuProvider.currentShizuku, 30);
    expect(harness.readLetterProvider.readLetterIds, isEmpty);
    expect(harness.weatherRepository.requestedDates, [DateTime(2026, 8, 7)]);
  });

  testWidgets('初期表示で当日の天候を読み込み雨なら演出を表示する', (tester) async {
    final harness = await _pumpRoom(tester);

    await tester.pumpAndSettle();

    expect(harness.weatherRepository.requestedDates, [DateTime(2026, 8, 7)]);
    expect(find.byKey(const ValueKey('rain-overlay')), findsOneWidget);
  });

  testWidgets('晴れまたは天候データなしなら雨演出を表示しない', (tester) async {
    await _pumpRoom(tester, weather: WeatherType.sunny);
    await tester.pumpAndSettle();
    expect(find.byKey(const ValueKey('rain-overlay')), findsNothing);

    await _pumpRoom(tester, weather: null);
    await tester.pumpAndSettle();
    expect(find.byKey(const ValueKey('rain-overlay')), findsNothing);
    expect(find.byType(RoomPage), findsOneWidget);
  });

  testWidgets('日付変更で天候と雨演出を更新する', (tester) async {
    final harness = await _pumpRoom(tester);
    await tester.pumpAndSettle();
    expect(find.byKey(const ValueKey('rain-overlay')), findsOneWidget);

    harness.weatherRepository.weather = WeatherType.sunny;
    await harness.dateProvider.setDebugDate(DateTime(2026, 8, 8));
    await tester.pumpAndSettle();

    expect(harness.weatherRepository.requestedDates, [
      DateTime(2026, 8, 7),
      DateTime(2026, 8, 8),
    ]);
    expect(find.byKey(const ValueKey('rain-overlay')), findsNothing);
  });

  testWidgets('先頭の季節不一致を飛ばしてanyの手紙を配信する', (tester) async {
    final harness = await _pumpRoom(
      tester,
      date: DateTime(2026, 9, 1),
      letters: [
        _letter('summer'),
        _letter('any', season: SeasonType.any),
      ],
    );

    await _openDesk(tester);

    expect(harness.readLetterProvider.readLetterIds, {'any'});
    expect(find.byType(LetterPage), findsOneWidget);
  });

  testWidgets('先頭の天候不一致を飛ばして次の一致手紙を配信する', (tester) async {
    final harness = await _pumpRoom(
      tester,
      letters: [
        _letter('sunny', weather: WeatherType.sunny),
        _letter('rain'),
      ],
    );

    await _openDesk(tester);

    expect(harness.readLetterProvider.readLetterIds, {'rain'});
    expect(find.byType(LetterPage), findsOneWidget);
  });
}

Future<void> _openDesk(WidgetTester tester) async {
  await tester.tap(find.byKey(const ValueKey('deskTapArea')));
  await tester.pumpAndSettle();
}

Future<_RoomHarness> _pumpRoom(
  WidgetTester tester, {
  bool loadProviders = true,
  bool loadAppDateProvider = true,
  bool loadReadLetterProvider = true,
  bool loadShizukuProvider = true,
  bool loadCatalogProvider = true,
  bool loadPlacedFurnitureProvider = true,
  bool blockRewardSave = false,
  WeatherType? weather = WeatherType.rain,
  bool failNextWeatherLoad = false,
  List<Letter>? letters,
  DateTime? date,
  int initialRewardedCount = 0,
  ReadLetterState? initialReadState,
  ShizukuState? initialShizukuState,
}) async {
  final shizukuRepository = _FakeShizukuRepository(
    blockSave: blockRewardSave,
    initialRewardedCount: initialRewardedCount,
    initialState: initialShizukuState,
  );
  final readLetterRepository = _FakeReadLetterRepository(initialReadState);
  final shizukuProvider = ShizukuProvider(shizukuRepository);
  final readLetterProvider = ReadLetterProvider(readLetterRepository);
  final catalogProvider = CatalogProvider(_FakePurchasedFurnitureRepository());
  final placedProvider = PlacedFurnitureProvider(
    _FakePlacedFurnitureRepository(),
  );
  final dateProvider = AppDateProvider(
    _FakeAppDateRepository(date ?? DateTime(2026, 8, 7)),
  );
  final weatherRepository = _FakeWeatherRepository(
    weather: weather,
    failNextLoad: failNextWeatherLoad,
  );
  final weatherProvider = WeatherProvider(weatherRepository);
  final letterRepository = _FakeLetterRepository(letters ?? _defaultLetters);

  if (loadProviders) {
    await Future.wait([
      if (loadShizukuProvider) shizukuProvider.load(),
      if (loadReadLetterProvider) readLetterProvider.load(),
      if (loadCatalogProvider) catalogProvider.load(),
      if (loadPlacedFurnitureProvider) placedProvider.load(),
      if (loadAppDateProvider) dateProvider.load(),
    ]);
  }

  await tester.pumpWidget(
    MultiProvider(
      providers: [
        ChangeNotifierProvider.value(value: shizukuProvider),
        ChangeNotifierProvider.value(value: readLetterProvider),
        ChangeNotifierProvider.value(value: catalogProvider),
        ChangeNotifierProvider.value(value: placedProvider),
        ChangeNotifierProvider.value(value: dateProvider),
        ChangeNotifierProvider.value(value: weatherProvider),
      ],
      child: MaterialApp(home: RoomPage(letterRepository: letterRepository)),
    ),
  );
  await tester.pump();

  return _RoomHarness(
    shizukuRepository: shizukuRepository,
    readLetterRepository: readLetterRepository,
    shizukuProvider: shizukuProvider,
    readLetterProvider: readLetterProvider,
    dateProvider: dateProvider,
    weatherRepository: weatherRepository,
    letterRepository: letterRepository,
  );
}

class _RoomHarness {
  const _RoomHarness({
    required this.shizukuRepository,
    required this.readLetterRepository,
    required this.shizukuProvider,
    required this.readLetterProvider,
    required this.dateProvider,
    required this.weatherRepository,
    required this.letterRepository,
  });

  final _FakeShizukuRepository shizukuRepository;
  final _FakeReadLetterRepository readLetterRepository;
  final ShizukuProvider shizukuProvider;
  final ReadLetterProvider readLetterProvider;
  final AppDateProvider dateProvider;
  final _FakeWeatherRepository weatherRepository;
  final _FakeLetterRepository letterRepository;
}

class _FakeWeatherRepository extends WeatherRepository {
  _FakeWeatherRepository({required this.weather, required this.failNextLoad});

  WeatherType? weather;
  bool failNextLoad;
  final List<DateTime> requestedDates = [];

  @override
  Future<WeatherType?> getByDate(DateTime date) async {
    requestedDates.add(DateTime(date.year, date.month, date.day));
    if (failNextLoad) {
      failNextLoad = false;
      throw StateError('weather load failed');
    }
    return weather;
  }
}

class _FakeLetterRepository extends LetterRepository {
  _FakeLetterRepository(List<Letter> letters) : letters = List.of(letters);

  final List<Letter> letters;
  int getAllCallCount = 0;
  bool failNextLoad = false;
  bool blockNextLoad = false;
  Completer<void>? _loadCompleter;

  @override
  Future<List<Letter>> getAll() async {
    getAllCallCount++;
    if (failNextLoad) {
      failNextLoad = false;
      throw StateError('letter load failed');
    }
    if (blockNextLoad) {
      blockNextLoad = false;
      _loadCompleter = Completer<void>();
      await _loadCompleter!.future;
    }
    return letters;
  }

  void completeLoad() {
    final completer = _loadCompleter;
    if (completer != null && !completer.isCompleted) {
      completer.complete();
    }
  }
}

final List<Letter> _defaultLetters = [_letter('letterA'), _letter('letterB')];

Letter _letter(
  String id, {
  SeasonType season = SeasonType.summer,
  WeatherType weather = WeatherType.rain,
}) {
  return Letter(
    id: id,
    title: id,
    requiredSeason: season,
    requiredWeather: weather,
    body: id,
  );
}

class _FakeShizukuRepository extends ShizukuRepository {
  _FakeShizukuRepository({
    required this.blockSave,
    this.initialRewardedCount = 0,
    ShizukuState? initialState,
  }) : state = initialState ?? ShizukuState(
         currentShizuku: 30,
         rewardedLetterIds: {
           for (var index = 0; index < initialRewardedCount; index++)
             'letter$index',
         },
       );

  final bool blockSave;
  final int initialRewardedCount;
  final Completer<void> _saveCompleter = Completer<void>();
  ShizukuState state;
  bool failNextSave = false;
  int saveCallCount = 0;

  @override
  Future<ShizukuState> loadState() async => state;

  @override
  Future<void> saveState(ShizukuState nextState) async {
    saveCallCount++;
    if (failNextSave) {
      failNextSave = false;
      throw StateError('save failed');
    }
    if (blockSave) {
      await _saveCompleter.future;
    }
    state = nextState;
  }

  @override
  Future<void> resetState() async {
    state = const ShizukuState(currentShizuku: 30, rewardedLetterIds: {});
  }

  void completeSave() {
    if (!_saveCompleter.isCompleted) {
      _saveCompleter.complete();
    }
  }
}

class _FakeReadLetterRepository extends ReadLetterRepository {
  _FakeReadLetterRepository([ReadLetterState? initialState])
    : state = initialState ?? ReadLetterState(receivedLetters: {});

  ReadLetterState state;
  bool failNextSave = false;
  int saveCallCount = 0;

  Set<String> get persistedIds => state.readLetterIds;

  @override
  Future<ReadLetterState> loadState() async => state;

  @override
  Future<void> saveState(ReadLetterState nextState) async {
    saveCallCount++;
    if (failNextSave) {
      failNextSave = false;
      throw StateError('save failed');
    }
    state = nextState;
  }

  @override
  Future<void> resetState() async {
    state = ReadLetterState(receivedLetters: {});
  }
}

class _FakePurchasedFurnitureRepository extends PurchasedFurnitureRepository {
  @override
  Future<Set<String>> loadPurchasedFurnitureIds() async => {};
}

class _FakePlacedFurnitureRepository extends PlacedFurnitureRepository {
  @override
  Future<Map<String, String>> loadPlacedFurnitureIds() async => {};
}

class _FakeAppDateRepository extends AppDateRepository {
  _FakeAppDateRepository(this.savedDate);

  DateTime? savedDate;

  @override
  Future<DateTime?> load() async => savedDate;

  @override
  Future<void> save(DateTime date) async {
    savedDate = date;
  }

  @override
  Future<void> clear() async {
    savedDate = null;
  }
}
