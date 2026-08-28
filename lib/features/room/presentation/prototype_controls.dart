import 'package:ame_tsuzuri/shared/model/season_type.dart';
import 'package:flutter/material.dart';

enum PrototypeOperation {
  nextDay,
  outdoorAuto,
  outdoorSummer,
  outdoorAutumn,
  reset,
}

class PrototypeControls extends StatelessWidget {
  const PrototypeControls({
    super.key,
    required this.isRunning,
    required this.onNextDay,
    required this.onOutdoorSeasonChanged,
    required this.onReset,
  });

  final bool isRunning;
  final VoidCallback onNextDay;
  final ValueChanged<SeasonType?> onOutdoorSeasonChanged;
  final VoidCallback onReset;

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
          case PrototypeOperation.outdoorSummer:
            onOutdoorSeasonChanged(SeasonType.summer);
            return;
          case PrototypeOperation.outdoorAutumn:
            onOutdoorSeasonChanged(SeasonType.autumn);
            return;
          case PrototypeOperation.reset:
            onReset();
            return;
        }
      },
      itemBuilder: (context) => [
        PopupMenuItem<PrototypeOperation>(
          key: const ValueKey('prototypeNextDay'),
          value: PrototypeOperation.nextDay,
          child: const Text('翌日へ進む'),
        ),
        const PopupMenuDivider(),
        PopupMenuItem<PrototypeOperation>(
          key: const ValueKey('prototypeOutdoorAuto'),
          value: PrototypeOperation.outdoorAuto,
          child: const Text('背景：自動'),
        ),
        PopupMenuItem<PrototypeOperation>(
          key: const ValueKey('prototypeOutdoorSummer'),
          value: PrototypeOperation.outdoorSummer,
          child: const Text('背景：夏'),
        ),
        PopupMenuItem<PrototypeOperation>(
          key: const ValueKey('prototypeOutdoorAutumn'),
          value: PrototypeOperation.outdoorAutumn,
          child: const Text('背景：秋'),
        ),
        const PopupMenuDivider(),
        PopupMenuItem<PrototypeOperation>(
          key: const ValueKey('prototypeReset'),
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
