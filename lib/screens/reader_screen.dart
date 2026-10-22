import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../constants/app_colors.dart';
import '../constants/surah_data.dart';
import '../models/ayah.dart';
import '../services/quran_api_service.dart';
import '../services/storage_service.dart';
import '../widgets/ayah_card.dart';
import '../widgets/bismillah_banner.dart';
import '../widgets/glass_card.dart';
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

  List<Ayah> _ayahs = [];
  bool _isLoading = true;
  String? _errorMessage;

  ReaderMode _readerMode = ReaderMode.pageTurn;
  double _arabicFontSize = 24.0;
  bool _showTranslation = true;
  bool _isBookmarked = false;

  @override
  void initState() {
    super.initState();
    _loadPreferences();
    _fetchAyahs();
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

  void _showSettingsModal() {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setModalState) {
            return GlassCard(
              borderRadius: 28,
              padding: const EdgeInsets.all(24),
              color: AppColors.primarySurface.withOpacity(0.92),
              borderColor: AppColors.glassBorder,
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
                          color: AppColors.textLight,
                        ),
                      ),
                      IconButton(
                        icon: const Icon(Icons.close_rounded, color: AppColors.textMuted),
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
                      color: AppColors.textMuted,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                  SliderTheme(
                    data: SliderTheme.of(context).copyWith(
                      activeTrackColor: AppColors.gold,
                      inactiveTrackColor: AppColors.glassBackgroundHeavy,
                      thumbColor: AppColors.gold,
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
                          color: AppColors.textLight,
                        ),
                      ),
                      Switch(
                        value: _showTranslation,
                        activeColor: AppColors.gold,
                        activeTrackColor: AppColors.primary,
                        onChanged: (val) {
                          setModalState(() => _showTranslation = val);
                          setState(() => _showTranslation = val);
                          _storage.saveShowTranslation(val);
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
    return Scaffold(
      backgroundColor: AppColors.primaryDark,
      appBar: AppBar(
        title: Column(
          children: [
            Text(
              widget.surah.englishName,
              style: GoogleFonts.plusJakartaSans(
                fontSize: 17,
                fontWeight: FontWeight.bold,
                color: AppColors.textLight,
              ),
            ),
            Text(
              '${widget.surah.revelationType} • ${widget.surah.numberOfAyahs} Ayahs',
              style: GoogleFonts.plusJakartaSans(
                fontSize: 11,
                color: AppColors.textMuted,
              ),
            ),
          ],
        ),
        actions: [
          // Mode toggle button (Book Page-Turn vs Verse List)
          IconButton(
            icon: Icon(
              _readerMode == ReaderMode.pageTurn
                  ? Icons.menu_book_rounded
                  : Icons.view_headline_rounded,
              color: AppColors.gold,
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
              color: _isBookmarked ? AppColors.gold : AppColors.textLight,
            ),
            onPressed: () async {
              final newStatus = await _storage.toggleBookmark(widget.surah.number);
              setState(() => _isBookmarked = newStatus);
            },
          ),

          // Settings (Font size, translation)
          IconButton(
            icon: const Icon(Icons.tune_rounded, color: AppColors.textLight),
            onPressed: _showSettingsModal,
          ),
        ],
      ),
      body: _buildBody(),
    );
  }

  Widget _buildBody() {
    if (_isLoading) {
      return Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const CircularProgressIndicator(color: AppColors.gold),
            const SizedBox(height: 16),
            Text(
              'Loading Surah ${widget.surah.englishName}...',
              style: GoogleFonts.plusJakartaSans(
                fontSize: 14,
                color: AppColors.textMuted,
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
              const Icon(Icons.cloud_off_rounded, size: 48, color: AppColors.textMuted),
              const SizedBox(height: 12),
              Text(
                _errorMessage!,
                textAlign: TextAlign.center,
                style: GoogleFonts.plusJakartaSans(color: AppColors.textLight),
              ),
              const SizedBox(height: 16),
              ElevatedButton.icon(
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.primary,
                  foregroundColor: AppColors.gold,
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
    return ListView.builder(
      physics: const BouncingScrollPhysics(),
      padding: const EdgeInsets.only(top: 8, bottom: 32),
      itemCount: _ayahs.length + 1,
      itemBuilder: (context, index) {
        if (index == 0) {
          return BismillahBanner(surahNumber: widget.surah.number);
        }

        final ayah = _ayahs[index - 1];
        return AyahCard(
          ayah: ayah,
          arabicFontSize: _arabicFontSize,
          showTranslation: _showTranslation,
        );
      },
    );
  }
}
