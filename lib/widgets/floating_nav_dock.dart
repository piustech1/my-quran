import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
import '../constants/app_colors.dart';

class NavItemData {
  final String label;
  final IconData selectedIcon;
  final IconData unselectedIcon;

  const NavItemData({
    required this.label,
    required this.selectedIcon,
    required this.unselectedIcon,
  });
}

/// Ultra-Modern Floating Liquid Glass Bottom Navigation Dock
/// Directly matches the user reference image:
/// - Floating island dock elevated above the screen bottom
/// - Liquid frosted glass capsule with active rounded pill indicator [ Icon + Label ]
/// - Companion elevated circular action button on the right
class FloatingNavDock extends StatelessWidget {
  final int currentIndex;
  final ValueChanged<int> onTabSelected;
  final VoidCallback? onActionPressed;

  static const List<NavItemData> defaultItems = [
    NavItemData(
      label: 'Home',
      selectedIcon: Icons.home_rounded,
      unselectedIcon: Icons.home_outlined,
    ),
    NavItemData(
      label: "Qur'an",
      selectedIcon: Icons.menu_book_rounded,
      unselectedIcon: Icons.menu_book_outlined,
    ),
    NavItemData(
      label: 'Daily',
      selectedIcon: Icons.auto_stories_rounded,
      unselectedIcon: Icons.auto_stories_outlined,
    ),
    NavItemData(
      label: 'Prayers',
      selectedIcon: Icons.mosque_rounded,
      unselectedIcon: Icons.mosque_outlined,
    ),
  ];

