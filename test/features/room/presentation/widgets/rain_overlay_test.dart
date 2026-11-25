import 'dart:math' as math;

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

  testWidgets('tutorial未完了中はnormal rainを使用する', (tester) async {
    await _pumpRainOverlay(tester, isTutorialCompleted: false);

    expect(
      find.byKey(const ValueKey('rain-overlay-intensity-normal')),
      findsOneWidget,
    );
  });

  testWidgets('light / normal / heavyを強制してbuildできる', (tester) async {
    const expectedCounts = [6, 12, 20];
    const expectedLengths = [0.8, 1.0, 1.25];
    const expectedOpacities = [0.50, 0.67, 0.8];
    for (final (index, intensity) in RainIntensity.values.indexed) {
      await _pumpRainOverlay(tester, intensityOverride: intensity);

      expect(
        find.byKey(ValueKey('rain-overlay-intensity-${intensity.name}')),
        findsOneWidget,
      );
      final recording = _recordRain(tester);
      expect(recording.lines, hasLength(expectedCounts.elementAt(index)));
      expect(
        (recording.lines.first.end - recording.lines.first.start).distance,
        closeTo(math.sqrt(160) * expectedLengths.elementAt(index), 0.01),
      );
      expect(
        recording.lines.first.opacity,
        closeTo(expectedOpacities.elementAt(index), 0.01),
      );
      expect(tester.takeException(), null);
    }
  });

  testWidgets('同じOverlayで周期を切り替え位相を保ったまま移動速度を反映する', (tester) async {
    await _pumpRainOverlay(tester);
    final automaticPreset = _rainPainter.evaluate().single.widget.key;
    final overlayState = tester.state(find.byType(RainOverlay));
    final travelY = tester.getSize(_rainPainter).height * (0.435 - 0.035) + 12;
    const periods = {
      RainIntensity.light: 4200,
      RainIntensity.normal: 3000,
      RainIntensity.heavy: 2250,
    };

    for (final intensity in [
      ...RainIntensity.values,
      ...RainIntensity.values,
      RainIntensity.light,
    ]) {
      final before = _firstDropStart(tester);
      await _pumpRainOverlay(tester, intensityOverride: intensity);
      expect(tester.state(find.byType(RainOverlay)), same(overlayState));
      _expectOffsetCloseTo(_firstDropStart(tester), before);

      // One tenth of this preset's actual loop should move one tenth of the track.
      await tester.pump(Duration(milliseconds: periods[intensity]! ~/ 10));
      _expectOffsetCloseTo(
        _firstDropStart(tester),
        before + Offset(-travelY / 30, travelY / 10),
      );
    }

    final beforeAuto = _firstDropStart(tester);
    await _pumpRainOverlay(tester);
    expect(_rainPainter.evaluate().single.widget.key, automaticPreset);
    _expectOffsetCloseTo(_firstDropStart(tester), beforeAuto);
    await tester.pump(const Duration(milliseconds: 100));
    expect(_firstDropStart(tester).dy, greaterThan(beforeAuto.dy));
    expect(tester.binding.hasScheduledFrame, isTrue);
    expect(tester.takeException(), isNull);
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

Future<void> _pumpRainOverlay(
  WidgetTester tester, {
  bool isTutorialCompleted = true,
  RainIntensity? intensityOverride,
}) {
  return tester.pumpWidget(
    MaterialApp(
      home: Scaffold(
        body: Center(
          child: SizedBox(
            width: 390,
            height: 700,
            child: Stack(
              children: [
                RainOverlay(
                  isTutorialCompleted: isTutorialCompleted,
                  intensityOverride: intensityOverride,
                ),
              ],
            ),
          ),
        ),
      ),
    ),
  );
}

Offset _firstDropStart(WidgetTester tester) {
  return _recordRain(tester).lines.first.start;
}

_RecordingCanvas _recordRain(WidgetTester tester) {
  final customPaint = tester.widget<CustomPaint>(_rainPainter);
  final canvas = _RecordingCanvas();
  customPaint.painter!.paint(canvas, tester.getSize(_rainPainter));
  return canvas;
}

final _rainPainter = find.descendant(
  of: find.byType(RainOverlay),
  matching: find.byType(CustomPaint),
);

void _expectOffsetCloseTo(Offset actual, Offset expected) {
  expect(actual.dx, closeTo(expected.dx, 0.1));
  expect(actual.dy, closeTo(expected.dy, 0.1));
}

class _RecordingCanvas implements Canvas {
  final lines = <_RecordedLine>[];

  @override
  void drawLine(Offset p1, Offset p2, Paint paint) {
    lines.add(_RecordedLine(p1, p2, paint.color.a));
  }

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

class _RecordedLine {
  const _RecordedLine(this.start, this.end, this.opacity);

  final Offset start;
  final Offset end;
  final double opacity;
}
