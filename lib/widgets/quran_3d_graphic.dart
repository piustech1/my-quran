import 'package:flutter/material.dart';
import '../constants/app_colors.dart';

class Quran3DGraphic extends StatelessWidget {
  final double width;
  final double height;

  const Quran3DGraphic({
    super.key,
    this.width = 90,
    this.height = 110,
  });

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: width,
      height: height,
      child: CustomPaint(
        painter: _Quran3DBookPainter(),
      ),
    );
  }
}

class _Quran3DBookPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final w = size.width;
    final h = size.height;

    // Soft drop shadow
    final shadowPaint = Paint()
      ..color = Colors.black.withOpacity(0.18)
      ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 8);
    final shadowPath = Path()
      ..moveTo(w * 0.15, h * 0.92)
      ..lineTo(w * 0.95, h * 0.92)
      ..lineTo(w * 0.85, h * 1.0)
      ..lineTo(w * 0.05, h * 1.0)
      ..close();
    canvas.drawPath(shadowPath, shadowPaint);

    // 1. Pages Block (the thickness of the book on right and bottom)
    final pagePaint = Paint()..color = const Color(0xFFF3ECE1);
    final pageEdgePaint = Paint()..color = const Color(0xFFE4D5BE);

    // Right pages depth
    final rightPagesPath = Path()
      ..moveTo(w * 0.82, h * 0.08)
      ..lineTo(w * 0.92, h * 0.16)
      ..lineTo(w * 0.92, h * 0.90)
      ..lineTo(w * 0.82, h * 0.84)
      ..close();
    canvas.drawPath(rightPagesPath, pageEdgePaint);

    // Bottom pages depth
    final bottomPagesPath = Path()
      ..moveTo(w * 0.18, h * 0.84)
      ..lineTo(w * 0.82, h * 0.84)
      ..lineTo(w * 0.92, h * 0.90)
      ..lineTo(w * 0.28, h * 0.90)
      ..close();
    canvas.drawPath(bottomPagesPath, pagePaint);

    // 2. Front Cover (Deep Greenish Slate with gold border)
    final coverPaint = Paint()..color = const Color(0xFF1E2F29);
    final coverPath = Path()
      ..moveTo(w * 0.18, h * 0.04)
      ..lineTo(w * 0.82, h * 0.08)
      ..lineTo(w * 0.82, h * 0.84)
      ..lineTo(w * 0.18, h * 0.80)
      ..close();
    canvas.drawPath(coverPath, coverPaint);

    // Gold decorative border on front cover
    final goldBorderPaint = Paint()
      ..color = AppColors.accentGold.withOpacity(0.85)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.6;
    final innerCoverPath = Path()
      ..moveTo(w * 0.23, h * 0.09)
      ..lineTo(w * 0.77, h * 0.125)
      ..lineTo(w * 0.77, h * 0.79)
      ..lineTo(w * 0.23, h * 0.75)
      ..close();
    canvas.drawPath(innerCoverPath, goldBorderPaint);

    // Center Gold Medallion on Cover
    final medallionCenter = Offset(w * 0.50, h * 0.44);
    final medallionPaint = Paint()
      ..color = AppColors.accentGold
      ..style = PaintingStyle.fill;
    canvas.drawCircle(medallionCenter, w * 0.15, medallionPaint);

    final innerCirclePaint = Paint()
      ..color = const Color(0xFF1E2F29)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.4;
    canvas.drawCircle(medallionCenter, w * 0.11, innerCirclePaint);

    // 3. Spine (Left 3D curve)
    final spinePaint = Paint()..color = const Color(0xFF14201C);
    final spinePath = Path()
      ..moveTo(w * 0.10, h * 0.10)
      ..lineTo(w * 0.18, h * 0.04)
      ..lineTo(w * 0.18, h * 0.80)
      ..lineTo(w * 0.10, h * 0.86)
      ..close();
    canvas.drawPath(spinePath, spinePaint);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
