import 'dart:async';

import 'package:ame_tsuzuri/features/furniture/provider/placed_furniture_provider.dart';
import 'package:ame_tsuzuri/features/furniture/repository/placed_furniture_repository.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
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
  int loadCallCount = 0;
  int clearCallCount = 0;
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
  Future<void> clear() async {
    clearCallCount++;
    if (failClear) {
      throw StateError('clear failed');
    }
    ids = {};
  }
}