  const FloatingNavDock({
    super.key,
    required this.currentIndex,
    required this.onTabSelected,
    this.onActionPressed,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final bottomPadding = MediaQuery.of(context).padding.bottom;

    // Glass styling
    final glassColor = isDark
        ? const Color(0xFF132A1E).withOpacity(0.85)
        : Colors.white.withOpacity(0.88);
    final borderColor = isDark
        ? Colors.white.withOpacity(0.12)
        : Colors.white.withOpacity(0.65);
    final shadowColor = isDark
        ? Colors.black.withOpacity(0.45)
        : const Color(0xFF1B382B).withOpacity(0.10);

    return Container(
      // Keep clear gap above the bottom edge — never touches bottom
      margin: EdgeInsets.only(
        left: 16,
        right: 16,
        bottom: bottomPadding > 0 ? bottomPadding + 6 : 20,
      ),
      height: 64,
      child: Row(
        children: [
          // 1. Main Liquid Glass Pill Capsule
          Expanded(
            child: ClipRRect(
              borderRadius: BorderRadius.circular(34),
              child: BackdropFilter(
                filter: ImageFilter.blur(sigmaX: 20, sigmaY: 20),
                child: Container(
                  height: 64,
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
                  decoration: BoxDecoration(
                    color: glassColor,
                    borderRadius: BorderRadius.circular(34),
                    border: Border.all(color: borderColor, width: 1.2),
                    boxShadow: [
                      BoxShadow(
                        color: shadowColor,
                        blurRadius: 28,
                        offset: const Offset(0, 10),
                      ),
                      BoxShadow(
                        color: Colors.white.withOpacity(isDark ? 0.04 : 0.4),
                        blurRadius: 4,
                        offset: const Offset(0, 1),
                      ),
                    ],
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceAround,
                    children: List.generate(defaultItems.length, (index) {
                      final item = defaultItems[index];
                      final isSelected = currentIndex == index;
                      return _buildNavItem(
                        context: context,
                        index: index,
                        item: item,
                        isSelected: isSelected,
                        isDark: isDark,
                      );
                    }),
                  ),
                ),
              ),
            ),
          ),

          const SizedBox(width: 10),

          // 2. Elevated Floating Companion Action Button (Matching reference circular action button)
          _buildActionButton(context, isDark),
        ],
      ),
    );
  }

  Widget _buildNavItem({
    required BuildContext context,
    required int index,
    required NavItemData item,
    required bool isSelected,
    required bool isDark,
  }) {
    // Pill styling when selected
    final activePillBg = isDark
        ? const Color(0xFF1D4D36)
        : Colors.white;
    final activeTextColor = isDark
        ? const Color(0xFFFFDF7A)
        : const Color(0xFF1A2621);
    final inactiveIconColor = isDark
        ? Colors.white.withOpacity(0.55)
        : const Color(0xFF6E7873);

    return GestureDetector(
      onTap: () {
        HapticFeedback.lightImpact();
        onTabSelected(index);
      },
      behavior: HitTestBehavior.opaque,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeOutCubic,
        padding: EdgeInsets.symmetric(
          horizontal: isSelected ? 14 : 10,
          vertical: 8,
        ),
        decoration: BoxDecoration(
          color: isSelected ? activePillBg : Colors.transparent,
          borderRadius: BorderRadius.circular(24),
          boxShadow: isSelected
              ? [
                  BoxShadow(
                    color: isDark
                        ? Colors.black.withOpacity(0.3)
                        : Colors.black.withOpacity(0.08),
                    blurRadius: 10,
                    offset: const Offset(0, 3),
                  ),
                ]
              : null,
          border: isSelected
              ? Border.all(
                  color: isDark
                      ? const Color(0xFFE5B850).withOpacity(0.35)
                      : Colors.black.withOpacity(0.05),
                  width: 0.8,
                )
              : null,
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              isSelected ? item.selectedIcon : item.unselectedIcon,
              size: isSelected ? 22 : 22,
              color: isSelected ? activeTextColor : inactiveIconColor,
            ),
            if (isSelected) ...[
              const SizedBox(width: 6),
              Text(
                item.label,
                style: GoogleFonts.plusJakartaSans(
                  fontSize: 12.5,
                  fontWeight: FontWeight.bold,
                  color: activeTextColor,
                  letterSpacing: -0.2,
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildActionButton(BuildContext context, bool isDark) {
    return GestureDetector(
      onTap: () {
        HapticFeedback.mediumImpact();
        if (onActionPressed != null) {
          onActionPressed!();
        } else {
          _showQuickActionsModal(context, isDark);
        }
      },
      child: Container(
        width: 52,
        height: 52,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          // Coral / Rose Gradient matching reference circular button
          gradient: const LinearGradient(
            colors: [
              Color(0xFFFF6B6B),
              Color(0xFFEE4E4E),
            ],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
          boxShadow: [
            BoxShadow(
              color: const Color(0xFFEE4E4E).withOpacity(0.40),
              blurRadius: 18,
              offset: const Offset(0, 6),
            ),
            BoxShadow(
              color: Colors.white.withOpacity(0.3),
              blurRadius: 4,
              offset: const Offset(0, -1),
            ),
          ],
          border: Border.all(
            color: Colors.white.withOpacity(0.6),
            width: 1.2,
          ),
        ),
        alignment: Alignment.center,
        child: const Icon(
          Icons.add_rounded,
          color: Colors.white,
          size: 28,
        ),
      ),
    );
  }

  void _showQuickActionsModal(BuildContext context, bool isDark) {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (ctx) {
        final bg = isDark
            ? const Color(0xFF0F261B)
            : Colors.white;
        final textPrimary = isDark ? Colors.white : AppColors.lightTextPrimary;
        final textSecondary = isDark ? Colors.white60 : AppColors.lightTextSecondary;

        return BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 16, sigmaY: 16),
          child: Container(
            margin: const EdgeInsets.all(16),
            padding: const EdgeInsets.fromLTRB(20, 16, 20, 28),
            decoration: BoxDecoration(
              color: bg.withOpacity(isDark ? 0.95 : 0.96),
              borderRadius: BorderRadius.circular(32),
              border: Border.all(
                color: isDark ? Colors.white12 : Colors.black12,
                width: 1,
              ),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.25),
                  blurRadius: 30,
                  offset: const Offset(0, 10),
                ),
              ],
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                // Pill Handle
                Container(
                  width: 44,
                  height: 4,
                  decoration: BoxDecoration(
                    color: Colors.grey.withOpacity(0.3),
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
                const SizedBox(height: 18),

                Text(
                  'Quick Islamic Actions',
                  style: GoogleFonts.plusJakartaSans(
                    fontSize: 17,
                    fontWeight: FontWeight.bold,
                    color: textPrimary,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  'Essential shortcuts for your daily worship',
                  style: GoogleFonts.plusJakartaSans(
                    fontSize: 12,
                    color: textSecondary,
                  ),
                ),
                const SizedBox(height: 20),

                // Action Grid
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceAround,
                  children: [
                    _buildModalQuickAction(
                      ctx,
                      icon: Icons.search_rounded,
                      label: 'Search Surah',
                      color: const Color(0xFFE5B850),
                      onTap: () {
                        Navigator.pop(ctx);
                        onTabSelected(1); // Go to Qur'an library
                      },
                      isDark: isDark,
                    ),
                    _buildModalQuickAction(
                      ctx,
                      icon: Icons.fingerprint_rounded,
                      label: 'Tasbih',
                      color: const Color(0xFF48CAE4),
                      onTap: () {
                        Navigator.pop(ctx);
                        onTabSelected(3); // Go to Prayers & Dhikr
                      },
                      isDark: isDark,
                    ),
                    _buildModalQuickAction(
                      ctx,
                      icon: Icons.auto_stories_rounded,
                      label: 'Daily Ayah',
                      color: const Color(0xFF52B788),
                      onTap: () {
                        Navigator.pop(ctx);
                        onTabSelected(2); // Go to Daily Ayah
                      },
                      isDark: isDark,
                    ),
                    _buildModalQuickAction(
                      ctx,
                      icon: Icons.calculate_outlined,
                      label: 'Zakat',
                      color: const Color(0xFFFF9E00),
                      onTap: () {
                        Navigator.pop(ctx);
                        onTabSelected(0); // Switch to Home
                      },
                      isDark: isDark,
                    ),
                  ],
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildModalQuickAction(
    BuildContext context, {
    required IconData icon,
    required String label,
    required Color color,
    required VoidCallback onTap,
    required bool isDark,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 56,
            height: 56,
            decoration: BoxDecoration(
              color: color.withOpacity(isDark ? 0.2 : 0.12),
              shape: BoxShape.circle,
              border: Border.all(color: color.withOpacity(0.35), width: 1.2),
            ),
            alignment: Alignment.center,
            child: Icon(icon, color: color, size: 26),
          ),
          const SizedBox(height: 8),
          Text(
            label,
            style: GoogleFonts.plusJakartaSans(
              fontSize: 11.5,
              fontWeight: FontWeight.w600,
              color: isDark ? Colors.white : AppColors.lightTextPrimary,
            ),
          ),
        ],
      ),
    );
  }
}
