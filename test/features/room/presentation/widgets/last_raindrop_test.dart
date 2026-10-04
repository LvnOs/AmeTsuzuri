import 'package:ame_tsuzuri/features/room/presentation/widgets/last_raindrop.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

const _fallDuration = Duration(milliseconds: 400);

void main() {
  testWidgets('一滴だけ下へ落下し、完了後は非表示のままになる', (tester) async {
    await _pumpLastRaindrop(tester);

    expect(find.byKey(const ValueKey('lastRaindropPaint')), findsOneWidget);
    final initialTop = tester
        .getTopLeft(find.byKey(const ValueKey('lastRaindropPaint')))
        .dy;

    await tester.pump(const Duration(milliseconds: 200));
    expect(
      tester.getTopLeft(find.byKey(const ValueKey('lastRaindropPaint'))).dy,
      greaterThan(initialTop),
    );

    await tester.pump(const Duration(milliseconds: 201));
    expect(find.byKey(const ValueKey('lastRaindropPaint')), findsNothing);

    await tester.pump(const Duration(seconds: 1));
    expect(find.byKey(const ValueKey('lastRaindropPaint')), findsNothing);
    expect(tester.binding.hasScheduledFrame, isFalse);
  });

  testWidgets('IgnorePointerでタップを透過する', (tester) async {
    await _pumpLastRaindrop(tester);

    expect(
      find.descendant(
        of: find.byType(LastRaindrop),
        matching: find.byType(IgnorePointer),
      ),
      findsOneWidget,
    );
  });

  testWidgets('落下中にdisposeしてもTicker leakを起こさない', (tester) async {
    await _pumpLastRaindrop(tester);
    await tester.pump(const Duration(milliseconds: 100));

    await tester.pumpWidget(const SizedBox.shrink());
    await tester.pump(const Duration(seconds: 1));

    expect(tester.takeException(), isNull);
    expect(tester.binding.transientCallbackCount, 0);
  });
}

Future<void> _pumpLastRaindrop(WidgetTester tester) {
  return tester.pumpWidget(
    const MaterialApp(
      home: Scaffold(
        body: AspectRatio(
          aspectRatio: 390 / 700,
          child: Stack(children: [LastRaindrop(fallDuration: _fallDuration)]),
        ),
      ),
    ),
  );
}
