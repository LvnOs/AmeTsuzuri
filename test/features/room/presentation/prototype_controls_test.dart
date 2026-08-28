import 'dart:convert';

import 'package:ame_tsuzuri/features/furniture/provider/catalog_provider.dart';
import 'package:ame_tsuzuri/features/furniture/provider/placed_furniture_provider.dart';
import 'package:ame_tsuzuri/features/furniture/model/furniture.dart';
import 'package:ame_tsuzuri/features/furniture/repository/furniture_repository.dart';
import 'package:ame_tsuzuri/features/furniture/repository/placed_furniture_repository.dart';
import 'package:ame_tsuzuri/features/furniture/repository/purchased_furniture_repository.dart';
import 'package:ame_tsuzuri/features/letters/model/letter.dart';
import 'package:ame_tsuzuri/features/letters/provider/read_letter_provider.dart';
import 'package:ame_tsuzuri/features/letters/provider/shizuku_provider.dart';
import 'package:ame_tsuzuri/features/letters/repository/letter_repository.dart';
import 'package:ame_tsuzuri/features/letters/repository/read_letter_repository.dart';
import 'package:ame_tsuzuri/features/letters/repository/shizuku_repository.dart';
import 'package:ame_tsuzuri/features/room/presentation/room_page.dart';
import 'package:ame_tsuzuri/shared/model/season_type.dart';
import 'package:ame_tsuzuri/shared/model/weather_type.dart';
import 'package:ame_tsuzuri/shared/provider/app_data_provider.dart';
import 'package:ame_tsuzuri/shared/provider/weather_provider.dart';
import 'package:ame_tsuzuri/shared/repository/app_date_repository.dart';
import 'package:ame_tsuzuri/shared/repository/weather_repository.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  testWidgets('8月に秋背景overrideを選んでも日付を変更しない', (tester) async {
    final harness = await _pumpPrototypeRoom(tester);
    final prefs = await SharedPreferences.getInstance();
    final savedDate = prefs.getString('prototypeDate');

    await _selectPrototypeOperation(tester, 'prototypeOutdoorAutumn');

    expect(harness.date.today, DateTime(2026, 8, 7));
    expect(harness.date.currentSeason, SeasonType.summer);
    expect(prefs.getString('prototypeDate'), savedDate);
    expect(
      find.image(const AssetImage('assets/images/room/outdoor_autumn.png')),
      findsOneWidget,
    );
    expect(
      find.image(const AssetImage('assets/images/room/outdoor_summer.png')),
      findsNothing,
    );
    expect(
      find.image(const AssetImage('assets/images/room/room_base.png')),
      findsOneWidget,
    );

    await _selectPrototypeOperation(tester, 'prototypeOutdoorAuto');

    expect(
      find.image(const AssetImage('assets/images/room/outdoor_summer.png')),
      findsOneWidget,
    );
  });

  testWidgets('9月に夏背景overrideを選んでも日付を変更しない', (tester) async {
    final harness = await _pumpPrototypeRoom(
      tester,
      date: DateTime(2026, 9, 1),
    );
    final prefs = await SharedPreferences.getInstance();
    final savedDate = prefs.getString('prototypeDate');

    await _selectPrototypeOperation(tester, 'prototypeOutdoorSummer');

    expect(harness.date.today, DateTime(2026, 9, 1));
    expect(harness.date.currentSeason, SeasonType.autumn);
    expect(prefs.getString('prototypeDate'), savedDate);
    expect(
      find.image(const AssetImage('assets/images/room/outdoor_summer.png')),
      findsOneWidget,
    );
    expect(
      find.image(const AssetImage('assets/images/room/outdoor_autumn.png')),
      findsNothing,
    );
    expect(
      find.image(const AssetImage('assets/images/room/room_base.png')),
      findsOneWidget,
    );
  });

  testWidgets('翌日へ進むとゲーム状態を維持して翌日の手紙を配達する', (tester) async {
    final harness = await _pumpPrototypeRoom(tester);

    await tester.tap(find.byKey(const ValueKey('prototypeControls')));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 500));
    await tester.tap(find.byKey(const ValueKey('prototypeNextDay')));
    await tester.pump();
    await tester.pump(const Duration(seconds: 1));

    expect(harness.date.today, DateTime(2026, 8, 8));
    expect(harness.read.readLetterIds, {'tutorial_001'});
    expect(
      harness.read.deliveredLetterIdOn(DateTime(2026, 8, 7)),
      'tutorial_001',
    );
    expect(harness.read.deliveredLetterIdOn(DateTime(2026, 8, 8)), 'letter_01');
    expect(harness.shizuku.currentShizuku, 20);
    expect(harness.catalog.purchasedFurnitureIds, {'wooden_mug', 'ink_bottle'});
    expect(harness.placed.placedFurnitureIds, {
      'living_room_desk_surface_left': 'wooden_mug',
      'living_room_desk_surface_right': 'ink_bottle',
    });
  });

  testWidgets('最初からやり直すは確認し、キャンセルならRoomを維持する', (tester) async {
    final harness = await _pumpPrototypeRoom(tester);

    await tester.tap(find.byKey(const ValueKey('prototypeControls')));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 500));
    await tester.tap(find.byKey(const ValueKey('prototypeReset')));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 500));

    expect(find.text('最初からやり直しますか？'), findsOneWidget);
    await tester.tap(find.text('キャンセル'));
    await tester.pump(const Duration(milliseconds: 500));

    expect(find.byType(RoomPage), findsOneWidget);
    expect(harness.shizuku.currentShizuku, 20);
  });

  testWidgets('完全初期化後は新しいRoomでtutorialと到着演出を再開する', (tester) async {
    final harness = await _pumpPrototypeRoom(
      tester,
      date: DateTime(2026, 8, 10),
    );

    await tester.tap(find.byKey(const ValueKey('prototypeControls')));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 500));
    await tester.tap(find.byKey(const ValueKey('prototypeReset')));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 500));
    await tester.tap(find.text('最初から'));
    await tester.pump();
    await tester.pump();
    await tester.pump();
    await tester.pump(const Duration(seconds: 1));

    expect(harness.date.today, DateTime(2026, 8, 7));
    expect(harness.read.readLetterIds, isEmpty);
    expect(harness.shizuku.currentShizuku, 0);
    expect(harness.shizuku.rewardedLetterIds, isEmpty);
    expect(harness.catalog.purchasedFurnitureIds, isEmpty);
    expect(harness.placed.placedFurnitureIds, isEmpty);
    expect(find.byType(RoomPage), findsOneWidget);

    await tester.pump();
    expect(
      harness.read.deliveredLetterIdOn(DateTime(2026, 8, 7)),
      'tutorial_001',
    );
    expect(find.byKey(const ValueKey('postArrivalGlow')), findsOneWidget);

    await tester.pump(const Duration(milliseconds: 4350));
    expect(find.byKey(const ValueKey('roomLetterLayer')), findsOneWidget);

    await harness.read.markAsRead(
      'tutorial_001',
      receivedDate: DateTime(2026, 8, 7),
    );
    await tester.pump();
    await tester.tap(find.byKey(const ValueKey('bottleTapArea')));
    await tester.pump();
    await tester.pump(const Duration(seconds: 1));

    expect(harness.read.hasOpenedTutorialBottle, isTrue);
    expect(find.text('気に入った家具を、ひとつ迎えてみましょう。'), findsOneWidget);
  });

  testWidgets('reset失敗時は中継画面で再試行できる', (tester) async {
    final repository = _FailOncePurchasedRepository();
    final harness = await _pumpPrototypeRoom(
      tester,
      date: DateTime(2026, 8, 10),
      purchasedRepository: repository,
    );

    await tester.tap(find.byKey(const ValueKey('prototypeControls')));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 500));
    await tester.tap(find.byKey(const ValueKey('prototypeReset')));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 500));
    await tester.tap(find.text('最初から'));
    await tester.pump();
    await tester.pump();

    expect(find.text('初期化に失敗しました'), findsOneWidget);
    expect(find.text('もう一度試す'), findsOneWidget);
    expect(harness.date.today, DateTime(2026, 8, 10));

    await tester.tap(find.text('もう一度試す'));
    await tester.pump();
    await tester.pump();
    await tester.pump(const Duration(seconds: 1));

    expect(repository.clearCallCount, 2);
    expect(harness.date.today, DateTime(2026, 8, 7));
    expect(find.byType(RoomPage), findsOneWidget);
  });
}

