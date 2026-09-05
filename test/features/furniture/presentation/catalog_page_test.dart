import 'dart:async';

import 'package:ame_tsuzuri/features/furniture/model/furniture.dart';
import 'package:ame_tsuzuri/features/furniture/model/placement_slot.dart';
import 'package:ame_tsuzuri/features/furniture/presentation/catalog_page.dart';
import 'package:ame_tsuzuri/features/furniture/provider/catalog_provider.dart';
import 'package:ame_tsuzuri/features/furniture/provider/placed_furniture_provider.dart';
import 'package:ame_tsuzuri/features/furniture/repository/furniture_repository.dart';
import 'package:ame_tsuzuri/features/furniture/repository/placed_furniture_repository.dart';
import 'package:ame_tsuzuri/features/furniture/repository/placement_slot_repository.dart';
import 'package:ame_tsuzuri/features/furniture/repository/purchased_furniture_repository.dart';
import 'package:ame_tsuzuri/features/letters/provider/shizuku_provider.dart';
import 'package:ame_tsuzuri/features/letters/model/shizuku_state.dart';
import 'package:ame_tsuzuri/features/letters/repository/shizuku_repository.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';

const _deskSurfaceLeftSlotId = 'living_room_desk_surface_left';
const _deskSurfaceRightSlotId = 'living_room_desk_surface_right';
const _windowShelfDecorSlotId = 'living_room_window_shelf_decor';
const _windowHangingDecorSlotId = 'living_room_window_hanging_decor';
const _floorRugSlotId = 'living_room_floor_rug';
const _chairSlotId = 'living_room_chair';
const _windowVaseSlotId = 'living_room_window_vase';

const _furnitureA = Furniture(
  id: 'furniture_a',
  name: '家具A',
  price: 30,
  size: 'small',
  slotIds: ['test_slot'],
  imagePath: 'unused.png',
  initialAvailable: true,
);
const _furnitureB = Furniture(
  id: 'furniture_b',
  name: '家具B',
  price: 30,
  size: 'small',
  slotIds: ['test_slot'],
  imagePath: 'unused.png',
  initialAvailable: true,
);
const _furnitureC = Furniture(
  id: 'furniture_c',
  name: '家具C',
  price: 30,
  size: 'small',
  slotIds: ['test_slot'],
  imagePath: 'unused.png',
  initialAvailable: true,
);
const _longNameFurniture = Furniture(
  id: 'long_name_furniture',
  name: 'とても長い名前の木製アンティークチェア',
  price: 30,
  size: 'small',
  slotIds: ['test_slot'],
  imagePath: 'unused.png',
  initialAvailable: true,
);
const _woodenMug = Furniture(
  id: 'wooden_mug',
  name: '木のマグ',
  price: 30,
  size: 'small',
  slotIds: [_deskSurfaceLeftSlotId, _deskSurfaceRightSlotId],
  imagePath: 'furniture/desk/wooden_mug.png',
  initialAvailable: true,
);
const _inkBottle = Furniture(
  id: 'ink_bottle',
  name: 'インク瓶',
  price: 30,
  size: 'small',
  slotIds: [_deskSurfaceLeftSlotId, _deskSurfaceRightSlotId],
  imagePath: 'furniture/desk/ink_bottle.png',
  initialAvailable: true,
);
const _woodenFoxFigure = Furniture(
  id: 'wooden_fox_figure',
  name: '木彫りのキツネ',
  price: 30,
  size: 'small',
  slotIds: [_deskSurfaceLeftSlotId, _deskSurfaceRightSlotId],
  imagePath: 'furniture/desk/wooden_fox_figure.png',
  initialAvailable: true,
);
const _smallHouseplant = Furniture(
  id: 'small_houseplant',
  name: '小さな観葉植物',
  price: 30,
  size: 'small',
  slotIds: [_windowShelfDecorSlotId],
  imagePath: 'furniture/window/small_houseplant.png',
  initialAvailable: true,
);
const _woodenBirdFigure = Furniture(
  id: 'wooden_bird_figure',
  name: '木の小鳥',
  price: 30,
  size: 'small',
  slotIds: [_windowShelfDecorSlotId],
  imagePath: 'furniture/window/wooden_bird.png',
  initialAvailable: true,
);
const _smallGlassOrnament = Furniture(
  id: 'small_glass_ornament',
  name: 'ガラス細工',
  price: 30,
  size: 'small',
  slotIds: [_windowShelfDecorSlotId],
  imagePath: 'furniture/window/glass_ornament.png',
  initialAvailable: true,
);
const _windChime = Furniture(
  id: 'wind_chime',
  name: '風鈴',
  price: 30,
  size: 'small',
  slotIds: [_windowHangingDecorSlotId],
  imagePath: 'furniture/hanging/wind_chime.png',
  initialAvailable: true,
);
const _teruTeruBozu = Furniture(
  id: 'teru_teru_bozu',
  name: 'てるてる坊主',
  price: 30,
  size: 'small',
  slotIds: [_windowHangingDecorSlotId],
  imagePath: 'furniture/hanging/teru_teru_bozu.png',
  initialAvailable: true,
);
const _moonMobile = Furniture(
  id: 'moon_mobile',
  name: '月のモビール',
  price: 30,
  size: 'small',
  slotIds: [_windowHangingDecorSlotId],
  imagePath: 'furniture/hanging/moon_mobile.png',
  initialAvailable: true,
);
const _roundRug = Furniture(
  id: 'round_rug',
  name: '無地の丸ラグ',
  price: 70,
  size: 'large',
  slotIds: [_floorRugSlotId],
  imagePath: 'furniture/rug/round_rug.png',
  initialAvailable: true,
);
const _rectangularRug = Furniture(
  id: 'rectangular_rug',
  name: '淡いチェックの四角ラグ',
  price: 70,
  size: 'large',
  slotIds: [_floorRugSlotId],
  imagePath: 'furniture/rug/check_rug.png',
  initialAvailable: true,
);
const _woodenChair = Furniture(
  id: 'wooden_chair',
  name: '木製チェア',
  price: 70,
  size: 'large',
  slotIds: [_chairSlotId],
  imagePath: 'furniture/chair/wooden_chair.png',
  initialAvailable: true,
);
const _smallWhiteFlower = Furniture(
  id: 'small_white_flower',
  name: '白い小花',
  price: 10,
  size: 'small',
  slotIds: [_windowVaseSlotId],
  imagePath: 'furniture/window/small_white_flower.png',
  initialAvailable: true,
);
const _blueVioletFlower = Furniture(
  id: 'blue_violet_flower',
  name: '青紫の花',
  price: 10,
  size: 'small',
  slotIds: [_windowVaseSlotId],
  imagePath: 'furniture/window/blue_violet_flower.png',
  initialAvailable: true,
);
const _paleYellowFlower = Furniture(
  id: 'pale_yellow_flower',
  name: '淡い黄色の花',
  price: 10,
  size: 'small',
  slotIds: [_windowVaseSlotId],
  imagePath: 'furniture/window/pale_yellow_flower.png',
  initialAvailable: true,
);
const _flowers = [_smallWhiteFlower, _blueVioletFlower, _paleYellowFlower];
const _missingImageFurniture = Furniture(
  id: 'missing_image',
  name: '画像のない家具',
  price: 30,
  size: 'small',
  slotIds: ['test_slot'],
  imagePath: 'furniture/desk/missing.png',
  initialAvailable: true,
);
const _hiddenFurniture = Furniture(
  id: 'hidden_furniture',
  name: '非公開家具',
  price: 30,
  size: 'small',
  slotIds: ['legacy_slot'],
  imagePath: 'unused.png',
  initialAvailable: false,
);
const _multiSlotFurniture = Furniture(
  id: 'multi_slot_furniture',
  name: '複数配置家具',
  price: 30,
  size: 'small',
  slotIds: ['slot_a', 'long_slot'],
  imagePath: 'unused.png',
  initialAvailable: true,
);

