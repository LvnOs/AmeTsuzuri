import 'package:flutter/material.dart';

class RainOverlay extends StatefulWidget {
  const RainOverlay({super.key});

  @override
  State<RainOverlay> createState() => _RainOverlayState();
}

class _RainOverlayState extends State<RainOverlay>
    with SingleTickerProviderStateMixin {
  static const _animationDuration = Duration(seconds: 4);

  late final AnimationController _controller;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(vsync: this, duration: _animationDuration)
      ..repeat();
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
        child: CustomPaint(painter: _RainPainter(animation: _controller)),
      ),
    );
  }
}

class _RainPainter extends CustomPainter {
  _RainPainter({required Animation<double> animation})
    : _animation = animation,
      super(repaint: animation);

  final Animation<double> _animation;

  // Tracks start across the current room window. Their fixed phases keep the
  // deterministic drops from moving and wrapping as one sliding sheet.
  static const _drops = <_RainDrop>[
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
      ..color = const Color(0xFFB9D9EA).withValues(alpha: 0.7)
      ..strokeWidth = 1.5
      ..strokeCap = StrokeCap.round;

    for (final drop in _drops) {
      final progress = (_animation.value + drop.phase) % 1;
      final top = size.height * _windowTop - _lineVector.dy;
      final bottom = size.height * _windowBottom;
      final travelY = bottom - top;
      final start = Offset(
        size.width * drop.topX - (travelY * progress / 3),
        top + travelY * progress,
      );
      canvas.drawLine(start, start + _lineVector, paint);
    }
  }

  @override
  bool shouldRepaint(covariant _RainPainter oldDelegate) => false;
}

class _RainDrop {
  const _RainDrop({required this.topX, required this.phase});

  final double topX;
  final double phase;
}
