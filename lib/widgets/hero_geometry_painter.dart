import 'dart:math' as math;
import 'package:flutter/material.dart';
import '../theme/tokens.dart';

class HeroGeometryPainter extends CustomPainter {
  const HeroGeometryPainter();

  @override
  void paint(Canvas canvas, Size size) {
    final w = size.width;
    final h = size.height;

    // 1. Soft gold radial glow in the center upper hero
    final glowPaint = Paint()
      ..shader = RadialGradient(
        colors: [
          NoorColors.goldBright.withOpacity(0.32),
          NoorColors.goldBright.withOpacity(0.0),
        ],
        stops: const [0.0, 1.0],
      ).createShader(
        Rect.fromCenter(
          center: Offset(w / 2, h * 0.40),
          width: w * 0.95,
          height: h * 0.85,
        ),
      );
    canvas.drawOval(
      Rect.fromCenter(
        center: Offset(w / 2, h * 0.40),
        width: w * 0.95,
        height: h * 0.85,
      ),
      glowPaint,
    );

    // 2. Faint 8-point geometric star lattice pattern
    final starPaint = Paint()
      ..color = NoorColors.gold.withOpacity(0.18)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 0.7;

    const cellSize = 56.0;
    final cols = (w / cellSize).ceil() + 1;
    final rows = (h / cellSize).ceil() + 1;

    for (int r = 0; r < rows; r++) {
      for (int c = 0; c < cols; c++) {
        final cx = c * cellSize + 28.0;
        final cy = r * cellSize + 28.0;

        // Draw primary square (24x24)
        canvas.drawRect(
          Rect.fromCenter(center: Offset(cx, cy), width: 24, height: 24),
          starPaint,
        );

        // Draw 45-degree rotated square (forming the 8-point star rosette)
        canvas.save();
        canvas.translate(cx, cy);
        canvas.rotate(math.pi / 4);
        canvas.drawRect(
          Rect.fromCenter(center: Offset.zero, width: 24, height: 24),
          starPaint,
        );
        canvas.restore();

        // Inner circle
        canvas.drawCircle(Offset(cx, cy), 4.0, starPaint);

        // Corner connector accents
        final x0 = c * cellSize;
        final y0 = r * cellSize;
        canvas.drawLine(Offset(x0, y0), Offset(x0 + 8, y0 + 8), starPaint);
        canvas.drawLine(Offset(x0 + 56, y0), Offset(x0 + 48, y0 + 8), starPaint);
        canvas.drawLine(Offset(x0, y0 + 56), Offset(x0 + 8, y0 + 48), starPaint);
        canvas.drawLine(Offset(x0 + 56, y0 + 56), Offset(x0 + 48, y0 + 48), starPaint);
      }
    }

    // 3. Muqarnas scallop crown along top edge
    final scallopPaintA = Paint()
      ..color = NoorColors.gold.withOpacity(0.24)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 0.8;

    final scallopPaintB = Paint()
      ..color = NoorColors.gold.withOpacity(0.15)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 0.8;

    final scallopCount = (w / 36.0).ceil() + 2;
    for (int i = 0; i < scallopCount; i++) {
      final startX = i * 36.0 - 6.0;
      final pathA = Path()
        ..moveTo(startX, 0)
        ..quadraticBezierTo(startX + 18, 22, startX + 36, 0);
      canvas.drawPath(pathA, scallopPaintA);

      final startXB = i * 36.0 + 12.0;
      final pathB = Path()
        ..moveTo(startXB, 0)
        ..quadraticBezierTo(startXB + 18, 34, startXB + 36, 0);
      canvas.drawPath(pathB, scallopPaintB);
    }

    // 4. Subtle gold sparkles (4-point stars & small ambient points)
    final sparklePaint = Paint()
      ..color = NoorColors.goldBright.withOpacity(0.7)
      ..style = PaintingStyle.fill;

    _drawSparkle(canvas, Offset(w * 0.14, h * 0.35), 7.0, sparklePaint);
    _drawSparkle(canvas, Offset(w * 0.86, h * 0.28), 6.0, sparklePaint);

    final dotPaint = Paint()..style = PaintingStyle.fill;
    dotPaint.color = NoorColors.goldBright.withOpacity(0.5);
    canvas.drawCircle(Offset(w * 0.78, h * 0.60), 1.6, dotPaint);
    canvas.drawCircle(Offset(w * 0.22, h * 0.65), 1.4, dotPaint);
    canvas.drawCircle(Offset(w * 0.90, h * 0.48), 1.0, dotPaint);
  }

  void _drawSparkle(Canvas canvas, Offset center, double size, Paint paint) {
    final path = Path();
    final half = size / 2;

    path.moveTo(center.dx, center.dy - half);
    path.quadraticBezierTo(center.dx, center.dy, center.dx + half, center.dy);
    path.quadraticBezierTo(center.dx, center.dy, center.dx, center.dy + half);
    path.quadraticBezierTo(center.dx, center.dy, center.dx - half, center.dy);
    path.quadraticBezierTo(center.dx, center.dy, center.dx, center.dy - half);
    path.close();

    canvas.drawPath(path, paint);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
