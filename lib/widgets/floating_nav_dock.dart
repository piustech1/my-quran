import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
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
                padding: const EdgeInsets.symmetric(horizontal: 10),
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
                  mainAxisAlignment: MainAxisAlignment.spaceAround,
                  children: [
                    // Item 0: Home
                    _buildNavItem(
                      index: 0,
                      icon: Icons.mosque_rounded,
                      label: 'Home',
                      isSelected: currentIndex == 0,
                      isDark: isDark,
                      textMuted: textMuted,
                      onTap: () => onTabSelected(0),
                    ),

                    // Item 1: Qur'an
                    _buildNavItem(
                      index: 1,
                      icon: Icons.menu_book_rounded,
                      label: "Qur'an",
                      isSelected: currentIndex == 1,
                      isDark: isDark,
                      textMuted: textMuted,
                      onTap: () => onTabSelected(1),
                    ),

                    // Spacer for the center elevated diamond button
                    const SizedBox(width: 48),

                    // Item 2: Dzikir
                    _buildNavItem(
                      index: 2,
                      icon: Icons.grain_rounded,
                      label: 'Dzikir',
                      isSelected: currentIndex == 2,
                      isDark: isDark,
                      textMuted: textMuted,
                      onTap: () => onTabSelected(2),
                    ),

                    // Item 3: Library / Bookmarks
                    _buildNavItem(
                      index: 3,
                      icon: Icons.bookmark_rounded,
                      label: 'Library',
                      isSelected: currentIndex == 3,
                      isDark: isDark,
                      textMuted: textMuted,
                      onTap: () => onTabSelected(3),
                    ),
                  ],
                ),
              ),
            ),
          ),

          // 2. Noor Signature Center Diamond / Tilted Gold Button
          Positioned(
            top: -12,
            child: GestureDetector(
              onTap: onSearchPressed,
              child: Container(
                width: 52,
                height: 52,
                decoration: BoxDecoration(
                  boxShadow: [
                    BoxShadow(
                      color: AppColors.quranGold.withOpacity(0.40),
                      blurRadius: 16,
                      offset: const Offset(0, 4),
                    ),
                  ],
                ),
                child: Transform.rotate(
                  angle: 0.785398, // 45 degrees
                  child: Container(
                    decoration: BoxDecoration(
                      gradient: const LinearGradient(
                        colors: [
                          Color(0xFFFFDF7A),
                          AppColors.quranGold,
                          Color(0xFFD49E24),
                        ],
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                      ),
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(
                        color: Colors.white.withOpacity(0.6),
                        width: 1.2,
                      ),
                    ),
                    alignment: Alignment.center,
                    child: Transform.rotate(
                      angle: -0.785398, // counter-rotate
                      child: const Icon(
                        Icons.search_rounded,
                        color: Color(0xFF14171A),
                        size: 26,
                      ),
                    ),
                  ),
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
    required String label,
    required bool isSelected,
    required bool isDark,
    required Color textMuted,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      behavior: HitTestBehavior.opaque,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 220),
        curve: Curves.easeOutCubic,
        padding: EdgeInsets.symmetric(
          horizontal: isSelected ? 12 : 8,
          vertical: 6,
        ),
        decoration: BoxDecoration(
          color: isSelected
              ? (isDark
                  ? AppColors.deepEmerald
                  : AppColors.deepEmerald.withOpacity(0.12))
              : Colors.transparent,
          borderRadius: BorderRadius.circular(20),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              icon,
              size: 20,
              color: isSelected
                  ? (isDark ? AppColors.quranGold : AppColors.deepEmerald)
                  : textMuted,
            ),
            if (isSelected) ...[
              const SizedBox(width: 5),
              Text(
                label,
                style: GoogleFonts.plusJakartaSans(
                  fontSize: 11,
                  fontWeight: FontWeight.bold,
                  color: isDark ? Colors.white : AppColors.deepEmerald,
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}
