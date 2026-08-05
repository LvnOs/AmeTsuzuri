import 'package:flutter/services.dart';
import 'package:yaml/yaml.dart';

import '../model/letter.dart';

class LetterRepository {
  Future<List<Letter>> getAll() async {
    final yamlString = await rootBundle.loadString('assets/data/letters.yaml');
    // YAMLファイルの構造上、以下の取得方法となる
    final yaml = loadYaml(yamlString)["letters"];

    final List<Letter> letters = [];

    for (final item in yaml) {
      final bodyFile = item['body_file'] as String;
      final body = await rootBundle.loadString('assets/$bodyFile');

      letters.add(
        Letter(
          id: item["id"],
          title: item["title"],
          date: DateTime.parse(item["date"]),
          body: body,
        ),
      );
    }
    return letters;
  }

  Future<Letter?> getByDate(DateTime date) async {
    List<Letter> letters = await getAll();
    for (final letter in letters) {
      if (_isSameDate(letter.date, date)) {
        return letter;
      }
    }

    return null;
  }

  Future<Letter?> getTodayLetter() async {
    final today = DateTime.now();
    return getByDate(today);
  }

  bool _isSameDate(DateTime a, DateTime b) {
    return a.year == b.year && a.month == b.month && a.day == b.day;
  }
}
