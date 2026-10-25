import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:timezone/data/latest_all.dart' as tz;
import 'package:timezone/timezone.dart' as tz;

class PrayerNotificationItem {
  final int id;
  final String prayerName;
  final String arabicName;
  final DateTime scheduledTime;

  const PrayerNotificationItem({
    required this.id,
    required this.prayerName,
    required this.arabicName,
    required this.scheduledTime,
  });
}

/// Service managing OS-level Adhan notifications and exact prayer alarms
/// even when the application is closed.
class PrayerNotificationService {
  static final PrayerNotificationService _instance = PrayerNotificationService._internal();
  factory PrayerNotificationService() => _instance;
  PrayerNotificationService._internal();

  final FlutterLocalNotificationsPlugin _notificationsPlugin = FlutterLocalNotificationsPlugin();
  bool _isInitialized = false;

  static const String channelId = 'adhan_prayer_channel_v2';
  static const String channelName = 'Prayer Times Adhan';
  static const String channelDesc = 'Authentic Adhan notifications at exact Islamic prayer hours';

  /// Initialize notification plugin and configure Adhan audio channel
  Future<void> initialize() async {
    if (_isInitialized) return;

    try {
      tz.initializeTimeZones();

      const androidInit = AndroidInitializationSettings('@mipmap/ic_launcher');
      const iosInit = DarwinInitializationSettings(
        requestAlertPermission: true,
        requestBadgePermission: true,
        requestSoundPermission: true,
      );

      const initSettings = InitializationSettings(android: androidInit, iOS: iosInit);
      await _notificationsPlugin.initialize(
        initSettings,
        onDidReceiveNotificationResponse: (NotificationResponse response) {
          debugPrint('[PrayerNotificationService] Notification tapped: ${response.payload}');
        },
      );

      // Create high-priority Android channel with custom Adhan sound
      if (!kIsWeb && Platform.isAndroid) {
        final androidPlugin = _notificationsPlugin
            .resolvePlatformSpecificImplementation<AndroidFlutterLocalNotificationsPlugin>();

        if (androidPlugin != null) {
          await androidPlugin.createNotificationChannel(
            const AndroidNotificationChannel(
              channelId,
              channelName,
              description: channelDesc,
              importance: Importance.max,
              sound: RawResourceAndroidNotificationSound('adhan'),
              playSound: true,
              enableVibration: true,
            ),
          );

          // Request permissions for Android 13+
          await androidPlugin.requestNotificationsPermission();
          await androidPlugin.requestExactAlarmsPermission();
        }
      }

      _isInitialized = true;
    } catch (e) {
      debugPrint('[PrayerNotificationService] Error initializing: $e');
    }
  }

  /// Check whether Adhan reminder is enabled for a specific prayer
  Future<bool> isPrayerReminderEnabled(String prayerName) async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getBool('prayer_reminder_$prayerName') ?? true;
  }

  /// Toggle reminder on/off for a prayer
  Future<void> setPrayerReminderEnabled(String prayerName, bool enabled) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('prayer_reminder_$prayerName', enabled);
  }

  /// Schedules daily Adhan alarm for an individual prayer
  Future<void> schedulePrayerAdhan({
    required int id,
    required String prayerName,
    required String arabicName,
    required DateTime scheduledDateTime,
  }) async {
    if (!_isInitialized) await initialize();

    // Check if user disabled reminder for this prayer
    final isEnabled = await isPrayerReminderEnabled(prayerName);
    if (!isEnabled) {
      await cancelPrayerAdhan(id);
      return;
    }

    try {
      final now = DateTime.now();
      var targetTime = scheduledDateTime;
      if (targetTime.isBefore(now)) {
        targetTime = targetTime.add(const Duration(days: 1));
      }

      final tzDateTime = tz.TZDateTime.from(targetTime, tz.local);

      final androidDetails = AndroidNotificationDetails(
        channelId,
        channelName,
        channelDescription: channelDesc,
        importance: Importance.max,
        priority: Priority.high,
        sound: const RawResourceAndroidNotificationSound('adhan'),
        playSound: true,
        enableVibration: true,
        fullScreenIntent: true,
        styleInformation: BigTextStyleInformation(
          'It is now time for $prayerName prayer ($arabicName). Come to prayer, come to success.',
          contentTitle: 'Time for $prayerName ($arabicName) • أذان الصلاة',
        ),
      );

      const iosDetails = DarwinNotificationDetails(
        sound: 'adhan.mp3',
        presentAlert: true,
        presentBadge: true,
        presentSound: true,
      );

      final notificationDetails = NotificationDetails(
        android: androidDetails,
        iOS: iosDetails,
      );

      await _notificationsPlugin.zonedSchedule(
        id,
        'Time for $prayerName ($arabicName) • حي على الصلاة',
        'It is now time for $prayerName prayer. Click to listen to Adhan and open My Quran.',
        tzDateTime,
        notificationDetails,
        androidScheduleMode: AndroidScheduleMode.exactAllowWhileIdle,
        matchDateTimeComponents: DateTimeComponents.time,
        payload: prayerName,
      );

      debugPrint('[PrayerNotificationService] Scheduled $prayerName Adhan for $tzDateTime (id: $id)');
    } catch (e) {
      debugPrint('[PrayerNotificationService] Error scheduling $prayerName Adhan: $e');
    }
  }

  /// Triggers an immediate Adhan notification (useful for live prayer time or testing)
  Future<void> showInstantAdhanNotification({
    required String prayerName,
    required String arabicName,
  }) async {
    if (!_isInitialized) await initialize();

    try {
      const androidDetails = AndroidNotificationDetails(
        channelId,
        channelName,
        channelDescription: channelDesc,
        importance: Importance.max,
        priority: Priority.high,
        sound: RawResourceAndroidNotificationSound('adhan'),
        playSound: true,
        enableVibration: true,
      );

      const iosDetails = DarwinNotificationDetails(
        sound: 'adhan.mp3',
        presentAlert: true,
        presentSound: true,
      );

      await _notificationsPlugin.show(
        999,
        'Time for $prayerName ($arabicName) • حي على الصلاة',
        'It is now time for $prayerName prayer. May Allah accept your worship.',
        const NotificationDetails(android: androidDetails, iOS: iosDetails),
        payload: prayerName,
      );
    } catch (e) {
      debugPrint('[PrayerNotificationService] Error displaying instant notification: $e');
    }
  }

  /// Cancels an individual prayer notification
  Future<void> cancelPrayerAdhan(int id) async {
    try {
      await _notificationsPlugin.cancel(id);
    } catch (e) {
      debugPrint('[PrayerNotificationService] Error canceling alarm $id: $e');
    }
  }

  /// Cancels all scheduled prayer notifications
  Future<void> cancelAllAdhans() async {
    try {
      await _notificationsPlugin.cancelAll();
    } catch (e) {
      debugPrint('[PrayerNotificationService] Error canceling all alarms: $e');
    }
  }
}
