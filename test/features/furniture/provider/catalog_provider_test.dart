import 'dart:async';

import 'package:ame_tsuzuri/features/furniture/provider/catalog_provider.dart';
import 'package:ame_tsuzuri/features/furniture/repository/purchased_furniture_repository.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('並行loadはRepository読み込みを1回に共有する', () async {
    final repository = _FakePurchasedRepository()..blockLoad = true;
    final provider = CatalogProvider(repository);

    final first = provider.load();
    final second = provider.load();
    expect(repository.loadCallCount, 1);

    repository.completeLoad({'wooden_mug'});
    await Future.wait([first, second]);

    expect(provider.isLoaded, isTrue);
    expect(provider.purchasedFurnitureIds, {'wooden_mug'});
  });

  test('resetはclear成功後に購入済み家具を空にする', () async {
    final repository = _FakePurchasedRepository(ids: {'wooden_mug'});
    final provider = CatalogProvider(repository);
    await provider.load();

    await provider.reset();

    expect(repository.clearCallCount, 1);
    expect(provider.purchasedFurnitureIds, isEmpty);
  });

  test('clear失敗時は購入済み状態を維持する', () async {
    final repository = _FakePurchasedRepository(ids: {'wooden_mug'})
      ..failClear = true;
    final provider = CatalogProvider(repository);
    await provider.load();

    await expectLater(provider.reset(), throwsStateError);

    expect(provider.purchasedFurnitureIds, {'wooden_mug'});
  });

  test('load失敗後は再試行できる', () async {
    final repository = _FakePurchasedRepository(ids: {'wooden_mug'})
      ..failLoad = true;
    final provider = CatalogProvider(repository);

    await expectLater(provider.load(), throwsStateError);
    expect(provider.isLoaded, isFalse);

    await provider.load();
    expect(repository.loadCallCount, 2);
    expect(provider.purchasedFurnitureIds, {'wooden_mug'});
  });
}

class _FakePurchasedRepository extends PurchasedFurnitureRepository {
  _FakePurchasedRepository({this.ids = const {}});

  Set<String> ids;
  bool blockLoad = false;
  bool failClear = false;
  bool failLoad = false;
  int loadCallCount = 0;
  int clearCallCount = 0;
  Completer<Set<String>>? _loadCompleter;

  @override
  Future<Set<String>> loadPurchasedFurnitureIds() {
    loadCallCount++;
    if (failLoad) {
      failLoad = false;
      return Future.error(StateError('load failed'));
    }
    if (!blockLoad) {
      return Future.value(Set.of(ids));
    }
    _loadCompleter = Completer<Set<String>>();
    return _loadCompleter!.future;
  }

  void completeLoad(Set<String> value) => _loadCompleter!.complete(value);

  @override
  Future<void> clear() async {
    clearCallCount++;
    if (failClear) {
      throw StateError('clear failed');
    }
    ids = {};
  }
}
