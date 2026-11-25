import 'dart:math';

import 'package:flutter/material.dart';

enum RainIntensity { light, normal, heavy }

class RainOverlay extends StatefulWidget {
  const RainOverlay({
    super.key,
    required this.isTutorialCompleted,
    this.intensityOverride,
  });

  final bool isTutorialCompleted;
  final RainIntensity? intensityOverride;

  @override
  State<RainOverlay> createState() => _RainOverlayState();
}

class _RainOverlayState extends State<RainOverlay>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;
  late final RainIntensity _selectedIntensity;
  late RainIntensity _displayedIntensity;

  @override
  void initState() {
    super.initState();
    _selectedIntensity = _selectIntensity();
    _displayedIntensity = _resolveIntensity(widget);
    _controller = AnimationController(vsync: this)
      ..repeat(period: _presetFor(_displayedIntensity).animationDuration);
  }

  @override
  void didUpdateWidget(covariant RainOverlay oldWidget) {
    super.didUpdateWidget(oldWidget);
    final nextIntensity = _resolveIntensity(widget);
    if (nextIntensity == _displayedIntensity) {
      return;
    }
    _displayedIntensity = nextIntensity;
    // Restart the loop with the new period, starting at its current value.
    _controller.repeat(period: _presetFor(nextIntensity).animationDuration);
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Positioned.fill(
      key: const ValueKey('rain-overlay'),
      child: IgnorePointer(
        child: CustomPaint(
          key: ValueKey('rain-overlay-intensity-${_displayedIntensity.name}'),
          painter: _RainPainter(
            animation: _controller,
            preset: _presetFor(_displayedIntensity),
          ),
        ),
      ),
    );
  }

  RainIntensity _resolveIntensity(RainOverlay widget) {
    return widget.intensityOverride ??
        (widget.isTutorialCompleted
            ? _selectedIntensity
            : RainIntensity.normal);
  }

  RainIntensity _selectIntensity() {
    switch (Random().nextInt(10)) {
      case < 3:
        return RainIntensity.light;
      case < 8:
        return RainIntensity.normal;
      default:
        return RainIntensity.heavy;
    }
  }
}

class _RainPainter extends CustomPainter {
  _RainPainter({required Animation<double> animation, required this._preset})
    : _animation = animation,
      super(repaint: animation);

  final Animation<double> _animation;
  final _RainPreset _preset;

  // Tracks start across the current room window. Their fixed phases keep the
  // deterministic drops from moving and wrapping as one sliding sheet.
  static const _normalDrops = <_RainDrop>[
    _RainDrop(topX: 0.48, phase: 0.03),
    _RainDrop(topX: 0.57, phase: 0.56),
    _RainDrop(topX: 0.66, phase: 0.21),
    _RainDrop(topX: 0.75, phase: 0.78),
    _RainDrop(topX: 0.82, phase: 0.40),
    _RainDrop(topX: 0.52, phase: 0.90),
    _RainDrop(topX: 0.62, phase: 0.68),
    _RainDrop(topX: 0.71, phase: 0.12),
    _RainDrop(topX: 0.80, phase: 0.49),
    _RainDrop(topX: 0.55, phase: 0.31),
    _RainDrop(topX: 0.68, phase: 0.84),
    _RainDrop(topX: 0.77, phase: 0.63),
  ];

  static const _lineVector = Offset(-4, 12);
  static const _windowTop = 0.035;
  static const _windowBottom = 0.435;

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = const Color(0xFFB9D9EA).withValues(alpha: _preset.opacity)
      ..strokeWidth = 1.5
      ..strokeCap = StrokeCap.round;

    for (final drop in _preset.drops) {
      final progress = (_animation.value + drop.phase) % 1;
      final top = size.height * _windowTop - _lineVector.dy;
      final bottom = size.height * _windowBottom;
      final travelY = bottom - top;
      final start = Offset(
        size.width * drop.topX - (travelY * progress / 3),
        top + travelY * progress,
      );
      canvas.drawLine(start, start + _lineVector * _preset.lengthScale, paint);
    }
  }

  @override
  bool shouldRepaint(covariant _RainPainter oldDelegate) =>
      oldDelegate._preset != _preset;
}

class _RainDrop {
  const _RainDrop({required this.topX, required this.phase});

  final double topX;
  final double phase;
}

class _RainPreset {
  const _RainPreset({
    required this.animationDuration,
    required this.drops,
    required this.opacity,
    required this.lengthScale,
  });

  final Duration animationDuration;
  final List<_RainDrop> drops;
  final double opacity;
  final double lengthScale;
}

const _lightPreset = _RainPreset(
  animationDuration: Duration(milliseconds: 4200),
  drops: [
    _RainDrop(topX: 0.48, phase: 0.03),
    _RainDrop(topX: 0.57, phase: 0.56),
    _RainDrop(topX: 0.66, phase: 0.21),
    _RainDrop(topX: 0.75, phase: 0.78),
    _RainDrop(topX: 0.52, phase: 0.90),
    _RainDrop(topX: 0.68, phase: 0.84),
  ],
  opacity: 0.50,
  lengthScale: 0.8,
);

const _normalPreset = _RainPreset(
  animationDuration: Duration(seconds: 3),
  drops: _RainPainter._normalDrops,
  opacity: 0.67,
  lengthScale: 1,
);

const _heavyPreset = _RainPreset(
  animationDuration: Duration(milliseconds: 2250),
  drops: [
    ..._RainPainter._normalDrops,
    _RainDrop(topX: 0.50, phase: 0.16),
    _RainDrop(topX: 0.60, phase: 0.73),
    _RainDrop(topX: 0.73, phase: 0.35),
    _RainDrop(topX: 0.85, phase: 0.94),
    _RainDrop(topX: 0.54, phase: 0.46),
    _RainDrop(topX: 0.64, phase: 0.08),
    _RainDrop(topX: 0.79, phase: 0.60),
    _RainDrop(topX: 0.88, phase: 0.27),
  ],
  opacity: 0.8,
  lengthScale: 1.25,
);

_RainPreset _presetFor(RainIntensity intensity) {
  return switch (intensity) {
    RainIntensity.light => _lightPreset,
    RainIntensity.normal => _normalPreset,
    RainIntensity.heavy => _heavyPreset,
  };
}
