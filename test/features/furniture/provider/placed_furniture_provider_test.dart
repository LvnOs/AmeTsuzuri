import 'dart:async';

import 'package:ame_tsuzuri/features/furniture/provider/placed_furniture_provider.dart';
import 'package:ame_tsuzuri/features/furniture/repository/placed_furniture_repository.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('FIX済み配置仕様', () {
    test('空slotへ家具を配置する', () async {
      final repository = _FakePlacedRepository();
      final provider = PlacedFurnitureProvider(repository);
      await provider.load();

      final result = await provider.place(
        slotId: 'desk_a',
        furnitureId: 'wooden_mug',
        isPurchased: true,
        allowedSlotIds: const ['desk_a', 'desk_b'],
      );

      expect(result, PlaceFurnitureResult.success);
      expect(provider.placedFurnitureIds, {'desk_a': 'wooden_mug'});
      expect(repository.ids, {'desk_a': 'wooden_mug'});
    });

    test('occupied slotへ別家具を配置すると新家具で上書きする', () async {
      final repository = _FakePlacedRepository(ids: {'desk_a': 'wooden_mug'});
      final provider = PlacedFurnitureProvider(repository);
      await provider.load();

      final result = await provider.place(
        slotId: 'desk_a',
        furnitureId: 'ink_bottle',
        isPurchased: true,
        allowedSlotIds: const ['desk_a', 'desk_b'],
      );

      expect(result, PlaceFurnitureResult.success);
      expect(provider.placedFurnitureIds, {'desk_a': 'ink_bottle'});
      expect(repository.ids, {'desk_a': 'ink_bottle'});
    });

    test('occupied slotから追い出された家具の購入状態は失われない', () async {
      final purchasedFurnitureIds = {'wooden_mug', 'ink_bottle'};
      final repository = _FakePlacedRepository(ids: {'desk_a': 'wooden_mug'});
      final provider = PlacedFurnitureProvider(repository);
      await provider.load();

      await provider.place(
        slotId: 'desk_a',
        furnitureId: 'ink_bottle',
        isPurchased: purchasedFurnitureIds.contains('ink_bottle'),
        allowedSlotIds: const ['desk_a', 'desk_b'],
      );

      expect(provider.placedFurnitureIds, {'desk_a': 'ink_bottle'});
      expect(purchasedFurnitureIds, {'wooden_mug', 'ink_bottle'});
      expect(provider.getSlotIdByFurnitureId('wooden_mug'), isNull);
    });

    test('配置済み家具を別slotへ移動すると元slotが空になる', () async {
      final repository = _FakePlacedRepository(ids: {'desk_a': 'wooden_mug'});
      final provider = PlacedFurnitureProvider(repository);
      await provider.load();

      await provider.place(
        slotId: 'desk_b',
        furnitureId: 'wooden_mug',
        isPurchased: true,
        allowedSlotIds: const ['desk_a', 'desk_b'],
      );

      expect(provider.placedFurnitureIds, {'desk_b': 'wooden_mug'});
      expect(provider.placedFurnitureIds, isNot(contains('desk_a')));
    });

    test('移動先がoccupiedでもswapせず移動先の家具を未配置にする', () async {
      final repository = _FakePlacedRepository(
        ids: {'desk_a': 'wooden_mug', 'desk_b': 'ink_bottle'},
      );
      final provider = PlacedFurnitureProvider(repository);
      await provider.load();

      await provider.place(
        slotId: 'desk_b',
        furnitureId: 'wooden_mug',
        isPurchased: true,
        allowedSlotIds: const ['desk_a', 'desk_b'],
      );

      expect(provider.placedFurnitureIds, {'desk_b': 'wooden_mug'});
      expect(provider.getSlotIdByFurnitureId('ink_bottle'), isNull);
    });

    test('同じ家具を通常操作で別slotへ配置してもコピーしない', () async {
      final repository = _FakePlacedRepository();
      final provider = PlacedFurnitureProvider(repository);
      await provider.load();

      await provider.place(
        slotId: 'desk_a',
        furnitureId: 'wooden_mug',
        isPurchased: true,
        allowedSlotIds: const ['desk_a', 'desk_b'],
      );
      await provider.place(
        slotId: 'desk_b',
        furnitureId: 'wooden_mug',
        isPurchased: true,
        allowedSlotIds: const ['desk_a', 'desk_b'],
      );

      expect(provider.placedFurnitureIds, {'desk_b': 'wooden_mug'});
      expect(
        provider.placedFurnitureIds.values.where(
          (furnitureId) => furnitureId == 'wooden_mug',
        ),
        hasLength(1),
      );
    });

    test('Repository保存失敗時は配置Mapを操作前の状態に維持する', () async {
      final repository = _FakePlacedRepository(
        ids: {'desk_a': 'wooden_mug', 'desk_b': 'ink_bottle'},
      )..failSave = true;
      final provider = PlacedFurnitureProvider(repository);
      await provider.load();

      await expectLater(
        provider.place(
          slotId: 'desk_b',
          furnitureId: 'wooden_mug',
          isPurchased: true,
          allowedSlotIds: const ['desk_a', 'desk_b'],
        ),
        throwsStateError,
      );

      expect(provider.placedFurnitureIds, {
        'desk_a': 'wooden_mug',
        'desk_b': 'ink_bottle',
      });
      expect(repository.ids, {'desk_a': 'wooden_mug', 'desk_b': 'ink_bottle'});
    });

    test('allowedSlotIdsに含まれないslotへの配置を拒否して状態を維持する', () async {
      final repository = _FakePlacedRepository(ids: {'desk_a': 'wooden_mug'});
      final provider = PlacedFurnitureProvider(repository);
      await provider.load();

      final result = await provider.place(
        slotId: 'window_a',
        furnitureId: 'wooden_mug',
        isPurchased: true,
        allowedSlotIds: const ['desk_a', 'desk_b'],
      );

      expect(result, PlaceFurnitureResult.invalidSlot);
      expect(provider.placedFurnitureIds, {'desk_a': 'wooden_mug'});
      expect(repository.saveCallCount, 0);
    });
  });

  group('重複済み保存データの正規化', () {
    test('重複2件から移動すると全旧slotを削除して新slotだけにする', () async {
      final repository = _FakePlacedRepository(
        ids: {'desk_a': 'wooden_mug', 'desk_b': 'wooden_mug'},
      );
      final provider = PlacedFurnitureProvider(repository);
      await provider.load();

      await provider.place(
        slotId: 'window_a',
        furnitureId: 'wooden_mug',
        isPurchased: true,
        allowedSlotIds: const ['desk_a', 'desk_b', 'window_a'],
      );

      expect(provider.placedFurnitureIds, {'window_a': 'wooden_mug'});
      expect(
        provider.placedFurnitureIds.values.where(
          (furnitureId) => furnitureId == 'wooden_mug',
        ),
        hasLength(1),
      );
    });

    test('重複3件から移動しても新slotの1件だけにする', () async {
      final repository = _FakePlacedRepository(
        ids: {
          'desk_a': 'wooden_mug',
          'desk_b': 'wooden_mug',
          'window_a': 'wooden_mug',
        },
      );
      final provider = PlacedFurnitureProvider(repository);
      await provider.load();

      await provider.place(
        slotId: 'hanging',
        furnitureId: 'wooden_mug',
        isPurchased: true,
        allowedSlotIds: const ['desk_a', 'desk_b', 'window_a', 'hanging'],
      );

      expect(provider.placedFurnitureIds, {'hanging': 'wooden_mug'});
      expect(repository.ids, {'hanging': 'wooden_mug'});
    });

    test('移動先自身が既存重複の1つでもそのslotの1件だけにする', () async {
      final repository = _FakePlacedRepository(
        ids: {'desk_a': 'wooden_mug', 'desk_b': 'wooden_mug'},
      );
      final provider = PlacedFurnitureProvider(repository);
      await provider.load();

      await provider.place(
        slotId: 'desk_b',
        furnitureId: 'wooden_mug',
        isPurchased: true,
        allowedSlotIds: const ['desk_a', 'desk_b'],
      );

      expect(provider.placedFurnitureIds, {'desk_b': 'wooden_mug'});
      expect(repository.ids, {'desk_b': 'wooden_mug'});
    });

    test('occupied先への移動は全重複を削除してswapしない', () async {
      final purchasedFurnitureIds = {'wooden_mug', 'lamp'};
      final repository = _FakePlacedRepository(
        ids: {'slot_a': 'wooden_mug', 'slot_b': 'lamp', 'slot_c': 'wooden_mug'},
      );
      final provider = PlacedFurnitureProvider(repository);
      await provider.load();

      await provider.place(
        slotId: 'slot_b',
        furnitureId: 'wooden_mug',
        isPurchased: purchasedFurnitureIds.contains('wooden_mug'),
        allowedSlotIds: const ['slot_a', 'slot_b', 'slot_c'],
      );

      expect(provider.placedFurnitureIds, {'slot_b': 'wooden_mug'});
      expect(provider.getSlotIdByFurnitureId('lamp'), isNull);
      expect(purchasedFurnitureIds, {'wooden_mug', 'lamp'});
    });

    test('保存失敗時はoccupied家具を含む重複元状態を維持する', () async {
      final originalState = {
        'slot_a': 'wooden_mug',
        'slot_b': 'lamp',
        'slot_c': 'wooden_mug',
      };
      final repository = _FakePlacedRepository(ids: originalState)
        ..failSave = true;
      final provider = PlacedFurnitureProvider(repository);
      await provider.load();

      await expectLater(
        provider.place(
          slotId: 'slot_b',
          furnitureId: 'wooden_mug',
          isPurchased: true,
          allowedSlotIds: const ['slot_a', 'slot_b', 'slot_c'],
        ),
        throwsStateError,
      );

      expect(provider.placedFurnitureIds, originalState);
      expect(repository.ids, originalState);
    });
  });

  test('並行loadはRepository読み込みを1回に共有する', () async {
    final repository = _FakePlacedRepository()..blockLoad = true;
    final provider = PlacedFurnitureProvider(repository);

    final first = provider.load();
    final second = provider.load();
    expect(repository.loadCallCount, 1);

    repository.completeLoad({'desk': 'wooden_mug'});
    await Future.wait([first, second]);

    expect(provider.isLoaded, isTrue);
    expect(provider.placedFurnitureIds, {'desk': 'wooden_mug'});
  });

  test('resetはclear成功後に配置家具を空にする', () async {
    final repository = _FakePlacedRepository(ids: {'desk': 'wooden_mug'});
    final provider = PlacedFurnitureProvider(repository);
    await provider.load();

    await provider.reset();

    expect(repository.clearCallCount, 1);
    expect(provider.placedFurnitureIds, isEmpty);
  });

  test('clear失敗時は配置状態を維持する', () async {
    final repository = _FakePlacedRepository(ids: {'desk': 'wooden_mug'})
      ..failClear = true;
    final provider = PlacedFurnitureProvider(repository);
    await provider.load();

    await expectLater(provider.reset(), throwsStateError);

    expect(provider.placedFurnitureIds, {'desk': 'wooden_mug'});
  });

  test('load失敗後は再試行できる', () async {
    final repository = _FakePlacedRepository(ids: {'desk': 'wooden_mug'})
      ..failLoad = true;
    final provider = PlacedFurnitureProvider(repository);

    await expectLater(provider.load(), throwsStateError);
    expect(provider.isLoaded, isFalse);

    await provider.load();
    expect(repository.loadCallCount, 2);
    expect(provider.placedFurnitureIds, {'desk': 'wooden_mug'});
  });
}

