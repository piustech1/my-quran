import 'dart:async';
import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_compass/flutter_compass.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:google_fonts/google_fonts.dart';
import '../services/location_weather_service.dart';
import '../services/qibla_service.dart';

class QiblaCompassScreen extends StatefulWidget {
  const QiblaCompassScreen({super.key});

  @override
  State<QiblaCompassScreen> createState() => _QiblaCompassScreenState();
}

class _QiblaCompassScreenState extends State<QiblaCompassScreen> {
  final QiblaService _qiblaService = QiblaService();
  final LocationWeatherService _locationService = LocationWeatherService();

  StreamSubscription<CompassEvent>? _compassSubscription;
  double? _smoothedHeading;
  double _qiblaBearing = 14.2; // Default for East Africa / Kampala -> Makkah
  double _distanceKm = 2470.0;
  String _locationName = 'Locating...';
  bool _hasCompassSensor = true;
  bool _isAlignedWithKaaba = false;
  bool _hapticFired = false;

  @override
  void initState() {
    super.initState();
    _initDataAndCompass();
  }

  Future<void> _initDataAndCompass() async {
    // 1. Fetch user location name & coordinates
    try {
      final loc = await _locationService.detectLocation();
      final qiblaData = await _qiblaService.getQiblaData(
        fallbackLat: loc.lat,
        fallbackLng: loc.lon,
      );

      if (mounted) {
        setState(() {
          _locationName = '${loc.city}, ${loc.country}';
          _qiblaBearing = qiblaData.qiblaBearing;
          _distanceKm = qiblaData.distanceKm;
        });
      }
    } catch (_) {
      if (mounted) {
        setState(() {
          _locationName = 'Standard Coordinates';
        });
      }
    }

    // 2. Listen to compass sensor events with smoothing
    final compassStream = _qiblaService.compassStream;
    if (compassStream == null) {
      if (mounted) {
        setState(() => _hasCompassSensor = false);
      }
      return;
    }

    _compassSubscription = compassStream.listen((event) {
      final heading = event.heading;
      if (heading == null) return;

      if (mounted) {
        setState(() {
          if (_smoothedHeading == null) {
            _smoothedHeading = heading;
          } else {
            // Low-pass exponential smoothing with shortest angular delta
            final delta =
                QiblaService.shortestAngleDelta(_smoothedHeading!, heading);
            _smoothedHeading = (_smoothedHeading! + delta * 0.20) % 360.0;
            if (_smoothedHeading! < 0) _smoothedHeading = _smoothedHeading! + 360.0;
          }

          // Check if user is pointing directly towards the Kaaba (within ±2°)
          final diffToQibla = (_qiblaBearing - _smoothedHeading!).abs();
          final isAligned = diffToQibla <= 2.0 || (360.0 - diffToQibla) <= 2.0;

          if (isAligned && !_hapticFired) {
            HapticFeedback.lightImpact();
            _hapticFired = true;
          } else if (!isAligned) {
            _hapticFired = false;
          }

          _isAlignedWithKaaba = isAligned;
        });
      }
    }, onError: (_) {
      if (mounted) {
        setState(() => _hasCompassSensor = false);
      }
    });
  }

