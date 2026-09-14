import 'package:flutter/material.dart';
import '../model/letter.dart';

class LetterPage extends StatelessWidget {
  const LetterPage({super.key, required this.letter, this.rewardAmount});

  static const Color _pageBackgroundColor = Color(0xFFE5DDD0);
  static const Color _paperColor = Color(0xFFFFFAEC);
  static const Color _titleColor = Color(0xFF3F382F);
  static const Color _bodyColor = Color(0xFF494239);
  static const double _bodyFontSize = 16.5;
  static const double _ruleSpacing = 30;
  static const double _ruleStartOffset = 30;
  static const double _bodyHeight = _ruleSpacing / _bodyFontSize;
  static const TextStyle _bodyTextStyle = TextStyle(
    color: _bodyColor,
    fontSize: _bodyFontSize,
    height: _bodyHeight,
  );
  static const double _paperVerticalPadding = 32;
  static const double _titleLineHeight = 24 * 1.35;
  static const double _titleBodySpacing = 26;
  static const double _rewardFeedbackTopSpacing = 12;
  static const double _rewardFeedbackHeight = 32;

  final Letter letter;
  final int? rewardAmount;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: _pageBackgroundColor,
      appBar: AppBar(
        title: const Text('手紙'),
        backgroundColor: _pageBackgroundColor,
        foregroundColor: _titleColor,
        elevation: 0,
        scrolledUnderElevation: 0,
        surfaceTintColor: Colors.transparent,
      ),
      body: SafeArea(
        child: LayoutBuilder(
          builder: (context, constraints) {
            const horizontalPadding = 16.0;
            const topPadding = 16.0;
            const bottomPadding = 32.0;
            final minimumPaperHeight =
                (constraints.maxHeight - topPadding - bottomPadding)
                    .clamp(0.0, double.infinity)
                    .toDouble();
            final rewardFeedbackHeight = rewardAmount == null
                ? 0.0
                : _rewardFeedbackTopSpacing + _rewardFeedbackHeight;
            final minimumRuledAreaHeight =
                (minimumPaperHeight -
                        (_paperVerticalPadding * 2) -
                        _titleLineHeight -
                        rewardFeedbackHeight -
                        _titleBodySpacing)
                    .clamp(0.0, double.infinity)
                    .toDouble();

            return SingleChildScrollView(
              padding: const EdgeInsets.fromLTRB(
                horizontalPadding,
                topPadding,
                horizontalPadding,
                bottomPadding,
              ),
              child: Center(
                child: ConstrainedBox(
                  key: const ValueKey('letterContent'),
                  constraints: BoxConstraints(
                    maxWidth: 640,
                    minHeight: minimumPaperHeight,
                  ),
                  child: Container(
                    key: const ValueKey('letterPaper'),
                    width: double.infinity,
                    padding: const EdgeInsets.symmetric(
                      horizontal: 24,
                      vertical: _paperVerticalPadding,
                    ),
                    decoration: BoxDecoration(
                      color: _paperColor,
                      borderRadius: BorderRadius.circular(4),
                      boxShadow: const [
                        BoxShadow(
                          color: Color(0x263D342B),
                          blurRadius: 24,
                          offset: Offset(0, 6),
                        ),
                      ],
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          letter.title,
                          style: const TextStyle(
                            color: _titleColor,
                            fontSize: 24,
                            fontWeight: FontWeight.w600,
                            height: 1.35,
                          ),
                        ),
                        if (rewardAmount != null) ...[
                          const SizedBox(height: _rewardFeedbackTopSpacing),
                          SizedBox(
                            height: _rewardFeedbackHeight,
                            child: Align(
                              alignment: Alignment.centerLeft,
                              child: _DropRewardFeedback(amount: rewardAmount!),
                            ),
                          ),
                        ],
                        const SizedBox(height: _titleBodySpacing),
                        CustomPaint(
                          key: const ValueKey('letterRules'),
                          painter: const _LetterRulesPainter(
                            color: Color(0x1F8A8175),
                            spacing: _ruleSpacing,
                            startOffset: _ruleStartOffset,
                          ),
                          child: ConstrainedBox(
                            constraints: BoxConstraints(
                              minHeight: minimumRuledAreaHeight,
                            ),
                            child: SizedBox(
                              width: double.infinity,
                              child: Text(
                                letter.body,
                                style: _bodyTextStyle,
                                strutStyle: const StrutStyle(
                                  fontSize: _bodyFontSize,
                                  height: _bodyHeight,
                                  forceStrutHeight: true,
                                ),
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            );
          },
        ),
      ),
    );
  }
}

class _DropRewardFeedback extends StatefulWidget {
  const _DropRewardFeedback({required this.amount});

  final int amount;

  @override
  State<_DropRewardFeedback> createState() => _DropRewardFeedbackState();
}

class _DropRewardFeedbackState extends State<_DropRewardFeedback>
    with SingleTickerProviderStateMixin {
  static const Duration _duration = Duration(milliseconds: 3500);

  late final AnimationController _controller;
  late final Animation<double> _opacity;
  late final Animation<Offset> _offset;
  bool _isVisible = true;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(vsync: this, duration: _duration)
      ..addStatusListener(_handleStatus)
      ..forward();
    _opacity = TweenSequence<double>([
      TweenSequenceItem(
        tween: Tween<double>(
          begin: 0,
          end: 1,
        ).chain(CurveTween(curve: Curves.easeOut)),
        weight: 10,
      ),
      TweenSequenceItem(tween: ConstantTween(1), weight: 65),
      TweenSequenceItem(
        tween: Tween<double>(
          begin: 1,
          end: 0,
        ).chain(CurveTween(curve: Curves.easeIn)),
        weight: 25,
      ),
    ]).animate(_controller);
    _offset = Tween<Offset>(
      begin: const Offset(0, 0.04),
      end: const Offset(0, -0.04),
    ).animate(CurvedAnimation(parent: _controller, curve: Curves.easeOut));
  }

  void _handleStatus(AnimationStatus status) {
    if (status == AnimationStatus.completed && mounted) {
      setState(() => _isVisible = false);
    }
  }

  @override
  void dispose() {
    _controller
      ..removeStatusListener(_handleStatus)
      ..dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (!_isVisible) {
      return const SizedBox.shrink();
    }

    return FadeTransition(
      opacity: _opacity,
      child: SlideTransition(
        position: _offset,
        child: Semantics(
          liveRegion: true,
          label: '雫を${widget.amount}滴受け取りました',
          child: ExcludeSemantics(
            child: Row(
              key: const ValueKey('dropRewardFeedback'),
              mainAxisSize: MainAxisSize.min,
              children: [
                const Icon(
                  Icons.water_drop_outlined,
                  size: 18,
                  color: Color(0xFF5796AD),
                ),
                const SizedBox(width: 6),
                Text(
                  '雫を${widget.amount}滴受け取りました',
                  style: const TextStyle(
                    color: Color(0xFF477F94),
                    fontSize: 14.5,
                    fontWeight: FontWeight.w600,
                    letterSpacing: 0.2,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _LetterRulesPainter extends CustomPainter {
  const _LetterRulesPainter({
    required this.color,
    required this.spacing,
    required this.startOffset,
  });

  final Color color;
  final double spacing;
  final double startOffset;

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = color
      ..strokeWidth = 0.8;

    for (var y = startOffset; y < size.height; y += spacing) {
      canvas.drawLine(Offset(0, y), Offset(size.width, y), paint);
    }
  }

  @override
  bool shouldRepaint(covariant _LetterRulesPainter oldDelegate) {
    return color != oldDelegate.color ||
        spacing != oldDelegate.spacing ||
        startOffset != oldDelegate.startOffset;
  }
}
