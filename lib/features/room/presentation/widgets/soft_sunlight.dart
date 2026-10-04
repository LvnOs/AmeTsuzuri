import 'package:flutter/material.dart';

class SoftSunlight extends StatelessWidget {
  const SoftSunlight({super.key});

  @override
  Widget build(BuildContext context) {
    return const Positioned.fill(
      key: ValueKey('softSunlight'),
      child: IgnorePointer(
        child: Stack(
          fit: StackFit.expand,
          children: [
            Align(
              alignment: Alignment.topCenter,
              child: FractionallySizedBox(
                widthFactor: 0.80,
                heightFactor: 0.52,
                child: DecoratedBox(
                  key: ValueKey('softSunlightWindowGlow'),
                  decoration: BoxDecoration(
                    gradient: RadialGradient(
                      center: Alignment(0, -0.58),
                      radius: 1.08,
                      colors: [
                        Color(0x3AFFF8E8),
                        Color(0x24FFF9ED),
                        Color(0x0BFFFCF7),
                        Color(0x00FFFFFF),
                      ],
                      stops: [0, 0.34, 0.72, 1],
                    ),
                  ),
                ),
              ),
            ),
            Align(
              alignment: Alignment(0, -0.02),
              child: FractionallySizedBox(
                widthFactor: 0.68,
                heightFactor: 0.42,
                child: DecoratedBox(
                  key: ValueKey('softSunlightInteriorGlow'),
                  decoration: BoxDecoration(
                    gradient: RadialGradient(
                      center: Alignment(-0.04, -0.18),
                      radius: 0.86,
                      colors: [
                        Color(0x36FFE9C2),
                        Color(0x20FFF0D3),
                        Color(0x0AFFF7E6),
                        Color(0x00FFFFFF),
                      ],
                      stops: [0, 0.22, 0.58, 1],
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
