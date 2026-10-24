import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
import '../constants/app_colors.dart';
import '../services/prayer_time_service.dart';
import 'mosque_finder_screen.dart';

class PrayerRowData {
  final String name;
  final String arabicName;
  final String time;
  final String imageAsset;
  final bool isNext;
  final bool isPast;

  const PrayerRowData({
    required this.name,
    required this.arabicName,
    required this.time,
    required this.imageAsset,
    required this.isNext,
    required this.isPast,
  });
}

class PrayersScreen extends StatefulWidget {
  const PrayersScreen({super.key});

  @override
  State<PrayersScreen> createState() => _PrayersScreenState();
}

class _PrayersScreenState extends State<PrayersScreen> {
  final PrayerTimeService _prayerService = PrayerTimeService();
  PrayerSchedule? _schedule;
  UpcomingPrayer? _upcomingPrayer;
  Timer? _ticker;
  DateTime _now = DateTime.now();

  @override
  void initState() {
    super.initState();
    _loadSchedule();
    _ticker = Timer.periodic(const Duration(seconds: 1), (_) {
      if (mounted) {
        setState(() {
          _now = DateTime.now();
          if (_schedule != null) {
            _upcomingPrayer = _prayerService.getUpcomingPrayer(_schedule!, _now);
          }
        });
      }
    });
  }

  Future<void> _loadSchedule() async {
    final sched = await _prayerService.fetchPrayerTimes();
    if (mounted) {
      setState(() {
        _schedule = sched;
        _upcomingPrayer = _prayerService.getUpcomingPrayer(sched, DateTime.now());
      });
    }
  }

  @override
  void dispose() {
    _ticker?.cancel();
    super.dispose();
  }

  String _formatCountdown(Duration d) {
    if (d.isNegative) return '00:00:00';
    final hours = d.inHours.toString().padLeft(2, '0');
    final minutes = (d.inMinutes % 60).toString().padLeft(2, '0');
    final seconds = (d.inSeconds % 60).toString().padLeft(2, '0');
    return '$hours:$minutes:$seconds';
  }

  DateTime _parseToday(String time24) {
    try {
      final parts = time24.split(':');
      final hour = int.parse(parts[0]);
      final minute = int.parse(parts[1]);
      return DateTime(_now.year, _now.month, _now.day, hour, minute);
    } catch (_) {
      return DateTime(_now.year, _now.month, _now.day, 12, 0);
    }
  }

  String _format12Hour(String time24) {
    try {
      final parts = time24.split(':');
      var hour = int.parse(parts[0]);
      final minute = parts[1].padLeft(2, '0');
      final period = hour >= 12 ? 'PM' : 'AM';
      if (hour > 12) hour -= 12;
      if (hour == 0) hour = 12;
      return '$hour:$minute $period';
    } catch (_) {
      return time24;
    }
  }

