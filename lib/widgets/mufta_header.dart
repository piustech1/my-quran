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
    // Natural aspect ratio of 4K Mufta asset (1440 x 841 = 0.584)
    final naturalHeight = screenWidth * 0.584;
    final totalHeight = height ?? (naturalHeight + (topPadding > 24 ? (topPadding - 24) : 0));

    return SizedBox(
      width: double.infinity,
      height: totalHeight,
      child: Stack(
        clipBehavior: Clip.none,
        children: [
          // 1. Safe status bar fill at top edge ONLY (never behind transparent arch cutout)
          Positioned(
            left: 0,
            right: 0,
            top: 0,
            height: topPadding > 0 ? topPadding : 0,
            child: Container(
              color: AppColors.forestGreen,
            ),
          ),

          // 2. HD 4K Arabesque Mufta Dome Image (Full curves with transparent arch cutout)
          Positioned(
            left: 0,
            right: 0,
            top: 0,
            bottom: 0,
            child: IgnorePointer(
              child: Image.asset(
                'assets/top_mufta.png',
                width: double.infinity,
                height: totalHeight,
                fit: BoxFit.fill,
                alignment: Alignment.topCenter,
                filterQuality: FilterQuality.high,
                errorBuilder: (context, error, stackTrace) => Container(
                  height: totalHeight,
                  color: AppColors.forestGreen,
                ),
              ),
            ),
          ),

          // 3. Foreground Controls placed comfortably high up near status bar
          Positioned(
            left: 0,
            right: 0,
            top: 0,
            child: Padding(
              padding: padding ??
                  EdgeInsets.fromLTRB(
                    18,
                    topPadding + 4,
                    18,
                    8,
                  ),
              child: child,
            ),
          ),
        ],
      ),
    );
  }
}