void main() {
  group('v0.3.8 配置説明', () {
    testWidgets('公開17家具の場所名は本番slot定義と一致する', (tester) async {
      final furnitures = (await FurnitureRepository().getAll())
          .where((furniture) => furniture.initialAvailable)
          .toList();
      expect(furnitures, hasLength(17));
      final repository = PlacementSlotRepository();
      for (final furniture in furnitures) {
        final names = <String>[];
        for (final id in furniture.slotIds) {
          names.add((await repository.getById(id))!.name);
        }
        await _pumpCatalog(
          tester,
          furnitures: [furniture],
          placementSlotRepository: repository,
        );
        final text = tester.widget<Text>(
          find.byKey(ValueKey('catalogPlacementNames-${furniture.id}')),
        );
        expect(text.data, '置き場所：${names.join('／')}');
        expect(text.maxLines, isNull);
        expect(text.overflow, isNot(TextOverflow.ellipsis));
        await tester.pumpWidget(const SizedBox.shrink());
      }
    });

    for (final entry in {
      _smallWhiteFlower: '花瓶はそのままで、現在の花と入れ替わります。',
      _woodenChair: '現在の椅子と入れ替わります。',
      _roundRug: '現在のラグと入れ替わります。',
      _woodenMug: '選んだ場所に家具がある場合は、入れ替えて置きます。',
      _windChime: '選んだ場所に家具がある場合は、入れ替えて置きます。',
      _smallHouseplant: '選んだ場所に家具がある場合は、入れ替えて置きます。',
    }.entries) {
      testWidgets('${entry.key.id}の購入前に配置先・交換・後日配置を伝える', (tester) async {
        final furniture = entry.key;
        final harness = await _pumpCatalog(tester, furnitures: [furniture]);
        await tester.tap(_furnitureTile(furniture.name));
        await tester.pumpAndSettle();
        final description = tester
            .widget<Text>(
              find.byKey(const ValueKey('purchasePlacementDescription')),
            )
            .data!;
        expect(description, contains(entry.value));
        for (final id in furniture.slotIds) {
          final slot = await _FakePlacementSlotRepository().getById(id);
          expect(description, contains(slot!.name));
        }
        expect(find.text('配置はあとからでもできます。'), findsOneWidget);
        expect(description, isNot(contains('追加型')));
        expect(description, isNot(contains('交換型')));
        await tester.tap(find.text('やめる'));
        await tester.pumpAndSettle();
        expect(harness.shizukuProvider.currentShizuku, 100);
        expect(harness.catalogProvider.isPurchased(furniture.id), isFalse);
      });
    }

    for (final furniture in [_smallWhiteFlower, _woodenChair, _roundRug]) {
      testWidgets('${furniture.id}の初期Assetを空き扱いせず自分の配置も区別する', (tester) async {
        final harness = await _pumpCatalog(
          tester,
          furnitures: [furniture],
          purchasedFurnitureIds: {furniture.id},
        );
        await tester.tap(_furnitureTile(furniture.name));
        await tester.pumpAndSettle();
        final stateFinder = find.byKey(
          ValueKey('placementState-${furniture.slotIds.single}'),
        );
        expect(tester.widget<Text>(stateFinder).data, contains('入れ替わります'));
        expect(find.text('空いています'), findsNothing);
        if (furniture == _smallWhiteFlower) {
          expect(tester.widget<Text>(stateFinder).data, contains('花瓶はそのまま'));
        }
        await tester.tap(find.text('キャンセル'));
        await tester.pumpAndSettle();
        await harness.placedFurnitureProvider.place(
          slotId: furniture.slotIds.single,
          furnitureId: furniture.id,
          isPurchased: true,
          allowedSlotIds: furniture.slotIds,
        );
        await tester.pumpAndSettle();
        await tester.tap(_furnitureTile(furniture.name));
        await tester.pumpAndSettle();
        expect(tester.widget<Text>(stateFinder).data, '現在ここに配置中');
        expect(find.textContaining('家具あり'), findsNothing);
      });
    }

    testWidgets('空き・自分・別家具を区別し移動先の確認と所有状態を維持する', (tester) async {
      final harness = await _pumpCatalog(
        tester,
        openAsRoute: true,
        furnitures: const [_woodenMug, _inkBottle],
        purchasedFurnitureIds: const {'wooden_mug', 'ink_bottle'},
        placedFurnitureIds: const {_deskSurfaceLeftSlotId: 'wooden_mug'},
      );
      await tester.tap(_furnitureTile(_woodenMug.name));
      await tester.pumpAndSettle();
      expect(find.text('現在ここに配置中'), findsOneWidget);
      expect(find.text('空いています'), findsOneWidget);
      await tester.tap(find.text('キャンセル'));
      await tester.pumpAndSettle();
      await harness.placedFurnitureProvider.place(
        slotId: _deskSurfaceRightSlotId,
        furnitureId: 'ink_bottle',
        isPurchased: true,
        allowedSlotIds: _inkBottle.slotIds,
      );
      await tester.pumpAndSettle();
      await tester.tap(_furnitureTile(_woodenMug.name));
      await tester.pumpAndSettle();
      expect(find.text('現在ここに配置中'), findsOneWidget);
      expect(find.text('家具あり・入れ替え'), findsOneWidget);
      await tester.tap(
        find.byKey(const ValueKey('placementOption-$_deskSurfaceRightSlotId')),
      );
      await tester.pumpAndSettle();
      expect(find.text('置き換える'), findsOneWidget);
      await tester.tap(find.text('置き換える'));
      await tester.pumpAndSettle();
      expect(harness.placedFurnitureProvider.placedFurnitureIds, {
        _deskSurfaceRightSlotId: 'wooden_mug',
      });
      expect(harness.catalogProvider.isPurchased('ink_bottle'), isTrue);
    });

    testWidgets('場所名の失敗でも購入でき配置時は既存Repositoryから再取得する', (tester) async {
      final repository = _FailOncePlacementSlotRepository();
      final harness = await _pumpCatalog(
        tester,
        furnitures: const [_woodenMug],
        placementSlotRepository: repository,
        blockPurchase: false,
      );
      expect(
        find.byKey(const ValueKey('catalogPlacementNames-wooden_mug')),
        findsNothing,
      );
      await _buyFurniture(tester, _woodenMug.name);
      expect(find.text('机（左）に置く'), findsOneWidget);
      expect(harness.catalogProvider.isPurchased('wooden_mug'), isTrue);
      await tester.tap(find.text('キャンセル'));
      await tester.pumpAndSettle();
      expect(harness.shizukuProvider.currentShizuku, 70);
      expect(harness.placedFurnitureProvider.placedFurnitureIds, isEmpty);
    });

    testWidgets('名前読み込み待ちでも購入確認を開け完了時に説明を更新する', (tester) async {
      final repository = _DelayedPlacementSlotRepository();
      final harness = await _pumpCatalog(
        tester,
        furnitures: const [_woodenMug, _inkBottle],
        placementSlotRepository: repository,
      );
      await tester.tap(_furnitureTile(_woodenMug.name));
      await tester.pumpAndSettle();
      expect(find.text('迎える'), findsOneWidget);
      repository.ready.complete();
      await tester.pumpAndSettle();
      expect(
        tester
            .widget<Text>(
              find.byKey(const ValueKey('purchasePlacementDescription')),
            )
            .data,
        contains('机（左）または机（右）'),
      );
      await tester.tap(find.text('やめる'));
      await tester.pumpAndSettle();
      await harness.placedFurnitureProvider.remove('wooden_mug');
      await tester.pumpAndSettle();
      expect(repository.calls, {
        _deskSurfaceLeftSlotId: 1,
        _deskSurfaceRightSlotId: 1,
      });
    });

    for (final size in [const Size(320, 640), const Size(390, 700)]) {
      for (final scale in [1.0, 1.5]) {
        testWidgets('${size.width}px・文字倍率$scaleで一覧・購入・配置を操作できる', (
          tester,
        ) async {
          tester.view.physicalSize = size;
          tester.view.devicePixelRatio = 1;
          addTearDown(tester.view.resetPhysicalSize);
          addTearDown(tester.view.resetDevicePixelRatio);
          await _pumpCatalog(
            tester,
            textScale: scale,
            furnitures: const [
              _woodenMug,
              _windChime,
              _longNameFurniture,
              _smallWhiteFlower,
            ],
            purchasedFurnitureIds: const {'long_name_furniture', 'wind_chime'},
            placedFurnitureIds: const {_windowHangingDecorSlotId: 'wind_chime'},
            blockPurchase: false,
          );
          for (final furniture in [
            _woodenMug,
            _windChime,
            _longNameFurniture,
            _smallWhiteFlower,
          ]) {
            final row = find.byKey(
              ValueKey('catalogFurnitureRow-${furniture.id}'),
            );
            await tester.scrollUntilVisible(
              row,
              120,
              scrollable: find.descendant(
                of: find.byKey(const ValueKey('catalogFurnitureList')),
                matching: find.byType(Scrollable),
              ),
            );
            final location = tester.widget<Text>(
              find.byKey(ValueKey('catalogPlacementNames-${furniture.id}')),
            );
            expect(location.maxLines, isNull);
            expect(tester.takeException(), isNull);
          }
          await tester.tap(_furnitureTile(_smallWhiteFlower.name));
          await tester.pumpAndSettle();
          expect(tester.takeException(), isNull);
          await tester.tap(find.text('迎える'));
          await tester.pumpAndSettle();
          expect(
            find.byKey(const ValueKey('placementState-$_windowVaseSlotId')),
            findsOneWidget,
          );
          expect(tester.takeException(), isNull);
          await tester.tap(find.text('キャンセル'));
          await tester.pumpAndSettle();
          expect(find.text('配置する'), findsWidgets);
        });
      }
    }
  });

  group('一輪挿しの花', () {
    testWidgets('3種類を10滴商品として表示する', (tester) async {
      await _pumpCatalog(tester, furnitures: _flowers);

      for (final flower in _flowers) {
        expect(_furnitureTile(flower.name), findsOneWidget);
      }
      expect(find.text('10滴で迎える'), findsNWidgets(3));
    });

    for (final flower in _flowers) {
      testWidgets('${flower.name}を残高10滴で購入して一輪挿しへ配置できる', (tester) async {
        final harness = await _pumpCatalog(
          tester,
          openAsRoute: true,
          blockPurchase: false,
          initialShizuku: 10,
          purchasedFurnitureIds: const {},
          furnitures: [flower],
        );

        await _buyFurniture(tester, flower.name);

        expect(harness.catalogProvider.isPurchased(flower.id), isTrue);
        expect(harness.shizukuProvider.currentShizuku, 0);
        expect(
          find.byKey(const ValueKey('placementOption-$_windowVaseSlotId')),
          findsOneWidget,
        );
        await tester.tap(
          find.byKey(const ValueKey('placementOption-$_windowVaseSlotId')),
        );
        await tester.pumpAndSettle();
        expect(harness.placedFurnitureProvider.placedFurnitureIds, {
          _windowVaseSlotId: flower.id,
        });
      });
    }

    testWidgets('残高9滴では購入できない', (tester) async {
      final harness = await _pumpCatalog(
        tester,
        blockPurchase: false,
        initialShizuku: 9,
        purchasedFurnitureIds: const {},
        furnitures: const [_smallWhiteFlower],
      );

      await _buyFurniture(tester, _smallWhiteFlower.name);

      expect(
        harness.catalogProvider.isPurchased(_smallWhiteFlower.id),
        isFalse,
      );
      expect(harness.shizukuProvider.currentShizuku, 9);
      expect(find.text('雫が足りません'), findsOneWidget);
    });

    testWidgets('同じslotで花を交換し旧花の購入状態を維持して取り外せる', (tester) async {
      final harness = await _pumpCatalog(
        tester,
        openAsRoute: true,
        furnitures: const [_smallWhiteFlower, _blueVioletFlower],
        purchasedFurnitureIds: const {
          'small_white_flower',
          'blue_violet_flower',
        },
        placedFurnitureIds: const {_windowVaseSlotId: 'small_white_flower'},
      );

      await tester.tap(_furnitureTile(_blueVioletFlower.name));
      await tester.pumpAndSettle();
      await tester.tap(
        find.byKey(const ValueKey('placementOption-$_windowVaseSlotId')),
      );
      await tester.pumpAndSettle();
      await tester.tap(find.text('置き換える'));
      await tester.pumpAndSettle();

      expect(harness.placedFurnitureProvider.placedFurnitureIds, const {
        _windowVaseSlotId: 'blue_violet_flower',
      });
      expect(harness.catalogProvider.isPurchased('small_white_flower'), isTrue);

      await tester.tap(find.byKey(const ValueKey('openCatalog')));
      await tester.pumpAndSettle();
      await tester.tap(_furnitureTile(_blueVioletFlower.name));
      await tester.pumpAndSettle();
      await tester.tap(find.text('取り外す'));
      await tester.pumpAndSettle();
      expect(harness.placedFurnitureProvider.placedFurnitureIds, isEmpty);
    });

    testWidgets('tutorial初回でも花を購入・配置できる', (tester) async {
      final harness = await _pumpCatalog(
        tester,
        openAsRoute: true,
        showTutorialGuide: true,
        blockPurchase: false,
        initialShizuku: 30,
        purchasedFurnitureIds: const {},
        furnitures: const [_paleYellowFlower],
      );
      await tester.tap(
        find.byKey(const ValueKey('catalogTutorialGuideContinue')),
      );
      await tester.pumpAndSettle();
      await _buyFurniture(tester, _paleYellowFlower.name);
      await tester.tap(
        find.byKey(const ValueKey('placementOption-$_windowVaseSlotId')),
      );
      await tester.pumpAndSettle();

      expect(harness.shizukuProvider.currentShizuku, 20);
      expect(harness.placedFurnitureProvider.placedFurnitureIds, const {
        _windowVaseSlotId: 'pale_yellow_flower',
      });
    });
  });

  group('chair furniture', () {
    testWidgets('70雫で購入してchair slotだけへ配置できる', (tester) async {
      final harness = await _pumpCatalog(
        tester,
        openAsRoute: true,
        blockPurchase: false,
        initialShizuku: 70,
        purchasedFurnitureIds: const {},
        furnitures: const [_woodenChair],
      );

      await _buyFurniture(tester, _woodenChair.name);

      expect(harness.catalogProvider.isPurchased(_woodenChair.id), isTrue);
      expect(harness.shizukuProvider.currentShizuku, 0);
      expect(
        find.byKey(const ValueKey('placementOption-$_chairSlotId')),
        findsOneWidget,
      );
      expect(
        find.byKey(const ValueKey('placementOption-$_floorRugSlotId')),
        findsNothing,
      );

      await tester.tap(
        find.byKey(const ValueKey('placementOption-$_chairSlotId')),
      );
      await tester.pumpAndSettle();

      expect(harness.placedFurnitureProvider.placedFurnitureIds, const {
        _chairSlotId: 'wooden_chair',
      });
    });
  });

  group('丸ラグ家具', () {
    testWidgets('70滴で購入してラグslotだけへ配置できる', (tester) async {
      final harness = await _pumpCatalog(
        tester,
        openAsRoute: true,
        blockPurchase: false,
        initialShizuku: 70,
        purchasedFurnitureIds: const {},
        furnitures: const [_roundRug],
      );

      await _buyFurniture(tester, _roundRug.name);

      expect(harness.catalogProvider.isPurchased('round_rug'), isTrue);
      expect(harness.shizukuProvider.currentShizuku, 0);
      expect(
        find.byKey(const ValueKey('placementOption-$_floorRugSlotId')),
        findsOneWidget,
      );
      expect(
        find.byKey(
          const ValueKey('placementOption-$_windowHangingDecorSlotId'),
        ),
        findsNothing,
      );
      expect(
        find.byKey(const ValueKey('placementOption-$_windowShelfDecorSlotId')),
        findsNothing,
      );
      expect(
        find.byKey(const ValueKey('placementOption-$_deskSurfaceLeftSlotId')),
        findsNothing,
      );

      await tester.tap(
        find.byKey(const ValueKey('placementOption-$_floorRugSlotId')),
      );
      await tester.pumpAndSettle();

      expect(harness.placedFurnitureProvider.placedFurnitureIds, const {
        _floorRugSlotId: 'round_rug',
      });
      expect(find.byType(CatalogPage), findsNothing);
    });

    testWidgets('配置済み丸ラグを取り外せる', (tester) async {
      final harness = await _pumpCatalog(
        tester,
        furnitures: const [_roundRug],
        purchasedFurnitureIds: const {'round_rug'},
        placedFurnitureIds: const {_floorRugSlotId: 'round_rug'},
      );

      await tester.tap(_furnitureTile(_roundRug.name));
      await tester.pumpAndSettle();
      await tester.tap(find.text('取り外す'));
      await tester.pumpAndSettle();

      expect(harness.placedFurnitureProvider.placedFurnitureIds, isEmpty);
      expect(harness.catalogProvider.isPurchased('round_rug'), isTrue);
      expect(find.byType(CatalogPage), findsOneWidget);
    });

    testWidgets('チェック柄ラグを70滴で購入してラグslotだけへ配置できる', (tester) async {
      final harness = await _pumpCatalog(
        tester,
        openAsRoute: true,
        blockPurchase: false,
        initialShizuku: 70,
        purchasedFurnitureIds: const {},
        furnitures: const [_rectangularRug],
      );

      await _buyFurniture(tester, _rectangularRug.name);

      expect(harness.catalogProvider.isPurchased('rectangular_rug'), isTrue);
      expect(harness.shizukuProvider.currentShizuku, 0);
      expect(
        find.byKey(const ValueKey('placementOption-$_floorRugSlotId')),
        findsOneWidget,
      );
      expect(
        find.byKey(
          const ValueKey('placementOption-$_windowHangingDecorSlotId'),
        ),
        findsNothing,
      );
      expect(
        find.byKey(const ValueKey('placementOption-$_windowShelfDecorSlotId')),
        findsNothing,
      );
      expect(
        find.byKey(const ValueKey('placementOption-$_deskSurfaceLeftSlotId')),
        findsNothing,
      );

      await tester.tap(
        find.byKey(const ValueKey('placementOption-$_floorRugSlotId')),
      );
      await tester.pumpAndSettle();

      expect(harness.placedFurnitureProvider.placedFurnitureIds, const {
        _floorRugSlotId: 'rectangular_rug',
      });
      expect(find.byType(CatalogPage), findsNothing);
    });

    for (final replacement in const [
      (from: _roundRug, to: _rectangularRug),
      (from: _rectangularRug, to: _roundRug),
    ]) {
      testWidgets(
        '${replacement.from.id}から${replacement.to.id}へ上書きし購入状態を維持する',
        (tester) async {
          final harness = await _pumpCatalog(
            tester,
            openAsRoute: true,
            furnitures: [replacement.from, replacement.to],
            purchasedFurnitureIds: {replacement.from.id, replacement.to.id},
            placedFurnitureIds: {_floorRugSlotId: replacement.from.id},
          );

          await tester.tap(_furnitureTile(replacement.to.name));
          await tester.pumpAndSettle();
          await tester.tap(
            find.byKey(const ValueKey('placementOption-$_floorRugSlotId')),
          );
          await tester.pumpAndSettle();
          await tester.tap(find.text('置き換える'));
          await tester.pumpAndSettle();

          expect(harness.placedFurnitureProvider.placedFurnitureIds, {
            _floorRugSlotId: replacement.to.id,
          });
          expect(
            harness.catalogProvider.isPurchased(replacement.from.id),
            isTrue,
          );
          expect(
            harness.catalogProvider.isPurchased(replacement.to.id),
            isTrue,
          );
          expect(find.byType(CatalogPage), findsNothing);
        },
      );
    }
  });

  group('吊り飾り家具', () {
    for (final furniture in const [_windChime, _teruTeruBozu, _moonMobile]) {
      testWidgets('${furniture.name}を30滴で購入して吊り飾りだけへ配置できる', (tester) async {
        final harness = await _pumpCatalog(
          tester,
          openAsRoute: true,
          blockPurchase: false,
          initialShizuku: 30,
          purchasedFurnitureIds: const {},
          furnitures: [furniture],
        );

        await _buyFurniture(tester, furniture.name);

        expect(harness.catalogProvider.isPurchased(furniture.id), isTrue);
        expect(harness.shizukuProvider.currentShizuku, 0);
        expect(
          find.byKey(
            const ValueKey('placementOption-$_windowHangingDecorSlotId'),
          ),
          findsOneWidget,
        );
        expect(
          find.byKey(
            const ValueKey('placementOption-$_windowShelfDecorSlotId'),
          ),
          findsNothing,
        );
        expect(
          find.byKey(const ValueKey('placementOption-$_deskSurfaceLeftSlotId')),
          findsNothing,
        );
        expect(
          find.byKey(
            const ValueKey('placementOption-$_deskSurfaceRightSlotId'),
          ),
          findsNothing,
        );

        await tester.tap(
          find.byKey(
            const ValueKey('placementOption-$_windowHangingDecorSlotId'),
          ),
        );
        await tester.pumpAndSettle();

        expect(harness.placedFurnitureProvider.placedFurnitureIds, {
          _windowHangingDecorSlotId: furniture.id,
        });
        expect(find.byType(CatalogPage), findsNothing);
      });
    }

    testWidgets('occupiedな吊り飾りは別家具で上書きし追い出した家具も購入済みを維持する', (tester) async {
      final harness = await _pumpCatalog(
        tester,
        openAsRoute: true,
        furnitures: const [_windChime, _moonMobile],
        purchasedFurnitureIds: const {'wind_chime', 'moon_mobile'},
        placedFurnitureIds: const {_windowHangingDecorSlotId: 'wind_chime'},
      );

      await tester.tap(_furnitureTile(_moonMobile.name));
      await tester.pumpAndSettle();
      await tester.tap(
        find.byKey(
          const ValueKey('placementOption-$_windowHangingDecorSlotId'),
        ),
      );
      await tester.pumpAndSettle();
      await tester.tap(find.text('置き換える'));
      await tester.pumpAndSettle();

      expect(harness.placedFurnitureProvider.placedFurnitureIds, const {
        _windowHangingDecorSlotId: 'moon_mobile',
      });
      expect(harness.catalogProvider.isPurchased('wind_chime'), isTrue);
      expect(harness.catalogProvider.isPurchased('moon_mobile'), isTrue);
      expect(find.byType(CatalogPage), findsNothing);
    });
  });

  group('窓辺A家具', () {
    for (final furniture in const [
      _smallHouseplant,
      _woodenBirdFigure,
      _smallGlassOrnament,
    ]) {
      testWidgets('${furniture.name}を30滴で購入して窓辺Aだけへ配置できる', (tester) async {
        final harness = await _pumpCatalog(
          tester,
          openAsRoute: true,
          blockPurchase: false,
          initialShizuku: 30,
          purchasedFurnitureIds: const {},
          furnitures: [furniture],
        );

        await _buyFurniture(tester, furniture.name);

        expect(harness.catalogProvider.isPurchased(furniture.id), isTrue);
        expect(harness.shizukuProvider.currentShizuku, 0);
        expect(
          find.byKey(
            const ValueKey('placementOption-$_windowShelfDecorSlotId'),
          ),
          findsOneWidget,
        );
        expect(
          find.byKey(const ValueKey('placementOption-$_deskSurfaceLeftSlotId')),
          findsNothing,
        );
        expect(
          find.byKey(
            const ValueKey('placementOption-$_deskSurfaceRightSlotId'),
          ),
          findsNothing,
        );

        await tester.tap(
          find.byKey(
            const ValueKey('placementOption-$_windowShelfDecorSlotId'),
          ),
        );
        await tester.pumpAndSettle();

        expect(harness.placedFurnitureProvider.placedFurnitureIds, {
          _windowShelfDecorSlotId: furniture.id,
        });
        expect(find.byType(CatalogPage), findsNothing);
      });
    }

    testWidgets('occupiedな窓辺Aは別家具で上書きし追い出した家具も購入済みを維持する', (tester) async {
      final harness = await _pumpCatalog(
        tester,
        openAsRoute: true,
        furnitures: const [_smallHouseplant, _woodenBirdFigure],
        purchasedFurnitureIds: const {'small_houseplant', 'wooden_bird_figure'},
        placedFurnitureIds: const {_windowShelfDecorSlotId: 'small_houseplant'},
      );

      await tester.tap(_furnitureTile(_woodenBirdFigure.name));
      await tester.pumpAndSettle();
      await tester.tap(
        find.byKey(const ValueKey('placementOption-$_windowShelfDecorSlotId')),
      );
      await tester.pumpAndSettle();
      await tester.tap(find.text('置き換える'));
      await tester.pumpAndSettle();

      expect(harness.placedFurnitureProvider.placedFurnitureIds, const {
        _windowShelfDecorSlotId: 'wooden_bird_figure',
      });
      expect(harness.catalogProvider.isPurchased('small_houseplant'), isTrue);
      expect(harness.catalogProvider.isPurchased('wooden_bird_figure'), isTrue);
      expect(find.byType(CatalogPage), findsNothing);
    });
  });

  testWidgets('Providerロード中は進捗表示しロード後に家具一覧へ切り替わる', (tester) async {
    final harness = await _pumpCatalog(tester, loadCatalogProvider: false);

    expect(find.byType(CircularProgressIndicator), findsOneWidget);

    await harness.catalogProvider.load();
    await tester.pumpAndSettle();

    expect(find.byType(CircularProgressIndicator), findsNothing);
    expect(_catalogFurnitureRows, findsNWidgets(3));
  });

  group('CatalogPageの公開家具フィルタ', () {
    testWidgets('initialAvailableがtrueの家具だけを表示する', (tester) async {
      await _pumpCatalog(
        tester,
        furnitures: const [_furnitureA, _hiddenFurniture],
        purchasedFurnitureIds: const {},
      );

      expect(find.text(_furnitureA.name), findsOneWidget);
      expect(find.text(_hiddenFurniture.name), findsNothing);
      expect(_catalogFurnitureRows, findsOneWidget);
    });

    testWidgets('非公開家具の旧購入・旧配置データがあっても公開家具を操作できる', (tester) async {
      await _pumpCatalog(
        tester,
        furnitures: const [_furnitureA, _hiddenFurniture],
        purchasedFurnitureIds: const {'hidden_furniture'},
        placedFurnitureIds: const {'legacy_slot': 'hidden_furniture'},
      );

      expect(find.text(_hiddenFurniture.name), findsNothing);
      expect(find.text(_furnitureA.name), findsOneWidget);
      expect(tester.takeException(), isNull);

      await tester.tap(_furnitureTile(_furnitureA.name));
      await tester.pumpAndSettle();
      expect(find.text('30滴で迎えますか？'), findsOneWidget);
    });
  });

  group('CatalogPageの家具目録ビジュアル', () {
    testWidgets('tutorial初回導線ではガイドDialogとCTAを表示する', (tester) async {
      final harness = await _pumpCatalog(
        tester,
        showTutorialGuide: true,
        purchasedFurnitureIds: const {},
      );

      expect(
        find.byKey(const ValueKey('catalogTutorialGuideDialog')),
        findsOneWidget,
      );
      expect(find.text('気に入った家具を、ひとつ迎えてみましょう。'), findsOneWidget);
      expect(find.text('家具を見る'), findsOneWidget);
      expect(harness.shizukuProvider.currentShizuku, 100);
      expect(harness.catalogProvider.purchasedFurnitureIds, isEmpty);
      expect(find.text('30滴で迎えますか？'), findsNothing);

      await tester.tap(
        find.byKey(const ValueKey('catalogTutorialGuideContinue')),
      );
      await tester.pumpAndSettle();

      expect(
        find.byKey(const ValueKey('catalogTutorialGuideDialog')),
        findsNothing,
      );
      expect(
        find.byKey(const ValueKey('catalogFurnitureList')),
        findsOneWidget,
      );
      expect(
        find.descendant(
          of: find.byKey(const ValueKey('catalogPaper')),
          matching: find.text('気に入った家具を、ひとつ迎えてみましょう。'),
        ),
        findsNothing,
      );

      await tester.tap(_furnitureTile('家具A'));
      await tester.pumpAndSettle();
      expect(find.text('30滴で迎えますか？'), findsOneWidget);
    });

    testWidgets('通常表示ではtutorialガイドDialogを表示しない', (tester) async {
      await _pumpCatalog(tester);

      expect(find.text('気に入った家具を、ひとつ迎えてみましょう。'), findsNothing);
      expect(
        find.byKey(const ValueKey('catalogTutorialGuideDialog')),
        findsNothing,
      );
    });

    testWidgets('CTAで閉じた後のrebuildとProvider通知でDialogを再表示しない', (tester) async {
      final harness = await _pumpCatalog(tester, showTutorialGuide: true);
      await tester.tap(
        find.byKey(const ValueKey('catalogTutorialGuideContinue')),
      );
      await tester.pumpAndSettle();

      tester.view.physicalSize = const Size(390, 700);
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);
      await tester.pump();
      await harness.placedFurnitureProvider.place(
        slotId: 'test_slot',
        furnitureId: 'furniture_c',
        isPurchased: true,
        allowedSlotIds: const ['test_slot'],
      );
      await tester.pump();

      expect(
        find.byKey(const ValueKey('catalogTutorialGuideDialog')),
        findsNothing,
      );
    });

    testWidgets('barrierで閉じてもCatalogを維持してDialogを再表示しない', (tester) async {
      final harness = await _pumpCatalog(tester, showTutorialGuide: true);

      await tester.tapAt(const Offset(4, 4));
      await tester.pumpAndSettle();
      expect(find.byType(CatalogPage), findsOneWidget);
      expect(
        find.byKey(const ValueKey('catalogTutorialGuideDialog')),
        findsNothing,
      );

      await harness.placedFurnitureProvider.place(
        slotId: 'test_slot',
        furnitureId: 'furniture_c',
        isPurchased: true,
        allowedSlotIds: const ['test_slot'],
      );
      await tester.pump();
      expect(
        find.byKey(const ValueKey('catalogTutorialGuideDialog')),
        findsNothing,
      );
    });

    testWidgets('320px・390px・PC幅でtutorial Dialogがoverflowしない', (tester) async {
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);

      for (final size in const [
        Size(320, 640),
        Size(390, 700),
        Size(1200, 800),
      ]) {
        tester.view.physicalSize = size;
        await _pumpCatalog(tester, showTutorialGuide: true);

        expect(
          find.byKey(const ValueKey('catalogTutorialGuideDialog')),
          findsOneWidget,
        );
        final dialog = tester.widget<AlertDialog>(
          find.byKey(const ValueKey('catalogTutorialGuideDialog')),
        );
        expect(dialog.constraints?.maxWidth, 360);
        expect(tester.takeException(), isNull);
      }
    });

    testWidgets('背景と紙面と目録ヘッダーを表示する', (tester) async {
      await _pumpCatalog(tester);

      final scaffold = tester.widget<Scaffold>(find.byType(Scaffold));
      final appBar = tester.widget<AppBar>(find.byType(AppBar));
      final paper = tester.widget<Container>(
        find.byKey(const ValueKey('catalogPaper')),
      );
      final decoration = paper.decoration! as BoxDecoration;

      expect(scaffold.backgroundColor, const Color(0xFFE5DDD0));
      expect(appBar.backgroundColor, const Color(0xFFE5DDD0));
      expect(appBar.elevation, 0);
      expect(appBar.scrolledUnderElevation, 0);
      expect(appBar.surfaceTintColor, Colors.transparent);
      expect(decoration.color, const Color(0xFFFFFAEC));
      expect(decoration.borderRadius, BorderRadius.circular(4));
      expect(decoration.boxShadow, isNotEmpty);
      expect(find.byKey(const ValueKey('catalogPaperTitle')), findsOneWidget);
      expect(find.text('家具目録'), findsNWidgets(2));
      expect(
        find.byKey(const ValueKey('catalogShizukuBalance')),
        findsOneWidget,
      );
      expect(find.text('所持雫 100滴'), findsOneWidget);
    });

    testWidgets('正式3家具を目録番号と安定した行Keyで表示する', (tester) async {
      await _pumpCatalog(
        tester,
        furnitures: const [_woodenMug, _inkBottle, _woodenFoxFigure],
        purchasedFurnitureIds: const {},
      );

      for (var index = 0; index < 3; index++) {
        final furniture = [_woodenMug, _inkBottle, _woodenFoxFigure][index];
        expect(
          find.byKey(ValueKey('catalogFurnitureRow-${furniture.id}')),
          findsOneWidget,
        );
        expect(find.text('No.0${index + 1}'), findsOneWidget);
      }
    });

    testWidgets('未購入・購入済み未配置・配置済みを文字で判別できる', (tester) async {
      await _pumpCatalog(
        tester,
        furnitures: const [_furnitureA, _furnitureB, _furnitureC],
        purchasedFurnitureIds: const {'furniture_b', 'furniture_c'},
        placedFurnitureIds: const {'test_slot': 'furniture_c'},
      );

      expect(find.text('30滴で迎える'), findsOneWidget);
      expect(find.text('配置する'), findsOneWidget);
      expect(find.text('配置を変える'), findsOneWidget);
    });

    testWidgets('390x700で紙面と家具行が横overflowしない', (tester) async {
      tester.view.physicalSize = const Size(390, 700);
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);

      await _pumpCatalog(
        tester,
        furnitures: const [_woodenMug, _inkBottle, _woodenFoxFigure],
        purchasedFurnitureIds: const {'ink_bottle'},
      );

      expect(find.byKey(const ValueKey('catalogPaper')), findsOneWidget);
      expect(_catalogFurnitureRows, findsNWidgets(3));
      expect(tester.takeException(), isNull);
    });

    testWidgets('PC幅でも紙面は640pxを超えない', (tester) async {
      tester.view.physicalSize = const Size(1200, 800);
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);

      await _pumpCatalog(tester);

      expect(
        tester.getSize(find.byKey(const ValueKey('catalogPaper'))).width,
        lessThanOrEqualTo(640),
      );
      expect(tester.takeException(), isNull);
    });

    testWidgets('公開家具が増えても目録内を縦スクロールできる', (tester) async {
      final furnitures = List.generate(
        10,
        (index) => Furniture(
          id: 'scroll_furniture_$index',
          name: '家具$index',
          price: 30,
          size: 'small',
          slotIds: const ['test_slot'],
          imagePath: 'unused.png',
          initialAvailable: true,
        ),
      );
      await _pumpCatalog(
        tester,
        furnitures: furnitures,
        purchasedFurnitureIds: const {},
      );

      final list = find.byKey(const ValueKey('catalogFurnitureList'));
      expect(list, findsOneWidget);
      await tester.scrollUntilVisible(
        find.text('家具9'),
        250,
        scrollable: find.descendant(
          of: list,
          matching: find.byType(Scrollable),
        ),
      );
      expect(find.text('家具9'), findsOneWidget);
      expect(tester.takeException(), isNull);
    });
  });

  group('CatalogPageの家具画像プレビュー', () {
    for (final furniture in [_woodenMug, _inkBottle, _woodenFoxFigure]) {
      testWidgets('${furniture.id}はFurniture.imagePathの画像を表示する', (
        tester,
      ) async {
        await _pumpCatalog(
          tester,
          furnitures: [furniture],
          purchasedFurnitureIds: const {},
        );

        final preview = tester.widget<SizedBox>(
          find.byKey(ValueKey('catalogFurniturePreview-${furniture.id}')),
        );
        final image = tester.widget<Image>(
          find.byKey(ValueKey('catalogFurnitureImage-${furniture.id}')),
        );
        expect(preview.width, 64);
        expect(preview.height, 64);
        expect(image.fit, BoxFit.contain);
        expect(
          (image.image as AssetImage).assetName,
          'assets/images/${furniture.imagePath}',
        );
      });
    }

    testWidgets('画像欠落でも家具名と購入操作を維持する', (tester) async {
      await _pumpCatalog(
        tester,
        blockPurchase: false,
        furnitures: const [_missingImageFurniture],
        purchasedFurnitureIds: const {},
      );
      await tester.pump();

      expect(find.text(_missingImageFurniture.name), findsOneWidget);
      expect(tester.takeException(), isNull);

      await tester.tap(_furnitureTile(_missingImageFurniture.name));
      await tester.pumpAndSettle();
      expect(find.byType(AlertDialog), findsOneWidget);
      expect(find.byType(FilledButton), findsOneWidget);
    });

    testWidgets('画像欠落でも購入済み家具の配置場所を選択できる', (tester) async {
      await _pumpCatalog(
        tester,
        furnitures: const [_missingImageFurniture],
        purchasedFurnitureIds: const {'missing_image'},
      );
      await tester.pump();

      expect(find.text(_missingImageFurniture.name), findsOneWidget);
      expect(tester.takeException(), isNull);

      await tester.tap(_furnitureTile(_missingImageFurniture.name));
      await tester.pumpAndSettle();
      expect(find.byType(AlertDialog), findsOneWidget);
      expect(
        find.byKey(const ValueKey('placementOption-test_slot')),
        findsOneWidget,
      );
    });

    testWidgets('プレビュー追加後も所持雫と購入状態を維持する', (tester) async {
      await _pumpCatalog(
        tester,
        furnitures: const [_woodenMug, _inkBottle],
        purchasedFurnitureIds: const {'ink_bottle'},
      );

      expect(_textContainingAscii('100'), findsOneWidget);
      expect(_textContainingAscii('30'), findsOneWidget);
      expect(_purchasedCheckInTile(_inkBottle.name), findsOneWidget);
      expect(_purchasedCheckInTile(_woodenMug.name), findsNothing);
    });
  });

  group('正式3家具のMVP操作', () {
    for (final furniture in [_woodenMug, _inkBottle, _woodenFoxFigure]) {
      testWidgets('${furniture.id}を30雫で購入できる', (tester) async {
        await _pumpCatalog(
          tester,
          blockPurchase: false,
          initialShizuku: 30,
          furnitures: [furniture],
          purchasedFurnitureIds: const {},
        );

        await tester.tap(_furnitureTile(furniture.name));
        await tester.pumpAndSettle();
        await tester.tap(find.text('迎える'));
        await tester.pumpAndSettle();

        expect(find.text('${furniture.name}を迎えました'), findsOneWidget);
        expect(find.text('所持雫 0滴'), findsOneWidget);
        expect(_purchasedCheckInTile(furniture.name), findsOneWidget);
      });
    }

    testWidgets('机上Aで正式家具を交換して旧家具の購入済み状態を維持する', (tester) async {
      final harness = await _pumpCatalog(
        tester,
        furnitures: const [_woodenMug, _inkBottle],
        purchasedFurnitureIds: const {'wooden_mug', 'ink_bottle'},
        placedFurnitureIds: const {_deskSurfaceLeftSlotId: 'wooden_mug'},
      );

      await tester.tap(_furnitureTile(_inkBottle.name));
      await tester.pumpAndSettle();
      await tester.tap(
        find.byKey(
          const ValueKey('placementOption-living_room_desk_surface_left'),
        ),
      );
      await tester.pumpAndSettle();
      await tester.tap(find.text('置き換える'));
      await tester.pumpAndSettle();

      expect(harness.placedFurnitureProvider.placedFurnitureIds, const {
        _deskSurfaceLeftSlotId: 'ink_bottle',
      });
      expect(harness.catalogProvider.isPurchased('wooden_mug'), isTrue);
      expect(harness.catalogProvider.isPurchased('ink_bottle'), isTrue);
      expect(find.byType(CatalogPage), findsNothing);
    });

    testWidgets('机上Aから取り外した購入済み家具を再配置できる', (tester) async {
      final harness = await _pumpCatalog(
        tester,
        furnitures: const [_woodenMug],
        purchasedFurnitureIds: const {'wooden_mug'},
        placedFurnitureIds: const {_deskSurfaceLeftSlotId: 'wooden_mug'},
      );

      await tester.tap(_furnitureTile(_woodenMug.name));
      await tester.pumpAndSettle();
      await tester.tap(find.text('取り外す'));
      await tester.pumpAndSettle();
      expect(harness.placedFurnitureProvider.placedFurnitureIds, isEmpty);
      expect(_purchasedCheckInTile(_woodenMug.name), findsOneWidget);

      await tester.tap(_furnitureTile(_woodenMug.name));
      await tester.pumpAndSettle();
      await tester.tap(
        find.byKey(
          const ValueKey('placementOption-living_room_desk_surface_left'),
        ),
      );
      await tester.pumpAndSettle();
      expect(harness.placedFurnitureProvider.placedFurnitureIds, const {
        _deskSurfaceLeftSlotId: 'wooden_mug',
      });
    });

    testWidgets('正式家具の配置Dialogに机上Aと机上Bを表示する', (tester) async {
      await _pumpCatalog(
        tester,
        furnitures: const [_woodenMug],
        purchasedFurnitureIds: const {'wooden_mug'},
        placedFurnitureIds: const {_deskSurfaceRightSlotId: 'wooden_mug'},
      );

      await tester.tap(_furnitureTile(_woodenMug.name));
      await tester.pumpAndSettle();

      expect(find.text('机（左）に置く'), findsOneWidget);
      expect(find.text('机（右）に置く'), findsOneWidget);
      expect(find.text('現在の配置場所：机（右）'), findsOneWidget);
    });

    testWidgets('配置済み家具を机上Aから机上Bへ移動する', (tester) async {
      final harness = await _pumpCatalog(
        tester,
        furnitures: const [_woodenMug],
        purchasedFurnitureIds: const {'wooden_mug'},
        placedFurnitureIds: const {_deskSurfaceLeftSlotId: 'wooden_mug'},
      );

      await tester.tap(_furnitureTile(_woodenMug.name));
      await tester.pumpAndSettle();
      await tester.tap(
        find.byKey(
          const ValueKey('placementOption-living_room_desk_surface_right'),
        ),
      );
      await tester.pumpAndSettle();

      expect(harness.placedFurnitureProvider.placedFurnitureIds, const {
        _deskSurfaceRightSlotId: 'wooden_mug',
      });
    });

    testWidgets('occupiedな机上Bへ移動してもswapせず旧家具の購入状態を維持する', (tester) async {
      final harness = await _pumpCatalog(
        tester,
        furnitures: const [_woodenMug, _inkBottle],
        purchasedFurnitureIds: const {'wooden_mug', 'ink_bottle'},
        placedFurnitureIds: const {
          _deskSurfaceLeftSlotId: 'wooden_mug',
          _deskSurfaceRightSlotId: 'ink_bottle',
        },
      );

      await tester.tap(_furnitureTile(_woodenMug.name));
      await tester.pumpAndSettle();
      await tester.tap(
        find.byKey(
          const ValueKey('placementOption-living_room_desk_surface_right'),
        ),
      );
      await tester.pumpAndSettle();
      await tester.tap(find.text('置き換える'));
      await tester.pumpAndSettle();

      expect(harness.placedFurnitureProvider.placedFurnitureIds, const {
        _deskSurfaceRightSlotId: 'wooden_mug',
      });
      expect(harness.catalogProvider.isPurchased('wooden_mug'), isTrue);
      expect(harness.catalogProvider.isPurchased('ink_bottle'), isTrue);
      expect(find.byType(CatalogPage), findsNothing);
    });

    testWidgets('320px幅でも正式家具の机上Aと机上Bをoverflowなく表示する', (tester) async {
      tester.view.physicalSize = const Size(320, 640);
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);
      await _pumpCatalog(
        tester,
        furnitures: const [_woodenMug],
        purchasedFurnitureIds: const {'wooden_mug'},
      );

      await tester.tap(_furnitureTile(_woodenMug.name));
      await tester.pumpAndSettle();

      expect(find.text('机（左）に置く'), findsOneWidget);
      expect(find.text('机（右）に置く'), findsOneWidget);
      expect(tester.takeException(), isNull);
    });
  });

  group('CatalogPageの初見UX表示', () {
    testWidgets('未購入家具に価格と迎える導線を表示する', (tester) async {
      await _pumpCatalog(tester);

      expect(find.text('30滴で迎える'), findsNWidgets(2));
      expect(find.text('所持雫 100滴'), findsOneWidget);
      expect(_purchasedCheckInTile('家具A'), findsNothing);
      expect(_purchasedCheckInTile('家具B'), findsNothing);
      expect(_purchasedCheckInTile('家具C'), findsOneWidget);
    });

    testWidgets('未購入家具から迎える確認へ進める', (tester) async {
      await _pumpCatalog(tester);

      await tester.tap(_furnitureTile('家具A'));
      await tester.pumpAndSettle();

      expect(find.text('30滴で迎えますか？'), findsOneWidget);
      expect(find.text('迎える'), findsOneWidget);
    });

    testWidgets('迎えた家具は配置する表示へ切り替わる', (tester) async {
      await _pumpCatalog(tester, blockPurchase: false);

      await tester.tap(_furnitureTile('家具A'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('迎える'));
      await tester.pumpAndSettle();

      expect(find.text('家具Aを迎えました'), findsOneWidget);
      expect(find.text('配置する'), findsNWidgets(2));
      expect(find.text('所持雫 70滴'), findsOneWidget);
      expect(_purchasedCheckInTile('家具A'), findsOneWidget);
    });

    testWidgets('購入済み未配置家具から配置ダイアログへ進める', (tester) async {
      await _pumpCatalog(tester);

      await tester.tap(_furnitureTile('家具C'));
      await tester.pumpAndSettle();

      expect(find.text('配置する'), findsOneWidget);
      expect(find.text('どこに置きますか？'), findsOneWidget);
      expect(find.text('迎えた家具を、部屋に置いてみましょう。'), findsNothing);
      expect(find.text('置く場所を選んでください。'), findsOneWidget);
      expect(find.text('テスト配置場所に置く'), findsOneWidget);
    });

    testWidgets('配置済み家具に配置を変えると表示し配置操作へ進める', (tester) async {
      await _pumpCatalog(
        tester,
        placedFurnitureIds: {'test_slot': 'furniture_c'},
      );

      expect(find.text('配置を変える'), findsOneWidget);
      expect(_purchasedCheckInTile('家具C'), findsOneWidget);
      await tester.tap(_furnitureTile('家具C'));
      await tester.pumpAndSettle();

      expect(find.text('現在の配置場所：テスト配置場所'), findsOneWidget);
      expect(find.text('取り外す'), findsOneWidget);
      expect(
        find.descendant(
          of: find.byKey(const ValueKey('placementOption-test_slot')),
          matching: find.byIcon(Icons.check_circle_outline),
        ),
        findsOneWidget,
      );
    });

    testWidgets('雫未ロード中は所持雫をダッシュ表示にする', (tester) async {
      await _pumpCatalog(tester, loadShizukuProvider: false);

      expect(find.text('所持雫 --'), findsOneWidget);
    });

    testWidgets('雫不足では家具を迎えずエラー表示を維持する', (tester) async {
      await _pumpCatalog(tester, blockPurchase: false, initialShizuku: 20);

      await tester.tap(_furnitureTile('家具A'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('迎える'));
      await tester.pumpAndSettle();

      expect(find.text('雫が足りません'), findsOneWidget);
      expect(find.text('30滴で迎える'), findsNWidgets(2));
      expect(find.text('所持雫 20滴'), findsOneWidget);
    });

    testWidgets('320px幅で長い家具名と状態表示がoverflowしない', (tester) async {
      tester.view.physicalSize = const Size(320, 640);
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);

      await _pumpCatalog(
        tester,
        furnitures: const [_longNameFurniture],
        purchasedFurnitureIds: const {'long_name_furniture'},
      );

      expect(find.text('所持雫 100滴'), findsOneWidget);
      expect(find.text('配置する'), findsOneWidget);
      expect(_purchasedCheckInTile(_longNameFurniture.name), findsOneWidget);
      expect(tester.takeException(), isNull);
    });
  });

  group('購入成功後の配置Dialog自動表示', () {
    testWidgets('購入した家具の配置Dialogだけを自動表示する', (tester) async {
      await _pumpCatalog(
        tester,
        blockPurchase: false,
        purchasedFurnitureIds: const {},
      );

      await _buyFurniture(tester, '家具A');

      expect(find.byType(AlertDialog), findsOneWidget);
      expect(
        find.descendant(
          of: find.byType(AlertDialog),
          matching: find.text('家具A'),
        ),
        findsOneWidget,
      );
      expect(find.text('どこに置きますか？'), findsOneWidget);
      expect(find.text('置く場所を選んでください。'), findsOneWidget);
      expect(find.text('迎えた家具を、部屋に置いてみましょう。'), findsOneWidget);
    });

    testWidgets('購入確認キャンセルでは購入も配置Dialog表示もしない', (tester) async {
      final harness = await _pumpCatalog(
        tester,
        blockPurchase: false,
        purchasedFurnitureIds: const {},
      );

      await tester.tap(_furnitureTile('家具A'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('やめる'));
      await tester.pumpAndSettle();

      expect(harness.catalogProvider.isPurchased('furniture_a'), isFalse);
      expect(find.byType(AlertDialog), findsNothing);
      expect(find.byType(CatalogPage), findsOneWidget);
    });

    testWidgets('購入失敗では配置Dialogを表示せず状態を維持する', (tester) async {
      final harness = await _pumpCatalog(
        tester,
        blockPurchase: false,
        failNextShizukuSave: true,
        purchasedFurnitureIds: const {},
      );

      await _buyFurniture(tester, '家具A');

      expect(find.text('家具を迎えられませんでした'), findsOneWidget);
      expect(find.byType(AlertDialog), findsNothing);
      expect(harness.catalogProvider.isPurchased('furniture_a'), isFalse);
      expect(harness.shizukuProvider.currentShizuku, 100);
    });

    testWidgets('雫不足では配置Dialogを表示しない', (tester) async {
      await _pumpCatalog(
        tester,
        blockPurchase: false,
        initialShizuku: 20,
        purchasedFurnitureIds: const {},
      );

      await _buyFurniture(tester, '家具A');

      expect(find.text('雫が足りません'), findsOneWidget);
      expect(find.byType(AlertDialog), findsNothing);
    });

    testWidgets('自動配置をキャンセルしても購入と雫消費を維持しCatalogに残る', (tester) async {
      final harness = await _pumpCatalog(
        tester,
        blockPurchase: false,
        purchasedFurnitureIds: const {},
      );

      await _buyFurniture(tester, '家具A');
      await tester.tap(find.text('キャンセル'));
      await tester.pumpAndSettle();

      expect(harness.catalogProvider.isPurchased('furniture_a'), isTrue);
      expect(harness.shizukuProvider.currentShizuku, 70);
      expect(harness.placedFurnitureProvider.placedFurnitureIds, isEmpty);
      expect(find.byType(CatalogPage), findsOneWidget);
      expect(find.byType(AlertDialog), findsNothing);
    });

    testWidgets('自動配置キャンセル後も同じ家具を再操作して配置できる', (tester) async {
      final harness = await _pumpCatalog(
        tester,
        blockPurchase: false,
        purchasedFurnitureIds: const {},
      );

      await _buyFurniture(tester, '家具A');
      await tester.tap(find.text('キャンセル'));
      await tester.pumpAndSettle();
      await tester.tap(_furnitureTile('家具A'));
      await tester.pumpAndSettle();
      await tester.tap(find.byKey(const ValueKey('placementOption-test_slot')));
      await tester.pumpAndSettle();

      expect(harness.placedFurnitureProvider.placedFurnitureIds, const {
        'test_slot': 'furniture_a',
      });
      expect(find.byType(CatalogPage), findsNothing);
    });

    testWidgets('購入成功後の自動Dialogから既存配置処理で配置できる', (tester) async {
      final harness = await _pumpCatalog(
        tester,
        blockPurchase: false,
        purchasedFurnitureIds: const {},
      );

      await _buyFurniture(tester, '家具A');
      await tester.tap(find.byKey(const ValueKey('placementOption-test_slot')));
      await tester.pumpAndSettle();

      expect(harness.placedFurnitureProvider.placedFurnitureIds, const {
        'test_slot': 'furniture_a',
      });
      expect(find.byType(CatalogPage), findsNothing);
    });

    for (final showTutorialGuide in [true, false]) {
      testWidgets(
        '${showTutorialGuide ? 'tutorial初回' : '通常'}Catalogでも購入後に自動表示する',
        (tester) async {
          await _pumpCatalog(
            tester,
            showTutorialGuide: showTutorialGuide,
            blockPurchase: false,
            purchasedFurnitureIds: const {},
          );
          if (showTutorialGuide) {
            await tester.tap(
              find.byKey(const ValueKey('catalogTutorialGuideContinue')),
            );
            await tester.pumpAndSettle();
          }

          await _buyFurniture(tester, '家具A');

          expect(find.text('どこに置きますか？'), findsOneWidget);
          expect(find.byType(AlertDialog), findsOneWidget);
        },
      );
    }

    testWidgets('320px幅でも複数slotと長い名前を縦ボタンで表示できる', (tester) async {
      tester.view.physicalSize = const Size(320, 640);
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);
      await _pumpCatalog(
        tester,
        furnitures: const [_multiSlotFurniture],
        purchasedFurnitureIds: const {'multi_slot_furniture'},
      );

      await tester.tap(_furnitureTile('複数配置家具'));
      await tester.pumpAndSettle();

      expect(
        find.byKey(const ValueKey('placementOption-slot_a')),
        findsOneWidget,
      );
      expect(
        find.byKey(const ValueKey('placementOption-long_slot')),
        findsOneWidget,
      );
      expect(find.text('窓辺に置く'), findsOneWidget);
      expect(find.text('とても長い名前の配置場所に置く'), findsOneWidget);
      expect(tester.takeException(), isNull);
    });
  });

  group('CatalogPageの購入排他制御', () {
    testWidgets('購入中は同じ未購入家具を再操作できない', (tester) async {
      final harness = await _pumpCatalog(tester);

      await _startPurchase(tester, '家具A');
      await tester.tap(_furnitureTile('家具A'));
      await tester.pump();

      expect(find.text('30滴で迎えますか？'), findsNothing);
      expect(harness.shizukuRepository.saveCallCount, 1);
      expect(harness.catalogRepository.saveCallCount, 0);

      await harness.finishPurchase(tester);
    });

    testWidgets('購入中は別の未購入家具を操作できない', (tester) async {
      final harness = await _pumpCatalog(tester);

      await _startPurchase(tester, '家具A');
      await tester.tap(_furnitureTile('家具B'));
      await tester.pump();

      expect(find.text('30滴で迎えますか？'), findsNothing);
      expect(harness.shizukuRepository.saveCallCount, 1);
      expect(harness.catalogRepository.saveCallCount, 0);

      await harness.finishPurchase(tester);
    });

    testWidgets('購入中の家具だけにインジケーターを表示する', (tester) async {
      final harness = await _pumpCatalog(tester);

      await _startPurchase(tester, '家具A');

      expect(_progressInTile('家具A'), findsOneWidget);
      expect(_progressInTile('家具B'), findsNothing);
      expect(_progressInTile('家具C'), findsNothing);

      await harness.finishPurchase(tester);
    });

    testWidgets('別家具の購入中でも購入済み家具の配置操作ができる', (tester) async {
      final harness = await _pumpCatalog(tester);

      await _startPurchase(tester, '家具A');
      await tester.tap(_furnitureTile('家具C'));
      await tester.pump();
      await tester.pump();

      expect(find.text('どこに置きますか？'), findsOneWidget);
      expect(find.text('テスト配置場所に置く'), findsOneWidget);

      await tester.tap(find.text('キャンセル'));
      await tester.pump();
      await harness.finishPurchase(tester);
    });
  });
  group('CatalogPage placement result', () {
    testWidgets('successful placement returns true and closes Catalog', (
      tester,
    ) async {
      final harness = await _pumpCatalog(
        tester,
        openAsRoute: true,
        purchasedFurnitureIds: const {'furniture_c'},
      );

      await tester.tap(_furnitureTile(_furnitureC.name));
      await tester.pumpAndSettle();
      await tester.tap(find.byKey(const ValueKey('placementOption-test_slot')));
      await tester.pumpAndSettle();

      expect(find.byType(CatalogPage), findsNothing);
      expect(find.text('catalogResult:true'), findsOneWidget);
      expect(harness.placedFurnitureProvider.placedFurnitureIds, const {
        'test_slot': 'furniture_c',
      });
    });

    testWidgets('placement cancellation leaves Catalog open', (tester) async {
      await _pumpCatalog(
        tester,
        openAsRoute: true,
        purchasedFurnitureIds: const {'furniture_c'},
      );

      await tester.tap(_furnitureTile(_furnitureC.name));
      await tester.pumpAndSettle();
      await tester.tap(find.text('キャンセル'));
      await tester.pumpAndSettle();

      expect(find.byType(CatalogPage), findsOneWidget);
      expect(find.text('catalogResult:null'), findsNothing);
    });

    testWidgets('new purchase placement returns directly from Catalog', (
      tester,
    ) async {
      final harness = await _pumpCatalog(
        tester,
        openAsRoute: true,
        blockPurchase: false,
        purchasedFurnitureIds: const {},
      );

      await _buyFurniture(tester, _furnitureA.name);
      await tester.tap(find.byKey(const ValueKey('placementOption-test_slot')));
      await tester.pumpAndSettle();

      expect(find.byType(CatalogPage), findsNothing);
      expect(find.text('catalogResult:true'), findsOneWidget);
      expect(harness.catalogProvider.isPurchased('furniture_a'), isTrue);
      expect(harness.shizukuProvider.currentShizuku, 70);
    });
  });
}

