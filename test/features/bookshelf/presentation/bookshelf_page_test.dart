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

    await tester.tap(find.text('手紙A'));
    await tester.pumpAndSettle();

    expect(find.byType(LetterPage), findsOneWidget);
    expect(shizukuProvider.bottleRecordCount, 30);
    expect(shizukuProvider.fullBottleCount, 1);
  });
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
