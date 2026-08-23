import 'dart:async';

import 'package:ame_tsuzuri/features/furniture/provider/catalog_provider.dart';
import 'package:ame_tsuzuri/features/furniture/provider/placed_furniture_provider.dart';
import 'package:ame_tsuzuri/features/furniture/presentation/catalog_page.dart';
import 'package:ame_tsuzuri/features/furniture/model/furniture.dart';
import 'package:ame_tsuzuri/features/furniture/repository/furniture_repository.dart';
import 'package:ame_tsuzuri/features/furniture/repository/placed_furniture_repository.dart';
import 'package:ame_tsuzuri/features/furniture/repository/purchased_furniture_repository.dart';
import 'package:ame_tsuzuri/features/bookshelf/presentation/bookshelf_page.dart';
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
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  const roomHint = '机や本棚など、気になる場所をタップしてみてください';
  const guideTitle = '雨つづり。へようこそ';
  const guideContent =
      '雨の日には、机に手紙が届きます。\n'
      '手紙を開くと雫がたまり、家具を迎えられます。\n'
      '瓶から家具目録を開き、迎えた家具を配置できます。\n'
      '本棚では、届いた手紙をいつでも読み返せます。';

  group('初回案内', () {
    testWidgets('Providerロード前は案内を表示せず読み込み中にする', (tester) async {
      await _pumpRoom(tester, loadProviders: false, dismissInitialGuide: false);

      expect(find.text('読み込み中です…'), findsOneWidget);
      expect(find.text(guideTitle), findsNothing);
    });

    testWidgets('ロード完了後の受取履歴が空なら短い案内を表示する', (tester) async {
      await _pumpRoom(tester, dismissInitialGuide: false);

      expect(find.text(guideTitle), findsOneWidget);
      expect(find.text(guideContent), findsOneWidget);
      expect(find.text('はじめる'), findsOneWidget);
    });

    testWidgets('案内を閉じると下部ヒントへ移り再buildで再表示しない', (tester) async {
      final harness = await _pumpRoom(tester, dismissInitialGuide: false);

      await tester.tap(find.text('はじめる'));
      await tester.pumpAndSettle();
      expect(find.text(guideTitle), findsNothing);
      expect(find.text(roomHint), findsOneWidget);

      await harness.dateProvider.setDebugDate(DateTime(2026, 8, 8));
      await tester.pump();
      expect(find.text(guideTitle), findsNothing);
    });

    testWidgets('受取日ありの履歴があれば案内を表示しない', (tester) async {
      await _pumpRoom(
        tester,
        dismissInitialGuide: false,
        initialReadState: ReadLetterState(
          receivedLetters: {'letterA': DateTime(2026, 8, 7)},
        ),
      );

      expect(find.text(guideTitle), findsNothing);
      expect(find.text(roomHint), findsOneWidget);
    });

    testWidgets('null受取日の旧履歴でも非空なら案内を表示しない', (tester) async {
      await _pumpRoom(
        tester,
        dismissInitialGuide: false,
        initialReadState: ReadLetterState(receivedLetters: {'legacy': null}),
      );

      expect(find.text(guideTitle), findsNothing);
    });

    testWidgets('同じRoomPageで案内を閉じてリセットしても再表示しない', (tester) async {
      await _pumpRoom(tester, dismissInitialGuide: false);
      await tester.tap(find.text('はじめる'));
      await tester.pumpAndSettle();

      await tester.tap(find.text('リセット'));
      await tester.pumpAndSettle();

      expect(find.text(guideTitle), findsNothing);
    });

    testWidgets('受取履歴が空の新しいRoomPageなら案内を再表示する', (tester) async {
      await _pumpRoom(tester, dismissInitialGuide: false);
      await tester.tap(find.text('はじめる'));
      await tester.pumpAndSettle();

      await tester.pumpWidget(const SizedBox.shrink());
      await tester.pump();
      await _pumpRoom(tester, dismissInitialGuide: false);

      expect(find.text(guideTitle), findsOneWidget);
    });

    testWidgets('320px幅で案内文とボタンがoverflowしない', (tester) async {
      tester.view.devicePixelRatio = 1;
      tester.view.physicalSize = const Size(320, 640);
      addTearDown(() {
        tester.view.resetDevicePixelRatio();
        tester.view.resetPhysicalSize();
      });

      await _pumpRoom(tester, dismissInitialGuide: false);

      expect(find.text(guideTitle), findsOneWidget);
      expect(find.text(guideContent), findsOneWidget);
      expect(find.text('はじめる'), findsOneWidget);
      expect(tester.takeException(), isNull);
    });
  });

  testWidgets('完全新規日付から8月7日の初回案内と最初の手紙受取が成立する', (tester) async {
    SharedPreferences.setMockInitialValues({});
    final harness = await _pumpRoom(
      tester,
      appDateRepository: AppDateRepository(),
    );

    expect(harness.dateProvider.today, DateTime(2026, 8, 7));
    await _openDesk(tester);

    expect(find.byType(LetterPage), findsOneWidget);
    expect(harness.shizukuProvider.currentShizuku, 40);
    expect(
      harness.readLetterProvider.receivedDateFor('letterA'),
      DateTime(2026, 8, 7),
    );
    expect(harness.weatherRepository.requestedDates, [DateTime(2026, 8, 7)]);
  });

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
  group('今日の手紙の配達表示', () {
    testWidgets('未配達で候補があれば配達してletterレイヤーを表示する', (tester) async {
      final harness = await _pumpRoom(tester);
      await tester.pumpAndSettle();

      expect(
        harness.readLetterProvider.deliveredLetterIdOn(DateTime(2026, 8, 7)),
        'letterA',
      );
      expect(find.byKey(const ValueKey('roomLetterLayer')), findsOneWidget);
      expect(harness.letterRepository.getAllCallCount, 1);
      expect(harness.weatherRepository.requestedDates, [DateTime(2026, 8, 7)]);
    });

    testWidgets('配達済み未読なら候補を再選択せずletterレイヤーを表示する', (tester) async {
      final harness = await _pumpRoom(
        tester,
        initialReadState: ReadLetterState(
          receivedLetters: {},
          deliveredLetters: {'2026-08-07': 'letterA'},
        ),
      );

      expect(find.byKey(const ValueKey('roomLetterLayer')), findsOneWidget);
      expect(harness.letterRepository.getAllCallCount, 0);
      expect(harness.weatherRepository.requestedDates, isEmpty);
    });

    testWidgets('配達済み既読でも当日はletterレイヤーを表示する', (tester) async {
      final harness = await _pumpRoom(
        tester,
        initialReadState: ReadLetterState(
          receivedLetters: {'letterA': DateTime(2026, 8, 7)},
          deliveredLetters: {'2026-08-07': 'letterA'},
        ),
      );

      expect(find.byKey(const ValueKey('roomLetterLayer')), findsOneWidget);
      expect(harness.letterRepository.getAllCallCount, 0);
    });

    testWidgets('今日の候補がなければ配達せずletterレイヤーを表示しない', (tester) async {
      final harness = await _pumpRoom(tester, weather: WeatherType.sunny);
      await tester.pumpAndSettle();

      expect(
        harness.readLetterProvider.hasDeliveredLetterOn(DateTime(2026, 8, 7)),
        isFalse,
      );
      expect(find.byKey(const ValueKey('roomLetterLayer')), findsNothing);
    });

    testWidgets('別日の配達IDだけでは今日のletterレイヤーを表示しない', (tester) async {
      await _pumpRoom(
        tester,
        weather: WeatherType.sunny,
        initialReadState: ReadLetterState(
          receivedLetters: {},
          deliveredLetters: {'2026-08-06': 'letterA'},
        ),
      );
      await tester.pumpAndSettle();

      expect(find.byKey(const ValueKey('roomLetterLayer')), findsNothing);
    });

    testWidgets('必要Providerのロード前は配達処理を開始しない', (tester) async {
      final harness = await _pumpRoom(tester, loadProviders: false);
      await tester.pumpAndSettle();

      expect(harness.letterRepository.getAllCallCount, 0);
      expect(harness.weatherRepository.requestedDates, isEmpty);
      expect(harness.readLetterProvider.deliveredLetters, isEmpty);
      expect(find.byKey(const ValueKey('roomLetterLayer')), findsNothing);
    });

    testWidgets('配達保存失敗時は配達済みとして表示しない', (tester) async {
      final harness = await _pumpRoom(tester, failNextReadSave: true);
      await tester.pumpAndSettle();

      expect(harness.readLetterProvider.deliveredLetters, isEmpty);
      expect(find.byKey(const ValueKey('roomLetterLayer')), findsNothing);
    });

    testWidgets('同日の再buildでは2通目を選択しない', (tester) async {
      final harness = await _pumpRoom(tester);
      await tester.pumpAndSettle();
      expect(harness.letterRepository.getAllCallCount, 1);

      await tester.pump();
      await tester.pump();

      expect(harness.letterRepository.getAllCallCount, 1);
      expect(
        harness.readLetterProvider.deliveredLetterIdOn(DateTime(2026, 8, 7)),
        'letterA',
      );
    });
  });

  group('今日の手紙を開く', () {
    testWidgets('未配達時はletterTapAreaが存在しない', (tester) async {
      await _pumpRoom(tester, weather: WeatherType.sunny);
      await tester.pumpAndSettle();

      expect(find.byKey(const ValueKey('letterTapArea')), findsNothing);
    });

    testWidgets('配達済み未読の確定IDを開いて初回だけ報酬と既読を保存する', (tester) async {
      final harness = await _pumpRoom(
        tester,
        initialReadState: ReadLetterState(
          receivedLetters: {},
          deliveredLetters: {'2026-08-07': 'letterB'},
        ),
      );

      expect(find.byKey(const ValueKey('letterTapArea')), findsOneWidget);
      await _tapLetter(tester);

      expect(find.byType(LetterPage), findsOneWidget);
      expect(find.text('letterB'), findsWidgets);
      expect(harness.shizukuProvider.currentShizuku, 40);
      expect(harness.shizukuProvider.rewardedLetterIds, {'letterB'});
      expect(harness.readLetterProvider.readLetterIds, {'letterB'});
      expect(
        harness.readLetterProvider.receivedDateFor('letterB'),
        DateTime(2026, 8, 7),
      );
      expect(harness.letterRepository.getAllCallCount, 1);
      expect(harness.weatherRepository.requestedDates, isEmpty);

      await tester.pageBack();
      await tester.pumpAndSettle();
      expect(find.byKey(const ValueKey('roomLetterLayer')), findsOneWidget);
      expect(find.byKey(const ValueKey('letterTapArea')), findsOneWidget);
    });

    testWidgets('既読状態では報酬と既読保存なしで同じ手紙を再読できる', (tester) async {
      final harness = await _pumpRoom(
        tester,
        initialReadState: ReadLetterState(
          receivedLetters: {'letterB': DateTime(2026, 8, 7)},
          deliveredLetters: {'2026-08-07': 'letterB'},
        ),
        initialShizukuState: const ShizukuState(
          currentShizuku: 40,
          rewardedLetterIds: {'letterB'},
        ),
      );

      await _tapLetter(tester);
      expect(find.text('letterB'), findsWidgets);
      await tester.pageBack();
      await tester.pumpAndSettle();
      await _tapLetter(tester);

      expect(find.text('letterB'), findsWidgets);
      expect(harness.shizukuProvider.currentShizuku, 40);
      expect(harness.shizukuRepository.saveCallCount, 0);
      expect(harness.readLetterRepository.saveCallCount, 0);
      expect(harness.letterRepository.getAllCallCount, 2);
    });

    testWidgets('連続タップでも報酬・既読保存・画面pushを一度だけ行う', (tester) async {
      final harness = await _pumpRoom(
        tester,
        initialReadState: ReadLetterState(
          receivedLetters: {},
          deliveredLetters: {'2026-08-07': 'letterA'},
        ),
      );
      harness.letterRepository.blockNextLoad = true;

      await tester.tap(find.byKey(const ValueKey('letterTapArea')));
      await tester.pump();
      await tester.tap(find.byKey(const ValueKey('letterTapArea')));
      await tester.pump();
      expect(harness.letterRepository.getAllCallCount, 1);

      harness.letterRepository.completeLoad();
      await tester.pumpAndSettle();

      expect(find.byType(LetterPage), findsOneWidget);
      expect(harness.shizukuRepository.saveCallCount, 1);
      expect(harness.readLetterRepository.saveCallCount, 1);
    });

    testWidgets('Providerロード前はletterTapAreaを表示せず副作用を起こさない', (tester) async {
      final harness = await _pumpRoom(tester, loadProviders: false);

      expect(find.byKey(const ValueKey('letterTapArea')), findsNothing);
      expect(harness.letterRepository.getAllCallCount, 0);
      expect(harness.shizukuRepository.saveCallCount, 0);
      expect(harness.readLetterRepository.saveCallCount, 0);
    });

    testWidgets('Shizuku未ロードでも最初のタップを保持してロード後に手紙を開く', (tester) async {
      final harness = await _pumpRoom(
        tester,
        loadShizukuProvider: false,
        blockNextShizukuLoad: true,
        initialReadState: ReadLetterState(
          receivedLetters: {},
          deliveredLetters: {'2026-08-07': 'letterA'},
        ),
      );

      expect(find.byKey(const ValueKey('letterTapArea')), findsOneWidget);
      await tester.tap(find.byKey(const ValueKey('letterTapArea')));
      await tester.pump();
      await tester.tap(find.byKey(const ValueKey('letterTapArea')));
      await tester.pump();

      expect(harness.shizukuRepository.loadCallCount, 1);
      expect(harness.letterRepository.getAllCallCount, 0);

      harness.shizukuRepository.completeLoad();
      await tester.pumpAndSettle();

      expect(find.byType(LetterPage), findsOneWidget);
      expect(harness.shizukuRepository.saveCallCount, 1);
      expect(harness.readLetterRepository.saveCallCount, 1);
      expect(harness.letterRepository.getAllCallCount, 1);
    });

    testWidgets('Shizukuロード失敗後は状態を変えず再タップで再試行できる', (tester) async {
      final harness = await _pumpRoom(
        tester,
        loadShizukuProvider: false,
        failNextShizukuLoad: true,
        initialReadState: ReadLetterState(
          receivedLetters: {},
          deliveredLetters: {'2026-08-07': 'letterA'},
        ),
      );

      await tester.tap(find.byKey(const ValueKey('letterTapArea')));
      await tester.pump();

      expect(tester.takeException(), isNull);
      expect(find.byType(LetterPage), findsNothing);
      expect(harness.shizukuRepository.saveCallCount, 0);
      expect(harness.readLetterRepository.saveCallCount, 0);

      await tester.tap(find.byKey(const ValueKey('letterTapArea')));
      await tester.pumpAndSettle();

      expect(harness.shizukuRepository.loadCallCount, 2);
      expect(find.byType(LetterPage), findsOneWidget);
    });

    testWidgets('Shizukuロード待機中に日付が変わったら古い手紙を開かない', (tester) async {
      final harness = await _pumpRoom(
        tester,
        loadShizukuProvider: false,
        blockNextShizukuLoad: true,
        weather: null,
        initialReadState: ReadLetterState(
          receivedLetters: {},
          deliveredLetters: {'2026-08-07': 'letterA'},
        ),
      );

      await tester.tap(find.byKey(const ValueKey('letterTapArea')));
      await tester.pump();
      await harness.dateProvider.setDebugDate(DateTime(2026, 8, 8));
      await tester.pump();
      harness.shizukuRepository.completeLoad();
      await tester.pumpAndSettle();

      expect(find.byType(LetterPage), findsNothing);
      expect(harness.shizukuRepository.saveCallCount, 0);
      expect(harness.readLetterRepository.saveCallCount, 0);
    });

    testWidgets('Shizukuロード待機中に配達IDが変わったら古い手紙を開かない', (tester) async {
      final harness = await _pumpRoom(
        tester,
        loadShizukuProvider: false,
        blockNextShizukuLoad: true,
        initialReadState: ReadLetterState(
          receivedLetters: {},
          deliveredLetters: {'2026-08-07': 'letterA'},
        ),
      );

      await tester.tap(find.byKey(const ValueKey('letterTapArea')));
      await tester.pump();
      harness.readLetterRepository.state = ReadLetterState(
        receivedLetters: {},
        deliveredLetters: {'2026-08-07': 'letterB'},
      );
      await harness.readLetterProvider.load();
      harness.shizukuRepository.completeLoad();
      await tester.pumpAndSettle();

      expect(find.byType(LetterPage), findsNothing);
      expect(harness.shizukuRepository.saveCallCount, 0);
      expect(harness.readLetterRepository.saveCallCount, 0);
    });

    testWidgets('既読手紙もShizuku未ロード時の最初のタップで再読できる', (tester) async {
      final harness = await _pumpRoom(
        tester,
        loadShizukuProvider: false,
        blockNextShizukuLoad: true,
        initialReadState: ReadLetterState(
          receivedLetters: {'letterA': DateTime(2026, 8, 7)},
          deliveredLetters: {'2026-08-07': 'letterA'},
        ),
      );

      await tester.tap(find.byKey(const ValueKey('letterTapArea')));
      await tester.pump();
      harness.shizukuRepository.completeLoad();
      await tester.pumpAndSettle();

      expect(find.byType(LetterPage), findsOneWidget);
      expect(harness.shizukuRepository.saveCallCount, 0);
      expect(harness.readLetterRepository.saveCallCount, 0);
    });

    testWidgets('既読保存失敗時は遷移せず配達済み表示を維持する', (tester) async {
      final harness = await _pumpRoom(
        tester,
        failNextReadSave: true,
        initialReadState: ReadLetterState(
          receivedLetters: {},
          deliveredLetters: {'2026-08-07': 'letterA'},
        ),
      );

      await _tapLetter(tester);

      expect(find.byType(LetterPage), findsNothing);
      expect(harness.shizukuProvider.currentShizuku, 40);
      expect(harness.readLetterProvider.readLetterIds, isEmpty);
      expect(
        harness.readLetterProvider.deliveredLetterIdOn(DateTime(2026, 8, 7)),
        'letterA',
      );
      expect(find.byKey(const ValueKey('letterTapArea')), findsOneWidget);

      await _tapLetter(tester);

      expect(find.byType(LetterPage), findsOneWidget);
      expect(harness.shizukuProvider.currentShizuku, 40);
      expect(harness.shizukuRepository.saveCallCount, 1);
      expect(harness.readLetterProvider.readLetterIds, {'letterA'});
    });

    testWidgets('報酬保存失敗時は既読保存と遷移を行わない', (tester) async {
      final harness = await _pumpRoom(
        tester,
        initialReadState: ReadLetterState(
          receivedLetters: {},
          deliveredLetters: {'2026-08-07': 'letterA'},
        ),
      );
      harness.shizukuRepository.failNextSave = true;

      await _tapLetter(tester);

      expect(find.byType(LetterPage), findsNothing);
      expect(harness.shizukuProvider.currentShizuku, 30);
      expect(harness.readLetterProvider.readLetterIds, isEmpty);
      expect(harness.readLetterRepository.saveCallCount, 0);
      expect(find.byKey(const ValueKey('letterTapArea')), findsOneWidget);
    });
  });

  group('Roomオブジェクトからの画面遷移', () {
    testWidgets('瓶と本棚の透明タップ領域が存在する', (tester) async {
      await _pumpRoom(tester);

      expect(find.byKey(const ValueKey('bottleTapArea')), findsOneWidget);
      expect(find.byKey(const ValueKey('bookshelfTapArea')), findsOneWidget);

      final bottleSize = tester.getSize(
        find.byKey(const ValueKey('bottleTapArea')),
      );
      expect(bottleSize.width, greaterThan(50));
      expect(bottleSize.height, greaterThan(bottleSize.width));
    });

    testWidgets('瓶タップでCatalogPageを開く', (tester) async {
      await _pumpRoom(tester);

      await tester.tap(find.byKey(const ValueKey('bottleTapArea')));
      await _pumpRouteTransition(tester);

      expect(find.byType(CatalogPage), findsOneWidget);
    });

    testWidgets('本棚タップでBookshelfPageを開く', (tester) async {
      await _pumpRoom(tester);

      await tester.tap(find.byKey(const ValueKey('bookshelfTapArea')));
      await _pumpRouteTransition(tester);

      expect(find.byType(BookshelfPage), findsOneWidget);
    });

    testWidgets('瓶の連続タップでCatalogPageを複数pushしない', (tester) async {
      await _pumpRoom(tester);

      final detector = tester.widget<GestureDetector>(
        find.byKey(const ValueKey('bottleTapArea')),
      );
      detector.onTap!();
      detector.onTap!();
      await _pumpRouteTransition(tester);

      expect(find.byType(CatalogPage), findsOneWidget);
    });

    testWidgets('本棚の連続タップでBookshelfPageを複数pushしない', (tester) async {
      await _pumpRoom(tester);

      final detector = tester.widget<GestureDetector>(
        find.byKey(const ValueKey('bookshelfTapArea')),
      );
      detector.onTap!();
      detector.onTap!();
      await _pumpRouteTransition(tester);

      expect(find.byType(BookshelfPage), findsOneWidget);
    });

    testWidgets('瓶遷移開始後の本棚タップで別画面を重ねない', (tester) async {
      await _pumpRoom(tester);

      final bottleDetector = tester.widget<GestureDetector>(
        find.byKey(const ValueKey('bottleTapArea')),
      );
      final bookshelfDetector = tester.widget<GestureDetector>(
        find.byKey(const ValueKey('bookshelfTapArea')),
      );
      bottleDetector.onTap!();
      bookshelfDetector.onTap!();
      await _pumpRouteTransition(tester);

      expect(find.byType(CatalogPage), findsOneWidget);
      expect(find.byType(BookshelfPage), findsNothing);
    });

    testWidgets('本棚遷移開始後の瓶タップで別画面を重ねない', (tester) async {
      await _pumpRoom(tester);

      final bookshelfDetector = tester.widget<GestureDetector>(
        find.byKey(const ValueKey('bookshelfTapArea')),
      );
      final bottleDetector = tester.widget<GestureDetector>(
        find.byKey(const ValueKey('bottleTapArea')),
      );
      bookshelfDetector.onTap!();
      bottleDetector.onTap!();
      await _pumpRouteTransition(tester);

      expect(find.byType(BookshelfPage), findsOneWidget);
      expect(find.byType(CatalogPage), findsNothing);
    });

    testWidgets('Catalog側Providerロード前でも最初の瓶タップで遷移してロードを待つ', (tester) async {
      await _pumpRoom(tester, loadCatalogProvider: false);

      await tester.tap(find.byKey(const ValueKey('bottleTapArea')));
      await _pumpRouteTransition(tester);

      expect(find.byType(CatalogPage), findsOneWidget);
      expect(find.byType(CircularProgressIndicator), findsOneWidget);
    });

    testWidgets('Bookshelf側Providerロード前は本棚タップで遷移しない', (tester) async {
      await _pumpRoom(tester, loadReadLetterProvider: false);

      await tester.tap(find.byKey(const ValueKey('bookshelfTapArea')));
      await tester.pumpAndSettle();

      expect(find.byType(BookshelfPage), findsNothing);
    });

    testWidgets('遷移先から戻ると再度Roomオブジェクトから遷移できる', (tester) async {
      await _pumpRoom(tester);

      await tester.tap(find.byKey(const ValueKey('bottleTapArea')));
      await _pumpRouteTransition(tester);
      await tester.pageBack();
      await _pumpRouteTransition(tester);
      await tester.tap(find.byKey(const ValueKey('bookshelfTapArea')));
      await _pumpRouteTransition(tester);

      expect(find.byType(BookshelfPage), findsOneWidget);
    });

    testWidgets('瓶・本棚・手紙のタップ領域が重ならない', (tester) async {
      await _pumpRoom(
        tester,
        initialReadState: ReadLetterState(
          receivedLetters: {},
          deliveredLetters: {'2026-08-07': 'letterA'},
        ),
      );

      final bottleRect = tester.getRect(
        find.byKey(const ValueKey('bottleTapArea')),
      );
      final bookshelfRect = tester.getRect(
        find.byKey(const ValueKey('bookshelfTapArea')),
      );
      final letterRect = tester.getRect(
        find.byKey(const ValueKey('letterTapArea')),
      );

      expect(bottleRect.overlaps(bookshelfRect), isFalse);
      expect(bottleRect.overlaps(letterRect), isFalse);
      expect(bookshelfRect.overlaps(letterRect), isFalse);
    });
  });

  group('初回チュートリアル手紙の配達', () {
    testWidgets('未読なら通常候補よりtutorial_001を優先する', (tester) async {
      final harness = await _pumpRoom(
        tester,
        letters: [_letter('letterA'), _letter('tutorial_001')],
      );

      expect(
        harness.readLetterProvider.deliveredLetterIdOn(DateTime(2026, 8, 7)),
        'tutorial_001',
      );
      expect(harness.weatherRepository.requestedDates, isEmpty);
    });

    testWidgets('季節と天候が一致しなくてもtutorial_001を配達する', (tester) async {
      final harness = await _pumpRoom(
        tester,
        weather: WeatherType.sunny,
        letters: [
          _letter(
            'tutorial_001',
            season: SeasonType.winter,
            weather: WeatherType.rain,
          ),
        ],
      );

      expect(
        harness.readLetterProvider.deliveredLetterIdOn(DateTime(2026, 8, 7)),
        'tutorial_001',
      );
      expect(harness.weatherRepository.requestedDates, isEmpty);
    });

    testWidgets('配達済み未読ならrebuildでも通常手紙へ変えない', (tester) async {
      final harness = await _pumpRoom(
        tester,
        letters: [_letter('tutorial_001'), _letter('letterA')],
        initialReadState: ReadLetterState(
          receivedLetters: {},
          deliveredLetters: {'2026-08-07': 'tutorial_001'},
        ),
      );

      await tester.pump();
      await tester.pump();

      expect(
        harness.readLetterProvider.deliveredLetterIdOn(DateTime(2026, 8, 7)),
        'tutorial_001',
      );
      expect(harness.letterRepository.getAllCallCount, 0);
    });

    testWidgets('当日に通常手紙が配達済みならtutorial_001で上書きしない', (tester) async {
      final harness = await _pumpRoom(
        tester,
        letters: [_letter('tutorial_001'), _letter('letterA')],
        initialReadState: ReadLetterState(
          receivedLetters: {},
          deliveredLetters: {'2026-08-07': 'letterA'},
        ),
      );

      expect(
        harness.readLetterProvider.deliveredLetterIdOn(DateTime(2026, 8, 7)),
        'letterA',
      );
      expect(harness.letterRepository.getAllCallCount, 0);
    });

    testWidgets('tutorial_001読了後は通常の季節天候候補を配達する', (tester) async {
      final harness = await _pumpRoom(
        tester,
        letters: [_letter('tutorial_001'), _letter('letterA')],
        initialReadState: ReadLetterState(
          receivedLetters: {'tutorial_001': DateTime(2026, 8, 6)},
        ),
      );

      expect(
        harness.readLetterProvider.deliveredLetterIdOn(DateTime(2026, 8, 7)),
        'letterA',
      );
      expect(harness.weatherRepository.requestedDates, [DateTime(2026, 8, 7)]);
    });

    testWidgets('通常配達候補からtutorial_001を除外する', (tester) async {
      final harness = await _pumpRoom(
        tester,
        letters: [_letter('tutorial_001'), _letter('letterA')],
        initialReadState: ReadLetterState(
          receivedLetters: {'tutorial_001': DateTime(2026, 8, 6)},
        ),
      );

      expect(
        harness.readLetterProvider.deliveredLetterIdOn(DateTime(2026, 8, 7)),
        isNot('tutorial_001'),
      );
      expect(
        harness.readLetterProvider.deliveredLetterIdOn(DateTime(2026, 8, 7)),
        'letterA',
      );
    });

    testWidgets('tutorial_001の新規配達でも既存到着演出を開始する', (tester) async {
      await _pumpRoom(tester, letters: [_letter('tutorial_001')]);

      expect(_opacityForKey(tester, 'roomLetterLayer'), 0);
      expect(find.byKey(const ValueKey('letterTapArea')), findsNothing);

      await tester.pump(const Duration(milliseconds: 1000));
      expect(find.byKey(const ValueKey('postArrivalGlow')), findsOneWidget);

      await tester.pump(const Duration(milliseconds: 3450));
      expect(_opacityForKey(tester, 'roomLetterLayer'), 1);
      expect(find.byKey(const ValueKey('letterTapArea')), findsOneWidget);
    });

    testWidgets('tutorial_001を既存LetterPageで読み既読保存する', (tester) async {
      final harness = await _pumpRoom(
        tester,
        letters: [_letter('tutorial_001')],
        initialReadState: ReadLetterState(
          receivedLetters: {},
          deliveredLetters: {'2026-08-07': 'tutorial_001'},
        ),
        initialShizukuState: const ShizukuState(
          currentShizuku: 0,
          rewardedLetterIds: {},
        ),
      );

      await _tapLetter(tester);

      expect(find.byType(LetterPage), findsOneWidget);
      expect(find.text('tutorial_001'), findsWidgets);
      expect(
        harness.readLetterProvider.readLetterIds,
        contains('tutorial_001'),
      );
      expect(harness.shizukuProvider.currentShizuku, 30);
    });
  });

  group('手紙の到着演出', () {
    testWidgets('既存の当日配達は演出なしで手紙とtapAreaを即表示する', (tester) async {
      await _pumpRoom(
        tester,
        initialReadState: ReadLetterState(
          receivedLetters: {},
          deliveredLetters: {'2026-08-07': 'letterA'},
        ),
      );

      expect(find.byKey(const ValueKey('postArrivalGlow')), findsNothing);
      expect(find.byKey(const ValueKey('arrivalMovingLight')), findsNothing);
      expect(find.byKey(const ValueKey('roomLetterLayer')), findsOneWidget);
      expect(find.byKey(const ValueKey('letterTapArea')), findsOneWidget);
    });

    testWidgets('新規配達時はpost発光から光移動を経て手紙を表示する', (tester) async {
      await _pumpRoom(tester);

      expect(find.byKey(const ValueKey('postArrivalGlow')), findsNothing);
      expect(find.byKey(const ValueKey('arrivalMovingLight')), findsNothing);
      expect(_opacityForKey(tester, 'roomLetterLayer'), 0);
      expect(find.byKey(const ValueKey('letterTapArea')), findsNothing);

      await tester.pump(const Duration(milliseconds: 700));
      expect(find.byKey(const ValueKey('postArrivalGlow')), findsNothing);
      expect(find.byKey(const ValueKey('arrivalMovingLight')), findsNothing);
      expect(_opacityForKey(tester, 'roomLetterLayer'), 0);
      expect(find.byKey(const ValueKey('letterTapArea')), findsNothing);

      await tester.pump(const Duration(milliseconds: 500));
      expect(_opacityForKey(tester, 'postArrivalGlow'), greaterThan(0.1));
      expect(find.byKey(const ValueKey('arrivalMovingLight')), findsNothing);
      expect(_opacityForKey(tester, 'roomLetterLayer'), 0);

      await tester.pump(const Duration(milliseconds: 1500));
      expect(find.byKey(const ValueKey('postArrivalGlow')), findsNothing);
      expect(_opacityForKey(tester, 'arrivalMovingLight'), greaterThan(0));
      expect(_opacityForKey(tester, 'roomLetterLayer'), 0);
      expect(find.byKey(const ValueKey('letterTapArea')), findsNothing);

      await tester.pump(const Duration(milliseconds: 1750));
      expect(find.byKey(const ValueKey('postArrivalGlow')), findsNothing);
      expect(find.byKey(const ValueKey('arrivalMovingLight')), findsNothing);
      expect(_opacityForKey(tester, 'roomLetterLayer'), 1);
      expect(find.byKey(const ValueKey('letterTapArea')), findsOneWidget);
    });

    testWidgets('演出中のProvider通知やrebuildで最初から再生し直さない', (tester) async {
      final harness = await _pumpRoom(tester);
      await tester.pump(const Duration(seconds: 1));

      await harness.readLetterProvider.load();
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 3450));

      expect(find.byKey(const ValueKey('postArrivalGlow')), findsNothing);
      expect(find.byKey(const ValueKey('arrivalMovingLight')), findsNothing);
      expect(find.byKey(const ValueKey('letterTapArea')), findsOneWidget);
    });

    testWidgets('演出中にRoomPageを破棄してもTicker leakや例外がない', (tester) async {
      await _pumpRoom(tester);
      await tester.pump(const Duration(milliseconds: 1000));
      expect(find.byKey(const ValueKey('postArrivalGlow')), findsOneWidget);

      await tester.pumpWidget(const SizedBox.shrink());
      await tester.pump();

      expect(tester.takeException(), isNull);
    });
  });

  group('机上Aの配置家具', () {
    testWidgets('PlacedFurnitureProvider未ロードでは表示せずクラッシュしない', (tester) async {
      await _pumpRoom(tester, loadPlacedFurnitureProvider: false);

      expect(_placedFurnitureLayer, findsNothing);
      expect(tester.takeException(), isNull);
    });

    testWidgets('机上Aが未配置なら家具を表示しない', (tester) async {
      await _pumpRoom(tester);

      expect(_placedFurnitureLayer, findsNothing);
    });

    for (final entry in {
      'wooden_mug': 'furniture/desk/wooden_mug.png',
      'ink_bottle': 'furniture/desk/ink_bottle.png',
      'wooden_fox_figure': 'furniture/desk/wooden_fox_figure.png',
    }.entries) {
      testWidgets('机上Aの${entry.key}を対応するPNGで表示する', (tester) async {
        await _pumpRoom(
          tester,
          initialPlacedFurnitureIds: {_deskSurfaceLeftSlotId: entry.key},
        );

        expect(_placedFurnitureLayer, findsOneWidget);
        final image = tester.widget<Image>(
          find.byKey(ValueKey('roomFurnitureImage-${entry.key}')),
        );
        expect(
          (image.image as AssetImage).assetName,
          'assets/images/${entry.value}',
        );
      });
    }

    testWidgets('Providerの配置交換をRoomへ反映する', (tester) async {
      final harness = await _pumpRoom(
        tester,
        initialPlacedFurnitureIds: {_deskSurfaceLeftSlotId: 'wooden_mug'},
      );

      await harness.placedFurnitureProvider.place(
        slotId: _deskSurfaceLeftSlotId,
        furnitureId: 'ink_bottle',
        isPurchased: true,
        allowedSlotIds: const [_deskSurfaceLeftSlotId],
      );
      await tester.pump();

      expect(
        find.byKey(const ValueKey('roomFurnitureImage-wooden_mug')),
        findsNothing,
      );
      expect(
        find.byKey(const ValueKey('roomFurnitureImage-ink_bottle')),
        findsOneWidget,
      );
    });

    testWidgets('Providerで取り外すとRoomから家具が消える', (tester) async {
      final harness = await _pumpRoom(
        tester,
        initialPlacedFurnitureIds: {_deskSurfaceLeftSlotId: 'wooden_mug'},
      );

      await harness.placedFurnitureProvider.remove('wooden_mug');
      await tester.pump();

      expect(_placedFurnitureLayer, findsNothing);
    });

    testWidgets('未対応スロットの配置家具は描画しない', (tester) async {
      await _pumpRoom(
        tester,
        initialPlacedFurnitureIds: const {
          'living_room_desk_surface_right': 'wooden_mug',
        },
      );

      expect(_placedFurnitureLayer, findsNothing);
    });

    testWidgets('存在しないfurnitureIdでもクラッシュしない', (tester) async {
      await _pumpRoom(
        tester,
        initialPlacedFurnitureIds: const {
          _deskSurfaceLeftSlotId: 'missing_furniture',
        },
      );

      expect(_placedFurnitureLayer, findsNothing);
      expect(tester.takeException(), isNull);
    });

    testWidgets('画像asset欠損時もRoomをクラッシュさせない', (tester) async {
      await _pumpRoom(
        tester,
        initialPlacedFurnitureIds: const {_deskSurfaceLeftSlotId: 'wooden_mug'},
        furnitures: const [
          Furniture(
            id: 'wooden_mug',
            name: 'missing image',
            price: 30,
            size: 'small',
            slotIds: [_deskSurfaceLeftSlotId],
            imagePath: 'furniture/desk/missing.png',
            initialAvailable: true,
          ),
        ],
      );
      await tester.pump();

      expect(_placedFurnitureLayer, findsOneWidget);
      expect(tester.takeException(), isNull);
    });

    testWidgets('今日の手紙と机上A家具を同時に表示できる', (tester) async {
      await _pumpRoom(
        tester,
        initialPlacedFurnitureIds: const {_deskSurfaceLeftSlotId: 'wooden_mug'},
        initialReadState: ReadLetterState(
          receivedLetters: const {},
          deliveredLetters: const {'2026-08-07': 'letterA'},
        ),
      );

      expect(_placedFurnitureLayer, findsOneWidget);
      expect(find.byKey(const ValueKey('roomLetterLayer')), findsOneWidget);
    });

    testWidgets('固定の瓶・花瓶・椅子・ラグを維持する', (tester) async {
      await _pumpRoom(
        tester,
        initialPlacedFurnitureIds: const {_deskSurfaceLeftSlotId: 'wooden_mug'},
      );

      for (final asset in [
        'assets/images/room/bottle.png',
        'assets/images/room/vase.png',
        'assets/images/room/chair.png',
        'assets/images/room/rug.png',
      ]) {
        expect(find.image(AssetImage(asset)), findsOneWidget);
      }
    });
  });
}