Finder _progressInTile(String furnitureName) {
  return find.descendant(
    of: _furnitureTile(furnitureName),
    matching: find.byType(CircularProgressIndicator),
  );
}

Finder _textContainingAscii(String value) {
  return find.byWidgetPredicate(
    (widget) => widget is Text && (widget.data?.contains(value) ?? false),
  );
}

Finder _furnitureTile(String furnitureName) {
  return find.ancestor(
    of: find.text(furnitureName),
    matching: _catalogFurnitureRows,
  );
}

final _catalogFurnitureRows = find.byWidgetPredicate(
  (widget) =>
      widget.key is ValueKey<String> &&
      (widget.key! as ValueKey<String>).value.startsWith(
        'catalogFurnitureRow-',
      ),
);

Future<void> _startPurchase(WidgetTester tester, String furnitureName) async {
  await tester.tap(_furnitureTile(furnitureName));
  await tester.pumpAndSettle();
  await tester.tap(find.text('迎える'));
  await tester.pump();
  await tester.pump(const Duration(seconds: 1));
}

Future<void> _buyFurniture(WidgetTester tester, String furnitureName) async {
  await tester.tap(_furnitureTile(furnitureName));
  await tester.pumpAndSettle();
  await tester.tap(find.text('迎える'));
  await tester.pumpAndSettle();
}

