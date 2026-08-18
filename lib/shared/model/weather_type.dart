enum WeatherType {
  rain,
  sunny;

  static WeatherType fromYaml(String value) {
    return switch (value) {
      'rain' => WeatherType.rain,
      'sunny' => WeatherType.sunny,
      _ => throw FormatException('Unsupported weather type: $value'),
    };
  }
}
