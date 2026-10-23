import 'package:flutter/material.dart';

/// Custom clipper that carves an organic Islamic arch notch into the top center of a card.
/// This allows the protruding sharp center tip of the top Mufta header to nest
/// seamlessly into the card like a puzzle piece without colliding with child text or icons.
class MuftaCutoutClipper extends CustomClipper<Path> {
  final double notchWidth;
  final double notchDepth;
  final double borderRadius;

  const MuftaCutoutClipper({
    this.notchWidth = 76.0,
    this.notchDepth = 24.0,
    this.borderRadius = 28.0,
  });

  @override
  Path getClip(Size size) {
    final path = Path();
    final halfW = size.width / 2;
    final halfNotch = notchWidth / 2;

    // Start at top-left after corner radius
    path.moveTo(borderRadius, 0);

    // Straight to start of notch
    final notchStart = halfW - halfNotch;
    path.lineTo(notchStart, 0);

    // Smooth Islamic pointed arch curve dipping to (halfW, notchDepth)
    path.cubicTo(
      halfW - (halfNotch * 0.45),
      notchDepth * 0.25,
      halfW - (halfNotch * 0.15),
      notchDepth * 0.85,
      halfW,
      notchDepth,
    );

    // Right slope rising back to top edge
    final notchEnd = halfW + halfNotch;
    path.cubicTo(
      halfW + (halfNotch * 0.15),
      notchDepth * 0.85,
      halfW + (halfNotch * 0.45),
      notchDepth * 0.25,
      notchEnd,
      0,
    );

    // Continue to top-right corner
    path.lineTo(size.width - borderRadius, 0);
    path.arcToPoint(
      Offset(size.width, borderRadius),
      radius: Radius.circular(borderRadius),
    );

    // Down to bottom-right corner
    path.lineTo(size.width, size.height - borderRadius);
    path.arcToPoint(
      Offset(size.width - borderRadius, size.height),
      radius: Radius.circular(borderRadius),
    );

    // Along bottom to bottom-left corner
    path.lineTo(borderRadius, size.height);
    path.arcToPoint(
      Offset(0, size.height - borderRadius),
      radius: Radius.circular(borderRadius),
    );

    // Up to top-left corner
    path.lineTo(0, borderRadius);
    path.arcToPoint(
      Offset(borderRadius, 0),
      radius: Radius.circular(borderRadius),
    );

    path.close();
    return path;
  }

  @override
  bool shouldReclip(covariant MuftaCutoutClipper oldClipper) =>
      oldClipper.notchWidth != notchWidth ||
      oldClipper.notchDepth != notchDepth ||
      oldClipper.borderRadius != borderRadius;
}
