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
    final screenWidth = MediaQuery.of(context).size.width;
    // Aspect ratio of New Mufta muqarnas asset (1440 x 720 = 0.50)
    final naturalHeight = screenWidth * 0.54 + topPadding;
    final totalHeight = height ?? naturalHeight;

    return SizedBox(
      width: double.infinity,
      height: totalHeight,
      child: Stack(
        clipBehavior: Clip.none,
        children: [
          // 1. New Mufta Islamic Grand Muqarnas Archway Image
          Positioned(
            left: 0,
            right: 0,
            top: 0,
            bottom: 0,
            child: IgnorePointer(
              child: Image.asset(
                'assets/new_mufta.jpg',
                width: double.infinity,
                height: totalHeight,
                fit: BoxFit.cover,
                alignment: Alignment.topCenter,
                filterQuality: FilterQuality.high,
                errorBuilder: (context, error, stackTrace) => Container(
                  height: totalHeight,
                  color: AppColors.forestGreen,
                ),
              ),
            ),
          ),

          // 3. Foreground Controls (Floating glassmorphic top bar)
          Positioned(
            left: 0,
            right: 0,
            top: 0,
            child: Padding(
              padding: padding ??
                  EdgeInsets.fromLTRB(
                    18,
                    topPadding + 6,
                    18,
                    12,
                  ),
              child: child,
            ),
          ),
        ],
      ),
    );
  }
}
