import 'dart:async';

import 'package:ame_tsuzuri/features/bookshelf/presentation/bookshelf_page.dart';
import 'package:ame_tsuzuri/features/letters/model/letter.dart';
import 'package:ame_tsuzuri/features/letters/model/read_letter_state.dart';
import 'package:ame_tsuzuri/features/letters/model/shizuku_state.dart';
import 'package:ame_tsuzuri/features/letters/presentation/letter_page.dart';
import 'package:ame_tsuzuri/features/letters/provider/read_letter_provider.dart';
import 'package:ame_tsuzuri/features/letters/provider/shizuku_provider.dart';
import 'package:ame_tsuzuri/features/letters/repository/letter_repository.dart';
import 'package:ame_tsuzuri/features/letters/repository/read_letter_repository.dart';
import 'package:ame_tsuzuri/features/letters/repository/shizuku_repository.dart';
import 'package:ame_tsuzuri/shared/model/season_type.dart';
import 'package:ame_tsuzuri/shared/model/weather_type.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';

void main() {
  testWidgets('読了済みtutorial_001を一覧から通常LetterPageで再読できる', (tester) async {
    final readProvider = ReadLetterProvider(
      _FakeReadLetterRepository(
        ReadLetterState(
          receivedLetters: {'tutorial_001': DateTime(2026, 8, 7)},
        ),
      ),
    );
    final shizukuProvider = ShizukuProvider(_FakeShizukuRepository(1));
    await Future.wait([readProvider.load(), shizukuProvider.load()]);

    await tester.pumpWidget(
      MultiProvider(
        providers: [
          ChangeNotifierProvider.value(value: readProvider),
          ChangeNotifierProvider.value(value: shizukuProvider),
        ],
        child: MaterialApp(
          home: BookshelfPage(
            letterRepository: _FakeLetterRepository([
              _letter('tutorial_001', '雨つづり。へようこそ'),
            ]),
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text('雨つづり。へようこそ'), findsOneWidget);
    expect(
      find.byKey(const ValueKey('bookshelfLetterRow-tutorial_001')),
      findsOneWidget,
    );
    await tester.tap(
      find.byKey(const ValueKey('bookshelfLetterRow-tutorial_001')),
    );
    await tester.pumpAndSettle();
    expect(find.byType(LetterPage), findsOneWidget);
  });

  testWidgets('未読のtutorial_001は一覧に表示しない', (tester) async {
    final readProvider = ReadLetterProvider(
      _FakeReadLetterRepository(ReadLetterState(receivedLetters: {})),
    );
    final shizukuProvider = ShizukuProvider(_FakeShizukuRepository(0));
    await Future.wait([readProvider.load(), shizukuProvider.load()]);

    await tester.pumpWidget(
      MultiProvider(
        providers: [
          ChangeNotifierProvider.value(value: readProvider),
          ChangeNotifierProvider.value(value: shizukuProvider),
        ],
        child: MaterialApp(
          home: BookshelfPage(
            letterRepository: _FakeLetterRepository([
              _letter('tutorial_001', '雨つづり。へようこそ'),
            ]),
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text('雨つづり。へようこそ'), findsNothing);
    expect(
      find.byKey(const ValueKey('bookshelfLetterRow-tutorial_001')),
      findsNothing,
    );
  });

  testWidgets('既読手紙に受取日を表示し未読手紙は表示しない', (tester) async {
    final readProvider = ReadLetterProvider(
      _FakeReadLetterRepository(
        ReadLetterState(
          receivedLetters: {
            'letterA': DateTime(2026, 8, 10),
            'legacyLetter': null,
          },
        ),
      ),
    );
    await readProvider.load();
    final shizukuProvider = ShizukuProvider(_FakeShizukuRepository(0));
    await shizukuProvider.load();

    await tester.pumpWidget(
      MultiProvider(
        providers: [
          ChangeNotifierProvider.value(value: readProvider),
          ChangeNotifierProvider.value(value: shizukuProvider),
        ],
        child: MaterialApp(
          home: BookshelfPage(
            letterRepository: _FakeLetterRepository([
              _letter('letterA', '手紙A'),
              _letter('legacyLetter', '昔の手紙'),
              _letter('unreadLetter', '未読の手紙'),
            ]),
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text('手紙A'), findsOneWidget);
    expect(find.text('2026年8月10日'), findsOneWidget);
    expect(find.text('昔の手紙'), findsOneWidget);
    expect(find.text('受取日不明'), findsOneWidget);
    expect(find.text('未読の手紙'), findsNothing);
    expect(find.text('満ちた瓶 0本'), findsOneWidget);
    expect(
      find.byKey(const ValueKey('bookshelfLetterRow-letterA')),
      findsOneWidget,
    );
    expect(
      find.byKey(const ValueKey('bookshelfLetterRow-unreadLetter')),
      findsNothing,
    );
  });

  for (final entry in const {0: 0, 29: 0, 30: 1, 59: 1, 60: 2}.entries) {
    testWidgets('報酬済み${entry.key}件なら満ちた瓶${entry.value}本を表示する', (tester) async {
      final readProvider = ReadLetterProvider(
        _FakeReadLetterRepository(ReadLetterState(receivedLetters: {})),
      );
      final shizukuProvider = ShizukuProvider(
        _FakeShizukuRepository(entry.key),
      );
      await Future.wait([readProvider.load(), shizukuProvider.load()]);

      await tester.pumpWidget(
        MultiProvider(
          providers: [
            ChangeNotifierProvider.value(value: readProvider),
            ChangeNotifierProvider.value(value: shizukuProvider),
          ],
          child: MaterialApp(
            home: BookshelfPage(
              letterRepository: _FakeLetterRepository(const []),
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text('満ちた瓶 ${entry.value}本'), findsOneWidget);
      expect(
        find.byKey(const ValueKey('bookshelfBottleRecord')),
        findsOneWidget,
      );
    });
  }

  testWidgets('本棚から手紙を再読しても満ちた瓶本数は変わらない', (tester) async {
    final readProvider = ReadLetterProvider(
      _FakeReadLetterRepository(
        ReadLetterState(receivedLetters: {'letterA': DateTime(2026, 8, 10)}),
      ),
    );
    final shizukuProvider = ShizukuProvider(_FakeShizukuRepository(30));
    await Future.wait([readProvider.load(), shizukuProvider.load()]);

    await tester.pumpWidget(
      MultiProvider(
        providers: [
          ChangeNotifierProvider.value(value: readProvider),
          ChangeNotifierProvider.value(value: shizukuProvider),
        ],
        child: MaterialApp(
          home: BookshelfPage(
            letterRepository: _FakeLetterRepository([
              _letter('letterA', '手紙A'),
            ]),
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();

    final shizukuBefore = shizukuProvider.currentShizuku;
    final rewardedIdsBefore = shizukuProvider.rewardedLetterIds;
    final fullBottleCountBefore = shizukuProvider.fullBottleCount;

    await tester.tap(
      find.byKey(const ValueKey('bookshelfLetterRow-letterA')),
    );
    await tester.pumpAndSettle();

    expect(find.byType(LetterPage), findsOneWidget);
    expect(shizukuProvider.bottleRecordCount, 30);
    expect(shizukuProvider.fullBottleCount, 1);
    expect(shizukuProvider.currentShizuku, shizukuBefore);
    expect(shizukuProvider.rewardedLetterIds, rewardedIdsBefore);
    expect(shizukuProvider.fullBottleCount, fullBottleCountBefore);
  });

  group('BookshelfPageの記録帳ビジュアル', () {
    testWidgets('背景と紙面とヘッダーを表示する', (tester) async {
      await _pumpBookshelf(tester);

      final scaffold = tester.widget<Scaffold>(find.byType(Scaffold));
      final appBar = tester.widget<AppBar>(find.byType(AppBar));
      final paper = tester.widget<Container>(
        find.byKey(const ValueKey('bookshelfPaper')),
      );
      final decoration = paper.decoration! as BoxDecoration;

      expect(scaffold.backgroundColor, const Color(0xFFE5DDD0));
      expect(appBar.backgroundColor, const Color(0xFFE5DDD0));
      expect(appBar.elevation, 0);
      expect(appBar.scrolledUnderElevation, 0);
      expect(appBar.surfaceTintColor, Colors.transparent);
      expect(decoration.color, const Color(0xFFFFFAEC));
      expect(decoration.borderRadius, BorderRadius.circular(4));
      expect(decoration.boxShadow, isNotEmpty);
      expect(find.text('届いた手紙'), findsOneWidget);
      expect(
        find.byKey(const ValueKey('bookshelfBottleRecord')),
        findsOneWidget,
      );
    });

    testWidgets('既読0件でも紙面と瓶記録とEmpty文言を表示する', (tester) async {
      await _pumpBookshelf(tester);

      expect(find.byKey(const ValueKey('bookshelfPaper')), findsOneWidget);
      expect(find.text('満ちた瓶 0本'), findsOneWidget);
      expect(find.text('まだ読んだ手紙はありません'), findsOneWidget);
    });

    testWidgets('Repository待機中は紙面内に進捗表示する', (tester) async {
      final repository = _PendingLetterRepository();
      addTearDown(repository.complete);

      await _pumpBookshelf(tester, letterRepository: repository);

      expect(find.byKey(const ValueKey('bookshelfPaper')), findsOneWidget);
      expect(find.byType(CircularProgressIndicator), findsOneWidget);
    });

    testWidgets('Repository失敗時は既存エラーを表示する', (tester) async {
      await _pumpBookshelf(
        tester,
        letterRepository: _ErrorLetterRepository(),
      );

      expect(find.textContaining('手紙の読み込みに失敗しました'), findsOneWidget);
      expect(find.textContaining('test error'), findsOneWidget);
    });

    for (final size in const [Size(320, 640), Size(390, 700)]) {
      testWidgets('${size.width.toInt()}px幅で長いタイトルも横overflowしない', (
        tester,
      ) async {
        tester.view.physicalSize = size;
        tester.view.devicePixelRatio = 1;
        addTearDown(tester.view.resetPhysicalSize);
        addTearDown(tester.view.resetDevicePixelRatio);

        const id = 'long_letter';
        await _pumpBookshelf(
          tester,
          receivedLetters: {id: DateTime(2026, 8, 10)},
          letters: [
            _letter(id, 'とても長い題名を持つ雨の日に届いた一通の手紙について'),
          ],
        );

        expect(find.byKey(const ValueKey('bookshelfPaper')), findsOneWidget);
        expect(
          find.byKey(const ValueKey('bookshelfLetterRow-long_letter')),
          findsOneWidget,
        );
        expect(tester.takeException(), isNull);
      });
    }

    testWidgets('PC幅でも紙面は640pxを超えない', (tester) async {
      tester.view.physicalSize = const Size(1200, 800);
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);

      await _pumpBookshelf(tester);

      expect(
        tester.getSize(find.byKey(const ValueKey('bookshelfPaper'))).width,
        lessThanOrEqualTo(640),
      );
      expect(tester.takeException(), isNull);
    });

    testWidgets('手紙が増えても最後の項目まで縦スクロールできる', (tester) async {
      final letters = List.generate(
        12,
        (index) => _letter('letter$index', '手紙$index'),
      );
      final receivedLetters = {
        for (var index = 0; index < letters.length; index++)
          letters[index].id: DateTime(2026, 8, index + 1),
      };
      await _pumpBookshelf(
        tester,
        letters: letters,
        receivedLetters: receivedLetters,
      );

      final list = find.byKey(const ValueKey('bookshelfLetterList'));
      expect(list, findsOneWidget);
      await tester.scrollUntilVisible(
        find.byKey(const ValueKey('bookshelfLetterRow-letter11')),
        250,
        scrollable: find.descendant(
          of: list,
          matching: find.byType(Scrollable),
        ),
      );
      expect(
        find.byKey(const ValueKey('bookshelfLetterRow-letter11')),
        findsOneWidget,
      );
      expect(tester.takeException(), isNull);
    });
  });
}

Future<void> _pumpBookshelf(
  WidgetTester tester, {
  LetterRepository? letterRepository,
  List<Letter> letters = const [],
  Map<String, DateTime?> receivedLetters = const {},
  int rewardedCount = 0,
}) async {
  final readProvider = ReadLetterProvider(
    _FakeReadLetterRepository(
      ReadLetterState(receivedLetters: receivedLetters),
    ),
  );
  final shizukuProvider = ShizukuProvider(
    _FakeShizukuRepository(rewardedCount),
  );
  await Future.wait([readProvider.load(), shizukuProvider.load()]);

  await tester.pumpWidget(
    MultiProvider(
      providers: [
        ChangeNotifierProvider.value(value: readProvider),
        ChangeNotifierProvider.value(value: shizukuProvider),
      ],
      child: MaterialApp(
        home: BookshelfPage(
          letterRepository: letterRepository ?? _FakeLetterRepository(letters),
        ),
      ),
    ),
  );
  await tester.pump();
  await tester.pump();
}

Letter _letter(String id, String title) {
  return Letter(
    id: id,
    title: title,
    body: id,
    requiredSeason: SeasonType.any,
    requiredWeather: WeatherType.rain,
  );
}

class _FakeLetterRepository extends LetterRepository {
  _FakeLetterRepository(this.letters);

  final List<Letter> letters;

  @override
  Future<List<Letter>> getAll() async => letters;
}

class _PendingLetterRepository extends LetterRepository {
  final Completer<List<Letter>> _completer = Completer<List<Letter>>();

  @override
  Future<List<Letter>> getAll() => _completer.future;

  void complete() {
    if (!_completer.isCompleted) {
      _completer.complete(const []);
    }
  }
}

class _ErrorLetterRepository extends LetterRepository {
  @override
  Future<List<Letter>> getAll() => Future.error('test error');
}

class _FakeReadLetterRepository extends ReadLetterRepository {
  _FakeReadLetterRepository(this.state);

  final ReadLetterState state;

  @override
  Future<ReadLetterState> loadState() async => state;
}

class _FakeShizukuRepository extends ShizukuRepository {
  _FakeShizukuRepository(int rewardedCount)
    : state = ShizukuState(
        currentShizuku: 30,
        rewardedLetterIds: {
          for (var index = 0; index < rewardedCount; index++) 'letter$index',
        },
      );

  final ShizukuState state;

  @override
  Future<ShizukuState> loadState() async => state;
}
