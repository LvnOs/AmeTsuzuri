enum SeasonType {
  spring,
  summer,
  autumn,
  winter,
  any;

  static SeasonType fromYaml(String value) {
    return switch (value) {
      'spring' => SeasonType.spring,
      'summer' => SeasonType.summer,
      'autumn' => SeasonType.autumn,
      'winter' => SeasonType.winter,
      'any' => SeasonType.any,
      _ => throw FormatException('Unsupported season type: $value'),
    };
  }

  static SeasonType fromDate(DateTime date) {
    return switch (date.month) {
      >= 3 && <= 5 => SeasonType.spring,
      >= 6 && <= 8 => SeasonType.summer,
      >= 9 && <= 11 => SeasonType.autumn,
      _ => SeasonType.winter,
    };
  }
}
