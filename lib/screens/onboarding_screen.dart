import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:google_fonts/google_fonts.dart';
import '../services/storage_service.dart';
import '../theme/tokens.dart';
import 'auth/login_screen.dart';
import 'auth/signup_screen.dart';
import 'main_navigation_shell.dart';

class OnboardingSlideData {
  final String title;
  final String subtitle;
  final String svgAsset;

  const OnboardingSlideData({
    required this.title,
    required this.subtitle,
    required this.svgAsset,
  });
}

class OnboardingScreen extends StatefulWidget {
  const OnboardingScreen({super.key});

  @override
  State<OnboardingScreen> createState() => _OnboardingScreenState();
}

class _OnboardingScreenState extends State<OnboardingScreen> {
  final PageController _pageController = PageController();
  final StorageService _storageService = StorageService();

  int _currentPage = 0;
  bool _isButtonPressed = false;

  static const List<OnboardingSlideData> _slides = [
    OnboardingSlideData(
      title: 'Recite & Reflect',
      subtitle:
          'Immerse in crystal-clear translations, colored Tajweed recitation, and daily Ayah reflections.',
      svgAsset: 'assets/svg/onboarding_slide1_quran_rehal.svg',
    ),
    OnboardingSlideData(
      title: 'Accurate Prayer Times',
      subtitle:
          'Real-time Adhan alerts, daily prayer streak tracker, and auto-adjusted prayer calculations.',
      svgAsset: 'assets/svg/onboarding_slide2_mosque_minarets.svg',
    ),
    OnboardingSlideData(
      title: 'Find Your Qibla',
      subtitle:
          'Smooth, real-time directional compass guiding you straight to the Holy Kaaba from anywhere.',
      svgAsset: 'assets/svg/onboarding_slide3_qibla_compass_kaaba.svg',
    ),
  ];

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  void _onPageChanged(int index) {
    setState(() => _currentPage = index);
  }

  void _onNext() {
    HapticFeedback.lightImpact();
    if (_currentPage < _slides.length - 1) {
      _pageController.animateToPage(
        _currentPage + 1,
        duration: const Duration(milliseconds: 450),
        curve: Curves.easeOutCubic,
      );
    } else {
      _navigateToSignUp();
    }
  }

  void _onBack() {
    HapticFeedback.lightImpact();
    if (_currentPage > 0) {
      _pageController.animateToPage(
        _currentPage - 1,
        duration: const Duration(milliseconds: 450),
        curve: Curves.easeOutCubic,
      );
    }
  }

  Future<void> _navigateToSignUp() async {
    await _storageService.setOnboardingCompleted(true);
    if (!mounted) return;
    Navigator.of(context).push(
      PageRouteBuilder(
        pageBuilder: (_, __, ___) => const SignUpScreen(),
        transitionsBuilder: (_, animation, __, child) =>
            FadeTransition(opacity: animation, child: child),
        transitionDuration: const Duration(milliseconds: 400),
      ),
    );
  }

  Future<void> _navigateToLogin() async {
    await _storageService.setOnboardingCompleted(true);
    if (!mounted) return;
    Navigator.of(context).push(
      PageRouteBuilder(
        pageBuilder: (_, __, ___) => const LoginScreen(),
        transitionsBuilder: (_, animation, __, child) =>
            FadeTransition(opacity: animation, child: child),
        transitionDuration: const Duration(milliseconds: 400),
      ),
    );
  }

