import 'package:ame_tsuzuri/features/furniture/model/furniture.dart';
import 'package:ame_tsuzuri/features/room/presentation/widgets/furniture_reaction.dart';
import 'package:ame_tsuzuri/features/room/presentation/widgets/room_furniture_layers.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('RoomFurnitureLayers', () {
    testWidgets('未配置時はfallbackと花瓶だけを表示し空slotは描画しない', (tester) async {
      await _pumpLayers(tester);

      expect(_image('roomInitialFlowerImage'), findsOneWidget);
      expect(_image('roomFixedChairImage'), findsOneWidget);
      expect(_image('roomInitialCurtainImage'), findsOneWidget);
      expect(_image('roomFixedRugImage'), findsOneWidget);
      expect(
        find.image(const AssetImage('assets/images/room/vase.png')),
        findsOneWidget,
      );
      expect(
        find.byKey(const ValueKey('deskSurfaceLeftFurnitureLayer')),
        findsNothing,
      );
      expect(
        find.byKey(const ValueKey('deskSurfaceRightFurnitureLayer')),
        findsNothing,
      );
      expect(
        find.byKey(const ValueKey('windowShelfDecorFurnitureLayer')),
        findsNothing,
      );
      expect(
        find.byKey(const ValueKey('windowHangingDecorFurnitureLayer')),
        findsNothing,
      );
      expect(find.byType(RoomFurnitureLayers), findsNWidgets(4));
      expect(find.byType(FurnitureReaction), findsNothing);
    });

    testWidgets('8slotのFurniture画像・asset path・位置・サイズを維持する', (tester) async {
      await _pumpLayers(
        tester,
        hangingId: 'wind_chime',
        rugId: 'rectangular_rug',
        curtainId: 'rain_blue_curtains',
        shelfId: 'small_houseplant',
        deskLeftId: 'wooden_mug',
        deskRightId: 'ink_bottle',
        flowerId: 'blue_violet_flower',
        chairId: 'cushioned_chair',
      );

      const expectedAssets = {
        'wind_chime': 'assets/images/furniture/hanging/wind_chime.png',
        'rectangular_rug': 'assets/images/furniture/rug/check_rug.png',
        'rain_blue_curtains':
            'assets/images/furniture/curtain/rain_blue_curtains.png',
        'small_houseplant':
            'assets/images/furniture/window/small_houseplant.png',
        'wooden_mug': 'assets/images/furniture/desk/wooden_mug.png',
        'ink_bottle': 'assets/images/furniture/desk/ink_bottle.png',
        'blue_violet_flower':
            'assets/images/furniture/flower/blue_violet_flower.png',
        'cushioned_chair': 'assets/images/furniture/chair/cushioned_chair.png',
      };
      for (final entry in expectedAssets.entries) {
        final image = tester.widget<Image>(
          _image('roomFurnitureImage-${entry.key}'),
        );
        expect((image.image as AssetImage).assetName, entry.value);
        expect(image.fit, BoxFit.contain);
      }

      _expectAlignment(
        tester,
        'windowHangingDecorFurnitureLayer',
        const Alignment(0.57, -0.93),
      );
      _expectAlignment(
        tester,
        'windowShelfDecorFurnitureLayer',
        const Alignment(-0.55, -0.15),
      );
      _expectAlignment(
        tester,
        'deskSurfaceLeftFurnitureLayer',
        const Alignment(-0.65, 0.02),
      );
      _expectAlignment(
        tester,
        'deskSurfaceRightFurnitureLayer',
        const Alignment(0.70, 0.02),
      );
      _expectAlignment(tester, 'roomFlowerLayer', const Alignment(0.34, -0.26));
      _expectAlignment(tester, 'roomChairLayer', const Alignment(0, 0.72));
      _expectAlignment(tester, 'roomCurtainLayer', const Alignment(0, -0.83));
      _expectAlignment(tester, 'roomRugLayer', const Alignment(0.25, 1.035));

      expect(
        _layerWidth(tester, 'deskSurfaceLeftFurnitureLayer'),
        closeTo(97.5, 0.001),
      );
      expect(
        _layerWidth(tester, 'deskSurfaceRightFurnitureLayer'),
        closeTo(87.75, 0.001),
      );
      expect(
        _layerWidth(tester, 'windowShelfDecorFurnitureLayer'),
        closeTo(62.4, 0.001),
      );
      expect(
        _layerWidth(tester, 'windowHangingDecorFurnitureLayer'),
        closeTo(63.18, 0.001),
      );
      expect(_layerWidth(tester, 'roomFlowerLayer'), closeTo(50.7, 0.001));
      expect(_layerWidth(tester, 'roomChairLayer'), closeTo(183.3, 0.001));

      final curtainTransform = tester.widget<Transform>(
        find.descendant(
          of: find.byKey(const ValueKey('roomCurtainLayer')),
          matching: find.byType(Transform),
        ),
      );
      expect(curtainTransform.transform.storage[0], closeTo(0.91, 0.0001));
      expect(curtainTransform.transform.storage[5], closeTo(1.3, 0.0001));
      final rugTransform = tester.widget<Transform>(
        find.descendant(
          of: find.byKey(const ValueKey('roomRugLayer')),
          matching: find.byType(Transform),
        ),
      );
      expect(rugTransform.transform.storage[5], closeTo(0.75, 0.0001));
    });

    testWidgets('reaction対象の透明tap areaから既存animationを開始する', (tester) async {
      await _pumpLayers(
        tester,
        hangingId: 'wind_chime',
        flowerId: 'small_white_flower',
        chairId: 'rocking_chair',
      );

      for (final entry in const {
        'wind_chime': Size(63.18, 94.77),
        'small_white_flower': Size(50.7, 76.05),
        'rocking_chair': Size(183.3, 243.0873046875),
      }.entries) {
        final tapArea = find.byKey(
          ValueKey('furnitureReactionTapArea-${entry.key}'),
        );
        expect(tapArea, findsOneWidget);
        expect(tester.getSize(tapArea).width, closeTo(entry.value.width, 0.01));
        expect(
          tester.getSize(tapArea).height,
          closeTo(entry.value.height, 0.01),
        );

        await tester.tap(tapArea);
        await tester.pump();
        await tester.pump(const Duration(milliseconds: 100));
        final transform = tester.widget<Transform>(
          find.byKey(ValueKey('furnitureReactionTransform-${entry.key}')),
        );
        expect(transform.transform.storage[1].abs(), greaterThan(0.0001));
        await tester.pumpAndSettle();
      }
    });

    testWidgets('reaction非対象Furnitureには追加tap areaを表示しない', (tester) async {
      await _pumpLayers(tester, chairId: 'cushioned_chair');

      expect(
        find.byKey(const ValueKey('furnitureReactionTapArea-cushioned_chair')),
        findsNothing,
      );
      expect(
        find.byKey(const ValueKey('furnitureReaction-cushioned_chair')),
        findsNothing,
      );
    });

    testWidgets('未知・欠損Furnitureは空表示または既存fallbackへ戻る', (tester) async {
      await _pumpLayers(
        tester,
        furnitures: const [],
        hangingId: 'unknown_hanging',
        rugId: 'missing_rug',
        curtainId: 'missing_curtain',
        shelfId: 'unknown_shelf',
        deskLeftId: 'unknown_desk',
        flowerId: 'unknown_flower',
        chairId: 'unknown_chair',
      );

      expect(
        find.byKey(const ValueKey('windowHangingDecorFurnitureLayer')),
        findsNothing,
      );
      expect(
        find.byKey(const ValueKey('windowShelfDecorFurnitureLayer')),
        findsNothing,
      );
      expect(
        find.byKey(const ValueKey('deskSurfaceLeftFurnitureLayer')),
        findsNothing,
      );
      expect(_image('roomInitialFlowerImage'), findsOneWidget);
      expect(_image('roomFixedChairImage'), findsOneWidget);
      expect(_image('roomInitialCurtainImage'), findsOneWidget);
      expect(_image('roomFixedRugImage'), findsOneWidget);
      expect(tester.takeException(), isNull);
    });

    testWidgets('surfaceとreaction内のStack順を維持する', (tester) async {
      await _pumpLayers(
        tester,
        hangingId: 'wind_chime',
        rugId: 'rectangular_rug',
        curtainId: 'rain_blue_curtains',
        shelfId: 'small_houseplant',
        deskLeftId: 'wooden_mug',
        deskRightId: 'ink_bottle',
        flowerId: 'small_white_flower',
        chairId: 'rocking_chair',
      );

      final surfaces = tester.widget<Stack>(
        find.byKey(const ValueKey('roomFurnitureSurfaceLayers')),
      );
      expect(surfaces.children.map((child) => child.key).toList(), const [
        ValueKey('roomRugAsyncFurnitureLayer'),
        ValueKey('roomCurtainAsyncFurnitureLayer'),
        ValueKey('roomWindowShelfAsyncFurnitureLayer'),
        ValueKey('roomDeskLeftAsyncFurnitureLayer'),
        ValueKey('roomDeskRightAsyncFurnitureLayer'),
      ]);

      final chairAndReactions = tester.widget<Stack>(
        find.byKey(const ValueKey('roomChairAndReactionLayers')),
      );
      expect(
        chairAndReactions.children.first.key,
        const ValueKey('roomChairAsyncFurnitureLayer'),
      );
      final reactionTapAreaKeys = find
          .descendant(
            of: find.byKey(const ValueKey('roomChairAndReactionLayers')),
            matching: find.byWidgetPredicate(
              (widget) =>
                  widget.key?.toString().contains(
                    'furnitureReactionTapArea-',
                  ) ??
                  false,
            ),
          )
          .evaluate()
          .map((element) => element.widget.key)
          .toList();
      expect(reactionTapAreaKeys, const [
        ValueKey('furnitureReactionTapArea-wind_chime'),
        ValueKey('furnitureReactionTapArea-small_white_flower'),
        ValueKey('furnitureReactionTapArea-rocking_chair'),
      ]);
    });

    for (final size in const [
      Size(320, 568),
      Size(390, 700),
      Size(1200, 800),
    ]) {
      testWidgets('${size.width.toInt()}px幅でoverflowしない', (tester) async {
        await _pumpLayers(
          tester,
          size: size,
          hangingId: 'wind_chime',
          rugId: 'rectangular_rug',
          curtainId: 'rain_blue_curtains',
          shelfId: 'small_houseplant',
          deskLeftId: 'wooden_mug',
          deskRightId: 'ink_bottle',
          flowerId: 'small_white_flower',
          chairId: 'rocking_chair',
        );

        expect(tester.takeException(), isNull);
      });
    }
  });
}

