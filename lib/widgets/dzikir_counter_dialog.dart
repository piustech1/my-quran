import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
import '../constants/app_colors.dart';

class DzikirCounterDialog extends StatefulWidget {
  const DzikirCounterDialog({super.key});

  @override
  State<DzikirCounterDialog> createState() => _DzikirCounterDialogState();
}

class _DzikirCounterDialogState extends State<DzikirCounterDialog> {
  int _counter = 0;
  final int _target = 33;
  int _phraseIndex = 0;

  final List<Map<String, String>> _phrases = [
    {'ar': 'سُبْحَانَ اللَّهِ', 'en': 'SubhanAllah (Glory be to Allah)'},
    {'ar': 'الْحَمْدُ لِلَّهِ', 'en': 'Alhamdulillah (Praise be to Allah)'},
    {'ar': 'اللَّهُ أَكْبَرُ', 'en': 'Allahu Akbar (Allah is the Greatest)'},
    {'ar': 'لَا إِلَٰهَ إِلَّا اللَّهُ', 'en': 'La ilaha illallah (None worthy of worship but Allah)'},
    {'ar': 'أَسْتَغْفِرُ اللَّهَ', 'en': 'Astaghfirullah (I seek forgiveness from Allah)'},
  ];

  void _increment() {
    HapticFeedback.lightImpact();
    setState(() {
      _counter++;
      if (_counter >= _target) {
        _counter = 0;
        _phraseIndex = (_phraseIndex + 1) % _phrases.length;
      }
    });
  }

  void _reset() {
    setState(() {
      _counter = 0;
    });
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final bg = isDark ? AppColors.darkSurface : AppColors.lightSurface;
    final textPrimary = isDark ? AppColors.darkTextPrimary : AppColors.lightTextPrimary;
    final textSecondary = isDark ? AppColors.darkTextSecondary : AppColors.lightTextSecondary;

    final currentPhrase = _phrases[_phraseIndex];

    return Dialog(
      backgroundColor: bg,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(28)),
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Row(
                  children: [
                    const Icon(Icons.circle_outlined, color: AppColors.accentGold, size: 20),
                    const SizedBox(width: 8),
                    Text(
                      'Dzikir & Tasbih',
                      style: GoogleFonts.plusJakartaSans(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        color: textPrimary,
                      ),
                    ),
                  ],
                ),
                IconButton(
                  icon: const Icon(Icons.close_rounded, size: 20),
                  color: textSecondary,
                  onPressed: () => Navigator.of(context).pop(),
                ),
              ],
            ),
            const SizedBox(height: 16),

            // Arabic Phrase
            Text(
              currentPhrase['ar']!,
              textDirection: TextDirection.rtl,
              textAlign: TextAlign.center,
              style: GoogleFonts.amiri(
                fontSize: 26,
                fontWeight: FontWeight.bold,
                color: AppColors.accentGold,
              ),
            ),
            const SizedBox(height: 6),
            Text(
              currentPhrase['en']!,
              textAlign: TextAlign.center,
              style: GoogleFonts.plusJakartaSans(
                fontSize: 12,
                color: textSecondary,
              ),
            ),
            const SizedBox(height: 24),

            // Big Tap Circle Counter
            GestureDetector(
              onTap: _increment,
              child: Container(
                width: 140,
                height: 140,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: AppColors.accentGold.withOpacity(0.12),
                  border: Border.all(
                    color: AppColors.accentGold,
                    width: 3.5,
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: AppColors.accentGold.withOpacity(0.15),
                      blurRadius: 20,
                      spreadRadius: 2,
                    ),
                  ],
                ),
                alignment: Alignment.center,
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text(
                      '$_counter',
                      style: GoogleFonts.plusJakartaSans(
                        fontSize: 42,
                        fontWeight: FontWeight.bold,
                        color: textPrimary,
                      ),
                    ),
                    Text(
                      '/ $_target',
                      style: GoogleFonts.plusJakartaSans(
                        fontSize: 12,
                        color: textSecondary,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 18),

            Text(
              'Tap circle to count',
              style: GoogleFonts.plusJakartaSans(
                fontSize: 12,
                color: textSecondary,
              ),
            ),
            const SizedBox(height: 12),

            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                TextButton.icon(
                  icon: const Icon(Icons.refresh_rounded, size: 16, color: AppColors.accentGold),
                  label: Text(
                    'Reset Counter',
                    style: GoogleFonts.plusJakartaSans(
                      fontSize: 13,
                      fontWeight: FontWeight.w600,
                      color: AppColors.accentGold,
                    ),
                  ),
                  onPressed: _reset,
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
