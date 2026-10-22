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

  ReaderMode _readerMode = ReaderMode.verseList; // Default to study verse list
  double _arabicFontSize = 24.0;
  bool _showTranslation = true;
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
                      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                      decoration: BoxDecoration(
                        color: isSelected
                            ? AppColors.accentGold.withOpacity(0.18)
                            : (isDark ? AppColors.darkSurfaceSubtle : AppColors.lightSurfaceSubtle),
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(
                          color: isSelected ? AppColors.accentGold : border,
                          width: 1,
                        ),
                      ),
                      child: Row(
                        children: [
                          Icon(
                            Icons.mic_rounded,
                            color: isSelected ? AppColors.accentGold : textSecondary,
                            size: 20,
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
                            const Icon(Icons.check_circle_rounded, color: AppColors.accentGold, size: 20),
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
    final textPrimary = isDark ? AppColors.darkTextPrimary : AppColors.lightTextPrimary;
    final textSecondary = isDark ? AppColors.darkTextSecondary : AppColors.lightTextSecondary;

    return Scaffold(
      backgroundColor: bg,
      appBar: AppBar(
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new_rounded, size: 20),
          color: textPrimary,
          onPressed: () => Navigator.of(context).pop(),
        ),
        title: Column(
          children: [
            Text(
              widget.surah.englishName,
              style: GoogleFonts.plusJakartaSans(
                fontSize: 17,
                fontWeight: FontWeight.bold,
                color: textPrimary,
              ),
            ),
            Text(
              '${widget.surah.revelationType} • ${widget.surah.numberOfAyahs} Ayahs',
              style: GoogleFonts.plusJakartaSans(
                fontSize: 11,
                color: textSecondary,
              ),
            ),
          ],
        ),
        actions: [
          // Play Full Surah Audio action
          IconButton(
            icon: const Icon(Icons.play_circle_outline_rounded, color: AppColors.accentGold),
            tooltip: 'Play Surah Audio',
            onPressed: () {
              _audioService.playAyah(
                surahNumber: widget.surah.number,
                ayahNumber: 1,
                maxVerses: widget.surah.numberOfAyahs,
              );
            },
          ),

          // Mode toggle button (Book Page-Turn vs Verse List)
          IconButton(
            icon: Icon(
              _readerMode == ReaderMode.pageTurn
                  ? Icons.menu_book_rounded
                  : Icons.view_headline_rounded,
              color: AppColors.accentGold,
            ),
            tooltip: _readerMode == ReaderMode.pageTurn
                ? 'Switch to Verse List'
                : 'Switch to Book Page Turn',
            onPressed: () {
              setState(() {
                _readerMode = _readerMode == ReaderMode.pageTurn
                    ? ReaderMode.verseList
                    : ReaderMode.pageTurn;
              });
            },
          ),

          // Bookmark Toggle
          IconButton(
            icon: Icon(
              _isBookmarked ? Icons.bookmark_rounded : Icons.bookmark_border_rounded,
              color: _isBookmarked ? AppColors.accentGold : textPrimary,
            ),
            onPressed: () async {
              final newStatus = await _storage.toggleBookmark(widget.surah.number);
              setState(() => _isBookmarked = newStatus);
            },
          ),

          // Settings (Font size, translation, audio)
          IconButton(
            icon: Icon(Icons.tune_rounded, color: textPrimary),
            onPressed: _showSettingsModal,
          ),
        ],
      ),
      body: Stack(
        children: [
          // Main Reader Body
          Positioned.fill(
            child: _buildBody(),
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

    // 1. Book Page-Turn Mode (3D Open/Curl Transition)
    if (_readerMode == ReaderMode.pageTurn) {
      return PageTurnView(
        ayahs: _ayahs,
        surahNameArabic: widget.surah.name,
        surahNameEnglish: widget.surah.englishName,
        surahNumber: widget.surah.number,
        arabicFontSize: _arabicFontSize,
        showTranslation: _showTranslation,
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
