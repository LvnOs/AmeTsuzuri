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

void main() {
  group('チュートリアル誘導対象の導出', () {
    String resolve({
      bool areProvidersLoaded = true,
      bool tutorialCompleted = false,
      bool isTutorialRead = true,
      bool hasTutorialLetterInRoom = false,
      bool hasOpenedTutorialBottle = false,
      bool hasPurchasedFurniture = false,
      bool hasPlacedFurniture = false,
    }) {
      return RoomPage.resolveTutorialTargetForTesting(
        areProvidersLoaded: areProvidersLoaded,
        tutorialCompleted: tutorialCompleted,
        isTutorialRead: isTutorialRead,
        hasTutorialLetterInRoom: hasTutorialLetterInRoom,
        hasOpenedTutorialBottle: hasOpenedTutorialBottle,
        hasPurchasedFurniture: hasPurchasedFurniture,
        hasPlacedFurniture: hasPlacedFurniture,
      );
    }

    test('Provider未ロードならnone', () {
      expect(
        resolve(
          areProvidersLoaded: false,
          isTutorialRead: false,
          hasTutorialLetterInRoom: true,
        ),
        'none',
      );
    });

    test('tutorial未読かつRoomに配達済みならletter', () {
      expect(
        resolve(isTutorialRead: false, hasTutorialLetterInRoom: true),
        'letter',
      );
    });

    test('tutorial既読で瓶未確認かつ家具未購入・未配置ならbottle', () {
      expect(resolve(), 'bottle');
    });

    test('瓶確認済みで家具未購入・未配置ならnone', () {
      expect(resolve(hasOpenedTutorialBottle: true), 'none');
    });

    test('瓶未確認でも家具購入済み・未配置ならnone', () {
      expect(resolve(hasPurchasedFurniture: true), 'none');
    });

    test('瓶確認済みかつ家具購入済み・未配置ならnone', () {
      expect(
        resolve(hasOpenedTutorialBottle: true, hasPurchasedFurniture: true),
        'none',
      );
    });

    test('tutorial既読かつ家具配置済みで未完了ならbookshelf', () {
      expect(resolve(hasPlacedFurniture: true), 'bookshelf');
    });

    test('家具配置済みでもtutorial完了済みならnone', () {
      expect(
        resolve(hasPlacedFurniture: true, tutorialCompleted: true),
        'none',
      );
    });

    test('tutorial未読と家具配置済みが競合したらletterを優先', () {
      expect(
        resolve(
          isTutorialRead: false,
          hasTutorialLetterInRoom: true,
          hasPlacedFurniture: true,
        ),
        'letter',
      );
    });

    test('本棚を先に開いた想定でも家具未配置ならbookshelfにしない', () {
      expect(resolve(hasOpenedTutorialBottle: true), 'none');
    });

    test('reset相当では配達前none、配達後letter', () {
      expect(resolve(isTutorialRead: false), 'none');
      expect(
        resolve(isTutorialRead: false, hasTutorialLetterInRoom: true),
        'letter',
      );
    });

    test('通常プレイのtutorial完了状態ならnone', () {
      expect(
        resolve(
          tutorialCompleted: true,
          hasOpenedTutorialBottle: true,
          hasPurchasedFurniture: true,
          hasPlacedFurniture: true,
        ),
        'none',
      );
    });
  });

  group('チュートリアル対象の継続Glow', () {
    final letterGlow = find.byKey(const ValueKey('tutorialLetterGlow'));
    final bottleGlow = find.byKey(const ValueKey('tutorialBottleGlow'));

    final bookshelfGlow = find.byKey(const ValueKey('tutorialBookshelfGlow'));

    testWidgets('tutorial未読かつ配達済みならletter Glowだけを表示する', (tester) async {
      await _pumpRoom(
        tester,
        initialReadState: ReadLetterState(
          receivedLetters: {},
          deliveredLetters: const {'2026-08-07': 'tutorial_001'},
        ),
      );

      expect(letterGlow, findsOneWidget);
      expect(bottleGlow, findsNothing);
      expect(bookshelfGlow, findsNothing);
    });

    testWidgets('tutorial到着演出中はGlowを表示せず完了後にletter Glowを開始する', (tester) async {
      await _pumpRoom(tester, letters: [_letter('tutorial_001')]);

      expect(letterGlow, findsNothing);

      await tester.pump(const Duration(seconds: 5));
      await tester.pump();

      expect(letterGlow, findsOneWidget);
      expect(find.byKey(const ValueKey('postArrivalGlow')), findsNothing);
    });

    testWidgets('tutorial既読かつ瓶未確認ならbottle Glowだけを表示する', (tester) async {
      await _pumpRoom(
        tester,
        weather: WeatherType.sunny,
        initialReadState: ReadLetterState(
          receivedLetters: {'tutorial_001': DateTime(2026, 8, 6)},
        ),
      );

      expect(letterGlow, findsNothing);
      expect(bottleGlow, findsOneWidget);
      expect(bookshelfGlow, findsNothing);
    });

    testWidgets('家具配置済みかつ未完了ならbookshelf Glowだけを表示する', (tester) async {
      await _pumpRoom(
        tester,
        weather: WeatherType.sunny,
        initialReadState: ReadLetterState(
          receivedLetters: {'tutorial_001': DateTime(2026, 8, 6)},
        ),
        initialPlacedFurnitureIds: const {_deskSurfaceLeftSlotId: 'wooden_mug'},
      );

      expect(letterGlow, findsNothing);
      expect(bottleGlow, findsNothing);
      expect(bookshelfGlow, findsOneWidget);
    });

    testWidgets('tutorial完了済みならGlowを表示しない', (tester) async {
      await _pumpRoom(
        tester,
        weather: WeatherType.sunny,
        initialReadState: ReadLetterState(
          receivedLetters: {'tutorial_001': DateTime(2026, 8, 6)},
          hasOpenedTutorialBottle: true,
          tutorialCompleted: true,
        ),
        initialPlacedFurnitureIds: const {_deskSurfaceLeftSlotId: 'wooden_mug'},
      );

      expect(letterGlow, findsNothing);
      expect(bottleGlow, findsNothing);
      expect(bookshelfGlow, findsNothing);
    });

    testWidgets('購入済み未配置ならGlowを表示しない', (tester) async {
      await _pumpRoom(
        tester,
        weather: WeatherType.sunny,
        initialReadState: ReadLetterState(
          receivedLetters: {'tutorial_001': DateTime(2026, 8, 6)},
        ),
        initialPurchasedFurnitureIds: const {'wooden_mug'},
      );

      expect(letterGlow, findsNothing);
      expect(bottleGlow, findsNothing);
      expect(bookshelfGlow, findsNothing);
    });

    testWidgets('必要Provider未ロードならGlowを表示しない', (tester) async {
      await _pumpRoom(tester, loadCatalogProvider: false);

      expect(letterGlow, findsNothing);
      expect(bottleGlow, findsNothing);
      expect(bookshelfGlow, findsNothing);
    });

    testWidgets('対象がletterからbottleへ変化するとGlowを切り替える', (tester) async {
      final harness = await _pumpRoom(
        tester,
        letters: [_letter('tutorial_001')],
        initialReadState: ReadLetterState(
          receivedLetters: {},
          deliveredLetters: const {'2026-08-07': 'tutorial_001'},
        ),
      );
      expect(letterGlow, findsOneWidget);

      await harness.readLetterProvider.markAsRead(
        'tutorial_001',
        receivedDate: DateTime(2026, 8, 7),
      );
      await tester.pump();

      expect(letterGlow, findsNothing);
      expect(bottleGlow, findsOneWidget);
    });

    testWidgets('対象がbottleからbookshelfへ変化するとGlowを切り替える', (tester) async {
      final harness = await _pumpRoom(
        tester,
        weather: WeatherType.sunny,
        initialReadState: ReadLetterState(
          receivedLetters: {'tutorial_001': DateTime(2026, 8, 6)},
        ),
      );
      expect(bottleGlow, findsOneWidget);

      await harness.placedFurnitureProvider.place(
        slotId: _deskSurfaceLeftSlotId,
        furnitureId: 'wooden_mug',
        isPurchased: true,
        allowedSlotIds: const [_deskSurfaceLeftSlotId],
      );
      await tester.pump();

      expect(bottleGlow, findsNothing);
      expect(bookshelfGlow, findsOneWidget);
    });

    testWidgets('tutorialCompletedへ変化すると全Glowを停止する', (tester) async {
      final harness = await _pumpRoom(
        tester,
        weather: WeatherType.sunny,
        initialReadState: ReadLetterState(
          receivedLetters: {'tutorial_001': DateTime(2026, 8, 6)},
        ),
        initialPlacedFurnitureIds: const {_deskSurfaceLeftSlotId: 'wooden_mug'},
      );
      expect(bookshelfGlow, findsOneWidget);

      await harness.readLetterProvider.completeTutorial();
      await tester.pump();

      expect(letterGlow, findsNothing);
      expect(bottleGlow, findsNothing);
      expect(bookshelfGlow, findsNothing);
    });

    testWidgets('GlowはIgnorePointerでtapAreaを遮らない', (tester) async {
      await _pumpRoom(
        tester,
        weather: WeatherType.sunny,
        initialReadState: ReadLetterState(
          receivedLetters: {'tutorial_001': DateTime(2026, 8, 6)},
        ),
      );

      expect(
        find.descendant(of: bottleGlow, matching: find.byType(IgnorePointer)),
        findsOneWidget,
      );
      await tester.tap(find.byKey(const ValueKey('bottleTapArea')));
      await _pumpRouteTransition(tester);
      expect(find.byType(CatalogPage), findsOneWidget);
    });

    testWidgets('Glow動作中にRoomを破棄してもTicker例外がない', (tester) async {
      await _pumpRoom(
        tester,
        weather: WeatherType.sunny,
        initialReadState: ReadLetterState(
          receivedLetters: {'tutorial_001': DateTime(2026, 8, 6)},
        ),
      );
      await tester.pump(const Duration(milliseconds: 900));

      await tester.pumpWidget(const SizedBox.shrink());
      await tester.pump();

      expect(tester.takeException(), isNull);
    });

    testWidgets('到着ControllerとGlow Controllerの共存時もTicker leakがない', (
      tester,
    ) async {
      await _pumpRoom(tester, letters: [_letter('tutorial_001')]);
      await tester.pump(const Duration(milliseconds: 4350));
      await tester.pump(const Duration(milliseconds: 300));
      expect(letterGlow, findsOneWidget);

      await tester.pumpWidget(const SizedBox.shrink());
      await tester.pump();

      expect(tester.takeException(), isNull);
    });

    testWidgets('Room再生成時も永続状態に対応するGlowだけを表示する', (tester) async {
      await _pumpRoom(
        tester,
        weather: WeatherType.sunny,
        initialReadState: ReadLetterState(
          receivedLetters: {'tutorial_001': DateTime(2026, 8, 6)},
        ),
      );
      expect(bottleGlow, findsOneWidget);

      await tester.pumpWidget(const SizedBox.shrink());
      await _pumpRoom(
        tester,
        weather: WeatherType.sunny,
        initialReadState: ReadLetterState(
          receivedLetters: {'tutorial_001': DateTime(2026, 8, 6)},
        ),
        initialPlacedFurnitureIds: const {_deskSurfaceLeftSlotId: 'wooden_mug'},
      );

      expect(letterGlow, findsNothing);
      expect(bottleGlow, findsNothing);
      expect(bookshelfGlow, findsOneWidget);
    });
  });

  group('tutorial初読後の手紙から瓶への移動光', () {
    final movingLight = find.byKey(
      const ValueKey('tutorialLetterToBottleMovingLight'),
    );
    final letterGlow = find.byKey(const ValueKey('tutorialLetterGlow'));
    final bottleGlow = find.byKey(const ValueKey('tutorialBottleGlow'));

    Future<_RoomHarness> openUnreadTutorial(WidgetTester tester) async {
      final harness = await _pumpRoom(
        tester,
        letters: [_letter('tutorial_001')],
        initialReadState: ReadLetterState(
          receivedLetters: {},
          deliveredLetters: const {'2026-08-07': 'tutorial_001'},
        ),
      );
      expect(letterGlow, findsOneWidget);

      await tester.tap(find.byKey(const ValueKey('letterTapArea')));
      await pumpUntilLetterPage(tester);
      expect(find.byType(LetterPage), findsOneWidget);
      return harness;
    }

    Future<void> returnToRoom(WidgetTester tester) async {
      await tester.pageBack();
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 400));
    }

    testWidgets('tutorial初読は30滴を付与して既読保存する', (tester) async {
      final harness = await openUnreadTutorial(tester);

      expect(harness.shizukuProvider.currentShizuku, 60);
      expect(
        harness.readLetterProvider.readLetterIds,
        contains('tutorial_001'),
      );
      expect(movingLight, findsNothing);
    });

    testWidgets('tutorial初読画面からRoomへ戻ると移動光を一度表示する', (tester) async {
      await openUnreadTutorial(tester);
      await returnToRoom(tester);

      expect(movingLight, findsOneWidget);
      expect(letterGlow, findsNothing);
    });

    testWidgets('移動中はbottle Glowを抑止し完了後に表示する', (tester) async {
      await openUnreadTutorial(tester);
      await returnToRoom(tester);

      expect(movingLight, findsOneWidget);
      expect(bottleGlow, findsNothing);

      await tester.pump(const Duration(milliseconds: 1300));
      await tester.pump();

      expect(movingLight, findsNothing);
      expect(bottleGlow, findsOneWidget);
    });

    testWidgets('tutorial既読再読後は移動光を表示しない', (tester) async {
      await _pumpRoom(
        tester,
        letters: [_letter('tutorial_001')],
        initialReadState: ReadLetterState(
          receivedLetters: {'tutorial_001': DateTime(2026, 8, 7)},
          deliveredLetters: const {'2026-08-07': 'tutorial_001'},
        ),
      );

      await tester.tap(find.byKey(const ValueKey('letterTapArea')));
      await pumpUntilLetterPage(tester);
      await returnToRoom(tester);

      expect(movingLight, findsNothing);
      expect(bottleGlow, findsOneWidget);
    });

    testWidgets('通常手紙の初読後は移動光を表示しない', (tester) async {
      await _pumpRoom(
        tester,
        initialReadState: ReadLetterState(
          receivedLetters: {'tutorial_001': DateTime(2026, 8, 6)},
          deliveredLetters: const {'2026-08-07': 'letterA'},
        ),
      );

      await tester.tap(find.byKey(const ValueKey('letterTapArea')));
      await pumpUntilLetterPage(tester);
      await returnToRoom(tester);

      expect(movingLight, findsNothing);
    });

    testWidgets('tutorial既読状態でRoomを再生成しても移動光なしでbottle Glowのみ', (tester) async {
      await _pumpRoom(
        tester,
        weather: WeatherType.sunny,
        initialReadState: ReadLetterState(
          receivedLetters: {'tutorial_001': DateTime(2026, 8, 6)},
        ),
      );

      expect(movingLight, findsNothing);
      expect(bottleGlow, findsOneWidget);
    });

    testWidgets('tutorial未読配達済みでRoomを再生成するとletter Glowのみ', (tester) async {
      await _pumpRoom(
        tester,
        initialReadState: ReadLetterState(
          receivedLetters: {},
          deliveredLetters: const {'2026-08-07': 'tutorial_001'},
        ),
      );

      expect(movingLight, findsNothing);
      expect(letterGlow, findsOneWidget);
      expect(bottleGlow, findsNothing);
    });

    testWidgets('移動中にRoomを破棄してもTicker例外がない', (tester) async {
      await openUnreadTutorial(tester);
      await returnToRoom(tester);
      expect(movingLight, findsOneWidget);

      await tester.pumpWidget(const SizedBox.shrink());
      await tester.pump();

      expect(tester.takeException(), isNull);
    });

    testWidgets('移動中のrebuildでアニメーションを最初から再開しない', (tester) async {
      final harness = await openUnreadTutorial(tester);
      await returnToRoom(tester);
      await tester.pump(const Duration(milliseconds: 700));

      await harness.readLetterProvider.load();
      await tester.pump();
      expect(movingLight, findsOneWidget);

      await tester.pump(const Duration(milliseconds: 650));
      await tester.pump();
      expect(movingLight, findsNothing);
      expect(bottleGlow, findsOneWidget);
    });

    testWidgets('到着演出中は手紙を開けずtutorial移動光も開始しない', (tester) async {
      await _pumpRoom(tester, letters: [_letter('tutorial_001')]);

      expect(find.byKey(const ValueKey('letterTapArea')), findsNothing);
      expect(movingLight, findsNothing);
    });

    testWidgets('LetterPage表示中にtutorial完了状態になった場合は移動光を開始しない', (tester) async {
      final harness = await openUnreadTutorial(tester);
      await harness.readLetterProvider.completeTutorial();
      await returnToRoom(tester);

      expect(movingLight, findsNothing);
      expect(bottleGlow, findsNothing);
    });
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

  group('通常手紙の翌日配達と天候再試行', () {
    testWidgets('日付が翌日に変わると翌日の手紙を配達して前日の配達IDを維持する', (tester) async {
      final harness = await _pumpRoom(
        tester,
        initialReadState: ReadLetterState(
          receivedLetters: {'letterA': DateTime(2026, 8, 7)},
          deliveredLetters: {'2026-08-07': 'letterA'},
        ),
      );

      await harness.dateProvider.moveToNextDay();
      await tester.pumpAndSettle();

      expect(
        harness.readLetterProvider.deliveredLetterIdOn(DateTime(2026, 8, 7)),
        'letterA',
      );
      expect(
        harness.readLetterProvider.deliveredLetterIdOn(DateTime(2026, 8, 8)),
        'letterB',
      );
      expect(harness.weatherRepository.requestedDates, [DateTime(2026, 8, 8)]);
    });

    testWidgets('通常配達の天候ロードが一度失敗すると750ms後に一度だけ再試行する', (tester) async {
      final harness = await _pumpRoom(
        tester,
        initialReadState: ReadLetterState(
          receivedLetters: {'tutorial_001': DateTime(2026, 8, 6)},
        ),
        weatherLoadFailureCount: 1,
      );

      expect(harness.weatherRepository.requestedDates, [DateTime(2026, 8, 7)]);
      expect(harness.readLetterProvider.deliveredLetters, isEmpty);

      await tester.pump(const Duration(milliseconds: 750));
      await tester.pump();

      expect(harness.weatherRepository.requestedDates, [
        DateTime(2026, 8, 7),
        DateTime(2026, 8, 7),
      ]);
      expect(
        harness.readLetterProvider.deliveredLetterIdOn(DateTime(2026, 8, 7)),
        'letterA',
      );
    });

    testWidgets('通常配達の天候ロードが二度失敗しても三度目は自動実行しない', (tester) async {
      final harness = await _pumpRoom(
        tester,
        initialReadState: ReadLetterState(
          receivedLetters: {'tutorial_001': DateTime(2026, 8, 6)},
        ),
        weatherLoadFailureCount: 2,
      );

      await tester.pump(const Duration(milliseconds: 750));
      await tester.pump(const Duration(seconds: 2));

      expect(harness.weatherRepository.requestedDates, [
        DateTime(2026, 8, 7),
        DateTime(2026, 8, 7),
      ]);
      expect(harness.readLetterProvider.deliveredLetters, isEmpty);
    });

    testWidgets('天候再試行待機中に日付が変わると古い日付へ配達しない', (tester) async {
      final harness = await _pumpRoom(
        tester,
        initialReadState: ReadLetterState(
          receivedLetters: {'tutorial_001': DateTime(2026, 8, 6)},
        ),
        weatherLoadFailureCount: 1,
      );

      await harness.dateProvider.moveToNextDay();
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 750));
      await tester.pump();

      expect(
        harness.readLetterProvider.deliveredLetterIdOn(DateTime(2026, 8, 7)),
        isNull,
      );
      expect(
        harness.readLetterProvider.deliveredLetterIdOn(DateTime(2026, 8, 8)),
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

    testWidgets('不正な当日deliveredLetterIdでも配達状態を壊さず副作用を起こさない', (tester) async {
      final harness = await _pumpRoom(
        tester,
        initialReadState: ReadLetterState(
          receivedLetters: {},
          deliveredLetters: {'2026-08-07': 'missing_letter'},
        ),
      );

      await tester.tap(find.byKey(const ValueKey('letterTapArea')));
      await tester.pumpAndSettle();

      expect(tester.takeException(), isNull);
      expect(find.byType(LetterPage), findsNothing);
      expect(harness.shizukuRepository.saveCallCount, 0);
      expect(harness.readLetterRepository.saveCallCount, 0);
      expect(
        harness.readLetterProvider.deliveredLetterIdOn(DateTime(2026, 8, 7)),
        'missing_letter',
      );
      expect(find.byKey(const ValueKey('roomLetterLayer')), findsOneWidget);
    });

    testWidgets('確定手紙のRepository取得失敗では状態を維持して次回タップで再試行できる', (tester) async {
      final harness = await _pumpRoom(
        tester,
        initialReadState: ReadLetterState(
          receivedLetters: {},
          deliveredLetters: {'2026-08-07': 'letterB'},
        ),
      );
      harness.letterRepository.failNextLoad = true;

      await tester.tap(find.byKey(const ValueKey('letterTapArea')));
      await tester.pumpAndSettle();

      expect(find.byType(LetterPage), findsNothing);
      expect(harness.shizukuRepository.saveCallCount, 0);
      expect(harness.readLetterRepository.saveCallCount, 0);
      expect(
        harness.readLetterProvider.deliveredLetterIdOn(DateTime(2026, 8, 7)),
        'letterB',
      );

      await _tapLetter(tester);

      expect(find.byType(LetterPage), findsOneWidget);
      expect(find.text('letterB'), findsWidgets);
      expect(harness.letterRepository.getAllCallCount, 2);
    });

    testWidgets('確定済み手紙の閲覧では天候を再ロードせず候補を再選択しない', (tester) async {
      final harness = await _pumpRoom(
        tester,
        letters: [_letter('letterA'), _letter('letterB')],
        initialReadState: ReadLetterState(
          receivedLetters: {},
          deliveredLetters: {'2026-08-07': 'letterB'},
        ),
      );

      await _tapLetter(tester);

      expect(find.text('letterB'), findsWidgets);
      expect(harness.weatherRepository.requestedDates, isEmpty);
      expect(
        harness.readLetterProvider.deliveredLetterIdOn(DateTime(2026, 8, 7)),
        'letterB',
      );
      expect(harness.letterRepository.getAllCallCount, 1);
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

    testWidgets('ReadLetter未ロードでも最初の本棚タップを保持してロード後に遷移する', (tester) async {
      final harness = await _pumpRoom(
        tester,
        loadReadLetterProvider: false,
        blockNextReadLoad: true,
      );

      await tester.tap(find.byKey(const ValueKey('bookshelfTapArea')));
      await tester.pump();

      expect(find.byType(BookshelfPage), findsNothing);
      expect(harness.readLetterRepository.loadCallCount, 1);

      harness.readLetterRepository.completeLoad();
      await tester.pump();
      await _pumpRouteTransition(tester);

      expect(find.byType(BookshelfPage), findsOneWidget);
    });

    testWidgets('Shizuku未ロードでも最初の本棚タップを保持してロード後に遷移する', (tester) async {
      final harness = await _pumpRoom(
        tester,
        loadShizukuProvider: false,
        blockNextShizukuLoad: true,
      );

      await tester.tap(find.byKey(const ValueKey('bookshelfTapArea')));
      await tester.pump();

      expect(find.byType(BookshelfPage), findsNothing);
      expect(harness.shizukuRepository.loadCallCount, 1);

      harness.shizukuRepository.completeLoad();
      await _pumpRouteTransition(tester);

      expect(find.byType(BookshelfPage), findsOneWidget);
    });

    testWidgets('両Provider未ロードなら両方の完了を待って本棚へ遷移する', (tester) async {
      final harness = await _pumpRoom(
        tester,
        loadReadLetterProvider: false,
        loadShizukuProvider: false,
        blockNextReadLoad: true,
        blockNextShizukuLoad: true,
      );

      await tester.tap(find.byKey(const ValueKey('bookshelfTapArea')));
      await tester.pump();
      harness.readLetterRepository.completeLoad();
      await tester.pump();

      expect(find.byType(BookshelfPage), findsNothing);

      harness.shizukuRepository.completeLoad();
      await _pumpRouteTransition(tester);

      expect(find.byType(BookshelfPage), findsOneWidget);
    });

    testWidgets('本棚ロード待機中の連打と瓶タップで画面を重ねない', (tester) async {
      final harness = await _pumpRoom(
        tester,
        loadReadLetterProvider: false,
        blockNextReadLoad: true,
      );
      final bookshelfDetector = tester.widget<GestureDetector>(
        find.byKey(const ValueKey('bookshelfTapArea')),
      );
      final bottleDetector = tester.widget<GestureDetector>(
        find.byKey(const ValueKey('bottleTapArea')),
      );

      bookshelfDetector.onTap!();
      bookshelfDetector.onTap!();
      bottleDetector.onTap!();
      await tester.pump();

      expect(harness.readLetterRepository.loadCallCount, 1);
      expect(find.byType(CatalogPage), findsNothing);

      harness.readLetterRepository.completeLoad();
      await tester.pump();
      await _pumpRouteTransition(tester);

      expect(find.byType(BookshelfPage), findsOneWidget);
      expect(find.byType(CatalogPage), findsNothing);
    });

    testWidgets('本棚Providerロード失敗後は再タップで再試行できる', (tester) async {
      final harness = await _pumpRoom(
        tester,
        loadReadLetterProvider: false,
        failNextReadLoad: true,
      );

      await tester.tap(find.byKey(const ValueKey('bookshelfTapArea')));
      await tester.pump();

      expect(tester.takeException(), isNull);
      expect(find.byType(BookshelfPage), findsNothing);

      await tester.tap(find.byKey(const ValueKey('bookshelfTapArea')));
      await _pumpRouteTransition(tester);

      expect(harness.readLetterRepository.loadCallCount, 2);
      expect(find.byType(BookshelfPage), findsOneWidget);
    });

    testWidgets('BookshelfPageから戻ると再び1タップで開ける', (tester) async {
      await _pumpRoom(tester);

      await tester.tap(find.byKey(const ValueKey('bookshelfTapArea')));
      await _pumpRouteTransition(tester);
      await tester.pageBack();
      await _pumpRouteTransition(tester);
      await tester.tap(find.byKey(const ValueKey('bookshelfTapArea')));
      await _pumpRouteTransition(tester);

      expect(find.byType(BookshelfPage), findsOneWidget);
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

Future<void> _pumpRouteTransition(WidgetTester tester) async {
  await tester.pump();
  await tester.pump(const Duration(seconds: 1));
}

Future<void> pumpUntilLetterPage(WidgetTester tester) async {
  for (var i = 0; i < 20 && find.byType(LetterPage).evaluate().isEmpty; i++) {
    await tester.pump(const Duration(milliseconds: 50));
  }
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
  int weatherLoadFailureCount = 0,
  List<Letter>? letters,
  DateTime? date,
  int initialRewardedCount = 0,
  ReadLetterState? initialReadState,
  ShizukuState? initialShizukuState,
  bool dismissInitialGuide = true,
  bool failNextReadSave = false,
  bool blockNextReadLoad = false,
  bool failNextReadLoad = false,
  AppDateRepository? appDateRepository,
  Set<String> initialPurchasedFurnitureIds = const {},
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
  readLetterRepository
    ..failNextSave = failNextReadSave
    ..blockNextLoad = blockNextReadLoad
    ..failNextLoad = failNextReadLoad;
  final shizukuProvider = ShizukuProvider(shizukuRepository);
  final readLetterProvider = ReadLetterProvider(readLetterRepository);
  final catalogProvider = CatalogProvider(
    _FakePurchasedFurnitureRepository(initialPurchasedFurnitureIds),
  );
  final placedProvider = PlacedFurnitureProvider(
    _FakePlacedFurnitureRepository(initialPlacedFurnitureIds),
  );
  final dateProvider = AppDateProvider(
    appDateRepository ?? _FakeAppDateRepository(date ?? DateTime(2026, 8, 7)),
  );
  final weatherRepository = _FakeWeatherRepository(
    weather: weather,
    failNextLoad: failNextWeatherLoad,
    remainingFailures: weatherLoadFailureCount,
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
    catalogProvider: catalogProvider,
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
    required this.catalogProvider,
    required this.placedFurnitureProvider,
  });

  final _FakeShizukuRepository shizukuRepository;
  final _FakeReadLetterRepository readLetterRepository;
  final ShizukuProvider shizukuProvider;
  final ReadLetterProvider readLetterProvider;
  final AppDateProvider dateProvider;
  final _FakeWeatherRepository weatherRepository;
  final _FakeLetterRepository letterRepository;
  final CatalogProvider catalogProvider;
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
  _FakeWeatherRepository({
    required this.weather,
    required this.failNextLoad,
    this.remainingFailures = 0,
  });

  WeatherType? weather;
  bool failNextLoad;
  int remainingFailures;
  final List<DateTime> requestedDates = [];

  @override
  Future<WeatherType?> getByDate(DateTime date) async {
    requestedDates.add(DateTime(date.year, date.month, date.day));
    if (failNextLoad || remainingFailures > 0) {
      failNextLoad = false;
      if (remainingFailures > 0) {
        remainingFailures--;
      }
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
  bool blockNextLoad = false;
  bool failNextLoad = false;
  int saveCallCount = 0;
  int loadCallCount = 0;
  Completer<ReadLetterState>? _loadCompleter;

  Set<String> get persistedIds => state.readLetterIds;

  @override
  Future<ReadLetterState> loadState() async {
    loadCallCount++;
    if (failNextLoad) {
      failNextLoad = false;
      throw StateError('load failed');
    }
    if (blockNextLoad) {
      blockNextLoad = false;
      _loadCompleter = Completer<ReadLetterState>();
      return _loadCompleter!.future;
    }
    return state;
  }

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

  void completeLoad() {
    final completer = _loadCompleter;
    if (completer != null && !completer.isCompleted) {
      completer.complete(state);
    }
  }
}

class _FakePurchasedFurnitureRepository extends PurchasedFurnitureRepository {
  _FakePurchasedFurnitureRepository([Set<String> initialState = const {}])
    : state = Set.of(initialState);

  Set<String> state;

  @override
  Future<Set<String>> loadPurchasedFurnitureIds() async => Set.of(state);
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
