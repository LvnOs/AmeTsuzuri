import 'package:ame_tsuzuri/features/letters/model/letter.dart';
import 'package:ame_tsuzuri/features/letters/presentation/letter_page.dart';
import 'package:ame_tsuzuri/shared/model/season_type.dart';
import 'package:ame_tsuzuri/shared/model/weather_type.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  testWidgets('便箋にtitleとbodyを表示してAppBarから戻れる', (tester) async {
    await _setSurfaceSize(tester, const Size(390, 700));
    await _pumpLetter(tester, body: '雨の日に届いた手紙です。');

    expect(find.text('手紙'), findsOneWidget);
    expect(find.text('雨の手紙'), findsOneWidget);
    expect(find.text('雨の日に届いた手紙です。'), findsOneWidget);
    expect(find.byType(BackButton), findsOneWidget);
    expect(find.byKey(const ValueKey('letterContent')), findsOneWidget);
    expect(find.byKey(const ValueKey('letterPaper')), findsOneWidget);
  });

  testWidgets('便箋Containerは生成り色と控えめな角・影を持つ', (tester) async {
    await _setSurfaceSize(tester, const Size(390, 700));
    await _pumpLetter(tester, body: '短い手紙です。');

    final paper = tester.widget<Container>(
      find.byKey(const ValueKey('letterPaper')),
    );
    final decoration = paper.decoration! as BoxDecoration;

    expect(decoration.color, const Color(0xFFFFFAEC));
    expect(decoration.borderRadius, BorderRadius.circular(4));
    expect(decoration.boxShadow, isNotEmpty);
  });

  testWidgets('本文部分だけにCustomPainterの横罫線背景を持つ', (tester) async {
    await _setSurfaceSize(tester, const Size(390, 700));
    await _pumpLetter(tester, body: '罫線に沿って読む本文です。');

    final rulesFinder = find.byKey(const ValueKey('letterRules'));
    final rules = tester.widget<CustomPaint>(rulesFinder);
    final dynamic rulesPainter = rules.painter;
    final body = tester.widget<Text>(find.text('罫線に沿って読む本文です。'));

    expect(rules.painter, isNotNull);
    expect(rulesPainter.spacing, 30);
    expect(rulesPainter.startOffset, 30);
    expect(body.style!.fontSize, 16.5);
    expect(body.style!.height, closeTo(30 / 16.5, 0.0001));
    expect(body.strutStyle!.forceStrutHeight, isTrue);
    expect(body.strutStyle!.height, closeTo(30 / 16.5, 0.0001));
    expect(
      find.ancestor(of: find.text('雨の手紙'), matching: rulesFinder),
      findsNothing,
    );
    expect(
      find.ancestor(of: find.text('罫線に沿って読む本文です。'), matching: rulesFinder),
      findsOneWidget,
    );
  });

  testWidgets('短い本文でも便箋の余白まで横罫線領域が続く', (tester) async {
    await _setSurfaceSize(tester, const Size(390, 700));
    await _pumpLetter(tester, body: '短い手紙です。');

    final rulesSize = tester.getSize(
      find.byKey(const ValueKey('letterRules')),
    );

    expect(rulesSize.height, greaterThan(400));
    expect(tester.takeException(), isNull);
  });

  for (final size in const [Size(320, 640), Size(390, 700)]) {
    testWidgets('${size.width.toInt()}px幅で便箋が横overflowしない', (tester) async {
      await _setSurfaceSize(tester, size);
      await _pumpLetter(tester, body: 'スマートフォンで読む手紙です。');

      final contentSize = tester.getSize(
        find.byKey(const ValueKey('letterContent')),
      );

      expect(contentSize.width, lessThanOrEqualTo(size.width - 32));
      expect(tester.takeException(), isNull);
    });
  }

  testWidgets('短い手紙でも390x700の表示領域に沿った便箋高を持つ', (tester) async {
    await _setSurfaceSize(tester, const Size(390, 700));
    await _pumpLetter(tester, body: '短い手紙です。');

    final paperSize = tester.getSize(find.byKey(const ValueKey('letterPaper')));

    expect(paperSize.height, greaterThan(500));
    expect(tester.takeException(), isNull);
  });

  testWidgets('PC幅でも便箋は最大640pxを超えない', (tester) async {
    await _setSurfaceSize(tester, const Size(1200, 800));
    await _pumpLetter(tester, body: '広い画面で読む手紙です。');

    final contentSize = tester.getSize(
      find.byKey(const ValueKey('letterContent')),
    );

    expect(contentSize.width, lessThanOrEqualTo(640));
    expect(tester.takeException(), isNull);
  });

  testWidgets('長い手紙は便箋全体を縦方向にスクロールできる', (tester) async {
    await _setSurfaceSize(tester, const Size(320, 400));
    await _pumpLetter(tester, body: List.filled(80, '雨の音が聞こえます。').join('\n'));

    final scrollable = tester.state<ScrollableState>(
      find.descendant(
        of: find.byType(SingleChildScrollView),
        matching: find.byType(Scrollable),
      ),
    );
    expect(scrollable.position.maxScrollExtent, greaterThan(0));

    await tester.drag(
      find.byType(SingleChildScrollView),
      const Offset(0, -200),
    );
    await tester.pump();

    expect(scrollable.position.pixels, greaterThan(0));
    expect(tester.takeException(), isNull);
  });

  testWidgets('tutorial_001正式本文を390x700で最後までスクロールできる', (
    tester,
  ) async {
    final tutorialBody = await rootBundle.loadString(
      'assets/letters/tutorial_001.md',
    );
    await _setSurfaceSize(tester, const Size(390, 700));
    await _pumpLetter(tester, body: tutorialBody);

    final scrollable = tester.state<ScrollableState>(
      find.descendant(
        of: find.byType(SingleChildScrollView),
        matching: find.byType(Scrollable),
      ),
    );
    expect(scrollable.position.maxScrollExtent, greaterThan(0));

    scrollable.position.jumpTo(scrollable.position.maxScrollExtent);
    await tester.pump();

    expect(scrollable.position.pixels, scrollable.position.maxScrollExtent);
    expect(find.textContaining('またこの部屋へ来てください。'), findsOneWidget);
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

Future<void> _pumpLetter(WidgetTester tester, {required String body}) async {
  await tester.pumpWidget(
    MaterialApp(
      home: Builder(
        builder: (context) => Scaffold(
          body: Center(
            child: ElevatedButton(
              onPressed: () {
                Navigator.of(context).push(
                  MaterialPageRoute<void>(
                    builder: (context) => LetterPage(
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
              },
              child: const Text('手紙を開く'),
            ),
          ),
        ),
      ),
    ),
  );
  await tester.tap(find.text('手紙を開く'));
  await tester.pumpAndSettle();
}
