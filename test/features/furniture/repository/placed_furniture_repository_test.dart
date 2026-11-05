import 'dart:convert';

import 'package:ame_tsuzuri/features/furniture/repository/placed_furniture_repository.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  const key = 'placedFurnitureIds';

  setUp(() {
    SharedPreferences.setMockInitialValues({});
  });

  test('正常JSONのslotIdとfurnitureIdを復元する', () async {
    SharedPreferences.setMockInitialValues({
      key: jsonEncode({'desk_a': 'wooden_mug', 'window_a': 'small_houseplant'}),
    });

    expect(await PlacedFurnitureRepository().loadPlacedFurnitureIds(), {
      'desk_a': 'wooden_mug',
      'window_a': 'small_houseplant',
    });
  });

  test('空Mapを空配置として復元する', () async {
    SharedPreferences.setMockInitialValues({key: '{}'});

    expect(await PlacedFurnitureRepository().loadPlacedFurnitureIds(), isEmpty);
  });

  test('不正JSON文字列は空配置として扱う', () async {
    SharedPreferences.setMockInitialValues({key: '{broken'});

    expect(await PlacedFurnitureRepository().loadPlacedFurnitureIds(), isEmpty);
  });

  test('JSON object以外は空配置として扱う', () async {
    for (final value in ['[]', '"wooden_mug"', '10', 'null']) {
      SharedPreferences.setMockInitialValues({key: value});

      expect(
        await PlacedFurnitureRepository().loadPlacedFurnitureIds(),
        isEmpty,
        reason: value,
      );
    }
  });

  test('key/value形式の配列はobjectではないため空配置として扱う', () async {
    SharedPreferences.setMockInitialValues({
      key: jsonEncode([
        {'key': 1, 'value': 'wooden_mug'},
      ]),
    });

    expect(await PlacedFurnitureRepository().loadPlacedFurnitureIds(), isEmpty);
  });

  test('valueがString以外のentryは除外する', () async {
    SharedPreferences.setMockInitialValues({
      key: jsonEncode({
        'number': 10,
        'boolean': true,
        'list': ['wooden_mug'],
        'object': {'id': 'wooden_mug'},
        'null': null,
      }),
    });

    expect(await PlacedFurnitureRepository().loadPlacedFurnitureIds(), isEmpty);
  });

  test('正常entryと不正entryの混在時は正常entryだけ復元する', () async {
    SharedPreferences.setMockInitialValues({
      key: jsonEncode({
        'desk_a': 'wooden_mug',
        'broken': 10,
        'window_a': 'small_houseplant',
      }),
    });

    expect(await PlacedFurnitureRepository().loadPlacedFurnitureIds(), {
      'desk_a': 'wooden_mug',
      'window_a': 'small_houseplant',
    });
  });

  test('setStringがfalseなら保存失敗として例外にする', () async {
    final repository = PlacedFurnitureRepository(
      setStringOverride: (_, _) async => false,
    );

    await expectLater(
      repository.savePlacedFurnitureIds({'desk_a': 'wooden_mug'}),
      throwsStateError,
    );
  });

  test('removeがfalseならclear失敗として例外にする', () async {
    final repository = PlacedFurnitureRepository(
      removeOverride: (_) async => false,
    );

    await expectLater(repository.clear(), throwsStateError);
  });
}
