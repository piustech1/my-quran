import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:my_quran/services/adhan_player_service.dart';
import 'package:my_quran/services/prayer_notification_service.dart';
import 'package:my_quran/services/prayer_time_service.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('AdhanPlayerService Tests', () {
    test('AdhanPlayerService is a singleton', () {
      final s1 = AdhanPlayerService();
      final s2 = AdhanPlayerService();
      expect(identical(s1, s2), isTrue);
    });

    test('Initial player state is not playing and prayer name is null', () {
      final service = AdhanPlayerService();
      expect(service.isPlaying, isFalse);
      expect(service.currentPrayer, isNull);
    });
  });

  group('PrayerNotificationService Preference Tests', () {
    setUp(() {
      SharedPreferences.setMockInitialValues({
        'prayer_reminder_Fajr': true,
        'prayer_reminder_Sunrise': false,
        'prayer_reminder_Dhuhr': true,
      });
    });

    test('isPrayerReminderEnabled returns mock values and default true', () async {
      final service = PrayerNotificationService();
      expect(await service.isPrayerReminderEnabled('Fajr'), isTrue);
      expect(await service.isPrayerReminderEnabled('Sunrise'), isFalse);
      expect(await service.isPrayerReminderEnabled('Maghrib'), isTrue); // default true
    });

    test('setPrayerReminderEnabled saves updated toggle state', () async {
      final service = PrayerNotificationService();
      await service.setPrayerReminderEnabled('Isha', false);
      expect(await service.isPrayerReminderEnabled('Isha'), isFalse);

      await service.setPrayerReminderEnabled('Isha', true);
      expect(await service.isPrayerReminderEnabled('Isha'), isTrue);
    });
  });

  group('PrayerSchedule & Calculations Tests', () {
    test('PrayerSchedule.fallbackDefault provides valid timetable strings', () {
      final fallback = PrayerSchedule.fallbackDefault();
      expect(fallback.fajr, isNotEmpty);
      expect(fallback.sunrise, isNotEmpty);
      expect(fallback.dhuhr, isNotEmpty);
      expect(fallback.asr, isNotEmpty);
      expect(fallback.maghrib, isNotEmpty);
      expect(fallback.isha, isNotEmpty);
      expect(fallback.fajr.contains(':'), isTrue);
    });

    test('getUpcomingPrayer correctly computes next prayer', () {
      final prayerService = PrayerTimeService();
      final schedule = PrayerSchedule.fallbackDefault();
      // Test with midday time 12:00
      final midday = DateTime(2026, 10, 25, 12, 0);
      final upcoming = prayerService.getUpcomingPrayer(schedule, midday);
      expect(upcoming.name, isNotEmpty);
      expect(upcoming.timeFormatted, isNotEmpty);
    });
  });
}
