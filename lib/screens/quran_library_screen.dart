import 'dart:math' as math;
import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../constants/app_colors.dart';
import '../constants/surah_data.dart';
import '../models/juz.dart';
import '../models/quran_navigation_data.dart';
import '../services/audio_service.dart';
import '../services/storage_service.dart';
import '../widgets/audio_player_bar.dart';
import '../widgets/islamic_star_badge.dart';
import '../widgets/quran_3d_graphic.dart';
import 'reader_screen.dart';

class QuranLibraryScreen extends StatefulWidget {
  const QuranLibraryScreen({super.key});

  @override
  State<QuranLibraryScreen> createState() => _QuranLibraryScreenState();
}

class _QuranLibraryScreenState extends State<QuranLibraryScreen> {
  final StorageService _storage = StorageService();
  final QuranAudioService _audioService = QuranAudioService();

  int _selectedTabIndex = 0; // 0: Surah, 1: Para, 2: Page, 3: Hizb
  Map<String, dynamic>? _lastRead;
  final TextEditingController _searchController = TextEditingController();
  bool _isSearching = false;
  String _searchQuery = '';

  List<SurahMeta> _filteredSurahs = kAllSurahs;
  List<JuzMeta> _filteredJuzs = kAllJuzs;
  List<PageMeta> _filteredPages = QuranPageCatalog.allPages;
  List<HizbMeta> _filteredHizbs = kAllHizbs;

  @override
  void initState() {
    super.initState();
    _loadLastRead();
  }

  Future<void> _loadLastRead() async {
    final lastRead = await _storage.getLastRead();
    if (mounted) {
      setState(() {
        _lastRead = lastRead;
      });
    }
  }

  void _onSearch(String query) {
    setState(() {
      _searchQuery = query.toLowerCase().trim();
      if (_searchQuery.isEmpty) {
        _filteredSurahs = kAllSurahs;
        _filteredJuzs = kAllJuzs;
        _filteredPages = QuranPageCatalog.allPages;
        _filteredHizbs = kAllHizbs;
      } else {
        // Filter Surahs
        _filteredSurahs = kAllSurahs.where((s) {
          return s.englishName.toLowerCase().contains(_searchQuery) ||
              s.name.contains(_searchQuery) ||
              s.englishNameTranslation.toLowerCase().contains(_searchQuery) ||
              s.number.toString() == _searchQuery;
        }).toList();

        // Filter Juzs
        _filteredJuzs = kAllJuzs.where((j) {
          return j.number.toString() == _searchQuery ||
              j.arabicName.contains(_searchQuery) ||
              j.startSurahName.toLowerCase().contains(_searchQuery);
        }).toList();

        // Filter Pages
        _filteredPages = QuranPageCatalog.allPages.where((p) {
          return p.pageNumber.toString() == _searchQuery ||
              p.surahName.toLowerCase().contains(_searchQuery) ||
              p.surahNameArabic.contains(_searchQuery);
        }).toList();

        // Filter Hizbs
        _filteredHizbs = kAllHizbs.where((h) {
          return h.hizbNumber.toString() == _searchQuery ||
              h.arabicOpening.contains(_searchQuery) ||
              h.surahName.toLowerCase().contains(_searchQuery);
        }).toList();
      }
    });
  }

