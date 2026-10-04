import 'dart:math' as math;

import 'package:flutter/material.dart';

enum FurnitureReactionType { sway, gentleSway, rotate, rock, flowerSway }

const Map<String, FurnitureReactionType> _reactionTypesByFurnitureId = {
  'wind_chime': FurnitureReactionType.sway,
  'teru_teru_bozu': FurnitureReactionType.gentleSway,
  'moon_mobile': FurnitureReactionType.rotate,
  'rocking_chair': FurnitureReactionType.rock,
  'small_white_flower': FurnitureReactionType.flowerSway,
  'blue_violet_flower': FurnitureReactionType.flowerSway,
  'pale_yellow_flower': FurnitureReactionType.flowerSway,
};

FurnitureReactionType? furnitureReactionTypeFor(String furnitureId) {
  return _reactionTypesByFurnitureId[furnitureId];
}

class FurnitureReaction extends StatefulWidget {
  const FurnitureReaction({
    super.key,
    required this.furnitureId,
    required this.type,
    required this.child,
    this.duration,
  });

  final String furnitureId;
  final FurnitureReactionType type;
  final Widget child;
  final Duration? duration;

  @override
  FurnitureReactionState createState() => FurnitureReactionState();
}

class FurnitureReactionState extends State<FurnitureReaction>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: widget.duration ?? _durationFor(widget.type),
    );
  }

  void play() {
    _controller.forward(from: 0);
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      key: ValueKey('furnitureReaction-${widget.furnitureId}'),
      behavior: HitTestBehavior.translucent,
      onTap: play,
      child: AnimatedBuilder(
        animation: _controller,
        child: widget.child,
        builder: (context, child) {
          return Transform.rotate(
            key: ValueKey('furnitureReactionTransform-${widget.furnitureId}'),
            angle: _reactionAngle(widget.type, _controller.value),
            alignment: _pivotFor(widget.type),
            child: child,
          );
        },
      ),
    );
  }
}

Duration _durationFor(FurnitureReactionType type) {
  return switch (type) {
    FurnitureReactionType.sway => const Duration(milliseconds: 720),
    FurnitureReactionType.gentleSway => const Duration(milliseconds: 900),
    FurnitureReactionType.rotate => const Duration(milliseconds: 820),
    FurnitureReactionType.rock => const Duration(milliseconds: 900),
    FurnitureReactionType.flowerSway => const Duration(milliseconds: 760),
  };
}

Alignment _pivotFor(FurnitureReactionType type) {
  return switch (type) {
    FurnitureReactionType.sway ||
    FurnitureReactionType.gentleSway => Alignment.topCenter,
    FurnitureReactionType.rotate => Alignment.center,
    FurnitureReactionType.rock ||
    FurnitureReactionType.flowerSway => Alignment.bottomCenter,
  };
}

double _reactionAngle(FurnitureReactionType type, double progress) {
  final easedProgress = Curves.easeOut.transform(progress);
  final damping = 1 - easedProgress;
  final (maximumAngle, halfTurns) = switch (type) {
    FurnitureReactionType.sway => (0.055, 5.0),
    FurnitureReactionType.gentleSway => (0.040, 4.0),
    FurnitureReactionType.rotate => (0.090, 1.0),
    FurnitureReactionType.rock => (0.035, 5.0),
    FurnitureReactionType.flowerSway => (0.042, 4.0),
  };
  return math.sin(easedProgress * math.pi * halfTurns) * maximumAngle * damping;
}
