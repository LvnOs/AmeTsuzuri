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

void main() {
  group('CatalogPageの購入排他制御', () {
    testWidgets('購入中は同じ未購入家具を再操作できない', (tester) async {
      final harness = await _pumpCatalog(tester);

      await _startPurchase(tester, '家具A');
      await tester.tap(_furnitureTile('家具A'));
      await tester.pump();

      expect(find.text('30滴で購入しますか？'), findsNothing);
      expect(harness.shizukuRepository.saveCallCount, 1);
      expect(harness.catalogRepository.saveCallCount, 0);

      await harness.finishPurchase(tester);
    });

    testWidgets('購入中は別の未購入家具を操作できない', (tester) async {
      final harness = await _pumpCatalog(tester);

      await _startPurchase(tester, '家具A');
      await tester.tap(_furnitureTile('家具B'));
      await tester.pump();

      expect(find.text('30滴で購入しますか？'), findsNothing);
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

Finder _furnitureTile(String furnitureName) {
  return find.widgetWithText(ListTile, furnitureName);
}

Future<void> _startPurchase(WidgetTester tester, String furnitureName) async {
  await tester.tap(_furnitureTile(furnitureName));
  await tester.pumpAndSettle();
  await tester.tap(find.text('購入'));
  await tester.pump();
  await tester.pump(const Duration(seconds: 1));
}

Future<_CatalogHarness> _pumpCatalog(WidgetTester tester) async {
  final shizukuRepository = _BlockingShizukuRepository();
  addTearDown(shizukuRepository.completeSave);
  final catalogRepository = _FakePurchasedFurnitureRepository();
  final shizukuProvider = ShizukuProvider(shizukuRepository);
  final catalogProvider = CatalogProvider(catalogRepository);
  final placedFurnitureProvider = PlacedFurnitureProvider(
    _FakePlacedFurnitureRepository(),
  );

  await Future.wait([
    shizukuProvider.load(),
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
          furnitureRepository: _FakeFurnitureRepository(),
          placementSlotRepository: _FakePlacementSlotRepository(),
        ),
      ),
    ),
  );
  await tester.pumpAndSettle();

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
  @override
  Future<List<Furniture>> getAll() async => const [
    _furnitureA,
    _furnitureB,
    _furnitureC,
  ];
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
  int saveCallCount = 0;

  @override
  Future<Set<String>> loadPurchasedFurnitureIds() async => {'furniture_c'};

  @override
  Future<void> savePurchasedFurnitureIds(Set<String> furnitureIds) async {
    saveCallCount++;
  }
}

class _BlockingShizukuRepository extends ShizukuRepository {
  final Completer<void> _saveCompleter = Completer<void>();
  int saveCallCount = 0;

  @override
  Future<ShizukuState> loadState() async =>
      const ShizukuState(currentShizuku: 100, rewardedLetterIds: {});

  @override
  Future<void> saveState(ShizukuState state) {
    saveCallCount++;
    return _saveCompleter.future;
  }

  void completeSave() {
    if (!_saveCompleter.isCompleted) {
      _saveCompleter.complete();
    }
  }
}

class _FakePlacedFurnitureRepository extends PlacedFurnitureRepository {
  @override
  Future<Map<String, String>> loadPlacedFurnitureIds() async => {};
}
