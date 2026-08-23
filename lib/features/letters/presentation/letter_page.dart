import 'package:flutter/material.dart';
import '../model/letter.dart';

class LetterPage extends StatelessWidget {
  const LetterPage({super.key, required this.letter});

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

  final Letter letter;

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
                (constraints.maxHeight - topPadding - bottomPadding).clamp(
                  0.0,
                  double.infinity,
                ).toDouble();
            final minimumRuledAreaHeight =
                (minimumPaperHeight -
                        (_paperVerticalPadding * 2) -
                        _titleLineHeight -
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