  void _openReader(SurahMeta surah, {int? initialAyah}) {
    Navigator.of(context)
        .push(
          MaterialPageRoute(
            builder: (_) =>
                ReaderScreen(surah: surah, initialAyah: initialAyah),
          ),
        )
        .then((_) => _loadLastRead());
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final bg = isDark ? AppColors.darkBackground : AppColors.lightBackground;
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
          // 1. Natural Unified CustomScrollView
          // Everything (Mufta, Main Card, Tabs) scrolls smoothly away as user scrolls
          CustomScrollView(
            physics: const BouncingScrollPhysics(),
            slivers: [
              // Header Sliver containing Mufta Backdrop, Top Bar, Main Card & TabBar
              SliverToBoxAdapter(
                child: Stack(
                  children: [
                    // A. Mufta Backdrop with Organic Curved Bottom
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
                                decoration: const BoxDecoration(
                                  gradient: LinearGradient(
                                    begin: Alignment.topCenter,
                                    end: Alignment.bottomCenter,
                                    colors: [
                                      Color(0x400D2F1F),
                                      Color(0x100D2F1F),
                                      Color(0x800D2F1F),
                                    ],
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),

                    // B. Foreground Content: Top Bar + Main Card + Segmented TabBar
                    SafeArea(
                      bottom: false,
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          // 1. Top Bar
                          Padding(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 16, vertical: 6),
                            child: _buildTopBarRow(context, isDark),
                          ),

                          const SizedBox(height: 8),

                          // 2. Main Card ("Last Read" or "Now Playing" with backgroundless frequency wave)
                          Padding(
                            padding: const EdgeInsets.symmetric(horizontal: 16),
                            child: _buildMainHeroCard(isDark),
                          ),

                          const SizedBox(height: 16),

                          // 3. Segmented TabBar with Unique Islamic Icons
                          Padding(
                            padding: const EdgeInsets.symmetric(horizontal: 16),
                            child: _buildSegmentedTabBar(isDark, textPrimary, textSecondary),
                          ),

                          const SizedBox(height: 12),
                        ],
                      ),
                    ),
                  ],
                ),
              ),

              // Active Tab Content Items
              _buildActiveTabSliver(isDark, textPrimary, textSecondary),

              // Bottom Padding for Dock / Floating Audio
              const SliverToBoxAdapter(
                child: SizedBox(height: 100),
              ),
            ],
          ),

          // 2. Floating Audio Player at bottom if recitation is active
          const Positioned(
            left: 0,
            right: 0,
            bottom: 0,
            child: AudioPlayerBar(totalVerses: 114),
          ),
        ],
      ),
    );
  }

  /// Top Bar with Liquid Glass Back and Search Controls
  Widget _buildTopBarRow(BuildContext context, bool isDark) {
    return Row(
      children: [
        // Circular Back Button
        GestureDetector(
          onTap: () => Navigator.of(context).pop(),
          child: ClipRRect(
            borderRadius: BorderRadius.circular(20),
            child: BackdropFilter(
              filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
              child: Container(
                width: 40,
                height: 40,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: Colors.black.withOpacity(0.28),
                  border: Border.all(
                    color: Colors.white.withOpacity(0.22),
                    width: 0.8,
                  ),
                ),
                alignment: Alignment.center,
                child: const Icon(
                  Icons.arrow_back_ios_new_rounded,
                  size: 16,
                  color: Colors.white,
                ),
              ),
            ),
          ),
        ),
        const SizedBox(width: 12),

        // Center Title or Search Input
        Expanded(
          child: _isSearching
              ? ClipRRect(
                  borderRadius: BorderRadius.circular(16),
                  child: BackdropFilter(
                    filter: ImageFilter.blur(sigmaX: 12, sigmaY: 12),
                    child: Container(
                      height: 40,
                      padding: const EdgeInsets.symmetric(horizontal: 12),
                      decoration: BoxDecoration(
                        color: Colors.black.withOpacity(0.35),
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(
                          color: Colors.white.withOpacity(0.20),
                          width: 0.8,
                        ),
                      ),
                      alignment: Alignment.center,
                      child: TextField(
                        controller: _searchController,
                        autofocus: true,
                        onChanged: _onSearch,
                        style: GoogleFonts.plusJakartaSans(
                          color: Colors.white,
                          fontSize: 14.5,
                          fontWeight: FontWeight.w600,
                        ),
                        cursorColor: AppColors.quranGold,
                        decoration: InputDecoration(
                          hintText: _getSearchPlaceholder(),
                          hintStyle: GoogleFonts.plusJakartaSans(
                            color: Colors.white60,
                            fontSize: 13,
                          ),
                          border: InputBorder.none,
                          isDense: true,
                          contentPadding: EdgeInsets.zero,
                        ),
                      ),
                    ),
                  ),
                )
              : Center(
                  child: Text(
                    "Q U R ' A N",
                    style: GoogleFonts.plusJakartaSans(
                      fontSize: 18,
                      fontWeight: FontWeight.w900,
                      letterSpacing: 4.0,
                      color: Colors.white,
                      shadows: [
                        Shadow(
                          color: Colors.black.withOpacity(0.55),
                          blurRadius: 10,
                          offset: const Offset(0, 2),
                        ),
                      ],
                    ),
                  ),
                ),
        ),
        const SizedBox(width: 12),

        // Search Toggle Button
        GestureDetector(
          onTap: () {
            setState(() {
              if (_isSearching) {
                _isSearching = false;
                _searchController.clear();
                _onSearch('');
              } else {
                _isSearching = true;
              }
            });
          },
          child: ClipRRect(
            borderRadius: BorderRadius.circular(20),
            child: BackdropFilter(
              filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
              child: Container(
                width: 40,
                height: 40,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: Colors.black.withOpacity(0.28),
                  border: Border.all(
                    color: Colors.white.withOpacity(0.22),
                    width: 0.8,
                  ),
                ),
                alignment: Alignment.center,
                child: Icon(
                  _isSearching ? Icons.close_rounded : Icons.search_rounded,
                  size: 20,
                  color: Colors.white,
                ),
              ),
            ),
          ),
        ),
      ],
    );
  }

  String _getSearchPlaceholder() {
    switch (_selectedTabIndex) {
      case 1:
        return 'Search Juz (e.g. 1 or Al-Baqarah)...';
      case 2:
        return 'Search Page (1 - 604)...';
      case 3:
        return 'Search Hizb (1 - 60)...';
      default:
        return 'Search Surah name or number...';
    }
  }

  /// Borderless Liquid Glass Main Card with Larger 3D Quran Asset & Pure Backgroundless Frequency Waves
  Widget _buildMainHeroCard(bool isDark) {
    return ValueListenableBuilder<bool>(
      valueListenable: _audioService.isPlayingNotifier,
      builder: (context, isPlaying, _) {
        return ValueListenableBuilder<int?>(
          valueListenable: _audioService.currentPlayingSurah,
          builder: (context, playingSurahNum, _) {
            // Determine active surah meta
            final lastReadSurahNum = _lastRead?['surah'] as int? ?? 1;
            final lastReadAyah = _lastRead?['ayah'] as int? ?? 1;
            final isAudioActive = isPlaying && playingSurahNum != null;

            final activeSurahNum =
                isAudioActive ? playingSurahNum : lastReadSurahNum;
            final surahMeta = kAllSurahs.firstWhere(
              (s) => s.number == activeSurahNum,
              orElse: () => kAllSurahs.first,
            );

            return Container(
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(28),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(isDark ? 0.45 : 0.18),
                    blurRadius: 20,
                    offset: const Offset(0, 8),
                  ),
                ],
              ),
              child: ClipRRect(
                borderRadius: BorderRadius.circular(28),
                child: BackdropFilter(
                  filter: ImageFilter.blur(sigmaX: 16, sigmaY: 16),
                  child: Container(
                    padding: const EdgeInsets.fromLTRB(20, 18, 16, 18),
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(28),
                      border: null, // NO outline border as requested
                      gradient: const LinearGradient(
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                        colors: [
                          Color(0xF00F3B2F),
                          Color(0xF50A2920),
                        ],
                      ),
                    ),
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.center,
                      children: [
                        // Left details
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              // Top Tag: Last Read or Reciting Now
                              Row(
                                children: [
                                  Icon(
                                    isAudioActive
                                        ? Icons.graphic_eq_rounded
                                        : Icons.auto_stories_rounded,
                                    size: 14,
                                    color: AppColors.quranGold,
                                  ),
                                  const SizedBox(width: 6),
                                  Text(
                                    isAudioActive
                                        ? 'Reciting Now'
                                        : 'Last Read',
                                    style: GoogleFonts.plusJakartaSans(
                                      fontSize: 12,
                                      fontWeight: FontWeight.w700,
                                      letterSpacing: 0.4,
                                      color: isAudioActive
                                          ? AppColors.quranGold
                                          : Colors.white70,
                                    ),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 6),

                              // Category
                              Text(
                                'Surah',
                                style: GoogleFonts.plusJakartaSans(
                                  fontSize: 11.5,
                                  fontWeight: FontWeight.w500,
                                  color: Colors.white60,
                                ),
                              ),
                              const SizedBox(height: 2),

                              // Surah Name in White Bold
                              Text(
                                surahMeta.englishName,
                                style: GoogleFonts.plusJakartaSans(
                                  fontSize: 22,
                                  fontWeight: FontWeight.bold,
                                  color: Colors.white,
                                  letterSpacing: -0.3,
                                ),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                              ),
                              const SizedBox(height: 3),

                              // Arabic calligraphy + Ayah reference
                              Row(
                                children: [
                                  Text(
                                    surahMeta.name,
                                    style: GoogleFonts.amiri(
                                      fontSize: 15,
                                      fontWeight: FontWeight.bold,
                                      color: AppColors.quranGold,
                                    ),
                                  ),
                                  const SizedBox(width: 8),
                                  Text(
                                    isAudioActive
                                        ? '• ${surahMeta.numberOfAyahs} ayat'
                                        : '• Ayah $lastReadAyah',
                                    style: GoogleFonts.plusJakartaSans(
                                      fontSize: 11.5,
                                      fontWeight: FontWeight.w600,
                                      color: Colors.white70,
                                    ),
                                  ),
                                ],
                              ),

                              const SizedBox(height: 14),

                              // In-place Frequency Bars & Action Control Row
                              // Backgroundless, fitting directly on the main card surface
                              Row(
                                children: [
                                  if (isAudioActive) ...[
                                    // Pause button
                                    GestureDetector(
                                      onTap: () => _audioService.pause(),
                                      child: Container(
                                        width: 32,
                                        height: 32,
                                        decoration: const BoxDecoration(
                                          shape: BoxShape.circle,
                                          color: AppColors.quranGold,
                                        ),
                                        child: const Icon(
                                          Icons.pause_rounded,
                                          size: 18,
                                          color: AppColors.midnightNavy,
                                        ),
                                      ),
                                    ),
                                    const SizedBox(width: 10),

                                    // PURE BACKGROUNDLESS FREQUENCY BARS
                                    const _BackgroundlessFrequencyWave(
                                      isPlaying: true,
                                      barColor: AppColors.quranGold,
                                    ),

                                    const SizedBox(width: 12),
                                  ],

                                  // Continue Reading Button
                                  GestureDetector(
                                    onTap: () => _openReader(surahMeta,
                                        initialAyah: isAudioActive
                                            ? _audioService
                                                    .currentPlayingAyah.value ??
                                                1
                                            : lastReadAyah),
                                    child: Container(
                                      padding: const EdgeInsets.symmetric(
                                          horizontal: 14, vertical: 7),
                                      decoration: BoxDecoration(
                                        color: AppColors.quranGold,
                                        borderRadius:
                                            BorderRadius.circular(16),
                                        boxShadow: const [
                                          BoxShadow(
                                            color: Color(0x55F5CE63),
                                            blurRadius: 8,
                                            offset: Offset(0, 2),
                                          ),
                                        ],
                                      ),
                                      child: Row(
                                        mainAxisSize: MainAxisSize.min,
                                        children: [
                                          Text(
                                            'Continue Reading',
                                            style:
                                                GoogleFonts.plusJakartaSans(
                                              fontSize: 11.5,
                                              fontWeight: FontWeight.bold,
                                              color: AppColors.midnightNavy,
                                            ),
                                          ),
                                          const SizedBox(width: 3),
                                          const Icon(
                                            Icons.chevron_right_rounded,
                                            size: 15,
                                            color: AppColors.midnightNavy,
                                          ),
                                        ],
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            ],
                          ),
                        ),

                        // Right: Larger 3D Holy Quran Graphic Asset
                        Image.asset(
                          'assets/quran asset.png',
                          width: 125,
                          height: 140,
                          fit: BoxFit.contain,
                          errorBuilder: (context, error, stackTrace) =>
                              const Quran3DGraphic(width: 110, height: 130),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            );
          },
        );
      },
    );
  }

  /// Segmented TabBar with Unique Islamic Icons (Surah, Para, Page, Hizb)
  Widget _buildSegmentedTabBar(
      bool isDark, Color textPrimary, Color textSecondary) {
    final tabs = [
      {'label': 'Surah', 'icon': Icons.menu_book_rounded},
      {'label': 'Para', 'icon': Icons.auto_stories_rounded},
      {'label': 'Page', 'icon': Icons.library_books_rounded},
      {'label': 'Hizb', 'icon': Icons.stars_rounded},
    ];

    return Container(
      height: 48,
      padding: const EdgeInsets.all(4),
      decoration: BoxDecoration(
        color: isDark ? AppColors.darkCard : const Color(0xFFF1EFE9),
        borderRadius: BorderRadius.circular(26),
        border: Border.all(
          color: isDark ? AppColors.darkBorder : Colors.black.withOpacity(0.05),
          width: 0.8,
        ),
      ),
      child: Row(
        children: List.generate(tabs.length, (index) {
          final isSelected = _selectedTabIndex == index;
          final tab = tabs[index];

          return Expanded(
            child: GestureDetector(
              onTap: () {
                setState(() {
                  _selectedTabIndex = index;
                });
              },
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 200),
                curve: Curves.easeInOut,
                decoration: BoxDecoration(
                  color: isSelected
                      ? AppColors.deepEmerald
                      : Colors.transparent,
                  borderRadius: BorderRadius.circular(22),
                  boxShadow: isSelected
                      ? [
                          BoxShadow(
                            color: AppColors.deepEmerald.withOpacity(0.35),
                            blurRadius: 8,
                            offset: const Offset(0, 2),
                          ),
                        ]
                      : null,
                ),
                alignment: Alignment.center,
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(
                      tab['icon'] as IconData,
                      size: 15,
                      color: isSelected
                          ? AppColors.quranGold
                          : textSecondary,
                    ),
                    const SizedBox(width: 6),
                    Text(
                      tab['label'] as String,
                      style: GoogleFonts.plusJakartaSans(
                        fontSize: 12.5,
                        fontWeight:
                            isSelected ? FontWeight.bold : FontWeight.w600,
                        color: isSelected ? Colors.white : textSecondary,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          );
        }),
      ),
    );
  }

  /// Active Tab Sliver (Surah, Para, Page, or Hizb)
  Widget _buildActiveTabSliver(
      bool isDark, Color textPrimary, Color textSecondary) {
    switch (_selectedTabIndex) {
      case 1:
        return _buildParaSliver(isDark, textPrimary, textSecondary);
      case 2:
        return _buildPageSliver(isDark, textPrimary, textSecondary);
      case 3:
        return _buildHizbSliver(isDark, textPrimary, textSecondary);
      default:
        return _buildSurahSliver(isDark, textPrimary, textSecondary);
    }
  }

  /// Surah Tab Sliver with Rub-el-Hizb Star Badges and In-Place Play
  Widget _buildSurahSliver(
      bool isDark, Color textPrimary, Color textSecondary) {
    if (_filteredSurahs.isEmpty) {
      return SliverToBoxAdapter(child: _buildEmptyState('No surahs found'));
    }

    return SliverPadding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      sliver: SliverList(
        delegate: SliverChildBuilderDelegate(
          (context, index) {
            final surah = _filteredSurahs[index];
            return Container(
              margin: const EdgeInsets.only(bottom: 12),
              decoration: BoxDecoration(
                color: isDark ? AppColors.darkSurface : AppColors.lightSurface,
                borderRadius: BorderRadius.circular(22),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(isDark ? 0.2 : 0.04),
                    blurRadius: 10,
                    offset: const Offset(0, 3),
                  ),
                ],
              ),
              child: InkWell(
                onTap: () => _openReader(surah),
                borderRadius: BorderRadius.circular(22),
                child: Padding(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                  child: Row(
                    children: [
                      // Authentic Rub-el-Hizb 8-pointed star badge
                      IslamicStarBadge(
                        number: surah.number,
                        size: 38,
                        color: AppColors.accentGoldDark,
                        textColor: isDark ? Colors.white : AppColors.midnightNavy,
                      ),
                      const SizedBox(width: 14),

                      // Surah English Name + Translation & Ayat count
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              surah.englishName,
                              style: GoogleFonts.plusJakartaSans(
                                fontSize: 16,
                                fontWeight: FontWeight.bold,
                                color: textPrimary,
                              ),
                              overflow: TextOverflow.ellipsis,
                            ),
                            const SizedBox(height: 3),
                            Text(
                              '${surah.englishNameTranslation} • ${surah.numberOfAyahs} ayat',
                              style: GoogleFonts.plusJakartaSans(
                                fontSize: 12,
                                fontWeight: FontWeight.w500,
                                color: textSecondary,
                              ),
                            ),
                          ],
                        ),
                      ),

                      // Arabic Calligraphy in Gold
                      Text(
                        surah.name,
                        textDirection: TextDirection.rtl,
                        style: GoogleFonts.amiri(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                          color: AppColors.accentGoldDark,
                        ),
                      ),
                      const SizedBox(width: 14),

                      // Solid Gold Play Button — triggers in-place recitation and updates main card
                      GestureDetector(
                        onTap: () {
                          _audioService.playAyah(
                            surahNumber: surah.number,
                            ayahNumber: 1,
                            maxVerses: surah.numberOfAyahs,
                          );
                        },
                        child: Container(
                          width: 38,
                          height: 38,
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            color: AppColors.quranGold,
                            boxShadow: [
                              BoxShadow(
                                color: AppColors.quranGold.withOpacity(0.35),
                                blurRadius: 8,
                                offset: const Offset(0, 2),
                              ),
                            ],
                          ),
                          alignment: Alignment.center,
                          child: const Icon(
                            Icons.play_arrow_rounded,
                            color: AppColors.midnightNavy,
                            size: 22,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            );
          },
          childCount: _filteredSurahs.length,
        ),
      ),
    );
  }

  /// Para (Juz) Tab Sliver (30 Juzs with Real Information)
  Widget _buildParaSliver(
      bool isDark, Color textPrimary, Color textSecondary) {
    if (_filteredJuzs.isEmpty) {
      return SliverToBoxAdapter(child: _buildEmptyState('No paras found'));
    }

    return SliverPadding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      sliver: SliverList(
        delegate: SliverChildBuilderDelegate(
          (context, index) {
            final juz = _filteredJuzs[index];
            final surahMeta = kAllSurahs.firstWhere(
              (s) => s.number == juz.startSurahNumber,
              orElse: () => kAllSurahs.first,
            );

            return Container(
              margin: const EdgeInsets.only(bottom: 12),
              decoration: BoxDecoration(
                color: isDark ? AppColors.darkSurface : AppColors.lightSurface,
                borderRadius: BorderRadius.circular(22),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(isDark ? 0.2 : 0.04),
                    blurRadius: 10,
                    offset: const Offset(0, 3),
                  ),
                ],
              ),
              child: InkWell(
                onTap: () =>
                    _openReader(surahMeta, initialAyah: juz.startAyah),
                borderRadius: BorderRadius.circular(22),
                child: Padding(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                  child: Row(
                    children: [
                      IslamicStarBadge(
                        number: juz.number,
                        size: 38,
                        color: AppColors.accentGoldDark,
                        textColor: isDark ? Colors.white : AppColors.midnightNavy,
                      ),
                      const SizedBox(width: 14),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              children: [
                                Text(
                                  'Juz ${juz.number}',
                                  style: GoogleFonts.plusJakartaSans(
                                    fontSize: 16,
                                    fontWeight: FontWeight.bold,
                                    color: textPrimary,
                                  ),
                                ),
                                const SizedBox(width: 10),
                                Text(
                                  juz.arabicName,
                                  textDirection: TextDirection.rtl,
                                  style: GoogleFonts.amiri(
                                    fontSize: 17,
                                    fontWeight: FontWeight.bold,
                                    color: AppColors.accentGoldDark,
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 3),
                            Text(
                              'Starts at Surah ${juz.startSurahName} (${juz.startSurahNumber}:${juz.startAyah})',
                              style: GoogleFonts.plusJakartaSans(
                                fontSize: 12,
                                color: textSecondary,
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                          ],
                        ),
                      ),
                      const Icon(Icons.arrow_forward_ios_rounded,
                          size: 14, color: AppColors.accentGoldDark),
                    ],
                  ),
                ),
              ),
            );
          },
          childCount: _filteredJuzs.length,
        ),
      ),
    );
  }

  /// Page Tab Sliver (604 Standard Madani Mushaf Pages with Real Mapping)
  Widget _buildPageSliver(
      bool isDark, Color textPrimary, Color textSecondary) {
    if (_filteredPages.isEmpty) {
      return SliverToBoxAdapter(child: _buildEmptyState('No pages found'));
    }

    return SliverPadding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      sliver: SliverList(
        delegate: SliverChildBuilderDelegate(
          (context, index) {
            final page = _filteredPages[index];
            final surahMeta = kAllSurahs.firstWhere(
              (s) => s.number == page.surahNumber,
              orElse: () => kAllSurahs.first,
            );

            return Container(
              margin: const EdgeInsets.only(bottom: 10),
              decoration: BoxDecoration(
                color: isDark ? AppColors.darkSurface : AppColors.lightSurface,
                borderRadius: BorderRadius.circular(20),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(isDark ? 0.2 : 0.04),
                    blurRadius: 8,
                    offset: const Offset(0, 2),
                  ),
                ],
              ),
              child: ListTile(
                dense: true,
                contentPadding:
                    const EdgeInsets.symmetric(horizontal: 14, vertical: 2),
                leading: IslamicStarBadge(
                  number: page.pageNumber,
                  size: 36,
                  color: AppColors.accentGoldDark,
                  textColor: isDark ? Colors.white : AppColors.midnightNavy,
                ),
                title: Row(
                  children: [
                    Text(
                      'Page ${page.pageNumber}',
                      style: GoogleFonts.plusJakartaSans(
                        fontSize: 14,
                        fontWeight: FontWeight.bold,
                        color: textPrimary,
                      ),
                    ),
                    const SizedBox(width: 8),
                    Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 6, vertical: 2),
                      decoration: BoxDecoration(
                        color: isDark
                            ? Colors.white.withOpacity(0.08)
                            : Colors.black.withOpacity(0.05),
                        borderRadius: BorderRadius.circular(6),
                      ),
                      child: Text(
                        'Juz ${page.juzNumber}',
                        style: GoogleFonts.plusJakartaSans(
                          fontSize: 10,
                          fontWeight: FontWeight.w600,
                          color: textSecondary,
                        ),
                      ),
                    ),
                  ],
                ),
                subtitle: Text(
                  'Surah ${page.surahName} (${page.surahNameArabic})',
                  style: GoogleFonts.plusJakartaSans(
                    fontSize: 11.5,
                    color: textSecondary,
                  ),
                ),
                trailing: const Icon(Icons.arrow_forward_ios_rounded,
                    size: 14, color: AppColors.accentGoldDark),
                onTap: () =>
                    _openReader(surahMeta, initialAyah: page.startAyah),
              ),
            );
          },
          childCount: _filteredPages.length,
        ),
      ),
    );
  }

  /// Hizb Tab Sliver (60 Verified Hizbs with Authentic Details)
  Widget _buildHizbSliver(
      bool isDark, Color textPrimary, Color textSecondary) {
    if (_filteredHizbs.isEmpty) {
      return SliverToBoxAdapter(child: _buildEmptyState('No hizbs found'));
    }

    return SliverPadding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      sliver: SliverList(
        delegate: SliverChildBuilderDelegate(
          (context, index) {
            final hizb = _filteredHizbs[index];
            final surahMeta = kAllSurahs.firstWhere(
              (s) => s.number == hizb.surahNumber,
              orElse: () => kAllSurahs.first,
            );

            return Container(
              margin: const EdgeInsets.only(bottom: 10),
              decoration: BoxDecoration(
                color: isDark ? AppColors.darkSurface : AppColors.lightSurface,
                borderRadius: BorderRadius.circular(20),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(isDark ? 0.2 : 0.04),
                    blurRadius: 8,
                    offset: const Offset(0, 2),
                  ),
                ],
              ),
              child: ListTile(
                dense: true,
                contentPadding:
                    const EdgeInsets.symmetric(horizontal: 14, vertical: 4),
                leading: IslamicStarBadge(
                  number: hizb.hizbNumber,
                  size: 36,
                  color: AppColors.accentGoldDark,
                  textColor: isDark ? Colors.white : AppColors.midnightNavy,
                ),
                title: Row(
                  children: [
                    Text(
                      'Hizb ${hizb.hizbNumber}',
                      style: GoogleFonts.plusJakartaSans(
                        fontSize: 14,
                        fontWeight: FontWeight.bold,
                        color: textPrimary,
                      ),
                    ),
                    const SizedBox(width: 8),
                    Text(
                      hizb.arabicOpening,
                      textDirection: TextDirection.rtl,
                      style: GoogleFonts.amiri(
                        fontSize: 15,
                        fontWeight: FontWeight.bold,
                        color: AppColors.accentGoldDark,
                      ),
                    ),
                  ],
                ),
                subtitle: Text(
                  'Juz ${hizb.juzNumber} • Surah ${hizb.surahName} (${hizb.surahNumber}:${hizb.startAyah})',
                  style: GoogleFonts.plusJakartaSans(
                    fontSize: 11.5,
                    color: textSecondary,
                  ),
                ),
                trailing: const Icon(Icons.arrow_forward_ios_rounded,
                    size: 14, color: AppColors.accentGoldDark),
                onTap: () =>
                    _openReader(surahMeta, initialAyah: hizb.startAyah),
              ),
            );
          },
          childCount: _filteredHizbs.length,
        ),
      ),
    );
  }

  Widget _buildEmptyState(String message) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 48),
      child: Center(
        child: Column(
          children: [
            const Icon(Icons.search_off_rounded, size: 40, color: Colors.grey),
            const SizedBox(height: 8),
            Text(
              message,
              style: GoogleFonts.plusJakartaSans(color: Colors.grey),
            ),
          ],
        ),
      ),
    );
  }
}