const _deskSurfaceLeftSlotId = 'living_room_desk_surface_left';
final _placedFurnitureLayer = find.byKey(
  const ValueKey('deskSurfaceLeftFurnitureLayer'),
);

Future<void> _openDesk(WidgetTester tester) async {
  await tester.tap(find.byKey(const ValueKey('deskTapArea')));
  await tester.pumpAndSettle();
}

Future<void> _pumpRouteTransition(WidgetTester tester) async {
  await tester.pump();
  await tester.pump(const Duration(seconds: 1));
}

Future<void> _tapLetter(WidgetTester tester) async {
  await tester.tap(find.byKey(const ValueKey('letterTapArea')));
  await tester.pumpAndSettle();
}

double _opacityForKey(WidgetTester tester, String key) {
  final keyedWidget = find.byKey(ValueKey(key));
  final descendantOpacity = find.descendant(
    of: keyedWidget,
    matching: find.byType(Opacity),
  );
  if (descendantOpacity.evaluate().isNotEmpty) {
    return tester.widget<Opacity>(descendantOpacity.first).opacity;
  }
  final ancestorOpacity = find.ancestor(
    of: keyedWidget,
    matching: find.byType(Opacity),
  );
  return tester.widget<Opacity>(ancestorOpacity.first).opacity;
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
  bool blockNextShizukuLoad = false,
  bool failNextShizukuLoad = false,
  WeatherType? weather = WeatherType.rain,
  bool failNextWeatherLoad = false,
  List<Letter>? letters,
  DateTime? date,
  int initialRewardedCount = 0,
  ReadLetterState? initialReadState,
  ShizukuState? initialShizukuState,
  bool dismissInitialGuide = true,
  bool failNextReadSave = false,
  AppDateRepository? appDateRepository,
  Map<String, String> initialPlacedFurnitureIds = const {},
  List<Furniture> furnitures = _roomFurnitures,
}) async {
  final shizukuRepository = _FakeShizukuRepository(
    blockSave: blockRewardSave,
    initialRewardedCount: initialRewardedCount,
    initialState: initialShizukuState,
  );
  shizukuRepository
    ..blockNextLoad = blockNextShizukuLoad
    ..failNextLoad = failNextShizukuLoad;
  final readLetterRepository = _FakeReadLetterRepository(initialReadState);
  readLetterRepository.failNextSave = failNextReadSave;
  final shizukuProvider = ShizukuProvider(shizukuRepository);
  final readLetterProvider = ReadLetterProvider(readLetterRepository);
  final catalogProvider = CatalogProvider(_FakePurchasedFurnitureRepository());
  final placedProvider = PlacedFurnitureProvider(
    _FakePlacedFurnitureRepository(initialPlacedFurnitureIds),
  );
  final dateProvider = AppDateProvider(
    appDateRepository ?? _FakeAppDateRepository(date ?? DateTime(2026, 8, 7)),
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
      child: MaterialApp(
        home: RoomPage(
          letterRepository: letterRepository,
          furnitureRepository: _FakeFurnitureRepository(furnitures),
        ),
      ),
    ),
  );
  await tester.pump();
  await tester.pump();

  if (dismissInitialGuide && find.text('はじめる').evaluate().isNotEmpty) {
    await tester.tap(find.text('はじめる'));
    await tester.pumpAndSettle();
  }

  return _RoomHarness(
    shizukuRepository: shizukuRepository,
    readLetterRepository: readLetterRepository,
    shizukuProvider: shizukuProvider,
    readLetterProvider: readLetterProvider,
    dateProvider: dateProvider,
    weatherRepository: weatherRepository,
    letterRepository: letterRepository,
    placedFurnitureProvider: placedProvider,
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
    required this.placedFurnitureProvider,
  });

  final _FakeShizukuRepository shizukuRepository;
  final _FakeReadLetterRepository readLetterRepository;
  final ShizukuProvider shizukuProvider;
  final ReadLetterProvider readLetterProvider;
  final AppDateProvider dateProvider;
  final _FakeWeatherRepository weatherRepository;
  final _FakeLetterRepository letterRepository;
  final PlacedFurnitureProvider placedFurnitureProvider;
}

