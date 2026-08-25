import 'package:ame_tsuzuri/features/furniture/model/furniture.dart';
import 'package:ame_tsuzuri/features/furniture/repository/furniture_repository.dart';
import 'package:flutter_test/flutter_test.dart';

const _deskSurfaceLeftSlotId = 'living_room_desk_surface_left';
const _deskSurfaceRightSlotId = 'living_room_desk_surface_right';
const _windowShelfDecorSlotId = 'living_room_window_shelf_decor';
const _deskFurnitureIds = {'wooden_mug', 'ink_bottle', 'wooden_fox_figure'};
const _windowFurnitureIds = {
  'small_houseplant',
  'wooden_bird_figure',
  'small_glass_ornament',
};
const _publicFurnitureIds = {..._deskFurnitureIds, ..._windowFurnitureIds};

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('FurnitureRepositoryのv0.2.0 MVPマスター', () {
    late List<Furniture> furnitures;

    setUpAll(() async {
      furnitures = await FurnitureRepository().getAll();
    });

    test('全43件の家具定義を維持する', () {
      expect(furnitures, hasLength(43));
    });

    test('机上3家具と窓辺3家具だけが初期公開される', () {
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

    test('MVP対象外の代表家具は非公開だがマスターに残る', () {
      final teaCup = furnitures.singleWhere((item) => item.id == 'tea_cup');

      expect(teaCup.initialAvailable, isFalse);
      expect(teaCup.slotIds, isNotEmpty);
    });
  });
}
