import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../constants/app_colors.dart';
import '../services/theme_service.dart';
import '../widgets/curved_header.dart';
import '../widgets/dzikir_counter_dialog.dart';
import 'quran_library_screen.dart';

class HomeDashboardScreen extends StatefulWidget {
  const HomeDashboardScreen({super.key});

  @override
  State<HomeDashboardScreen> createState() => _HomeDashboardScreenState();
}

class _HomeDashboardScreenState extends State<HomeDashboardScreen> {
  final ThemeService _themeService = ThemeService();
  int _selectedNavIndex = 0;

  void _showZakatDialog() {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final bg = isDark ? AppColors.darkSurface : AppColors.lightSurface;
    final textPrimary = isDark ? AppColors.darkTextPrimary : AppColors.lightTextPrimary;
    final textSecondary = isDark ? AppColors.darkTextSecondary : AppColors.lightTextSecondary;

    final controller = TextEditingController();
    double zakatAmount = 0.0;

    showDialog(
      context: context,
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setDialogState) {
            return Dialog(
              backgroundColor: bg,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
              child: Padding(
                padding: const EdgeInsets.all(24),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Row(
                          children: [
                            const Icon(Icons.volunteer_activism_rounded, color: AppColors.accentGold, size: 22),
                            const SizedBox(width: 8),
                            Text(
                              'Zakat Calculator',
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
                    const SizedBox(height: 12),
                    Text(
                      'Enter your total eligible wealth/savings to calculate the 2.5% annual Zakat obligation.',
                      style: GoogleFonts.plusJakartaSans(fontSize: 12, color: textSecondary),
                    ),
                    const SizedBox(height: 16),
                    TextField(
                      controller: controller,
                      keyboardType: const TextInputType.numberWithOptions(decimal: true),
                      style: GoogleFonts.plusJakartaSans(color: textPrimary, fontWeight: FontWeight.bold),
                      decoration: InputDecoration(
                        hintText: 'Enter amount (e.g. 1000)',
                        hintStyle: GoogleFonts.plusJakartaSans(color: textSecondary),
                        prefixText: '\$ ',
                        prefixStyle: GoogleFonts.plusJakartaSans(color: AppColors.accentGold, fontWeight: FontWeight.bold),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(14),
                          borderSide: BorderSide(color: isDark ? AppColors.darkBorder : AppColors.lightBorder),
                        ),
                        focusedBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(14),
                          borderSide: const BorderSide(color: AppColors.accentGold, width: 2),
                        ),
                      ),
                      onChanged: (val) {
                        final parsed = double.tryParse(val) ?? 0.0;
                        setDialogState(() {
                          zakatAmount = parsed * 0.025;
                        });
                      },
                    ),
                    const SizedBox(height: 20),
                    Container(
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: AppColors.accentGold.withOpacity(0.15),
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(color: AppColors.accentGold.withOpacity(0.4)),
                      ),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(
                            'Zakat Due (2.5%):',
                            style: GoogleFonts.plusJakartaSans(
                              fontSize: 13,
                              fontWeight: FontWeight.w600,
                              color: textPrimary,
                            ),
                          ),
                          Text(
                            '\$${zakatAmount.toStringAsFixed(2)}',
                            style: GoogleFonts.plusJakartaSans(
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                              color: AppColors.accentGold,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            );
          },
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final bg = isDark ? AppColors.darkBackground : AppColors.lightBackground;
    final cardBg = isDark ? AppColors.darkSurface : AppColors.lightSurface;
    final border = isDark ? AppColors.darkBorder : AppColors.lightBorder;
    final textPrimary = isDark ? AppColors.darkTextPrimary : AppColors.lightTextPrimary;
    final textSecondary = isDark ? AppColors.darkTextSecondary : AppColors.lightTextSecondary;

    return Scaffold(
      backgroundColor: bg,
      body: Column(
        children: [
          // 1. Curved Downward Solid Forest Green Header (no outlines)
          CurvedDownwardHeader(
            curveDepth: 24.0,
            backgroundColor: AppColors.forestGreen,
            padding: EdgeInsets.fromLTRB(20, MediaQuery.of(context).padding.top + 10, 20, 24),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Row(
                  children: [
                    // Profile Avatar
                    Container(
                      width: 48,
                      height: 48,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: Colors.white.withOpacity(0.15),
                      ),
                      child: const Icon(Icons.person_rounded, color: AppColors.warmGold, size: 26),
                    ),
                    const SizedBox(width: 12),

                    // Greeting "Assalamu alaikum, Aminah ✎"
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(
                          "Assalamu alaikum,",
                          style: GoogleFonts.plusJakartaSans(
                            fontSize: 12,
                            color: AppColors.warmGold,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        Row(
                          children: [
                            Text(
                              "Aminah",
                              style: GoogleFonts.plusJakartaSans(
                                fontSize: 18,
                                fontWeight: FontWeight.bold,
                                color: Colors.white,
                              ),
                            ),
                            const SizedBox(width: 5),
                            const Icon(Icons.edit_outlined, size: 14, color: AppColors.warmGold),
                          ],
                        ),
                      ],
                    ),
                  ],
                ),

                // Actions: Notification Bell + Theme Toggle Button
                Row(
                  children: [
                    Container(
                      width: 42,
                      height: 42,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: Colors.white.withOpacity(0.12),
                      ),
                      alignment: Alignment.center,
                      child: const Icon(
                        Icons.notifications_outlined,
                        color: Colors.white,
                        size: 20,
                      ),
                    ),
                    const SizedBox(width: 8),
                    GestureDetector(
                      onTap: () => _themeService.toggleTheme(),
                      child: Container(
                        width: 42,
                        height: 42,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          color: AppColors.warmGold.withOpacity(0.25),
                        ),
                        alignment: Alignment.center,
                        child: Icon(
                          isDark ? Icons.dark_mode_rounded : Icons.light_mode_rounded,
                          color: AppColors.warmGold,
                          size: 20,
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),

          // Scrollable Body Content
          Expanded(
            child: SingleChildScrollView(
              physics: const BouncingScrollPhysics(),
              padding: const EdgeInsets.fromLTRB(20, 14, 20, 24),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  // 2. Prayer Card ("DHUHR 12:16 PM" with Sun/Cloud Illustration & Weather)
                  Container(
                    height: 165,
                    padding: const EdgeInsets.symmetric(horizontal: 22, vertical: 18),
                    decoration: BoxDecoration(
                      color: isDark ? AppColors.darkSurface : AppColors.lightSurface,
                      borderRadius: BorderRadius.circular(28),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withOpacity(isDark ? 0.25 : 0.05),
                          blurRadius: 18,
                          offset: const Offset(0, 6),
                        ),
                      ],
                    ),
                    child: Row(
                  children: [
                    // Prayer Time Details
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Text(
                            'D H U H R',
                            style: GoogleFonts.plusJakartaSans(
                              fontSize: 12,
                              fontWeight: FontWeight.bold,
                              letterSpacing: 3.0,
                              color: AppColors.accentGold,
                            ),
                          ),
                          const SizedBox(height: 6),
                          Text(
                            '12:16 PM',
                            style: GoogleFonts.plusJakartaSans(
                              fontSize: 30,
                              fontWeight: FontWeight.w800,
                              color: textPrimary,
                            ),
                          ),
                          const SizedBox(height: 6),
                          Text(
                            'Now 11:20:51 PM',
                            style: GoogleFonts.plusJakartaSans(
                              fontSize: 12,
                              color: textSecondary,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                          Text(
                            'Oct 22, 2026',
                            style: GoogleFonts.plusJakartaSans(
                              fontSize: 11,
                              color: textSecondary,
                            ),
                          ),
                        ],
                      ),
                    ),

                    // Sun Behind Cloud Illustration & Weather info (matching Image 2)
                    Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      crossAxisAlignment: CrossAxisAlignment.end,
                      children: [
                        _buildSunCloudIllustration(),
                        const SizedBox(height: 4),
                        Text(
                          '27°',
                          style: GoogleFonts.plusJakartaSans(
                            fontSize: 22,
                            fontWeight: FontWeight.bold,
                            color: textPrimary,
                          ),
                        ),
                        Text(
                          'Partly cloudy • Kampala',
                          style: GoogleFonts.plusJakartaSans(
                            fontSize: 11,
                            color: textSecondary,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 22),

              // 3. Quick Action Cards: Qur'an, Zakat, Dzikir (Exact 3-card squircle row matching Image 2)
              Row(
                children: [
                  _buildQuickActionItem(
                    label: "Qur'an",
                    icon: Icons.menu_book_rounded,
                    isDark: isDark,
                    cardBg: cardBg,
                    border: border,
                    textPrimary: textPrimary,
                    onTap: () {
                      Navigator.of(context).push(
                        MaterialPageRoute(builder: (_) => const QuranLibraryScreen()),
                      );
                    },
                  ),
                  const SizedBox(width: 14),
                  _buildQuickActionItem(
                    label: "Zakat",
                    icon: Icons.all_inbox_rounded,
                    isDark: isDark,
                    cardBg: cardBg,
                    border: border,
                    textPrimary: textPrimary,
                    onTap: _showZakatDialog,
                  ),
                  const SizedBox(width: 14),
                  _buildQuickActionItem(
                    label: "Dzikir",
                    icon: Icons.nightlight_round,
                    subtitle: "0 / 33",
                    isDark: isDark,
                    cardBg: cardBg,
                    border: border,
                    textPrimary: textPrimary,
                    onTap: () {
                      showDialog(
                        context: context,
                        builder: (_) => const DzikirCounterDialog(),
                      );
                    },
                  ),
                ],
              ),
              const SizedBox(height: 26),

              // 4. "Featured" Section
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    'Featured',
                    style: GoogleFonts.plusJakartaSans(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: textPrimary,
                    ),
                  ),
                  TextButton(
                    onPressed: () {
                      Navigator.of(context).push(
                        MaterialPageRoute(builder: (_) => const QuranLibraryScreen()),
                      );
                    },
                    child: Text(
                      'View all',
                      style: GoogleFonts.plusJakartaSans(
                        fontSize: 13,
                        fontWeight: FontWeight.w600,
                        color: textSecondary,
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 8),

              // 5. Featured Card: Ramadan Study / Daily Dakwah (Exact proportions of Image 2)
              Container(
                height: 175,
                padding: const EdgeInsets.all(22),
                decoration: BoxDecoration(
                  color: AppColors.accentGold,
                  borderRadius: BorderRadius.circular(28),
                  boxShadow: [
                    BoxShadow(
                      color: AppColors.accentGold.withOpacity(0.38),
                      blurRadius: 20,
                      offset: const Offset(0, 6),
                    ),
                  ],
                ),
                child: Row(
                  children: [
                    // Text Column
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                            decoration: BoxDecoration(
                              color: const Color(0xFF38290B).withOpacity(0.18),
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: Text(
                              'DAILY DAKWAH',
                              style: GoogleFonts.plusJakartaSans(
                                fontSize: 10,
                                fontWeight: FontWeight.bold,
                                letterSpacing: 0.8,
                                color: const Color(0xFF38290B),
                              ),
                            ),
                          ),
                          const SizedBox(height: 8),
                          Text(
                            'Ramadan Study',
                            style: GoogleFonts.plusJakartaSans(
                              fontSize: 22,
                              fontWeight: FontWeight.w800,
                              color: const Color(0xFF14171A),
                              height: 1.15,
                            ),
                          ),
                          const SizedBox(height: 12),
                          Row(
                            children: [
                              Container(
                                width: 28,
                                height: 28,
                                decoration: BoxDecoration(
                                  shape: BoxShape.circle,
                                  color: const Color(0xFF281E08),
                                  border: Border.all(color: Colors.white, width: 1.2),
                                ),
                                child: const Icon(Icons.person, size: 16, color: AppColors.accentGold),
                              ),
                              const SizedBox(width: 8),
                              Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    'With',
                                    style: GoogleFonts.plusJakartaSans(
                                      fontSize: 10,
                                      fontWeight: FontWeight.w500,
                                      color: const Color(0xFF4A3812),
                                    ),
                                  ),
                                  Text(
                                    'Ustd. Hanan',
                                    style: GoogleFonts.plusJakartaSans(
                                      fontSize: 12,
                                      fontWeight: FontWeight.bold,
                                      color: const Color(0xFF14171A),
                                    ),
                                  ),
                                ],
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),

                    // 3D Calendar Graphic from user assets
                    _build3DCalendarGraphic(),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    ],
  ),

  // Custom Floating Bottom Navigation Bar matching mockup
  bottomNavigationBar: _buildBottomNav(isDark, cardBg, border, textPrimary, textSecondary),
);
  }

  Widget _buildQuickActionItem({
    required String label,
    required IconData icon,
    String? subtitle,
    required bool isDark,
    required Color cardBg,
    required Color border,
    required Color textPrimary,
    required VoidCallback onTap,
  }) {
    return Expanded(
      child: GestureDetector(
        onTap: onTap,
        child: Container(
          height: 122,
          padding: const EdgeInsets.symmetric(vertical: 14),
          decoration: BoxDecoration(
            color: cardBg,
            borderRadius: BorderRadius.circular(24),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(isDark ? 0.25 : 0.04),
                blurRadius: 12,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Container(
                width: 46,
                height: 46,
                decoration: const BoxDecoration(
                  shape: BoxShape.circle,
                  color: AppColors.accentGold,
                ),
                child: Icon(icon, color: const Color(0xFF14171A), size: 22),
              ),
              const SizedBox(height: 8),
              Text(
                label,
                style: GoogleFonts.plusJakartaSans(
                  fontSize: 13,
                  fontWeight: FontWeight.bold,
                  color: textPrimary,
                ),
              ),
              if (subtitle != null) ...[
                const SizedBox(height: 2),
                Text(
                  subtitle,
                  style: GoogleFonts.plusJakartaSans(
                    fontSize: 11,
                    fontWeight: FontWeight.w600,
                    color: AppColors.accentGoldDark,
                  ),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildSunCloudIllustration() {
    return Image.asset(
      'assets/sun asset.png',
      width: 76,
      height: 76,
      fit: BoxFit.contain,
      errorBuilder: (context, error, stackTrace) => const SizedBox(
        width: 76,
        height: 76,
        child: Icon(Icons.wb_sunny_rounded, color: Color(0xFFFBBF24), size: 40),
      ),
    );
  }

  Widget _build3DCalendarGraphic() {
    return Image.asset(
      'assets/calender assets.png',
      width: 120,
      height: 120,
      fit: BoxFit.contain,
      errorBuilder: (context, error, stackTrace) => const SizedBox(
        width: 120,
        height: 120,
        child: Icon(Icons.calendar_month_rounded, color: Colors.white, size: 50),
      ),
    );
  }

  Widget _buildBottomNav(
    bool isDark,
    Color cardBg,
    Color border,
    Color textPrimary,
    Color textSecondary,
  ) {
    return Container(
      height: 72,
      margin: const EdgeInsets.fromLTRB(20, 0, 20, 16),
      decoration: BoxDecoration(
        color: cardBg,
        borderRadius: BorderRadius.circular(28),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(isDark ? 0.35 : 0.08),
            blurRadius: 20,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceAround,
        children: [
          // Home Tab
          IconButton(
            icon: Icon(
              Icons.home_filled,
              color: _selectedNavIndex == 0 ? AppColors.accentGold : textSecondary,
              size: 26,
            ),
            onPressed: () => setState(() => _selectedNavIndex = 0),
          ),

          // Center Floating Diamond/Squircle Search Button (Mockup)
          GestureDetector(
            onTap: () {
              Navigator.of(context).push(
                MaterialPageRoute(builder: (_) => const QuranLibraryScreen()),
              );
            },
            child: Transform.rotate(
              angle: 0.785398, // 45 degrees
              child: Container(
                width: 46,
                height: 46,
                decoration: BoxDecoration(
                  color: AppColors.accentGold,
                  borderRadius: BorderRadius.circular(14),
                  boxShadow: [
                    BoxShadow(
                      color: AppColors.accentGold.withOpacity(0.4),
                      blurRadius: 10,
                      offset: const Offset(0, 3),
                    ),
                  ],
                ),
                child: Transform.rotate(
                  angle: -0.785398,
                  child: const Icon(
                    Icons.search_rounded,
                    color: AppColors.lightPillButton,
                    size: 24,
                  ),
                ),
              ),
            ),
          ),

          // Quran Library / Bookmarks Tab
          IconButton(
            icon: Icon(
              Icons.menu_book_rounded,
              color: _selectedNavIndex == 1 ? AppColors.accentGold : textSecondary,
              size: 26,
            ),
            onPressed: () {
              setState(() => _selectedNavIndex = 1);
              Navigator.of(context).push(
                MaterialPageRoute(builder: (_) => const QuranLibraryScreen()),
              );
            },
          ),
        ],
      ),
    );
  }
}
