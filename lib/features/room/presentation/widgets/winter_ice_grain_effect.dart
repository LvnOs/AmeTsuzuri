import 'dart:async';
import 'dart:math' as math;

import 'package:flutter/material.dart';

class WinterIceGrainEffect extends StatefulWidget {
  const WinterIceGrainEffect({
    super.key,
    this.random,
    this.minInterval = const Duration(seconds: 15),
    this.maxInterval = const Duration(seconds: 30),
    this.fallDuration = const Duration(milliseconds: 3200),
  });

  final math.Random? random;
  final Duration minInterval;
  final Duration maxInterval;
  final Duration fallDuration;

  @override
  State<WinterIceGrainEffect> createState() => _WinterIceGrainEffectState();
}

class _WinterIceGrainEffectState extends State<WinterIceGrainEffect>
    with SingleTickerProviderStateMixin {
  static const _grainWidthScale = 0.014;
  static const _grainHeightRatio = 0.78;
  static const _verticalTravelScale = 0.28;
  static const _horizontalTravelScale = 0.04;
  static const _startRegions = <_IceGrainStartRegion>[
    _IceGrainStartRegion(minX: 0.25, maxX: 0.36, minY: 0.07, maxY: 0.12),
    _IceGrainStartRegion(minX: 0.65, maxX: 0.77, minY: 0.06, maxY: 0.11),
  ];

  late final math.Random _random;
  late final AnimationController _controller;
  Timer? _timer;
  bool _isGrainVisible = false;
  double _startX = 0.30;
  double _startY = 0.08;
  bool _peelsRight = true;

  @override
  void initState() {
    super.initState();
    assert(!widget.minInterval.isNegative);
    assert(widget.maxInterval >= widget.minInterval);
    assert(widget.fallDuration > Duration.zero);
    _random = widget.random ?? math.Random();
    _controller = AnimationController(
      vsync: this,
      duration: widget.fallDuration,
    )..addStatusListener(_onAnimationStatusChanged);
    _scheduleNextGrain();
  }

  void _scheduleNextGrain() {
    final minimum = widget.minInterval.inMilliseconds;
    final range = widget.maxInterval.inMilliseconds - minimum;
    final delay = Duration(
      milliseconds: minimum + (range == 0 ? 0 : _random.nextInt(range + 1)),
    );
    _timer = Timer(delay, _startGrainFall);
  }

  void _startGrainFall() {
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
      _peelsRight = _random.nextBool();
      _isGrainVisible = true;
    });
    _controller.forward(from: 0);
  }

  void _onAnimationStatusChanged(AnimationStatus status) {
    if (status != AnimationStatus.completed || !mounted) {
      return;
    }
    setState(() => _isGrainVisible = false);
    _scheduleNextGrain();
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
      key: const ValueKey('winterIceGrainEffect'),
      child: IgnorePointer(
        child: LayoutBuilder(
          builder: (context, constraints) {
            return AnimatedBuilder(
              animation: _controller,
              child: const CustomPaint(
                key: ValueKey('winterIceGrainPaint'),
                painter: _IceGrainPainter(),
              ),
              builder: (context, child) {
                if (!_isGrainVisible) {
                  return const SizedBox.expand();
                }

                final fallProgress = Curves.easeInQuad.transform(
                  _controller.value,
                );
                final peelProgress = const Interval(
                  0,
                  0.32,
                  curve: Curves.easeOutCubic,
                ).transform(_controller.value);
                final grainWidth = constraints.maxWidth * _grainWidthScale;
                final peel =
                    constraints.maxWidth *
                    _horizontalTravelScale *
                    (_peelsRight ? 1 : -1);

                return Stack(
                  children: [
                    Positioned(
                      key: const ValueKey('winterIceGrainParticle'),
                      left:
                          constraints.maxWidth * _startX + peel * peelProgress,
                      top:
                          constraints.maxHeight *
                          (_startY + _verticalTravelScale * fallProgress),
                      width: grainWidth,
                      height: grainWidth * _grainHeightRatio,
                      child: Opacity(
                        opacity: _grainOpacity(_controller.value),
                        child: child,
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

double _grainOpacity(double progress) {
  const maximumOpacity = 0.90;
  if (progress < 0.12) {
    return maximumOpacity * progress / 0.12;
  }
  if (progress > 0.70) {
    return maximumOpacity * (1 - progress) / 0.30;
  }
  return maximumOpacity;
}

class _IceGrainPainter extends CustomPainter {
  const _IceGrainPainter();

  @override
  void paint(Canvas canvas, Size size) {
    final grainPath = Path()
      ..moveTo(size.width * 0.08, size.height * 0.38)
      ..lineTo(size.width * 0.28, size.height * 0.06)
      ..lineTo(size.width * 0.62, 0)
      ..lineTo(size.width * 0.94, size.height * 0.26)
      ..lineTo(size.width * 0.82, size.height * 0.62)
      ..lineTo(size.width * 0.55, size.height * 0.92)
      ..lineTo(size.width * 0.20, size.height * 0.78)
      ..close();

    canvas.drawPath(grainPath, Paint()..color = const Color(0xFFF2F4F0));
    canvas.drawPath(
      grainPath,
      Paint()
        ..color = const Color(0xFFCAD8DC)
        ..strokeWidth = size.width * 0.07
        ..style = PaintingStyle.stroke
        ..strokeJoin = StrokeJoin.round,
    );
  }

  @override
  bool shouldRepaint(covariant _IceGrainPainter oldDelegate) => false;
}

class _IceGrainStartRegion {
  const _IceGrainStartRegion({
    required this.minX,
    required this.maxX,
    required this.minY,
    required this.maxY,
  });

  final double minX;
  final double maxX;
  final double minY;
  final double maxY;
}