  Future<void> _continueAsGuest() async {
    HapticFeedback.lightImpact();
    await _storageService.setOnboardingCompleted(true);
    if (!mounted) return;
    Navigator.of(context).pushReplacement(
      PageRouteBuilder(
        pageBuilder: (_, __, ___) => const MainNavigationShell(),
        transitionsBuilder: (_, animation, __, child) =>
            FadeTransition(opacity: animation, child: child),
        transitionDuration: const Duration(milliseconds: 500),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final isLastPage = _currentPage == _slides.length - 1;

    return Scaffold(
      backgroundColor: NoorColors.emeraldDeep,
      body: Stack(
        children: [
          // 1. Radial Emerald Gradient Background
          Container(
            decoration: const BoxDecoration(
              gradient: NoorGradients.emeraldRadial,
            ),
          ),

          // 2. Geometric Islamic Watermark Pattern
          Positioned.fill(
            child: IgnorePointer(
              child: CustomPaint(
                painter: IslamicPatternPainter(),
              ),
            ),
          ),

          // 3. Main Foreground Content
          SafeArea(
            child: Column(
              children: [
                // Top Bar: Back & Skip
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      // Back Button
                      AnimatedOpacity(
                        duration: const Duration(milliseconds: 250),
                        opacity: _currentPage == 0 ? 0.0 : 1.0,
                        child: IgnorePointer(
                          ignoring: _currentPage == 0,
                          child: GestureDetector(
                            onTap: _onBack,
                            child: Padding(
                              padding: const EdgeInsets.symmetric(vertical: 6, horizontal: 4),
                              child: Text(
                                '← Back',
                                style: GoogleFonts.manrope(
                                  fontSize: 14,
                                  fontWeight: FontWeight.w600,
                                  color: NoorColors.cream.withOpacity(0.7),
                                ),
                              ),
                            ),
                          ),
                        ),
                      ),

                      // Skip Button
                      GestureDetector(
                        onTap: _navigateToLogin,
                        child: Container(
                          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
                          decoration: BoxDecoration(
                            color: Colors.white.withOpacity(0.08),
                            borderRadius: NoorRadii.pill,
                          ),
                          child: Text(
                            'Skip',
                            style: GoogleFonts.manrope(
                              fontSize: 13.5,
                              fontWeight: FontWeight.w600,
                              color: NoorColors.goldLight,
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),

                // 3-Slide Pager Area
                Expanded(
                  child: PageView.builder(
                    controller: _pageController,
                    onPageChanged: _onPageChanged,
                    itemCount: _slides.length,
                    itemBuilder: (context, index) {
                      final slide = _slides[index];
                      return Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 28),
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            // SVG Vector Artwork
                            Expanded(
                              flex: 12,
                              child: Center(
                                child: SvgPicture.asset(
                                  slide.svgAsset,
                                  fit: BoxFit.contain,
                                  alignment: Alignment.center,
                                ),
                              ),
                            ),

                            const SizedBox(height: 16),

                            // Display Title (Cormorant Garamond)
                            Text(
                              slide.title,
                              textAlign: TextAlign.center,
                              style: GoogleFonts.cormorantGaramond(
                                fontSize: 32,
                                fontWeight: FontWeight.bold,
                                color: NoorColors.goldLight,
                                letterSpacing: 0.2,
                              ),
                            ),

                            const SizedBox(height: 10),

                            // Subtitle (Manrope)
                            Padding(
                              padding: const EdgeInsets.symmetric(horizontal: 8),
                              child: Text(
                                slide.subtitle,
                                textAlign: TextAlign.center,
                                style: GoogleFonts.manrope(
                                  fontSize: 14.5,
                                  fontWeight: FontWeight.w400,
                                  height: 1.5,
                                  color: NoorColors.cream.withOpacity(0.75),
                                ),
                              ),
                            ),

                            const Spacer(flex: 1),
                          ],
                        ),
                      );
                    },
                  ),
                ),

                // Bottom Section: Dots, Primary Action Button, and Footer
                Padding(
                  padding: const EdgeInsets.fromLTRB(28, 12, 28, 20),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      // Animated Dots
                      Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: List.generate(_slides.length, (index) {
                          final active = index == _currentPage;
                          return GestureDetector(
                            onTap: () {
                              _pageController.animateToPage(
                                index,
                                duration: const Duration(milliseconds: 400),
                                curve: Curves.easeOutCubic,
                              );
                            },
                            child: AnimatedContainer(
                              duration: const Duration(milliseconds: 300),
                              curve: Curves.easeOut,
                              margin: const EdgeInsets.symmetric(horizontal: 4),
                              width: active ? 24 : 8,
                              height: 8,
                              decoration: BoxDecoration(
                                color: active
                                    ? NoorColors.goldLight
                                    : NoorColors.cream.withOpacity(0.3),
                                borderRadius: NoorRadii.pill,
                              ),
                            ),
                          );
                        }),
                      ),

                      const SizedBox(height: 24),

                      // Primary Action Button (Continue / Get Started)
                      GestureDetector(
                        onTapDown: (_) => setState(() => _isButtonPressed = true),
                        onTapUp: (_) => setState(() => _isButtonPressed = false),
                        onTapCancel: () => setState(() => _isButtonPressed = false),
                        onTap: _onNext,
                        child: AnimatedScale(
                          scale: _isButtonPressed ? 0.97 : 1.0,
                          duration: const Duration(milliseconds: 150),
                          curve: Curves.easeOut,
                          child: Container(
                            height: 56,
                            width: double.infinity,
                            decoration: BoxDecoration(
                              gradient: NoorGradients.primaryButton,
                              borderRadius: NoorRadii.button,
                              border: Border.all(
                                color: NoorColors.gold,
                                width: 1.5,
                              ),
                              boxShadow: NoorShadows.primaryButton,
                            ),
                            alignment: Alignment.center,
                            child: Text(
                              isLastPage ? 'Get Started' : 'Continue',
                              style: GoogleFonts.manrope(
                                fontSize: 16,
                                fontWeight: FontWeight.bold,
                                color: NoorColors.cream,
                                letterSpacing: 0.3,
                              ),
                            ),
                          ),
                        ),
                      ),

                      const SizedBox(height: 16),

                      // Footer Navigation Link
                      Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Text(
                            'Already have an account? ',
                            style: GoogleFonts.manrope(
                              fontSize: 13.5,
                              color: NoorColors.cream.withOpacity(0.6),
                            ),
                          ),
                          GestureDetector(
                            onTap: _navigateToLogin,
                            child: Text(
                              'Sign In',
                              style: GoogleFonts.manrope(
                                fontSize: 13.5,
                                fontWeight: FontWeight.bold,
                                color: NoorColors.goldLight,
                              ),
                            ),
                          ),
                        ],
                      ),

                      const SizedBox(height: 6),

                      // Guest Mode Alternative
                      GestureDetector(
                        onTap: _continueAsGuest,
                        child: Padding(
                          padding: const EdgeInsets.symmetric(vertical: 4),
                          child: Text(
                            'Explore as Guest →',
                            style: GoogleFonts.manrope(
                              fontSize: 12.5,
                              fontWeight: FontWeight.w600,
                              color: NoorColors.cream.withOpacity(0.5),
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

// =============================================================================
// ISLAMIC PATTERN WATERMARK PAINTER
// =============================================================================
class IslamicPatternPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = const Color(0xFFF3C64F).withOpacity(0.05)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.0;

    const double step = 60.0;
    for (double x = 0; x < size.width + step; x += step) {
      for (double y = 0; y < size.height + step; y += step) {
        final path = Path();
        path.moveTo(x + 30, y);
        path.lineTo(x + 38.8, y + 21.2);
        path.lineTo(x + 60, y + 30);
        path.lineTo(x + 38.8, y + 38.8);
        path.lineTo(x + 30, y + 60);
        path.lineTo(x + 21.2, y + 38.8);
        path.lineTo(x, y + 30);
        path.lineTo(x + 21.2, y + 21.2);
        path.close();
        canvas.drawPath(path, paint);
      }
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
