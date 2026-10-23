import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../constants/app_colors.dart';
import '../constants/surah_data.dart';
import 'islamic_star_badge.dart';

class SurahCard extends StatelessWidget {
  final SurahMeta surah;
  final VoidCallback onTap;
  final VoidCallback? onPlayTap;

  const SurahCard({
    super.key,
    required this.surah,
    required this.onTap,
    this.onPlayTap,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final bg = isDark ? AppColors.darkCard : AppColors.lightSurface;
    final border = isDark ? AppColors.darkBorder : AppColors.lightBorder;
    final textPrimary =
        isDark ? AppColors.darkTextPrimary : AppColors.lightTextPrimary;
    final textSecondary =
        isDark ? AppColors.darkTextSecondary : AppColors.lightTextSecondary;

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 5),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(20),
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
            decoration: BoxDecoration(
              color: bg,
              borderRadius: BorderRadius.circular(20),
              border: Border.all(color: border, width: 0.8),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(isDark ? 0.25 : 0.03),
                  blurRadius: 10,
                  offset: const Offset(0, 3),
                ),
              ],
            ),
            child: Row(
              children: [
                // 1. Number Badge (Islamic Star)
                IslamicStarBadge(
                  number: surah.number,
                  size: 40,
                  color: AppColors.quranGold,
                  textColor: isDark ? Colors.white : AppColors.midnightNavy,
                ),
                const SizedBox(width: 14),

                // 2. Transliterated Name & Details
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        surah.englishName,
                        style: GoogleFonts.plusJakartaSans(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                          color: textPrimary,
                        ),
                      ),
                      const SizedBox(height: 3),
                      Row(
                        children: [
                          Flexible(
                            child: Text(
                              surah.englishNameTranslation,
                              style: GoogleFonts.plusJakartaSans(
                                fontSize: 12,
                                color: textSecondary,
                              ),
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                          const SizedBox(width: 6),
                          Container(
                            width: 3.5,
                            height: 3.5,
                            decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              color: textSecondary.withOpacity(0.6),
                            ),
                          ),
                          const SizedBox(width: 6),
                          Text(
                            '${surah.numberOfAyahs} Verses',
                            style: GoogleFonts.plusJakartaSans(
                              fontSize: 11,
                              color: AppColors.accentGoldDark,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),

                // 3. Arabic Calligraphy Name
                Text(
                  surah.name,
                  textDirection: TextDirection.rtl,
                  style: GoogleFonts.amiri(
                    fontSize: 22,
                    fontWeight: FontWeight.bold,
                    color: AppColors.quranGold,
                  ),
                ),

                // 4. Optional Play Icon Button
                if (onPlayTap != null) ...[
                  const SizedBox(width: 10),
                  GestureDetector(
                    onTap: onPlayTap,
                    child: Container(
                      width: 34,
                      height: 34,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: isDark
                            ? AppColors.deepEmerald.withOpacity(0.3)
                            : AppColors.quranGold.withOpacity(0.18),
                      ),
                      alignment: Alignment.center,
                      child: const Icon(
                        Icons.play_arrow_rounded,
                        color: AppColors.quranGold,
                        size: 20,
                      ),
                    ),
                  ),
                ],
              ],
            ),
          ),
        ),
      ),
    );
  }
}
