import 'dart:async';
import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:lottie/lottie.dart';
import '../constants/app_colors.dart';
import 'main_navigation_shell.dart';

class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen>
    with TickerProviderStateMixin {
  late final AnimationController _entranceController;
  late final AnimationController _progressController;
  late final AnimationController _shimmerController;

  late final Animation<double> _fadeAnimation;
  late final Animation<double> _scaleAnimation;
  late final Animation<double> _sayingFadeAnimation;
  late final Animation<Offset> _sayingSlideAnimation;

  Timer? _safetyTimer;
  bool _hasNavigated = false;

  @override
  void initState() {
    super.initState();

    // 1. Entrance animation (Logo + Title)
    _entranceController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1100),
    );

    _fadeAnimation = CurvedAnimation(
      parent: _entranceController,
      curve: Curves.easeIn,
    );

    _scaleAnimation = Tween<double>(begin: 0.88, end: 1.0).animate(
      CurvedAnimation(parent: _entranceController, curve: Curves.easeOutBack),
    );

    // 2. Progressive loading bar animation (0.0 to 1.0 over 2.6 seconds)
    _progressController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 2600),
    );

    // 3. Shimmer / progressive wave on the saying tag
    _shimmerController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1800),
    )..repeat();

    // 4. Saying tag entrance (slides up and fades in after logo lands)
    _sayingFadeAnimation = CurvedAnimation(
      parent: _progressController,
      curve: const Interval(0.15, 0.50, curve: Curves.easeOut),
    );

    _sayingSlideAnimation = Tween<Offset>(
      begin: const Offset(0, 0.35),
      end: Offset.zero,
    ).animate(
      CurvedAnimation(
        parent: _progressController,
        curve: const Interval(0.15, 0.50, curve: Curves.easeOutCubic),
      ),
    );

    _entranceController.forward();
    _progressController.forward();

    // Navigate to Main Navigation Shell upon completion
    _progressController.addStatusListener((status) {
      if (status == AnimationStatus.completed) {
        _navigateToHome();
      }
    });

    // 4-second safety fallback timer
    _safetyTimer = Timer(const Duration(milliseconds: 3800), () {
      _navigateToHome();
    });
  }

  void _navigateToHome() {
    if (_hasNavigated || !mounted) return;
    _hasNavigated = true;
    _safetyTimer?.cancel();

    Navigator.of(context).pushReplacement(
      PageRouteBuilder(
        pageBuilder: (_, __, ___) => const MainNavigationShell(),
        transitionsBuilder: (_, animation, __, child) {
          return FadeTransition(opacity: animation, child: child);
        },
        transitionDuration: const Duration(milliseconds: 550),
      ),
    );
  }

  @override
  void dispose() {
    _safetyTimer?.cancel();
    _entranceController.dispose();
    _progressController.dispose();
    _shimmerController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    const textSecondary = Color(0xFFC7DEC9);

    return Scaffold(
      backgroundColor: const Color(0xFF0D2818),
      body: Stack(
        children: [
          // Background radial golden glow
          Positioned.fill(
            child: Container(
              decoration: const BoxDecoration(
                gradient: RadialGradient(
                  center: Alignment(0, -0.15),
                  radius: 0.9,
                  colors: [
                    Color(0x38D4AF37),
                    Color(0x120D2818),
                    Color(0xFF0D2818),
                  ],
                  stops: [0.0, 0.55, 1.0],
                ),
              ),
            ),
          ),

          SafeArea(
            child: SizedBox.expand(
              child: Column(
                children: [
                  const Spacer(flex: 3),

                  // A. Main Center: Lottie Calligraphy Mandala, Official Logo, Title
                  FadeTransition(
                    opacity: _fadeAnimation,
                    child: ScaleTransition(
                      scale: _scaleAnimation,
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          // Stack of Lottie Calligraphy Mandala & Logo
                          SizedBox(
                            width: 170,
                            height: 170,
                            child: Stack(
                              alignment: Alignment.center,
                              children: [
                                // Lottie Calligraphy Mandala Animation
                                Lottie.asset(
                                  'assets/animations/splash_calligraphy.json',
                                  width: 170,
                                  height: 170,
                                  fit: BoxFit.contain,
                                  repeat: true,
                                  errorBuilder: (_, __, ___) =>
                                      const SizedBox.shrink(),
                                ),

                                // Centered App Logo
                                Container(
                                  width: 88,
                                  height: 88,
                                  decoration: BoxDecoration(
                                    borderRadius: BorderRadius.circular(22),
                                    boxShadow: const [
                                      BoxShadow(
                                        color: Color(0x60D4AF37),
                                        blurRadius: 30,
                                        spreadRadius: 2,
                                        offset: Offset(0, 6),
                                      ),
                                    ],
                                  ),
                                  child: ClipRRect(
                                    borderRadius: BorderRadius.circular(22),
                                    child: Image.asset(
                                      'assets/images/app_logo.png',
                                      fit: BoxFit.cover,
                                      errorBuilder: (_, __, ___) => Container(
                                        color: const Color(0xFF204B34),
                                        child: const Icon(
                                          Icons.menu_book_rounded,
                                          color: Color(0xFFF5CE63),
                                          size: 42,
                                        ),
                                      ),
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ),
                          const SizedBox(height: 18),

                          // Brand App Name
                          Text(
                            'MY QURAN',
                            style: GoogleFonts.plusJakartaSans(
                              fontSize: 26,
                              fontWeight: FontWeight.w800,
                              color: Colors.white,
                              letterSpacing: 2.2,
                            ),
                          ),
                          const SizedBox(height: 5),

                          // Arabic Calligraphy
                          Text(
                            'القرآن الكريم',
                            textDirection: TextDirection.rtl,
                            style: GoogleFonts.amiri(
                              fontSize: 22,
                              fontWeight: FontWeight.bold,
                              color: const Color(0xFFD4AF37),
                            ),
                          ),
                          const SizedBox(height: 5),

                          Text(
                            'DAILY DEVOTION & RECITATION',
                            style: GoogleFonts.plusJakartaSans(
                              fontSize: 11,
                              color: const Color(0xFFC7DEC9),
                              letterSpacing: 1.4,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),

              const Spacer(flex: 3),

              // B. Bottom Progressive Section: Animated Progress Bar & Saying Tag
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 32),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    // 1. Progressive Loading Bar
                    AnimatedBuilder(
                      animation: _progressController,
                      builder: (context, _) {
                        final progress = _progressController.value;
                        return Column(
                          children: [
                            Container(
                              height: 5,
                              width: 220,
                              decoration: BoxDecoration(
                                color: isDark
                                    ? Colors.white.withOpacity(0.08)
                                    : const Color(0xFFE2EBE5),
                                borderRadius: BorderRadius.circular(10),
                              ),
                              child: Align(
                                alignment: Alignment.centerLeft,
                                child: Container(
                                  width: 220 * progress,
                                  decoration: BoxDecoration(
                                    gradient: const LinearGradient(
                                      colors: [
                                        Color(0xFF204B34),
                                        Color(0xFF2E7D52),
                                        Color(0xFFF5CE63),
                                      ],
                                    ),
                                    borderRadius: BorderRadius.circular(10),
                                    boxShadow: [
                                      BoxShadow(
                                        color: AppColors.accentGold.withOpacity(0.40),
                                        blurRadius: 8,
                                        spreadRadius: 1,
                                      ),
                                    ],
                                  ),
                                ),
                              ),
                            ),
                          ],
                        );
                      },
                    ),

                    const SizedBox(height: 18),

                    // 2. Animated Progressive Saying Tag
                    SlideTransition(
                      position: _sayingSlideAnimation,
                      child: FadeTransition(
                        opacity: _sayingFadeAnimation,
                        child: AnimatedBuilder(
                          animation: _shimmerController,
                          builder: (context, child) {
                            final shimmerVal = _shimmerController.value;
                            return Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 16,
                                vertical: 10,
                              ),
                              decoration: BoxDecoration(
                                color: isDark
                                    ? const Color(0xFF132B20).withOpacity(0.85)
                                    : const Color(0xFFF2F7F4),
                                borderRadius: BorderRadius.circular(20),
                                boxShadow: [
                                  BoxShadow(
                                    color: Colors.black.withOpacity(isDark ? 0.25 : 0.05),
                                    blurRadius: 12,
                                    offset: const Offset(0, 4),
                                  ),
                                ],
                              ),
                              child: Column(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Row(
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      Icon(
                                        Icons.format_quote_rounded,
                                        size: 14,
                                        color: AppColors.accentGold.withOpacity(0.85),
                                      ),
                                      const SizedBox(width: 6),
                                      Flexible(
                                        child: Text(
                                          '«خَيْرُكُمْ مَنْ تَعَلَّمَ الْقُرْآنَ وَعَلَّمَهُ»',
                                          textDirection: TextDirection.rtl,
                                          style: GoogleFonts.amiri(
                                            fontSize: 14,
                                            fontWeight: FontWeight.bold,
                                            color: isDark
                                                ? AppColors.quranGold
                                                : const Color(0xFF204B34),
                                          ),
                                        ),
                                      ),
                                    ],
                                  ),
                                  const SizedBox(height: 3),
                                  Text(
                                    '“The best among you are those who learn the Quran and teach it”',
                                    textAlign: TextAlign.center,
                                    style: GoogleFonts.plusJakartaSans(
                                      fontSize: 11,
                                      fontStyle: FontStyle.italic,
                                      fontWeight: FontWeight.w500,
                                      color: textSecondary.withOpacity(0.85 + 0.15 * math.sin(shimmerVal * 2 * math.pi)),
                                    ),
                                  ),
                                ],
                              ),
                            );
                          },
                        ),
                      ),
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 24),
            ],
          ),
        ),
      ),
    ],
  ),
);
  }
}
