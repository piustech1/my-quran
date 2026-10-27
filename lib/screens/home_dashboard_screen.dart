import 'dart:async';
import 'dart:math' as math;
import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../constants/app_colors.dart';
import '../constants/surah_data.dart';
import '../models/juz.dart';
import '../services/audio_service.dart';
import '../services/daily_ayah_service.dart';
import '../services/location_weather_service.dart';
import '../services/prayer_time_service.dart';
import '../services/storage_service.dart';
import '../services/theme_service.dart';
import '../widgets/floating_nav_dock.dart';
import 'daily_ayah_screen.dart';
import 'islamic_reels_screen.dart';
import 'prayers_screen.dart';
import 'quran_library_screen.dart';
import 'reader_screen.dart';
import 'zakat_screen.dart';

class HomeDashboardScreen extends StatefulWidget {
  final bool isEmbeddedInShell;
  final ValueChanged<int>? onNavigateTab;

  const HomeDashboardScreen({
    super.key,
    this.isEmbeddedInShell = false,
    this.onNavigateTab,
  });

  @override
  State<HomeDashboardScreen> createState() => _HomeDashboardScreenState();
}

class _HomeDashboardScreenState extends State<HomeDashboardScreen> {
  final ThemeService _themeService = ThemeService();
  final PrayerTimeService _prayerService = PrayerTimeService();
  final LocationWeatherService _weatherService = LocationWeatherService();
  final DailyAyahService _dailyAyahService = DailyAyahService();
  final QuranAudioService _audioService = QuranAudioService();
  final StorageService _storageService = StorageService();

  Map<String, dynamic>? _lastReadData;
  int _selectedNavIndex = 0;
  PrayerSchedule? _prayerSchedule;
  UpcomingPrayer? _upcomingPrayer;
  WeatherData? _weatherData;
  UserLocation? _userLocation;
  Timer? _clockTimer;
  DateTime _currentTime = DateTime.now();

  @override
  void initState() {
    super.initState();
    _startClock();
    _loadRealData();
    _loadLastRead();
  }

  Future<void> _loadLastRead() async {
    final data = await _storageService.getLastRead();
    if (mounted) {
      setState(() => _lastReadData = data);
    }
  }

  int _getJuzForAyah(int surahNum, int ayahNum) {
    int juz = 1;
    for (final j in kAllJuzs) {
      if (j.startSurahNumber < surahNum ||
          (j.startSurahNumber == surahNum && j.startAyah <= ayahNum)) {
        juz = j.number;
      } else {
        break;
      }
    }
    return juz;
  }

  @override
  void dispose() {
    _clockTimer?.cancel();
    super.dispose();
  }

  void _startClock() {
    _clockTimer = Timer.periodic(const Duration(seconds: 1), (_) {
      if (mounted) {
        setState(() {
          _currentTime = DateTime.now();
          if (_prayerSchedule != null) {
            _upcomingPrayer = _prayerService.getUpcomingPrayer(
              _prayerSchedule!,
              _currentTime,
            );
          }
        });
      }
    });
  }

  Future<void> _loadRealData() async {
    try {
      final loc = await _weatherService.detectLocation();
      if (mounted) {
        setState(() => _userLocation = loc);
      }

      final schedule = await _prayerService.fetchPrayerTimes(
        lat: loc.lat,
        lon: loc.lon,
        city: loc.city,
        country: loc.country,
      );
      final upcoming = _prayerService.getUpcomingPrayer(schedule, DateTime.now());

      final weather = await _weatherService.fetchWeather(
        lat: loc.lat,
        lon: loc.lon,
        city: loc.city,
      );

      if (mounted) {
        setState(() {
          _prayerSchedule = schedule;
          _upcomingPrayer = upcoming;
          _weatherData = weather;
        });
      }
    } catch (_) {
      // Keep graceful offline fallbacks
    }
  }

  String _formatLiveClock(DateTime dt) {
    var hour = dt.hour;
    final min = dt.minute.toString().padLeft(2, '0');
    final sec = dt.second.toString().padLeft(2, '0');
    final period = hour >= 12 ? 'PM' : 'AM';
    if (hour > 12) hour -= 12;
    if (hour == 0) hour = 12;
    final hourStr = hour.toString().padLeft(2, '0');
    return '$hourStr:$min:$sec $period';
  }

