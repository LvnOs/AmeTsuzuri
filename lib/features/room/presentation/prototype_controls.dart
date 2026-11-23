import 'package:ame_tsuzuri/features/real_weather/presentation/real_weather_panel.dart';
import 'package:ame_tsuzuri/features/room/presentation/widgets/rain_overlay.dart';
import 'package:ame_tsuzuri/shared/model/season_type.dart';
import 'package:ame_tsuzuri/shared/model/weather_type.dart';
import 'package:flutter/material.dart';

enum PrototypeOperation {
  toggleDateMode,
  nextDay,
  outdoorAuto,
  outdoorSpring,
  outdoorSummer,
  outdoorAutumn,
  outdoorWinter,
  letterAuto,
  letterSpring,
  letterSummer,
  letterAutumn,
  letterWinter,
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
    required this.isPrototypeMode,
    required this.showWeather,
    required this.compact,
    required this.onToggleDateMode,
    required this.onNextDay,
    required this.onOutdoorSeasonChanged,
    required this.letterSeasonOverride,
    required this.onLetterSeasonChanged,
    required this.onWeatherChanged,
    required this.onRainIntensityChanged,
    required this.onReset,
  });

  final bool isRunning;
  final bool isPrototypeMode;
  final bool showWeather;
  final bool compact;
  final VoidCallback onToggleDateMode;
  final VoidCallback onNextDay;
  final ValueChanged<SeasonType?> onOutdoorSeasonChanged;
  final SeasonType? letterSeasonOverride;
  final ValueChanged<SeasonType?> onLetterSeasonChanged;
  final ValueChanged<WeatherType?> onWeatherChanged;
  final ValueChanged<RainIntensity?> onRainIntensityChanged;
  final VoidCallback onReset;

  static const double _itemHeight = 34;
  static const double _dividerHeight = 6;

  @override
  Widget build(BuildContext context) {
    if (!isPrototypeMode) {
      Future<void> openSettings() async {
        final enterPrototype = await showModalBottomSheet<bool>(
          context: context,
          useSafeArea: true,
          isScrollControlled: true,
          backgroundColor: const Color(0xFFFFFAEC),
          builder: (sheetContext) => SafeArea(
            top: false,
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(16),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Row(
                    children: [
                      Expanded(
                        child: Semantics(
                          header: true,
                          child: Text(
                            '設定',
                            style: Theme.of(sheetContext).textTheme.titleLarge,
                          ),
                        ),
                      ),
                      CloseButton(onPressed: () => Navigator.pop(sheetContext)),
                    ],
                  ),
                  if (showWeather) const RealWeatherPanel(),
                  const Divider(),
                  Semantics(header: true, child: const Text('テスト操作')),
                  TextButton(
                    onPressed: () => Navigator.pop(sheetContext, true),
                    child: const Text('Prototypeモードに切り替える'),
                  ),
                ],
              ),
            ),
          ),
        );
        if (context.mounted && enterPrototype == true) {
          onToggleDateMode();
        }
      }

      if (compact) {
        return IconButton.filledTonal(
          key: const ValueKey('roomSettings'),
          tooltip: '設定',
          onPressed: isRunning ? null : openSettings,
          icon: const Icon(Icons.settings_outlined),
        );
      }
      return FilledButton.tonalIcon(
        key: const ValueKey('roomSettings'),
        style: FilledButton.styleFrom(
          backgroundColor: const Color(0xECFFFAEC),
          foregroundColor: const Color(0xFF554D43),
          padding: const EdgeInsets.symmetric(horizontal: 10),
        ),
        onPressed: isRunning ? null : openSettings,
        icon: const Icon(Icons.settings_outlined, size: 16),
        label: const Text('設定'),
      );
    }
    return PopupMenuButton<PrototypeOperation>(
      key: const ValueKey('prototypeControls'),
      enabled: !isRunning,
      tooltip: 'テスト操作',
      onSelected: (operation) {
        switch (operation) {
          case PrototypeOperation.toggleDateMode:
            onToggleDateMode();
            return;
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
          case PrototypeOperation.letterAuto:
            onLetterSeasonChanged(null);
            return;
          case PrototypeOperation.letterSpring:
            onLetterSeasonChanged(SeasonType.spring);
            return;
          case PrototypeOperation.letterSummer:
            onLetterSeasonChanged(SeasonType.summer);
            return;
          case PrototypeOperation.letterAutumn:
            onLetterSeasonChanged(SeasonType.autumn);
            return;
          case PrototypeOperation.letterWinter:
            onLetterSeasonChanged(SeasonType.winter);
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
      itemBuilder: (context) {
        final modeItem = PopupMenuItem<PrototypeOperation>(
          height: _itemHeight,
          value: PrototypeOperation.toggleDateMode,
          child: const Text('通常プレイに戻る'),
        );
        return [modeItem, ..._prototypeItems()];
      },
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

  List<PopupMenuEntry<PrototypeOperation>> _prototypeItems() => [
    const PopupMenuDivider(height: _dividerHeight),
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
      key: const ValueKey('prototypeLetterAuto'),
      height: _itemHeight,
      value: PrototypeOperation.letterAuto,
      child: _menuLabel('手紙：自動', letterSeasonOverride == null),
    ),
    PopupMenuItem<PrototypeOperation>(
      key: const ValueKey('prototypeLetterSpring'),
      height: _itemHeight,
      value: PrototypeOperation.letterSpring,
      child: _menuLabel('手紙：春', letterSeasonOverride == SeasonType.spring),
    ),
    PopupMenuItem<PrototypeOperation>(
      key: const ValueKey('prototypeLetterSummer'),
      height: _itemHeight,
      value: PrototypeOperation.letterSummer,
      child: _menuLabel('手紙：夏', letterSeasonOverride == SeasonType.summer),
    ),
    PopupMenuItem<PrototypeOperation>(
      key: const ValueKey('prototypeLetterAutumn'),
      height: _itemHeight,
      value: PrototypeOperation.letterAutumn,
      child: _menuLabel('手紙：秋', letterSeasonOverride == SeasonType.autumn),
    ),
    PopupMenuItem<PrototypeOperation>(
      key: const ValueKey('prototypeLetterWinter'),
      height: _itemHeight,
      value: PrototypeOperation.letterWinter,
      child: _menuLabel('手紙：冬', letterSeasonOverride == SeasonType.winter),
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
  ];

  Widget _menuLabel(String label, bool isSelected) {
    return Row(
      children: [
        Expanded(child: Text(label)),
        if (isSelected) const Icon(Icons.check, size: 16),
      ],
    );
  }
}
