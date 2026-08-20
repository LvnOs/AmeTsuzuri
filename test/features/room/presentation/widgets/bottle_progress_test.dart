import 'package:ame_tsuzuri/features/room/presentation/widgets/bottle_progress.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  for (final progress in const [0, 1, 15, 29]) {
    testWidgets('瓶の水位を$progress/30で表示する', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Center(child: BottleProgress(progress: progress)),
        ),
      );

      expect(find.text('$progress/30'), findsOneWidget);
      expect(
        tester.getSemantics(find.byType(BottleProgress)).label,
        contains('瓶の水位 $progress/30'),
      );
    });
  }

  testWidgets('満杯演出中は保存済み進行が0でも30/30を表示する', (tester) async {
    await tester.pumpWidget(
      const MaterialApp(
        home: Center(
          child: BottleProgress(progress: 0, showFullState: true),
        ),
      ),
    );

    expect(find.text('30/30'), findsOneWidget);
  });
}
