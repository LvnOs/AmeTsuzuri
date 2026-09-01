import 'dart:math' as math;

import 'package:ame_tsuzuri/features/room/presentation/widgets/autumn_leaf_effect.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  const interval = Duration(milliseconds: 100);
  const fallDuration = Duration(milliseconds: 400);

  testWidgets('初回待機後に一枚だけ落下し、完了後は非表示になる', (tester) async {
    await _pumpEffect(tester);

    expect(find.byType(AutumnLeafEffect), findsOneWidget);
    expect(
      find.descendant(
        of: find.byType(AutumnLeafEffect),
        matching: find.byType(IgnorePointer),
      ),
      findsOneWidget,
    );
    expect(find.byKey(const ValueKey('autumnLeafImage')), findsNothing);

    await tester.pump(interval);
    await tester.pump();
    expect(find.byKey(const ValueKey('autumnLeafImage')), findsOneWidget);
    final initialTop = _leafPosition(tester).top!;

    await tester.pump(const Duration(milliseconds: 200));
    expect(_leafPosition(tester).top!, greaterThan(initialTop));
    expect(find.byKey(const ValueKey('autumnLeafImage')), findsOneWidget);

    await tester.pump(const Duration(milliseconds: 201));
    await tester.pump();
    expect(find.byKey(const ValueKey('autumnLeafImage')), findsNothing);
  });

  testWidgets('落下完了後に次の待機と落下を繰り返す', (tester) async {
    await _pumpEffect(tester);

    await tester.pump(interval);
    await tester.pump();
    await tester.pump(fallDuration + const Duration(milliseconds: 1));
    await tester.pump();
    expect(find.byKey(const ValueKey('autumnLeafImage')), findsNothing);

    await tester.pump(interval);
    await tester.pump();
    expect(find.byKey(const ValueKey('autumnLeafImage')), findsOneWidget);
  });

  testWidgets('待機中にdisposeしてもTimer callbackやticker leakがない', (tester) async {
    await _pumpEffect(tester);

    await tester.pumpWidget(const SizedBox.shrink());
    await tester.pump(const Duration(seconds: 1));

    expect(tester.takeException(), isNull);
    expect(tester.binding.transientCallbackCount, 0);
  });

  testWidgets('落下中にdisposeしてもticker leakがない', (tester) async {
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
                AutumnLeafEffect(
                  random: math.Random(1),
                  minInterval: const Duration(milliseconds: 100),
                  maxInterval: const Duration(milliseconds: 100),
                  fallDuration: const Duration(milliseconds: 400),
                ),
              ],
            ),
          ),
        ),
      ),
    ),
  );
}

Positioned _leafPosition(WidgetTester tester) {
  return tester.widget<Positioned>(
    find.byKey(const ValueKey('autumnLeafImage')),
  );
}
