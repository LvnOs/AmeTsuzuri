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
  slotIds: ['test_slot'],
  imagePath: 'furniture/desk/wooden_mug.png',
  initialAvailable: true,
);
const _inkBottle = Furniture(
  id: 'ink_bottle',
  name: 'インク瓶',
  price: 30,
  size: 'small',
  slotIds: ['test_slot'],
  imagePath: 'furniture/desk/ink_bottle.png',
  initialAvailable: true,
);
const _woodenFoxFigure = Furniture(
  id: 'wooden_fox_figure',
  name: '木彫りのキツネ',
  price: 30,
  size: 'small',
  slotIds: ['test_slot'],
  imagePath: 'furniture/desk/wooden_fox_figure.png',
  initialAvailable: true,
);
const _missingImageFurniture = Furniture(
  id: 'missing_image',
  name: '画像のない家具',
  price: 30,
  size: 'small',
  slotIds: ['test_slot'],
  imagePath: 'furniture/desk/missing.png',
  initialAvailable: true,
);

void main() {
  group('CatalogPageの家具画像プレビュー', () {
    for (final furniture in [
      _woodenMug,
      _inkBottle,
      _woodenFoxFigure,
    ]) {
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
        find.descendant(
          of: find.byType(AlertDialog),
          matching: find.byType(ListTile),
        ),
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
      expect(find.text('配置可能な場所'), findsOneWidget);
    });

    testWidgets('配置済み家具に配置を変えると表示し配置操作へ進める', (tester) async {
      await _pumpCatalog(tester, placedFurnitureIds: {'test_slot': 'furniture_c'});

      expect(find.text('配置を変える'), findsOneWidget);
      expect(_purchasedCheckInTile('家具C'), findsOneWidget);
      await tester.tap(_furnitureTile('家具C'));
      await tester.pumpAndSettle();

      expect(find.text('現在の配置場所：テスト配置場所'), findsOneWidget);
      expect(find.text('取り外す'), findsOneWidget);
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

      expect(find.text('配置可能な場所'), findsOneWidget);
      expect(find.text('テスト配置場所'), findsOneWidget);

      await tester.tap(find.text('キャンセル'));
      await tester.pump();
      await harness.finishPurchase(tester);
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
  return find.widgetWithText(ListTile, furnitureName);
}

Future<void> _startPurchase(WidgetTester tester, String furnitureName) async {
  await tester.tap(_furnitureTile(furnitureName));
  await tester.pumpAndSettle();
  await tester.tap(find.text('迎える'));
  await tester.pump();
  await tester.pump(const Duration(seconds: 1));
}

Future<_CatalogHarness> _pumpCatalog(
  WidgetTester tester, {
  bool blockPurchase = true,
  bool loadShizukuProvider = true,
  int initialShizuku = 100,
  Map<String, String> placedFurnitureIds = const {},
  Set<String> purchasedFurnitureIds = const {'furniture_c'},
  List<Furniture> furnitures = const [_furnitureA, _furnitureB, _furnitureC],
}) async {
  final shizukuRepository = _BlockingShizukuRepository(
    blockSave: blockPurchase,
    initialShizuku: initialShizuku,
  );
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
    catalogProvider.load(),
    placedFurnitureProvider.load(),
  ]);

  await tester.pumpWidget(
    MultiProvider(
      providers: [
        ChangeNotifierProvider.value(value: shizukuProvider),
        ChangeNotifierProvider.value(value: catalogProvider),
        ChangeNotifierProvider.value(value: placedFurnitureProvider),
      ],
      child: MaterialApp(
        home: CatalogPage(
          furnitureRepository: _FakeFurnitureRepository(furnitures),
          placementSlotRepository: _FakePlacementSlotRepository(),
        ),
      ),
    ),
  );
  if (loadShizukuProvider) {
    await tester.pumpAndSettle();
  } else {
    await tester.pump();
  }

  return _CatalogHarness(
    shizukuRepository: shizukuRepository,
    catalogRepository: catalogRepository,
  );
}

class _CatalogHarness {
  const _CatalogHarness({
    required this.shizukuRepository,
    required this.catalogRepository,
  });

  final _BlockingShizukuRepository shizukuRepository;
  final _FakePurchasedFurnitureRepository catalogRepository;

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
  Future<PlacementSlot?> getById(String slotId) async => const PlacementSlot(
    id: 'test_slot',
    name: 'テスト配置場所',
    type: 'surface',
    maxItems: 1,
  );
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

  @override
  Future<ShizukuState> loadState() async =>
      ShizukuState(currentShizuku: initialShizuku, rewardedLetterIds: {});

  @override
  Future<void> saveState(ShizukuState state) {
    saveCallCount++;
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
}

Finder _purchasedCheckInTile(String furnitureName) {
  return find.descendant(
    of: _furnitureTile(furnitureName),
    matching: find.byIcon(Icons.check_circle_outline),
  );
}
