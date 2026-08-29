import 'package:ame_tsuzuri/features/room/presentation/widgets/rain_overlay.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  testWidgets('RainOverlayはアニメーションを開始してタップを透過する', (tester) async {
    await _pumpRainOverlay(tester);

    expect(find.byType(RainOverlay), findsOneWidget);
    expect(
      find.descendant(
        of: find.byType(RainOverlay),
        matching: find.byType(IgnorePointer),
      ),
      findsOneWidget,
    );
    expect(tester.binding.hasScheduledFrame, true);
    expect(tester.takeException(), null);
  });

  testWidgets('時間経過とループ境界付近でも描画を継続する', (tester) async {
    await _pumpRainOverlay(tester);

    await tester.pump(const Duration(seconds: 4));
    expect(tester.takeException(), null);
    expect(tester.binding.hasScheduledFrame, true);

    await tester.pump(const Duration(milliseconds: 3999));
    expect(tester.takeException(), null);

    await tester.pump(const Duration(milliseconds: 2));
    expect(tester.takeException(), null);
    expect(tester.binding.hasScheduledFrame, true);
  });

  testWidgets('dispose後にTicker leakを起こさない', (tester) async {
    await _pumpRainOverlay(tester);
    await tester.pump(const Duration(seconds: 1));

    await tester.pumpWidget(const SizedBox.shrink());
    await tester.pump(const Duration(seconds: 1));

    expect(tester.takeException(), null);
    expect(tester.binding.transientCallbackCount, 0);
  });
}

Future<void> _pumpRainOverlay(WidgetTester tester) {
  return tester.pumpWidget(
    const MaterialApp(
      home: Scaffold(
        body: Center(
          child: AspectRatio(
            aspectRatio: 390 / 700,
            child: Stack(children: [RainOverlay()]),
          ),
        ),
      ),
    ),
  );
}
