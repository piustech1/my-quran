import 'package:flutter_test/flutter_test.dart';
import 'package:my_quran/services/qibla_service.dart';
import 'package:my_quran/services/prayer_time_service.dart';

void main() {
  group('QiblaService Calculations', () {
    test('calculateQiblaBearing returns accurate bearing for Kampala, Uganda', () {
      // Kampala coordinates: ~0.3476° N, 32.5825° E
      final bearing = QiblaService.calculateQiblaBearing(
        latitude: 0.3476,
        longitude: 32.5825,
      );

      // Kampala towards Makkah is approximately 19° NNE
      expect(bearing, greaterThan(18.0));
      expect(bearing, lessThan(21.0));
    });

    test('calculateQiblaBearing returns accurate bearing for London, UK', () {
      // London coordinates: ~51.5074° N, -0.1278° W
      final bearing = QiblaService.calculateQiblaBearing(
        latitude: 51.5074,
        longitude: -0.1278,
      );

      // London towards Makkah is approximately 118° - 120° ESE
      expect(bearing, greaterThan(117.0));
      expect(bearing, lessThan(121.0));
    });

    test('calculateDistanceToKaabaKm returns accurate spherical distance', () {
      // Distance from Kampala to Makkah is approx 2380 km
      final distance = QiblaService.calculateDistanceToKaabaKm(
        latitude: 0.3476,
        longitude: 32.5825,
      );

      expect(distance, greaterThan(2300));
      expect(distance, lessThan(2500));
    });

    test('shortestAngleDelta calculates shortest circular turn angle', () {
      // 355° to 5° is +10° turn
      expect(QiblaService.shortestAngleDelta(355, 5), closeTo(10.0, 0.01));

      // 5° to 355° is -10° turn
      expect(QiblaService.shortestAngleDelta(5, 355), closeTo(-10.0, 0.01));

      // 180° opposite
      expect(QiblaService.shortestAngleDelta(0, 180).abs(), closeTo(180.0, 0.01));
    });
  });

  group('PrayerTimeService Hijri Conversion', () {
    test('calculateHijriDate produces non-empty formatted Hijri date', () {
      final hijri = PrayerSchedule.calculateHijriDate(DateTime(2026, 10, 24));
      expect(hijri, contains('AH'));
      expect(hijri, isNotEmpty);
    });
  });
}
