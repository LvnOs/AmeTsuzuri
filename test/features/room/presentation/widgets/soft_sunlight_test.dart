import 'package:ame_tsuzuri/features/room/presentation/widgets/soft_sunlight.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  testWidgets('SoftSunlightはGradientを描画してタップを透過する', (tester) async {
    await _pumpSoftSunlight(tester, const Size(390, 700));

    expect(find.byType(SoftSunlight), findsOneWidget);
    expect(
      find.descendant(
        of: find.byType(SoftSunlight),
        matching: find.byType(IgnorePointer),
      ),
      findsOneWidget,
    );
    final gradientLayers = find.descendant(
      of: find.byType(SoftSunlight),
      matching: find.byType(DecoratedBox),
    );
    expect(gradientLayers, findsNWidgets(2));
    for (final decoratedBox in tester.widgetList<DecoratedBox>(
      gradientLayers,
    )) {
      expect((decoratedBox.decoration as BoxDecoration).gradient, isNotNull);
    }
    expect(tester.takeException(), isNull);
  });

  for (final size in const [Size(390, 700), Size(1200, 800)]) {
    testWidgets('${size.width.toInt()}px幅でoverflowしない', (tester) async {
      await _pumpSoftSunlight(tester, size);

      expect(tester.getSize(find.byType(SoftSunlight)), size);
      expect(tester.takeException(), isNull);
    });
  }
}

Future<void> _pumpSoftSunlight(WidgetTester tester, Size size) async {
  tester.view.devicePixelRatio = 1;
  tester.view.physicalSize = size;
  addTearDown(() {
    tester.view.resetDevicePixelRatio();
    tester.view.resetPhysicalSize();
  });
  await tester.pumpWidget(
    const MaterialApp(
      home: Scaffold(body: Stack(children: [SoftSunlight()])),
    ),
  );
}
