import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../constants/app_colors.dart';
import 'glass_card.dart';

class BismillahBanner extends StatelessWidget {
  final int surahNumber;

  const BismillahBanner({super.key, required this.surahNumber});

  @override
  Widget build(BuildContext context) {
    // Surah 9 (At-Tawbah) does not start with Bismillah
    if (surahNumber == 9) return const SizedBox.shrink();

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      child: GlassCard(
        borderRadius: 24,
        padding: const EdgeInsets.symmetric(vertical: 20, horizontal: 16),
        color: AppColors.primarySurface.withOpacity(0.4),
        borderColor: AppColors.gold.withOpacity(0.35),
        child: Column(
          children: [
            Text(
              "بِسۡمِ ٱللَّهِ ٱلرَّحۡمَـٰنِ ٱلرَّحِیمِ",
              textAlign: TextAlign.center,
              textDirection: TextDirection.rtl,
              style: GoogleFonts.amiri(
                fontSize: 26,
                fontWeight: FontWeight.bold,
                color: AppColors.gold,
                height: 1.8,
              ),
            ),
            const SizedBox(height: 6),
            Text(
              "In the name of God, the Lord of Mercy, the Giver of Mercy",
              textAlign: TextAlign.center,
              style: GoogleFonts.plusJakartaSans(
                fontSize: 12,
                color: AppColors.textMuted,
                letterSpacing: 0.3,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
