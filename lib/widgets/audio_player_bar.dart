import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../constants/app_colors.dart';
import '../services/audio_service.dart';
import 'glass_card.dart';

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

    return ValueListenableBuilder<int?>(
      valueListenable: audioService.currentPlayingAyah,
      builder: (context, currentAyah, _) {
        if (currentAyah == null) return const SizedBox.shrink();

        return Padding(
          padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
          child: GlassCard(
            borderRadius: 24,
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            color: AppColors.primarySurface.withOpacity(0.92),
            borderColor: AppColors.gold.withOpacity(0.4),
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
                        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                        decoration: BoxDecoration(
                          color: AppColors.primary,
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(
                            color: AppColors.gold.withOpacity(0.5),
                            width: 1,
                          ),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            const Icon(Icons.person_rounded, size: 14, color: AppColors.gold),
                            const SizedBox(width: 6),
                            Text(
                              audioService.selectedReciter.name,
                              style: GoogleFonts.plusJakartaSans(
                                fontSize: 11,
                                fontWeight: FontWeight.bold,
                                color: AppColors.gold,
                              ),
                            ),
                            const SizedBox(width: 4),
                            const Icon(Icons.arrow_drop_down_rounded, size: 16, color: AppColors.gold),
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
                        fontWeight: FontWeight.w600,
                        color: AppColors.textLight,
                      ),
                    ),
                    const SizedBox(width: 8),

                    // Stop / Close button
                    IconButton(
                      icon: const Icon(Icons.close_rounded, size: 18),
                      color: AppColors.textMuted,
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
                      color: currentAyah > 1 ? AppColors.textLight : AppColors.textMuted,
                      iconSize: 28,
                      onPressed: currentAyah > 1 ? () => audioService.playPreviousAyah() : null,
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
                                color: AppColors.gold,
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
                                color: AppColors.gold,
                                boxShadow: [
                                  BoxShadow(
                                    color: AppColors.gold.withOpacity(0.25),
                                    blurRadius: 12,
                                  ),
                                ],
                              ),
                              child: IconButton(
                                icon: Icon(
                                  isPlaying ? Icons.pause_rounded : Icons.play_arrow_rounded,
                                ),
                                color: AppColors.primaryDark,
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
                      color: currentAyah < totalVerses ? AppColors.textLight : AppColors.textMuted,
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