Finder _image(String key) => find.byKey(ValueKey(key));

void _expectAlignment(WidgetTester tester, String key, Alignment expected) {
  expect(tester.widget<Align>(find.byKey(ValueKey(key))).alignment, expected);
}

double _layerWidth(WidgetTester tester, String layerKey) {
  final sizedBox = tester.widget<SizedBox>(
    find
        .descendant(
          of: find.byKey(ValueKey(layerKey)),
          matching: find.byType(SizedBox),
        )
        .first,
  );
  return sizedBox.width!;
}

Future<void> _pumpLayers(
  WidgetTester tester, {
  Size size = const Size(390, 700),
  List<Furniture> furnitures = _furnitures,
  String? hangingId,
  String? rugId,
  String? curtainId,
  String? shelfId,
  String? deskLeftId,
  String? deskRightId,
  String? flowerId,
  String? chairId,
}) async {
  tester.view.devicePixelRatio = 1;
  tester.view.physicalSize = const Size(1400, 1000);
  addTearDown(tester.view.resetDevicePixelRatio);
  addTearDown(tester.view.resetPhysicalSize);

  final furnituresFuture = Future.value(furnitures);
  final hangingKey = GlobalKey<FurnitureReactionState>();
  final flowerKey = GlobalKey<FurnitureReactionState>();
  final chairKey = GlobalKey<FurnitureReactionState>();
  await tester.pumpWidget(
    MaterialApp(
      home: Scaffold(
        body: Align(
          alignment: Alignment.topLeft,
          child: SizedBox(
            width: size.width,
            height: size.height,
            child: Stack(
              fit: StackFit.expand,
              children: [
                RoomFurnitureLayers.hanging(
                  furnituresFuture: furnituresFuture,
                  furnitureId: hangingId,
                  roomWidth: size.width,
                  reactionKey: hangingKey,
                ),
                RoomFurnitureLayers.surfaces(
                  furnituresFuture: furnituresFuture,
                  roomWidth: size.width,
                  floorRugFurnitureId: rugId,
                  curtainFurnitureId: curtainId,
                  windowShelfDecorFurnitureId: shelfId,
                  deskSurfaceLeftFurnitureId: deskLeftId,
                  deskSurfaceRightFurnitureId: deskRightId,
                ),
                RoomFurnitureLayers.flowerAndVase(
                  furnituresFuture: furnituresFuture,
                  furnitureId: flowerId,
                  roomWidth: size.width,
                  reactionKey: flowerKey,
                ),
                RoomFurnitureLayers.chairAndReactionAreas(
                  furnituresFuture: furnituresFuture,
                  roomWidth: size.width,
                  windowHangingDecorFurnitureId: hangingId,
                  flowerFurnitureId: flowerId,
                  chairFurnitureId: chairId,
                  windowHangingReactionKey: hangingKey,
                  flowerReactionKey: flowerKey,
                  chairReactionKey: chairKey,
                ),
              ],
            ),
          ),
        ),
      ),
    ),
  );
  await tester.pump();
}