Future<void> _selectPrototypeOperation(
  WidgetTester tester,
  String operationKey,
) async {
  await tester.tap(find.byKey(const ValueKey('prototypeControls')));
  await tester.pump();
  await tester.pump(const Duration(milliseconds: 500));
  await tester.tap(find.byKey(ValueKey(operationKey)));
  await tester.pump();
}

Future<_PrototypeHarness> _pumpPrototypeRoom(
  WidgetTester tester, {
  DateTime? date,
  PurchasedFurnitureRepository? purchasedRepository,
}) async {
  SharedPreferences.setMockInitialValues({
    'prototypeDate': (date ?? DateTime(2026, 8, 7)).toIso8601String(),
    'readLetterState': jsonEncode({
      'version': 2,
      'receivedLetters': {'tutorial_001': '2026-08-07'},
      'deliveredLetters': {'2026-08-07': 'tutorial_001'},
    }),
    'shizukuState': jsonEncode({
      'version': 1,
      'currentShizuku': 20,
      'rewardedLetterIds': ['tutorial_001'],
    }),
    'purchasedFurnitureIds': ['wooden_mug', 'ink_bottle'],
    'placedFurnitureIds': jsonEncode({
      'living_room_desk_surface_left': 'wooden_mug',
      'living_room_desk_surface_right': 'ink_bottle',
    }),
  });

  final read = ReadLetterProvider(ReadLetterRepository());
  final shizuku = ShizukuProvider(ShizukuRepository());
  final catalog = CatalogProvider(
    purchasedRepository ?? PurchasedFurnitureRepository(),
  );
  final placed = PlacedFurnitureProvider(PlacedFurnitureRepository());
  final appDate = AppDateProvider(AppDateRepository());
  await Future.wait([
    read.load(),
    shizuku.load(),
    catalog.load(),
    placed.load(),
    appDate.load(),
  ]);

  await tester.pumpWidget(
    MultiProvider(
      providers: [
        ChangeNotifierProvider.value(value: read),
        ChangeNotifierProvider.value(value: shizuku),
        ChangeNotifierProvider.value(value: catalog),
        ChangeNotifierProvider.value(value: placed),
        ChangeNotifierProvider.value(value: appDate),
        ChangeNotifierProvider(
          create: (_) => WeatherProvider(_RainWeatherRepository()),
        ),
      ],
      child: MaterialApp(
        home: RoomPage(
          letterRepository: _PrototypeLetterRepository(),
          furnitureRepository: _EmptyFurnitureRepository(),
        ),
      ),
    ),
  );
  await tester.pump();
  await tester.pump();

  return _PrototypeHarness(read, shizuku, catalog, placed, appDate);
}

