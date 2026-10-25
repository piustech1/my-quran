import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
import '../services/prayer_time_service.dart';
import '../widgets/floating_nav_dock.dart';
import 'main_navigation_shell.dart';
import 'mosque_finder_screen.dart';

class PrayerDisplayItem {
  final String name;
  final String arabicName;
  final String time;
  final IconData icon;
  final bool isNext;
  final bool isPast;

  const PrayerDisplayItem({
    required this.name,
    required this.arabicName,
    required this.time,
    required this.icon,
    required this.isNext,
    required this.isPast,
  });
}

class PrayersScreen extends StatefulWidget {
  final bool isEmbeddedInShell;

  const PrayersScreen({
    super.key,
    this.isEmbeddedInShell = true,
  });

  @override
  State<PrayersScreen> createState() => _PrayersScreenState();
}

class _PrayersScreenState extends State<PrayersScreen> {
  final PrayerTimeService _prayerService = PrayerTimeService();
  PrayerSchedule? _schedule;
  UpcomingPrayer? _upcomingPrayer;
  Timer? _ticker;
  DateTime _now = DateTime.now();

  // Notification reminder toggles per prayer
  final Map<String, bool> _prayerReminders = {
    'Fajr': true,
    'Sunrise': false,
    'Dhuhr': true,
    'Asr': true,
    'Maghrib': true,
    'Isha': true,
  };

