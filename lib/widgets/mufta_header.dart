import 'package:flutter/material.dart';
import '../constants/app_colors.dart';

/// Reusable top header widget showcasing the AI-generated Islamic Mufta dome texture.
/// Features high-definition arabesque relief carvings, a multi-lobed arch boundary,
/// and an organic protruding sharp center tip.
class MuftaHeader extends StatelessWidget {
  final Widget child;
  final double? height;
  final EdgeInsetsGeometry? padding;

  const MuftaHeader({
    super.key,
    required this.child,
    this.height,
    this.padding,
  });

  @override
  Widget build(BuildContext context) {
    final topPadding = MediaQuery.of(context).padding.top;
    final totalHeight = height ?? (topPadding + 136.0);

    return SizedBox(
      width: double.infinity,
      height: totalHeight,
      child: Stack(
        clipBehavior: Clip.none,
        children: [
          // 1. HD 4K Arabesque Mufta Background Image
          Positioned(
            left: 0,
            right: 0,
            top: 0,
            bottom: 0,
            child: Container(
              color: AppColors.forestGreen,
              child: Image.asset(
                'assets/top_mufta.png',
                width: double.infinity,
                height: totalHeight,
                fit: BoxFit.cover,
                alignment: Alignment.topCenter,
                errorBuilder: (context, error, stackTrace) => Container(
                  color: AppColors.forestGreen,
                ),
              ),
            ),
          ),

          // 2. Subtle ambient bottom drop shadow beneath the arch
          Positioned(
            left: 0,
            right: 0,
            bottom: -6,
            height: 16,
            child: IgnorePointer(
              child: Container(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                    colors: [
                      Colors.black.withOpacity(0.18),
                      Colors.transparent,
                    ],
                  ),
                ),
              ),
            ),
          ),

          // 3. Foreground Controls placed safely above the arch curve
          Positioned.fill(
            child: Padding(
              padding: padding ??
                  EdgeInsets.fromLTRB(
                    18,
                    topPadding + 6,
                    18,
                    24,
                  ),
              child: child,
            ),
          ),
        ],
      ),
    );
  }
}
