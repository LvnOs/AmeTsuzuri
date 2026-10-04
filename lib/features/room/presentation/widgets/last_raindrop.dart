import 'package:flutter/material.dart';

class LastRaindrop extends StatefulWidget {
  const LastRaindrop({
    super.key,
    this.fallDuration = const Duration(milliseconds: 2200),
  });

  final Duration fallDuration;

  @override
  State<LastRaindrop> createState() => _LastRaindropState();
}

class _LastRaindropState extends State<LastRaindrop>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;
  bool _isVisible = true;

  @override
  void initState() {
    super.initState();
    assert(widget.fallDuration > Duration.zero);
    _controller = AnimationController(
      vsync: this,
      duration: widget.fallDuration,
    )..addStatusListener(_onAnimationStatusChanged);
    _controller.forward();
  }

  void _onAnimationStatusChanged(AnimationStatus status) {
    if (status == AnimationStatus.completed && mounted) {
      setState(() => _isVisible = false);
    }
  }

  @override
  void dispose() {
    _controller
      ..removeStatusListener(_onAnimationStatusChanged)
      ..dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Positioned.fill(
      key: const ValueKey('lastRaindrop'),
      child: IgnorePointer(
        child: LayoutBuilder(
          builder: (context, constraints) {
            return AnimatedBuilder(
              animation: _controller,
              builder: (context, child) {
                if (!_isVisible) {
                  return const SizedBox.expand();
                }

                final progress = Curves.easeIn.transform(_controller.value);
                final opacity = _dropOpacity(progress);
                return Align(
                  alignment: const Alignment(0.40, -0.62),
                  child: Transform.translate(
                    key: const ValueKey('lastRaindropDrop'),
                    offset: Offset(0, constraints.maxHeight * 0.16 * progress),
                    child: Opacity(
                      opacity: opacity,
                      child: const CustomPaint(
                        key: ValueKey('lastRaindropPaint'),
                        size: Size(7, 12),
                        painter: _LastRaindropPainter(),
                      ),
                    ),
                  ),
                );
              },
            );
          },
        ),
      ),
    );
  }
}

double _dropOpacity(double progress) {
  if (progress < 0.12) {
    return progress / 0.12;
  }
  if (progress > 0.82) {
    return (1 - progress) / 0.18;
  }
  return 0.58;
}

class _LastRaindropPainter extends CustomPainter {
  const _LastRaindropPainter();

  @override
  void paint(Canvas canvas, Size size) {
    final path = Path()
      ..moveTo(size.width / 2, 0)
      ..cubicTo(
        size.width * 0.38,
        size.height * 0.28,
        0,
        size.height * 0.58,
        0,
        size.height * 0.72,
      )
      ..cubicTo(
        0,
        size.height,
        size.width,
        size.height,
        size.width,
        size.height * 0.72,
      )
      ..cubicTo(
        size.width,
        size.height * 0.58,
        size.width * 0.62,
        size.height * 0.28,
        size.width / 2,
        0,
      )
      ..close();

    canvas.drawPath(
      path,
      Paint()
        ..color = const Color(0xD8A4C1D0)
        ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 0.65),
    );
    canvas.drawCircle(
      Offset(size.width * 0.36, size.height * 0.58),
      size.width * 0.08,
      Paint()..color = const Color(0x66E8F0F2),
    );
  }

  @override
  bool shouldRepaint(covariant _LastRaindropPainter oldDelegate) => false;
}
