import 'dart:math' as math;

import 'package:ame_tsuzuri/features/room/presentation/widgets/spring_petal_drift_effect.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  const interval = Duration(milliseconds: 100);
  const driftDuration = Duration(milliseconds: 400);

  testWidgets('初回待機後に花びらが横へ流れ、完了後は非表示になる', (tester) async {
    await _pumpEffect(tester);

    expect(find.byType(SpringPetalDriftEffect), findsOneWidget);
    expect(
      find.descendant(
        of: find.byType(SpringPetalDriftEffect),
        matching: find.byType(IgnorePointer),
      ),
      findsOneWidget,
    );
    expect(find.byKey(const ValueKey('springPetalParticle')), findsNothing);

    await tester.pump(interval);
    await tester.pump();
    expect(find.byKey(const ValueKey('springPetalParticle')), findsOneWidget);
    expect(find.byKey(const ValueKey('springPetalPaint')), findsOneWidget);
    final initialLeft = _petalPosition(tester).left!;

    await tester.pump(const Duration(milliseconds: 200));
    expect(_petalPosition(tester).left!, isNot(closeTo(initialLeft, 0.001)));
    expect(find.byKey(const ValueKey('springPetalParticle')), findsOneWidget);

    await tester.pump(const Duration(milliseconds: 201));
    await tester.pump();
    expect(find.byKey(const ValueKey('springPetalParticle')), findsNothing);
    expect(find.byKey(const ValueKey('springPetalPaint')), findsNothing);
  });

  testWidgets('移動完了後に次の待機と花びら表示を繰り返す', (tester) async {
    await _pumpEffect(tester);

    await tester.pump(interval);
    await tester.pump();
    await tester.pump(driftDuration + const Duration(milliseconds: 1));
    await tester.pump();
    expect(find.byKey(const ValueKey('springPetalParticle')), findsNothing);

    await tester.pump(interval);
    await tester.pump();
    expect(find.byKey(const ValueKey('springPetalParticle')), findsOneWidget);
  });

  testWidgets('待機中にdisposeしてもTimer callbackやticker leakがない', (tester) async {
    await _pumpEffect(tester);

    await tester.pumpWidget(const SizedBox.shrink());
    await tester.pump(const Duration(seconds: 1));

    expect(tester.takeException(), isNull);
    expect(tester.binding.transientCallbackCount, 0);
  });

  testWidgets('移動中にdisposeしてもticker leakがない', (tester) async {
    await _pumpEffect(tester);
    await tester.pump(interval);
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 100));

    await tester.pumpWidget(const SizedBox.shrink());
    await tester.pump(const Duration(seconds: 1));

    expect(tester.takeException(), isNull);
    expect(tester.binding.transientCallbackCount, 0);
  });
}

Future<void> _pumpEffect(WidgetTester tester) {
  return tester.pumpWidget(
    MaterialApp(
      home: Scaffold(
        body: Center(
          child: AspectRatio(
            aspectRatio: 390 / 700,
            child: Stack(
              children: [
                SpringPetalDriftEffect(
                  random: math.Random(1),
                  minInterval: const Duration(milliseconds: 100),
                  maxInterval: const Duration(milliseconds: 100),
                  driftDuration: const Duration(milliseconds: 400),
                ),
              ],
            ),
          ),
        ),
      ),
    ),
  );
}

Positioned _petalPosition(WidgetTester tester) {
  return tester.widget<Positioned>(
    find.byKey(const ValueKey('springPetalParticle')),
  );
}