  @override
  void dispose() {
    _compassSubscription?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final currentHeading = _smoothedHeading ?? 0.0;
    // Rotation angles in radians
    final dialRotation = -currentHeading * (math.pi / 180.0);
    final qiblaPointerRotation =
        (_qiblaBearing - currentHeading) * (math.pi / 180.0);
    final needleRotation = -currentHeading * (math.pi / 180.0);

    return Scaffold(
      backgroundColor: const Color(0xFF091F14), // Deep premium Islamic emerald
      body: Stack(
        children: [
          // 1. Ambient Background Glow and Subtle Mosque Geometry
          Positioned.fill(
            child: Container(
              decoration: const BoxDecoration(
                gradient: RadialGradient(
                  center: Alignment(0.0, -0.15),
                  radius: 0.95,
                  colors: [
                    Color(0xFF14422D),
                    Color(0xFF081C12),
                    Color(0xFF040F0A),
                  ],
                ),
              ),
            ),
          ),

          // 2. Safe Area Content
          SafeArea(
            child: Column(
              children: [
                // Top Custom Header Row
                _buildTopBar(context),

                const Spacer(flex: 1),

                // Alignment Status Banner
                _buildAlignmentBanner(),

                const SizedBox(height: 14),

                // Main Stacked Compass Widget
                _buildCompassWidget(
                  dialRotation: dialRotation,
                  qiblaPointerRotation: qiblaPointerRotation,
                  needleRotation: needleRotation,
                ),

                const Spacer(flex: 1),

                // Bottom Metadata Cards (Angle, Distance, Location)
                _buildMetadataPanel(currentHeading),

                const SizedBox(height: 24),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTopBar(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          // Back button
          GestureDetector(
            onTap: () => Navigator.of(context).pop(),
            child: Container(
              width: 42,
              height: 42,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: Colors.white.withOpacity(0.12),
              ),
              child: const Icon(
                Icons.arrow_back_ios_new_rounded,
                color: Colors.white,
                size: 18,
              ),
            ),
          ),

          // Title & Subtitle
          Column(
            children: [
              Text(
                'QIBLA FINDER',
                style: GoogleFonts.plusJakartaSans(
                  fontSize: 11,
                  fontWeight: FontWeight.w700,
                  letterSpacing: 2.0,
                  color: const Color(0xFFD4AF37),
                ),
              ),
              Text(
                'اتجاه القبلة إلى مكة',
                style: GoogleFonts.amiri(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  color: Colors.white,
                ),
              ),
            ],
          ),

          // Calibration Info / Sensor status
          Container(
            width: 42,
            height: 42,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: Colors.white.withOpacity(0.08),
            ),
            child: Icon(
              _hasCompassSensor
                  ? Icons.explore_rounded
                  : Icons.sensors_off_rounded,
              color: _hasCompassSensor
                  ? const Color(0xFFD4AF37)
                  : Colors.redAccent,
              size: 20,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildAlignmentBanner() {
    if (!_hasCompassSensor) {
      return Container(
        margin: const EdgeInsets.symmetric(horizontal: 24),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
        decoration: BoxDecoration(
          color: Colors.red.withOpacity(0.2),
          borderRadius: BorderRadius.circular(16),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.info_outline, color: Colors.white, size: 16),
            const SizedBox(width: 8),
            Text(
              'No magnetometer found. Calibrating via GPS.',
              style: GoogleFonts.plusJakartaSans(
                color: Colors.white,
                fontSize: 12,
                fontWeight: FontWeight.w500,
              ),
            ),
          ],
        ),
      );
    }

    return AnimatedContainer(
      duration: const Duration(milliseconds: 300),
      margin: const EdgeInsets.symmetric(horizontal: 24),
      padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 10),
      decoration: BoxDecoration(
        color: _isAlignedWithKaaba
            ? const Color(0xFFD4AF37).withOpacity(0.24)
            : Colors.white.withOpacity(0.07),
        borderRadius: BorderRadius.circular(20),
        boxShadow: _isAlignedWithKaaba
            ? [
                BoxShadow(
                  color: const Color(0xFFD4AF37).withOpacity(0.35),
                  blurRadius: 16,
                  spreadRadius: 2,
                ),
              ]
            : null,
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            _isAlignedWithKaaba
                ? Icons.check_circle_rounded
                : Icons.adjust_rounded,
            color:
                _isAlignedWithKaaba ? const Color(0xFFD4AF37) : Colors.white70,
            size: 18,
          ),
          const SizedBox(width: 8),
          Text(
            _isAlignedWithKaaba
                ? 'Directly Facing Kaaba (Makkah)'
                : 'Rotate phone until golden pointer aligns with top',
            style: GoogleFonts.plusJakartaSans(
              color: _isAlignedWithKaaba ? const Color(0xFFF9E8B2) : Colors.white70,
              fontSize: 12.5,
              fontWeight:
                  _isAlignedWithKaaba ? FontWeight.bold : FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCompassWidget({
    required double dialRotation,
    required double qiblaPointerRotation,
    required double needleRotation,
  }) {
    const double compassSize = 310.0;

    return Center(
      child: SizedBox(
        width: compassSize,
        height: compassSize,
        child: Stack(
          alignment: Alignment.center,
          children: [
            // Ambient Radiant Golden Glow around compass
            AnimatedContainer(
              duration: const Duration(milliseconds: 350),
              width: compassSize - 10,
              height: compassSize - 10,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                boxShadow: [
                  BoxShadow(
                    color: _isAlignedWithKaaba
                        ? const Color(0xFFD4AF37).withOpacity(0.45)
                        : const Color(0xFF17573B).withOpacity(0.25),
                    blurRadius: _isAlignedWithKaaba ? 38 : 22,
                    spreadRadius: _isAlignedWithKaaba ? 6 : 1,
                  ),
                ],
              ),
            ),

            // 1. Outer Compass Dial (Rotates with device heading)
            Transform.rotate(
              angle: dialRotation,
              child: SvgPicture.asset(
                'assets/svg/compass_dial.svg',
                width: compassSize,
                height: compassSize,
                fit: BoxFit.contain,
              ),
            ),

            // 2. Magnetic North / South Needle
            Transform.rotate(
              angle: needleRotation,
              child: SvgPicture.asset(
                'assets/svg/compass_needle.svg',
                width: compassSize * 0.76,
                height: compassSize * 0.76,
                fit: BoxFit.contain,
              ),
            ),

            // 3. Golden Qibla Pointer with Kaaba Emblem (Points directly to Kaaba)
            Transform.rotate(
              angle: qiblaPointerRotation,
              child: SvgPicture.asset(
                'assets/svg/qibla_pointer.svg',
                width: compassSize * 0.88,
                height: compassSize * 0.88,
                fit: BoxFit.contain,
              ),
            ),

            // 4. Center Gold Pivot Core
            Container(
              width: 18,
              height: 18,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                gradient: const RadialGradient(
                  colors: [
                    Color(0xFFF9E8B2),
                    Color(0xFFD4AF37),
                    Color(0xFF7A5C16),
                  ],
                ),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.4),
                    blurRadius: 6,
                    offset: const Offset(0, 2),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildMetadataPanel(double currentHeading) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20),
      child: Row(
        children: [
          // Degree Angle Card
          Expanded(
            child: _buildInfoCard(
              title: 'QIBLA BEARING',
              value: '${_qiblaBearing.toStringAsFixed(1)}°',
              subtitle: 'Heading: ${currentHeading.toStringAsFixed(0)}°',
              icon: Icons.explore_rounded,
              accentColor: const Color(0xFFD4AF37),
            ),
          ),
          const SizedBox(width: 12),

          // Distance to Kaaba Card
          Expanded(
            child: _buildInfoCard(
              title: 'DISTANCE',
              value: '${_distanceKm.toStringAsFixed(0)} km',
              subtitle: _locationName,
              icon: Icons.mosque_rounded,
              accentColor: const Color(0xFF48C78E),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildInfoCard({
    required String title,
    required String value,
    required String subtitle,
    required IconData icon,
    required Color accentColor,
  }) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      decoration: BoxDecoration(
        color: const Color(0xFF112D20).withOpacity(0.85),
        borderRadius: BorderRadius.circular(22),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.25),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(icon, size: 15, color: accentColor),
              const SizedBox(width: 6),
              Text(
                title,
                style: GoogleFonts.plusJakartaSans(
                  fontSize: 10,
                  fontWeight: FontWeight.w700,
                  letterSpacing: 1.0,
                  color: Colors.white60,
                ),
              ),
            ],
          ),
          const SizedBox(height: 6),
          Text(
            value,
            style: GoogleFonts.plusJakartaSans(
              fontSize: 20,
              fontWeight: FontWeight.bold,
              color: Colors.white,
            ),
          ),
          const SizedBox(height: 2),
          Text(
            subtitle,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: GoogleFonts.plusJakartaSans(
              fontSize: 11,
              fontWeight: FontWeight.w500,
              color: Colors.white54,
            ),
          ),
        ],
      ),
    );
  }
}
