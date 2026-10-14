import 'dart:async';
import 'dart:math' as math;

import 'package:flutter/material.dart';

class SpringPetalDriftEffect extends StatefulWidget {
  const SpringPetalDriftEffect({
    super.key,
    this.random,
    this.minInterval = const Duration(seconds: 24),
    this.maxInterval = const Duration(seconds: 42),
    this.driftDuration = const Duration(milliseconds: 3400),
  });

  final math.Random? random;
  final Duration minInterval;
  final Duration maxInterval;
  final Duration driftDuration;

  @override
  State<SpringPetalDriftEffect> createState() => _SpringPetalDriftEffectState();
}

class _SpringPetalDriftEffectState extends State<SpringPetalDriftEffect>
    with SingleTickerProviderStateMixin {
  static const _petalWidthScale = 0.030;
  static const _petalHeightRatio = 0.58;
  static const _horizontalTravelScale = 0.11;
  static const _verticalTravelScale = 0.055;
  static const _arcHeightScale = 0.018;
  static const _startRegions = <_PetalStartRegion>[
    _PetalStartRegion(
      minX: 0.20,
      maxX: 0.27,
      minY: 0.13,
      maxY: 0.29,
      direction: 1,
    ),
    _PetalStartRegion(
      minX: 0.73,
      maxX: 0.80,
      minY: 0.13,
      maxY: 0.29,
      direction: -1,
    ),
  ];

  late final math.Random _random;
  late final AnimationController _controller;
  Timer? _timer;
  bool _isPetalVisible = false;
  double _startX = 0.23;
  double _startY = 0.18;
  double _direction = 1;
  double _tiltDirection = 1;

  @override
  void initState() {
    super.initState();
    assert(!widget.minInterval.isNegative);
    assert(widget.maxInterval >= widget.minInterval);
    assert(widget.driftDuration > Duration.zero);
    _random = widget.random ?? math.Random();
    _controller = AnimationController(
      vsync: this,
      duration: widget.driftDuration,
    )..addStatusListener(_onAnimationStatusChanged);
    _scheduleNextPetal();
  }

  void _scheduleNextPetal() {
    final minimum = widget.minInterval.inMilliseconds;
    final range = widget.maxInterval.inMilliseconds - minimum;
    final delay = Duration(
      milliseconds: minimum + (range == 0 ? 0 : _random.nextInt(range + 1)),
    );
    _timer = Timer(delay, _startPetalDrift);
  }

  void _startPetalDrift() {
    if (!mounted) {
      return;
    }
    _timer = null;
    final region = _startRegions[_random.nextInt(_startRegions.length)];
    setState(() {
      _startX =
          region.minX + _random.nextDouble() * (region.maxX - region.minX);
      _startY =
          region.minY + _random.nextDouble() * (region.maxY - region.minY);
      _direction = region.direction;
      _tiltDirection = _random.nextBool() ? 1 : -1;
      _isPetalVisible = true;
    });
    _controller.forward(from: 0);
  }

  void _onAnimationStatusChanged(AnimationStatus status) {
    if (status != AnimationStatus.completed || !mounted) {
      return;
    }
    setState(() => _isPetalVisible = false);
    _scheduleNextPetal();
  }

  @override
  void dispose() {
    _timer?.cancel();
    _controller
      ..removeStatusListener(_onAnimationStatusChanged)
      ..dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Positioned.fill(
      key: const ValueKey('springPetalDriftEffect'),
      child: IgnorePointer(
        child: LayoutBuilder(
          builder: (context, constraints) {
            return AnimatedBuilder(
              animation: _controller,
              child: const CustomPaint(
                key: ValueKey('springPetalPaint'),
                painter: _SpringPetalPainter(),
              ),
              builder: (context, child) {
                if (!_isPetalVisible) {
                  return const SizedBox.expand();
                }

                final progress = _controller.value;
                final driftProgress = Curves.easeInOutCubic.transform(progress);
                final petalWidth = constraints.maxWidth * _petalWidthScale;
                final horizontalTravel =
                    constraints.maxWidth * _horizontalTravelScale * _direction;
                final arc = math.sin(progress * math.pi) * _arcHeightScale;
                final angle =
                    _tiltDirection *
                    (-0.10 + 0.22 * Curves.easeInOut.transform(progress));

                return Stack(
                  children: [
                    Positioned(
                      key: const ValueKey('springPetalParticle'),
                      left:
                          constraints.maxWidth * _startX +
                          horizontalTravel * driftProgress,
                      top:
                          constraints.maxHeight *
                          (_startY +
                              _verticalTravelScale * driftProgress -
                              arc),
                      width: petalWidth,
                      height: petalWidth * _petalHeightRatio,
                      child: Opacity(
                        opacity: _petalOpacity(progress),
                        child: Transform.rotate(angle: angle, child: child),
                      ),
                    ),
                  ],
                );
              },
            );
          },
        ),
      ),
    );
  }
}