class _FakePlacedRepository extends PlacedFurnitureRepository {
  _FakePlacedRepository({this.ids = const {}});

  Map<String, String> ids;
  bool blockLoad = false;
  bool failClear = false;
  bool failLoad = false;
  bool failSave = false;
  int loadCallCount = 0;
  int clearCallCount = 0;
  int saveCallCount = 0;
  Completer<Map<String, String>>? _loadCompleter;

  @override
  Future<Map<String, String>> loadPlacedFurnitureIds() {
    loadCallCount++;
    if (failLoad) {
      failLoad = false;
      return Future.error(StateError('load failed'));
    }
    if (!blockLoad) {
      return Future.value(Map.of(ids));
    }
    _loadCompleter = Completer<Map<String, String>>();
    return _loadCompleter!.future;
  }

  void completeLoad(Map<String, String> value) =>
      _loadCompleter!.complete(value);

  @override
  Future<void> savePlacedFurnitureIds(
    Map<String, String> placedFurnitureIds,
  ) async {
    saveCallCount++;
    if (failSave) {
      throw StateError('save failed');
    }
    ids = Map.of(placedFurnitureIds);
  }

  @override
  Future<void> clear() async {
    clearCallCount++;
    if (failClear) {
      throw StateError('clear failed');
    }
    ids = {};
  }
}
