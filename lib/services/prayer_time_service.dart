import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';

class PrayerSchedule {
  final String fajr;
  final String sunrise;
  final String dhuhr;
  final String asr;
  final String maghrib;
  final String isha;
  final String readableDate;
  final String hijriDate;

  PrayerSchedule({
    required this.fajr,
    required this.sunrise,
    required this.dhuhr,
    required this.asr,
    required this.maghrib,
    required this.isha,
    required this.readableDate,
    required this.hijriDate,
  });

  factory PrayerSchedule.fromJson(Map<String, dynamic> json) {
    final timings = json['data']['timings'] as Map<String, dynamic>;
    final date = json['data']['date'] as Map<String, dynamic>;
    final hijri = date['hijri'] as Map<String, dynamic>?;

    final hijriFormatted = hijri != null
        ? '${hijri['day']} ${hijri['month']['en']} ${hijri['year']} AH'
        : '';

    return PrayerSchedule(
      fajr: _cleanTime(timings['Fajr']),
      sunrise: _cleanTime(timings['Sunrise']),
      dhuhr: _cleanTime(timings['Dhuhr']),
      asr: _cleanTime(timings['Asr']),
      maghrib: _cleanTime(timings['Maghrib']),
      isha: _cleanTime(timings['Isha']),
      readableDate: date['readable'] ?? '',
      hijriDate: hijriFormatted,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'fajr': fajr,
      'sunrise': sunrise,
      'dhuhr': dhuhr,
      'asr': asr,
      'maghrib': maghrib,
      'isha': isha,
      'readableDate': readableDate,
      'hijriDate': hijriDate,
    };
  }

  factory PrayerSchedule.fromMap(Map<String, dynamic> map) {
    return PrayerSchedule(
      fajr: map['fajr'] ?? '05:30',
      sunrise: map['sunrise'] ?? '06:30',
      dhuhr: map['dhuhr'] ?? '12:30',
      asr: map['asr'] ?? '15:45',
      maghrib: map['maghrib'] ?? '18:30',
      isha: map['isha'] ?? '19:45',
      readableDate: map['readableDate'] ?? '',
      hijriDate: map['hijriDate'] ?? '',
    );
  }

  static String _cleanTime(dynamic val) {
    if (val == null) return '00:00';
    final str = val.toString();
    // Some responses have format "05:33 (EAT)"
    final parts = str.split(' ');
    return parts.first;
  }

  static PrayerSchedule fallbackDefault() {
    return PrayerSchedule(
      fajr: '05:33',
      sunrise: '06:31',
      dhuhr: '12:16',
      asr: '15:52',
      maghrib: '18:37',
      isha: '19:35',
      readableDate: '23 Oct 2026',
      hijriDate: '12 Jumada al-awwal 1448 AH',
    );
  }
}

class UpcomingPrayer {
  final String name;
  final String timeFormatted;
  final Duration remaining;
  final DateTime prayerDateTime;

  UpcomingPrayer({
    required this.name,
    required this.timeFormatted,
    required this.remaining,
    required this.prayerDateTime,
  });

  Duration get timeRemaining => remaining;
}

class PrayerTimeService {
  static const String _baseUrl = 'http://api.aladhan.com/v1';

  /// Fetches prayer times by latitude and longitude with local cache
  Future<PrayerSchedule> fetchPrayerTimes({
    double lat = 0.3476,
    double lon = 32.5825,
    String? city,
    String? country,
  }) async {
    final prefs = await SharedPreferences.getInstance();
    final today = DateTime.now();
    final dateKey = '${today.year}_${today.month}_${today.day}';
    final cacheKey = 'cached_prayer_times_${dateKey}_${lat.toStringAsFixed(2)}_${lon.toStringAsFixed(2)}';

    // 1. Check local cache
    final cached = prefs.getString(cacheKey);
    if (cached != null) {
      try {
        final Map<String, dynamic> map = jsonDecode(cached);
        return PrayerSchedule.fromMap(map);
      } catch (_) {}
    }

    // 2. Fetch from API
    try {
      final Uri uri;
      if (city != null && country != null) {
        uri = Uri.parse(
            '$_baseUrl/timingsByCity?city=$city&country=$country&method=2');
      } else {
        uri = Uri.parse(
            '$_baseUrl/timings?latitude=$lat&longitude=$lon&method=2');
      }

      final response = await http.get(uri).timeout(const Duration(seconds: 8));
      if (response.statusCode == 200) {
        final json = jsonDecode(response.body) as Map<String, dynamic>;
        final schedule = PrayerSchedule.fromJson(json);

        // Save to cache
        await prefs.setString(cacheKey, jsonEncode(schedule.toMap()));
        return schedule;
      }
    } catch (_) {
      // Network or timeout error, proceed to fallback
    }

    return PrayerSchedule.fallbackDefault();
  }

  /// Calculates which of the 5 prayers is currently upcoming or active
  UpcomingPrayer getUpcomingPrayer(PrayerSchedule schedule, DateTime now) {
    final prayers = [
      MapEntry('FAJR', schedule.fajr),
      MapEntry('DHUHR', schedule.dhuhr),
      MapEntry('ASR', schedule.asr),
      MapEntry('MAGHRIB', schedule.maghrib),
      MapEntry('ISHA', schedule.isha),
    ];

    for (final p in prayers) {
      final pTime = _parseTimeToToday(p.value, now);
      if (now.isBefore(pTime)) {
        return UpcomingPrayer(
          name: p.key,
          timeFormatted: _format12Hour(p.value),
          remaining: pTime.difference(now),
          prayerDateTime: pTime,
        );
      }
    }

    // After Isha: Next upcoming prayer is tomorrow's Fajr
    final tomorrow = now.add(const Duration(days: 1));
    final tomorrowFajr = _parseTimeToToday(schedule.fajr, tomorrow);
    return UpcomingPrayer(
      name: 'FAJR',
      timeFormatted: _format12Hour(schedule.fajr),
      remaining: tomorrowFajr.difference(now),
      prayerDateTime: tomorrowFajr,
    );
  }

  DateTime _parseTimeToToday(String time24, DateTime day) {
    try {
      final parts = time24.split(':');
      final hour = int.parse(parts[0]);
      final minute = int.parse(parts[1]);
      return DateTime(day.year, day.month, day.day, hour, minute);
    } catch (_) {
      return DateTime(day.year, day.month, day.day, 12, 0);
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
}
