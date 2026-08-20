import 'package:ame_tsuzuri/features/letters/model/letter.dart';
import 'package:ame_tsuzuri/features/letters/presentation/letter_page.dart';
import 'package:ame_tsuzuri/shared/model/season_type.dart';
import 'package:ame_tsuzuri/shared/model/weather_type.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  testWidgets('スマホ幅で手紙本文が画面内に収まる', (tester) async {
    await _setSurfaceSize(tester, const Size(320, 640));
    await _pumpLetter(tester, body: '短い手紙です。');

    final contentSize = tester.getSize(
      find.byKey(const ValueKey('letterContent')),
    );

    expect(contentSize.width, lessThanOrEqualTo(320));
    expect(contentSize.width, 280);
    expect(
      tester.widget<Scrollable>(find.byType(Scrollable)).axisDirection,
      AxisDirection.down,
    );
    expect(tester.takeException(), isNull);
  });

  testWidgets('PC幅で手紙本文の最大幅を維持する', (tester) async {
    await _setSurfaceSize(tester, const Size(1200, 800));
    await _pumpLetter(tester, body: '広い画面で読む手紙です。');

    final contentSize = tester.getSize(
      find.byKey(const ValueKey('letterContent')),
    );

    expect(contentSize.width, 640);
    expect(tester.takeException(), isNull);
  });

  testWidgets('長い手紙は縦方向にスクロールできる', (tester) async {
    await _setSurfaceSize(tester, const Size(320, 400));
    await _pumpLetter(tester, body: List.filled(80, '雨の音が聞こえます。').join('\n'));

    final scrollable = tester.state<ScrollableState>(find.byType(Scrollable));
    expect(scrollable.position.maxScrollExtent, greaterThan(0));

    await tester.drag(
      find.byType(SingleChildScrollView),
      const Offset(0, -200),
    );
    await tester.pump();

    expect(scrollable.position.pixels, greaterThan(0));
    expect(tester.takeException(), isNull);
  });
}

Future<void> _setSurfaceSize(WidgetTester tester, Size size) async {
  tester.view.devicePixelRatio = 1;
  tester.view.physicalSize = size;
  addTearDown(() {
    tester.view.resetDevicePixelRatio();
    tester.view.resetPhysicalSize();
  });
}

Future<void> _pumpLetter(WidgetTester tester, {required String body}) {
  return tester.pumpWidget(
    MaterialApp(
      home: LetterPage(
        letter: Letter(
          id: 'letter',
          title: '雨の手紙',
          body: body,
          requiredSeason: SeasonType.any,
          requiredWeather: WeatherType.rain,
        ),
      ),
    ),
  );
}
