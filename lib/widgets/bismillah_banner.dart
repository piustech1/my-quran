import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../constants/app_colors.dart';

class BismillahBanner extends StatelessWidget {
  final int surahNumber;

  const BismillahBanner({super.key, required this.surahNumber});

  @override
  Widget build(BuildContext context) {
    if (surahNumber == 9) return const SizedBox.shrink();

    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      child: Container(
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(24),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(isDark ? 0.40 : 0.14),
              blurRadius: 16,
              offset: const Offset(0, 5),
            ),
          ],
        ),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(24),
          child: Stack(
            children: [
              // Deep Emerald Gradient Surface (borderless, matching the main card)
              Container(
                decoration: const BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                    colors: [
                      Color(0xFF0F3E30),
                      Color(0xFF0A2920),
                    ],
                  ),
                ),
              ),

              // Corner Islamic Ornaments
              Positioned(
                top: 0,
                left: 0,
                width: 44,
                height: 32,
                child: IgnorePointer(
                  child: Opacity(
                    opacity: 0.35,
                    child: Transform.flip(
                      flipX: true,
                      flipY: true,
                      child: Image.asset(
                        'assets/corner_asset.png',
                        fit: BoxFit.fill,
                        errorBuilder: (_, __, ___) => const SizedBox.shrink(),
                      ),
                    ),
                  ),
                ),
              ),
              Positioned(
                top: 0,
                right: 0,
                width: 44,
                height: 32,
                child: IgnorePointer(
                  child: Opacity(
                    opacity: 0.35,
                    child: Transform.flip(
                      flipY: true,
                      child: Image.asset(
                        'assets/corner_asset.png',
                        fit: BoxFit.fill,
                        errorBuilder: (_, __, ___) => const SizedBox.shrink(),
                      ),
                    ),
                  ),
                ),
              ),
              Positioned(
                bottom: 0,
                left: 0,
                width: 44,
                height: 32,
                child: IgnorePointer(
                  child: Opacity(
                    opacity: 0.35,
                    child: Transform.flip(
                      flipX: true,
                      child: Image.asset(
                        'assets/corner_asset.png',
                        fit: BoxFit.fill,
                        errorBuilder: (_, __, ___) => const SizedBox.shrink(),
                      ),
                    ),
                  ),
                ),
              ),
              Positioned(
                bottom: 0,
                right: 0,
                width: 44,
                height: 32,
                child: IgnorePointer(
                  child: Opacity(
                    opacity: 0.35,
                    child: Image.asset(
                      'assets/corner_asset.png',
                      fit: BoxFit.fill,
                      errorBuilder: (_, __, ___) => const SizedBox.shrink(),
                    ),
                  ),
                ),
              ),

              // Content: Gold Arabic Calligraphy + Bold White English Subtitle
              Padding(
                padding:
                    const EdgeInsets.symmetric(vertical: 22, horizontal: 20),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      "بِسۡمِ ٱللَّهِ ٱلرَّحۡمَـٰنِ ٱلرَّحِیمِ",
                      textAlign: TextAlign.center,
                      textDirection: TextDirection.rtl,
                      style: GoogleFonts.amiri(
                        fontSize: 27,
                        fontWeight: FontWeight.bold,
                        color: AppColors.quranGold,
                        height: 1.8,
                        shadows: const [
                          Shadow(
                            color: Color(0x60000000),
                            blurRadius: 6,
                            offset: Offset(0, 1),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 6),
                    Text(
                      "In the name of God, the Lord of Mercy, the Giver of Mercy",
                      textAlign: TextAlign.center,
                      style: GoogleFonts.plusJakartaSans(
                        fontSize: 12.5,
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                        letterSpacing: 0.3,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
