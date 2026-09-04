import 'package:ame_tsuzuri/features/furniture/model/furniture.dart';
import 'package:ame_tsuzuri/features/furniture/repository/furniture_repository.dart';
import 'package:flutter_test/flutter_test.dart';

const _deskSurfaceLeftSlotId = 'living_room_desk_surface_left';
const _deskSurfaceRightSlotId = 'living_room_desk_surface_right';
const _windowShelfDecorSlotId = 'living_room_window_shelf_decor';
const _windowHangingDecorSlotId = 'living_room_window_hanging_decor';
const _floorRugSlotId = 'living_room_floor_rug';
const _chairSlotId = 'living_room_chair';
const _windowVaseSlotId = 'living_room_window_vase';
const _deskFurnitureIds = {'wooden_mug', 'ink_bottle', 'wooden_fox_figure'};
const _windowFurnitureIds = {
  'small_houseplant',
  'wooden_bird_figure',
  'small_glass_ornament',
};
const _hangingFurnitureIds = {'wind_chime', 'teru_teru_bozu', 'moon_mobile'};
const _flowerFurnitureIds = {
  'small_white_flower',
  'blue_violet_flower',
  'pale_yellow_flower',
};
const _publicFurnitureIds = {
  ..._deskFurnitureIds,
  ..._windowFurnitureIds,
  ..._hangingFurnitureIds,
  ..._flowerFurnitureIds,
  'round_rug',
  'rectangular_rug',
  'wooden_chair',
  'cushioned_chair',
  'rocking_chair',
};

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('FurnitureRepositoryのv0.2.0 MVPマスター', () {
    late List<Furniture> furnitures;

    setUpAll(() async {
      furnitures = await FurnitureRepository().getAll();
    });

    test('全49件の家具定義を維持する', () {
      expect(furnitures, hasLength(49));
    });

    test('既存公開家具と花3種だけが初期公開される', () {
      final availableIds = furnitures
          .where((furniture) => furniture.initialAvailable)
          .map((furniture) => furniture.id)
          .toSet();

      expect(availableIds, _publicFurnitureIds);
    });

    test('正式3家具は30雫で机上Aと机上Bだけへ配置できる', () {
      for (final id in _deskFurnitureIds) {
        final furniture = furnitures.singleWhere((item) => item.id == id);

        expect(furniture.price, 30, reason: id);
        expect(furniture.initialAvailable, isTrue, reason: id);
        expect(furniture.slotIds, const [
          _deskSurfaceLeftSlotId,
          _deskSurfaceRightSlotId,
        ], reason: id);
      }
    });

    test('窓辺A家具3種は30滴で窓辺Aだけに配置できる', () {
      const expectedNames = {
        'small_houseplant': '小さな観葉植物',
        'wooden_bird_figure': '木の小鳥',
        'small_glass_ornament': 'ガラス細工',
      };
      const expectedImages = {
        'small_houseplant': 'furniture/window/small_houseplant.png',
        'wooden_bird_figure': 'furniture/window/wooden_bird.png',
        'small_glass_ornament': 'furniture/window/glass_ornament.png',
      };

      for (final id in _windowFurnitureIds) {
        final furniture = furnitures.singleWhere((item) => item.id == id);

        expect(furniture.name, expectedNames[id], reason: id);
        expect(furniture.price, 30, reason: id);
        expect(furniture.initialAvailable, isTrue, reason: id);
        expect(furniture.slotIds, const [_windowShelfDecorSlotId], reason: id);
        expect(furniture.imagePath, expectedImages[id], reason: id);
      }
    });

    test('吊り飾り家具3種は30滴で吊り飾りだけに配置できる', () {
      const expectedNames = {
        'wind_chime': '風鈴',
        'teru_teru_bozu': 'てるてる坊主',
        'moon_mobile': '月のモビール',
      };
      const expectedImages = {
        'wind_chime': 'furniture/hanging/wind_chime.png',
        'teru_teru_bozu': 'furniture/hanging/teru_teru_bozu.png',
        'moon_mobile': 'furniture/hanging/moon_mobile.png',
      };

      for (final id in _hangingFurnitureIds) {
        final furniture = furnitures.singleWhere((item) => item.id == id);

        expect(furniture.name, expectedNames[id], reason: id);
        expect(furniture.price, 30, reason: id);
        expect(furniture.initialAvailable, isTrue, reason: id);
        expect(furniture.slotIds, const [
          _windowHangingDecorSlotId,
        ], reason: id);
        expect(furniture.imagePath, expectedImages[id], reason: id);
      }
    });

    test('花3種は10滴で一輪挿しだけに配置できる', () {
      const expected = {
        'small_white_flower': (
          '白い小花',
          'furniture/window/small_white_flower.png',
        ),
        'blue_violet_flower': (
          '青紫の花',
          'furniture/window/blue_violet_flower.png',
        ),
        'pale_yellow_flower': (
          '淡い黄色の花',
          'furniture/window/pale_yellow_flower.png',
        ),
      };

      for (final entry in expected.entries) {
        final furniture = furnitures.singleWhere(
          (item) => item.id == entry.key,
        );
        expect(furniture.name, entry.value.$1, reason: entry.key);
        expect(furniture.price, 10, reason: entry.key);
        expect(furniture.size, 'small', reason: entry.key);
        expect(furniture.initialAvailable, isTrue, reason: entry.key);
        expect(furniture.slotIds, const [_windowVaseSlotId], reason: entry.key);
        expect(furniture.imagePath, entry.value.$2, reason: entry.key);
      }
    });

    test('無地の丸ラグは70滴でラグslotだけに配置できる', () {
      final rug = furnitures.singleWhere((item) => item.id == 'round_rug');

      expect(rug.name, '無地の丸ラグ');
      expect(rug.price, 70);
      expect(rug.size, 'large');
      expect(rug.initialAvailable, isTrue);
      expect(rug.slotIds, const [_floorRugSlotId]);
      expect(rug.imagePath, 'furniture/rug/round_rug.png');
    });

    test('淡いチェックの四角ラグは70滴でラグslotだけに配置できる', () {
      final rug = furnitures.singleWhere(
        (item) => item.id == 'rectangular_rug',
      );

      expect(rug.name, '淡いチェックの四角ラグ');
      expect(rug.price, 70);
      expect(rug.size, 'large');
      expect(rug.initialAvailable, isTrue);
      expect(rug.slotIds, const [_floorRugSlotId]);
      expect(rug.imagePath, 'furniture/rug/check_rug.png');
    });

    test('MVP対象外の代表家具は非公開だがマスターに残る', () {
      final teaCup = furnitures.singleWhere((item) => item.id == 'tea_cup');

      expect(teaCup.initialAvailable, isFalse);
      expect(teaCup.slotIds, isNotEmpty);
    });
    test('chair 3種は70雫でchair slotだけに配置できる', () {
      const expected = {
        'wooden_chair': ('木製チェア', 'furniture/chair/wooden_chair.png'),
        'cushioned_chair': (
          'クッション付きチェア',
          'furniture/chair/cushioned_chair.png',
        ),
        'rocking_chair': ('ロッキングチェア', 'furniture/chair/rocking_chair.png'),
      };

      for (final entry in expected.entries) {
        final furniture = furnitures.singleWhere(
          (item) => item.id == entry.key,
        );
        expect(furniture.name, entry.value.$1, reason: entry.key);
        expect(furniture.price, 70, reason: entry.key);
        expect(furniture.size, 'large', reason: entry.key);
        expect(furniture.initialAvailable, isTrue, reason: entry.key);
        expect(furniture.slotIds, const [_chairSlotId], reason: entry.key);
        expect(furniture.imagePath, entry.value.$2, reason: entry.key);
      }
    });
  });
}
