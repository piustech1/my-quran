import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../constants/app_colors.dart';
import '../models/ayah.dart';

/// A 3D Book Page-Turning View that opens and curls pages like a real manuscript.
class PageTurnView extends StatefulWidget {
  final List<Ayah> ayahs;
  final String surahNameArabic;
  final String surahNameEnglish;
  final int surahNumber;
  final double arabicFontSize;
  final bool showTranslation;

  const PageTurnView({
    super.key,
    required this.ayahs,
    required this.surahNameArabic,
    required this.surahNameEnglish,
    required this.surahNumber,
    this.arabicFontSize = 22.0,
    this.showTranslation = true,
  });

  @override
  State<PageTurnView> createState() => _PageTurnViewState();
}

class _PageTurnViewState extends State<PageTurnView> {
  late PageController _pageController;
  double _currentPage = 0.0;

  late List<List<Ayah>> _pages;

  @override
  void initState() {
    super.initState();
    _pageController = PageController();
    _pageController.addListener(() {
      setState(() {
        _currentPage = _pageController.page ?? 0.0;
      });
    });
    _chunkAyahsIntoPages();
  }

  void _chunkAyahsIntoPages() {
    _pages = [];
    const int perPage = 5;
    for (int i = 0; i < widget.ayahs.length; i += perPage) {
      final end = (i + perPage < widget.ayahs.length) ? i + perPage : widget.ayahs.length;
      _pages.add(widget.ayahs.sublist(i, end));
    }
    if (_pages.isEmpty) {
      _pages.add([]);
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
        // Page Navigation header
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Page ${(_currentPage.round() + 1)} of ${_pages.length}',
                style: GoogleFonts.plusJakartaSans(
                  fontSize: 13,
                  color: AppColors.accentGoldDark,
                  fontWeight: FontWeight.bold,
                ),
              ),
              Row(
                children: [
                  IconButton(
                    icon: const Icon(Icons.arrow_back_ios_rounded, size: 16),
                    color: _currentPage.round() > 0 ? textPrimary : textSecondary.withOpacity(0.4),
                    onPressed: _currentPage.round() > 0
                        ? () {
                            _pageController.previousPage(
                              duration: const Duration(milliseconds: 400),
                              curve: Curves.easeInOutCubic,
                            );
                          }
                        : null,
                  ),
                  IconButton(
                    icon: const Icon(Icons.arrow_forward_ios_rounded, size: 16),
                    color: _currentPage.round() < _pages.length - 1
                        ? textPrimary
                        : textSecondary.withOpacity(0.4),
                    onPressed: _currentPage.round() < _pages.length - 1
                        ? () {
                            _pageController.nextPage(
                              duration: const Duration(milliseconds: 400),
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

        // 3D Book Page View
        Expanded(
          child: PageView.builder(
            controller: _pageController,
            itemCount: _pages.length,
            itemBuilder: (context, index) {
              final pageOffset = _currentPage - index;

              final isLeaving = pageOffset > 0;
              final rotationY = isLeaving
                  ? math.min(pageOffset * -math.pi / 2.5, 0.0)
                  : math.max(pageOffset * -math.pi / 2.5, 0.0);

              return Transform(
                transform: Matrix4.identity()
                  ..setEntry(3, 2, 0.0015) // 3D depth perspective
                  ..rotateY(rotationY),
                alignment: isLeaving ? Alignment.centerRight : Alignment.centerLeft,
                child: _buildBookPage(index, _pages[index]),
              );
            },
          ),
        ),
        const SizedBox(height: 12),
      ],
    );
  }

  Widget _buildBookPage(int pageIndex, List<Ayah> pageAyahs) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      decoration: BoxDecoration(
        color: AppColors.parchment,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(
          color: AppColors.accentGold.withOpacity(0.55),
          width: 2.0,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.12),
            blurRadius: 18,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      child: Stack(
        children: [
          // Inner ornamental border frame
          Positioned.fill(
            child: Container(
              margin: const EdgeInsets.all(6),
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(14),
                border: Border.all(
                  color: AppColors.parchmentBorder,
                  width: 1.2,
                ),
              ),
            ),
          ),

          // Content of the Page
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 20, 20, 16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                // Top Page Header: Surah title
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      widget.surahNameEnglish,
                      style: GoogleFonts.plusJakartaSans(
                        fontSize: 13,
                        fontWeight: FontWeight.bold,
                        color: AppColors.lightTextPrimary,
                      ),
                    ),
                    Text(
                      widget.surahNameArabic,
                      textDirection: TextDirection.rtl,
                      style: GoogleFonts.amiri(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        color: AppColors.accentGoldDark,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                Divider(color: AppColors.accentGold.withOpacity(0.4), height: 1),
                const SizedBox(height: 12),

                // Verses on this page
                Expanded(
                  child: ListView.builder(
                    physics: const BouncingScrollPhysics(),
                    itemCount: pageAyahs.length,
                    itemBuilder: (context, i) {
                      final ayah = pageAyahs[i];
                      return Padding(
                        padding: const EdgeInsets.only(bottom: 16),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.stretch,
                          children: [
                            Row(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                // Ayah number badge
                                Container(
                                  padding: const EdgeInsets.all(6),
                                  decoration: BoxDecoration(
                                    shape: BoxShape.circle,
                                    border: Border.all(
                                      color: AppColors.accentGold,
                                      width: 1.2,
                                    ),
                                    color: Colors.white,
                                  ),
                                  child: Text(
                                    '${ayah.verse}',
                                    style: GoogleFonts.plusJakartaSans(
                                      fontSize: 11,
                                      fontWeight: FontWeight.bold,
                                      color: AppColors.lightTextPrimary,
                                    ),
                                  ),
                                ),
                                const SizedBox(width: 10),
                                Expanded(
                                  child: Text(
                                    ayah.arabicText,
                                    textAlign: TextAlign.right,
                                    textDirection: TextDirection.rtl,
                                    style: GoogleFonts.amiri(
                                      fontSize: widget.arabicFontSize,
                                      color: AppColors.lightTextPrimary,
                                      fontWeight: FontWeight.w600,
                                      height: 1.9,
                                    ),
                                  ),
                                ),
                              ],
                            ),

                            if (widget.showTranslation && ayah.translation.isNotEmpty) ...[
                              const SizedBox(height: 6),
                              Padding(
                                padding: const EdgeInsets.only(left: 36),
                                child: Text(
                                  ayah.translation,
                                  style: GoogleFonts.plusJakartaSans(
                                    fontSize: 12.5,
                                    color: AppColors.lightTextSecondary,
                                    height: 1.5,
                                  ),
                                ),
                              ),
                            ],
                          ],
                        ),
                      );
                    },
                  ),
                ),

                // Bottom Page Number
                Center(
                  child: Text(
                    '— Page ${pageIndex + 1} —',
                    style: GoogleFonts.plusJakartaSans(
                      fontSize: 11,
                      color: AppColors.accentGoldDark,
                      letterSpacing: 1.2,
                      fontWeight: FontWeight.w600,
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
}
