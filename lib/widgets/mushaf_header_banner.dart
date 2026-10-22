import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../constants/app_colors.dart';

/// Helper to convert standard integers to Arabic-Indic digits (٠، ١، ٢، ٣، ٤، ٥، ٦، ٧، ٨، ٩)
String toArabicDigits(int number) {
  const digits = ['٠', '١', '٢', '٣', '٤', '٥', '٦', '٧', '٨', '٩'];
  return number.toString().split('').map((c) {
    final d = int.tryParse(c);
    return d != null ? digits[d] : c;
  }).join('');
}

/// Traditional Illuminated Surah Header Frame matching authentic Mushaf manuscripts
/// Displays the ornate floral/geometric frame with Surah Name, Ayah Count, Order, and Bismillah.
class MushafHeaderBanner extends StatelessWidget {
  final String surahNameArabic;
  final int numberOfAyahs;
  final int surahNumber;
  final bool showBismillah;

  const MushafHeaderBanner({
    super.key,
    required this.surahNameArabic,
    required this.numberOfAyahs,
    required this.surahNumber,
    this.showBismillah = true,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        // Ornate Surah Frame matching the user's reference mockup
        Container(
          margin: const EdgeInsets.symmetric(vertical: 4),
          height: 64,
          decoration: BoxDecoration(
            color: const Color(0xFFF9F7F1),
            borderRadius: BorderRadius.circular(10),
            border: Border.all(color: const Color(0xFF1B6B45), width: 2.2),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.06),
                blurRadius: 6,
                offset: const Offset(0, 2),
              ),
            ],
          ),
          child: Stack(
            children: [
              // Arabesque corner & background ornamentation
              Positioned.fill(
                child: CustomPaint(
                  painter: _HeaderFrameOrnamentPainter(),
                ),
              ),

              // Inner Cartridge with Header Content
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    // Left Medallion: Order / Surah Number (ترتيبها)
                    _buildMedallion(
                      label: 'تَرْتِيبُهَا',
                      value: toArabicDigits(surahNumber),
                    ),

                    // Center Cartridge: Surah Title (سورة ...)
                    Expanded(
                      child: Container(
                        margin: const EdgeInsets.symmetric(horizontal: 8),
                        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 2),
                        decoration: BoxDecoration(
                          color: Colors.white.withOpacity(0.92),
                          borderRadius: BorderRadius.circular(20),
                          border: Border.all(
                            color: const Color(0xFF2C7D54),
                            width: 1.4,
                          ),
                        ),
                        child: FittedBox(
                          fit: BoxFit.scaleDown,
                          child: Text(
                            'سُورَةُ $surahNameArabic',
                            textDirection: TextDirection.rtl,
                            style: GoogleFonts.amiri(
                              fontSize: 22,
                              fontWeight: FontWeight.bold,
                              color: const Color(0xFF111827),
                              height: 1.3,
                            ),
                          ),
                        ),
                      ),
                    ),

                    // Right Medallion: Ayah Count (آياتها)
                    _buildMedallion(
                      label: 'آيَاتُهَا',
                      value: toArabicDigits(numberOfAyahs),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),

        // Traditional Bismillah Calligraphy (Shown for all Surahs except At-Tawbah #9)
        if (showBismillah && surahNumber != 9) ...[
          const SizedBox(height: 10),
          Center(
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 4),
              child: Text(
                'بِسْمِ اللَّهِ الرَّحْمَٰنِ الرَّحِيمِ',
                textDirection: TextDirection.rtl,
                textAlign: TextAlign.center,
                style: GoogleFonts.amiri(
                  fontSize: 22,
                  fontWeight: FontWeight.bold,
                  color: const Color(0xFF1B242C),
                  height: 1.6,
                ),
              ),
            ),
          ),
          const SizedBox(height: 6),
        ],
      ],
    );
  }

  Widget _buildMedallion({required String label, required String value}) {
    return Container(
      width: 48,
      height: 48,
      decoration: BoxDecoration(
        color: const Color(0xFF23754E),
        shape: BoxShape.circle,
        border: Border.all(color: AppColors.accentGold, width: 1.4),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.12),
            blurRadius: 4,
            offset: const Offset(0, 1),
          ),
        ],
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Text(
            label,
            style: const TextStyle(
              fontSize: 7.5,
              fontWeight: FontWeight.bold,
              color: Colors.white,
              height: 1.1,
            ),
          ),
          Text(
            value,
            style: const TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.w800,
              color: AppColors.accentGold,
              height: 1.1,
            ),
          ),
        ],
      ),
    );
  }
}

/// Custom painter for the Islamic geometric and floral ornaments on the frame
class _HeaderFrameOrnamentPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final goldPaint = Paint()
      ..color = AppColors.accentGold.withOpacity(0.65)
      ..strokeWidth = 1.0
      ..style = PaintingStyle.stroke;

    final greenPaint = Paint()
      ..color = const Color(0xFF135836).withOpacity(0.15)
      ..style = PaintingStyle.fill;

    // Corner decorative brackets
    const bracketSize = 14.0;
    // Top-Left
    canvas.drawRect(const Rect.fromLTWH(2, 2, bracketSize, bracketSize), greenPaint);
    canvas.drawLine(const Offset(2, 2), const Offset(bracketSize, 2), goldPaint);
    canvas.drawLine(const Offset(2, 2), const Offset(2, bracketSize), goldPaint);

    // Top-Right
    canvas.drawRect(Rect.fromLTWH(size.width - bracketSize - 2, 2, bracketSize, bracketSize), greenPaint);
    canvas.drawLine(Offset(size.width - 2, 2), Offset(size.width - bracketSize, 2), goldPaint);
    canvas.drawLine(Offset(size.width - 2, 2), Offset(size.width - 2, bracketSize), goldPaint);

    // Bottom-Left
    canvas.drawRect(Rect.fromLTWH(2, size.height - bracketSize - 2, bracketSize, bracketSize), greenPaint);
    canvas.drawLine(Offset(2, size.height - 2), Offset(bracketSize, size.height - 2), goldPaint);
    canvas.drawLine(Offset(2, size.height - 2), Offset(2, size.height - bracketSize), goldPaint);

    // Bottom-Right
    canvas.drawRect(Rect.fromLTWH(size.width - bracketSize - 2, size.height - bracketSize - 2, bracketSize, bracketSize), greenPaint);
    canvas.drawLine(Offset(size.width - 2, size.height - 2), Offset(size.width - bracketSize, size.height - 2), goldPaint);
    canvas.drawLine(Offset(size.width - 2, size.height - 2), Offset(size.width - 2, size.height - bracketSize), goldPaint);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