  String _formatCurrentDate(DateTime dt) {
    const months = [
      'Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun',
      'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'
    ];
    final m = months[dt.month - 1];
    return '$m ${dt.day}, ${dt.year}';
  }





  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final bg = isDark ? AppColors.darkBackground : AppColors.lightBackground;
    final textPrimary =
        isDark ? AppColors.darkTextPrimary : AppColors.lightTextPrimary;
    final textSecondary =
        isDark ? AppColors.darkTextSecondary : AppColors.lightTextSecondary;

    final dailyAyah = _dailyAyahService.getDailyAyah();

    final topPadding = MediaQuery.of(context).padding.top;
    final headerHeight = topPadding + 265.0;

    return Scaffold(
      backgroundColor: bg,
      body: Stack(
        children: [
          // 1. Mufta Islamic Dome Header with rounded bottom edge matching reference
          Positioned(
            top: 0,
            left: 0,
            right: 0,
            child: SizedBox(
              height: headerHeight,
              child: ClipRRect(
                borderRadius: const BorderRadius.vertical(
                  bottom: Radius.circular(40),
                ),
                child: Stack(
                  fit: StackFit.expand,
                  children: [
                    // Deep forest green base
                    Container(color: const Color(0xFF0D2F1F)),

                    // Mufta Grand Muqarnas Backdrop
                    Image.asset(
                      'assets/new_mufta.jpg',
                      fit: BoxFit.cover,
                      alignment: Alignment.topCenter,
                      filterQuality: FilterQuality.high,
                    ),

                    // Atmospheric gradient overlay for contrast
                    Container(
                      decoration: const BoxDecoration(
                        gradient: LinearGradient(
                          begin: Alignment.topCenter,
                          end: Alignment.bottomCenter,
                          colors: [
                            Color(0x750D2F1F),
                            Color(0x200D2F1F),
                            Color(0x8A0D2F1F),
                          ],
                        ),
                      ),
                    ),

                    // Subtle hairline gold accent line at curved bottom
                    Positioned(
                      bottom: 0,
                      left: 0,
                      right: 0,
                      child: Container(
                        height: 1,
                        decoration: const BoxDecoration(
                          gradient: LinearGradient(
                            colors: [
                              Colors.transparent,
                              Color(0x55F5CE63),
                              Colors.transparent,
                            ],
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),

          // 2. Scrollable Body Content (Overlaps the bottom of the Mufta header)
          Positioned.fill(
            child: SingleChildScrollView(
              physics: const BouncingScrollPhysics(),
              padding: EdgeInsets.fromLTRB(18, topPadding + 155.0, 18, 96),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  // 2. Main Prayer Card (Solid White with drop shadow in Light Mode)
                  Container(
                    height: 184,
                    padding: const EdgeInsets.all(14),
                    decoration: BoxDecoration(
                      color: isDark ? AppColors.darkCard : Colors.white,
                      borderRadius: BorderRadius.circular(30),
                      border: Border.all(
                        color: isDark
                            ? AppColors.darkBorder
                            : const Color(0xFFEFE9DF),
                        width: 1.0,
                      ),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withOpacity(isDark ? 0.40 : 0.08),
                          blurRadius: 28,
                          offset: const Offset(0, 10),
                        ),
                      ],
                    ),
                    child: Row(
                      children: [
                        // Left: The Nested Hour Card (Warm sandy cream surface)
                        Expanded(
                          flex: 11,
                          child: Container(
                            height: double.infinity,
                            padding: const EdgeInsets.fromLTRB(16, 14, 14, 14),
                            decoration: BoxDecoration(
                              color: isDark
                                  ? AppColors.darkInnerCard
                                  : AppColors.lightSurfaceSubtle,
                              borderRadius: BorderRadius.circular(22),
                            ),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Text(
                                  (_upcomingPrayer?.name ?? 'DHUHR')
                                      .split('')
                                      .join(' '),
                                  style: GoogleFonts.plusJakartaSans(
                                    fontSize: 12,
                                    fontWeight: FontWeight.w800,
                                    letterSpacing: 2.5,
                                    color: const Color(0xFFB8934A),
                                  ),
                                ),
                                const SizedBox(height: 5),
                                Builder(
                                  builder: (context) {
                                    final prayerTimeStr =
                                        _upcomingPrayer?.timeFormatted ??
                                            '12:16 PM';
                                    final parts = prayerTimeStr.split(' ');
                                    final timeDigits =
                                        parts.isNotEmpty ? parts[0] : '12:16';
                                    final timeAmPm =
                                        parts.length > 1 ? parts[1] : 'PM';
                                    return RichText(
                                      text: TextSpan(
                                        children: [
                                          TextSpan(
                                            text: '$timeDigits ',
                                            style: GoogleFonts.plusJakartaSans(
                                              fontSize: 30,
                                              fontWeight: FontWeight.w800,
                                              color: isDark
                                                  ? Colors.white
                                                  : AppColors.lightTextPrimary,
                                              letterSpacing: -0.5,
                                            ),
                                          ),
                                          TextSpan(
                                            text: timeAmPm,
                                            style: GoogleFonts.plusJakartaSans(
                                              fontSize: 14,
                                              fontWeight: FontWeight.w600,
                                              color: isDark
                                                  ? Colors.white70
                                                  : const Color(0xFF2B3430),
                                            ),
                                          ),
                                        ],
                                      ),
                                    );
                                  },
                                ),
                                const SizedBox(height: 7),
                                Container(
                                  padding: const EdgeInsets.symmetric(
                                      horizontal: 8, vertical: 3),
                                  decoration: BoxDecoration(
                                    color: isDark
                                        ? Colors.white.withOpacity(0.08)
                                        : const Color(0xFF103C30).withOpacity(0.06),
                                    borderRadius: BorderRadius.circular(8),
                                  ),
                                  child: Row(
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      Container(
                                        width: 5,
                                        height: 5,
                                        decoration: const BoxDecoration(
                                          shape: BoxShape.circle,
                                          color: Color(0xFFB8934A),
                                        ),
                                      ),
                                      const SizedBox(width: 5),
                                      Text(
                                        'NOW',
                                        style: GoogleFonts.plusJakartaSans(
                                          fontSize: 9.5,
                                          fontWeight: FontWeight.w800,
                                          letterSpacing: 1.0,
                                          color: const Color(0xFFB8934A),
                                        ),
                                      ),
                                      const SizedBox(width: 5),
                                      Text(
                                        _formatLiveClock(_currentTime),
                                        style: GoogleFonts.plusJakartaSans(
                                          fontSize: 12,
                                          fontWeight: FontWeight.w700,
                                          color: isDark
                                              ? Colors.white
                                              : AppColors.lightTextPrimary,
                                          letterSpacing: 0.2,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                                const SizedBox(height: 2),
                                Text(
                                  _formatCurrentDate(_currentTime),
                                  style: GoogleFonts.plusJakartaSans(
                                    fontSize: 12,
                                    color: isDark
                                        ? Colors.white38
                                        : AppColors.lightTextSecondary,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                        const SizedBox(width: 14),

                        // Right: 3D Sun/Cloud Graphic & Weather Info
                        Expanded(
                          flex: 9,
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            crossAxisAlignment: CrossAxisAlignment.center,
                            children: [
                              _buildSunCloudIllustration(),
                              const SizedBox(height: 6),
                              Text(
                                '${_weatherData?.temperature ?? 27}°',
                                style: GoogleFonts.plusJakartaSans(
                                  fontSize: 26,
                                  fontWeight: FontWeight.bold,
                                  color: isDark
                                      ? Colors.white
                                      : AppColors.lightTextPrimary,
                                ),
                              ),
                              const SizedBox(height: 2),
                              Text(
                                '${_weatherData?.condition ?? "Partly cloudy"} · ${_weatherData?.city ?? (_userLocation?.city ?? "Kampala")}',
                                textAlign: TextAlign.center,
                                style: GoogleFonts.plusJakartaSans(
                                  fontSize: 11,
                                  color: isDark
                                      ? Colors.white54
                                      : AppColors.lightTextSecondary,
                                  fontWeight: FontWeight.w500,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 22),

                  // 3. Islamic Bento Grid: Qur'an, Zakat, Mosques (Edge-to-edge photography, glass tags)
                  _buildBentoGrid(isDark),

                  const SizedBox(height: 26),

                  // 4. "Featured" Section
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        'Featured',
                        style: GoogleFonts.plusJakartaSans(
                          fontSize: 19,
                          fontWeight: FontWeight.bold,
                          color: textPrimary,
                        ),
                      ),
                      TextButton(
                        onPressed: () {
                          if (widget.onNavigateTab != null) {
                            widget.onNavigateTab!(1);
                          } else {
                            Navigator.of(context).push(
                              MaterialPageRoute(
                                  builder: (_) => const QuranLibraryScreen()),
                            );
                          }
                        },
                        child: Text(
                          'View all',
                          style: GoogleFonts.plusJakartaSans(
                            fontSize: 13,
                            fontWeight: FontWeight.w600,
                            color: textSecondary,
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 10),

                  // 5. Featured Card: Rebranded to Daily Ayah (Clean, borderless, zero gradients)
                  GestureDetector(
                    onTap: () {
                      if (widget.onNavigateTab != null) {
                        widget.onNavigateTab!(2);
                      } else {
                        Navigator.of(context).push(
                          MaterialPageRoute(
                              builder: (_) => const DailyAyahScreen()),
                        );
                      }
                    },
                    child: Container(
                      padding: const EdgeInsets.all(20),
                      decoration: BoxDecoration(
                        color: isDark
                            ? AppColors.darkCard
                            : AppColors.lightSurfaceSubtle,
                        borderRadius: BorderRadius.circular(28),
                        boxShadow: [
                          BoxShadow(
                            color:
                                Colors.black.withOpacity(isDark ? 0.35 : 0.05),
                            blurRadius: 20,
                            offset: const Offset(0, 6),
                          ),
                        ],
                      ),
                      child: Row(
                        children: [
                          // Left Text Column
                          Expanded(
                            flex: 13,
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Container(
                                  padding: const EdgeInsets.symmetric(
                                      horizontal: 10, vertical: 4),
                                  decoration: BoxDecoration(
                                    color: isDark
                                        ? AppColors.darkInnerCard
                                        : AppColors.accentGold
                                            .withOpacity(0.22),
                                    borderRadius: BorderRadius.circular(12),
                                  ),
                                  child: Text(
                                    'DAILY AYAH',
                                    style: GoogleFonts.plusJakartaSans(
                                      fontSize: 10,
                                      fontWeight: FontWeight.w800,
                                      letterSpacing: 1.0,
                                      color: isDark
                                          ? AppColors.quranGold
                                          : const Color(0xFF9E7728),
                                    ),
                                  ),
                                ),
                                const SizedBox(height: 8),
                                Text(
                                  'Daily Ayah',
                                  style: GoogleFonts.plusJakartaSans(
                                    fontSize: 22,
                                    fontWeight: FontWeight.w800,
                                    color: textPrimary,
                                    height: 1.15,
                                  ),
                                ),
                                const SizedBox(height: 4),
                                Text(
                                  'Food of the Soul · Make your day',
                                  style: GoogleFonts.plusJakartaSans(
                                    fontSize: 12,
                                    fontWeight: FontWeight.w600,
                                    color: AppColors.accentGoldDark,
                                  ),
                                ),
                                const SizedBox(height: 10),
                                Text(
                                  '“${dailyAyah.defaultTranslation}”',
                                  maxLines: 2,
                                  overflow: TextOverflow.ellipsis,
                                  style: GoogleFonts.plusJakartaSans(
                                    fontSize: 12.5,
                                    fontStyle: FontStyle.italic,
                                    color: textPrimary.withOpacity(0.85),
                                    height: 1.35,
                                  ),
                                ),
                                const SizedBox(height: 10),
                                Row(
                                  children: [
                                    Text(
                                      dailyAyah.reference,
                                      style: GoogleFonts.plusJakartaSans(
                                        fontSize: 11,
                                        fontWeight: FontWeight.bold,
                                        color: textSecondary,
                                      ),
                                    ),
                                    const SizedBox(width: 6),
                                    const Icon(
                                      Icons.arrow_forward_rounded,
                                      size: 13,
                                      color: AppColors.accentGoldDark,
                                    ),
                                  ],
                                ),
                              ],
                            ),
                          ),
                          const SizedBox(width: 14),

                          // Right: Thematic Visual Thumbnail with Play Badge
                          Expanded(
                            flex: 8,
                            child: ClipRRect(
                              borderRadius: BorderRadius.circular(20),
                              child: Stack(
                                alignment: Alignment.center,
                                children: [
                                  Image.asset(
                                    dailyAyah.imageAsset,
                                    height: 116,
                                    width: double.infinity,
                                    fit: BoxFit.cover,
                                  ),
                                  Container(
                                    height: 116,
                                    decoration: BoxDecoration(
                                      gradient: LinearGradient(
                                        begin: Alignment.topCenter,
                                        end: Alignment.bottomCenter,
                                        colors: [
                                          Colors.transparent,
                                          Colors.black.withOpacity(0.40),
                                        ],
                                      ),
                                    ),
                                  ),
                                  Container(
                                    width: 38,
                                    height: 38,
                                    decoration: BoxDecoration(
                                      shape: BoxShape.circle,
                                      color: Colors.black.withOpacity(0.45),
                                      border: Border.all(
                                        color: Colors.white.withOpacity(0.35),
                                        width: 1.0,
                                      ),
                                    ),
                                    child: const Icon(
                                      Icons.play_arrow_rounded,
                                      color: Colors.white,
                                      size: 24,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: 16),
                  _buildContinueReadingCard(isDark, textPrimary, textSecondary),
                  SizedBox(height: widget.isEmbeddedInShell ? 120 : 36),
                ],
              ),
            ),
          ),

          // 3. Floating Deep Emerald Capsule Top Bar matching reference
          Positioned(
            top: topPadding + 10,
            left: 18,
            right: 18,
            child: _buildHeaderRow(isDark),
          ),

          // 4. Backgroundless Golden Frequency Waves (Seen between top app bar & prayer card when reciting)
          Positioned(
            top: topPadding + 84,
            left: 0,
            right: 0,
            child: ValueListenableBuilder<bool>(
              valueListenable: _audioService.isPlayingNotifier,
              builder: (context, isPlaying, _) {
                if (!isPlaying) return const SizedBox.shrink();
                return Center(
                  child: _FloatingGoldenFrequencyBars(
                    onTap: () {
                      final surahNum = _audioService.currentPlayingSurah.value;
                      if (surahNum != null) {
                        final surahMeta = kAllSurahs.firstWhere(
                          (s) => s.number == surahNum,
                          orElse: () => kAllSurahs.first,
                        );
                        Navigator.of(context).push(
                          MaterialPageRoute(
                            builder: (_) => ReaderScreen(
                              surah: surahMeta,
                              initialAyah:
                                  _audioService.currentPlayingAyah.value ?? 1,
                            ),
                          ),
                        );
                      }
                    },
                  ),
                );
              },
            ),
          ),
        ],
      ),

      // Custom Floating Bottom Navigation Bar matching reference (omitted if embedded in shell)
      bottomNavigationBar: widget.isEmbeddedInShell
          ? null
          : FloatingNavDock(
              currentIndex: _selectedNavIndex,
              onTabSelected: (index) {
                setState(() => _selectedNavIndex = index);
                if (index == 1) {
                  Navigator.of(context).push(
                    MaterialPageRoute(
                        builder: (_) => const QuranLibraryScreen()),
                  );
                } else if (index == 2) {
                  Navigator.of(context).push(
                    MaterialPageRoute(
                        builder: (_) => const DailyAyahScreen()),
                  );
                } else if (index == 3) {
                  Navigator.of(context).push(
                    MaterialPageRoute(
                        builder: (_) => const PrayersScreen()),
                  );
                }
              },
            ),
    );
  }

  Widget _buildContinueReadingCard(
      bool isDark, Color textPrimary, Color textSecondary) {
    final surahNum = (_lastReadData?['surah'] as num?)?.toInt() ?? 2;
    final ayahNum = (_lastReadData?['ayah'] as num?)?.toInt() ?? 187;

    final surahMeta = kAllSurahs.firstWhere(
      (s) => s.number == surahNum,
      orElse: () => kAllSurahs[1],
    );

    final totalAyahs =
        surahMeta.numberOfAyahs > 0 ? surahMeta.numberOfAyahs : 286;
    final percentage = ((ayahNum / totalAyahs) * 100).clamp(1, 100).round();
    final juzNum = _getJuzForAyah(surahNum, ayahNum);

    final cardBg = isDark ? const Color(0xFF13221C) : Colors.white;

    void openReader() {
      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (_) => ReaderScreen(
            surah: surahMeta,
            initialAyah: ayahNum,
          ),
        ),
      ).then((_) => _loadLastRead());
    }

    return Container(
      decoration: BoxDecoration(
        color: cardBg,
        borderRadius: BorderRadius.circular(24),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(isDark ? 0.35 : 0.05),
            blurRadius: 18,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: openReader,
          borderRadius: BorderRadius.circular(24),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                // 1. Circular Progress Ring (Left)
                SizedBox(
                  width: 58,
                  height: 58,
                  child: Stack(
                    alignment: Alignment.center,
                    children: [
                      SizedBox(
                        width: 54,
                        height: 54,
                        child: CircularProgressIndicator(
                          value: percentage / 100,
                          strokeWidth: 4.5,
                          backgroundColor: isDark
                              ? Colors.white.withOpacity(0.08)
                              : const Color(0xFFE4EDE7),
                          valueColor: const AlwaysStoppedAnimation<Color>(
                            Color(0xFF267A53),
                          ),
                          strokeCap: StrokeCap.round,
                        ),
                      ),
                      Text(
                        '$percentage%',
                        style: GoogleFonts.plusJakartaSans(
                          fontSize: 12.5,
                          fontWeight: FontWeight.w800,
                          color: textPrimary,
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 14),

                // 2. Center Text Column & Resume Button
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        'CONTINUE READING',
                        style: GoogleFonts.plusJakartaSans(
                          fontSize: 9.5,
                          fontWeight: FontWeight.w800,
                          letterSpacing: 0.8,
                          color: const Color(0xFFB8934A),
                        ),
                      ),
                      const SizedBox(height: 3),
                      Text(
                        'Surah ${surahMeta.englishName}',
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: GoogleFonts.plusJakartaSans(
                          fontSize: 15.5,
                          fontWeight: FontWeight.w700,
                          color: textPrimary,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        'Ayah $ayahNum • Juz $juzNum',
                        style: GoogleFonts.plusJakartaSans(
                          fontSize: 11.5,
                          fontWeight: FontWeight.w500,
                          color: textSecondary,
                        ),
                      ),
                      const SizedBox(height: 9),
                      // Resume Pill
                      GestureDetector(
                        onTap: openReader,
                        child: Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 13, vertical: 5.5),
                          decoration: BoxDecoration(
                            color: const Color(0xFF103C30),
                            borderRadius: BorderRadius.circular(20),
                            boxShadow: [
                              BoxShadow(
                                color: const Color(0xFF103C30).withOpacity(0.35),
                                blurRadius: 6,
                                offset: const Offset(0, 2),
                              ),
                            ],
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              const Icon(
                                Icons.auto_stories_rounded,
                                size: 13,
                                color: Color(0xFFF5CE63),
                              ),
                              const SizedBox(width: 5),
                              Text(
                                'Resume',
                                style: GoogleFonts.plusJakartaSans(
                                  fontSize: 11.5,
                                  fontWeight: FontWeight.w700,
                                  color: Colors.white,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 8),

                // 3. Right Side: 3-dots popup menu & Rihal graphic
                Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    Align(
                      alignment: Alignment.topRight,
                      child: PopupMenuButton<String>(
                        padding: EdgeInsets.zero,
                        constraints: const BoxConstraints(),
                        icon: Icon(
                          Icons.more_horiz_rounded,
                          color: textSecondary.withOpacity(0.6),
                          size: 20,
                        ),
                        itemBuilder: (ctx) => [
                          PopupMenuItem(
                            value: 'reset',
                            child: Row(
                              children: [
                                const Icon(Icons.refresh_rounded, size: 18),
                                const SizedBox(width: 8),
                                Text(
                                  'Reset to Al-Fatihah',
                                  style: GoogleFonts.plusJakartaSans(
                                      fontSize: 13),
                                ),
                              ],
                            ),
                          ),
                        ],
                        onSelected: (val) async {
                          if (val == 'reset') {
                            await _storageService.saveLastRead(
                              surahNumber: 1,
                              surahName: 'Al-Fatiha',
                              ayahNumber: 1,
                            );
                            _loadLastRead();
                          }
                        },
                      ),
                    ),
                    const SizedBox(height: 2),
                    Image.asset(
                      'assets/images/rihal.png',
                      width: 72,
                      height: 62,
                      fit: BoxFit.contain,
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildHeaderRow(bool isDark) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(32),
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 20, sigmaY: 20),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
          decoration: BoxDecoration(
            color: const Color(0xFF0E3323).withOpacity(0.92),
            borderRadius: BorderRadius.circular(32),
            border: Border.all(
              color: Colors.white.withOpacity(0.12),
              width: 1.0,
            ),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.20),
                blurRadius: 18,
                offset: const Offset(0, 5),
              ),
            ],
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              Expanded(
                child: Row(
                  children: [
                    // Aminah Avatar from reference
                    ClipOval(
                      child: Image.asset(
                        'assets/aminah.png',
                        width: 44,
                        height: 44,
                        fit: BoxFit.cover,
                      ),
                    ),
                    const SizedBox(width: 10),

                    // Greeting "Assalamu alaikum," & "Aminah" ✎
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Text(
                            "Assalamu alaikum,",
                            style: GoogleFonts.plusJakartaSans(
                              fontSize: 12,
                              color: const Color(0xFFC5D6C5),
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                          const SizedBox(height: 1),
                          Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Flexible(
                                child: Text(
                                  "Aminah",
                                  overflow: TextOverflow.ellipsis,
                                  style: GoogleFonts.plusJakartaSans(
                                    fontSize: 18,
                                    fontWeight: FontWeight.bold,
                                    color: const Color(0xFFEAB34D),
                                  ),
                                ),
                              ),
                              const SizedBox(width: 5),
                              const Icon(
                                Icons.edit_outlined,
                                size: 14,
                                color: Color(0xFFEAB34D),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 8),

              // Actions: Notification Bell + Theme Toggle Button
              Row(
                children: [
                  Container(
                    width: 40,
                    height: 40,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: Colors.white.withOpacity(0.10),
                    ),
                    alignment: Alignment.center,
                    child: const Icon(
                      Icons.notifications_none_rounded,
                      color: Color(0xFFEAB34D),
                      size: 20,
                    ),
                  ),
                  const SizedBox(width: 8),
                  GestureDetector(
                    onTap: () => _themeService.toggleTheme(),
                    child: Container(
                      width: 40,
                      height: 40,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: Colors.white.withOpacity(0.10),
                      ),
                      alignment: Alignment.center,
                      child: Icon(
                        isDark
                            ? Icons.light_mode_rounded
                            : Icons.dark_mode_outlined,
                        color: const Color(0xFFEAB34D),
                        size: 20,
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildBentoGrid(bool isDark) {
    return Row(
      children: [
        _buildBentoCard(
          label: "Qur'an",
          imagePath: 'assets/bento_quran.jpg',
          icon: Icons.menu_book_rounded,
          isDark: isDark,
          onTap: () {
            if (widget.onNavigateTab != null) {
              widget.onNavigateTab!(1);
            } else {
              Navigator.of(context).push(
                MaterialPageRoute(builder: (_) => const QuranLibraryScreen()),
              );
            }
          },
        ),
        const SizedBox(width: 12),
        _buildBentoCard(
          label: "Zakat",
          imagePath: 'assets/bento_zakat.jpg',
          icon: Icons.all_inclusive_rounded,
          isDark: isDark,
          onTap: () {
            Navigator.of(context).push(
              MaterialPageRoute(builder: (_) => const ZakatScreen()),
            );
          },
        ),
        const SizedBox(width: 12),
        _buildBentoCard(
          label: "Reels",
          imagePath: 'assets/bento_zakat.jpg',
          icon: Icons.play_circle_filled_rounded,
          badgeText: "New",
          isDark: isDark,
          onTap: () {
            Navigator.of(context).push(
              MaterialPageRoute(builder: (_) => const IslamicReelsScreen()),
            );
          },
        ),
      ],
    );
  }

  Widget _buildBentoCard({
    required String label,
    required String imagePath,
    required IconData icon,
    String? badgeText,
    required bool isDark,
    required VoidCallback onTap,
  }) {
    return Expanded(
      child: GestureDetector(
        onTap: onTap,
        child: Container(
          height: 148,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(26),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(isDark ? 0.38 : 0.12),
                blurRadius: 16,
                offset: const Offset(0, 6),
              ),
            ],
          ),
          child: ClipRRect(
            borderRadius: BorderRadius.circular(26),
            child: Stack(
              fit: StackFit.expand,
              children: [
                // 1. Full cover image without outline
                Image.asset(
                  imagePath,
                  fit: BoxFit.cover,
                  filterQuality: FilterQuality.high,
                  errorBuilder: (context, error, stackTrace) {
                    return Container(
                      color: isDark
                          ? AppColors.darkCard
                          : const Color(0xFFF0EBE2),
                      child: Icon(icon, color: AppColors.quranGold, size: 36),
                    );
                  },
                ),

                // 2. Glassmorphic gradient overlay for contrast and depth
                Container(
                  decoration: const BoxDecoration(
                    gradient: LinearGradient(
                      begin: Alignment.topCenter,
                      end: Alignment.bottomCenter,
                      colors: [
                        Colors.transparent,
                        Color(0x22000000),
                        Color(0xB80A1F16),
                      ],
                      stops: [0.35, 0.65, 1.0],
                    ),
                  ),
                ),

                // 3. Frosted Glass Label Tag at bottom
                Positioned(
                  left: 8,
                  right: 8,
                  bottom: 8,
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(16),
                    child: BackdropFilter(
                      filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 8, vertical: 6),
                        decoration: BoxDecoration(
                          color: Colors.black.withOpacity(0.38),
                          borderRadius: BorderRadius.circular(16),
                          border: Border.all(
                            color: Colors.white.withOpacity(0.18),
                            width: 0.8,
                          ),
                        ),
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Text(
                              label,
                              textAlign: TextAlign.center,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: GoogleFonts.plusJakartaSans(
                                fontSize: 13,
                                fontWeight: FontWeight.bold,
                                color: Colors.white,
                                shadows: const [
                                  Shadow(
                                    color: Colors.black54,
                                    blurRadius: 4,
                                    offset: Offset(0, 1),
                                  ),
                                ],
                              ),
                            ),
                            if (badgeText != null) ...[
                              const SizedBox(height: 1),
                              Text(
                                badgeText,
                                style: GoogleFonts.plusJakartaSans(
                                  fontSize: 10,
                                  fontWeight: FontWeight.w600,
                                  color: AppColors.quranGold,
                                ),
                              ),
                            ],
                          ],
                        ),
                      ),
                    ),
                  ),
                ),

                // 4. Floating subtle Islamic icon bubble at top right
                Positioned(
                  top: 8,
                  right: 8,
                  child: Container(
                    width: 26,
                    height: 26,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: Colors.black.withOpacity(0.32),
                      border: Border.all(
                        color: Colors.white.withOpacity(0.16),
                        width: 0.6,
                      ),
                    ),
                    alignment: Alignment.center,
                    child: Icon(icon, color: AppColors.quranGold, size: 14),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildSunCloudIllustration() {
    final assetPath = _weatherData?.weatherAssetPath ?? 'assets/weather/sun.png';

    return AnimatedSwitcher(
      duration: const Duration(milliseconds: 600),
      transitionBuilder: (child, animation) =>
          FadeTransition(opacity: animation, child: child),
      child: Image.asset(
        assetPath,
        key: ValueKey<String>(assetPath),
        width: 76,
        height: 76,
        fit: BoxFit.contain,
        errorBuilder: (context, error, stackTrace) => Image.asset(
          'assets/sun asset.png',
          width: 76,
          height: 76,
          fit: BoxFit.contain,
          errorBuilder: (_, __, ___) => const SizedBox(
            width: 76,
            height: 76,
            child: Icon(Icons.wb_sunny_rounded,
                color: Color(0xFFFBBF24), size: 42),
          ),
        ),
      ),
    );
  }
}

class _FloatingGoldenFrequencyBars extends StatefulWidget {
  final VoidCallback? onTap;
  const _FloatingGoldenFrequencyBars({this.onTap});

  @override
  State<_FloatingGoldenFrequencyBars> createState() =>
      _FloatingGoldenFrequencyBarsState();
}

class _FloatingGoldenFrequencyBarsState
    extends State<_FloatingGoldenFrequencyBars>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1100),
    )..repeat(reverse: true);
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: widget.onTap,
      behavior: HitTestBehavior.opaque,
      child: AnimatedBuilder(
        animation: _controller,
        builder: (context, _) {
          return CustomPaint(
            size: const Size(190, 24),
            painter: _GoldenWavePainter(progress: _controller.value),
          );
        },
      ),
    );
  }
}

class _GoldenWavePainter extends CustomPainter {
  final double progress;
  _GoldenWavePainter({required this.progress});

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = const Color(0xFFF5CE63)
      ..strokeCap = StrokeCap.round
      ..style = PaintingStyle.fill;

    const count = 30;
    final spacing = size.width / count;
    final mid = size.height / 2;

    for (int i = 0; i < count; i++) {
      final t = (i / count);
      final wave1 =
          math.sin((t * 4 * math.pi) + (progress * 2 * math.pi)).abs();
      final wave2 =
          math.cos((t * 2 * math.pi) - (progress * math.pi)).abs();
      final barHeight =
          (4.0 + (wave1 * 0.6 + wave2 * 0.4) * (size.height - 4))
              .clamp(3.0, size.height);

      final x = i * spacing + spacing / 2;
      final yTop = mid - barHeight / 2;
      final yBottom = mid + barHeight / 2;

      final rrect = RRect.fromRectAndRadius(
        Rect.fromLTRB(x - 1.5, yTop, x + 1.5, yBottom),
        const Radius.circular(2),
      );
      canvas.drawRRect(rrect, paint);
    }
  }

  @override
  bool shouldRepaint(covariant _GoldenWavePainter oldDelegate) =>
      oldDelegate.progress != progress;
}


