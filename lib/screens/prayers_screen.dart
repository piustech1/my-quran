import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
import '../services/prayer_time_service.dart';
import '../services/adhan_player_service.dart';
import '../services/prayer_notification_service.dart';
import '../widgets/floating_nav_dock.dart';
import 'main_navigation_shell.dart';

class PrayerDisplayItem {
  final int id;
  final String name;
  final String arabicName;
  final String time;
  final IconData icon;
  final bool isNext;
  final bool isPast;

  const PrayerDisplayItem({
    required this.id,
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
  final AdhanPlayerService _adhanService = AdhanPlayerService();
  final PrayerNotificationService _notificationService = PrayerNotificationService();

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

  String? _lastTriggeredPrayer;

  @override
  void initState() {
    super.initState();
    _initNotificationsAndSchedule();

    _ticker = Timer.periodic(const Duration(seconds: 1), (_) {
      if (mounted) {
        setState(() {
          _now = DateTime.now();
          if (_schedule != null) {
            _upcomingPrayer = _prayerService.getUpcomingPrayer(_schedule!, _now);
            _checkAndTriggerAdhan();
          }
        });
      }
    });
  }

  Future<void> _initNotificationsAndSchedule() async {
    await _notificationService.initialize();

    // Load reminder preferences
    for (final key in _prayerReminders.keys) {
      final enabled = await _notificationService.isPrayerReminderEnabled(key);
      _prayerReminders[key] = enabled;
    }

    await _loadSchedule();
  }

  Future<void> _loadSchedule() async {
    final sched = await _prayerService.fetchPrayerTimes();
    if (mounted) {
      setState(() {
        _schedule = sched;
        _upcomingPrayer = _prayerService.getUpcomingPrayer(sched, DateTime.now());
      });
      _scheduleDailyAdhanAlarms();
    }
  }

  void _scheduleDailyAdhanAlarms() {
    if (_schedule == null) return;
    final prayers = _getPrayerRows();
    for (final p in prayers) {
      if (p.name == 'Sunrise') continue; // Sunrise is not a prayer call
      final timeParts = p.time.split(':');
      if (timeParts.length == 2) {
        final hour = int.tryParse(timeParts[0]) ?? 0;
        final minute = int.tryParse(timeParts[1]) ?? 0;
        final prayerTime = DateTime(_now.year, _now.month, _now.day, hour, minute);

        _notificationService.schedulePrayerAdhan(
          id: p.id,
          prayerName: p.name,
          arabicName: p.arabicName,
          scheduledDateTime: prayerTime,
        );
      }
    }
  }

  void _checkAndTriggerAdhan() {
    if (_schedule == null) return;
    final prayers = _getPrayerRows();
    for (final p in prayers) {
      if (p.name == 'Sunrise') continue;
      final isEnabled = _prayerReminders[p.name] ?? true;
      if (!isEnabled) continue;

      final timeParts = p.time.split(':');
      if (timeParts.length == 2) {
        final hour = int.tryParse(timeParts[0]);
        final minute = int.tryParse(timeParts[1]);
        if (hour == _now.hour && minute == _now.minute && _now.second < 2) {
          final triggerKey = '${p.name}_${_now.day}_$hour:$minute';
          if (_lastTriggeredPrayer != triggerKey) {
            _lastTriggeredPrayer = triggerKey;
            _adhanService.playAdhan(p.name);
            _notificationService.showInstantAdhanNotification(
              prayerName: p.name,
              arabicName: p.arabicName,
            );
          }
        }
      }
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
        'id': 1,
        'name': 'Fajr',
        'arabic': 'الفجر',
        'time': sched.fajr,
        'icon': Icons.nightlight_round,
      },
      {
        'id': 2,
        'name': 'Sunrise',
        'arabic': 'الشروق',
        'time': sched.sunrise,
        'icon': Icons.wb_twilight_rounded,
      },
      {
        'id': 3,
        'name': 'Dhuhr',
        'arabic': 'الظهر',
        'time': sched.dhuhr,
        'icon': Icons.wb_sunny_rounded,
      },
      {
        'id': 4,
        'name': 'Asr',
        'arabic': 'العصر',
        'time': sched.asr,
        'icon': Icons.wb_sunny_outlined,
      },
      {
        'id': 5,
        'name': 'Maghrib',
        'arabic': 'المغرب',
        'time': sched.maghrib,
        'icon': Icons.wb_twilight_rounded,
      },
      {
        'id': 6,
        'name': 'Isha',
        'arabic': 'العشاء',
        'time': sched.isha,
        'icon': Icons.nights_stay_rounded,
      },
    ];

    return list.map((item) {
      final prayerName = item['name'] as String;
      final arabic = item['arabic'] as String;
      final time24 = item['time'] as String;
      final icon = item['icon'] as IconData;
      final id = item['id'] as int;

      final isNext = _upcomingPrayer != null && _upcomingPrayer!.name == prayerName;

      bool isPast = false;
      try {
        final parts = time24.split(':');
        final hour = int.parse(parts[0]);
        final minute = int.parse(parts[1]);
        final prayerTime = DateTime(_now.year, _now.month, _now.day, hour, minute);
        isPast = _now.isAfter(prayerTime) && !isNext;
      } catch (_) {}

      return PrayerDisplayItem(
        id: id,
        name: prayerName,
        arabicName: arabic,
        time: time24,
        icon: icon,
        isNext: isNext,
        isPast: isPast,
      );
    }).toList();
  }

  Future<void> _toggleReminder(String prayerName) async {
    HapticFeedback.lightImpact();
    final currentState = _prayerReminders[prayerName] ?? true;
    final newState = !currentState;

    setState(() {
      _prayerReminders[prayerName] = newState;
    });

    await _notificationService.setPrayerReminderEnabled(prayerName, newState);
    _scheduleDailyAdhanAlarms();

    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            newState
                ? 'Adhan alarm enabled for $prayerName'
                : 'Adhan alarm muted for $prayerName',
            style: GoogleFonts.plusJakartaSans(color: Colors.white, fontSize: 13),
          ),
          backgroundColor: const Color(0xFF0F3826),
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          duration: const Duration(seconds: 2),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final countdown = _upcomingPrayer != null
        ? _formatCountdown(_upcomingPrayer!.timeRemaining)
        : '00:00:00';

    return Scaffold(
      backgroundColor: isDark ? const Color(0xFF0A1F14) : const Color(0xFFF7F5F0),
      body: Stack(
        children: [
          // Main Scrollable Area without Mosque Finder card
          SafeArea(
            top: false,
            bottom: false,
            child: SingleChildScrollView(
              physics: const ClampingScrollPhysics(),
              padding: const EdgeInsets.only(bottom: 110),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  // 1. Crystal-Clear Mufta Islamic Header Arch
                  _buildHeaderArch(isDark, countdown),

                  const SizedBox(height: 12),

                  // 2. Active Adhan Live Audio Banner (if Adhan is playing)
                  ValueListenableBuilder<bool>(
                    valueListenable: _adhanService.isPlayingNotifier,
                    builder: (context, isPlaying, _) {
                      if (!isPlaying) return const SizedBox.shrink();
                      return _buildAdhanLiveBanner();
                    },
                  ),

                  // 3. "Today's prayers" Schedule Section
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // Section Header: "Today's prayers" & Date
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text(
                              "Today's prayers",
                              style: GoogleFonts.plusJakartaSans(
                                fontSize: 16.5,
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
                        const SizedBox(height: 10),

                        // Prayer List Cards (Zero Outlines)
                        _buildPrayerList(isDark),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),

          // 4. Standalone Floating Nav Dock (if not already embedded in MainNavigationShell)
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

  /// 1. Top Header Arch Container (Crystal-Clear Mufta matching Home Dashboard, Zero Outlines)
  Widget _buildHeaderArch(bool isDark, String countdown) {
    final topPadding = MediaQuery.of(context).padding.top;

    return Container(
      decoration: const BoxDecoration(
        color: Color(0xFF0D2F1F),
        borderRadius: BorderRadius.vertical(bottom: Radius.circular(38)),
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
          // Background Mufta Pattern (Crystal Clear, High Quality)
          Positioned.fill(
            child: Image.asset(
              'assets/new_mufta.jpg',
              fit: BoxFit.cover,
              alignment: Alignment.topCenter,
              filterQuality: FilterQuality.high,
            ),
          ),

          // Atmospheric gradient overlay for contrast (Matching Home Dashboard razor-sharp clarity)
          Positioned.fill(
            child: Container(
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
          ),

          // Hairline gold accent line at curved bottom
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

          // Header Content
          Padding(
            padding: EdgeInsets.fromLTRB(16, topPadding + 8, 16, 20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Top Row: [ < ] Back Button & [ 📍 Kampala, Uganda ] Pill (NO OUTLINES)
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
                          color: Colors.white.withOpacity(0.18),
                        ),
                        child: const Icon(
                          Icons.arrow_back_rounded,
                          color: Colors.white,
                          size: 19,
                        ),
                      ),
                    ),

                    // Location Pill [ 📍 Kampala, Uganda ] (NO BORDER / OUTLINE)
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 7),
                      decoration: BoxDecoration(
                        color: Colors.white.withOpacity(0.18),
                        borderRadius: BorderRadius.circular(20),
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

                const SizedBox(height: 16),

                // Title Section: "DAILY DEVOTION" + "Prayer Times" + Clock Icon
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'DAILY DEVOTION',
                          style: GoogleFonts.plusJakartaSans(
                            fontSize: 10.5,
                            fontWeight: FontWeight.w700,
                            letterSpacing: 1.2,
                            color: const Color(0xFFCCA048),
                          ),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          'Prayer Times',
                          style: GoogleFonts.plusJakartaSans(
                            fontSize: 26,
                            fontWeight: FontWeight.bold,
                            color: Colors.white,
                            letterSpacing: -0.5,
                          ),
                        ),
                      ],
                    ),
                    const Icon(
                      Icons.access_time_rounded,
                      color: Color(0xFFCCA048),
                      size: 26,
                    ),
                  ],
                ),

                const SizedBox(height: 16),

                // UPCOMING PRAYER Card (NO BORDER / OUTLINE)
                _buildUpcomingPrayerCard(countdown),
              ],
            ),
          ),
        ],
      ),
    );
  }

  /// Elevated Upcoming Prayer Card (NO BORDER / OUTLINE)
  Widget _buildUpcomingPrayerCard(String countdown) {
    final upcomingName = _upcomingPrayer?.name ?? 'Fajr';
    final upcomingTime = _upcomingPrayer != null
        ? _format12Hour(_upcomingPrayer!.timeFormatted)
        : '5:33 AM';
    final isTomorrow = _upcomingPrayer != null &&
        _upcomingPrayer!.prayerDateTime.day != _now.day;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 15),
      decoration: BoxDecoration(
        color: const Color(0xFF143B29).withOpacity(0.92),
        borderRadius: BorderRadius.circular(24),
        boxShadow: const [
          BoxShadow(
            color: Colors.black26,
            blurRadius: 12,
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
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 7),
                decoration: BoxDecoration(
                  color: const Color(0xFFE5A93C),
                  borderRadius: BorderRadius.circular(20),
                  boxShadow: [
                    BoxShadow(
                      color: const Color(0xFFE5A93C).withOpacity(0.35),
                      blurRadius: 10,
                      offset: const Offset(0, 3),
                    ),
                  ],
                ),
                child: Text(
                  countdown,
                  style: GoogleFonts.plusJakartaSans(
                    fontSize: 14,
                    fontWeight: FontWeight.bold,
                    color: const Color(0xFF143B29),
                    letterSpacing: 0.5,
                  ),
                ),
              ),
              const SizedBox(height: 4),
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

  /// Live Adhan Audio Banner when Adhan is sounding
  Widget _buildAdhanLiveBanner() {
    final currentAdhanPrayer = _adhanService.currentPrayer ?? 'Prayer';

    return Container(
      margin: const EdgeInsets.fromLTRB(16, 0, 16, 12),
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        color: const Color(0xFF133624),
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFFCCA048).withOpacity(0.25),
            blurRadius: 14,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Row(
        children: [
          Container(
            width: 38,
            height: 38,
            decoration: const BoxDecoration(
              shape: BoxShape.circle,
              color: Color(0xFFCCA048),
            ),
            child: const Icon(
              Icons.volume_up_rounded,
              color: Color(0xFF0F3826),
              size: 20,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Adhan Reciting: $currentAdhanPrayer',
                  style: GoogleFonts.plusJakartaSans(
                    fontSize: 13.5,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                  ),
                ),
                Text(
                  'Mishary Rashid Alafasy • حي على الصلاة',
                  style: GoogleFonts.plusJakartaSans(
                    fontSize: 11,
                    color: const Color(0xFFC7DEC9),
                  ),
                ),
              ],
            ),
          ),
          ElevatedButton(
            onPressed: () {
              HapticFeedback.lightImpact();
              _adhanService.stopAdhan();
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF265D3C),
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
              elevation: 0,
            ),
            child: Text(
              'Stop',
              style: GoogleFonts.plusJakartaSans(
                fontSize: 12,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
        ],
      ),
    );
  }

  /// 3. Prayer Timetable Schedule Cards (ZERO OUTLINES)
  Widget _buildPrayerList(bool isDark) {
    final prayers = _getPrayerRows();

    return Column(
      children: prayers.map((p) {
        final isNext = p.isNext;
        final isReminding = _prayerReminders[p.name] ?? true;

        if (isNext) {
          // Highlighted Golden-Cream Active Next Prayer Card (NO BORDER / OUTLINE)
          return Container(
            margin: const EdgeInsets.only(bottom: 8),
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 13),
            decoration: BoxDecoration(
              color: isDark ? const Color(0xFF1D4530) : const Color(0xFFFAF0D9),
              borderRadius: BorderRadius.circular(22),
              boxShadow: [
                BoxShadow(
                  color: const Color(0xFFCCA048).withOpacity(isDark ? 0.18 : 0.12),
                  blurRadius: 10,
                  offset: const Offset(0, 3),
                ),
              ],
            ),
            child: Row(
              children: [
                // Amber circle with icon
                Container(
                  width: 40,
                  height: 40,
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
                              fontSize: 15,
                              fontWeight: FontWeight.bold,
                              color: isDark ? Colors.white : const Color(0xFF18181B),
                            ),
                          ),
                          const SizedBox(width: 8),
                          Text(
                            p.arabicName,
                            style: GoogleFonts.amiri(
                              fontSize: 14,
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
                          fontSize: 11,
                          fontWeight: FontWeight.w600,
                          color: isDark ? const Color(0xFFCCA048) : const Color(0xFF986F20),
                        ),
                      ),
                    ],
                  ),
                ),

                // Time & Interactive Notification Bell
                Row(
                  children: [
                    Text(
                      _format12Hour(p.time),
                      style: GoogleFonts.plusJakartaSans(
                        fontSize: 14.5,
                        fontWeight: FontWeight.bold,
                        color: isDark ? Colors.white : const Color(0xFF18181B),
                      ),
                    ),
                    const SizedBox(width: 12),
                    GestureDetector(
                      onTap: () => _toggleReminder(p.name),
                      child: Container(
                        padding: const EdgeInsets.all(6),
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
                    ),
                  ],
                ),
              ],
            ),
          );
        }

        // Clean Neutral Card for other prayers (NO BORDER / OUTLINE)
        return Container(
          margin: const EdgeInsets.only(bottom: 8),
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          decoration: BoxDecoration(
            color: isDark ? const Color(0xFF142E20) : Colors.white,
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

              // Time & Interactive Notification Bell
              Row(
                children: [
                  Text(
                    _format12Hour(p.time),
                    style: GoogleFonts.plusJakartaSans(
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                      color: isDark ? Colors.white60 : const Color(0xFF57534E),
                    ),
                  ),
                  const SizedBox(width: 12),
                  if (p.name != 'Sunrise')
                    GestureDetector(
                      onTap: () => _toggleReminder(p.name),
                      child: Container(
                        padding: const EdgeInsets.all(6),
                        child: Icon(
                          isReminding
                              ? Icons.notifications_active_rounded
                              : Icons.notifications_off_outlined,
                          size: 19,
                          color: isReminding
                              ? (isDark ? const Color(0xFFCCA048) : const Color(0xFF1B633D))
                              : Colors.grey.withOpacity(0.5),
                        ),
                      ),
                    )
                  else
                    const SizedBox(width: 31),
                ],
              ),
            ],
          ),
        );
      }).toList(),
    );
  }
}
