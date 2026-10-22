import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../constants/app_colors.dart';
import '../constants/surah_data.dart';
import '../models/juz.dart';
import '../services/storage_service.dart';
import '../widgets/glass_card.dart';
import '../widgets/surah_card.dart';
import 'reader_screen.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> with SingleTickerProviderStateMixin {
  late TabController _tabController;
  final TextEditingController _searchController = TextEditingController();
  final StorageService _storage = StorageService();

  List<SurahMeta> _filteredSurahs = kAllSurahs;
  Map<String, dynamic>? _lastRead;
  List<int> _bookmarkedSurahs = [];

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
    _loadState();
  }

  Future<void> _loadState() async {
    final lastRead = await _storage.getLastRead();
    final bookmarks = await _storage.getBookmarkedSurahs();
    if (mounted) {
      setState(() {
        _lastRead = lastRead;
        _bookmarkedSurahs = bookmarks;
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
              s.englishNameTranslation.toLowerCase().contains(q) ||
              s.name.contains(q) ||
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
    ).then((_) => _loadState());
  }

  @override
  void dispose() {
    _tabController.dispose();
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.primaryDark,
      body: SafeArea(
        child: NestedScrollView(
          headerSliverBuilder: (context, innerBoxIsScrolled) {
            return [
              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(16, 16, 16, 10),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      // Header Row
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'My Quran',
                                style: GoogleFonts.plusJakartaSans(
                                  fontSize: 22,
                                  fontWeight: FontWeight.bold,
                                  color: AppColors.textLight,
                                ),
                              ),
                              const SizedBox(height: 2),
                              Text(
                                'Read, explore and reflect',
                                style: GoogleFonts.plusJakartaSans(
                                  fontSize: 13,
                                  color: AppColors.textMuted,
                                ),
                              ),
                            ],
                          ),
                          Container(
                            padding: const EdgeInsets.all(8),
                            decoration: BoxDecoration(
                              color: AppColors.primary,
                              borderRadius: BorderRadius.circular(12),
                              border: Border.all(
                                color: AppColors.gold.withOpacity(0.4),
                                width: 1,
                              ),
                            ),
                            child: const Icon(
                              Icons.menu_book_rounded,
                              color: AppColors.gold,
                              size: 22,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 16),

                      // Last Read Quick Resume Card (if exists)
                      _buildLastReadCard(),
                      const SizedBox(height: 12),

                      // Search Bar (iOS Frosted Glass)
                      GlassCard(
                        borderRadius: 16,
                        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 2),
                        color: AppColors.glassBackground,
                        borderColor: AppColors.glassBorderSubtle,
                        child: TextField(
                          controller: _searchController,
                          onChanged: _onSearch,
                          style: GoogleFonts.plusJakartaSans(
                            color: AppColors.textLight,
                            fontSize: 14,
                          ),
                          decoration: InputDecoration(
                            border: InputBorder.none,
                            hintText: 'Search Surah by name or number...',
                            hintStyle: GoogleFonts.plusJakartaSans(
                              color: AppColors.textMuted,
                              fontSize: 13,
                            ),
                            icon: const Icon(
                              Icons.search_rounded,
                              color: AppColors.gold,
                              size: 20,
                            ),
                            suffixIcon: _searchController.text.isNotEmpty
                                ? IconButton(
                                    icon: const Icon(Icons.clear_rounded, size: 16, color: AppColors.textMuted),
                                    onPressed: () {
                                      _searchController.clear();
                                      _onSearch('');
                                    },
                                  )
                                : null,
                          ),
                        ),
                      ),
                      const SizedBox(height: 16),

                      // Frosted Tab Bar (No gradients, pure solid & glass)
                      Container(
                        height: 44,
                        decoration: BoxDecoration(
                          color: AppColors.primarySurface.withOpacity(0.4),
                          borderRadius: BorderRadius.circular(14),
                          border: Border.all(
                            color: AppColors.glassBorderSubtle,
                            width: 1,
                          ),
                        ),
                        child: TabBar(
                          controller: _tabController,
                          indicator: BoxDecoration(
                            color: AppColors.primary,
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(
                              color: AppColors.gold.withOpacity(0.5),
                              width: 1,
                            ),
                          ),
                          indicatorSize: TabBarIndicatorSize.tab,
                          dividerColor: Colors.transparent,
                          labelColor: AppColors.gold,
                          unselectedLabelColor: AppColors.textMuted,
                          labelStyle: GoogleFonts.plusJakartaSans(
                            fontWeight: FontWeight.bold,
                            fontSize: 13,
                          ),
                          unselectedLabelStyle: GoogleFonts.plusJakartaSans(
                            fontWeight: FontWeight.w500,
                            fontSize: 13,
                          ),
                          tabs: const [
                            Tab(text: 'Surahs (114)'),
                            Tab(text: 'Juz (30)'),
                            Tab(text: 'Bookmarks'),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ];
          },
          body: TabBarView(
            controller: _tabController,
            children: [
              // Tab 1: Surahs List
              _buildSurahList(),

              // Tab 2: Juz List
              _buildJuzList(),

              // Tab 3: Bookmarks List
              _buildBookmarksList(),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildLastReadCard() {
    final surahNum = _lastRead?['surah'] as int? ?? 1;
    final surahName = _lastRead?['surahName'] as String? ?? 'Al-Fatiha';
    final ayahNum = _lastRead?['ayah'] as int? ?? 1;

    final surahMeta = kAllSurahs.firstWhere(
      (s) => s.number == surahNum,
      orElse: () => kAllSurahs.first,
    );

    return GlassCard(
      borderRadius: 18,
      padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 16),
      color: AppColors.primary,
      borderColor: AppColors.gold.withOpacity(0.35),
      onTap: () => _openReader(surahMeta),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: AppColors.primarySurface,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(
                color: AppColors.gold.withOpacity(0.4),
                width: 1,
              ),
            ),
            child: const Icon(
              Icons.auto_stories_rounded,
              color: AppColors.gold,
              size: 24,
            ),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    const Icon(Icons.bookmark_added_rounded, size: 14, color: AppColors.gold),
                    const SizedBox(width: 4),
                    Text(
                      'LAST READ',
                      style: GoogleFonts.plusJakartaSans(
                        fontSize: 11,
                        letterSpacing: 1.0,
                        fontWeight: FontWeight.bold,
                        color: AppColors.gold,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 4),
                Text(
                  '$surahName • Ayah $ayahNum',
                  style: GoogleFonts.plusJakartaSans(
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                    color: AppColors.textLight,
                  ),
                ),
              ],
            ),
          ),
          const Icon(
            Icons.arrow_forward_ios_rounded,
            size: 16,
            color: AppColors.gold,
          ),
        ],
      ),
    );
  }

  Widget _buildSurahList() {
    if (_filteredSurahs.isEmpty) {
      return Center(
        child: Text(
          'No Surahs found matching "${_searchController.text}"',
          style: GoogleFonts.plusJakartaSans(color: AppColors.textMuted),
        ),
      );
    }

    return ListView.builder(
      padding: const EdgeInsets.only(top: 8, bottom: 24),
      physics: const BouncingScrollPhysics(),
      itemCount: _filteredSurahs.length,
      itemBuilder: (context, index) {
        final surah = _filteredSurahs[index];
        return SurahCard(
          surah: surah,
          onTap: () => _openReader(surah),
        );
      },
    );
  }

  Widget _buildJuzList() {
    return ListView.builder(
      padding: const EdgeInsets.only(top: 8, bottom: 24),
      physics: const BouncingScrollPhysics(),
      itemCount: kAllJuzs.length,
      itemBuilder: (context, index) {
        final juz = kAllJuzs[index];
        final correspondingSurah = kAllSurahs.firstWhere(
          (s) => s.number == juz.startSurahNumber,
          orElse: () => kAllSurahs.first,
        );

        return Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
          child: GlassCard(
            borderRadius: 18,
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
            onTap: () => _openReader(correspondingSurah),
            child: Row(
              children: [
                // Juz Badge
                Container(
                  width: 44,
                  height: 44,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: AppColors.primary,
                    border: Border.all(
                      color: AppColors.gold.withOpacity(0.5),
                      width: 1.5,
                    ),
                  ),
                  alignment: Alignment.center,
                  child: Text(
                    '${juz.number}',
                    style: GoogleFonts.plusJakartaSans(
                      fontSize: 14,
                      fontWeight: FontWeight.bold,
                      color: AppColors.gold,
                    ),
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Juz ${juz.number}',
                        style: GoogleFonts.plusJakartaSans(
                          fontSize: 16,
                          fontWeight: FontWeight.w600,
                          color: AppColors.textLight,
                        ),
                      ),
                      const SizedBox(height: 3),
                      Text(
                        'Starts at Surah ${juz.startSurahName} (${juz.startSurahNumber}:${juz.startAyah})',
                        style: GoogleFonts.plusJakartaSans(
                          fontSize: 12,
                          color: AppColors.textMuted,
                        ),
                      ),
                    ],
                  ),
                ),
                Text(
                  juz.arabicName,
                  textDirection: TextDirection.rtl,
                  style: GoogleFonts.amiri(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                    color: AppColors.gold,
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildBookmarksList() {
    if (_bookmarkedSurahs.isEmpty) {
      return Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              Icons.bookmark_outline_rounded,
              size: 48,
              color: AppColors.textMuted.withOpacity(0.5),
            ),
            const SizedBox(height: 12),
            Text(
              'No bookmarks saved yet',
              style: GoogleFonts.plusJakartaSans(
                fontSize: 15,
                color: AppColors.textLight,
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              'Tap the bookmark icon in any Surah to save it here',
              style: GoogleFonts.plusJakartaSans(
                fontSize: 12,
                color: AppColors.textMuted,
              ),
            ),
          ],
        ),
      );
    }

    final bookmarkedList = kAllSurahs
        .where((s) => _bookmarkedSurahs.contains(s.number))
        .toList();

    return ListView.builder(
      padding: const EdgeInsets.only(top: 8, bottom: 24),
      physics: const BouncingScrollPhysics(),
      itemCount: bookmarkedList.length,
      itemBuilder: (context, index) {
        final surah = bookmarkedList[index];
        return SurahCard(
          surah: surah,
          onTap: () => _openReader(surah),
        );
      },
    );
  }
}
