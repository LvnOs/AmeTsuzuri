import 'dart:async';

import 'package:ame_tsuzuri/features/furniture/model/furniture.dart';
import 'package:ame_tsuzuri/features/furniture/provider/catalog_provider.dart';
import 'package:ame_tsuzuri/features/furniture/repository/purchased_furniture_repository.dart';
import 'package:ame_tsuzuri/features/letters/model/shizuku_state.dart';
import 'package:ame_tsuzuri/features/letters/provider/shizuku_provider.dart';
import 'package:ame_tsuzuri/features/letters/repository/shizuku_repository.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  setUp(() {
    SharedPreferences.setMockInitialValues({});
  });

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

  group('buy', () {
    test('購入履歴保存が例外になると雫と購入状態を戻し再試行できる', () async {
      final purchasedRepository = _FakePurchasedRepository()..failSave = true;
      final shizukuRepository = _FakeShizukuRepository(100);
      final provider = CatalogProvider(purchasedRepository);
      final shizukuProvider = ShizukuProvider(shizukuRepository);
      await Future.wait([provider.load(), shizukuProvider.load()]);

      await expectLater(
        provider.buy(furniture: _furniture, shizukuProvider: shizukuProvider),
        throwsStateError,
      );

      expect(shizukuProvider.currentShizuku, 100);
      expect(provider.purchasedFurnitureIds, isEmpty);
      expect(purchasedRepository.ids, isEmpty);

      final result = await provider.buy(
        furniture: _furniture,
        shizukuProvider: shizukuProvider,
      );

      expect(result, FurniturePurchaseResult.success);
      expect(shizukuProvider.currentShizuku, 70);
      expect(provider.purchasedFurnitureIds, {'wooden_mug'});
      expect(purchasedRepository.ids, {'wooden_mug'});
    });

    test('購入履歴保存失敗後にProviderを再生成しても未購入かつ補償済みになる', () async {
      final purchasedRepository = _FakePurchasedRepository()..failSave = true;
      final shizukuRepository = _FakeShizukuRepository(100);
      final provider = CatalogProvider(purchasedRepository);
      final shizukuProvider = ShizukuProvider(shizukuRepository);
      await Future.wait([provider.load(), shizukuProvider.load()]);

      await expectLater(
        provider.buy(furniture: _furniture, shizukuProvider: shizukuProvider),
        throwsStateError,
      );

      final recreatedCatalogProvider = CatalogProvider(purchasedRepository);
      final recreatedShizukuProvider = ShizukuProvider(shizukuRepository);
      await Future.wait([
        recreatedCatalogProvider.load(),
        recreatedShizukuProvider.load(),
      ]);

      expect(recreatedCatalogProvider.purchasedFurnitureIds, isEmpty);
      expect(recreatedShizukuProvider.currentShizuku, 100);
    });

    test('setStringListがfalseでも雫と購入状態を戻す', () async {
      final purchasedRepository = PurchasedFurnitureRepository(
        setStringListOverride: (_, _) async => false,
      );
      final shizukuRepository = _FakeShizukuRepository(100);
      final provider = CatalogProvider(purchasedRepository);
      final shizukuProvider = ShizukuProvider(shizukuRepository);
      await Future.wait([provider.load(), shizukuProvider.load()]);

      await expectLater(
        provider.buy(furniture: _furniture, shizukuProvider: shizukuProvider),
        throwsStateError,
      );

      expect(shizukuProvider.currentShizuku, 100);
      expect(provider.purchasedFurnitureIds, isEmpty);
    });

    test('雫補償保存も失敗した場合は永続状態を再読込して補償失敗を伝える', () async {
      final purchasedRepository = _FakePurchasedRepository()..failSave = true;
      final shizukuRepository = _FakeShizukuRepository(100)..failSaveCall = 2;
      final provider = CatalogProvider(purchasedRepository);
      final shizukuProvider = ShizukuProvider(shizukuRepository);
      await Future.wait([provider.load(), shizukuProvider.load()]);

      await expectLater(
        provider.buy(furniture: _furniture, shizukuProvider: shizukuProvider),
        throwsA(
          isA<StateError>().having(
            (error) => error.message,
            'message',
            'shizuku save failed',
          ),
        ),
      );

      expect(provider.purchasedFurnitureIds, isEmpty);
      expect(shizukuProvider.currentShizuku, 70);
      expect(shizukuRepository.loadCallCount, 2);
    });

    test('正常購入は雫を1回消費して購入状態を保存する', () async {
      final purchasedRepository = _FakePurchasedRepository();
      final shizukuRepository = _FakeShizukuRepository(100);
      final provider = CatalogProvider(purchasedRepository);
      final shizukuProvider = ShizukuProvider(shizukuRepository);
      await Future.wait([provider.load(), shizukuProvider.load()]);

      final result = await provider.buy(
        furniture: _furniture,
        shizukuProvider: shizukuProvider,
      );

      expect(result, FurniturePurchaseResult.success);
      expect(shizukuProvider.currentShizuku, 70);
      expect(provider.purchasedFurnitureIds, {'wooden_mug'});
      expect(purchasedRepository.ids, {'wooden_mug'});
      expect(shizukuRepository.saveCallCount, 1);
      expect(purchasedRepository.saveCallCount, 1);
    });

    test('同じ家具の同時購入は雫を二重に消費しない', () async {
      final purchasedRepository = _FakePurchasedRepository();
      final shizukuRepository = _FakeShizukuRepository(100)..blockSave = true;
      final provider = CatalogProvider(purchasedRepository);
      final shizukuProvider = ShizukuProvider(shizukuRepository);
      await Future.wait([provider.load(), shizukuProvider.load()]);

      final firstPurchase = provider.buy(
        furniture: _furniture,
        shizukuProvider: shizukuProvider,
      );
      final secondResult = await provider.buy(
        furniture: _furniture,
        shizukuProvider: shizukuProvider,
      );

      expect(secondResult, FurniturePurchaseResult.purchaseInProgress);
      expect(shizukuRepository.saveCallCount, 1);
      shizukuRepository.completeSave();
      expect(await firstPurchase, FurniturePurchaseResult.success);
      expect(shizukuProvider.currentShizuku, 70);
    });
  });
}

