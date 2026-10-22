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
    final lastReadMeta = kAllSurahs.firstWhere(
      (s) => s.number == lastReadSurahNum,
      orElse: () => kAllSurahs.first,
    );

    return Scaffold(
      backgroundColor: bg,
      appBar: AppBar(
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new_rounded, size: 20),
          color: textPrimary,
          onPressed: () => Navigator.of(context).pop(),
        ),
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
                'QUR\'AN',
                style: GoogleFonts.plusJakartaSans(
                  fontSize: 18,
                  fontWeight: FontWeight.w800,
                  letterSpacing: 1.2,
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
        ],
      ),
      body: Stack(
        children: [
          Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // 1. Golden "Last Read" Card (Exact replica of mockup)
              Padding(
                padding: const EdgeInsets.fromLTRB(16, 8, 16, 12),
                child: Container(
                  height: 140,
                  padding: const EdgeInsets.fromLTRB(20, 16, 12, 16),
                  decoration: BoxDecoration(
                    color: AppColors.accentGold,
                    borderRadius: BorderRadius.circular(22),
                    boxShadow: [
                      BoxShadow(
                        color: AppColors.accentGold.withOpacity(0.35),
                        blurRadius: 18,
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
                                  color: Color(0xFF5A4418),
                                ),
                                const SizedBox(width: 6),
                                Text(
                                  'Last Read',
                                  style: GoogleFonts.plusJakartaSans(
                                    fontSize: 12,
                                    fontWeight: FontWeight.w600,
                                    color: const Color(0xFF5A4418),
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 6),
                            Text(
                              'Surah',
                              style: GoogleFonts.plusJakartaSans(
                                fontSize: 11,
                                color: const Color(0xFF5A4418).withOpacity(0.85),
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                            Text(
                              lastReadSurahName,
                              style: GoogleFonts.plusJakartaSans(
                                fontSize: 19,
                                fontWeight: FontWeight.w800,
                                color: const Color(0xFF231B0A),
                              ),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                            const SizedBox(height: 10),

                            // Pill button: "Back to reading >"
                            GestureDetector(
                              onTap: () => _openReader(lastReadMeta),
                              child: Container(
                                padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 7),
                                decoration: BoxDecoration(
                                  color: AppColors.lightPillButton,
                                  borderRadius: BorderRadius.circular(20),
                                ),
                                child: Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    Text(
                                      'Back to reading',
                                      style: GoogleFonts.plusJakartaSans(
                                        fontSize: 11,
                                        fontWeight: FontWeight.bold,
                                        color: Colors.white,
                                      ),
                                    ),
                                    const SizedBox(width: 4),
                                    const Icon(
                                      Icons.chevron_right_rounded,
                                      size: 14,
                                      color: Colors.white,
                                    ),
                                  ],
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),

                      // Right 3D Book Graphic
                      const Quran3DGraphic(width: 90, height: 115),
                    ],
                  ),
                ),
              ),

              // 2. Category Tabs: Surah | Para | Page | Hijb
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
                    fontSize: 14,
                  ),
                  unselectedLabelStyle: GoogleFonts.plusJakartaSans(
                    fontWeight: FontWeight.w500,
                    fontSize: 14,
                  ),
                  tabs: const [
                    Tab(text: 'Surah'),
                    Tab(text: 'Para'),
                    Tab(text: 'Page'),
                    Tab(text: 'Hijb'),
                  ],
                ),
              ),
              const SizedBox(height: 4),

              // 3. Tab Views
              Expanded(
                child: TabBarView(
                  controller: _tabController,
                  children: [
                    // Tab 1: Surah List (with 8-pointed star & gold play buttons)
                    _buildSurahListView(textPrimary, textSecondary),

                    // Tab 2: Para (Juz) List
                    _buildParaListView(textPrimary, textSecondary),

                    // Tab 3: Page List (Medina Mushaf 604 standard pages)
                    _buildPageListView(textPrimary, textSecondary),

                    // Tab 4: Hijb List (60 Hizbs)
                    _buildHizbListView(textPrimary, textSecondary),
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

  Widget _buildSurahListView(Color textPrimary, Color textSecondary) {
    return ListView.separated(
      physics: const BouncingScrollPhysics(),
      padding: const EdgeInsets.only(top: 8, bottom: 90, left: 16, right: 16),
      itemCount: _filteredSurahs.length,
      separatorBuilder: (_, __) => Divider(
        color: Theme.of(context).brightness == Brightness.dark
            ? AppColors.darkBorder
            : AppColors.lightBorder,
        height: 1,
      ),
      itemBuilder: (context, index) {
        final surah = _filteredSurahs[index];
        return InkWell(
          onTap: () => _openReader(surah),
          borderRadius: BorderRadius.circular(14),
          child: Padding(
            padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 4),
            child: Row(
              children: [
                // 8-Pointed Star Medallion (۞ Rub el Hizb)
                IslamicStarBadge(number: surah.number, size: 38),
                const SizedBox(width: 14),

                // Surah Name (English + Arabic side-by-side as shown in mockup)
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Flexible(
                            child: Text(
                              surah.englishName,
                              style: GoogleFonts.plusJakartaSans(
                                fontSize: 15,
                                fontWeight: FontWeight.bold,
                                color: textPrimary,
                              ),
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                          const SizedBox(width: 10),
                          Text(
                            surah.name,
                            textDirection: TextDirection.rtl,
                            style: GoogleFonts.amiri(
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                              color: AppColors.accentGold,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 2),
                      Text(
                        '${surah.revelationType.toUpperCase()} • ${surah.numberOfAyahs} VERSES',
                        style: GoogleFonts.plusJakartaSans(
                          fontSize: 11,
                          fontWeight: FontWeight.w600,
                          color: textSecondary,
                          letterSpacing: 0.4,
                        ),
                      ),
                    ],
                  ),
                ),

                // Circular Gold Play Button (matching mockup)
                GestureDetector(
                  onTap: () {
                    _audioService.playAyah(
                      surahNumber: surah.number,
                      ayahNumber: 1,
                      maxVerses: surah.numberOfAyahs,
                    );
                  },
                  child: Container(
                    width: 36,
                    height: 36,
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
                      color: AppColors.lightPillButton,
                      size: 22,
                    ),
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildParaListView(Color textPrimary, Color textSecondary) {
    return ListView.separated(
      physics: const BouncingScrollPhysics(),
      padding: const EdgeInsets.only(top: 8, bottom: 90, left: 16, right: 16),
      itemCount: kAllJuzs.length,
      separatorBuilder: (_, __) => Divider(
        color: Theme.of(context).brightness == Brightness.dark
            ? AppColors.darkBorder
            : AppColors.lightBorder,
        height: 1,
      ),
      itemBuilder: (context, index) {
        final juz = kAllJuzs[index];
        final surahMeta = kAllSurahs.firstWhere(
          (s) => s.number == juz.startSurahNumber,
          orElse: () => kAllSurahs.first,
        );

        return InkWell(
          onTap: () => _openReader(surahMeta),
          borderRadius: BorderRadius.circular(14),
          child: Padding(
            padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 4),
            child: Row(
              children: [
                IslamicStarBadge(number: juz.number, size: 38),
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
                              fontSize: 15,
                              fontWeight: FontWeight.bold,
                              color: textPrimary,
                            ),
                          ),
                          const SizedBox(width: 10),
                          Text(
                            juz.arabicName,
                            textDirection: TextDirection.rtl,
                            style: GoogleFonts.amiri(
                              fontSize: 16,
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
                          fontSize: 11,
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
        );
      },
    );
  }

  Widget _buildPageListView(Color textPrimary, Color textSecondary) {
    // 604 standard pages of the Medina Mushaf
    return ListView.builder(
      physics: const BouncingScrollPhysics(),
      padding: const EdgeInsets.only(top: 8, bottom: 90, left: 16, right: 16),
      itemCount: 604,
      itemBuilder: (context, index) {
        final pageNum = index + 1;
        // Map page to approximate surah (Surah 1 on page 1, Surah 2 on page 2, etc.)
        final approxSurahNum = ((pageNum / 604) * 114).clamp(1, 114).toInt();
        final surahMeta = kAllSurahs.firstWhere((s) => s.number == approxSurahNum, orElse: () => kAllSurahs.first);

        return ListTile(
          dense: true,
          contentPadding: const EdgeInsets.symmetric(horizontal: 4, vertical: 2),
          leading: IslamicStarBadge(number: pageNum, size: 34),
          title: Text(
            'Page $pageNum',
            style: GoogleFonts.plusJakartaSans(
              fontSize: 14,
              fontWeight: FontWeight.w600,
              color: textPrimary,
            ),
          ),
          subtitle: Text(
            'Near Surah ${surahMeta.englishName}',
            style: GoogleFonts.plusJakartaSans(fontSize: 11, color: textSecondary),
          ),
          trailing: const Icon(Icons.arrow_forward_ios_rounded, size: 14, color: AppColors.accentGold),
          onTap: () => _openReader(surahMeta),
        );
      },
    );
  }

  Widget _buildHizbListView(Color textPrimary, Color textSecondary) {
    // 60 Hizbs in the Quran
    return ListView.separated(
      physics: const BouncingScrollPhysics(),
      padding: const EdgeInsets.only(top: 8, bottom: 90, left: 16, right: 16),
      itemCount: 60,
      separatorBuilder: (_, __) => Divider(
        color: Theme.of(context).brightness == Brightness.dark
            ? AppColors.darkBorder
            : AppColors.lightBorder,
        height: 1,
      ),
      itemBuilder: (context, index) {
        final hizbNum = index + 1;
        final approxSurahNum = ((hizbNum / 60) * 114).clamp(1, 114).toInt();
        final surahMeta = kAllSurahs.firstWhere((s) => s.number == approxSurahNum, orElse: () => kAllSurahs.first);

        return ListTile(
          dense: true,
          contentPadding: const EdgeInsets.symmetric(horizontal: 4, vertical: 4),
          leading: IslamicStarBadge(number: hizbNum, size: 34),
          title: Text(
            'Hizb (Quarter) $hizbNum',
            style: GoogleFonts.plusJakartaSans(
              fontSize: 14,
              fontWeight: FontWeight.w600,
              color: textPrimary,
            ),
          ),
          subtitle: Text(
            'In Surah ${surahMeta.englishName}',
            style: GoogleFonts.plusJakartaSans(fontSize: 11, color: textSecondary),
          ),
          trailing: const Icon(Icons.arrow_forward_ios_rounded, size: 14, color: AppColors.accentGold),
          onTap: () => _openReader(surahMeta),
        );
      },
    );
  }
}
