import 'package:flutter/material.dart';

class RainOverlay extends StatelessWidget {
  const RainOverlay({super.key});

  @override
  Widget build(BuildContext context) {
    return const Positioned.fill(
      key: ValueKey('rain-overlay'),
      child: IgnorePointer(child: CustomPaint(painter: _RainPainter())),
    );
  }
}

class _RainPainter extends CustomPainter {
  const _RainPainter();

  static const _drops = <Offset>[
    Offset(0.34, 0.10),
    Offset(0.39, 0.18),
    Offset(0.45, 0.08),
    Offset(0.50, 0.23),
    Offset(0.56, 0.13),
    Offset(0.61, 0.28),
    Offset(0.36, 0.35),
    Offset(0.43, 0.43),
    Offset(0.49, 0.34),
    Offset(0.55, 0.48),
    Offset(0.62, 0.39),
  ];

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = const Color(0xFFB9D9EA).withValues(alpha: 0.7)
      ..strokeWidth = 1.5
      ..strokeCap = StrokeCap.round;

    for (final drop in _drops) {
      final start = Offset(size.width * drop.dx, size.height * drop.dy);
      canvas.drawLine(start, start + const Offset(-4, 12), paint);
    }
  }

  @override
  bool shouldRepaint(covariant _RainPainter oldDelegate) => false;
}