const _furniture = Furniture(
  id: 'wooden_mug',
  name: '木のマグカップ',
  price: 30,
  size: 'small',
  slotIds: ['desk'],
  imagePath: 'assets/images/furniture/wooden_mug.png',
  initialAvailable: true,
);

class _FakePurchasedRepository extends PurchasedFurnitureRepository {
  _FakePurchasedRepository({this.ids = const {}});

  Set<String> ids;
  bool blockLoad = false;
  bool failClear = false;
  bool failLoad = false;
  bool failSave = false;
  int loadCallCount = 0;
  int clearCallCount = 0;
  int saveCallCount = 0;
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
  Future<void> savePurchasedFurnitureIds(Set<String> furnitureIds) async {
    saveCallCount++;
    if (failSave) {
      failSave = false;
      throw StateError('save failed');
    }
    ids = Set.of(furnitureIds);
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

class _FakeShizukuRepository extends ShizukuRepository {
  _FakeShizukuRepository(int initialShizuku)
    : state = ShizukuState(
        currentShizuku: initialShizuku,
        rewardedLetterIds: const {},
      );

  ShizukuState state;
  bool blockSave = false;
  int? failSaveCall;
  int loadCallCount = 0;
  int saveCallCount = 0;
  Completer<void>? _saveCompleter;

  @override
  Future<ShizukuState> loadState() async {
    loadCallCount++;
    return state;
  }

  @override
  Future<void> saveState(ShizukuState nextState) async {
    saveCallCount++;
    if (saveCallCount == failSaveCall) {
      throw StateError('shizuku save failed');
    }
    if (blockSave) {
      _saveCompleter = Completer<void>();
      await _saveCompleter!.future;
    }
    state = nextState;
  }

  void completeSave() => _saveCompleter!.complete();
}
