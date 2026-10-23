import 'dart:math' as math;
import 'dart:ui';
import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../constants/app_colors.dart';
import '../models/ayah.dart';
import '../services/audio_service.dart';
import 'mushaf_header_banner.dart';

/// A 3D Mushaf Book Page-Turning View that opens and curls pages like an authentic Quran manuscript.
/// Supports continuous Arabic-first typography, live audio verse highlighting, and automatic 3D page turning.
class PageTurnView extends StatefulWidget {
  final List<Ayah> ayahs;
  final String surahNameArabic;
  final String surahNameEnglish;
  final int surahNumber;
  final int numberOfAyahs;
  final double arabicFontSize;
  final bool showTranslation;
  final VoidCallback? onToggleTranslation;

  const PageTurnView({
    super.key,
    required this.ayahs,
    required this.surahNameArabic,
    required this.surahNameEnglish,
    required this.surahNumber,
    required this.numberOfAyahs,
    this.arabicFontSize = 23.0,
    this.showTranslation = false,
    this.onToggleTranslation,
  });

  @override
  State<PageTurnView> createState() => _PageTurnViewState();
}

class _PageTurnViewState extends State<PageTurnView> {
  late PageController _pageController;
  final QuranAudioService _audioService = QuranAudioService();
  double _currentPage = 0.0;
  late List<List<Ayah>> _pages;

  @override
  void initState() {
    super.initState();
    _pageController = PageController();
    _pageController.addListener(_handleScroll);
    _chunkAyahsIntoPages();

    // Listen to active audio recitation to highlight verses & auto-flip pages
    _audioService.currentPlayingAyah.addListener(_handleAudioVerseChange);
  }

  void _handleScroll() {
    if (mounted) {
      setState(() {
        _currentPage = _pageController.page ?? 0.0;
      });
    }
  }

  /// Automatically flips to the next page when the current page's verses finish reciting
  void _handleAudioVerseChange() {
    final playingAyah = _audioService.currentPlayingAyah.value;
    if (playingAyah == null || !mounted || _pages.isEmpty) return;

    // Find which page index holds this active Ayah
    for (int p = 0; p < _pages.length; p++) {
      if (_pages[p].any((a) => a.verse == playingAyah)) {
        if (_currentPage.round() != p && _pageController.hasClients) {
          _pageController.animateToPage(
            p,
            duration: const Duration(milliseconds: 700),
            curve: Curves.easeInOutCubic,
          );
        }
        break;
      }
    }
    setState(() {});
  }

  /// Paginates verses into realistic Mushaf page chunks.
  /// Short chapters (<= 8 verses like Al-Fatihah, Quraish, Kawthar) fit on 1 complete page.
  void _chunkAyahsIntoPages() {
    _pages = [];
    if (widget.ayahs.isEmpty) {
      _pages.add([]);
      return;
    }

    if (widget.ayahs.length <= 8) {
      _pages.add(List.from(widget.ayahs));
      return;
    }

    // For longer chapters, divide by ~5 to 7 verses per page
    const int perPage = 6;
    for (int i = 0; i < widget.ayahs.length; i += perPage) {
      final end = (i + perPage < widget.ayahs.length) ? i + perPage : widget.ayahs.length;
      _pages.add(widget.ayahs.sublist(i, end));
    }
  }

