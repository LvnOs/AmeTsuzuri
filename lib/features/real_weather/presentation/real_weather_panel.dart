import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../../shared/model/weather_type.dart';
import '../provider/real_weather_provider.dart';
import '../service/weather_platform_stub.dart'
    if (dart.library.js_interop) '../service/weather_platform_web.dart'
    as platform;

class RealWeatherPanel extends StatefulWidget {
  const RealWeatherPanel({super.key});

  @override
  State<RealWeatherPanel> createState() => _RealWeatherPanelState();
}

class _RealWeatherPanelState extends State<RealWeatherPanel> {
  bool _expanded = false;

  @override
  Widget build(BuildContext context) {
    final weather = context.watch<RealWeatherProvider?>();
    if (weather == null || !weather.isLoaded) return const SizedBox.shrink();

    final status = weather.isLoading
        ? '現在地の天気を確認中…'
        : switch (weather.current?.weather) {
            WeatherType.rain => '現在の天気：雨 · Open-Meteo',
            WeatherType.sunny => '現在の天気：雨ではありません · Open-Meteo',
            null when weather.isEnabled => '現在地の天気は未確定です',
            null => '現在地の天気',
          };
    final foreground = Colors.brown.shade900;
    return Material(
      color: const Color(0xFFEEE7D9),
      child: SizedBox(
        width: double.infinity,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextButton(
              style: TextButton.styleFrom(foregroundColor: foreground),
              onPressed: () => setState(() => _expanded = !_expanded),
              child: Semantics(
                liveRegion: true,
                child: Text(_expanded ? '$status ▴' : '$status ▾'),
              ),
            ),
            if (_expanded)
              ConstrainedBox(
                constraints: BoxConstraints(
                  maxHeight: MediaQuery.sizeOf(context).height * 0.38,
                ),
                child: SingleChildScrollView(
                  padding: const EdgeInsets.fromLTRB(12, 0, 12, 8),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      if (!weather.isEnabled)
                        const Text(
                          '現在地の天気を確認するため、取得のたびに位置情報を一度取得し、'
                          '座標を Open-Meteo に送信します。アプリに座標は保存しません。',
                          textAlign: TextAlign.center,
                        ),
                      if (weather.failure != null)
                        Text(switch (weather.failure!) {
                          RealWeatherFailure.denied => 'ブラウザで位置情報が許可されていません',
                          RealWeatherFailure.locationTimeout =>
                            '位置情報の取得がタイムアウトしました',
                          RealWeatherFailure.unsupported =>
                            'この環境では位置情報を利用できません',
                          RealWeatherFailure.locationUnavailable =>
                            '位置情報を取得できませんでした',
                          RealWeatherFailure.weatherUnavailable =>
                            '天気を確認できませんでした',
                        }, textAlign: TextAlign.center),
                      if (weather.settingError)
                        const Text('位置利用設定を読み込み、または保存できませんでした。'),
                      Wrap(
                        alignment: WrapAlignment.center,
                        children: [
                          TextButton(
                            onPressed: weather.isLoading
                                ? null
                                : weather.enableOrRetry,
                            child: Text(
                              !weather.isEnabled
                                  ? '現在地の天気を使う'
                                  : weather.failure != null ||
                                        weather.current == null
                                  ? '再試行'
                                  : '天気を更新する',
                            ),
                          ),
                          if (weather.isEnabled || weather.settingError)
                            TextButton(
                              onPressed: weather.disable,
                              child: const Text('天気の利用をやめる'),
                            ),
                        ],
                      ),
                      Wrap(
                        alignment: WrapAlignment.center,
                        crossAxisAlignment: WrapCrossAlignment.center,
                        children: [
                          TextButton(
                            onPressed: () =>
                                platform.openCredit('https://open-meteo.com/'),
                            child: const Text('Open-Meteo'),
                          ),
                          TextButton(
                            onPressed: () => platform.openCredit(
                              'https://creativecommons.org/licenses/by/4.0/',
                            ),
                            child: const Text('CC BY 4.0'),
                          ),
                          const Text('天気データを雨・非降雨に分類'),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }
}