Future<_CatalogHarness> _pumpCatalog(
  WidgetTester tester, {
  bool openAsRoute = false,
  bool showTutorialGuide = false,
  bool blockPurchase = true,
  bool failNextShizukuSave = false,
  bool loadShizukuProvider = true,
  bool loadCatalogProvider = true,
  PlacementSlotRepository? placementSlotRepository,
  double textScale = 1,
  int initialShizuku = 100,
  Map<String, String> placedFurnitureIds = const {},
  Set<String> purchasedFurnitureIds = const {'furniture_c'},
  List<Furniture> furnitures = const [_furnitureA, _furnitureB, _furnitureC],
}) async {
  final shizukuRepository = _BlockingShizukuRepository(
    blockSave: blockPurchase,
    initialShizuku: initialShizuku,
  )..failNextSave = failNextShizukuSave;
  addTearDown(shizukuRepository.completeSave);
  final catalogRepository = _FakePurchasedFurnitureRepository(
    purchasedFurnitureIds,
  );
  final shizukuProvider = ShizukuProvider(shizukuRepository);
  final catalogProvider = CatalogProvider(catalogRepository);
  final placedFurnitureProvider = PlacedFurnitureProvider(
    _FakePlacedFurnitureRepository(placedFurnitureIds),
  );

  await Future.wait([
    if (loadShizukuProvider) shizukuProvider.load(),
    if (loadCatalogProvider) catalogProvider.load(),
    placedFurnitureProvider.load(),
  ]);

  final catalogPage = CatalogPage(
    showTutorialGuide: showTutorialGuide,
    furnitureRepository: _FakeFurnitureRepository(furnitures),
    placementSlotRepository:
        placementSlotRepository ?? _FakePlacementSlotRepository(),
  );

  await tester.pumpWidget(
    MultiProvider(
      providers: [
        ChangeNotifierProvider.value(value: shizukuProvider),
        ChangeNotifierProvider.value(value: catalogProvider),
        ChangeNotifierProvider.value(value: placedFurnitureProvider),
      ],
      child: MaterialApp(
        builder: (context, child) => MediaQuery(
          data: MediaQuery.of(
            context,
          ).copyWith(textScaler: TextScaler.linear(textScale)),
          child: child!,
        ),
        home: openAsRoute
            ? _CatalogRouteHost(catalogPage: catalogPage)
            : catalogPage,
      ),
    ),
  );
  if (loadShizukuProvider && loadCatalogProvider) {
    await tester.pumpAndSettle();
  } else {
    await tester.pump();
  }
  if (openAsRoute) {
    await tester.tap(find.byKey(const ValueKey('openCatalog')));
    await tester.pumpAndSettle();
  }

  return _CatalogHarness(
    shizukuRepository: shizukuRepository,
    catalogRepository: catalogRepository,
    catalogProvider: catalogProvider,
    shizukuProvider: shizukuProvider,
    placedFurnitureProvider: placedFurnitureProvider,
  );
}

