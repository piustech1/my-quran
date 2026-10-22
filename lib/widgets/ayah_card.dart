import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
import '../constants/app_colors.dart';
import '../models/ayah.dart';
import 'glass_card.dart';

class AyahCard extends StatelessWidget {
  final Ayah ayah;
  final double arabicFontSize;
  final bool showTranslation;
  final VoidCallback? onBookmarkToggle;
  final bool isBookmarked;

  const AyahCard({
    super.key,
    required this.ayah,
    this.arabicFontSize = 24.0,
    this.showTranslation = true,
    this.onBookmarkToggle,
    this.isBookmarked = false,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: GlassCard(
        borderRadius: 20,
        padding: const EdgeInsets.all(18),
        color: AppColors.primarySurface.withOpacity(0.35),
        borderColor: AppColors.glassBorderSubtle,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Top Ayah action bar
            Row(
              children: [
                // Ayah Badge
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                  decoration: BoxDecoration(
                    color: AppColors.primary,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(
                      color: AppColors.gold.withOpacity(0.4),
                      width: 1,
                    ),
                  ),
                  child: Text(
                    '${ayah.chapter}:${ayah.verse}',
                    style: GoogleFonts.plusJakartaSans(
                      fontSize: 12,
                      fontWeight: FontWeight.bold,
                      color: AppColors.gold,
                    ),
                  ),
                ),
                const Spacer(),

                // Copy verse
                IconButton(
                  icon: const Icon(Icons.copy_rounded, size: 18),
                  color: AppColors.textMuted,
                  tooltip: 'Copy Ayah',
                  onPressed: () {
                    final text = '${ayah.arabicText}\n\n${ayah.translation} [Quran ${ayah.chapter}:${ayah.verse}]';
                    Clipboard.setData(ClipboardData(text: text));
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                        content: Text('Ayah copied to clipboard'),
                        duration: Duration(seconds: 2),
                        backgroundColor: AppColors.primary,
                      ),
                    );
                  },
                ),

                // Bookmark verse
                if (onBookmarkToggle != null)
                  IconButton(
                    icon: Icon(
                      isBookmarked ? Icons.bookmark_rounded : Icons.bookmark_border_rounded,
                      size: 20,
                      color: isBookmarked ? AppColors.gold : AppColors.textMuted,
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
                color: AppColors.textLight,
                height: 2.1,
              ),
            ),

            // Translation (if enabled)
            if (showTranslation && ayah.translation.isNotEmpty) ...[
              const SizedBox(height: 14),
              Divider(color: AppColors.glassDivider, height: 1),
              const SizedBox(height: 12),
              Text(
                ayah.translation,
                style: GoogleFonts.plusJakartaSans(
                  fontSize: 14,
                  color: AppColors.textLight.withOpacity(0.9),
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
