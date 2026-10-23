import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../constants/app_colors.dart';
import '../constants/surah_data.dart';
import '../models/ayah.dart';
import '../services/audio_service.dart';
import '../services/quran_api_service.dart';
import '../services/storage_service.dart';
import '../widgets/audio_player_bar.dart';
import '../widgets/ayah_card.dart';
import '../widgets/bismillah_banner.dart';
import '../widgets/curved_header.dart';
import '../widgets/page_turn_view.dart';

enum ReaderMode {
  pageTurn, // 3D Book Page-Turning Mode
  verseList, // Clean vertical scroll study mode
}

class ReaderScreen extends StatefulWidget {
  final SurahMeta surah;

  const ReaderScreen({super.key, required this.surah});

  @override
  State<ReaderScreen> createState() => _ReaderScreenState();
}

class _ReaderScreenState extends State<ReaderScreen> {
  final QuranApiService _apiService = QuranApiService();
  final StorageService _storage = StorageService();
  final QuranAudioService _audioService = QuranAudioService();
  final ScrollController _scrollController = ScrollController();

  List<Ayah> _ayahs = [];
  bool _isLoading = true;
  String? _errorMessage;

  ReaderMode _readerMode = ReaderMode.pageTurn; // Default to authentic 3D Mushaf book page
  double _arabicFontSize = 24.0;
  bool _showTranslation = false; // Arabic-first by default as requested
  bool _isBookmarked = false;

  @override
  void initState() {
    super.initState();
    _loadPreferences();
    _fetchAyahs();

    // Auto-scroll to active playing ayah when in verse list mode
    _audioService.currentPlayingAyah.addListener(_handleAudioAyahChange);
  }

  void _handleAudioAyahChange() {
    final playingAyah = _audioService.currentPlayingAyah.value;
    if (playingAyah != null && _readerMode == ReaderMode.verseList && _scrollController.hasClients) {
      final targetOffset = ((playingAyah - 1) * 190.0) + 100.0;
      _scrollController.animateTo(
        targetOffset.clamp(0.0, _scrollController.position.maxScrollExtent),
        duration: const Duration(milliseconds: 500),
        curve: Curves.easeOutCubic,
      );
    }
  }

  @override
  void dispose() {
    _audioService.currentPlayingAyah.removeListener(_handleAudioAyahChange);
    _scrollController.dispose();
    super.dispose();
  }

  Future<void> _loadPreferences() async {
    final size = await _storage.getArabicFontSize();
    final translation = await _storage.getShowTranslation();
    final bookmarked = await _storage.isBookmarked(widget.surah.number);
    if (mounted) {
      setState(() {
        _arabicFontSize = size;
        _showTranslation = translation;
        _isBookmarked = bookmarked;
      });
    }

    // Save as last read
    await _storage.saveLastRead(
      surahNumber: widget.surah.number,
      surahName: widget.surah.englishName,
      ayahNumber: 1,
    );
  }

