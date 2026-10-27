import 'dart:math' as math;
import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
import '../constants/app_colors.dart';
import '../services/audio_service.dart';
import '../services/daily_ayah_service.dart';
import '../services/storage_service.dart';

class DailyAyahScreen extends StatefulWidget {
  final DateTime? date;
  final bool isEmbeddedInShell;
  final ValueChanged<int>? onNavigateTab;

  const DailyAyahScreen({
    super.key,
    this.date,
    this.isEmbeddedInShell = false,
    this.onNavigateTab,
  });

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
  int _selectedExplanationTab = 0; // 0: Tafsir, 1: Key Lessons, 2: Word Breakdown

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
        // Only start auto-play if audio is not already playing in another screen
        if (!_audioService.isPlayingNotifier.value) {
          _audioService.playAyah(
            surahNumber: _dailyAyah.surahNumber,
            ayahNumber: _dailyAyah.ayahNumber,
            maxVerses: 286,
          );
        }
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

    final screenWidth = MediaQuery.of(context).size.width;
    final topPadding = MediaQuery.of(context).padding.top;
    final muftaHeight = screenWidth * 0.58 + topPadding;

    return Scaffold(
      backgroundColor: bg,
      body: Stack(
        children: [
          // 1. Signature Mufta Islamic Archway Backdrop at the top with curved bottom corners
          Positioned(
            top: 0,
            left: 0,
            right: 0,
            child: SizedBox(
              height: muftaHeight,
              child: ClipRRect(
                borderRadius: const BorderRadius.vertical(
                  bottom: Radius.circular(40),
                ),
                child: Stack(
                  fit: StackFit.expand,
                  children: [
                    Container(color: const Color(0xFF0D2F1F)),
                    Image.asset(
                      'assets/new_mufta.jpg',
                      fit: BoxFit.cover,
                      alignment: Alignment.topCenter,
                      filterQuality: FilterQuality.high,
                    ),
                    Container(
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          begin: Alignment.topCenter,
                          end: Alignment.bottomCenter,
                          colors: [
                            Colors.black.withOpacity(0.18),
                            Colors.transparent,
                            (isDark
                                    ? AppColors.darkSurface
                                    : AppColors.lightBackground)
                                .withOpacity(0.85),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),

          // 2. Main Foreground Scrollable Content
          SafeArea(
            child: Column(
              children: [
                // A. Compact Liquid Glass Top Header
                _buildHeader(isDark, textPrimary, textSecondary),

                // Scrollable Content
                Expanded(
                  child: SingleChildScrollView(
                    physics: const BouncingScrollPhysics(),
                    padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        // B. Thematic Visual with Integrated Centered Audio Frequency Waves & Reciter
                        _buildThematicVisualWithAudio(isDark, textPrimary, textSecondary),

                        const SizedBox(height: 18),

                        // C. Main Ayah Content (Directly below image, saving massive vertical space)
                        _buildMainAyahContent(isDark, surface, textPrimary, textSecondary),

                        const SizedBox(height: 18),

                        // D. Upgraded "Understanding this ayah" (Tafsir & Reflection)
                        _buildExplanationSection(isDark, surfaceSubtle, textPrimary, textSecondary),

                        const SizedBox(height: 20),

                        // E. Quick Actions Bar
                        _buildQuickActionsBar(isDark, surface, textPrimary, textSecondary),

                        SizedBox(height: widget.isEmbeddedInShell ? 120 : 36),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  /// Compact iOS-inspired Liquid Glass Top Header
  Widget _buildHeader(bool isDark, Color textPrimary, Color textSecondary) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 6, 16, 8),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          // Back button with liquid glass blur
          _buildLiquidGlassCircleButton(
            isDark: isDark,
            onTap: () {
              if (widget.isEmbeddedInShell) {
                widget.onNavigateTab?.call(0);
              } else if (Navigator.of(context).canPop()) {
                Navigator.of(context).pop();
              }
            },
            child: Icon(
              Icons.arrow_back_ios_new_rounded,
              size: 17,
              color: textPrimary,
            ),
          ),

          // Center Title & Date
          Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                'Daily Ayah',
                style: GoogleFonts.plusJakartaSans(
                  fontSize: 16.5,
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
                  fontWeight: FontWeight.w600,
                  color: AppColors.accentGoldDark,
                ),
              ),
            ],
          ),

          // Right Action Area: Translation Dropdown Menu, Bookmark, Share
          Row(
            children: [
              // Liquid Glass Translation Dropdown Selector
              _buildTranslationDropdownMenu(isDark, textPrimary, textSecondary),

              const SizedBox(width: 7),

              // Bookmark Toggle
              _buildLiquidGlassCircleButton(
                isDark: isDark,
                onTap: _toggleBookmark,
                child: Icon(
                  _isBookmarked
                      ? Icons.bookmark_rounded
                      : Icons.bookmark_border_rounded,
                  size: 19,
                  color: _isBookmarked ? AppColors.quranGold : textSecondary,
                ),
              ),

              const SizedBox(width: 7),

              // Share Button
              _buildLiquidGlassCircleButton(
                isDark: isDark,
                onTap: _copyToClipboard,
                child: Icon(
                  Icons.share_outlined,
                  size: 18,
                  color: textSecondary,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  /// Reusable Liquid Glass Circular Button
  Widget _buildLiquidGlassCircleButton({
    required bool isDark,
    required VoidCallback onTap,
    required Widget child,
    double size = 38,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: ClipRRect(
        borderRadius: BorderRadius.circular(size / 2),
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 12, sigmaY: 12),
          child: Container(
            width: size,
            height: size,
            decoration: BoxDecoration(
              color: (isDark ? Colors.black : Colors.white).withOpacity(0.42),
              shape: BoxShape.circle,
              border: Border.all(
                color: (isDark ? Colors.white : Colors.black).withOpacity(0.12),
                width: 0.8,
              ),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(isDark ? 0.25 : 0.05),
                  blurRadius: 8,
                  offset: const Offset(0, 2),
                ),
              ],
            ),
            alignment: Alignment.center,
            child: child,
          ),
        ),
      ),
    );
  }

  /// Compact iOS-style Liquid Glass Translation Selector Dropdown in Top Header
  Widget _buildTranslationDropdownMenu(
    bool isDark,
    Color textPrimary,
    Color textSecondary,
  ) {
    return PopupMenuButton<TranslationEdition>(
      initialValue: _selectedEdition,
      onSelected: _onSelectTranslation,
      elevation: 10,
      color: isDark ? AppColors.darkCard : Colors.white,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(18),
        side: BorderSide(
          color: (isDark ? Colors.white : Colors.black).withOpacity(0.08),
          width: 0.8,
        ),
      ),
      itemBuilder: (context) => DailyAyahService.supportedTranslations.map((edition) {
        final isSelected = edition.id == _selectedEdition.id;
        return PopupMenuItem<TranslationEdition>(
          value: edition,
          child: Row(
            children: [
              Icon(
                isSelected
                    ? Icons.check_circle_rounded
                    : Icons.radio_button_unchecked_rounded,
                size: 16,
                color: isSelected ? AppColors.accentGoldDark : textSecondary,
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      edition.languageName,
                      style: GoogleFonts.plusJakartaSans(
                        fontSize: 13,
                        fontWeight:
                            isSelected ? FontWeight.bold : FontWeight.w500,
                        color: textPrimary,
                      ),
                    ),
                    Text(
                      edition.authorName,
                      style: GoogleFonts.plusJakartaSans(
                        fontSize: 10.5,
                        color: textSecondary,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                ),
              ),
            ],
          ),
        );
      }).toList(),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(19),
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 12, sigmaY: 12),
          child: Container(
            height: 38,
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
            decoration: BoxDecoration(
              color: (isDark ? Colors.black : Colors.white).withOpacity(0.42),
              borderRadius: BorderRadius.circular(19),
              border: Border.all(
                color: (isDark ? Colors.white : Colors.black).withOpacity(0.12),
                width: 0.8,
              ),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Icon(
                  Icons.translate_rounded,
                  size: 14,
                  color: AppColors.accentGoldDark,
                ),
                const SizedBox(width: 5),
                Text(
                  _selectedEdition.languageName,
                  style: GoogleFonts.plusJakartaSans(
                    fontSize: 11.5,
                    fontWeight: FontWeight.w600,
                    color: textPrimary,
                  ),
                ),
                const SizedBox(width: 2),
                Icon(
                  Icons.keyboard_arrow_down_rounded,
                  size: 15,
                  color: textSecondary,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  /// Thematic Visual with Active Animated Frequency Waves, Reciter Profile Image & Controls Overlaid
  Widget _buildThematicVisualWithAudio(
    bool isDark,
    Color textPrimary,
    Color textSecondary,
  ) {
    return Container(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(24),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(isDark ? 0.45 : 0.12),
            blurRadius: 22,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(24),
        child: AspectRatio(
          aspectRatio: 16 / 10.5,
          child: Stack(
            fit: StackFit.expand,
            children: [
              // 1. Base Thematic Visual Image
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

              // 2. Subtle Dark Scrim across entire image for high contrast readability
              Container(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                    colors: [
                      Colors.black.withOpacity(0.35),
                      Colors.black.withOpacity(0.20),
                      Colors.black.withOpacity(0.70),
                    ],
                    stops: const [0.0, 0.45, 1.0],
                  ),
                ),
              ),

              // 3. Top Row inside image: Theme Tag & Fullscreen Zoom Icon
              Positioned(
                top: 12,
                left: 14,
                right: 14,
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    // Theme Tag
                    ClipRRect(
                      borderRadius: BorderRadius.circular(14),
                      child: BackdropFilter(
                        filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
                        child: Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 10, vertical: 5),
                          decoration: BoxDecoration(
                            color: Colors.black.withOpacity(0.42),
                            borderRadius: BorderRadius.circular(14),
                            border: Border.all(
                              color: Colors.white.withOpacity(0.20),
                              width: 0.8,
                            ),
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              const Icon(
                                Icons.spa_rounded,
                                color: AppColors.quranGold,
                                size: 12,
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
                      ),
                    ),

                    // Fullscreen Zoom Button
                    GestureDetector(
                      onTap: _openImageViewer,
                      child: ClipRRect(
                        borderRadius: BorderRadius.circular(14),
                        child: BackdropFilter(
                          filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
                          child: Container(
                            padding: const EdgeInsets.all(6),
                            decoration: BoxDecoration(
                              color: Colors.black.withOpacity(0.42),
                              shape: BoxShape.circle,
                              border: Border.all(
                                color: Colors.white.withOpacity(0.20),
                                width: 0.8,
                              ),
                            ),
                            child: const Icon(
                              Icons.fullscreen_rounded,
                              color: Colors.white,
                              size: 17,
                            ),
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),

              // 4. Centered Interactive Audio Stage: Reciter Profile + Play/Pause + Active Frequency Waves
              Center(
                child: _buildCenteredAudioOverlay(isDark, textPrimary, textSecondary),
              ),

              // 5. Bottom Interactive Progress Scrub Line & Timestamps
              Positioned(
                left: 14,
                right: 14,
                bottom: 8,
                child: _buildImageBottomProgress(),
              ),
            ],
          ),
        ),
      ),
    );
  }

  /// Centered Glassmorphic Stage with Reciter Profile, Play Button & Frequency Waveform
  Widget _buildCenteredAudioOverlay(
    bool isDark,
    Color textPrimary,
    Color textSecondary,
  ) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        // A. Reciter Profile Image with Tap-to-Change Popup Menu
              ValueListenableBuilder<Reciter>(
                valueListenable: _audioService.selectedReciterNotifier,
                builder: (context, reciter, _) {
                  return PopupMenuButton<Reciter>(
                    initialValue: reciter,
                    onSelected: (newReciter) {
                      _audioService.setReciter(newReciter);
                      // Re-trigger playback for selected reciter
                      _audioService.playAyah(
                        surahNumber: _dailyAyah.surahNumber,
                        ayahNumber: _dailyAyah.ayahNumber,
                        maxVerses: 286,
                      );
                    },
                    tooltip: 'Change Reciter',
                    color: isDark ? AppColors.darkCard : Colors.white,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(18),
                      side: BorderSide(
                        color: (isDark ? Colors.white : Colors.black)
                            .withOpacity(0.08),
                        width: 0.8,
                      ),
                    ),
                    itemBuilder: (context) =>
                        QuranAudioService.availableReciters.map((r) {
                      final isSelected = r.id == reciter.id;
                      return PopupMenuItem<Reciter>(
                        value: r,
                        child: Row(
                          children: [
                            ClipRRect(
                              borderRadius: BorderRadius.circular(14),
                              child: Image.asset(
                                r.imageAsset,
                                width: 28,
                                height: 28,
                                fit: BoxFit.cover,
                                errorBuilder: (_, __, ___) => const Icon(
                                  Icons.person_rounded,
                                  size: 20,
                                ),
                              ),
                            ),
                            const SizedBox(width: 10),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Text(
                                    r.name,
                                    style: GoogleFonts.plusJakartaSans(
                                      fontSize: 13,
                                      fontWeight: isSelected
                                          ? FontWeight.bold
                                          : FontWeight.normal,
                                      color: textPrimary,
                                    ),
                                  ),
                                  Text(
                                    r.description,
                                    style: GoogleFonts.plusJakartaSans(
                                      fontSize: 10.5,
                                      color: textSecondary,
                                    ),
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                ],
                              ),
                            ),
                            if (isSelected)
                              const Icon(
                                Icons.check_circle_rounded,
                                size: 16,
                                color: AppColors.quranGold,
                              ),
                          ],
                        ),
                      );
                    }).toList(),
                    child: Stack(
                      alignment: Alignment.bottomRight,
                      children: [
                        Container(
                          width: 40,
                          height: 40,
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            border: Border.all(
                              color: AppColors.quranGold,
                              width: 1.8,
                            ),
                            boxShadow: [
                              BoxShadow(
                                color: AppColors.quranGold.withOpacity(0.4),
                                blurRadius: 8,
                              ),
                            ],
                          ),
                          child: ClipOval(
                            child: Image.asset(
                              reciter.imageAsset,
                              fit: BoxFit.cover,
                              errorBuilder: (context, error, stackTrace) =>
                                  Container(
                                color: AppColors.deepEmerald,
                                child: const Icon(
                                  Icons.person_rounded,
                                  color: Colors.white,
                                  size: 20,
                                ),
                              ),
                            ),
                          ),
                        ),
                        // Micro reciter switch badge
                        Container(
                          padding: const EdgeInsets.all(1.5),
                          decoration: const BoxDecoration(
                            color: AppColors.accentGoldDark,
                            shape: BoxShape.circle,
                          ),
                          child: const Icon(
                            Icons.swap_horiz_rounded,
                            size: 9,
                            color: Colors.white,
                          ),
                        ),
                      ],
                    ),
                  );
                },
              ),

              const SizedBox(width: 10),

              // B. Play / Pause Button & C. Active Animated Frequency Bars
              ValueListenableBuilder<bool>(
                valueListenable: _audioService.isPlayingNotifier,
                builder: (context, isPlaying, _) {
                  return ValueListenableBuilder<int?>(
                    valueListenable: _audioService.currentPlayingSurah,
                    builder: (context, currentSurah, _) {
                      return ValueListenableBuilder<int?>(
                        valueListenable: _audioService.currentPlayingAyah,
                        builder: (context, currentAyah, _) {
                          final isThisAyahPlaying = isPlaying &&
                              currentSurah == _dailyAyah.surahNumber &&
                              currentAyah == _dailyAyah.ayahNumber;

                          return ValueListenableBuilder<bool>(
                            valueListenable: _audioService.isLoadingNotifier,
                            builder: (context, isLoading, _) {
                              final isThisAyahLoading = isLoading &&
                                  currentSurah == _dailyAyah.surahNumber &&
                                  currentAyah == _dailyAyah.ayahNumber;

                              return Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  GestureDetector(
                                    onTap: () {
                                      if (isThisAyahPlaying) {
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
                                      width: 40,
                                      height: 40,
                                      decoration: const BoxDecoration(
                                        shape: BoxShape.circle,
                                        color: AppColors.quranGold,
                                        boxShadow: [
                                          BoxShadow(
                                            color: Color(0x60F5CE63),
                                            blurRadius: 10,
                                            offset: Offset(0, 2),
                                          ),
                                        ],
                                      ),
                                      alignment: Alignment.center,
                                      child: isThisAyahLoading
                                          ? const SizedBox(
                                              width: 18,
                                              height: 18,
                                              child: CircularProgressIndicator(
                                                strokeWidth: 2,
                                                valueColor:
                                                    AlwaysStoppedAnimation<Color>(
                                                        AppColors.midnightNavy),
                                              ),
                                            )
                                          : Icon(
                                              isThisAyahPlaying
                                                  ? Icons.pause_rounded
                                                  : Icons.play_arrow_rounded,
                                              color: AppColors.midnightNavy,
                                              size: 24,
                                            ),
                                    ),
                                  ),
                                  const SizedBox(width: 10),
                                  _FrequencyWaveBars(
                                    isPlaying: isThisAyahPlaying,
                                    barColor: AppColors.quranGold,
                                  ),
                                ],
                              );
                            },
                          );
                        },
                      );
                    },
                  );
                },
              ),

              const SizedBox(width: 10),

              // D. Playback Speed Selector Tag
              GestureDetector(
                onTap: _togglePlaybackSpeed,
                child: Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: Colors.white.withOpacity(0.18),
                    borderRadius: BorderRadius.circular(10),
                    border: Border.all(
                      color: Colors.white.withOpacity(0.20),
                      width: 0.6,
                    ),
                  ),
                  child: Text(
                    '${_playbackSpeed}x',
                    style: GoogleFonts.plusJakartaSans(
                      fontSize: 11,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                    ),
                  ),
                ),
              ),
            ],
          );
  }

  /// Subtle Bottom Progress Bar and Duration Timestamps inside Image
  Widget _buildImageBottomProgress() {
    return StreamBuilder<Duration>(
      stream: _audioService.player.positionStream,
      builder: (context, posSnapshot) {
        final position = posSnapshot.data ?? Duration.zero;
        final duration =
            _audioService.player.duration ?? const Duration(seconds: 1);
        final progress =
            (position.inMilliseconds / duration.inMilliseconds).clamp(0.0, 1.0);

        return Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            SliderTheme(
              data: SliderThemeData(
                trackHeight: 2.8,
                activeTrackColor: AppColors.quranGold,
                inactiveTrackColor: Colors.white.withOpacity(0.25),
                thumbColor: AppColors.quranGold,
                thumbShape:
                    const RoundSliderThumbShape(enabledThumbRadius: 4.5),
                overlayShape:
                    const RoundSliderOverlayShape(overlayRadius: 8.0),
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
                      color: Colors.white.withOpacity(0.85),
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  Text(
                    _formatDuration(duration),
                    style: GoogleFonts.plusJakartaSans(
                      fontSize: 10,
                      color: Colors.white.withOpacity(0.85),
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ],
              ),
            ),
          ],
        );
      },
    );
  }

  /// Main Ayah Content Card (Brought directly below image for optimal space utilization)
  Widget _buildMainAyahContent(
    bool isDark,
    Color surface,
    Color textPrimary,
    Color textSecondary,
  ) {
    return Container(
      padding: const EdgeInsets.fromLTRB(20, 20, 20, 22),
      decoration: BoxDecoration(
        color: surface,
        borderRadius: BorderRadius.circular(24),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(isDark ? 0.35 : 0.06),
            blurRadius: 18,
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
                padding:
                    const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
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

          const SizedBox(height: 18),

          // Authentic Arabic Quran Text in Amiri Font
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

          const SizedBox(height: 16),

          // Hairline divider
          Container(
            height: 1,
            color: isDark
                ? Colors.white.withOpacity(0.08)
                : const Color(0xFFEFE9DE),
          ),

          const SizedBox(height: 16),

          // Selected Translation Content
          if (_isLoadingTranslation)
            const Padding(
              padding: EdgeInsets.symmetric(vertical: 14),
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
              textAlign:
                  _selectedEdition.isRtl ? TextAlign.right : TextAlign.left,
              textDirection: _selectedEdition.isRtl
                  ? TextDirection.rtl
                  : TextDirection.ltr,
              style: GoogleFonts.plusJakartaSans(
                fontSize: 15,
                fontWeight: FontWeight.w500,
                height: 1.55,
                color: textPrimary.withOpacity(0.92),
              ),
            ),
            const SizedBox(height: 8),
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

  /// Upgraded "Understanding this ayah" (Advanced Tafsir, Fawa'id Lessons & Vocabulary)
  Widget _buildExplanationSection(
    bool isDark,
    Color surfaceSubtle,
    Color textPrimary,
    Color textSecondary,
  ) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: surfaceSubtle,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(
          color: AppColors.quranGold.withOpacity(isDark ? 0.22 : 0.28),
          width: 1.0,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(isDark ? 0.20 : 0.04),
            blurRadius: 14,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header Row with Golden Book/Lamp Icon & Scholarly Badge
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(7),
                    decoration: BoxDecoration(
                      color: AppColors.quranGold.withOpacity(0.18),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: const Icon(
                      Icons.auto_stories_rounded,
                      size: 16,
                      color: AppColors.accentGoldDark,
                    ),
                  ),
                  const SizedBox(width: 9),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'TAFSIR & REFLECTION',
                        style: GoogleFonts.plusJakartaSans(
                          fontSize: 9.5,
                          fontWeight: FontWeight.w800,
                          letterSpacing: 1.2,
                          color: AppColors.accentGoldDark,
                        ),
                      ),
                      Text(
                        'Understanding this ayah',
                        style: GoogleFonts.plusJakartaSans(
                          fontSize: 13.5,
                          fontWeight: FontWeight.bold,
                          color: textPrimary,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
              Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 8, vertical: 3.5),
                decoration: BoxDecoration(
                  color: isDark
                      ? Colors.white.withOpacity(0.06)
                      : Colors.black.withOpacity(0.04),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(
                  'Classical',
                  style: GoogleFonts.plusJakartaSans(
                    fontSize: 10,
                    fontWeight: FontWeight.w600,
                    color: textSecondary,
                  ),
                ),
              ),
            ],
          ),

          const SizedBox(height: 14),

          // Multi-tab Segmented Switcher (Exegesis, Key Lessons, Vocabulary)
          Container(
            padding: const EdgeInsets.all(4),
            decoration: BoxDecoration(
              color: isDark
                  ? Colors.white.withOpacity(0.06)
                  : const Color(0xFFEFE9DC),
              borderRadius: BorderRadius.circular(16),
            ),
            child: Row(
              children: [
                _buildExplanationTabItem(0, 'Exegesis', Icons.menu_book_rounded, isDark),
                _buildExplanationTabItem(1, 'Key Lessons', Icons.lightbulb_outline_rounded, isDark),
                _buildExplanationTabItem(2, 'Vocabulary', Icons.translate_rounded, isDark),
              ],
            ),
          ),

          const SizedBox(height: 16),

          // Dynamic Tab Content
          AnimatedSwitcher(
            duration: const Duration(milliseconds: 220),
            child: _selectedExplanationTab == 0
                ? _buildTafsirTabContent(isDark, textPrimary, textSecondary)
                : _selectedExplanationTab == 1
                    ? _buildLessonsTabContent(isDark, textPrimary, textSecondary)
                    : _buildVocabularyTabContent(isDark, textPrimary, textSecondary),
          ),

          const SizedBox(height: 16),

          // Hairline separator
          Container(
            height: 0.8,
            color: isDark
                ? Colors.white.withOpacity(0.08)
                : const Color(0xFFE5DFD4),
          ),

          const SizedBox(height: 12),

          // Bottom Action Buttons (Copy & Share Wisdom)
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(
                children: [
                  const Icon(
                    Icons.verified_rounded,
                    size: 13,
                    color: AppColors.accentGoldDark,
                  ),
                  const SizedBox(width: 5),
                  Text(
                    'Source: ${_dailyAyah.tafsirAttribution}',
                    style: GoogleFonts.plusJakartaSans(
                      fontSize: 11,
                      fontStyle: FontStyle.italic,
                      fontWeight: FontWeight.w500,
                      color: textSecondary,
                    ),
                  ),
                ],
              ),
              Row(
                children: [
                  IconButton(
                    tooltip: 'Copy Ayah & Tafsir',
                    padding: EdgeInsets.zero,
                    constraints: const BoxConstraints(),
                    icon: Icon(
                      Icons.copy_rounded,
                      size: 16,
                      color: textSecondary,
                    ),
                    onPressed: () {
                      HapticFeedback.lightImpact();
                      Clipboard.setData(
                        ClipboardData(
                          text:
                              '${_dailyAyah.arabicText}\n"${_dailyAyah.defaultTranslation}"\n— ${_dailyAyah.reference}\n\nTafsir:\n${_dailyAyah.explanation} (${_dailyAyah.tafsirAttribution})',
                        ),
                      );
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(
                          content: Text(
                            'Ayah & Tafsir copied to clipboard',
                            style: GoogleFonts.plusJakartaSans(),
                          ),
                          behavior: SnackBarBehavior.floating,
                          duration: const Duration(seconds: 2),
                        ),
                      );
                    },
                  ),
                  const SizedBox(width: 14),
                  IconButton(
                    tooltip: 'Share Wisdom',
                    padding: EdgeInsets.zero,
                    constraints: const BoxConstraints(),
                    icon: const Icon(
                      Icons.share_outlined,
                      size: 16,
                      color: AppColors.accentGoldDark,
                    ),
                    onPressed: () {
                      HapticFeedback.lightImpact();
                      Clipboard.setData(
                        ClipboardData(
                          text:
                              '✨ Daily Quran Reflection ✨\n${_dailyAyah.arabicText}\n"${_dailyAyah.defaultTranslation}"\n— ${_dailyAyah.reference}\n\nReflection: ${_dailyAyah.explanation}',
                        ),
                      );
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(
                          content: Text(
                            'Reflection formatted & copied to share!',
                            style: GoogleFonts.plusJakartaSans(),
                          ),
                          behavior: SnackBarBehavior.floating,
                          duration: const Duration(seconds: 2),
                        ),
                      );
                    },
                  ),
                ],
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildExplanationTabItem(int index, String title, IconData icon, bool isDark) {
    final isSelected = _selectedExplanationTab == index;
    return Expanded(
      child: GestureDetector(
        onTap: () {
          HapticFeedback.selectionClick();
          setState(() => _selectedExplanationTab = index);
        },
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 180),
          padding: const EdgeInsets.symmetric(vertical: 7),
          decoration: BoxDecoration(
            color: isSelected
                ? (isDark ? const Color(0xFF1B3B2B) : Colors.white)
                : Colors.transparent,
            borderRadius: BorderRadius.circular(12),
            boxShadow: isSelected
                ? [
                    BoxShadow(
                      color: Colors.black.withOpacity(isDark ? 0.3 : 0.05),
                      blurRadius: 6,
                      offset: const Offset(0, 2),
                    ),
                  ]
                : null,
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                icon,
                size: 13,
                color: isSelected
                    ? AppColors.accentGoldDark
                    : (isDark ? Colors.white60 : Colors.black54),
              ),
              const SizedBox(width: 4),
              Text(
                title,
                style: GoogleFonts.plusJakartaSans(
                  fontSize: 11,
                  fontWeight: isSelected ? FontWeight.bold : FontWeight.w500,
                  color: isSelected
                      ? (isDark ? Colors.white : const Color(0xFF153322))
                      : (isDark ? Colors.white60 : Colors.black54),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildTafsirTabContent(bool isDark, Color textPrimary, Color textSecondary) {
    return Column(
      key: const ValueKey(0),
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              '“',
              style: GoogleFonts.amiri(
                fontSize: 28,
                fontWeight: FontWeight.bold,
                color: AppColors.quranGold.withOpacity(0.7),
                height: 1.0,
              ),
            ),
            const SizedBox(width: 6),
            Expanded(
              child: Text(
                _dailyAyah.explanation,
                style: GoogleFonts.plusJakartaSans(
                  fontSize: 13.5,
                  height: 1.62,
                  fontWeight: FontWeight.w400,
                  color: textPrimary.withOpacity(0.88),
                ),
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildLessonsTabContent(bool isDark, Color textPrimary, Color textSecondary) {
    final lessons = [
      {
        'title': 'Spiritual Steadfastness',
        'desc': 'Anchor your trust in Allah\'s wisdom; every circumstance is ordained with divine purpose.',
      },
      {
        'title': 'Ease Follows Patience',
        'desc': 'Hardship is transient. With conscious endurance and sincere prayer, relief invariably unfolds.',
      },
      {
        'title': 'Practical Action',
        'desc': 'Reflect on this ayah throughout the day, embody its virtue in your dealings, and engage in heartfelt dhikr.',
      },
    ];

    return Column(
      key: const ValueKey(1),
      children: lessons.map((l) {
        return Padding(
          padding: const EdgeInsets.only(bottom: 10),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                margin: const EdgeInsets.only(top: 2),
                padding: const EdgeInsets.all(4),
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: AppColors.accentGold.withOpacity(0.2),
                ),
                child: const Icon(
                  Icons.check_rounded,
                  size: 11,
                  color: AppColors.accentGoldDark,
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      l['title']!,
                      style: GoogleFonts.plusJakartaSans(
                        fontSize: 12.5,
                        fontWeight: FontWeight.bold,
                        color: textPrimary,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      l['desc']!,
                      style: GoogleFonts.plusJakartaSans(
                        fontSize: 11.5,
                        height: 1.45,
                        color: textSecondary,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        );
      }).toList(),
    );
  }

  Widget _buildVocabularyTabContent(bool isDark, Color textPrimary, Color textSecondary) {
    // Generate key vocabulary cards from the verse
    final words = _dailyAyah.arabicText.split(RegExp(r'\s+')).take(4).toList();

    return Column(
      key: const ValueKey(2),
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Key Arabic Vocabulary & Linguistic Gems',
          style: GoogleFonts.plusJakartaSans(
            fontSize: 11.5,
            fontWeight: FontWeight.bold,
            color: AppColors.accentGoldDark,
          ),
        ),
        const SizedBox(height: 8),
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: words.map((w) {
            return Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              decoration: BoxDecoration(
                color: isDark
                    ? Colors.white.withOpacity(0.05)
                    : const Color(0xFFF7F3EA),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(
                  color: AppColors.quranGold.withOpacity(0.2),
                  width: 0.8,
                ),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    w,
                    style: GoogleFonts.amiri(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: isDark ? AppColors.accentGold : const Color(0xFF103322),
                    ),
                  ),
                  Text(
                    'Surah ${_dailyAyah.surahNameEnglish}',
                    style: GoogleFonts.plusJakartaSans(
                      fontSize: 9.5,
                      fontWeight: FontWeight.w500,
                      color: textSecondary,
                    ),
                  ),
                ],
              ),
            );
          }).toList(),
        ),
      ],
    );
  }

  /// Quick Actions Bar (Font resizer, Copy, Save)
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
                padding:
                    const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
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
                padding:
                    const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
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

/// Dynamic Animated Equalizer Frequency Waveform Bars
class _FrequencyWaveBars extends StatefulWidget {
  final bool isPlaying;
  final Color barColor;

  const _FrequencyWaveBars({
    required this.isPlaying,
    this.barColor = AppColors.quranGold,
  });

  @override
  State<_FrequencyWaveBars> createState() => _FrequencyWaveBarsState();
}

class _FrequencyWaveBarsState extends State<_FrequencyWaveBars>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;

  static const List<double> _baseHeights = [
    12.0,
    22.0,
    9.0,
    25.0,
    16.0,
    26.0,
    11.0,
    21.0,
    15.0,
    18.0,
  ];

  static const List<double> _phaseShifts = [
    0.0,
    0.5,
    1.1,
    1.7,
    2.3,
    2.9,
    3.5,
    4.1,
    4.7,
    5.3,
  ];

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 950),
    );
    if (widget.isPlaying) {
      _controller.repeat();
    }
  }

  @override
  void didUpdateWidget(covariant _FrequencyWaveBars oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.isPlaying != oldWidget.isPlaying) {
      if (widget.isPlaying) {
        _controller.repeat();
      } else {
        _controller.stop();
      }
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _controller,
      builder: (context, _) {
        return Row(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.center,
          children: List.generate(_baseHeights.length, (index) {
            final phase = _phaseShifts[index];
            final base = _baseHeights[index];
            double height = 5.0;
            if (widget.isPlaying) {
              final t = (_controller.value * 2 * math.pi) + phase;
              final factor = (math.sin(t) + 1.0) / 2.0; // 0.0 .. 1.0
              height = 5.0 + factor * (base - 5.0);
            }

            return Container(
              margin: const EdgeInsets.symmetric(horizontal: 1.4),
              width: 3.0,
              height: height,
              decoration: BoxDecoration(
                color: widget.barColor,
                borderRadius: BorderRadius.circular(2),
                boxShadow: widget.isPlaying
                    ? [
                        BoxShadow(
                          color: widget.barColor.withOpacity(0.45),
                          blurRadius: 4,
                          spreadRadius: 0.3,
                        ),
                      ]
                    : null,
              ),
            );
          }),
        );
      },
    );
  }
}