class _CatalogRouteHost extends StatefulWidget {
  const _CatalogRouteHost({required this.catalogPage});

  final CatalogPage catalogPage;

  @override
  State<_CatalogRouteHost> createState() => _CatalogRouteHostState();
}

class _CatalogRouteHostState extends State<_CatalogRouteHost> {
  bool? _catalogResult;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Column(
        children: [
          Text('catalogResult:$_catalogResult'),
          FilledButton(
            key: const ValueKey('openCatalog'),
            onPressed: () async {
              final result = await Navigator.of(context).push<bool>(
                MaterialPageRoute<bool>(builder: (_) => widget.catalogPage),
              );
              if (mounted) {
                setState(() => _catalogResult = result);
              }
            },
            child: const Text('open'),
          ),
        ],
      ),
    );
  }
}

class _CatalogHarness {
  const _CatalogHarness({
    required this.shizukuRepository,
    required this.catalogRepository,
    required this.catalogProvider,
    required this.shizukuProvider,
    required this.placedFurnitureProvider,
  });

  final _BlockingShizukuRepository shizukuRepository;
  final _FakePurchasedFurnitureRepository catalogRepository;
  final CatalogProvider catalogProvider;
  final ShizukuProvider shizukuProvider;
  final PlacedFurnitureProvider placedFurnitureProvider;