  Future<void> _fetchAyahs() async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      final data = await _apiService.getChapterAyahs(widget.surah.number);
      if (mounted) {
        setState(() {
          _ayahs = data;
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _isLoading = false;
          _errorMessage = 'Could not load verses. Check your internet connection.';
        });
      }
    }
  }

  void _showReciterSelectionModal() {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final bg = isDark ? AppColors.darkSurface : AppColors.lightSurface;
    final textPrimary = isDark ? AppColors.darkTextPrimary : AppColors.lightTextPrimary;
    final textSecondary = isDark ? AppColors.darkTextSecondary : AppColors.lightTextSecondary;
    final border = isDark ? AppColors.darkBorder : AppColors.lightBorder;

    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (context) {
        return Container(
          padding: const EdgeInsets.all(24),
          decoration: BoxDecoration(
            color: bg,
            borderRadius: const BorderRadius.only(
              topLeft: Radius.circular(28),
              topRight: Radius.circular(28),
            ),
            border: Border.all(color: border, width: 1),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    'Select Reciter (Qari)',
                    style: GoogleFonts.plusJakartaSans(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: textPrimary,
                    ),
                  ),
                  IconButton(
                    icon: Icon(Icons.close_rounded, color: textSecondary),
                    onPressed: () => Navigator.of(context).pop(),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              ...QuranAudioService.availableReciters.map((reciter) {
                final isSelected = _audioService.selectedReciter.id == reciter.id;
                return Padding(
                  padding: const EdgeInsets.only(bottom: 8),
                  child: InkWell(
                    onTap: () {
                      _audioService.setReciter(reciter);
                      setState(() {});
                      Navigator.of(context).pop();
                    },
                    borderRadius: BorderRadius.circular(16),
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                      decoration: BoxDecoration(
                        color: isSelected
                            ? AppColors.warmGold.withOpacity(0.18)
                            : (isDark ? AppColors.darkSurfaceSubtle : AppColors.lightSurfaceSubtle),
                        borderRadius: BorderRadius.circular(16),
                      ),
                      child: Row(
                        children: [
                          ClipRRect(
                            borderRadius: BorderRadius.circular(20),
                            child: Image.asset(
                              reciter.imageAsset,
                              width: 42,
                              height: 42,
                              fit: BoxFit.cover,
                              errorBuilder: (_, __, ___) => const CircleAvatar(
                                radius: 21,
                                backgroundColor: AppColors.forestGreen,
                                child: Icon(Icons.mic_rounded, color: Colors.white, size: 20),
                              ),
                            ),
                          ),
                          const SizedBox(width: 14),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  reciter.name,
                                  style: GoogleFonts.plusJakartaSans(
                                    fontSize: 14,
                                    fontWeight: FontWeight.w600,
                                    color: isSelected ? AppColors.accentGoldDark : textPrimary,
                                  ),
                                ),
                                const SizedBox(height: 2),
                                Text(
                                  reciter.description,
                                  style: GoogleFonts.plusJakartaSans(
                                    fontSize: 11,
                                    color: textSecondary,
                                  ),
                                ),
                              ],
                            ),
                          ),
                          if (isSelected)
                            const Icon(Icons.check_circle_rounded, color: AppColors.accentGold, size: 22),
                        ],
                      ),
                    ),
                  ),
                );
              }),
            ],
          ),
        );
      },
    );
  }

  void _showSettingsModal() {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final bg = isDark ? AppColors.darkSurface : AppColors.lightSurface;
    final textPrimary = isDark ? AppColors.darkTextPrimary : AppColors.lightTextPrimary;
    final textSecondary = isDark ? AppColors.darkTextSecondary : AppColors.lightTextSecondary;
    final border = isDark ? AppColors.darkBorder : AppColors.lightBorder;

    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setModalState) {
            return Container(
              padding: const EdgeInsets.all(24),
              decoration: BoxDecoration(
                color: bg,
                borderRadius: const BorderRadius.only(
                  topLeft: Radius.circular(28),
                  topRight: Radius.circular(28),
                ),
                border: Border.all(color: border, width: 1),
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        'Reading Preferences',
                        style: GoogleFonts.plusJakartaSans(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                          color: textPrimary,
                        ),
                      ),
                      IconButton(
                        icon: Icon(Icons.close_rounded, color: textSecondary),
                        onPressed: () => Navigator.of(context).pop(),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),

                  // Arabic Font Size Slider
                  Text(
                    'Arabic Font Size: ${_arabicFontSize.toInt()} pt',
                    style: GoogleFonts.plusJakartaSans(
                      fontSize: 14,
                      color: textSecondary,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                  SliderTheme(
                    data: SliderTheme.of(context).copyWith(
                      activeTrackColor: AppColors.accentGold,
                      inactiveTrackColor: AppColors.accentGold.withOpacity(0.2),
                      thumbColor: AppColors.accentGold,
                    ),
                    child: Slider(
                      value: _arabicFontSize,
                      min: 18.0,
                      max: 38.0,
                      divisions: 10,
                      onChanged: (val) {
                        setModalState(() => _arabicFontSize = val);
                        setState(() => _arabicFontSize = val);
                        _storage.saveArabicFontSize(val);
                      },
                    ),
                  ),
                  const SizedBox(height: 12),

                  // Show Translation Switch
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        'Show English Translation',
                        style: GoogleFonts.plusJakartaSans(
                          fontSize: 14,
                          color: textPrimary,
                        ),
                      ),
                      Switch(
                        value: _showTranslation,
                        activeColor: AppColors.accentGold,
                        onChanged: (val) {
                          setModalState(() => _showTranslation = val);
                          setState(() => _showTranslation = val);
                          _storage.saveShowTranslation(val);
                        },
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),

                  // Auto Play Next Ayah Switch
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        'Continuous Recitation Auto-Play',
                        style: GoogleFonts.plusJakartaSans(
                          fontSize: 14,
                          color: textPrimary,
                        ),
                      ),
                      Switch(
                        value: _audioService.autoPlayNext,
                        activeColor: AppColors.accentGold,
                        onChanged: (val) {
                          setModalState(() => _audioService.autoPlayNext = val);
                          setState(() => _audioService.autoPlayNext = val);
                        },
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                ],
              ),
            );
          },
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final bg = isDark ? AppColors.darkBackground : AppColors.lightBackground;
    final topPadding = MediaQuery.of(context).padding.top;
    final headerHeight = topPadding + 104.0;

    return Scaffold(
      backgroundColor: bg,
      body: Stack(
        children: [
          // Main Reader Body positioned below header with bottom space for audio bar
          Positioned.fill(
            child: Padding(
              padding: EdgeInsets.only(top: headerHeight - 12, bottom: 64),
              child: _buildBody(),
            ),
          ),

          // Curved Downward Solid Forest Green Header (no outlines)
          Positioned(
            top: 0,
            left: 0,
            right: 0,
            child: _buildCurvedHeader(context),
          ),

          // Floating Audio Player Bar at bottom
          Positioned(
            left: 0,
            right: 0,
            bottom: 0,
            child: AudioPlayerBar(
              totalVerses: widget.surah.numberOfAyahs,
              onReciterChangeRequested: _showReciterSelectionModal,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCurvedHeader(BuildContext context) {
    final topPadding = MediaQuery.of(context).padding.top;

    return CurvedDownwardHeader(
      curveDepth: 22.0,
      backgroundColor: AppColors.forestGreen,
      padding: EdgeInsets.only(
        top: topPadding + 6,
        left: 12,
        right: 12,
        bottom: 22,
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Row(
            children: [
              // Back Button
              IconButton(
                icon: const Icon(Icons.arrow_back_ios_new_rounded, size: 20, color: Colors.white),
                onPressed: () => Navigator.of(context).pop(),
              ),

              // Surah Title & Metadata
              Expanded(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Flexible(
                          child: Text(
                            widget.surah.englishName,
                            style: GoogleFonts.plusJakartaSans(
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                              color: Colors.white,
                            ),
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                        const SizedBox(width: 6),
                        Text(
                          widget.surah.name,
                          style: GoogleFonts.amiri(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                            color: AppColors.warmGold,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 2),
                    Text(
                      '${widget.surah.revelationType} • ${widget.surah.numberOfAyahs} Ayahs',
                      style: GoogleFonts.plusJakartaSans(
                        fontSize: 11,
                        color: Colors.white.withOpacity(0.8),
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ],
                ),
              ),

              // Reciter Avatar button
              ValueListenableBuilder<Reciter>(
                valueListenable: _audioService.selectedReciterNotifier,
                builder: (context, reciter, _) {
                  return Tooltip(
                    message: 'Select Reciter: ${reciter.name}',
                    child: InkWell(
                      onTap: _showReciterSelectionModal,
                      borderRadius: BorderRadius.circular(20),
                      child: Container(
                        padding: const EdgeInsets.all(2),
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          border: Border.all(color: AppColors.warmGold, width: 1.5),
                        ),
                        child: ClipOval(
                          child: Image.asset(
                            reciter.imageAsset,
                            width: 28,
                            height: 28,
                            fit: BoxFit.cover,
                            errorBuilder: (_, __, ___) => const CircleAvatar(
                              radius: 14,
                              backgroundColor: AppColors.forestGreenSurface,
                              child: Icon(Icons.person, size: 16, color: Colors.white),
                            ),
                          ),
                        ),
                      ),
                    ),
                  );
                },
              ),
              const SizedBox(width: 4),

              // Audio Play / Pause in header
              ValueListenableBuilder<bool>(
                valueListenable: _audioService.isPlayingNotifier,
                builder: (context, isPlaying, _) {
                  return IconButton(
                    icon: Icon(
                      isPlaying ? Icons.pause_circle_filled_rounded : Icons.play_circle_filled_rounded,
                      color: AppColors.warmGold,
                      size: 28,
                    ),
                    tooltip: isPlaying ? 'Pause Recitation' : 'Play Surah',
                    onPressed: () {
                      if (isPlaying) {
                        _audioService.player.pause();
                      } else {
                        _audioService.playAyah(
                          surahNumber: widget.surah.number,
                          ayahNumber: 1,
                          maxVerses: widget.surah.numberOfAyahs,
                        );
                      }
                    },
                  );
                },
              ),
            ],
          ),

          const SizedBox(height: 6),

          // Secondary Quick Controls Row
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 8),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: [
                _buildHeaderPillAction(
                  icon: _showTranslation ? Icons.translate_rounded : Icons.g_translate_outlined,
                  label: _showTranslation ? 'English ON' : 'Arabic Only',
                  isActive: _showTranslation,
                  onTap: () {
                    setState(() => _showTranslation = !_showTranslation);
                    _storage.saveShowTranslation(_showTranslation);
                  },
                ),
                _buildHeaderPillAction(
                  icon: _readerMode == ReaderMode.pageTurn
                      ? Icons.menu_book_rounded
                      : Icons.view_headline_rounded,
                  label: _readerMode == ReaderMode.pageTurn ? 'Book Page' : 'Verse List',
                  isActive: _readerMode == ReaderMode.pageTurn,
                  onTap: () {
                    setState(() {
                      _readerMode = _readerMode == ReaderMode.pageTurn
                          ? ReaderMode.verseList
                          : ReaderMode.pageTurn;
                    });
                  },
                ),
                _buildHeaderPillAction(
                  icon: _isBookmarked ? Icons.bookmark_rounded : Icons.bookmark_border_rounded,
                  label: _isBookmarked ? 'Saved' : 'Bookmark',
                  isActive: _isBookmarked,
                  onTap: () async {
                    final newStatus = await _storage.toggleBookmark(widget.surah.number);
                    setState(() => _isBookmarked = newStatus);
                  },
                ),
                _buildHeaderPillAction(
                  icon: Icons.tune_rounded,
                  label: 'Prefs',
                  isActive: false,
                  onTap: _showSettingsModal,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildHeaderPillAction({
    required IconData icon,
    required String label,
    required bool isActive,
    required VoidCallback onTap,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(16),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
        decoration: BoxDecoration(
          color: isActive
              ? AppColors.warmGold.withOpacity(0.25)
              : Colors.white.withOpacity(0.12),
          borderRadius: BorderRadius.circular(16),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              icon,
              size: 14,
              color: isActive ? AppColors.warmGold : Colors.white,
            ),
            const SizedBox(width: 4),
            Text(
              label,
              style: GoogleFonts.plusJakartaSans(
                fontSize: 11,
                fontWeight: isActive ? FontWeight.w700 : FontWeight.w500,
                color: isActive ? AppColors.warmGold : Colors.white,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildBody() {
    if (_isLoading) {
      return Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const CircularProgressIndicator(color: AppColors.accentGold),
            const SizedBox(height: 16),
            Text(
              'Loading Surah ${widget.surah.englishName}...',
              style: GoogleFonts.plusJakartaSans(
                fontSize: 14,
                color: Theme.of(context).brightness == Brightness.dark
                    ? AppColors.darkTextSecondary
                    : AppColors.lightTextSecondary,
              ),
            ),
          ],
        ),
      );
    }

    if (_errorMessage != null) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 32),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(Icons.cloud_off_rounded, size: 48, color: AppColors.accentGold),
              const SizedBox(height: 12),
              Text(
                _errorMessage!,
                textAlign: TextAlign.center,
                style: GoogleFonts.plusJakartaSans(),
              ),
              const SizedBox(height: 16),
              ElevatedButton.icon(
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.accentGold,
                  foregroundColor: AppColors.lightPillButton,
                ),
                icon: const Icon(Icons.refresh_rounded),
                label: const Text('Try Again'),
                onPressed: _fetchAyahs,
              ),
            ],
          ),
        ),
      );
    }

    // 1. Authentic Mushaf Book Page-Turn Mode (3D Open/Curl Transition)
    if (_readerMode == ReaderMode.pageTurn) {
      return PageTurnView(
        ayahs: _ayahs,
        surahNameArabic: widget.surah.name,
        surahNameEnglish: widget.surah.englishName,
        surahNumber: widget.surah.number,
        numberOfAyahs: widget.surah.numberOfAyahs,
        arabicFontSize: _arabicFontSize,
        showTranslation: _showTranslation,
        onToggleTranslation: () {
          setState(() => _showTranslation = !_showTranslation);
          _storage.saveShowTranslation(_showTranslation);
        },
      );
    }

    // 2. Study Mode (Clean Vertical Scroll with Ayah Cards)
    return ValueListenableBuilder<int?>(
      valueListenable: _audioService.currentPlayingAyah,
      builder: (context, playingAyah, _) {
        return ListView.builder(
          controller: _scrollController,
          physics: const BouncingScrollPhysics(),
          padding: const EdgeInsets.only(top: 8, bottom: 120),
          itemCount: _ayahs.length + 1,
          itemBuilder: (context, index) {
            if (index == 0) {
              return BismillahBanner(surahNumber: widget.surah.number);
            }

            final ayah = _ayahs[index - 1];
            final isCurrentPlaying = playingAyah == ayah.verse;

            return AyahCard(
              ayah: ayah,
              arabicFontSize: _arabicFontSize,
              showTranslation: _showTranslation,
              isPlaying: isCurrentPlaying,
              onPlay: () {
                if (isCurrentPlaying && _audioService.isPlayingNotifier.value) {
                  _audioService.pause();
                } else {
                  _audioService.playAyah(
                    surahNumber: widget.surah.number,
                    ayahNumber: ayah.verse,
                    maxVerses: widget.surah.numberOfAyahs,
                  );
                }
              },
            );
          },
        );
      },
    );
  }
}