/// Pure Backgroundless Frequency Waveform Bars
/// Zero background box, zero outline — fits directly on the surface
class _BackgroundlessFrequencyWave extends StatefulWidget {
  final bool isPlaying;
  final Color barColor;

  const _BackgroundlessFrequencyWave({
    required this.isPlaying,
    this.barColor = AppColors.quranGold,
  });

  @override
  State<_BackgroundlessFrequencyWave> createState() =>
      _BackgroundlessFrequencyWaveState();
}

class _BackgroundlessFrequencyWaveState
    extends State<_BackgroundlessFrequencyWave>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;

  static const List<double> _baseHeights = [
    10.0,
    18.0,
    8.0,
    22.0,
    14.0,
    20.0,
    9.0,
    16.0,
    12.0,
  ];

  static const List<double> _phaseShifts = [
    0.0,
    0.6,
    1.3,
    2.0,
    2.7,
    3.4,
    4.1,
    4.8,
    5.5,
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
  void didUpdateWidget(covariant _BackgroundlessFrequencyWave oldWidget) {
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
            double height = 4.0;
            if (widget.isPlaying) {
              final t = (_controller.value * 2 * math.pi) + phase;
              final factor = (math.sin(t) + 1.0) / 2.0;
              height = 4.0 + factor * (base - 4.0);
            }

            return Container(
              margin: const EdgeInsets.symmetric(horizontal: 1.3),
              width: 2.8,
              height: height,
              decoration: BoxDecoration(
                color: widget.barColor,
                borderRadius: BorderRadius.circular(1.5),
                boxShadow: widget.isPlaying
                    ? [
                        BoxShadow(
                          color: widget.barColor.withOpacity(0.55),
                          blurRadius: 4,
                          spreadRadius: 0.4,
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
