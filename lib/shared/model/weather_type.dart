enum WeatherType {
  rain;

  static WeatherType fromYaml(String value) {
    return switch (value) {
      'rain' => WeatherType.rain,
      _ => throw FormatException('Unsupported weather type: $value'),
    };
  }
}
