import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
import '../constants/app_colors.dart';
import '../services/prayer_time_service.dart';

class PrayerRowData {
  final String name;
  final String time;
  final bool isNext;
  final bool isPast;

  const PrayerRowData({
    required this.name,
    required this.time,
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

  // Tasbih state
  int _tasbihCount = 0;
  int _selectedDhikrIndex = 0;
  final List<String> _dhikrPhrases = [
    'سُبْحَانَ اللَّهِ (SubhanAllah)',
    'الْحَمْدُ لِلَّهِ (Alhamdulillah)',
    'اللَّهُ أَكْبَرُ (Allahu Akbar)',
    'أَسْتَغْفِرُ اللَّهَ (Astaghfirullah)',
    'لَا إِلَٰهَ إِلَّا اللَّهُ (La ilaha illallah)',
  ];

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

  void _incrementTasbih() {
    HapticFeedback.selectionClick();
    setState(() {
      _tasbihCount++;
    });
  }

  void _resetTasbih() {
    HapticFeedback.mediumImpact();
    setState(() {
      _tasbihCount = 0;
    });
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
      {'name': 'Fajr', 'time': sched.fajr},
      {'name': 'Sunrise', 'time': sched.sunrise},
      {'name': 'Dhuhr', 'time': sched.dhuhr},
      {'name': 'Asr', 'time': sched.asr},
      {'name': 'Maghrib', 'time': sched.maghrib},
      {'name': 'Isha', 'time': sched.isha},
    ];

    return list.map((item) {
      final name = item['name']!;
      final timeStr = item['time']!;
      final isNext = _upcomingPrayer != null &&
          _upcomingPrayer!.name.toUpperCase() == name.toUpperCase();
      final dt = _parseToday(timeStr);
      final isPast = _now.isAfter(dt) && !isNext;
      return PrayerRowData(
        name: name,
        time: _format12Hour(timeStr),
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
          // 1. Signature Emerald Curved Mufta Header
          SliverToBoxAdapter(
            child: _buildMuftaHeader(isDark, _upcomingPrayer, countdown),
          ),

          // 2. Prayer Schedule Timetable
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(18, 20, 18, 12),
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

          // 3. Digital Interactive Tasbih Counter
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(18, 14, 18, 120), // Bottom padding for floating dock
              child: _buildTasbihSection(isDark, textPrimary, textSecondary),
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
            color: Colors.black26,
            blurRadius: 18,
            offset: Offset(0, 8),
          ),
        ],
      ),
      clipBehavior: Clip.antiAlias,
      child: Stack(
        children: [
          // Background Mufta
          Positioned.fill(
            child: Image.asset(
              'assets/new_mufta.jpg',
              fit: BoxFit.cover,
              alignment: Alignment.topCenter,
            ),
          ),

          // Emerald overlay
          Positioned.fill(
            child: Container(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [
                    const Color(0xFF0D2F1F).withOpacity(0.85),
                    const Color(0xFF13422C).withOpacity(0.92),
                  ],
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                ),
              ),
            ),
          ),

          // Content
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
                          'PRAYERS & DHIKR',
                          style: GoogleFonts.plusJakartaSans(
                            fontSize: 11,
                            fontWeight: FontWeight.bold,
                            letterSpacing: 1.5,
                            color: AppColors.accentGold,
                          ),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          'Daily Devotion',
                          style: GoogleFonts.plusJakartaSans(
                            fontSize: 22,
                            fontWeight: FontWeight.bold,
                            color: Colors.white,
                          ),
                        ),
                      ],
                    ),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                      decoration: BoxDecoration(
                        color: Colors.white.withOpacity(0.12),
                        borderRadius: BorderRadius.circular(20),
                        border: Border.all(color: Colors.white24, width: 0.8),
                      ),
                      child: Row(
                        children: [
                          const Icon(Icons.schedule_rounded, color: AppColors.accentGold, size: 14),
                          const SizedBox(width: 6),
                          Text(
                            _formatClockTime(_now),
                            style: GoogleFonts.plusJakartaSans(
                              fontSize: 12,
                              fontWeight: FontWeight.bold,
                              color: Colors.white,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 22),

                // Next Prayer Highlight Banner
                Container(
                  padding: const EdgeInsets.all(18),
                  decoration: BoxDecoration(
                    color: Colors.white.withOpacity(0.12),
                    borderRadius: BorderRadius.circular(24),
                    border: Border.all(color: Colors.white.withOpacity(0.18), width: 1),
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
          color: isDark ? Colors.white.withOpacity(0.08) : AppColors.lightBorder,
          width: 1,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(isDark ? 0.35 : 0.06),
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
            padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 14),
            decoration: BoxDecoration(
              color: isNext
                  ? AppColors.accentGold.withOpacity(isDark ? 0.15 : 0.12)
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
                Container(
                  width: 38,
                  height: 38,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: isNext
                        ? AppColors.accentGold
                        : (isDark ? Colors.white.withOpacity(0.08) : Colors.black.withOpacity(0.04)),
                  ),
                  alignment: Alignment.center,
                  child: Icon(
                    _getPrayerIcon(p.name),
                    size: 18,
                    color: isNext
                        ? const Color(0xFF132B1F)
                        : (isPast ? textSecondary.withOpacity(0.5) : textPrimary),
                  ),
                ),
                const SizedBox(width: 14),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        p.name,
                        style: GoogleFonts.plusJakartaSans(
                          fontSize: 15,
                          fontWeight: isNext ? FontWeight.bold : FontWeight.w600,
                          color: isNext
                              ? (isDark ? AppColors.accentGold : const Color(0xFFB58428))
                              : (isPast ? textSecondary.withOpacity(0.5) : textPrimary),
                        ),
                      ),
                      if (isNext && _upcomingPrayer != null)
                        Text(
                          'Next up in ${_formatCountdown(_upcomingPrayer!.remaining)}',
                          style: GoogleFonts.plusJakartaSans(
                            fontSize: 11,
                            color: isDark ? AppColors.accentGold : const Color(0xFFB58428),
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                    ],
                  ),
                ),
                Text(
                  p.time,
                  style: GoogleFonts.plusJakartaSans(
                    fontSize: 15,
                    fontWeight: isNext ? FontWeight.bold : FontWeight.w600,
                    color: isNext
                        ? (isDark ? AppColors.accentGold : const Color(0xFFB58428))
                        : (isPast ? textSecondary.withOpacity(0.5) : textPrimary),
                  ),
                ),
              ],
            ),
          );
        }),
      ),
    );
  }

  Widget _buildTasbihSection(
    bool isDark,
    Color textPrimary,
    Color textSecondary,
  ) {
    return Container(
      padding: const EdgeInsets.all(22),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF13281E) : Colors.white,
        borderRadius: BorderRadius.circular(28),
        border: Border.all(
          color: isDark ? Colors.white.withOpacity(0.08) : AppColors.lightBorder,
          width: 1,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(isDark ? 0.35 : 0.06),
            blurRadius: 18,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      child: Column(
        children: [
          // Header
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(
                children: [
                  const Icon(Icons.fingerprint_rounded, color: AppColors.accentGold, size: 20),
                  const SizedBox(width: 8),
                  Text(
                    'DIGITAL TASBIH',
                    style: GoogleFonts.plusJakartaSans(
                      fontSize: 13,
                      fontWeight: FontWeight.bold,
                      letterSpacing: 1.2,
                      color: AppColors.accentGold,
                    ),
                  ),
                ],
              ),
              IconButton(
                icon: const Icon(Icons.refresh_rounded, size: 20),
                color: textSecondary,
                tooltip: 'Reset counter',
                onPressed: _resetTasbih,
              ),
            ],
          ),
          const SizedBox(height: 16),

          // Dhikr Selector Dropdown Capsule
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 4),
            decoration: BoxDecoration(
              color: isDark ? Colors.white.withOpacity(0.06) : Colors.black.withOpacity(0.04),
              borderRadius: BorderRadius.circular(16),
            ),
            child: DropdownButtonHideUnderline(
              child: DropdownButton<int>(
                value: _selectedDhikrIndex,
                isExpanded: true,
                dropdownColor: isDark ? const Color(0xFF1B382B) : Colors.white,
                icon: const Icon(Icons.keyboard_arrow_down_rounded, color: AppColors.accentGold),
                items: List.generate(_dhikrPhrases.length, (i) {
                  return DropdownMenuItem<int>(
                    value: i,
                    child: Text(
                      _dhikrPhrases[i],
                      style: GoogleFonts.plusJakartaSans(
                        fontSize: 13.5,
                        fontWeight: FontWeight.w600,
                        color: textPrimary,
                      ),
                    ),
                  );
                }),
                onChanged: (val) {
                  if (val != null) {
                    setState(() {
                      _selectedDhikrIndex = val;
                      _tasbihCount = 0;
                    });
                  }
                },
              ),
            ),
          ),
          const SizedBox(height: 24),

          // Large Interactive Counter Bead Button
          GestureDetector(
            onTap: _incrementTasbih,
            child: Container(
              width: 140,
              height: 140,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                gradient: const LinearGradient(
                  colors: [
                    AppColors.accentGold,
                    Color(0xFFCCA035),
                  ],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                boxShadow: [
                  BoxShadow(
                    color: AppColors.accentGold.withOpacity(0.40),
                    blurRadius: 28,
                    offset: const Offset(0, 10),
                  ),
                ],
                border: Border.all(
                  color: Colors.white.withOpacity(0.8),
                  width: 3,
                ),
              ),
              alignment: Alignment.center,
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(
                    '$_tasbihCount',
                    style: GoogleFonts.plusJakartaSans(
                      fontSize: 42,
                      fontWeight: FontWeight.bold,
                      color: const Color(0xFF132B1F),
                    ),
                  ),
                  Text(
                    'TAP TO COUNT',
                    style: GoogleFonts.plusJakartaSans(
                      fontSize: 9,
                      fontWeight: FontWeight.bold,
                      letterSpacing: 1.2,
                      color: const Color(0xFF132B1F).withOpacity(0.7),
                    ),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 16),
          Text(
            'Target: 33 / 100 repeats',
            style: GoogleFonts.plusJakartaSans(
              fontSize: 12,
              color: textSecondary,
            ),
          ),
        ],
      ),
    );
  }

  IconData _getPrayerIcon(String name) {
    switch (name.toLowerCase()) {
      case 'fajr':
        return Icons.wb_twilight_rounded;
      case 'sunrise':
        return Icons.wb_sunny_rounded;
      case 'dhuhr':
        return Icons.wb_sunny_outlined;
      case 'asr':
        return Icons.cloud_outlined;
      case 'maghrib':
        return Icons.nights_stay_outlined;
      case 'isha':
        return Icons.nights_stay_rounded;
      default:
        return Icons.access_time_rounded;
    }
  }

  String _formatClockTime(DateTime time) {
    final h = time.hour > 12 ? time.hour - 12 : (time.hour == 0 ? 12 : time.hour);
    final m = time.minute.toString().padLeft(2, '0');
    final s = time.second.toString().padLeft(2, '0');
    final ampm = time.hour >= 12 ? 'PM' : 'AM';
    return '$h:$m:$s $ampm';
  }
}
