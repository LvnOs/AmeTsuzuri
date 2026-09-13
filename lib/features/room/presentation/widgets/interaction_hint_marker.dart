import 'dart:math' as math;

import 'package:flutter/material.dart';

/// A quiet, non-interactive indication that a room object can be touched.
///
/// The marker owns its animation so a Room rebuild does not drive its frame
/// updates. It is intentionally reusable for future interactive objects.
class InteractionHintMarker extends StatefulWidget {
  const InteractionHintMarker({super.key, this.size = defaultSize});

  static const double defaultSize = 30;
  static const Duration animationDuration = Duration(milliseconds: 2200);

  final double size;

  @visibleForTesting
  static double opacityForProgress(double progress) {
    final wave = (math.sin(progress * math.pi * 2) + 1) / 2;
    return 0.72 + wave * 0.20;
  }

  @visibleForTesting
  static double verticalOffsetForProgress(double progress) =>
      math.sin(progress * math.pi * 2) * 2;

  @override
  State<InteractionHintMarker> createState() => _InteractionHintMarkerState();
}

class _InteractionHintMarkerState extends State<InteractionHintMarker>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: InteractionHintMarker.animationDuration,
    )..repeat();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return IgnorePointer(
      child: SizedBox.square(
        dimension: widget.size,
        child: CustomPaint(
          painter: _InteractionHintMarkerPainter(animation: _controller),
        ),
      ),
    );
  }
}

class _InteractionHintMarkerPainter extends CustomPainter {
  const _InteractionHintMarkerPainter({required this.animation})
    : super(repaint: animation);

  final Animation<double> animation;

  @override
  void paint(Canvas canvas, Size size) {
    final progress = animation.value;
    final opacity = InteractionHintMarker.opacityForProgress(progress);
    final offset = InteractionHintMarker.verticalOffsetForProgress(progress);
    final path = _dropPath(size, offset);

    final glowPaint = Paint()
      ..color = const Color(0xFFC7E6F0).withValues(alpha: opacity * 0.14)
      ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 3);
    canvas.drawPath(path, glowPaint);

    final dropPaint = Paint()
      ..shader = LinearGradient(
        begin: Alignment.topCenter,
        end: Alignment.bottomCenter,
        colors: [
          const Color(0xFFF2FAFC).withValues(alpha: opacity),
          const Color(0xFFB8DAE7).withValues(alpha: opacity),
        ],
      ).createShader(Offset.zero & size);
    canvas.drawPath(path, dropPaint);

    final highlight = Paint()
      ..color = const Color(0xFFEAF8FC).withValues(alpha: opacity * 0.60)
      ..strokeCap = StrokeCap.round
      ..strokeWidth = size.width * 0.075;
    canvas.drawLine(
      Offset(size.width * 0.43, size.height * 0.46 + offset),
      Offset(size.width * 0.40, size.height * 0.59 + offset),
      highlight,
    );
  }

  Path _dropPath(Size size, double offset) {
    final width = size.width;
    final height = size.height;
    final centerX = width / 2;
    final top = height * 0.055 + offset;
    final bottom = height * 0.90 + offset;

    return Path()
      ..moveTo(centerX, top)
      ..cubicTo(
        width * 0.35,
        height * 0.31 + offset,
        width * 0.23,
        height * 0.54 + offset,
        width * 0.23,
        height * 0.67 + offset,
      )
      ..cubicTo(
        width * 0.23,
        height * 0.82 + offset,
        width * 0.35,
        bottom,
        centerX,
        bottom,
      )
      ..cubicTo(
        width * 0.65,
        bottom,
        width * 0.77,
        height * 0.82 + offset,
        width * 0.77,
        height * 0.67 + offset,
      )
      ..cubicTo(
        width * 0.77,
        height * 0.54 + offset,
        width * 0.65,
        height * 0.31 + offset,
        centerX,
        top,
      )
      ..close();
  }

  @override
  bool shouldRepaint(covariant _InteractionHintMarkerPainter oldDelegate) =>
      false;
}
