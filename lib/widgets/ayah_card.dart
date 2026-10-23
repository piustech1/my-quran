import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
import '../constants/app_colors.dart';
import '../models/ayah.dart';

class AyahCard extends StatelessWidget {
  final Ayah ayah;
  final double arabicFontSize;
  final bool showTranslation;
  final VoidCallback? onBookmarkToggle;
  final bool isBookmarked;
  final bool isPlaying;
  final VoidCallback? onPlay;

  const AyahCard({
    super.key,
    required this.ayah,
    this.arabicFontSize = 24.0,
    this.showTranslation = true,
    this.onBookmarkToggle,
    this.isBookmarked = false,
    this.isPlaying = false,
    this.onPlay,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final bg = isPlaying
        ? AppColors.accentGold.withOpacity(isDark ? 0.22 : 0.14)
        : (isDark ? AppColors.darkSurface : AppColors.lightSurface);
    final border = isPlaying
        ? AppColors.accentGold
        : (isDark ? AppColors.darkBorder : AppColors.lightBorder);
    final textPrimary =
        isDark ? AppColors.darkTextPrimary : AppColors.lightTextPrimary;
    final textSecondary =
        isDark ? AppColors.darkTextSecondary : AppColors.lightTextSecondary;

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
      child: Container(
        padding: const EdgeInsets.all(18),
        decoration: BoxDecoration(
          color: bg,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: border, width: isPlaying ? 1.8 : 1.0),
          boxShadow: [
            BoxShadow(
              color: isPlaying
                  ? AppColors.accentGold.withOpacity(0.18)
                  : Colors.black.withOpacity(isDark ? 0.2 : 0.04),
              blurRadius: isPlaying ? 16 : 10,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Top Ayah action bar
            Row(
              children: [
                // Ayah Badge
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                  decoration: BoxDecoration(
                    color: AppColors.accentGold.withOpacity(0.16),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(
                      color: AppColors.accentGold,
                      width: 1.2,
                    ),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      if (isPlaying) ...[
                        const Icon(Icons.volume_up_rounded,
                            size: 14, color: AppColors.accentGold),
                        const SizedBox(width: 4),
                      ],
                      Text(
                        '${ayah.chapter}:${ayah.verse}',
                        style: GoogleFonts.plusJakartaSans(
                          fontSize: 12,
                          fontWeight: FontWeight.bold,
                          color: AppColors.accentGoldDark,
                        ),
                      ),
                    ],
                  ),
                ),
                const Spacer(),

                // Play Audio Button
                if (onPlay != null)
                  IconButton(
                    icon: Icon(
                      isPlaying
                          ? Icons.pause_circle_filled_rounded
                          : Icons.play_circle_fill_rounded,
                      size: 24,
                      color: isPlaying
                          ? AppColors.accentGold
                          : AppColors.accentGold.withOpacity(0.85),
                    ),
                    tooltip: isPlaying ? 'Pause Audio' : 'Play Ayah Recitation',
                    onPressed: onPlay,
                  ),

                // Copy verse
                IconButton(
                  icon: const Icon(Icons.copy_rounded, size: 18),
                  color: textSecondary,
                  tooltip: 'Copy Ayah',
                  onPressed: () {
                    final text =
                        '${ayah.arabicText}\n\n${ayah.translation} [Quran ${ayah.chapter}:${ayah.verse}]';
                    Clipboard.setData(ClipboardData(text: text));
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                        content: Text('Ayah copied to clipboard'),
                        duration: Duration(seconds: 2),
                        backgroundColor: AppColors.lightPillButton,
                      ),
                    );
                  },
                ),

                // Bookmark verse
                if (onBookmarkToggle != null)
                  IconButton(
                    icon: Icon(
                      isBookmarked
                          ? Icons.bookmark_rounded
                          : Icons.bookmark_border_rounded,
                      size: 20,
                      color:
                          isBookmarked ? AppColors.accentGold : textSecondary,
                    ),
                    onPressed: onBookmarkToggle,
                  ),
              ],
            ),
            const SizedBox(height: 14),

            // Arabic text (RTL)
            Text(
              ayah.arabicText,
              textAlign: TextAlign.right,
              textDirection: TextDirection.rtl,
              style: GoogleFonts.amiri(
                fontSize: arabicFontSize,
                fontWeight: FontWeight.w600,
                color: textPrimary,
                height: 2.1,
              ),
            ),

            // Translation (if enabled)
            if (showTranslation && ayah.translation.isNotEmpty) ...[
              const SizedBox(height: 14),
              Divider(
                color:
                    isPlaying ? AppColors.accentGold.withOpacity(0.35) : border,
                height: 1,
              ),
              const SizedBox(height: 12),
              Text(
                ayah.translation,
                style: GoogleFonts.plusJakartaSans(
                  fontSize: 14,
                  color: textPrimary.withOpacity(0.88),
                  height: 1.6,
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}
