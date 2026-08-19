import 'package:ame_tsuzuri/features/bookshelf/presentation/bookshelf_page.dart';
import 'package:ame_tsuzuri/features/letters/model/letter.dart';
import 'package:ame_tsuzuri/features/letters/model/read_letter_state.dart';
import 'package:ame_tsuzuri/features/letters/provider/read_letter_provider.dart';
import 'package:ame_tsuzuri/features/letters/repository/letter_repository.dart';
import 'package:ame_tsuzuri/features/letters/repository/read_letter_repository.dart';
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

    await tester.pumpWidget(
      ChangeNotifierProvider.value(
        value: readProvider,
        child: MaterialApp(
          home: BookshelfPage(
            letterRepository: _FakeLetterRepository([
              _letter('letterA', '手紙A', DateTime(2020, 1, 1)),
              _letter('legacyLetter', '昔の手紙', DateTime(2019, 2, 2)),
              _letter('unreadLetter', '未読の手紙', DateTime(2026, 8, 10)),
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
    expect(find.text('2020年1月1日'), findsNothing);
    expect(find.text('2019年2月2日'), findsNothing);
  });
}

Letter _letter(String id, String title, DateTime masterDate) {
  return Letter(
    id: id,
    title: title,
    date: masterDate,
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
