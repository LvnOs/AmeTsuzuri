import 'package:ame_tsuzuri/features/room/presentation/widgets/furniture_reaction.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

const _testDuration = Duration(milliseconds: 400);

void main() {
  test('対象Furniture IDをreaction typeへ対応付ける', () {
    expect(furnitureReactionTypeFor('wind_chime'), FurnitureReactionType.sway);
    expect(
      furnitureReactionTypeFor('teru_teru_bozu'),
      FurnitureReactionType.gentleSway,
    );
    expect(
      furnitureReactionTypeFor('moon_mobile'),
      FurnitureReactionType.rotate,
    );
    expect(
      furnitureReactionTypeFor('rocking_chair'),
      FurnitureReactionType.rock,
    );
    for (final flowerId in const {
      'small_white_flower',
      'blue_violet_flower',
      'pale_yellow_flower',
    }) {
      expect(
        furnitureReactionTypeFor(flowerId),
        FurnitureReactionType.flowerSway,
      );
    }
    expect(furnitureReactionTypeFor('wooden_chair'), isNull);
    expect(furnitureReactionTypeFor('wooden_mug'), isNull);
  });

  for (final type in FurnitureReactionType.values) {
    testWidgets('$typeはtapで動き、終了後に通常状態へ戻る', (tester) async {
      await _pumpReaction(tester, type: type);

      expect(_rotationComponent(tester), closeTo(0, 0.000001));
      await tester.tap(find.byKey(const ValueKey('furnitureReaction-test')));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 100));

      expect(_rotationComponent(tester).abs(), greaterThan(0.0001));

      await tester.pump(const Duration(milliseconds: 301));
      expect(_rotationComponent(tester), closeTo(0, 0.000001));
    });
  }

  testWidgets('連続tapはmotionを再開始してqueueしない', (tester) async {
    await _pumpReaction(tester, type: FurnitureReactionType.sway);
    final reaction = find.byKey(const ValueKey('furnitureReaction-test'));

    await tester.tap(reaction);
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 180));
    await tester.tap(reaction);
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 40));

    expect(_rotationComponent(tester).abs(), greaterThan(0.0001));

    await tester.pump(const Duration(milliseconds: 401));
    expect(_rotationComponent(tester), closeTo(0, 0.000001));
    expect(tester.binding.hasScheduledFrame, isFalse);
  });

  testWidgets('再生中にdisposeしてもTicker leakを起こさない', (tester) async {
    await _pumpReaction(tester, type: FurnitureReactionType.rock);
    await tester.tap(find.byKey(const ValueKey('furnitureReaction-test')));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 100));

    await tester.pumpWidget(const SizedBox.shrink());
    await tester.pump(const Duration(seconds: 1));

    expect(tester.takeException(), isNull);
    expect(tester.binding.transientCallbackCount, 0);
  });
}

Future<void> _pumpReaction(
  WidgetTester tester, {
  required FurnitureReactionType type,
}) {
  return tester.pumpWidget(
    MaterialApp(
      home: Scaffold(
        body: Center(
          child: FurnitureReaction(
            furnitureId: 'test',
            type: type,
            duration: _testDuration,
            child: const SizedBox(width: 60, height: 100),
          ),
        ),
      ),
    ),
  );
}

double _rotationComponent(WidgetTester tester) {
  return tester
      .widget<Transform>(
        find.byKey(const ValueKey('furnitureReactionTransform-test')),
      )
      .transform
      .storage[1];
}
