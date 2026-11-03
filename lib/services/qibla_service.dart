import 'dart:async';
import 'dart:math' as math;
import 'package:flutter_compass/flutter_compass.dart';
import 'package:geolocator/geolocator.dart';

class QiblaCoordinates {
  static const double kaabaLatitude = 21.422487;
  static const double kaabaLongitude = 39.826206;
}

class QiblaData {
  final double qiblaBearing;
  final double distanceKm;
  final Position? userPosition;

  const QiblaData({
    required this.qiblaBearing,
    required this.distanceKm,
    this.userPosition,
  });
}

class QiblaService {
  static final QiblaService _instance = QiblaService._internal();
  factory QiblaService() => _instance;
  QiblaService._internal();

  /// Calculates the initial Great-Circle bearing towards the Kaaba in Makkah (0° - 360°)
  static double calculateQiblaBearing({
    required double latitude,
    required double longitude,
  }) {
    final phi1 = latitude * (math.pi / 180.0);
    const phi2 = QiblaCoordinates.kaabaLatitude * (math.pi / 180.0);
    final deltaLambda =
        (QiblaCoordinates.kaabaLongitude - longitude) * (math.pi / 180.0);

    final y = math.sin(deltaLambda) * math.cos(phi2);
    final x = math.cos(phi1) * math.sin(phi2) -
        math.sin(phi1) * math.cos(phi2) * math.cos(deltaLambda);

    final initialBearingRad = math.atan2(y, x);
    final initialBearingDeg = initialBearingRad * (180.0 / math.pi);

    return (initialBearingDeg + 360.0) % 360.0;
  }

  /// Calculates the spherical surface distance to the Kaaba in kilometers
  static double calculateDistanceToKaabaKm({
    required double latitude,
    required double longitude,
  }) {
    const double earthRadiusKm = 6371.0;
    final dLat = (QiblaCoordinates.kaabaLatitude - latitude) * (math.pi / 180.0);
    final dLng =
        (QiblaCoordinates.kaabaLongitude - longitude) * (math.pi / 180.0);
    final lat1 = latitude * (math.pi / 180.0);
    const lat2 = QiblaCoordinates.kaabaLatitude * (math.pi / 180.0);

    final a = math.sin(dLat / 2) * math.sin(dLat / 2) +
        math.sin(dLng / 2) *
            math.sin(dLng / 2) *
            math.cos(lat1) *
            math.cos(lat2);
    final c = 2 * math.atan2(math.sqrt(a), math.sqrt(1 - a));
    return earthRadiusKm * c;
  }

  /// Computes shortest circular angle difference between current and target angle (-180° to 180°)
  static double shortestAngleDelta(double currentDeg, double targetDeg) {
    return ((targetDeg - currentDeg + 540) % 360) - 180;
  }

  /// Fetches current location and calculates Qibla bearing and distance
  Future<QiblaData> getQiblaData({
    double fallbackLat = 0.3476,
    double fallbackLng = 32.5825,
  }) async {
    try {
      final serviceEnabled = await Geolocator.isLocationServiceEnabled();
      if (!serviceEnabled) {
        return QiblaData(
          qiblaBearing: calculateQiblaBearing(
            latitude: fallbackLat,
            longitude: fallbackLng,
          ),
          distanceKm: calculateDistanceToKaabaKm(
            latitude: fallbackLat,
            longitude: fallbackLng,
          ),
        );
      }

      LocationPermission permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
      }

      if (permission == LocationPermission.denied ||
          permission == LocationPermission.deniedForever) {
        return QiblaData(
          qiblaBearing: calculateQiblaBearing(
            latitude: fallbackLat,
            longitude: fallbackLng,
          ),
          distanceKm: calculateDistanceToKaabaKm(
            latitude: fallbackLat,
            longitude: fallbackLng,
          ),
        );
      }

      final position = await Geolocator.getCurrentPosition(
        locationSettings: const LocationSettings(
          accuracy: LocationAccuracy.medium,
          timeLimit: Duration(seconds: 7),
        ),
      );

      return QiblaData(
        qiblaBearing: calculateQiblaBearing(
          latitude: position.latitude,
          longitude: position.longitude,
        ),
        distanceKm: calculateDistanceToKaabaKm(
          latitude: position.latitude,
          longitude: position.longitude,
        ),
        userPosition: position,
      );
    } catch (_) {
      return QiblaData(
        qiblaBearing: calculateQiblaBearing(
          latitude: fallbackLat,
          longitude: fallbackLng,
        ),
        distanceKm: calculateDistanceToKaabaKm(
          latitude: fallbackLat,
          longitude: fallbackLng,
        ),
      );
    }
  }

  /// Device compass heading stream
  Stream<CompassEvent>? get compassStream => FlutterCompass.events;
}
