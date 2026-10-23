import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../constants/app_colors.dart';

class UstadhaAishaBubble extends StatefulWidget {
  final VoidCallback onTap;

  const UstadhaAishaBubble({
    super.key,
    required this.onTap,
  });

  @override
  State<UstadhaAishaBubble> createState() => _UstadhaAishaBubbleState();
}

class _UstadhaAishaBubbleState extends State<UstadhaAishaBubble> {
  bool _isDismissed = false;

  @override
  Widget build(BuildContext context) {
    if (_isDismissed) {
      // Show compact mini avatar button if bubble is closed
      return GestureDetector(
        onTap: () {
          setState(() => _isDismissed = false);
        },
        child: Container(
          width: 44,
          height: 44,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: AppColors.deepEmerald,
            border: Border.all(color: AppColors.quranGold, width: 1.5),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.3),
                blurRadius: 10,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          alignment: Alignment.center,
          child: const Icon(Icons.support_agent_rounded,
              color: AppColors.quranGold, size: 22),
        ),
      );
    }

    final isDark = Theme.of(context).brightness == Brightness.dark;
    final cardBg = isDark ? AppColors.midnightNavy : Colors.white;
    final textPrimary =
        isDark ? AppColors.darkTextPrimary : AppColors.lightTextPrimary;
    final textMuted =
        isDark ? AppColors.darkTextSecondary : AppColors.lightTextSecondary;

    return Row(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.end,
      children: [
        // Speech Bubble
        Flexible(
          child: GestureDetector(
            onTap: widget.onTap,
            child: Container(
              margin: const EdgeInsets.only(bottom: 6, right: 8),
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
              decoration: BoxDecoration(
                color: cardBg,
                borderRadius: const BorderRadius.only(
                  topLeft: Radius.circular(16),
                  topRight: Radius.circular(16),
                  bottomLeft: Radius.circular(16),
                  bottomRight: Radius.circular(4),
                ),
                border: Border.all(
                  color: isDark ? AppColors.darkBorder : AppColors.lightBorder,
                  width: 0.8,
                ),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(isDark ? 0.35 : 0.08),
                    blurRadius: 12,
                    offset: const Offset(0, 4),
                  ),
                ],
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Text(
                            'Ustadha Aisha',
                            style: GoogleFonts.plusJakartaSans(
                              fontSize: 11,
                              fontWeight: FontWeight.bold,
                              color: AppColors.quranGold,
                            ),
                          ),
                          const SizedBox(width: 4),
                          Container(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 4, vertical: 1),
                            decoration: BoxDecoration(
                              color: AppColors.deepEmerald.withOpacity(0.25),
                              borderRadius: BorderRadius.circular(4),
                            ),
                            child: Text(
                              'AI Guide',
                              style: GoogleFonts.plusJakartaSans(
                                fontSize: 9,
                                fontWeight: FontWeight.w600,
                                color: AppColors.quranGold,
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 2),
                      Text(
                        'Assalamu Alaikum! Need Quran guidance?',
                        style: GoogleFonts.plusJakartaSans(
                          fontSize: 11,
                          color: textPrimary,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(width: 8),
                  GestureDetector(
                    onTap: () {
                      setState(() => _isDismissed = true);
                    },
                    child:
                        Icon(Icons.close_rounded, size: 14, color: textMuted),
                  ),
                ],
              ),
            ),
          ),
        ),

        // Avatar Icon
        GestureDetector(
          onTap: widget.onTap,
          child: Container(
            width: 46,
            height: 46,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: AppColors.deepEmerald,
              border: Border.all(color: AppColors.quranGold, width: 2),
              boxShadow: [
                BoxShadow(
                  color: AppColors.quranGold.withOpacity(0.3),
                  blurRadius: 10,
                  offset: const Offset(0, 3),
                ),
              ],
            ),
            child: const Icon(Icons.person_pin_circle_rounded,
                color: AppColors.quranGold, size: 26),
          ),
        ),
      ],
    );
  }
}
