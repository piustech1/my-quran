import 'package:flutter/material.dart';
import '../constants/app_colors.dart';

/// Clipper that cuts a smooth downward curve at the bottom edge.
class DownwardCurveClipper extends CustomClipper<Path> {
  final double curveDepth;

  const DownwardCurveClipper({this.curveDepth = 24.0});

  @override
  Path getClip(Size size) {
    final path = Path();
    path.lineTo(0, size.height - curveDepth);
    // Smooth, organic convex dome arch with gentle horizontal apex
    path.cubicTo(
      size.width * 0.28,
      size.height + (curveDepth * 0.33),
      size.width * 0.72,
      size.height + (curveDepth * 0.33),
      size.width,
      size.height - curveDepth,
    );
    path.lineTo(size.width, 0);
    path.close();
    return path;
  }

  @override
  bool shouldReclip(covariant DownwardCurveClipper oldClipper) =>
      oldClipper.curveDepth != curveDepth;
}

/// Solid Forest-Green Curved Downward Header container (no outline)
class CurvedDownwardHeader extends StatelessWidget {
  final Widget child;
  final double curveDepth;
  final Color backgroundColor;
  final EdgeInsetsGeometry padding;

  const CurvedDownwardHeader({
    super.key,
    required this.child,
    this.curveDepth = 24.0,
    this.backgroundColor = AppColors.forestGreen,
    this.padding = EdgeInsets.zero,
  });

  @override
  Widget build(BuildContext context) {
    return ClipPath(
      clipper: DownwardCurveClipper(curveDepth: curveDepth),
      child: Container(
        color: backgroundColor,
        padding: padding,
        child: child,
      ),
    );
  }
}
