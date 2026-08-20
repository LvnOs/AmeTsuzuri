import 'package:flutter/material.dart';

class BottleProgress extends StatelessWidget {
  const BottleProgress({
    super.key,
    required this.progress,
    this.capacity = 30,
    this.showFullState = false,
  });

  final int progress;
  final int capacity;
  final bool showFullState;

  @override
  Widget build(BuildContext context) {
    final visibleProgress = showFullState
        ? capacity
        : progress.clamp(0, capacity);
    final ratio = capacity <= 0 ? 0.0 : visibleProgress / capacity;

    return Semantics(
      label: '瓶の水位 $visibleProgress/$capacity',
      child: Column(
        mainAxisAlignment: MainAxisAlignment.end,
        children: [
          Expanded(
            child: FractionallySizedBox(
              widthFactor: 0.58,
              child: DecoratedBox(
                key: const ValueKey('bottle-progress'),
                decoration: BoxDecoration(
                  color: const Color(0x55FFFFFF),
                  border: Border.all(color: const Color(0xFF665E55), width: 2),
                  borderRadius: const BorderRadius.vertical(
                    top: Radius.circular(8),
                    bottom: Radius.circular(14),
                  ),
                ),
                child: ClipRRect(
                  borderRadius: const BorderRadius.vertical(
                    top: Radius.circular(6),
                    bottom: Radius.circular(12),
                  ),
                  child: Align(
                    alignment: Alignment.bottomCenter,
                    child: FractionallySizedBox(
                      key: const ValueKey('bottle-water-level'),
                      heightFactor: ratio,
                      widthFactor: 1,
                      child: const ColoredBox(color: Color(0xAA75B9D2)),
                    ),
                  ),
                ),
              ),
            ),
          ),
          const SizedBox(height: 2),
          Text(
            '$visibleProgress/$capacity',
            key: const ValueKey('bottle-progress-label'),
            style: const TextStyle(fontSize: 10, color: Color(0xFF3E352D)),
          ),
        ],
      ),
    );
  }
}
