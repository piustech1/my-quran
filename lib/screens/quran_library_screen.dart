import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../constants/app_colors.dart';
import '../constants/surah_data.dart';
import '../models/juz.dart';
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

class _QuranLibraryScreenState extends State<QuranLibraryScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  final StorageService _storage = StorageService();
  final QuranAudioService _audioService = QuranAudioService();

  Map<String, dynamic>? _lastRead;
  final TextEditingController _searchController = TextEditingController();
  List<SurahMeta> _filteredSurahs = kAllSurahs;
  bool _isSearching = false;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 4, vsync: this);
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
      if (query.trim().isEmpty) {
        _filteredSurahs = kAllSurahs;
      } else {
        final q = query.toLowerCase().trim();
        _filteredSurahs = kAllSurahs.where((s) {
          return s.englishName.toLowerCase().contains(q) ||
              s.name.contains(q) ||
              s.englishNameTranslation.toLowerCase().contains(q) ||
              s.number.toString() == q;
        }).toList();
      }
    });
  }

  void _openReader(SurahMeta surah) {
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => ReaderScreen(surah: surah),
      ),
    ).then((_) => _loadLastRead());
  }

  @override
  void dispose() {
    _tabController.dispose();
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final bg = isDark ? AppColors.darkBackground : AppColors.lightBackground;
    final textPrimary = isDark ? AppColors.darkTextPrimary : AppColors.lightTextPrimary;
    final textSecondary = isDark ? AppColors.darkTextSecondary : AppColors.lightTextSecondary;

    final lastReadSurahNum = _lastRead?['surah'] as int? ?? 1;
    final lastReadSurahName = _lastRead?['surahName'] as String? ?? 'Al - Fatihah';
    final lastReadAyah = _lastRead?['ayah'] as int? ?? 1;
    final lastReadMeta = kAllSurahs.firstWhere(
      (s) => s.number == lastReadSurahNum,
      orElse: () => kAllSurahs.first,
    );

    return Scaffold(
      backgroundColor: bg,
      appBar: AppBar(
        leadingWidth: 64,
        leading: Padding(
          padding: const EdgeInsets.only(left: 16),
          child: Center(
            child: GestureDetector(
              onTap: () => Navigator.of(context).pop(),
              child: Container(
                width: 40,
                height: 40,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: isDark ? AppColors.darkSurface : AppColors.lightSurfaceSubtle,
                  border: Border.all(
                    color: isDark ? AppColors.darkBorder : AppColors.lightBorder,
                    width: 1,
                  ),
                ),
                alignment: Alignment.center,
                child: Icon(Icons.arrow_back_ios_new_rounded, size: 16, color: textPrimary),
              ),
            ),
          ),
        ),
        centerTitle: true,
        title: _isSearching
            ? TextField(
                controller: _searchController,
                autofocus: true,
                onChanged: _onSearch,
                style: GoogleFonts.plusJakartaSans(
                  color: textPrimary,
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                ),
                decoration: InputDecoration(
                  hintText: 'Search Surah...',
                  hintStyle: GoogleFonts.plusJakartaSans(color: textSecondary),
                  border: InputBorder.none,
                ),
              )
            : Text(
                'Q U R \' A N',
                style: GoogleFonts.plusJakartaSans(
                  fontSize: 16,
                  fontWeight: FontWeight.w800,
                  letterSpacing: 4.0,
                  color: textPrimary,
                ),
              ),
        actions: [
          IconButton(
            icon: Icon(
              _isSearching ? Icons.close_rounded : Icons.search_rounded,
              color: textPrimary,
            ),
            onPressed: () {
              setState(() {
                if (_isSearching) {
                  _searchController.clear();
                  _filteredSurahs = kAllSurahs;
                }
                _isSearching = !_isSearching;
              });
            },
          ),
          const SizedBox(width: 8),
        ],
      ),
      body: Stack(
        children: [
          Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // 1. Golden "Last Read" Card (Exact replica of mockup)
              Padding(
                padding: const EdgeInsets.fromLTRB(16, 6, 16, 14),
                child: Container(
                  height: 172,
                  padding: const EdgeInsets.fromLTRB(22, 18, 14, 18),
                  decoration: BoxDecoration(
                    color: AppColors.accentGold,
                    borderRadius: BorderRadius.circular(28),
                    boxShadow: [
                      BoxShadow(
                        color: AppColors.accentGold.withOpacity(0.38),
                        blurRadius: 20,
                        offset: const Offset(0, 6),
                      ),
                    ],
                  ),
                  child: Row(
                    children: [
                      // Left content
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Row(
                              children: [
                                const Icon(
                                  Icons.menu_book_rounded,
                                  size: 15,
                                  color: Color(0xFF4A3812),
                                ),
                                const SizedBox(width: 6),
                                Text(
                                  'Last Read',
                                  style: GoogleFonts.plusJakartaSans(
                                    fontSize: 13,
                                    fontWeight: FontWeight.w600,
                                    color: const Color(0xFF4A3812),
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 6),
                            Text(
                              'Surah',
                              style: GoogleFonts.plusJakartaSans(
                                fontSize: 12,
                                color: const Color(0xFF634D1C),
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                            const SizedBox(height: 2),
                            Text(
                              lastReadSurahName,
                              style: GoogleFonts.plusJakartaSans(
                                fontSize: 24,
                                fontWeight: FontWeight.w800,
                                color: const Color(0xFF1F1705),
                              ),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                            const SizedBox(height: 2),
                            Text(
                              '${lastReadMeta.name} • Ayah $lastReadAyah',
                              style: GoogleFonts.plusJakartaSans(
                                fontSize: 13,
                                fontWeight: FontWeight.w600,
                                color: const Color(0xFF4A3812),
                              ),
                            ),
                            const SizedBox(height: 12),

                            // Pill button: "Back to reading >"
                            GestureDetector(
                              onTap: () => _openReader(lastReadMeta),
                              child: Container(
                                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                                decoration: BoxDecoration(
                                  color: const Color(0xFF14171A),
                                  borderRadius: BorderRadius.circular(20),
                                ),
                                child: Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    Text(
                                      'Back to reading',
                                      style: GoogleFonts.plusJakartaSans(
                                        fontSize: 12,
                                        fontWeight: FontWeight.bold,
                                        color: Colors.white,
                                      ),
                                    ),
                                    const SizedBox(width: 4),
                                    const Icon(
                                      Icons.chevron_right_rounded,
                                      size: 15,
                                      color: Colors.white,
                                    ),
                                  ],
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),

                      // Right 3D Book Graphic from user assets
                      Image.asset(
                        'assets/quran asset.png',
                        width: 120,
                        height: 140,
                        fit: BoxFit.contain,
                        errorBuilder: (context, error, stackTrace) =>
                            const Quran3DGraphic(width: 100, height: 125),
                      ),
                    ],
                  ),
                ),
              ),

              // 2. Category Tabs: Surah | Para | Page | Hizb (matching Image 1)
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                child: TabBar(
                  controller: _tabController,
                  dividerColor: Colors.transparent,
                  indicatorColor: AppColors.accentGold,
                  indicatorWeight: 3.0,
                  indicatorSize: TabBarIndicatorSize.label,
                  labelColor: textPrimary,
                  unselectedLabelColor: textSecondary,
                  labelStyle: GoogleFonts.plusJakartaSans(
                    fontWeight: FontWeight.bold,
                    fontSize: 15,
                  ),
                  unselectedLabelStyle: GoogleFonts.plusJakartaSans(
                    fontWeight: FontWeight.w500,
                    fontSize: 15,
                  ),
                  tabs: const [
                    Tab(text: 'Surah'),
                    Tab(text: 'Para'),
                    Tab(text: 'Page'),
                    Tab(text: 'Hizb'),
                  ],
                ),
              ),
              const SizedBox(height: 8),

              // 3. Tab Views
              Expanded(
                child: TabBarView(
                  controller: _tabController,
                  children: [
                    // Tab 1: Surah List (with rounded cards, gold play buttons, and ayat count)
                    _buildSurahListView(textPrimary, textSecondary, isDark),

                    // Tab 2: Para (Juz) List
                    _buildParaListView(textPrimary, textSecondary, isDark),

                    // Tab 3: Page List (Medina Mushaf 604 standard pages)
                    _buildPageListView(textPrimary, textSecondary, isDark),

                    // Tab 4: Hizb List (60 Hizbs)
                    _buildHizbListView(textPrimary, textSecondary, isDark),
                  ],
                ),
              ),
            ],
          ),

          // Floating Audio Player at bottom if recitation is active
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

  Widget _buildSurahListView(Color textPrimary, Color textSecondary, bool isDark) {
    return ListView.builder(
      physics: const BouncingScrollPhysics(),
      padding: const EdgeInsets.only(top: 8, bottom: 90, left: 16, right: 16),
      itemCount: _filteredSurahs.length,
      itemBuilder: (context, index) {
        final surah = _filteredSurahs[index];
        return Container(
          margin: const EdgeInsets.only(bottom: 12),
          decoration: BoxDecoration(
            color: isDark ? AppColors.darkSurface : AppColors.lightSurface,
            borderRadius: BorderRadius.circular(22),
            border: Border.all(
              color: isDark ? AppColors.darkBorder : AppColors.lightBorder,
              width: 1,
            ),
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
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
              child: Row(
                children: [
                  // Number in circular gold border (matching Image 1)
                  Container(
                    width: 40,
                    height: 40,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      border: Border.all(
                        color: AppColors.accentGold.withOpacity(0.65),
                        width: 1.2,
                      ),
                      color: isDark ? AppColors.darkSurfaceSubtle : AppColors.lightSurfaceSubtle,
                    ),
                    alignment: Alignment.center,
                    child: Text(
                      '${surah.number}',
                      style: GoogleFonts.plusJakartaSans(
                        fontSize: 13,
                        fontWeight: FontWeight.bold,
                        color: AppColors.accentGold,
                      ),
                    ),
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

                  // Arabic calligraphy name in gold
                  Text(
                    surah.name,
                    textDirection: TextDirection.rtl,
                    style: GoogleFonts.amiri(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: AppColors.accentGold,
                    ),
                  ),
                  const SizedBox(width: 14),

                  // Circular Solid Gold Play Button (matching Image 1)
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
                        color: AppColors.accentGold,
                        boxShadow: [
                          BoxShadow(
                            color: AppColors.accentGold.withOpacity(0.35),
                            blurRadius: 8,
                            offset: const Offset(0, 2),
                          ),
                        ],
                      ),
                      alignment: Alignment.center,
                      child: const Icon(
                        Icons.play_arrow_rounded,
                        color: Color(0xFF14171A),
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
    );
  }

  Widget _buildParaListView(Color textPrimary, Color textSecondary, bool isDark) {
    return ListView.builder(
      physics: const BouncingScrollPhysics(),
      padding: const EdgeInsets.only(top: 8, bottom: 90, left: 16, right: 16),
      itemCount: kAllJuzs.length,
      itemBuilder: (context, index) {
        final juz = kAllJuzs[index];
        final surahMeta = kAllSurahs.firstWhere(
          (s) => s.number == juz.startSurahNumber,
          orElse: () => kAllSurahs.first,
        );

        return Container(
          margin: const EdgeInsets.only(bottom: 12),
          decoration: BoxDecoration(
            color: isDark ? AppColors.darkSurface : AppColors.lightSurface,
            borderRadius: BorderRadius.circular(22),
            border: Border.all(
              color: isDark ? AppColors.darkBorder : AppColors.lightBorder,
              width: 1,
            ),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(isDark ? 0.2 : 0.04),
                blurRadius: 10,
                offset: const Offset(0, 3),
              ),
            ],
          ),
          child: InkWell(
            onTap: () => _openReader(surahMeta),
            borderRadius: BorderRadius.circular(22),
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
              child: Row(
                children: [
                  Container(
                    width: 40,
                    height: 40,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      border: Border.all(
                        color: AppColors.accentGold.withOpacity(0.65),
                        width: 1.2,
                      ),
                      color: isDark ? AppColors.darkSurfaceSubtle : AppColors.lightSurfaceSubtle,
                    ),
                    alignment: Alignment.center,
                    child: Text(
                      '${juz.number}',
                      style: GoogleFonts.plusJakartaSans(
                        fontSize: 13,
                        fontWeight: FontWeight.bold,
                        color: AppColors.accentGold,
                      ),
                    ),
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
                                color: AppColors.accentGold,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 2),
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
                  const Icon(Icons.arrow_forward_ios_rounded, size: 14, color: AppColors.accentGold),
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _buildPageListView(Color textPrimary, Color textSecondary, bool isDark) {
    // 604 standard pages of the Medina Mushaf
    return ListView.builder(
      physics: const BouncingScrollPhysics(),
      padding: const EdgeInsets.only(top: 8, bottom: 90, left: 16, right: 16),
      itemCount: 604,
      itemBuilder: (context, index) {
        final pageNum = index + 1;
        final approxSurahNum = ((pageNum / 604) * 114).clamp(1, 114).toInt();
        final surahMeta = kAllSurahs.firstWhere((s) => s.number == approxSurahNum, orElse: () => kAllSurahs.first);

        return Container(
          margin: const EdgeInsets.only(bottom: 10),
          decoration: BoxDecoration(
            color: isDark ? AppColors.darkSurface : AppColors.lightSurface,
            borderRadius: BorderRadius.circular(20),
            border: Border.all(
              color: isDark ? AppColors.darkBorder : AppColors.lightBorder,
              width: 1,
            ),
          ),
          child: ListTile(
            dense: true,
            contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 2),
            leading: IslamicStarBadge(number: pageNum, size: 34),
            title: Text(
              'Page $pageNum',
              style: GoogleFonts.plusJakartaSans(
                fontSize: 14,
                fontWeight: FontWeight.bold,
                color: textPrimary,
              ),
            ),
            subtitle: Text(
              'Near Surah ${surahMeta.englishName}',
              style: GoogleFonts.plusJakartaSans(fontSize: 11, color: textSecondary),
            ),
            trailing: const Icon(Icons.arrow_forward_ios_rounded, size: 14, color: AppColors.accentGold),
            onTap: () => _openReader(surahMeta),
          ),
        );
      },
    );
  }

  Widget _buildHizbListView(Color textPrimary, Color textSecondary, bool isDark) {
    // 60 Hizbs in the Quran
    return ListView.builder(
      physics: const BouncingScrollPhysics(),
      padding: const EdgeInsets.only(top: 8, bottom: 90, left: 16, right: 16),
      itemCount: 60,
      itemBuilder: (context, index) {
        final hizbNum = index + 1;
        final approxSurahNum = ((hizbNum / 60) * 114).clamp(1, 114).toInt();
        final surahMeta = kAllSurahs.firstWhere((s) => s.number == approxSurahNum, orElse: () => kAllSurahs.first);

        return Container(
          margin: const EdgeInsets.only(bottom: 10),
          decoration: BoxDecoration(
            color: isDark ? AppColors.darkSurface : AppColors.lightSurface,
            borderRadius: BorderRadius.circular(20),
            border: Border.all(
              color: isDark ? AppColors.darkBorder : AppColors.lightBorder,
              width: 1,
            ),
          ),
          child: ListTile(
            dense: true,
            contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 2),
            leading: IslamicStarBadge(number: hizbNum, size: 34),
            title: Text(
              'Hizb $hizbNum',
              style: GoogleFonts.plusJakartaSans(
                fontSize: 14,
                fontWeight: FontWeight.bold,
                color: textPrimary,
              ),
            ),
            subtitle: Text(
              'In Surah ${surahMeta.englishName}',
              style: GoogleFonts.plusJakartaSans(fontSize: 11, color: textSecondary),
            ),
            trailing: const Icon(Icons.arrow_forward_ios_rounded, size: 14, color: AppColors.accentGold),
            onTap: () => _openReader(surahMeta),
          ),
        );
      },
    );
  }
}