  Future<void> finishPurchase(WidgetTester tester) async {
    shizukuRepository.completeSave();
    await tester.pumpAndSettle();
  }
}

class _FakeFurnitureRepository extends FurnitureRepository {
  _FakeFurnitureRepository(this.furnitures);

  final List<Furniture> furnitures;

  @override
  Future<List<Furniture>> getAll() async => furnitures;
}

class _FakePlacementSlotRepository extends PlacementSlotRepository {
  @override
  Future<PlacementSlot?> getById(String slotId) async => PlacementSlot(
    id: slotId,
    name: switch (slotId) {
      _deskSurfaceLeftSlotId => '机（左）',
      _deskSurfaceRightSlotId => '机（右）',
      _windowShelfDecorSlotId => '窓際（棚）',
      _windowHangingDecorSlotId => '窓際（吊り飾り）',
      _floorRugSlotId => 'ラグ',
      _windowVaseSlotId => '窓際（一輪挿し）',
      'slot_a' => '窓辺',
      'long_slot' => 'とても長い名前の配置場所',
      _ => 'テスト配置場所',
    },
    type: 'surface',
    maxItems: 1,
  );
}

class _FailOncePlacementSlotRepository extends _FakePlacementSlotRepository {
  final Set<String> _requested = {};

  @override
  Future<PlacementSlot?> getById(String slotId) async {
    if (_requested.add(slotId)) throw StateError('optional names unavailable');
    return super.getById(slotId);
  }
}

