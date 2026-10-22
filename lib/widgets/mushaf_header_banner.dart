import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

/// Helper to convert standard integers to Arabic-Indic digits (٠، ١، ٢، ٣، ٤، ٥، ٦، ٧، ٨، ٩)
String toArabicDigits(int number) {
  const digits = ['٠', '١', '٢', '٣', '٤', '٥', '٦', '٧', '٨', '٩'];
  return number.toString().split('').map((c) {
    final d = int.tryParse(c);
    return d != null ? digits[d] : c;
  }).join('');
}

/// Authentic Illuminated Surah Header Cartouche fitting naturally inside the Mushaf arch
/// Displays the Surah Title in classical Islamic calligraphy with refined ornamental framing,
/// avoiding oversized green balls, and positioning Bismillah appropriately.
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
    final isDark = Theme.of(context).brightness == Brightness.dark;

    // For Surah 1 (Al-Fatihah), Ayah 1 IS Bismillah. Do not show duplicate heading.
    // For Surah 9 (At-Tawbah), traditional Mushaf has no Bismillah.
    final bool shouldRenderBismillahHeading =
        showBismillah && surahNumber != 1 && surahNumber != 9;

    return Padding(
      padding: const EdgeInsets.only(top: 2, bottom: 4),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          // Elegant Illuminated Surah Title Cartouche (Traditional Mushaf Header)
          Container(
            constraints: const BoxConstraints(maxWidth: 240),
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 3),
            decoration: BoxDecoration(
              color: isDark
                  ? const Color(0xFF2A2315).withOpacity(0.9)
                  : const Color(0xFFFBF8EE),
              borderRadius: BorderRadius.circular(14),
              border: Border.all(
                color: const Color(0xFFD4AF37),
                width: 1.5,
              ),
              boxShadow: [
                BoxShadow(
                  color: const Color(0xFFD4AF37).withOpacity(0.18),
                  blurRadius: 6,
                  offset: const Offset(0, 2),
                ),
              ],
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                // Top inner decorative accent line
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Container(
                      width: 28,
                      height: 1,
                      color: const Color(0xFFD4AF37).withOpacity(0.6),
                    ),
                    const Padding(
                      padding: EdgeInsets.symmetric(horizontal: 6),
                      child: Icon(
                        Icons.auto_awesome,
                        size: 9,
                        color: Color(0xFFD4AF37),
                      ),
                    ),
                    Container(
                      width: 28,
                      height: 1,
                      color: const Color(0xFFD4AF37).withOpacity(0.6),
                    ),
                  ],
                ),

                const SizedBox(height: 1),

                // Surah Name in classical Arabic calligraphy
                FittedBox(
                  fit: BoxFit.scaleDown,
                  child: Text(
                    'سُورَةُ $surahNameArabic',
                    textDirection: TextDirection.rtl,
                    style: GoogleFonts.amiri(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                      color: isDark ? const Color(0xFFF5E6BE) : const Color(0xFF1B4D36),
                      height: 1.25,
                    ),
                  ),
                ),

                const SizedBox(height: 1),

                // Subtle metadata bar: Order & Ayah Count
                FittedBox(
                  fit: BoxFit.scaleDown,
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text(
                        'تَرْتِيبُهَا ${toArabicDigits(surahNumber)}',
                        textDirection: TextDirection.rtl,
                        style: GoogleFonts.amiri(
                          fontSize: 11,
                          color: isDark ? const Color(0xFFD4AF37) : const Color(0xFF6B5828),
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 6),
                        child: Text(
                          '•',
                          style: TextStyle(
                            fontSize: 10,
                            color: const Color(0xFFD4AF37).withOpacity(0.7),
                          ),
                        ),
                      ),
                      Text(
                        'آيَاتُهَا ${toArabicDigits(numberOfAyahs)}',
                        textDirection: TextDirection.rtl,
                        style: GoogleFonts.amiri(
                          fontSize: 11,
                          color: isDark ? const Color(0xFFD4AF37) : const Color(0xFF6B5828),
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),

          // Traditional Bismillah Calligraphy (Shown for Surahs 2-114, excluding 9)
          if (shouldRenderBismillahHeading) ...[
            const SizedBox(height: 6),
            Text(
              'بِسْمِ اللَّهِ الرَّحْمَٰنِ الرَّحِيمِ',
              textDirection: TextDirection.rtl,
              textAlign: TextAlign.center,
              style: GoogleFonts.amiri(
                fontSize: 19,
                fontWeight: FontWeight.bold,
                color: isDark ? const Color(0xFFE8D5A3) : const Color(0xFF1E242B),
                height: 1.4,
              ),
            ),
          ],
        ],
      ),
    );
  }
}
