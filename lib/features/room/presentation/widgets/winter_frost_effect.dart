import 'package:flutter/material.dart';

class WinterFrostEffect extends StatelessWidget {
  const WinterFrostEffect({super.key});

  @override
  Widget build(BuildContext context) {
    return const Positioned.fill(
      key: ValueKey('winterFrostEffect'),
      child: IgnorePointer(
        child: CustomPaint(
          key: ValueKey('winterFrostPaint'),
          painter: _WinterFrostPainter(),
        ),
      ),
    );
  }
}

class _WinterFrostPainter extends CustomPainter {
  const _WinterFrostPainter();

  static const _frostPatches = <_FrostPatch>[
    _FrostPatch(0.25, 0.050, 0.13, 0.026),
    _FrostPatch(0.43, 0.047, 0.12, 0.020),
    _FrostPatch(0.62, 0.047, 0.15, 0.022),
    _FrostPatch(0.76, 0.055, 0.10, 0.032),
    _FrostPatch(0.20, 0.15, 0.030, 0.10),
    _FrostPatch(0.20, 0.32, 0.034, 0.11),
    _FrostPatch(0.81, 0.17, 0.030, 0.11),
    _FrostPatch(0.81, 0.34, 0.034, 0.10),
  ];

  static const _frostClusters = <_FrostCluster>[
    _FrostCluster(0.23, 0.048, 0.015),
    _FrostCluster(0.31, 0.041, 0.010),
    _FrostCluster(0.40, 0.047, 0.007),
    _FrostCluster(0.48, 0.043, 0.010),
    _FrostCluster(0.57, 0.046, 0.007),
    _FrostCluster(0.66, 0.043, 0.010),
    _FrostCluster(0.77, 0.052, 0.016),
    _FrostCluster(0.19, 0.10, 0.012),
    _FrostCluster(0.20, 0.16, 0.007),
    _FrostCluster(0.20, 0.22, 0.014),
    _FrostCluster(0.19, 0.30, 0.008),
    _FrostCluster(0.20, 0.37, 0.010),
    _FrostCluster(0.82, 0.11, 0.012),
    _FrostCluster(0.81, 0.17, 0.008),
    _FrostCluster(0.81, 0.25, 0.014),
    _FrostCluster(0.82, 0.32, 0.008),
    _FrostCluster(0.81, 0.39, 0.010),
  ];

  @override
  void paint(Canvas canvas, Size size) {
    final frostScale = size.width;
    final patchPaint = Paint()
      ..color = const Color(0x3ADCECF2)
      ..maskFilter = MaskFilter.blur(BlurStyle.normal, frostScale * 0.009);
    final clusterPaint = Paint()
      ..color = const Color(0x50E0EFF4)
      ..maskFilter = MaskFilter.blur(BlurStyle.normal, frostScale * 0.005);
    final branchPaint = Paint()
      ..color = const Color(0x70E8F5F8)
      ..strokeWidth = frostScale * 0.003
      ..strokeCap = StrokeCap.round
      ..style = PaintingStyle.stroke;

    for (final patch in _frostPatches) {
      canvas.drawOval(
        Rect.fromCenter(
          center: Offset(size.width * patch.x, size.height * patch.y),
          width: size.width * patch.width,
          height: size.height * patch.height,
        ),
        patchPaint,
      );
    }

    for (final cluster in _frostClusters) {
      canvas.drawCircle(
        Offset(size.width * cluster.x, size.height * cluster.y),
        frostScale * cluster.radius,
        clusterPaint,
      );
    }

    _drawTopBranch(canvas, size, branchPaint);
    _drawLeftBranch(canvas, size, branchPaint);
    _drawRightBranch(canvas, size, branchPaint);
  }

  void _drawTopBranch(Canvas canvas, Size size, Paint paint) {
    final path = Path()
      ..moveTo(size.width * 0.38, size.height * 0.042)
      ..lineTo(size.width * 0.39, size.height * 0.070)
      ..moveTo(size.width * 0.39, size.height * 0.058)
      ..lineTo(size.width * 0.37, size.height * 0.066)
      ..moveTo(size.width * 0.39, size.height * 0.061)
      ..lineTo(size.width * 0.41, size.height * 0.072)
      ..moveTo(size.width * 0.68, size.height * 0.042)
      ..lineTo(size.width * 0.67, size.height * 0.071)
      ..moveTo(size.width * 0.675, size.height * 0.058)
      ..lineTo(size.width * 0.65, size.height * 0.068)
      ..moveTo(size.width * 0.672, size.height * 0.062)
      ..lineTo(size.width * 0.69, size.height * 0.073);
    canvas.drawPath(path, paint);
  }

  void _drawLeftBranch(Canvas canvas, Size size, Paint paint) {
    final path = Path()
      ..moveTo(size.width * 0.19, size.height * 0.25)
      ..lineTo(size.width * 0.23, size.height * 0.27)
      ..moveTo(size.width * 0.21, size.height * 0.26)
      ..lineTo(size.width * 0.22, size.height * 0.24)
      ..moveTo(size.width * 0.22, size.height * 0.265)
      ..lineTo(size.width * 0.24, size.height * 0.25);
    canvas.drawPath(path, paint);
  }

  void _drawRightBranch(Canvas canvas, Size size, Paint paint) {
    final path = Path()
      ..moveTo(size.width * 0.82, size.height * 0.18)
      ..lineTo(size.width * 0.78, size.height * 0.20)
      ..moveTo(size.width * 0.80, size.height * 0.19)
      ..lineTo(size.width * 0.79, size.height * 0.17)
      ..moveTo(size.width * 0.79, size.height * 0.195)
      ..lineTo(size.width * 0.77, size.height * 0.18);
    canvas.drawPath(path, paint);
  }

  @override
  bool shouldRepaint(covariant _WinterFrostPainter oldDelegate) => false;
}

class _FrostPatch {
  const _FrostPatch(this.x, this.y, this.width, this.height);

  final double x;
  final double y;
  final double width;
  final double height;
}

class _FrostCluster {
  const _FrostCluster(this.x, this.y, this.radius);

  final double x;
  final double y;
  final double radius;
}
