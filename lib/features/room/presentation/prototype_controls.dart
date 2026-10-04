import 'package:ame_tsuzuri/shared/model/season_type.dart';
import 'package:ame_tsuzuri/shared/model/weather_type.dart';
import 'package:ame_tsuzuri/features/room/presentation/widgets/rain_overlay.dart';
import 'package:flutter/material.dart';

enum PrototypeOperation {
  nextDay,
  outdoorAuto,
  outdoorSpring,
  outdoorSummer,
  outdoorAutumn,
  outdoorWinter,
  weatherAuto,
  weatherRain,
  weatherSunny,
  rainAuto,
  rainLight,
  rainNormal,
  rainHeavy,
  reset,
}

class PrototypeControls extends StatelessWidget {
  const PrototypeControls({
    super.key,
    required this.isRunning,
    required this.onNextDay,
    required this.onOutdoorSeasonChanged,
    required this.onWeatherChanged,
    required this.onRainIntensityChanged,
    required this.onReset,
  });

  final bool isRunning;
  final VoidCallback onNextDay;
  final ValueChanged<SeasonType?> onOutdoorSeasonChanged;
  final ValueChanged<WeatherType?> onWeatherChanged;
  final ValueChanged<RainIntensity?> onRainIntensityChanged;
  final VoidCallback onReset;

  static const double _itemHeight = 34;
  static const double _dividerHeight = 6;

  @override
  Widget build(BuildContext context) {
    return PopupMenuButton<PrototypeOperation>(
      key: const ValueKey('prototypeControls'),
      enabled: !isRunning,
      tooltip: 'テスト操作',
      onSelected: (operation) {
        switch (operation) {
          case PrototypeOperation.nextDay:
            onNextDay();
            return;
          case PrototypeOperation.outdoorAuto:
            onOutdoorSeasonChanged(null);
            return;
          case PrototypeOperation.outdoorSpring:
            onOutdoorSeasonChanged(SeasonType.spring);
            return;
          case PrototypeOperation.outdoorSummer:
            onOutdoorSeasonChanged(SeasonType.summer);
            return;
          case PrototypeOperation.outdoorAutumn:
            onOutdoorSeasonChanged(SeasonType.autumn);
            return;
          case PrototypeOperation.outdoorWinter:
            onOutdoorSeasonChanged(SeasonType.winter);
            return;
          case PrototypeOperation.weatherAuto:
            onWeatherChanged(null);
            return;
          case PrototypeOperation.weatherRain:
            onWeatherChanged(WeatherType.rain);
            return;
          case PrototypeOperation.weatherSunny:
            onWeatherChanged(WeatherType.sunny);
            return;
          case PrototypeOperation.rainAuto:
            onRainIntensityChanged(null);
            return;
          case PrototypeOperation.rainLight:
            onRainIntensityChanged(RainIntensity.light);
            return;
          case PrototypeOperation.rainNormal:
            onRainIntensityChanged(RainIntensity.normal);
            return;
          case PrototypeOperation.rainHeavy:
            onRainIntensityChanged(RainIntensity.heavy);
            return;
          case PrototypeOperation.reset:
            onReset();
            return;
        }
      },
      itemBuilder: (context) => [
        PopupMenuItem<PrototypeOperation>(
          key: const ValueKey('prototypeNextDay'),
          height: _itemHeight,
          value: PrototypeOperation.nextDay,
          child: const Text('翌日へ進む'),
        ),
        const PopupMenuDivider(height: _dividerHeight),
        PopupMenuItem<PrototypeOperation>(
          key: const ValueKey('prototypeOutdoorAuto'),
          height: _itemHeight,
          value: PrototypeOperation.outdoorAuto,
          child: const Text('背景：自動'),
        ),
        PopupMenuItem<PrototypeOperation>(
          key: const ValueKey('prototypeOutdoorSpring'),
          height: _itemHeight,
          value: PrototypeOperation.outdoorSpring,
          child: const Text('背景：春'),
        ),
        PopupMenuItem<PrototypeOperation>(
          key: const ValueKey('prototypeOutdoorSummer'),
          height: _itemHeight,
          value: PrototypeOperation.outdoorSummer,
          child: const Text('背景：夏'),
        ),
        PopupMenuItem<PrototypeOperation>(
          key: const ValueKey('prototypeOutdoorAutumn'),
          height: _itemHeight,
          value: PrototypeOperation.outdoorAutumn,
          child: const Text('背景：秋'),
        ),
        PopupMenuItem<PrototypeOperation>(
          key: const ValueKey('prototypeOutdoorWinter'),
          height: _itemHeight,
          value: PrototypeOperation.outdoorWinter,
          child: const Text('背景：冬'),
        ),
        const PopupMenuDivider(height: _dividerHeight),
        PopupMenuItem<PrototypeOperation>(
          key: const ValueKey('prototypeWeatherAuto'),
          height: _itemHeight,
          value: PrototypeOperation.weatherAuto,
          child: const Text('天気：自動'),
        ),
        PopupMenuItem<PrototypeOperation>(
          key: const ValueKey('prototypeWeatherRain'),
          height: _itemHeight,
          value: PrototypeOperation.weatherRain,
          child: const Text('天気：雨'),
        ),
        PopupMenuItem<PrototypeOperation>(
          key: const ValueKey('prototypeWeatherSunny'),
          height: _itemHeight,
          value: PrototypeOperation.weatherSunny,
          child: const Text('天気：晴れ'),
        ),
        const PopupMenuDivider(height: _dividerHeight),
        PopupMenuItem<PrototypeOperation>(
          key: const ValueKey('prototypeRainAuto'),
          height: _itemHeight,
          value: PrototypeOperation.rainAuto,
          child: const Text('雨量：自動'),
        ),
        PopupMenuItem<PrototypeOperation>(
          key: const ValueKey('prototypeRainLight'),
          height: _itemHeight,
          value: PrototypeOperation.rainLight,
          child: const Text('雨量：小雨'),
        ),
        PopupMenuItem<PrototypeOperation>(
          key: const ValueKey('prototypeRainNormal'),
          height: _itemHeight,
          value: PrototypeOperation.rainNormal,
          child: const Text('雨量：通常'),
        ),
        PopupMenuItem<PrototypeOperation>(
          key: const ValueKey('prototypeRainHeavy'),
          height: _itemHeight,
          value: PrototypeOperation.rainHeavy,
          child: const Text('雨量：大雨'),
        ),
        const PopupMenuDivider(height: _dividerHeight),
        PopupMenuItem<PrototypeOperation>(
          key: const ValueKey('prototypeReset'),
          height: _itemHeight,
          value: PrototypeOperation.reset,
          child: const Text('最初からやり直す'),
        ),
      ],
      child: DecoratedBox(
        decoration: BoxDecoration(
          color: const Color(0xCCFFFAEC),
          borderRadius: BorderRadius.circular(18),
          border: Border.all(color: const Color(0x668A8175)),
        ),
        child: const Padding(
          padding: EdgeInsets.symmetric(horizontal: 10, vertical: 6),
          child: Text(
            'テスト',
            style: TextStyle(fontSize: 12, color: Color(0xFF554D43)),
          ),
        ),
      ),
    );
  }
}
