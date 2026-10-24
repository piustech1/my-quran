import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../constants/app_colors.dart';

class IslamicStarBadge extends StatelessWidget {
  final int number;
  final double size;
  final Color? color;
  final Color? textColor;
  final Color? backgroundColor;

  const IslamicStarBadge({
    super.key,
    required this.number,
    this.size = 36.0,
    this.color,
    this.textColor,
    this.backgroundColor,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final effectiveColor = color ?? AppColors.accentGoldDark;
    final effectiveTextColor = textColor ??
        (isDark ? AppColors.darkTextPrimary : AppColors.lightTextPrimary);
    final effectiveBg = backgroundColor ??
        (isDark
            ? AppColors.quranGold.withOpacity(0.08)
            : const Color(0xFFF7F3EB));

    return SizedBox(
      width: size,
      height: size,
      child: Stack(
        alignment: Alignment.center,
        children: [
          // Soft decorative background
          Container(
            width: size * 0.92,
            height: size * 0.92,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: effectiveBg,
            ),
          ),
          // Geometric Rub-el-Hizb 8-pointed Star
          CustomPaint(
            size: Size(size, size),
            painter: _RubElHizbPainter(color: effectiveColor),
          ),
          // Centered Number
          Text(
            '$number',
            style: GoogleFonts.plusJakartaSans(
              fontSize: size * 0.36,
              fontWeight: FontWeight.bold,
              color: effectiveTextColor,
            ),
          ),
        ],
      ),
    );
  }
}

class _RubElHizbPainter extends CustomPainter {
  final Color color;

  _RubElHizbPainter({required this.color});

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = color
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.35;

    final center = Offset(size.width / 2, size.height / 2);
    final radius = (size.width / 2) * 0.88;

    // First square
    final path1 = Path();
    for (int i = 0; i < 4; i++) {
      final angle = (i * math.pi / 2) + (math.pi / 4);
      final x = center.dx + radius * math.cos(angle);
      final y = center.dy + radius * math.sin(angle);
      if (i == 0) {
        path1.moveTo(x, y);
      } else {
        path1.lineTo(x, y);
      }
    }
    path1.close();
    canvas.drawPath(path1, paint);

    // Second square rotated by 45 degrees
    final path2 = Path();
    for (int i = 0; i < 4; i++) {
      final angle = i * math.pi / 2;
      final x = center.dx + radius * math.cos(angle);
      final y = center.dy + radius * math.sin(angle);
      if (i == 0) {
        path2.moveTo(x, y);
      } else {
        path2.lineTo(x, y);
      }
    }
    path2.close();
    canvas.drawPath(path2, paint);

    // Inner delicate Islamic circle
    final innerCirclePaint = Paint()
      ..color = color.withOpacity(0.35)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 0.9;
    canvas.drawCircle(center, radius * 0.65, innerCirclePaint);
  }

  @override
  bool shouldRepaint(covariant _RubElHizbPainter oldDelegate) =>
      oldDelegate.color != color;
}