class _DelayedPlacementSlotRepository extends _FakePlacementSlotRepository {
  final ready = Completer<void>();
  final Map<String, int> calls = {};

  @override
  Future<PlacementSlot?> getById(String slotId) async {
    calls.update(slotId, (value) => value + 1, ifAbsent: () => 1);
    await ready.future;
    return super.getById(slotId);
  }
}

class _FakePurchasedFurnitureRepository extends PurchasedFurnitureRepository {
  _FakePurchasedFurnitureRepository(this.purchasedFurnitureIds);

  final Set<String> purchasedFurnitureIds;
  int saveCallCount = 0;

  @override
  Future<Set<String>> loadPurchasedFurnitureIds() async =>
      Set.of(purchasedFurnitureIds);

  @override
  Future<void> savePurchasedFurnitureIds(Set<String> furnitureIds) async {
    saveCallCount++;
  }
}

class _BlockingShizukuRepository extends ShizukuRepository {
  _BlockingShizukuRepository({
    required this.blockSave,
    required this.initialShizuku,
  });

  final bool blockSave;
  final int initialShizuku;
  final Completer<void> _saveCompleter = Completer<void>();
  int saveCallCount = 0;
  bool failNextSave = false;

  @override
  Future<ShizukuState> loadState() async =>
      ShizukuState(currentShizuku: initialShizuku, rewardedLetterIds: {});

  @override
  Future<void> saveState(ShizukuState state) {
    saveCallCount++;
    if (failNextSave) {
      failNextSave = false;
      throw StateError('save failed');
    }
    return blockSave ? _saveCompleter.future : Future.value();
  }

  void completeSave() {
    if (!_saveCompleter.isCompleted) {
      _saveCompleter.complete();
    }
  }
}

class _FakePlacedFurnitureRepository extends PlacedFurnitureRepository {
  _FakePlacedFurnitureRepository(this.placedFurnitureIds);

  final Map<String, String> placedFurnitureIds;

  @override
  Future<Map<String, String>> loadPlacedFurnitureIds() async =>
      placedFurnitureIds;

  @override
  Future<void> savePlacedFurnitureIds(
    Map<String, String> placedFurnitureIds,
  ) async {}
}

Finder _purchasedCheckInTile(String furnitureName) {
  return find.descendant(
    of: _furnitureTile(furnitureName),
    matching: find.byIcon(Icons.check_circle_outline),
  );
}