const _furnitures = [
  Furniture(
    id: 'wooden_mug',
    name: '木のマグカップ',
    price: 30,
    size: 'small',
    slotIds: [
      'living_room_desk_surface_left',
      'living_room_desk_surface_right',
    ],
    imagePath: 'furniture/desk/wooden_mug.png',
    initialAvailable: true,
  ),
  Furniture(
    id: 'ink_bottle',
    name: 'インク瓶',
    price: 30,
    size: 'small',
    slotIds: [
      'living_room_desk_surface_left',
      'living_room_desk_surface_right',
    ],
    imagePath: 'furniture/desk/ink_bottle.png',
    initialAvailable: true,
  ),
  Furniture(
    id: 'small_houseplant',
    name: '小さな観葉植物',
    price: 30,
    size: 'small',
    slotIds: ['living_room_window_shelf_decor'],
    imagePath: 'furniture/window/small_houseplant.png',
    initialAvailable: true,
  ),
  Furniture(
    id: 'wind_chime',
    name: '風鈴',
    price: 30,
    size: 'small',
    slotIds: ['living_room_window_hanging_decor'],
    imagePath: 'furniture/hanging/wind_chime.png',
    initialAvailable: true,
  ),
  Furniture(
    id: 'blue_violet_flower',
    name: '青紫の花',
    price: 10,
    size: 'small',
    slotIds: ['living_room_window_vase'],
    imagePath: 'furniture/flower/blue_violet_flower.png',
    initialAvailable: true,
  ),
  Furniture(
    id: 'small_white_flower',
    name: '白い小花',
    price: 10,
    size: 'small',
    slotIds: ['living_room_window_vase'],
    imagePath: 'furniture/flower/small_white_flower.png',
    initialAvailable: true,
  ),
  Furniture(
    id: 'rain_blue_curtains',
    name: '雨青のカーテン',
    price: 60,
    size: 'large',
    slotIds: ['living_room_window_curtain'],
    imagePath: 'furniture/curtain/rain_blue_curtains.png',
    initialAvailable: true,
  ),
  Furniture(
    id: 'rectangular_rug',
    name: 'チェック柄ラグ',
    price: 50,
    size: 'large',
    slotIds: ['living_room_floor_rug'],
    imagePath: 'furniture/rug/check_rug.png',
    initialAvailable: true,
  ),
  Furniture(
    id: 'cushioned_chair',
    name: 'クッション椅子',
    price: 60,
    size: 'large',
    slotIds: ['living_room_chair'],
    imagePath: 'furniture/chair/cushioned_chair.png',
    initialAvailable: true,
  ),
  Furniture(
    id: 'rocking_chair',
    name: 'ロッキングチェア',
    price: 80,
    size: 'large',
    slotIds: ['living_room_chair'],
    imagePath: 'furniture/chair/rocking_chair.png',
    initialAvailable: true,
  ),
];