class _PrototypeHarness {
  const _PrototypeHarness(
    this.read,
    this.shizuku,
    this.catalog,
    this.placed,
    this.date,
  );

  final ReadLetterProvider read;
  final ShizukuProvider shizuku;
  final CatalogProvider catalog;
  final PlacedFurnitureProvider placed;
  final AppDateProvider date;
}

class _PrototypeLetterRepository extends LetterRepository {
  @override
  Future<List<Letter>> getAll() async => const [
    Letter(
      id: 'tutorial_001',
      title: 'tutorial',
      body: 'tutorial',
      requiredSeason: SeasonType.summer,
      requiredWeather: WeatherType.rain,
    ),
    Letter(
      id: 'letter_01',
      title: 'letter',
      body: 'letter',
      requiredSeason: SeasonType.summer,
      requiredWeather: WeatherType.rain,
    ),
  ];
}

class _EmptyFurnitureRepository extends FurnitureRepository {
  @override
  Future<List<Furniture>> getAll() async => [];
}

class _RainWeatherRepository extends WeatherRepository {
  @override
  Future<WeatherType?> getByDate(DateTime date) async => WeatherType.rain;
}

class _FailOncePurchasedRepository extends PurchasedFurnitureRepository {
  int clearCallCount = 0;

  @override
  Future<Set<String>> loadPurchasedFurnitureIds() async => {'wooden_mug'};

  @override
  Future<void> clear() async {
    clearCallCount++;
    if (clearCallCount == 1) {
      throw StateError('clear failed');
    }
  }
}