  @override
  void didUpdateWidget(covariant PageTurnView oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.ayahs != widget.ayahs) {
      _chunkAyahsIntoPages();
    }
  }

  @override
  void dispose() {
    _audioService.currentPlayingAyah.removeListener(_handleAudioVerseChange);
    _pageController.removeListener(_handleScroll);
    _pageController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (_pages.isEmpty || widget.ayahs.isEmpty) {
      return const Center(child: CircularProgressIndicator(color: AppColors.accentGold));
    }

    final isDark = Theme.of(context).brightness == Brightness.dark;
    final textPrimary = isDark ? AppColors.darkTextPrimary : AppColors.lightTextPrimary;
    final textSecondary = isDark ? AppColors.darkTextSecondary : AppColors.lightTextSecondary;

    return Column(
      children: [
        // Top Navigation Header: Page Number + Navigation Arrows + Translation Switch
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 6),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              // Page Counter Pill
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 5),
                decoration: BoxDecoration(
                  color: isDark ? AppColors.darkSurface : Colors.white,
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(color: AppColors.accentGold.withOpacity(0.5), width: 1),
                ),
                child: Row(
                  children: [
                    const Icon(Icons.auto_stories_rounded, size: 14, color: AppColors.accentGold),
                    const SizedBox(width: 6),
                    Text(
                      'Page ${(_currentPage.round() + 1)} of ${_pages.length}',
                      style: GoogleFonts.plusJakartaSans(
                        fontSize: 12,
                        color: AppColors.accentGoldDark,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
              ),

              // Page Nav Controls
              Row(
                children: [
                  IconButton(
                    icon: const Icon(Icons.arrow_back_ios_rounded, size: 16),
                    color: _currentPage.round() > 0 ? textPrimary : textSecondary.withOpacity(0.3),
                    tooltip: 'Previous Page',
                    onPressed: _currentPage.round() > 0
                        ? () {
                            _pageController.previousPage(
                              duration: const Duration(milliseconds: 500),
                              curve: Curves.easeInOutCubic,
                            );
                          }
                        : null,
                  ),
                  IconButton(
                    icon: const Icon(Icons.arrow_forward_ios_rounded, size: 16),
                    color: _currentPage.round() < _pages.length - 1
                        ? textPrimary
                        : textSecondary.withOpacity(0.3),
                    tooltip: 'Next Page',
                    onPressed: _currentPage.round() < _pages.length - 1
                        ? () {
                            _pageController.nextPage(
                              duration: const Duration(milliseconds: 500),
                              curve: Curves.easeInOutCubic,
                            );
                          }
                        : null,
                  ),
                ],
              ),
            ],
          ),
        ),

        // 3D Book Perspective Page View
        Expanded(
          child: ValueListenableBuilder<int?>(
            valueListenable: _audioService.currentPlayingAyah,
            builder: (context, playingAyah, _) {
              return PageView.builder(
                controller: _pageController,
                itemCount: _pages.length,
                itemBuilder: (context, index) {
                  final pageOffset = _currentPage - index;
                  final isLeaving = pageOffset > 0;
                  final rotationY = isLeaving
                      ? math.min(pageOffset * -math.pi / 2.3, 0.0)
                      : math.max(pageOffset * -math.pi / 2.3, 0.0);

                  return Transform(
                    transform: Matrix4.identity()
                      ..setEntry(3, 2, 0.0014) // 3D depth perspective
                      ..rotateY(rotationY),
                    alignment: isLeaving ? Alignment.centerRight : Alignment.centerLeft,
                    child: _buildMushafManuscriptPage(index, _pages[index], playingAyah),
                  );
                },
              );
            },
          ),
        ),
        const SizedBox(height: 10),
      ],
    );
  }

  /// Builds a manuscript page with iOS-style liquid glassmorphism and 4-corner ornaments
  Widget _buildMushafManuscriptPage(int pageIndex, List<Ayah> pageAyahs, int? playingAyah) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final glassBg = isDark
        ? const Color(0xFF1B2228).withOpacity(0.85)
        : Colors.white.withOpacity(0.92);

    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
      decoration: BoxDecoration(
        color: glassBg,
        borderRadius: BorderRadius.circular(24),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(isDark ? 0.35 : 0.07),
            blurRadius: 20,
            offset: const Offset(0, 6),
          ),
          BoxShadow(
            color: Colors.white.withOpacity(isDark ? 0.05 : 0.7),
            blurRadius: 1,
            offset: const Offset(0, 1),
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(24),
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 16, sigmaY: 16),
          child: Stack(
            children: [
              // Top-Left Corner Islamic Ornament
              Positioned(
                top: 0,
                left: 0,
                width: 72,
                height: 48,
                child: IgnorePointer(
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

              // Top-Right Corner Islamic Ornament
              Positioned(
                top: 0,
                right: 0,
                width: 72,
                height: 48,
                child: IgnorePointer(
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

              // Bottom-Left Corner Islamic Ornament
              Positioned(
                bottom: 0,
                left: 0,
                width: 72,
                height: 48,
                child: IgnorePointer(
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

              // Bottom-Right Corner Islamic Ornament
              Positioned(
                bottom: 0,
                right: 0,
                width: 72,
                height: 48,
                child: IgnorePointer(
                  child: Image.asset(
                    'assets/corner_asset.png',
                    fit: BoxFit.fill,
                    errorBuilder: (_, __, ___) => const SizedBox.shrink(),
                  ),
                ),
              ),

              // Page Content situated inside the liquid glass card
              Padding(
                padding: const EdgeInsets.fromLTRB(20, 14, 20, 14),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    // Surah Header Frame: shown on page 0
                    if (pageIndex == 0)
                      MushafHeaderBanner(
                        surahNameArabic: widget.surahNameArabic,
                        numberOfAyahs: widget.numberOfAyahs,
                        surahNumber: widget.surahNumber,
                        showBismillah: true,
                      )
                    else
                      _buildSubsequentPageHeader(),

                    const SizedBox(height: 8),

                    // Flowing Quranic Arabic Text with Live Highlighting
                    Expanded(
                      child: SingleChildScrollView(
                        physics: const BouncingScrollPhysics(),
                        child: _buildFlowingArabicVerses(pageAyahs, playingAyah),
                      ),
                    ),

                    const SizedBox(height: 4),

                    // Bottom Page Number
                    Center(
                      child: Text(
                        '— ${pageIndex + 1} —',
                        style: GoogleFonts.plusJakartaSans(
                          fontSize: 11,
                          color: isDark ? const Color(0xFFD4AF37) : AppColors.accentGoldDark,
                          letterSpacing: 2,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  /// Compact centered solid forest green pill badge for pages 2, 3, etc. (No border, white text)
  Widget _buildSubsequentPageHeader() {
    return Center(
      child: Container(
        margin: const EdgeInsets.only(bottom: 6),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 5),
        decoration: BoxDecoration(
          color: const Color(0xFF143825),
          borderRadius: BorderRadius.circular(16),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.12),
              blurRadius: 6,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Text(
          'سُورَةُ ${widget.surahNameArabic}',
          textDirection: TextDirection.rtl,
          style: GoogleFonts.amiri(
            fontSize: 15,
            fontWeight: FontWeight.bold,
            color: Colors.white,
            height: 1.2,
          ),
        ),
      ),
    );
  }

  /// Builds the flowing Arabic text, exactly like an authentic printed Mushaf
  Widget _buildFlowingArabicVerses(List<Ayah> pageAyahs, int? playingAyah) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final textPrimary = isDark ? const Color(0xFFEDE8D0) : const Color(0xFF161C24);

    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Directionality(
          textDirection: TextDirection.rtl,
          child: Text.rich(
            TextSpan(
              children: [
                for (final ayah in pageAyahs) ...[
                  TextSpan(
                    text: '${ayah.arabicText} ',
                    style: GoogleFonts.amiri(
                      fontSize: widget.arabicFontSize,
                      fontWeight: FontWeight.w700,
                      color: (playingAyah == ayah.verse)
                          ? (isDark ? const Color(0xFFFFD54F) : const Color(0xFF8C5300))
                          : textPrimary,
                      backgroundColor: (playingAyah == ayah.verse)
                          ? AppColors.accentGold.withOpacity(isDark ? 0.35 : 0.22)
                          : Colors.transparent,
                      height: 2.1,
                      letterSpacing: 0.1,
                    ),
                    recognizer: TapGestureRecognizer()..onTap = () => _handleAyahTap(ayah),
                  ),
                  WidgetSpan(
                    alignment: PlaceholderAlignment.middle,
                    child: GestureDetector(
                      onTap: () => _handleAyahTap(ayah),
                      child: _buildAyahEndMedallion(ayah.verse, playingAyah == ayah.verse),
                    ),
                  ),
                  const TextSpan(text: ' '),
                ],
              ],
            ),
            textAlign: TextAlign.center,
            textDirection: TextDirection.rtl,
          ),
        ),

        // Optional English translations if toggled ON by user
        if (widget.showTranslation) ...[
          const SizedBox(height: 12),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
            decoration: BoxDecoration(
              color: isDark ? const Color(0xFF181E24).withOpacity(0.9) : const Color(0xFFF7F5EE).withOpacity(0.9),
              borderRadius: BorderRadius.circular(10),
              border: Border.all(color: const Color(0xFFD4AF37).withOpacity(0.35)),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: pageAyahs.map((ayah) {
                final isPlaying = playingAyah == ayah.verse;
                return Padding(
                  padding: const EdgeInsets.symmetric(vertical: 2.5),
                  child: Text(
                    '${ayah.verse}. ${ayah.translation}',
                    style: GoogleFonts.plusJakartaSans(
                      fontSize: 12,
                      fontWeight: isPlaying ? FontWeight.bold : FontWeight.w500,
                      color: isPlaying
                          ? (isDark ? const Color(0xFFFFD54F) : const Color(0xFF8C5300))
                          : (isDark ? Colors.white70 : const Color(0xFF374151)),
                      height: 1.35,
                    ),
                  ),
                );
              }).toList(),
            ),
          ),
        ],
      ],
    );
  }

  /// Traditional circular Ayah end medallion (۝) containing the Arabic verse numeral
  Widget _buildAyahEndMedallion(int verseNumber, bool isPlaying) {
    return Container(
      width: 26,
      height: 26,
      margin: const EdgeInsets.symmetric(horizontal: 2),
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        color: isPlaying ? AppColors.accentGold : const Color(0xFFFBF8EE),
        border: Border.all(
          color: isPlaying ? AppColors.accentGoldDark : const Color(0xFF1B6B45),
          width: 1.3,
        ),
        boxShadow: isPlaying
            ? [
                BoxShadow(
                  color: AppColors.accentGold.withOpacity(0.55),
                  blurRadius: 6,
                  spreadRadius: 1,
                ),
              ]
            : null,
      ),
      alignment: Alignment.center,
      child: Text(
        toArabicDigits(verseNumber),
        style: TextStyle(
          fontSize: 11,
          fontWeight: FontWeight.w800,
          color: isPlaying ? Colors.white : const Color(0xFF1B6B45),
          height: 1.1,
        ),
      ),
    );
  }

  /// When an Ayah is tapped, show a bottom modal with its translation and recitation action
  void _handleAyahTap(Ayah ayah) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final bg = isDark ? AppColors.darkSurface : AppColors.lightSurface;
    final textPrimary = isDark ? AppColors.darkTextPrimary : AppColors.lightTextPrimary;
    final textSecondary = isDark ? AppColors.darkTextSecondary : AppColors.lightTextSecondary;

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
            border: Border.all(
              color: isDark ? AppColors.darkBorder : AppColors.lightBorder,
              width: 1,
            ),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // Header
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                    decoration: BoxDecoration(
                      color: AppColors.accentGold.withOpacity(0.18),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Text(
                      'Ayah ${ayah.verse} • ${widget.surahNameEnglish}',
                      style: GoogleFonts.plusJakartaSans(
                        fontSize: 12,
                        fontWeight: FontWeight.bold,
                        color: AppColors.accentGoldDark,
                      ),
                    ),
                  ),
                  IconButton(
                    icon: Icon(Icons.close_rounded, color: textSecondary),
                    onPressed: () => Navigator.of(context).pop(),
                  ),
                ],
              ),
              const SizedBox(height: 14),

              // Arabic text
              Text(
                ayah.arabicText,
                textDirection: TextDirection.rtl,
                textAlign: TextAlign.right,
                style: GoogleFonts.amiri(
                  fontSize: 22,
                  fontWeight: FontWeight.bold,
                  color: textPrimary,
                  height: 1.8,
                ),
              ),
              const SizedBox(height: 14),

              // Translation
              Text(
                'Translation',
                style: GoogleFonts.plusJakartaSans(
                  fontSize: 11,
                  fontWeight: FontWeight.bold,
                  color: textSecondary,
                  letterSpacing: 1,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                ayah.translation.isNotEmpty ? ayah.translation : 'No translation available.',
                style: GoogleFonts.plusJakartaSans(
                  fontSize: 14,
                  color: textPrimary,
                  height: 1.5,
                ),
              ),
              const SizedBox(height: 20),

              // Action button: Play Recitation from this Ayah
              ElevatedButton.icon(
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.accentGold,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 14),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                ),
                icon: const Icon(Icons.play_arrow_rounded, size: 22),
                label: Text(
                  'Recite Ayah ${ayah.verse}',
                  style: GoogleFonts.plusJakartaSans(
                    fontWeight: FontWeight.bold,
                    fontSize: 14,
                  ),
                ),
                onPressed: () {
                  Navigator.of(context).pop();
                  _audioService.playAyah(
                    surahNumber: widget.surahNumber,
                    ayahNumber: ayah.verse,
                    maxVerses: widget.numberOfAyahs,
                  );
                },
              ),
            ],
          ),
        );
      },
    );
  }
}
