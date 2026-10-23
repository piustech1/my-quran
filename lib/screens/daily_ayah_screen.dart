import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
import '../constants/app_colors.dart';
import '../services/audio_service.dart';
import '../services/daily_ayah_service.dart';
import '../services/storage_service.dart';

class DailyAyahScreen extends StatefulWidget {
  final DateTime? date;

  const DailyAyahScreen({super.key, this.date});

  @override
  State<DailyAyahScreen> createState() => _DailyAyahScreenState();
}

class _DailyAyahScreenState extends State<DailyAyahScreen> {
  final DailyAyahService _dailyAyahService = DailyAyahService();
  final QuranAudioService _audioService = QuranAudioService();
  final StorageService _storageService = StorageService();

  late final DailyAyahModel _dailyAyah;
  late TranslationEdition _selectedEdition;

  String _currentTranslationText = '';
  bool _isLoadingTranslation = false;
  bool _isBookmarked = false;
  double _arabicFontSize = 26.0;
  double _playbackSpeed = 1.0;
  bool _hasAutoPlayed = false;

  @override
  void initState() {
    super.initState();
    _dailyAyah = _dailyAyahService.getDailyAyah(widget.date);
    _selectedEdition = DailyAyahService.supportedTranslations[0];
    _currentTranslationText = _dailyAyah.defaultTranslation;

    _loadPreferences();
    _initAutoAudio();
  }

  Future<void> _loadPreferences() async {
    final bookmarked = await _storageService.isDailyAyahBookmarked(
      _dailyAyah.surahNumber,
      _dailyAyah.ayahNumber,
    );
    final size = await _storageService.getDailyAyahFontSize();
    if (mounted) {
      setState(() {
        _isBookmarked = bookmarked;
        _arabicFontSize = size;
      });
    }
  }