class _FakeFurnitureRepository extends FurnitureRepository {
  _FakeFurnitureRepository(this.furnitures);

  final List<Furniture> furnitures;

  @override
  Future<List<Furniture>> getAll() async => furnitures;
}

const List<Furniture> _roomFurnitures = [
  Furniture(
    id: 'wooden_mug',
    name: 'wooden mug',
    price: 30,
    size: 'small',
    slotIds: [_deskSurfaceLeftSlotId],
    imagePath: 'furniture/desk/wooden_mug.png',
    initialAvailable: true,
  ),
  Furniture(
    id: 'ink_bottle',
    name: 'ink bottle',
    price: 30,
    size: 'small',
    slotIds: [_deskSurfaceLeftSlotId],
    imagePath: 'furniture/desk/ink_bottle.png',
    initialAvailable: true,
  ),
  Furniture(
    id: 'wooden_fox_figure',
    name: 'wooden fox figure',
    price: 30,
    size: 'small',
    slotIds: [_deskSurfaceLeftSlotId],
    imagePath: 'furniture/desk/wooden_fox_figure.png',
    initialAvailable: true,
  ),
];

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
  }) : state =
           initialState ??
           ShizukuState(
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
  bool blockNextLoad = false;
  bool failNextLoad = false;
  int saveCallCount = 0;
  int loadCallCount = 0;
  Completer<ShizukuState>? _loadCompleter;

  @override
  Future<ShizukuState> loadState() async {
    loadCallCount++;
    if (failNextLoad) {
      failNextLoad = false;
      throw StateError('load failed');
    }
    if (blockNextLoad) {
      blockNextLoad = false;
      _loadCompleter = Completer<ShizukuState>();
      return _loadCompleter!.future;
    }
    return state;
  }

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

  void completeLoad() {
    final completer = _loadCompleter;
    if (completer != null && !completer.isCompleted) {
      completer.complete(state);
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
  _FakePlacedFurnitureRepository([Map<String, String> initialState = const {}])
    : state = Map.of(initialState);

  Map<String, String> state;

  @override
  Future<Map<String, String>> loadPlacedFurnitureIds() async => Map.of(state);

  @override
  Future<void> savePlacedFurnitureIds(
    Map<String, String> placedFurnitureIds,
  ) async {
    state = Map.of(placedFurnitureIds);
  }
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
