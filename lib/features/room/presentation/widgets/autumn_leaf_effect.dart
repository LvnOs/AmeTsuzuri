import 'dart:async';
import 'dart:math' as math;

import 'package:flutter/material.dart';

class AutumnLeafEffect extends StatefulWidget {
  const AutumnLeafEffect({
    super.key,
    this.random,
    this.minInterval = const Duration(seconds: 18),
    this.maxInterval = const Duration(seconds: 32),
    this.fallDuration = const Duration(milliseconds: 5200),
  });

  final math.Random? random;
  final Duration minInterval;
  final Duration maxInterval;
  final Duration fallDuration;

  @override
  State<AutumnLeafEffect> createState() => _AutumnLeafEffectState();
}

class _AutumnLeafEffectState extends State<AutumnLeafEffect>
    with SingleTickerProviderStateMixin {
  static const _assetPath = 'assets/images/room/autumn_leaf.png';
  static const _leafWidthScale = 0.065;
  static const _startY = -0.08;
  static const _travelY = 0.53;
  static const _horizontalTravelScale = 0.08;

  late final math.Random _random;
  late final AnimationController _controller;
  Timer? _timer;
  bool _isLeafVisible = false;
  double _startX = 0.54;
  bool _driftsRight = true;

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
    _scheduleNextLeaf();
  }

  void _scheduleNextLeaf() {
    final minimum = widget.minInterval.inMilliseconds;
    final range = widget.maxInterval.inMilliseconds - minimum;
    final delay = Duration(
      milliseconds: minimum + (range == 0 ? 0 : _random.nextInt(range + 1)),
    );
    _timer = Timer(delay, _startLeafFall);
  }

  void _startLeafFall() {
    if (!mounted) {
      return;
    }
    _timer = null;
    setState(() {
      _startX = 0.52 + (_random.nextDouble() * 0.20);
      _driftsRight = _random.nextBool();
      _isLeafVisible = true;
    });
    _controller.forward(from: 0);
  }

  void _onAnimationStatusChanged(AnimationStatus status) {
    if (status != AnimationStatus.completed || !mounted) {
      return;
    }
    setState(() => _isLeafVisible = false);
    _scheduleNextLeaf();
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
      key: const ValueKey('autumnLeafEffect'),
      child: IgnorePointer(
        child: LayoutBuilder(
          builder: (context, constraints) {
            return AnimatedBuilder(
              animation: _controller,
              child: Image.asset(
                _assetPath,
                fit: BoxFit.contain,
              ),
              builder: (context, child) {
                if (!_isLeafVisible) {
                  return const SizedBox.expand();
                }

                final progress = Curves.easeInOutSine.transform(
                  _controller.value,
                );
                final leafWidth = constraints.maxWidth * _leafWidthScale;
                final drift =
                    constraints.maxWidth *
                    _horizontalTravelScale *
                    (_driftsRight ? 1 : -1);
                final opacity = _leafOpacity(progress);

                return Stack(
                  children: [
                    Positioned(
                      key: const ValueKey('autumnLeafImage'),
                      left: constraints.maxWidth * _startX + drift * progress,
                      top:
                          constraints.maxHeight *
                          (_startY + _travelY * progress),
                      width: leafWidth,
                      child: Opacity(
                        opacity: opacity,
                        child: Transform.rotate(
                          angle: -0.16 + (progress * 0.52),
                          child: child,
                        ),
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

double _leafOpacity(double progress) {
  if (progress < 0.06) {
    return progress / 0.06;
  }
  if (progress > 0.94) {
    return (1 - progress) / 0.06;
  }
  return 0.9;
}
