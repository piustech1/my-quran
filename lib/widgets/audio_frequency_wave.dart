import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../constants/app_colors.dart';
import '../services/audio_service.dart';

/// Minimalist Golden Audio Frequency Visualizer for the Curved Header.
/// Displays animated golden frequency curves when reciting, resting when paused.
class AudioFrequencyWave extends StatefulWidget {
  final int totalVerses;

  const AudioFrequencyWave({
    super.key,
    required this.totalVerses,
  });

  @override
  State<AudioFrequencyWave> createState() => _AudioFrequencyWaveState();
}

class _AudioFrequencyWaveState extends State<AudioFrequencyWave>
    with SingleTickerProviderStateMixin {
  late final AnimationController _animController;
  final QuranAudioService _audioService = QuranAudioService();

  @override
  void initState() {
    super.initState();
    _animController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1200),
    );

    _audioService.isPlayingNotifier.addListener(_handlePlaybackState);
    if (_audioService.isPlayingNotifier.value) {
      _animController.repeat();
    }
  }

  void _handlePlaybackState() {
    if (!mounted) return;
    if (_audioService.isPlayingNotifier.value) {
      if (!_animController.isAnimating) {
        _animController.repeat();
      }
    } else {
      _animController.stop();
    }
    setState(() {});
  }

  @override
  void dispose() {
    _audioService.isPlayingNotifier.removeListener(_handlePlaybackState);
    _animController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return ValueListenableBuilder<bool>(
      valueListenable: _audioService.isPlayingNotifier,
      builder: (context, isPlaying, _) {
        return ValueListenableBuilder<int?>(
          valueListenable: _audioService.currentPlayingAyah,
          builder: (context, playingAyah, _) {
            return AnimatedBuilder(
              animation: _animController,
              builder: (context, _) {
                return Container(
                  height: 22,
                  padding: const EdgeInsets.symmetric(horizontal: 14),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      // Active recitation indicator / Ayah count
                      if (isPlaying && playingAyah != null) ...[
                        Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 6, vertical: 2),
                          decoration: BoxDecoration(
                            color: AppColors.warmGold.withOpacity(0.2),
                            borderRadius: BorderRadius.circular(10),
                          ),
                          child: Text(
                            'Ayah $playingAyah / ${widget.totalVerses}',
                            style: GoogleFonts.plusJakartaSans(
                              fontSize: 10,
                              fontWeight: FontWeight.bold,
                              color: AppColors.warmGold,
                            ),
                          ),
                        ),
                        const SizedBox(width: 10),
                      ],

                      // Golden Frequency Bars (14 animated bars)
                      CustomPaint(
                        size: const Size(140, 18),
                        painter: _WaveFrequencyPainter(
                          progress: _animController.value,
                          isPlaying: isPlaying,
                          color: AppColors.warmGold,
                        ),
                      ),

                      if (!isPlaying) ...[
                        const SizedBox(width: 8),
                        Text(
                          'Recitation Paused',
                          style: GoogleFonts.plusJakartaSans(
                            fontSize: 10,
                            color: Colors.white.withOpacity(0.6),
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ],
                    ],
                  ),
                );
              },
            );
          },
        );
      },
    );
  }
}

class _WaveFrequencyPainter extends CustomPainter {
  final double progress;
  final bool isPlaying;
  final Color color;

  static const int barCount = 18;

  _WaveFrequencyPainter({
    required this.progress,
    required this.isPlaying,
    required this.color,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = color
      ..strokeCap = StrokeCap.round
      ..strokeWidth = 2.4;

    final barSpacing = size.width / (barCount - 1);
    final midY = size.height / 2;

    for (int i = 0; i < barCount; i++) {
      final x = i * barSpacing;
      double heightRatio;

      if (isPlaying) {
        // Multi-frequency wave pattern combining two harmonic frequencies
        final phase1 = progress * 2 * math.pi + (i * 0.45);
        final phase2 = progress * 4 * math.pi + (i * 0.25);
        final wave = (math.sin(phase1) * 0.6) + (math.cos(phase2) * 0.4);
        // Center-weighted window so ends are slightly calmer
        final window = math.sin((i / (barCount - 1)) * math.pi);
        heightRatio = 0.2 + (wave.abs() * 0.8 * (0.4 + 0.6 * window));
      } else {
        // Resting subtle golden dots/bars
        final window = math.sin((i / (barCount - 1)) * math.pi);
        heightRatio = 0.15 + (window * 0.2);
      }

      final barHalfHeight = (size.height * heightRatio) / 2;
      canvas.drawLine(
        Offset(x, midY - barHalfHeight),
        Offset(x, midY + barHalfHeight),
        paint,
      );
    }
  }

  @override
  bool shouldRepaint(covariant _WaveFrequencyPainter oldDelegate) =>
      oldDelegate.progress != progress || oldDelegate.isPlaying != isPlaying;
}
