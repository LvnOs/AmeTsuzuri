import 'package:ame_tsuzuri/features/room/presentation/widgets/interaction_hint_marker.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  testWidgets('雫形のCustomPaintをIgnorePointerで表示する', (tester) async {
    await tester.pumpWidget(
      const MaterialApp(home: Scaffold(body: InteractionHintMarker())),
    );

    expect(find.byType(InteractionHintMarker), findsOneWidget);
    expect(
      find.descendant(
        of: find.byType(InteractionHintMarker),
        matching: find.byType(IgnorePointer),
      ),
      findsOneWidget,
    );
    expect(
      find.descendant(
        of: find.byType(InteractionHintMarker),
        matching: find.byType(CustomPaint),
      ),
      findsOneWidget,
    );
  });

  test('ゆるやかな上下移動と控えめな明滅を行う', () {
    expect(InteractionHintMarker.verticalOffsetForProgress(0), 0);
    expect(InteractionHintMarker.verticalOffsetForProgress(0.25), 2);
    expect(InteractionHintMarker.verticalOffsetForProgress(0.75), -2);
    expect(InteractionHintMarker.opacityForProgress(0.25), closeTo(0.92, 0.001));
    expect(InteractionHintMarker.opacityForProgress(0.75), closeTo(0.72, 0.001));
  });
}
