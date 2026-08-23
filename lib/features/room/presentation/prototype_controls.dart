import 'package:flutter/material.dart';

enum PrototypeOperation { nextDay, reset }

class PrototypeControls extends StatelessWidget {
  const PrototypeControls({
    super.key,
    required this.isRunning,
    required this.onNextDay,
    required this.onReset,
  });

  final bool isRunning;
  final VoidCallback onNextDay;
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
