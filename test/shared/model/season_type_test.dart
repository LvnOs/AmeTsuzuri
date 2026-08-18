import 'package:ame_tsuzuri/shared/model/season_type.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('fromYaml', () {
    test('対応する文字列をSeasonTypeへ変換する', () {
      expect(SeasonType.fromYaml('summer'), SeasonType.summer);
      expect(SeasonType.fromYaml('any'), SeasonType.any);
    });

    test('未対応の文字列はFormatExceptionになる', () {
      expect(
        () => SeasonType.fromYaml('monsoon'),
        throwsA(isA<FormatException>()),
      );
    });
  });

  group('fromDate', () {
    final cases = <DateTime, SeasonType>{
      DateTime(2026, 2, 28): SeasonType.winter,
      DateTime(2024, 2, 29): SeasonType.winter,
      DateTime(2026, 3, 1): SeasonType.spring,
      DateTime(2026, 5, 31): SeasonType.spring,
      DateTime(2026, 6, 1): SeasonType.summer,
      DateTime(2026, 8, 31): SeasonType.summer,
      DateTime(2026, 9, 1): SeasonType.autumn,
      DateTime(2026, 11, 30): SeasonType.autumn,
      DateTime(2026, 12, 1): SeasonType.winter,
    };

    for (final entry in cases.entries) {
      test('${entry.key}は${entry.value.name}', () {
        expect(SeasonType.fromDate(entry.key), entry.value);
      });
    }
  });
}
