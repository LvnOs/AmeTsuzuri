import 'package:ame_tsuzuri/features/furniture/repository/purchased_furniture_repository.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  setUp(() {
    SharedPreferences.setMockInitialValues({});
  });

  test('購入済み家具を保存して読み込める', () async {
    final repository = PurchasedFurnitureRepository();

    await repository.savePurchasedFurnitureIds({'wooden_mug', 'ink_bottle'});

    expect(await repository.loadPurchasedFurnitureIds(), {
      'wooden_mug',
      'ink_bottle',
    });
  });

  test('setStringListがfalseなら保存失敗として例外にする', () async {
    final repository = PurchasedFurnitureRepository(
      setStringListOverride: (_, _) async => false,
    );

    await expectLater(
      repository.savePurchasedFurnitureIds({'wooden_mug'}),
      throwsA(isA<StateError>()),
    );
  });
}
