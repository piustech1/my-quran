import 'dart:ui';
import 'package:flutter/material.dart';
import '../constants/app_colors.dart';

class FloatingNavDock extends StatelessWidget {
  final int currentIndex;
  final Function(int) onTabSelected;
  final VoidCallback onSearchPressed;

  const FloatingNavDock({
    super.key,
    required this.currentIndex,
    required this.onTabSelected,
    required this.onSearchPressed,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final dockBg = isDark
        ? AppColors.midnightNavy.withOpacity(0.92)
        : Colors.white.withOpacity(0.94);
    final borderColor =
        isDark ? Colors.white.withOpacity(0.08) : AppColors.lightBorder;
    final textMuted =
        isDark ? AppColors.darkTextSecondary : AppColors.lightTextSecondary;

    return Container(
      margin: const EdgeInsets.fromLTRB(18, 0, 18, 16),
      child: Stack(
        alignment: Alignment.center,
        clipBehavior: Clip.none,
        children: [
          // 1. Frosted Glass Dock Pill
          ClipRRect(
            borderRadius: BorderRadius.circular(36),
            child: BackdropFilter(
              filter: ImageFilter.blur(sigmaX: 20, sigmaY: 20),
              child: Container(
                height: 64,
                padding: const EdgeInsets.symmetric(horizontal: 16),
                decoration: BoxDecoration(
                  color: dockBg,
                  borderRadius: BorderRadius.circular(36),
                  border: Border.all(color: borderColor, width: 0.8),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(isDark ? 0.40 : 0.08),
                      blurRadius: 24,
                      offset: const Offset(0, 8),
                    ),
                  ],
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    // Item 0: Home
                    _buildNavItem(
                      index: 0,
                      icon: Icons.home_outlined,
                      isSelected: currentIndex == 0,
                      isDark: isDark,
                      textMuted: textMuted,
                      onTap: () => onTabSelected(0),
                    ),

                    // Item 1: Qur'an
                    _buildNavItem(
                      index: 1,
                      icon: Icons.menu_book_outlined,
                      isSelected: currentIndex == 1,
                      isDark: isDark,
                      textMuted: textMuted,
                      onTap: () => onTabSelected(1),
                    ),

                    // Spacer for the center elevated circular gold button
                    const SizedBox(width: 56),

                    // Item 2: Library / Profile
                    _buildNavItem(
                      index: 2,
                      icon: Icons.person_outline_rounded,
                      isSelected: currentIndex == 2 || currentIndex == 3,
                      isDark: isDark,
                      textMuted: textMuted,
                      onTap: () => onTabSelected(2),
                    ),
                  ],
                ),
              ),
            ),
          ),

          // 2. Center Circular Gold Button matching reference
          Positioned(
            top: -10,
            child: GestureDetector(
              onTap: onSearchPressed,
              child: Container(
                width: 56,
                height: 56,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  gradient: const LinearGradient(
                    colors: [
                      Color(0xFFFFDF7A),
                      Color(0xFFE5B850),
                      Color(0xFFCC9730),
                    ],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: const Color(0xFFD4A747).withOpacity(0.45),
                      blurRadius: 18,
                      offset: const Offset(0, 5),
                    ),
                  ],
                  border: Border.all(
                    color: Colors.white.withOpacity(0.7),
                    width: 1.5,
                  ),
                ),
                alignment: Alignment.center,
                child: const Icon(
                  Icons.search_rounded,
                  color: Color(0xFF1D2321),
                  size: 26,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildNavItem({
    required int index,
    required IconData icon,
    required bool isSelected,
    required bool isDark,
    required Color textMuted,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      behavior: HitTestBehavior.opaque,
      child: Container(
        width: 48,
        height: 48,
        alignment: Alignment.center,
        child: Icon(
          icon,
          size: 26,
          color: isSelected
              ? (isDark ? const Color(0xFFF5CE63) : const Color(0xFFC79934))
              : (isDark ? textMuted : const Color(0xFF757B78)),
        ),
      ),
    );
  }
}