  void _initAutoAudio() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!_hasAutoPlayed && mounted) {
        _hasAutoPlayed = true;
        // Start playing the daily ayah recitation
        _audioService.playAyah(
          surahNumber: _dailyAyah.surahNumber,
          ayahNumber: _dailyAyah.ayahNumber,
          maxVerses: 286,
        );
      }
    });
  }

  Future<void> _onSelectTranslation(TranslationEdition edition) async {
    if (_selectedEdition.id == edition.id) return;

    setState(() {
      _selectedEdition = edition;
      _isLoadingTranslation = true;
    });

    final text = await _dailyAyahService.fetchTranslation(
      chapter: _dailyAyah.surahNumber,
      verse: _dailyAyah.ayahNumber,
      editionId: edition.id,
    );

    if (mounted) {
      setState(() {
        _currentTranslationText = text;
        _isLoadingTranslation = false;
      });
    }
  }

  Future<void> _toggleBookmark() async {
    final newState = await _storageService.toggleDailyAyahBookmark(
      _dailyAyah.surahNumber,
      _dailyAyah.ayahNumber,
    );
    if (mounted) {
      setState(() => _isBookmarked = newState);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            newState ? 'Ayah saved to bookmarks' : 'Ayah removed from bookmarks',
            style: GoogleFonts.plusJakartaSans(),
          ),
          duration: const Duration(seconds: 2),
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        ),
      );
    }
  }

  void _copyToClipboard() {
    final formatted = '''
${_dailyAyah.arabicText}

"$_currentTranslationText"

— ${_dailyAyah.reference}
(${_selectedEdition.authorName})

Tafsir: ${_dailyAyah.explanation}
(${_dailyAyah.tafsirAttribution})

Shared via My Quran
''';

    Clipboard.setData(ClipboardData(text: formatted));
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          children: [
            const Icon(Icons.check_circle_rounded, color: AppColors.quranGold, size: 18),
            const SizedBox(width: 8),
            Text(
              'Ayah & explanation copied to clipboard',
              style: GoogleFonts.plusJakartaSans(color: Colors.white),
            ),
          ],
        ),
        backgroundColor: AppColors.deepEmerald,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
      ),
    );
  }

  void _changeFontSize(double delta) {
    setState(() {
      _arabicFontSize = (_arabicFontSize + delta).clamp(20.0, 40.0);
    });
    _storageService.saveDailyAyahFontSize(_arabicFontSize);
  }

  void _togglePlaybackSpeed() {
    final speeds = [1.0, 1.25, 1.5];
    final nextIndex = (speeds.indexOf(_playbackSpeed) + 1) % speeds.length;
    final newSpeed = speeds[nextIndex];
    setState(() => _playbackSpeed = newSpeed);
    _audioService.player.setSpeed(newSpeed);
  }

  void _openImageViewer() {
    showDialog(
      context: context,
      barrierColor: Colors.black.withOpacity(0.85),
      builder: (ctx) {
        return Dialog(
          backgroundColor: Colors.transparent,
          insetPadding: const EdgeInsets.all(16),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Align(
                alignment: Alignment.topRight,
                child: IconButton(
                  icon: const Icon(Icons.close_rounded, color: Colors.white, size: 28),
                  onPressed: () => Navigator.of(ctx).pop(),
                ),
              ),
              ClipRRect(
                borderRadius: BorderRadius.circular(24),
                child: Image.asset(
                  _dailyAyah.imageAsset,
                  fit: BoxFit.contain,
                ),
              ),
              const SizedBox(height: 12),
              Text(
                '${_dailyAyah.themeTitle} · ${_dailyAyah.shortCitation}',
                style: GoogleFonts.plusJakartaSans(
                  color: Colors.white70,
                  fontSize: 13,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  String _formatDate(DateTime dt) {
    const days = [
      'Monday', 'Tuesday', 'Wednesday', 'Thursday', 'Friday', 'Saturday', 'Sunday'
    ];
    const months = [
      'Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun',
      'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'
    ];
    final dayName = days[dt.weekday - 1];
    final monthName = months[dt.month - 1];
    return '$dayName, $monthName ${dt.day}';
  }

  String _formatDuration(Duration d) {
    final minutes = d.inMinutes.remainder(60).toString().padLeft(2, '0');
    final seconds = d.inSeconds.remainder(60).toString().padLeft(2, '0');
    return '$minutes:$seconds';
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final bg = isDark ? AppColors.darkBackground : AppColors.lightBackground;
    final surface = isDark ? AppColors.darkCard : AppColors.lightSurface;
    final surfaceSubtle =
        isDark ? AppColors.darkInnerCard : AppColors.lightSurfaceSubtle;
    final textPrimary =
        isDark ? AppColors.darkTextPrimary : AppColors.lightTextPrimary;
    final textSecondary =
        isDark ? AppColors.darkTextSecondary : AppColors.lightTextSecondary;

    return Scaffold(
      backgroundColor: bg,
      body: SafeArea(
        child: Column(
          children: [
            // A. Compact Header
            _buildHeader(isDark, textPrimary, textSecondary),

            // Scrollable Content
            Expanded(
              child: SingleChildScrollView(
                physics: const BouncingScrollPhysics(),
                padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    // B. Thematic Visual
                    _buildThematicVisual(isDark),

                    const SizedBox(height: 18),

                    // C. Audio Recitation Player
                    _buildAudioPlayer(isDark, surface, surfaceSubtle, textPrimary, textSecondary),

                    const SizedBox(height: 22),

                    // D. Translation Language Selector
                    _buildTranslationSelector(isDark, textPrimary, textSecondary),

                    const SizedBox(height: 20),

                    // E. Main Ayah Content
                    _buildMainAyahContent(isDark, surface, textPrimary, textSecondary),

                    const SizedBox(height: 22),

                    // F. Short Explanation ("Understanding this ayah")
                    _buildExplanationSection(isDark, surfaceSubtle, textPrimary, textSecondary),

                    const SizedBox(height: 24),

                    // G. Quick Actions Bar
                    _buildQuickActionsBar(isDark, surface, textPrimary, textSecondary),

                    const SizedBox(height: 36),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildHeader(bool isDark, Color textPrimary, Color textSecondary) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 8, 16, 6),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          // Back button
          GestureDetector(
            onTap: () => Navigator.of(context).pop(),
            child: Container(
              width: 40,
              height: 40,
              decoration: BoxDecoration(
                color: isDark ? AppColors.darkCard : AppColors.lightSurface,
                shape: BoxShape.circle,
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(isDark ? 0.25 : 0.05),
                    blurRadius: 8,
                    offset: const Offset(0, 2),
                  ),
                ],
              ),
              alignment: Alignment.center,
              child: Icon(
                Icons.arrow_back_ios_new_rounded,
                size: 18,
                color: textPrimary,
              ),
            ),
          ),

          // Title & Date
          Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                'Daily Ayah',
                style: GoogleFonts.plusJakartaSans(
                  fontSize: 17,
                  fontWeight: FontWeight.bold,
                  color: textPrimary,
                  letterSpacing: -0.2,
                ),
              ),
              const SizedBox(height: 1),
              Text(
                _formatDate(widget.date ?? DateTime.now()),
                style: GoogleFonts.plusJakartaSans(
                  fontSize: 11,
                  fontWeight: FontWeight.w500,
                  color: AppColors.accentGoldDark,
                ),
              ),
            ],
          ),

          // Header Actions: Bookmark & Share
          Row(
            children: [
              GestureDetector(
                onTap: _toggleBookmark,
                child: Container(
                  width: 40,
                  height: 40,
                  decoration: BoxDecoration(
                    color: isDark ? AppColors.darkCard : AppColors.lightSurface,
                    shape: BoxShape.circle,
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity(isDark ? 0.25 : 0.05),
                        blurRadius: 8,
                        offset: const Offset(0, 2),
                      ),
                    ],
                  ),
                  alignment: Alignment.center,
                  child: Icon(
                    _isBookmarked
                        ? Icons.bookmark_rounded
                        : Icons.bookmark_border_rounded,
                    size: 20,
                    color: _isBookmarked ? AppColors.quranGold : textSecondary,
                  ),
                ),
              ),
              const SizedBox(width: 8),
              GestureDetector(
                onTap: _copyToClipboard,
                child: Container(
                  width: 40,
                  height: 40,
                  decoration: BoxDecoration(
                    color: isDark ? AppColors.darkCard : AppColors.lightSurface,
                    shape: BoxShape.circle,
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity(isDark ? 0.25 : 0.05),
                        blurRadius: 8,
                        offset: const Offset(0, 2),
                      ),
                    ],
                  ),
                  alignment: Alignment.center,
                  child: Icon(
                    Icons.share_outlined,
                    size: 19,
                    color: textSecondary,
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildThematicVisual(bool isDark) {
    return GestureDetector(
      onTap: _openImageViewer,
      child: Container(
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(22),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(isDark ? 0.40 : 0.10),
              blurRadius: 20,
              offset: const Offset(0, 8),
            ),
          ],
        ),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(22),
          child: AspectRatio(
            aspectRatio: 16 / 9,
            child: Stack(
              fit: StackFit.expand,
              children: [
                // Base Thematic Image
                Image.asset(
                  _dailyAyah.imageAsset,
                  fit: BoxFit.cover,
                  filterQuality: FilterQuality.high,
                  errorBuilder: (context, error, stackTrace) => Container(
                    color: AppColors.deepEmerald,
                    alignment: Alignment.center,
                    child: const Icon(
                      Icons.landscape_rounded,
                      color: AppColors.quranGold,
                      size: 48,
                    ),
                  ),
                ),

                // Subtle Bottom Scrim for Title Tag
                Container(
                  decoration: const BoxDecoration(
                    gradient: LinearGradient(
                      begin: Alignment.topCenter,
                      end: Alignment.bottomCenter,
                      colors: [
                        Colors.transparent,
                        Color(0x30000000),
                        Color(0xB3000000),
                      ],
                      stops: [0.5, 0.75, 1.0],
                    ),
                  ),
                ),

                // Theme Tag & Tap Hint
                Positioned(
                  left: 14,
                  bottom: 12,
                  right: 14,
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Row(
                        children: [
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                            decoration: BoxDecoration(
                              color: Colors.black.withOpacity(0.45),
                              borderRadius: BorderRadius.circular(12),
                              border: Border.all(
                                color: Colors.white.withOpacity(0.18),
                                width: 0.8,
                              ),
                            ),
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                const Icon(
                                  Icons.spa_rounded,
                                  color: AppColors.quranGold,
                                  size: 13,
                                ),
                                const SizedBox(width: 5),
                                Text(
                                  _dailyAyah.themeTitle,
                                  style: GoogleFonts.plusJakartaSans(
                                    fontSize: 11,
                                    fontWeight: FontWeight.bold,
                                    color: Colors.white,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                      Container(
                        padding: const EdgeInsets.all(5),
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          color: Colors.black.withOpacity(0.40),
                        ),
                        child: const Icon(
                          Icons.fullscreen_rounded,
                          color: Colors.white70,
                          size: 16,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildAudioPlayer(
    bool isDark,
    Color surface,
    Color surfaceSubtle,
    Color textPrimary,
    Color textSecondary,
  ) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      decoration: BoxDecoration(
        color: isDark ? AppColors.darkCard : AppColors.lightSurface,
        borderRadius: BorderRadius.circular(22),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(isDark ? 0.30 : 0.05),
            blurRadius: 14,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        children: [
          // Reciter Selector & Speed Toggle Row
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              ValueListenableBuilder<Reciter>(
                valueListenable: _audioService.selectedReciterNotifier,
                builder: (context, reciter, _) {
                  return PopupMenuButton<Reciter>(
                    initialValue: reciter,
                    onSelected: (newReciter) {
                      _audioService.setReciter(newReciter);
                    },
                    color: isDark ? AppColors.darkCard : Colors.white,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(16),
                    ),
                    itemBuilder: (context) =>
                        QuranAudioService.availableReciters.map((r) {
                      final isSelected = r.id == reciter.id;
                      return PopupMenuItem<Reciter>(
                        value: r,
                        child: Row(
                          children: [
                            Icon(
                              isSelected
                                  ? Icons.radio_button_checked_rounded
                                  : Icons.radio_button_off_rounded,
                              size: 16,
                              color: isSelected ? AppColors.quranGold : textSecondary,
                            ),
                            const SizedBox(width: 8),
                            Expanded(
                              child: Text(
                                r.name,
                                style: GoogleFonts.plusJakartaSans(
                                  fontSize: 13,
                                  fontWeight:
                                      isSelected ? FontWeight.bold : FontWeight.normal,
                                  color: textPrimary,
                                ),
                              ),
                            ),
                          ],
                        ),
                      );
                    }).toList(),
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                      decoration: BoxDecoration(
                        color: surfaceSubtle,
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          const Icon(
                            Icons.record_voice_over_rounded,
                            size: 14,
                            color: AppColors.accentGoldDark,
                          ),
                          const SizedBox(width: 6),
                          Text(
                            reciter.name,
                            style: GoogleFonts.plusJakartaSans(
                              fontSize: 12,
                              fontWeight: FontWeight.w600,
                              color: textPrimary,
                            ),
                          ),
                          const SizedBox(width: 4),
                          Icon(
                            Icons.keyboard_arrow_down_rounded,
                            size: 16,
                            color: textSecondary,
                          ),
                        ],
                      ),
                    ),
                  );
                },
              ),

              // Playback Speed button
              GestureDetector(
                onTap: _togglePlaybackSpeed,
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 5),
                  decoration: BoxDecoration(
                    color: surfaceSubtle,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Text(
                    '${_playbackSpeed}x',
                    style: GoogleFonts.plusJakartaSans(
                      fontSize: 12,
                      fontWeight: FontWeight.bold,
                      color: AppColors.accentGoldDark,
                    ),
                  ),
                ),
              ),
            ],
          ),

          const SizedBox(height: 12),

          // Main Controls & Progress Slider
          StreamBuilder<Duration>(
            stream: _audioService.player.positionStream,
            builder: (context, posSnapshot) {
              final position = posSnapshot.data ?? Duration.zero;
              final duration =
                  _audioService.player.duration ?? const Duration(seconds: 1);
              final progress = (position.inMilliseconds / duration.inMilliseconds)
                  .clamp(0.0, 1.0);

              return Row(
                children: [
                  // Play / Pause Button
                  ValueListenableBuilder<bool>(
                    valueListenable: _audioService.isPlayingNotifier,
                    builder: (context, isPlaying, _) {
                      return ValueListenableBuilder<bool>(
                        valueListenable: _audioService.isLoadingNotifier,
                        builder: (context, isLoading, _) {
                          return GestureDetector(
                            onTap: () {
                              if (isPlaying) {
                                _audioService.pause();
                              } else {
                                _audioService.playAyah(
                                  surahNumber: _dailyAyah.surahNumber,
                                  ayahNumber: _dailyAyah.ayahNumber,
                                  maxVerses: 286,
                                );
                              }
                            },
                            child: Container(
                              width: 46,
                              height: 46,
                              decoration: const BoxDecoration(
                                shape: BoxShape.circle,
                                color: AppColors.quranGold,
                                boxShadow: [
                                  BoxShadow(
                                    color: Color(0x35F5CE63),
                                    blurRadius: 10,
                                    offset: Offset(0, 3),
                                  ),
                                ],
                              ),
                              alignment: Alignment.center,
                              child: isLoading
                                  ? const SizedBox(
                                      width: 20,
                                      height: 20,
                                      child: CircularProgressIndicator(
                                        strokeWidth: 2.2,
                                        valueColor:
                                            AlwaysStoppedAnimation<Color>(
                                                AppColors.midnightNavy),
                                      ),
                                    )
                                  : Icon(
                                      isPlaying
                                          ? Icons.pause_rounded
                                          : Icons.play_arrow_rounded,
                                      color: AppColors.midnightNavy,
                                      size: 26,
                                    ),
                            ),
                          );
                        },
                      );
                    },
                  ),

                  const SizedBox(width: 14),

                  // Progress Slider & Timers
                  Expanded(
                    child: Column(
                      children: [
                        SliderTheme(
                          data: SliderThemeData(
                            trackHeight: 3.5,
                            activeTrackColor: AppColors.quranGold,
                            inactiveTrackColor: isDark
                                ? Colors.white12
                                : const Color(0xFFE5DFD4),
                            thumbColor: AppColors.accentGoldDark,
                            thumbShape: const RoundSliderThumbShape(
                                enabledThumbRadius: 6.0),
                            overlayShape: const RoundSliderOverlayShape(
                                overlayRadius: 12.0),
                          ),
                          child: Slider(
                            value: progress,
                            onChanged: (val) {
                              final target = Duration(
                                  milliseconds:
                                      (val * duration.inMilliseconds).round());
                              _audioService.player.seek(target);
                            },
                          ),
                        ),
                        Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 6),
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Text(
                                _formatDuration(position),
                                style: GoogleFonts.plusJakartaSans(
                                  fontSize: 10,
                                  color: textSecondary,
                                  fontWeight: FontWeight.w500,
                                ),
                              ),
                              Text(
                                _formatDuration(duration),
                                style: GoogleFonts.plusJakartaSans(
                                  fontSize: 10,
                                  color: textSecondary,
                                  fontWeight: FontWeight.w500,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              );
            },
          ),
        ],
      ),
    );
  }

  Widget _buildTranslationSelector(
    bool isDark,
    Color textPrimary,
    Color textSecondary,
  ) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.only(left: 4, bottom: 8),
          child: Text(
            'TRANSLATION',
            style: GoogleFonts.plusJakartaSans(
              fontSize: 10.5,
              fontWeight: FontWeight.w800,
              letterSpacing: 1.2,
              color: textSecondary,
            ),
          ),
        ),
        SizedBox(
          height: 38,
          child: ListView.separated(
            scrollDirection: Axis.horizontal,
            physics: const BouncingScrollPhysics(),
            itemCount: DailyAyahService.supportedTranslations.length,
            separatorBuilder: (_, __) => const SizedBox(width: 8),
            itemBuilder: (context, index) {
              final edition = DailyAyahService.supportedTranslations[index];
              final isSelected = edition.id == _selectedEdition.id;

              return GestureDetector(
                onTap: () => _onSelectTranslation(edition),
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 200),
                  padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                  decoration: BoxDecoration(
                    color: isSelected
                        ? (isDark ? AppColors.quranGold : AppColors.deepEmerald)
                        : (isDark ? AppColors.darkCard : AppColors.lightSurface),
                    borderRadius: BorderRadius.circular(19),
                    boxShadow: isSelected
                        ? [
                            BoxShadow(
                              color: (isDark
                                      ? AppColors.quranGold
                                      : AppColors.deepEmerald)
                                  .withOpacity(0.25),
                              blurRadius: 8,
                              offset: const Offset(0, 3),
                            ),
                          ]
                        : null,
                  ),
                  alignment: Alignment.center,
                  child: Text(
                    edition.languageName,
                    style: GoogleFonts.plusJakartaSans(
                      fontSize: 12,
                      fontWeight: isSelected ? FontWeight.bold : FontWeight.w500,
                      color: isSelected
                          ? (isDark ? AppColors.midnightNavy : Colors.white)
                          : textPrimary,
                    ),
                  ),
                ),
              );
            },
          ),
        ),
      ],
    );
  }

  Widget _buildMainAyahContent(
    bool isDark,
    Color surface,
    Color textPrimary,
    Color textSecondary,
  ) {
    return Container(
      padding: const EdgeInsets.fromLTRB(20, 22, 20, 24),
      decoration: BoxDecoration(
        color: surface,
        borderRadius: BorderRadius.circular(26),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(isDark ? 0.35 : 0.06),
            blurRadius: 20,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // Surah & Ayah Citation Header
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(
                  color: isDark
                      ? AppColors.darkInnerCard
                      : AppColors.lightSurfaceSubtle,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Text(
                  _dailyAyah.shortCitation.toUpperCase(),
                  style: GoogleFonts.plusJakartaSans(
                    fontSize: 11,
                    fontWeight: FontWeight.bold,
                    letterSpacing: 0.8,
                    color: AppColors.accentGoldDark,
                  ),
                ),
              ),
              Text(
                _dailyAyah.surahNameArabic,
                style: GoogleFonts.amiri(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: textSecondary,
                ),
              ),
            ],
          ),

          const SizedBox(height: 22),

          // Authentic Arabic Quran Text
          Directionality(
            textDirection: TextDirection.rtl,
            child: Text(
              _dailyAyah.arabicText,
              textAlign: TextAlign.center,
              style: GoogleFonts.amiri(
                fontSize: _arabicFontSize,
                fontWeight: FontWeight.bold,
                height: 2.1,
                color: textPrimary,
                letterSpacing: 0.2,
              ),
            ),
          ),

          const SizedBox(height: 18),

          // Hairline divider
          Container(
            height: 1,
            color: isDark
                ? Colors.white.withOpacity(0.08)
                : const Color(0xFFEFE9DE),
          ),

          const SizedBox(height: 18),

          // Selected Translation Content
          if (_isLoadingTranslation)
            const Padding(
              padding: EdgeInsets.symmetric(vertical: 16),
              child: Center(
                child: SizedBox(
                  width: 22,
                  height: 22,
                  child: CircularProgressIndicator(
                    strokeWidth: 2,
                    valueColor:
                        AlwaysStoppedAnimation<Color>(AppColors.accentGoldDark),
                  ),
                ),
              ),
            )
          else ...[
            Text(
              _currentTranslationText,
              textAlign: _selectedEdition.isRtl ? TextAlign.right : TextAlign.left,
              textDirection:
                  _selectedEdition.isRtl ? TextDirection.rtl : TextDirection.ltr,
              style: GoogleFonts.plusJakartaSans(
                fontSize: 15.5,
                fontWeight: FontWeight.w500,
                height: 1.55,
                color: textPrimary.withOpacity(0.92),
              ),
            ),
            const SizedBox(height: 10),
            Text(
              '— ${_selectedEdition.authorName}',
              textAlign:
                  _selectedEdition.isRtl ? TextAlign.right : TextAlign.left,
              style: GoogleFonts.plusJakartaSans(
                fontSize: 11.5,
                fontStyle: FontStyle.italic,
                fontWeight: FontWeight.w500,
                color: textSecondary,
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildExplanationSection(
    bool isDark,
    Color surfaceSubtle,
    Color textPrimary,
    Color textSecondary,
  ) {
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: surfaceSubtle,
        borderRadius: BorderRadius.circular(22),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(
                Icons.lightbulb_outline_rounded,
                size: 16,
                color: AppColors.accentGoldDark,
              ),
              const SizedBox(width: 8),
              Text(
                'Understanding this ayah',
                style: GoogleFonts.plusJakartaSans(
                  fontSize: 13,
                  fontWeight: FontWeight.bold,
                  color: textPrimary,
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          Text(
            _dailyAyah.explanation,
            style: GoogleFonts.plusJakartaSans(
              fontSize: 13,
              height: 1.5,
              color: textPrimary.withOpacity(0.85),
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Source: ${_dailyAyah.tafsirAttribution}',
            style: GoogleFonts.plusJakartaSans(
              fontSize: 11,
              fontStyle: FontStyle.italic,
              color: textSecondary,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildQuickActionsBar(
    bool isDark,
    Color surface,
    Color textPrimary,
    Color textSecondary,
  ) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        // Text Size Controls (A- / A+)
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
          decoration: BoxDecoration(
            color: surface,
            borderRadius: BorderRadius.circular(16),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(isDark ? 0.20 : 0.04),
                blurRadius: 8,
                offset: const Offset(0, 2),
              ),
            ],
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              IconButton(
                icon: const Icon(Icons.remove_rounded, size: 18),
                color: textPrimary,
                onPressed: () => _changeFontSize(-2.0),
                tooltip: 'Decrease text size',
              ),
              Text(
                'A',
                style: GoogleFonts.plusJakartaSans(
                  fontSize: 14,
                  fontWeight: FontWeight.bold,
                  color: AppColors.accentGoldDark,
                ),
              ),
              IconButton(
                icon: const Icon(Icons.add_rounded, size: 18),
                color: textPrimary,
                onPressed: () => _changeFontSize(2.0),
                tooltip: 'Increase text size',
              ),
            ],
          ),
        ),

        // Action Buttons: Copy & Share
        Row(
          children: [
            GestureDetector(
              onTap: _copyToClipboard,
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                decoration: BoxDecoration(
                  color: surface,
                  borderRadius: BorderRadius.circular(16),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(isDark ? 0.20 : 0.04),
                      blurRadius: 8,
                      offset: const Offset(0, 2),
                    ),
                  ],
                ),
                child: Row(
                  children: [
                    Icon(Icons.copy_rounded, size: 16, color: textPrimary),
                    const SizedBox(width: 6),
                    Text(
                      'Copy',
                      style: GoogleFonts.plusJakartaSans(
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                        color: textPrimary,
                      ),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(width: 8),
            GestureDetector(
              onTap: _toggleBookmark,
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                decoration: BoxDecoration(
                  color: _isBookmarked
                      ? AppColors.quranGold
                      : (isDark ? AppColors.darkCard : AppColors.lightSurface),
                  borderRadius: BorderRadius.circular(16),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(isDark ? 0.20 : 0.04),
                      blurRadius: 8,
                      offset: const Offset(0, 2),
                    ),
                  ],
                ),
                child: Row(
                  children: [
                    Icon(
                      _isBookmarked
                          ? Icons.bookmark_rounded
                          : Icons.bookmark_border_rounded,
                      size: 16,
                      color: _isBookmarked
                          ? AppColors.midnightNavy
                          : textPrimary,
                    ),
                    const SizedBox(width: 6),
                    Text(
                      _isBookmarked ? 'Saved' : 'Save',
                      style: GoogleFonts.plusJakartaSans(
                        fontSize: 12,
                        fontWeight: FontWeight.bold,
                        color: _isBookmarked
                            ? AppColors.midnightNavy
                            : textPrimary,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ],
    );
  }
}
