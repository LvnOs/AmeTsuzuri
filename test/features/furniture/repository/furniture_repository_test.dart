import 'package:ame_tsuzuri/features/furniture/model/furniture.dart';
import 'package:ame_tsuzuri/features/furniture/repository/furniture_repository.dart';
import 'package:flutter_test/flutter_test.dart';

const _deskSurfaceLeftSlotId = 'living_room_desk_surface_left';
const _mvpFurnitureIds = {
  'wooden_mug',
  'ink_bottle',
  'wooden_fox_figure',
};

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('FurnitureRepositoryのv0.2.0 MVPマスター', () {
    late List<Furniture> furnitures;

    setUpAll(() async {
      furnitures = await FurnitureRepository().getAll();
    });

    test('全42件の家具定義を維持する', () {
      expect(furnitures, hasLength(42));
    });

    test('正式3家具だけが初期公開される', () {
      final availableIds = furnitures
          .where((furniture) => furniture.initialAvailable)
          .map((furniture) => furniture.id)
          .toSet();

      expect(availableIds, _mvpFurnitureIds);
    });

    test('正式3家具は30雫で机上Aだけへ配置できる', () {
      for (final id in _mvpFurnitureIds) {
        final furniture = furnitures.singleWhere((item) => item.id == id);

        expect(furniture.price, 30, reason: id);
        expect(furniture.initialAvailable, isTrue, reason: id);
        expect(furniture.slotIds, const [_deskSurfaceLeftSlotId], reason: id);
      }
    });

    test('MVP対象外の代表家具は非公開だがマスターに残る', () {
      final teaCup = furnitures.singleWhere((item) => item.id == 'tea_cup');

      expect(teaCup.initialAvailable, isFalse);
      expect(teaCup.slotIds, isNotEmpty);
    });
  });
}
