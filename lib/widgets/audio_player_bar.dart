import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../constants/app_colors.dart';
import '../services/audio_service.dart';

class AudioPlayerBar extends StatelessWidget {
  final int totalVerses;
  final VoidCallback? onReciterChangeRequested;

  const AudioPlayerBar({
    super.key,
    required this.totalVerses,
    this.onReciterChangeRequested,
  });

  @override
  Widget build(BuildContext context) {
    final audioService = QuranAudioService();
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final bg = isDark ? AppColors.darkSurface : AppColors.lightSurface;
    final textPrimary =
        isDark ? AppColors.darkTextPrimary : AppColors.lightTextPrimary;
    final textSecondary =
        isDark ? AppColors.darkTextSecondary : AppColors.lightTextSecondary;

    return ValueListenableBuilder<int?>(
      valueListenable: audioService.currentPlayingAyah,
      builder: (context, currentAyah, _) {
        if (currentAyah == null) return const SizedBox.shrink();

        return Padding(
          padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            decoration: BoxDecoration(
              color: bg,
              borderRadius: BorderRadius.circular(24),
              border: Border.all(color: AppColors.accentGold, width: 1.2),
              boxShadow: [
                BoxShadow(
                  color: AppColors.accentGold.withOpacity(0.25),
                  blurRadius: 18,
                  offset: const Offset(0, 4),
                ),
              ],
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                // Top row: Reciter selector button & current status
                Row(
                  children: [
                    // Reciter badge
                    InkWell(
                      onTap: onReciterChangeRequested,
                      borderRadius: BorderRadius.circular(12),
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 10, vertical: 5),
                        decoration: BoxDecoration(
                          color: AppColors.accentGold.withOpacity(0.16),
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(
                            color: AppColors.accentGold,
                            width: 1,
                          ),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            const Icon(Icons.person_rounded,
                                size: 14, color: AppColors.accentGold),
                            const SizedBox(width: 6),
                            Text(
                              audioService.selectedReciter.name,
                              style: GoogleFonts.plusJakartaSans(
                                fontSize: 11,
                                fontWeight: FontWeight.bold,
                                color: isDark
                                    ? AppColors.darkTextPrimary
                                    : const Color(0xFF5A4418),
                              ),
                            ),
                            const SizedBox(width: 4),
                            const Icon(Icons.arrow_drop_down_rounded,
                                size: 16, color: AppColors.accentGold),
                          ],
                        ),
                      ),
                    ),
                    const Spacer(),

                    // Current Ayah indicator
                    Text(
                      'Ayah $currentAyah of $totalVerses',
                      style: GoogleFonts.plusJakartaSans(
                        fontSize: 12,
                        fontWeight: FontWeight.bold,
                        color: textPrimary,
                      ),
                    ),
                    const SizedBox(width: 8),

                    // Stop / Close button
                    IconButton(
                      icon: const Icon(Icons.close_rounded, size: 18),
                      color: textSecondary,
                      padding: EdgeInsets.zero,
                      constraints: const BoxConstraints(),
                      onPressed: () => audioService.stop(),
                    ),
                  ],
                ),
                const SizedBox(height: 10),

                // Playback control row
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    // Previous Ayah
                    IconButton(
                      icon: const Icon(Icons.skip_previous_rounded),
                      color: currentAyah > 1
                          ? textPrimary
                          : textSecondary.withOpacity(0.4),
                      iconSize: 28,
                      onPressed: currentAyah > 1
                          ? () => audioService.playPreviousAyah()
                          : null,
                    ),
                    const SizedBox(width: 16),

                    // Play / Pause / Buffering button
                    ValueListenableBuilder<bool>(
                      valueListenable: audioService.isLoadingNotifier,
                      builder: (context, isLoading, _) {
                        if (isLoading) {
                          return const SizedBox(
                            width: 46,
                            height: 46,
                            child: Padding(
                              padding: EdgeInsets.all(10),
                              child: CircularProgressIndicator(
                                strokeWidth: 2.5,
                                color: AppColors.accentGold,
                              ),
                            ),
                          );
                        }

                        return ValueListenableBuilder<bool>(
                          valueListenable: audioService.isPlayingNotifier,
                          builder: (context, isPlaying, _) {
                            return Container(
                              decoration: BoxDecoration(
                                shape: BoxShape.circle,
                                color: AppColors.accentGold,
                                boxShadow: [
                                  BoxShadow(
                                    color:
                                        AppColors.accentGold.withOpacity(0.35),
                                    blurRadius: 10,
                                  ),
                                ],
                              ),
                              child: IconButton(
                                icon: Icon(
                                  isPlaying
                                      ? Icons.pause_rounded
                                      : Icons.play_arrow_rounded,
                                ),
                                color: AppColors.lightPillButton,
                                iconSize: 28,
                                onPressed: () {
                                  if (isPlaying) {
                                    audioService.pause();
                                  } else {
                                    audioService.resume();
                                  }
                                },
                              ),
                            );
                          },
                        );
                      },
                    ),
                    const SizedBox(width: 16),

                    // Next Ayah
                    IconButton(
                      icon: const Icon(Icons.skip_next_rounded),
                      color: currentAyah < totalVerses
                          ? textPrimary
                          : textSecondary.withOpacity(0.4),
                      iconSize: 28,
                      onPressed: currentAyah < totalVerses
                          ? () => audioService.playNextAyah()
                          : null,
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
}