double _petalOpacity(double progress) {
  const maximumOpacity = 0.70;
  if (progress < 0.12) {
    return maximumOpacity * progress / 0.12;
  }
  if (progress > 0.72) {
    return maximumOpacity * (1 - progress) / 0.28;
  }
  return maximumOpacity;
}

class _SpringPetalPainter extends CustomPainter {
  const _SpringPetalPainter();

  @override
  void paint(Canvas canvas, Size size) {
    final petalPath = Path()
      ..moveTo(size.width * 0.04, size.height * 0.56)
      ..cubicTo(
        size.width * 0.14,
        size.height * 0.20,
        size.width * 0.47,
        size.height * 0.04,
        size.width * 0.82,
        size.height * 0.16,
      )
      ..cubicTo(
        size.width * 0.99,
        size.height * 0.22,
        size.width * 0.99,
        size.height * 0.38,
        size.width * 0.80,
        size.height * 0.48,
      )
      ..cubicTo(
        size.width * 0.76,
        size.height * 0.50,
        size.width * 0.77,
        size.height * 0.54,
        size.width * 0.82,
        size.height * 0.56,
      )
      ..cubicTo(
        size.width * 0.99,
        size.height * 0.68,
        size.width * 0.87,
        size.height * 0.82,
        size.width * 0.73,
        size.height * 0.86,
      )
      ..cubicTo(
        size.width * 0.39,
        size.height * 0.95,
        size.width * 0.13,
        size.height * 0.84,
        size.width * 0.04,
        size.height * 0.56,
      )
      ..close();

    canvas.drawPath(petalPath, Paint()..color = const Color(0xFFF5F0DC));
    canvas.save();
    canvas.clipPath(petalPath);
    final paleGreenFace = Path()
      ..moveTo(size.width * 0.16, size.height * 0.66)
      ..quadraticBezierTo(
        size.width * 0.54,
        size.height * 0.43,
        size.width,
        size.height * 0.36,
      )
      ..lineTo(size.width, size.height)
      ..lineTo(0, size.height)
      ..close();
    canvas.drawPath(paleGreenFace, Paint()..color = const Color(0xFFE6E8C9));
    canvas.restore();
    canvas.drawPath(
      petalPath,
      Paint()
        ..color = const Color(0x99D9D9BB)
        ..strokeWidth = size.height * 0.08
        ..style = PaintingStyle.stroke
        ..strokeJoin = StrokeJoin.round,
    );
    canvas.drawLine(
      Offset(size.width * 0.18, size.height * 0.59),
      Offset(size.width * 0.63, size.height * 0.46),
      Paint()
        ..color = const Color(0xA6BCC78C)
        ..strokeWidth = size.height * 0.09
        ..strokeCap = StrokeCap.round,
    );
  }

  @override
  bool shouldRepaint(covariant _SpringPetalPainter oldDelegate) => false;
}

class _PetalStartRegion {
  const _PetalStartRegion({
    required this.minX,
    required this.maxX,
    required this.minY,
    required this.maxY,
    required this.direction,
  });

  final double minX;
  final double maxX;
  final double minY;
  final double maxY;
  final double direction;
}