  @override
  void initState() {
    super.initState();
    _loadSchedule();
    _ticker = Timer.periodic(const Duration(seconds: 1), (_) {
      if (mounted) {
        setState(() {
          _now = DateTime.now();
          if (_schedule != null) {
            _upcomingPrayer =
                _prayerService.getUpcomingPrayer(_schedule!, _now);
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
        _upcomingPrayer =
            _prayerService.getUpcomingPrayer(sched, DateTime.now());
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

  String _formatClock24(DateTime time) {
    final h = time.hour.toString().padLeft(2, '0');
    final m = time.minute.toString().padLeft(2, '0');
    final s = time.second.toString().padLeft(2, '0');
    return '$h:$m:$s';
  }

  String _formatHeaderDate(DateTime date) {
    const months = [
      'Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun',
      'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'
    ];
    return '${date.day} ${months[date.month - 1]} ${date.year}';
  }

  List<PrayerDisplayItem> _getPrayerRows() {
    final sched = _schedule ?? PrayerSchedule.fallbackDefault();
    final list = [
      {
        'name': 'Fajr',
        'arabic': 'الفجر',
        'time': sched.fajr,
        'icon': Icons.nightlight_round,
      },
      {
        'name': 'Sunrise',
        'arabic': 'الشروق',
        'time': sched.sunrise,
        'icon': Icons.wb_twilight_rounded,
      },
      {
        'name': 'Dhuhr',
        'arabic': 'الظهر',
        'time': sched.dhuhr,
        'icon': Icons.wb_sunny_rounded,
      },
      {
        'name': 'Asr',
        'arabic': 'العصر',
        'time': sched.asr,
        'icon': Icons.wb_sunny_outlined,
      },
      {
        'name': 'Maghrib',
        'arabic': 'المغرب',
        'time': sched.maghrib,
        'icon': Icons.wb_twilight_rounded,
      },
      {
        'name': 'Isha',
        'arabic': 'العشاء',
        'time': sched.isha,
        'icon': Icons.nights_stay_rounded,
      },
    ];

    return list.map((item) {
      final name = item['name'] as String;
      final arabic = item['arabic'] as String;
      final timeStr = item['time'] as String;
      final icon = item['icon'] as IconData;

      final isNext = _upcomingPrayer != null &&
          _upcomingPrayer!.name.toUpperCase() == name.toUpperCase();
      final dt = _parseToday(timeStr);
      final isPast = _now.isAfter(dt) && !isNext;

      return PrayerDisplayItem(
        name: name,
        arabicName: arabic,
        time: _format12Hour(timeStr),
        icon: icon,
        isNext: isNext,
        isPast: isPast,
      );
    }).toList();
  }

  void _toggleReminder(String prayerName) {
    HapticFeedback.lightImpact();
    setState(() {
      final current = _prayerReminders[prayerName] ?? true;
      _prayerReminders[prayerName] = !current;
    });
    final active = _prayerReminders[prayerName] ?? true;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          active
              ? '$prayerName Adhan reminder activated'
              : '$prayerName Adhan reminder muted',
          style: GoogleFonts.plusJakartaSans(),
        ),
        behavior: SnackBarBehavior.floating,
        duration: const Duration(seconds: 2),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final bg = isDark ? const Color(0xFF0E1A14) : const Color(0xFFFBF8F2);

    final countdown = _upcomingPrayer != null
        ? _formatCountdown(_upcomingPrayer!.remaining)
        : '00:00:00';

    return Scaffold(
      backgroundColor: bg,
      body: Stack(
        children: [
          // Scrollable Prayer Content
          Positioned.fill(
            child: SingleChildScrollView(
              physics: const BouncingScrollPhysics(),
              padding: const EdgeInsets.only(bottom: 120),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  // 1. Pixel-Perfect Deep Green Arch Header Container
                  _buildHeaderArch(isDark, countdown),

                  // 2. Mosque Finder Hero Card
                  Padding(
                    padding: const EdgeInsets.fromLTRB(16, 16, 16, 6),
                    child: _buildMosqueFinderCard(isDark),
                  ),

                  // Helper caption text below card
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 18),
                    child: Text(
                      'Preview schedule • Kampala. Times are calculated with authentic Islamic coordinates.',
                      style: GoogleFonts.plusJakartaSans(
                        fontSize: 10.5,
                        color: isDark ? Colors.white54 : const Color(0xFF888279),
                      ),
                    ),
                  ),

                  const SizedBox(height: 18),

                  // 3. "Today's prayers" Schedule Section
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // Section Header: "Today's prayers" & "24 Oct 2026"
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text(
                              "Today's prayers",
                              style: GoogleFonts.plusJakartaSans(
                                fontSize: 16,
                                fontWeight: FontWeight.bold,
                                color: isDark ? Colors.white : const Color(0xFF1C1917),
                              ),
                            ),
                            Text(
                              _schedule?.readableDate.isNotEmpty == true
                                  ? _schedule!.readableDate
                                  : _formatHeaderDate(_now),
                              style: GoogleFonts.plusJakartaSans(
                                fontSize: 12,
                                fontWeight: FontWeight.w500,
                                color: isDark ? Colors.white60 : const Color(0xFF888279),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 12),

                        // Prayer List Cards
                        _buildPrayerList(isDark),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),

          // 4. Standalone Floating Nav Dock (only if not already embedded in MainNavigationShell)
          if (!widget.isEmbeddedInShell)
            Positioned(
              left: 0,
              right: 0,
              bottom: 0,
              child: FloatingNavDock(
                currentIndex: 3,
                onTabSelected: (idx) {
                  Navigator.of(context).pushReplacement(
                    MaterialPageRoute(
                      builder: (_) => MainNavigationShell(initialIndex: idx),
                    ),
                  );
                },
              ),
            ),
        ],
      ),
    );
  }

  /// 1. Top Header Arch Container (Curved bottom with Islamic Mufta Pattern)
  Widget _buildHeaderArch(bool isDark, String countdown) {
    final topPadding = MediaQuery.of(context).padding.top;

    return Container(
      decoration: const BoxDecoration(
        color: Color(0xFF0F3826),
        borderRadius: BorderRadius.vertical(bottom: Radius.circular(36)),
        boxShadow: [
          BoxShadow(
            color: Colors.black26,
            blurRadius: 16,
            offset: Offset(0, 6),
          ),
        ],
      ),
      clipBehavior: Clip.antiAlias,
      child: Stack(
        children: [
          // Background Mufta Pattern
          Positioned.fill(
            child: Image.asset(
              'assets/new_mufta.jpg',
              fit: BoxFit.cover,
              alignment: Alignment.topCenter,
            ),
          ),
          // Deep Emerald Gradient
          Positioned.fill(
            child: Container(
              decoration: const BoxDecoration(
                gradient: LinearGradient(
                  colors: [
                    Color(0xDF0F3826),
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
            padding: EdgeInsets.fromLTRB(16, topPadding + 10, 16, 22),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Top Row: [ < ] Back Button & [ 📍 Kampala, Uganda ] Pill
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    // Circular back button
                    GestureDetector(
                      onTap: () {
                        HapticFeedback.lightImpact();
                        if (Navigator.of(context).canPop()) {
                          Navigator.of(context).pop();
                        } else {
                          final shell = MainNavigationShell.of(context);
                          if (shell != null) {
                            shell.switchTab(0);
                          }
                        }
                      },
                      child: Container(
                        width: 38,
                        height: 38,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          color: Colors.white.withOpacity(0.14),
                        ),
                        child: const Icon(
                          Icons.arrow_back_rounded,
                          color: Colors.white,
                          size: 19,
                        ),
                      ),
                    ),

                    // Location Pill [ 📍 Kampala, Uganda ]
                    Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 14, vertical: 7),
                      decoration: BoxDecoration(
                        color: Colors.white.withOpacity(0.12),
                        borderRadius: BorderRadius.circular(20),
                        border: Border.all(
                          color: Colors.white.withOpacity(0.18),
                          width: 1,
                        ),
                      ),
                      child: Row(
                        children: [
                          const Icon(
                            Icons.location_on_outlined,
                            color: Color(0xFFC7DEC9),
                            size: 14,
                          ),
                          const SizedBox(width: 5),
                          Text(
                            'Kampala, Uganda',
                            style: GoogleFonts.plusJakartaSans(
                              fontSize: 12,
                              fontWeight: FontWeight.w600,
                              color: Colors.white,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),

                const SizedBox(height: 18),

                // DAILY DEVOTION title row with clock icon
                Text(
                  'DAILY DEVOTION',
                  style: GoogleFonts.plusJakartaSans(
                    fontSize: 11,
                    fontWeight: FontWeight.bold,
                    letterSpacing: 1.3,
                    color: const Color(0xFFCCA048),
                  ),
                ),
                const SizedBox(height: 3),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      'Prayer Times',
                      style: GoogleFonts.plusJakartaSans(
                        fontSize: 26,
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                      ),
                    ),
                    const Icon(
                      Icons.access_time_rounded,
                      color: Color(0xFFCCA048),
                      size: 24,
                    ),
                  ],
                ),

                const SizedBox(height: 18),

                // UPCOMING PRAYER Card
                _buildUpcomingPrayerCard(countdown),
              ],
            ),
          ),
        ],
      ),
    );
  }

  /// Elevated Upcoming Prayer Card inside the arch header
  Widget _buildUpcomingPrayerCard(String countdown) {
    final upcomingName = _upcomingPrayer?.name ?? 'Fajr';
    final upcomingTime = _upcomingPrayer != null
        ? _format12Hour(_upcomingPrayer!.timeFormatted)
        : '5:33 AM';
    final isTomorrow = _upcomingPrayer != null &&
        _upcomingPrayer!.prayerDateTime.day != _now.day;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 16),
      decoration: BoxDecoration(
        color: const Color(0xFF143B29).withOpacity(0.85),
        borderRadius: BorderRadius.circular(24),
        border: Border.all(
          color: Colors.white.withOpacity(0.12),
          width: 1,
        ),
        boxShadow: const [
          BoxShadow(
            color: Colors.black26,
            blurRadius: 10,
            offset: Offset(0, 4),
          ),
        ],
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          // Left: Upcoming prayer title, name, time
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'UPCOMING PRAYER',
                style: GoogleFonts.plusJakartaSans(
                  fontSize: 10,
                  fontWeight: FontWeight.w700,
                  letterSpacing: 1.1,
                  color: const Color(0xFFCCA048),
                ),
              ),
              const SizedBox(height: 4),
              Text(
                upcomingName,
                style: GoogleFonts.plusJakartaSans(
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                  color: Colors.white,
                ),
              ),
              const SizedBox(height: 2),
              Text(
                '${isTomorrow ? "Tomorrow" : "Today"} at $upcomingTime',
                style: GoogleFonts.plusJakartaSans(
                  fontSize: 12,
                  color: const Color(0xFFC7DEC9),
                ),
              ),
            ],
          ),

          // Right: Starts-in label, amber countdown pill, timezone
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text(
                'STARTS IN',
                style: GoogleFonts.plusJakartaSans(
                  fontSize: 9.5,
                  fontWeight: FontWeight.w600,
                  letterSpacing: 0.8,
                  color: Colors.white60,
                ),
              ),
              const SizedBox(height: 5),
              Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 16, vertical: 7),
                decoration: BoxDecoration(
                  color: const Color(0xFFE5A93C),
                  borderRadius: BorderRadius.circular(20),
                  boxShadow: [
                    BoxShadow(
                      color: const Color(0xFFE5A93C).withOpacity(0.35),
                      blurRadius: 8,
                      offset: const Offset(0, 2),
                    ),
                  ],
                ),
                child: Text(
                  countdown,
                  style: GoogleFonts.plusJakartaSans(
                    fontSize: 15.5,
                    fontWeight: FontWeight.bold,
                    color: const Color(0xFF122A1C),
                  ),
                ),
              ),
              const SizedBox(height: 5),
              Text(
                '${_formatClock24(_now)} EAT',
                style: GoogleFonts.plusJakartaSans(
                  fontSize: 10.5,
                  color: Colors.white60,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  /// 2. Mosque Finder Card: Photographic background with [ ↗ ] action button
  Widget _buildMosqueFinderCard(bool isDark) {
    return GestureDetector(
      onTap: () {
        HapticFeedback.lightImpact();
        Navigator.of(context).push(
          MaterialPageRoute(builder: (_) => const MosqueFinderScreen()),
        );
      },
      child: Container(
        height: 130,
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(26),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(isDark ? 0.4 : 0.1),
              blurRadius: 14,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        clipBehavior: Clip.antiAlias,
        child: Stack(
          children: [
            // Hero Image
            Positioned.fill(
              child: Image.asset(
                'assets/mosque_finder_hero.jpg',
                fit: BoxFit.cover,
              ),
            ),
            // Gradient Overlay
            Positioned.fill(
              child: Container(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                    colors: [
                      Colors.black.withOpacity(0.2),
                      Colors.black.withOpacity(0.7),
                    ],
                  ),
                ),
              ),
            ),
            // Content
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 14),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  // Top Row: [ 📍 MOSQUE FINDER ]
                  Row(
                    children: [
                      const Icon(
                        Icons.location_on_rounded,
                        size: 13,
                        color: Color(0xFFCCA048),
                      ),
                      const SizedBox(width: 4),
                      Text(
                        'MOSQUE FINDER',
                        style: GoogleFonts.plusJakartaSans(
                          fontSize: 10,
                          fontWeight: FontWeight.bold,
                          letterSpacing: 1.2,
                          color: const Color(0xFFCCA048),
                        ),
                      ),
                    ],
                  ),

                  // Bottom Row: Title, Subtitle & Circular [ ↗ ] button
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: [
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Find a place to pray',
                            style: GoogleFonts.plusJakartaSans(
                              fontSize: 17,
                              fontWeight: FontWeight.bold,
                              color: Colors.white,
                            ),
                          ),
                          const SizedBox(height: 2),
                          Text(
                            'Nearby mosques & directions',
                            style: GoogleFonts.plusJakartaSans(
                              fontSize: 12,
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
                          color: const Color(0xFF1B633D),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withOpacity(0.3),
                              blurRadius: 6,
                              offset: const Offset(0, 2),
                            ),
                          ],
                        ),
                        child: const Icon(
                          Icons.north_east_rounded,
                          color: Colors.white,
                          size: 19,
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
    );
  }

  /// 3. Prayer Timetable Schedule Cards (Active prayer in golden-cream card)
  Widget _buildPrayerList(bool isDark) {
    final prayers = _getPrayerRows();

    return Column(
      children: prayers.map((p) {
        final isNext = p.isNext;
        final isReminding = _prayerReminders[p.name] ?? true;

        if (isNext) {
          // Highlighted Golden-Cream Active Next Prayer Card
          return Container(
            margin: const EdgeInsets.only(bottom: 10),
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
            decoration: BoxDecoration(
              color: isDark ? const Color(0xFF233B2B) : const Color(0xFFFAF0D9),
              borderRadius: BorderRadius.circular(22),
              border: Border.all(
                color: const Color(0xFFCCA048).withOpacity(0.35),
                width: 1.2,
              ),
              boxShadow: [
                BoxShadow(
                  color: const Color(0xFFCCA048).withOpacity(isDark ? 0.15 : 0.1),
                  blurRadius: 10,
                  offset: const Offset(0, 3),
                ),
              ],
            ),
            child: Row(
              children: [
                // Amber circle with icon
                Container(
                  width: 42,
                  height: 42,
                  decoration: const BoxDecoration(
                    shape: BoxShape.circle,
                    color: Color(0xFFCCA048),
                  ),
                  child: Icon(
                    p.icon,
                    size: 20,
                    color: const Color(0xFF122A1C),
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
                              fontWeight: FontWeight.bold,
                              color: isDark ? Colors.white : const Color(0xFF18181B),
                            ),
                          ),
                          const SizedBox(width: 8),
                          Text(
                            p.arabicName,
                            style: GoogleFonts.amiri(
                              fontSize: 14.5,
                              fontWeight: FontWeight.bold,
                              color: isDark ? const Color(0xFFCCA048) : const Color(0xFF986F20),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 2),
                      Text(
                        'Next prayer',
                        style: GoogleFonts.plusJakartaSans(
                          fontSize: 11.5,
                          fontWeight: FontWeight.w600,
                          color: isDark ? const Color(0xFFCCA048) : const Color(0xFF986F20),
                        ),
                      ),
                    ],
                  ),
                ),

                // Time & Notification Bell
                Row(
                  children: [
                    Text(
                      p.time,
                      style: GoogleFonts.plusJakartaSans(
                        fontSize: 15,
                        fontWeight: FontWeight.bold,
                        color: isDark ? Colors.white : const Color(0xFF18181B),
                      ),
                    ),
                    const SizedBox(width: 10),
                    GestureDetector(
                      onTap: () => _toggleReminder(p.name),
                      child: Icon(
                        isReminding
                            ? Icons.notifications_active_rounded
                            : Icons.notifications_off_outlined,
                        size: 20,
                        color: isReminding
                            ? (isDark ? const Color(0xFFCCA048) : const Color(0xFF986F20))
                            : Colors.grey,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          );
        }

        // Clean White/Neutral Card for other prayers
        return Container(
          margin: const EdgeInsets.only(bottom: 8),
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          decoration: BoxDecoration(
            color: isDark ? const Color(0xFF152E20) : Colors.white,
            borderRadius: BorderRadius.circular(20),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(isDark ? 0.2 : 0.03),
                blurRadius: 6,
                offset: const Offset(0, 2),
              ),
            ],
          ),
          child: Row(
            children: [
              // Subtle circular icon badge
              Container(
                width: 38,
                height: 38,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: isDark
                      ? Colors.white.withOpacity(0.06)
                      : const Color(0xFFF2ECE1),
                ),
                child: Icon(
                  p.icon,
                  size: 18,
                  color: isDark ? Colors.white60 : const Color(0xFF6B665E),
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
                            fontSize: 14.5,
                            fontWeight: FontWeight.w600,
                            color: isDark ? Colors.white70 : const Color(0xFF292524),
                          ),
                        ),
                        const SizedBox(width: 8),
                        Text(
                          p.arabicName,
                          style: GoogleFonts.amiri(
                            fontSize: 13.5,
                            color: isDark ? Colors.white54 : Colors.black45,
                          ),
                        ),
                      ],
                    ),
                    Text(
                      p.isPast ? 'Completed' : 'Upcoming',
                      style: GoogleFonts.plusJakartaSans(
                        fontSize: 11,
                        color: isDark ? Colors.white38 : const Color(0xFFA19B91),
                      ),
                    ),
                  ],
                ),
              ),

              // Time & Notification Bell
              Row(
                children: [
                  Text(
                    p.time,
                    style: GoogleFonts.plusJakartaSans(
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                      color: isDark ? Colors.white70 : const Color(0xFF44403C),
                    ),
                  ),
                  const SizedBox(width: 10),
                  GestureDetector(
                    onTap: () => _toggleReminder(p.name),
                    child: Icon(
                      isReminding
                          ? Icons.notifications_none_rounded
                          : Icons.notifications_off_outlined,
                      size: 19,
                      color: isReminding
                          ? (isDark ? Colors.white60 : const Color(0xFF7A756D))
                          : Colors.grey.withOpacity(0.5),
                    ),
                  ),
                ],
              ),
            ],
          ),
        );
      }).toList(),
    );
  }
}