  List<PrayerRowData> _getPrayerRows() {
    final sched = _schedule ?? PrayerSchedule.fallbackDefault();
    final list = [
      {
        'name': 'Fajr',
        'arabic': 'الفجر',
        'time': sched.fajr,
        'image': 'assets/prayers/fajr.jpg',
      },
      {
        'name': 'Sunrise',
        'arabic': 'الشروق',
        'time': sched.sunrise,
        'image': 'assets/prayers/sunrise.jpg',
      },
      {
        'name': 'Dhuhr',
        'arabic': 'الظهر',
        'time': sched.dhuhr,
        'image': 'assets/prayers/dhuhr.jpg',
      },
      {
        'name': 'Asr',
        'arabic': 'العصر',
        'time': sched.asr,
        'image': 'assets/prayers/asr.jpg',
      },
      {
        'name': 'Maghrib',
        'arabic': 'المغرب',
        'time': sched.maghrib,
        'image': 'assets/prayers/maghrib.jpg',
      },
      {
        'name': 'Isha',
        'arabic': 'العشاء',
        'time': sched.isha,
        'image': 'assets/prayers/isha.jpg',
      },
    ];

    return list.map((item) {
      final name = item['name']!;
      final arabic = item['arabic']!;
      final timeStr = item['time']!;
      final image = item['image']!;
      final isNext = _upcomingPrayer != null &&
          _upcomingPrayer!.name.toUpperCase() == name.toUpperCase();
      final dt = _parseToday(timeStr);
      final isPast = _now.isAfter(dt) && !isNext;
      return PrayerRowData(
        name: name,
        arabicName: arabic,
        time: _format12Hour(timeStr),
        imageAsset: image,
        isNext: isNext,
        isPast: isPast,
      );
    }).toList();
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final bg = isDark ? AppColors.darkBackground : AppColors.lightBackground;
    final textPrimary = isDark ? Colors.white : AppColors.lightTextPrimary;
    final textSecondary = isDark ? Colors.white60 : AppColors.lightTextSecondary;

    final countdown = _upcomingPrayer != null
        ? _formatCountdown(_upcomingPrayer!.remaining)
        : '--:--:--';

    return Scaffold(
      backgroundColor: bg,
      body: CustomScrollView(
        physics: const BouncingScrollPhysics(),
        slivers: [
          // 1. Signature Emerald Solid Curved Mufta Header (No Frost, crisp solid depth)
          SliverToBoxAdapter(
            child: _buildMuftaHeader(isDark, _upcomingPrayer, countdown),
          ),

          // 2. Mosque Finder Action Banner
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(18, 16, 18, 6),
              child: _buildMosqueFinderBanner(isDark),
            ),
          ),

          // 3. Today's Prayer Schedule Timetable (Solid high-contrast cards, authentic artwork, no frost)
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(18, 14, 18, 120), // Bottom clearance for dock
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        'TODAY\'S PRAYERS',
                        style: GoogleFonts.plusJakartaSans(
                          fontSize: 12,
                          fontWeight: FontWeight.bold,
                          letterSpacing: 1.2,
                          color: AppColors.accentGold,
                        ),
                      ),
                      Text(
                        _schedule?.readableDate.isNotEmpty == true
                            ? _schedule!.readableDate
                            : 'Kampala, Uganda',
                        style: GoogleFonts.plusJakartaSans(
                          fontSize: 12,
                          color: textSecondary,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  _buildPrayerScheduleCard(isDark, textPrimary, textSecondary),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMuftaHeader(
    bool isDark,
    UpcomingPrayer? upcoming,
    String countdown,
  ) {
    final topPadding = MediaQuery.of(context).padding.top;

    return Container(
      decoration: const BoxDecoration(
        color: Color(0xFF0D2F1F),
        borderRadius: BorderRadius.vertical(bottom: Radius.circular(36)),
        boxShadow: [
          BoxShadow(
            color: Colors.black38,
            blurRadius: 18,
            offset: Offset(0, 8),
          ),
        ],
      ),
      clipBehavior: Clip.antiAlias,
      child: Stack(
        children: [
          // Background Mufta Arch
          Positioned.fill(
            child: Image.asset(
              'assets/new_mufta.jpg',
              fit: BoxFit.cover,
              alignment: Alignment.topCenter,
            ),
          ),

          // Solid Emerald Gradient Overlay (Zero frost blur)
          Positioned.fill(
            child: Container(
              decoration: const BoxDecoration(
                gradient: LinearGradient(
                  colors: [
                    Color(0xDF0D2F1F),
                    Color(0xF0103A26),
                  ],
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                ),
              ),
            ),
          ),

          // Header Content
          Padding(
            padding: EdgeInsets.fromLTRB(20, topPadding + 14, 20, 26),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'DAILY DEVOTION',
                          style: GoogleFonts.plusJakartaSans(
                            fontSize: 11,
                            fontWeight: FontWeight.bold,
                            letterSpacing: 1.5,
                            color: AppColors.accentGold,
                          ),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          'Prayer Times',
                          style: GoogleFonts.plusJakartaSans(
                            fontSize: 24,
                            fontWeight: FontWeight.bold,
                            color: Colors.white,
                          ),
                        ),
                      ],
                    ),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 7),
                      decoration: BoxDecoration(
                        color: const Color(0xFF163E2B),
                        borderRadius: BorderRadius.circular(20),
                        border: Border.all(color: AppColors.accentGold.withOpacity(0.5), width: 1),
                      ),
                      child: Row(
                        children: [
                          const Icon(Icons.schedule_rounded, color: AppColors.accentGold, size: 14),
                          const SizedBox(width: 6),
                          Text(
                            _formatClockTime(_now),
                            style: GoogleFonts.plusJakartaSans(
                              fontSize: 12.5,
                              fontWeight: FontWeight.bold,
                              color: Colors.white,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 20),

                // Next Prayer Solid Highlight Card
                Container(
                  padding: const EdgeInsets.all(18),
                  decoration: BoxDecoration(
                    color: const Color(0xFF143827),
                    borderRadius: BorderRadius.circular(24),
                    border: Border.all(color: AppColors.accentGold.withOpacity(0.4), width: 1.2),
                    boxShadow: const [
                      BoxShadow(
                        color: Colors.black38,
                        blurRadius: 14,
                        offset: Offset(0, 4),
                      ),
                    ],
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'UPCOMING PRAYER',
                            style: GoogleFonts.plusJakartaSans(
                              fontSize: 10.5,
                              fontWeight: FontWeight.w600,
                              letterSpacing: 1.0,
                              color: AppColors.accentGold,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            upcoming?.name.toUpperCase() ?? 'DHUHR',
                            style: GoogleFonts.plusJakartaSans(
                              fontSize: 24,
                              fontWeight: FontWeight.bold,
                              color: Colors.white,
                            ),
                          ),
                          const SizedBox(height: 2),
                          Text(
                            'at ${upcoming?.timeFormatted ?? "12:16 PM"}',
                            style: GoogleFonts.plusJakartaSans(
                              fontSize: 12,
                              color: Colors.white70,
                            ),
                          ),
                        ],
                      ),
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.end,
                        children: [
                          Text(
                            'COUNTDOWN',
                            style: GoogleFonts.plusJakartaSans(
                              fontSize: 10,
                              fontWeight: FontWeight.w600,
                              color: Colors.white60,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                            decoration: BoxDecoration(
                              color: AppColors.accentGold,
                              borderRadius: BorderRadius.circular(16),
                            ),
                            child: Text(
                              countdown,
                              style: GoogleFonts.plusJakartaSans(
                                fontSize: 16,
                                fontWeight: FontWeight.bold,
                                color: const Color(0xFF132B1F),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMosqueFinderBanner(bool isDark) {
    return GestureDetector(
      onTap: () {
        HapticFeedback.lightImpact();
        Navigator.of(context).push(
          MaterialPageRoute(builder: (_) => const MosqueFinderScreen()),
        );
      },
      child: Container(
        height: 96,
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(24),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(isDark ? 0.45 : 0.12),
              blurRadius: 16,
              offset: const Offset(0, 5),
            ),
          ],
        ),
        clipBehavior: Clip.antiAlias,
        child: Stack(
          children: [
            Image.asset(
              'assets/mosque_finder_hero.jpg',
              width: double.infinity,
              height: double.infinity,
              fit: BoxFit.cover,
            ),
            Container(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.centerLeft,
                  end: Alignment.centerRight,
                  colors: [
                    const Color(0xF00D281C),
                    const Color(0xD00D281C),
                    Colors.black.withOpacity(0.35),
                  ],
                ),
              ),
            ),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 18),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          const Icon(Icons.location_on_rounded, color: AppColors.accentGold, size: 16),
                          const SizedBox(width: 4),
                          Text(
                            'MOSQUE FINDER',
                            style: GoogleFonts.plusJakartaSans(
                              fontSize: 10.5,
                              fontWeight: FontWeight.bold,
                              letterSpacing: 1.2,
                              color: AppColors.accentGold,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 3),
                      Text(
                        'Find Nearby Mosques',
                        style: GoogleFonts.plusJakartaSans(
                          fontSize: 17,
                          fontWeight: FontWeight.bold,
                          color: Colors.white,
                        ),
                      ),
                      Text(
                        'Map navigation, Jamaat times & directions',
                        style: GoogleFonts.plusJakartaSans(
                          fontSize: 11,
                          color: Colors.white70,
                        ),
                      ),
                    ],
                  ),
                  Container(
                    width: 38,
                    height: 38,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: AppColors.accentGold,
                      boxShadow: [
                        BoxShadow(
                          color: AppColors.accentGold.withOpacity(0.4),
                          blurRadius: 10,
                          offset: const Offset(0, 3),
                        ),
                      ],
                    ),
                    child: const Icon(
                      Icons.arrow_forward_rounded,
                      color: Color(0xFF132B1F),
                      size: 20,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildPrayerScheduleCard(
    bool isDark,
    Color textPrimary,
    Color textSecondary,
  ) {
    final prayers = _getPrayerRows();

    return Container(
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF13281E) : Colors.white,
        borderRadius: BorderRadius.circular(26),
        border: Border.all(
          color: isDark ? Colors.white.withOpacity(0.09) : AppColors.lightBorder,
          width: 1.2,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(isDark ? 0.40 : 0.08),
            blurRadius: 18,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      child: Column(
        children: List.generate(prayers.length, (i) {
          final p = prayers[i];
          final isNext = p.isNext;
          final isPast = p.isPast;

          return Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            decoration: BoxDecoration(
              color: isNext
                  ? AppColors.accentGold.withOpacity(isDark ? 0.16 : 0.12)
                  : Colors.transparent,
              border: i < prayers.length - 1
                  ? Border(
                      bottom: BorderSide(
                        color: isDark ? Colors.white.withOpacity(0.06) : Colors.black.withOpacity(0.05),
                        width: 0.8,
                      ),
                    )
                  : null,
            ),
            child: Row(
              children: [
                // Authentic Prayer Artwork Thumbnail
                ClipRRect(
                  borderRadius: BorderRadius.circular(14),
                  child: Image.asset(
                    p.imageAsset,
                    width: 46,
                    height: 46,
                    fit: BoxFit.cover,
                  ),
                ),
                const SizedBox(width: 14),

                // Name & Arabic Name
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Text(
                            p.name,
                            style: GoogleFonts.plusJakartaSans(
                              fontSize: 15.5,
                              fontWeight: isNext ? FontWeight.bold : FontWeight.w600,
                              color: isNext
                                  ? (isDark ? AppColors.accentGold : const Color(0xFFB58428))
                                  : (isPast ? textSecondary.withOpacity(0.45) : textPrimary),
                            ),
                          ),
                          const SizedBox(width: 8),
                          Text(
                            p.arabicName,
                            style: GoogleFonts.amiri(
                              fontSize: 14,
                              color: isNext
                                  ? AppColors.accentGold
                                  : (isDark ? Colors.white54 : Colors.black45),
                            ),
                          ),
                        ],
                      ),
                      if (isNext && _upcomingPrayer != null)
                        Text(
                          'Next up in ${_formatCountdown(_upcomingPrayer!.remaining)}',
                          style: GoogleFonts.plusJakartaSans(
                            fontSize: 11,
                            color: isDark ? AppColors.accentGold : const Color(0xFFB58428),
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                    ],
                  ),
                ),

                // Prayer Time
                Container(
                  padding: isNext
                      ? const EdgeInsets.symmetric(horizontal: 10, vertical: 4)
                      : EdgeInsets.zero,
                  decoration: isNext
                      ? BoxDecoration(
                          color: AppColors.accentGold,
                          borderRadius: BorderRadius.circular(12),
                        )
                      : null,
                  child: Text(
                    p.time,
                    style: GoogleFonts.plusJakartaSans(
                      fontSize: 15,
                      fontWeight: isNext ? FontWeight.bold : FontWeight.w600,
                      color: isNext
                          ? const Color(0xFF132B1F)
                          : (isPast ? textSecondary.withOpacity(0.45) : textPrimary),
                    ),
                  ),
                ),
              ],
            ),
          );
        }),
      ),
    );
  }

  String _formatClockTime(DateTime time) {
    final h = time.hour > 12 ? time.hour - 12 : (time.hour == 0 ? 12 : time.hour);
    final m = time.minute.toString().padLeft(2, '0');
    final s = time.second.toString().padLeft(2, '0');
    final ampm = time.hour >= 12 ? 'PM' : 'AM';
    return '$h:$m:$s $ampm';
  }
}
