import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
import '../constants/app_colors.dart';
import '../models/ayah.dart';
import '../services/audio_service.dart';

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
        ? (isDark
            ? const Color(0xFF16382B)
            : const Color(0xFFFBF4E4))
        : (isDark ? AppColors.darkSurface : AppColors.lightSurface);
    final textPrimary =
        isDark ? AppColors.darkTextPrimary : AppColors.lightTextPrimary;
    final textSecondary =
        isDark ? AppColors.darkTextSecondary : AppColors.lightTextSecondary;

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
      child: Container(
        decoration: BoxDecoration(
          color: bg,
          borderRadius: BorderRadius.circular(22),
          border: null, // NO outline / borders as explicitly requested
          boxShadow: [
            BoxShadow(
              color: isPlaying
                  ? const Color(0x35EAB34D)
                  : Colors.black.withOpacity(isDark ? 0.25 : 0.05),
              blurRadius: isPlaying ? 16 : 10,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(22),
          child: Stack(
            children: [
              // Top-Left Corner Islamic Ornament
              Positioned(
                top: 0,
                left: 0,
                width: 38,
                height: 26,
                child: IgnorePointer(
                  child: Opacity(
                    opacity: isDark ? 0.25 : 0.35,
                    child: Transform.flip(
                      flipX: true,
                      flipY: true,
                      child: Image.asset(
                        'assets/corner_asset.png',
                        fit: BoxFit.fill,
                        errorBuilder: (_, __, ___) => const SizedBox.shrink(),
                      ),
                    ),
                  ),
                ),
              ),

              // Top-Right Corner Islamic Ornament
              Positioned(
                top: 0,
                right: 0,
                width: 38,
                height: 26,
                child: IgnorePointer(
                  child: Opacity(
                    opacity: isDark ? 0.25 : 0.35,
                    child: Transform.flip(
                      flipY: true,
                      child: Image.asset(
                        'assets/corner_asset.png',
                        fit: BoxFit.fill,
                        errorBuilder: (_, __, ___) => const SizedBox.shrink(),
                      ),
                    ),
                  ),
                ),
              ),

              // Bottom-Left Corner Islamic Ornament
              Positioned(
                bottom: 0,
                left: 0,
                width: 38,
                height: 26,
                child: IgnorePointer(
                  child: Opacity(
                    opacity: isDark ? 0.25 : 0.35,
                    child: Transform.flip(
                      flipX: true,
                      child: Image.asset(
                        'assets/corner_asset.png',
                        fit: BoxFit.fill,
                        errorBuilder: (_, __, ___) => const SizedBox.shrink(),
                      ),
                    ),
                  ),
                ),
              ),

              // Bottom-Right Corner Islamic Ornament
              Positioned(
                bottom: 0,
                right: 0,
                width: 38,
                height: 26,
                child: IgnorePointer(
                  child: Opacity(
                    opacity: isDark ? 0.25 : 0.35,
                    child: Image.asset(
                      'assets/corner_asset.png',
                      fit: BoxFit.fill,
                      errorBuilder: (_, __, ___) => const SizedBox.shrink(),
                    ),
                  ),
                ),
              ),

              // Main Card Content
              Padding(
                padding: const EdgeInsets.all(18),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    // Top Ayah action bar
                    Row(
                      children: [
                        // Borderless Ayah Badge
                        Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 10, vertical: 4),
                          decoration: BoxDecoration(
                            color: AppColors.quranGold.withOpacity(0.18),
                            borderRadius: BorderRadius.circular(12),
                            border: null, // No outline
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              if (isPlaying) ...[
                                const Icon(Icons.volume_up_rounded,
                                    size: 14, color: AppColors.quranGold),
                                const SizedBox(width: 4),
                              ],
                              Text(
                                '${ayah.chapter}:${ayah.verse}',
                                style: GoogleFonts.plusJakartaSans(
                                  fontSize: 12,
                                  fontWeight: FontWeight.bold,
                                  color: isDark
                                      ? AppColors.quranGold
                                      : const Color(0xFFB8860B),
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
                                  ? AppColors.quranGold
                                  : AppColors.quranGold.withOpacity(0.85),
                            ),
                            tooltip:
                                isPlaying ? 'Pause Audio' : 'Play Ayah Recitation',
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
                              color: isBookmarked
                                  ? AppColors.quranGold
                                  : textSecondary,
                            ),
                            onPressed: onBookmarkToggle,
                          ),
                      ],
                    ),
                    const SizedBox(height: 14),

                    // Arabic Text with Real-Time Recitation Word Highlighting
                    _buildArabicText(textPrimary, isDark),

                    // Translation (if enabled)
                    if (showTranslation && ayah.translation.isNotEmpty) ...[
                      const SizedBox(height: 14),
                      Container(
                        height: 0.8,
                        color: isDark
                            ? Colors.white.withOpacity(0.08)
                            : Colors.black.withOpacity(0.06),
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
            ],
          ),
        ),
      ),
    );
  }

  /// Builds Arabic text with real-time word-by-word synchronized highlighting when reciting
  Widget _buildArabicText(Color textPrimary, bool isDark) {
    if (!isPlaying) {
      return Text(
        ayah.arabicText,
        textAlign: TextAlign.right,
        textDirection: TextDirection.rtl,
        style: GoogleFonts.amiri(
          fontSize: arabicFontSize,
          fontWeight: FontWeight.w600,
          color: textPrimary,
          height: 2.1,
        ),
      );
    }

    final words = ayah.arabicText.trim().split(RegExp(r'\s+'));

    return ValueListenableBuilder<double>(
      valueListenable: QuranAudioService().ayahPlaybackProgress,
      builder: (context, progress, _) {
        final activeWordIndex =
            (progress * words.length).floor().clamp(0, words.length - 1);

        return Text.rich(
          TextSpan(
            children: List.generate(words.length, (index) {
              final word = words[index];
              final isSpoken = index < activeWordIndex;
              final isCurrentlySpeaking = index == activeWordIndex;

              Color wordColor;
              FontWeight weight;
              List<Shadow>? shadows;
              Paint? background;

              if (isCurrentlySpeaking) {
                // Active word being recited: Radiant gold with soft glow
                wordColor = const Color(0xFFFFD700);
                weight = FontWeight.bold;
                shadows = const [
                  Shadow(
                    color: Color(0x90FFD700),
                    blurRadius: 8,
                    offset: Offset(0, 0),
                  ),
                ];
                background = Paint()
                  ..color = const Color(0x30EAB34D)
                  ..style = PaintingStyle.fill;
              } else if (isSpoken) {
                // Spoken word: Warm gold
                wordColor = isDark
                    ? const Color(0xFFE5C158)
                    : const Color(0xFFB8860B);
                weight = FontWeight.w700;
                shadows = null;
                background = null;
              } else {
                // Upcoming word: Standard color
                wordColor = textPrimary;
                weight = FontWeight.w600;
                shadows = null;
                background = null;
              }

              return TextSpan(
                text: '$word ',
                style: GoogleFonts.amiri(
                  fontSize: arabicFontSize,
                  fontWeight: weight,
                  color: wordColor,
                  height: 2.1,
                  shadows: shadows,
                  background: background,
                ),
              );
            }),
          ),
          textAlign: TextAlign.right,
          textDirection: TextDirection.rtl,
        );
      },
    );
  }
}
