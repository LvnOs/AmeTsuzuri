import 'package:ame_tsuzuri/features/room/presentation/widgets/winter_frost_effect.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  testWidgets('WinterFrostEffectは霜を描画してタップを透過する', (tester) async {
    await tester.pumpWidget(
      const MaterialApp(
        home: Scaffold(body: Stack(children: [WinterFrostEffect()])),
      ),
    );

    expect(find.byType(WinterFrostEffect), findsOneWidget);
    expect(
      find.descendant(
        of: find.byType(WinterFrostEffect),
        matching: find.byType(IgnorePointer),
      ),
      findsOneWidget,
    );
    expect(
      find.descendant(
        of: find.byType(WinterFrostEffect),
        matching: find.byType(CustomPaint),
      ),
      findsOneWidget,
    );
    expect(tester.takeException(), isNull);
  });
}
