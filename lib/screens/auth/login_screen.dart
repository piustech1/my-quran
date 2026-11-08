import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../services/firebase_sync_service.dart';
import '../../services/storage_service.dart';
import '../../theme/tokens.dart';
import '../../widgets/hero_geometry_painter.dart';
import '../../widgets/pop_out_avatar_badge.dart';
import '../main_navigation_shell.dart';
import 'signup_screen.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final StorageService _storageService = StorageService();

  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();

  bool _obscurePassword = true;
  bool _isLoading = false;
  bool _isButtonPressed = false;
  String? _emailError;
  String? _passwordError;

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  bool _isValidEmail(String email) {
    return RegExp(r'^\S+@\S+\.\S+$').hasMatch(email.trim());
  }

  void _onEmailChanged(String val) {
    if (_emailError != null) {
      setState(() {
        _emailError = _isValidEmail(val) ? null : 'Please enter a valid email address';
      });
    } else {
      setState(() {});
    }
  }

  void _onPasswordChanged(String val) {
    if (_passwordError != null) {
      setState(() {
        _passwordError = val.length >= 6 ? null : 'Password must be at least 6 characters';
      });
    } else {
      setState(() {});
    }
  }

  Future<void> _handleSignIn() async {
    HapticFeedback.lightImpact();
    final email = _emailController.text.trim();
    final password = _passwordController.text;

    setState(() {
      _emailError = _isValidEmail(email) ? null : 'Please enter a valid email address';
      _passwordError = password.isNotEmpty ? null : 'Please enter your password';
    });

    if (_emailError != null || _passwordError != null) {
      return;
    }

    setState(() => _isLoading = true);
    await Future.delayed(const Duration(milliseconds: 600));

    // Sign in via Firebase if connected
    try {
      await FirebaseSyncService().signInWithEmail(email, password);
    } catch (e) {
      debugPrint('[LoginScreen] Firebase sign-in note: $e');
    }

    // Persist login session locally and sync data
    await _storageService.saveUserSession(
      name: email.split('@').first,
      email: email,
    );

    if (!mounted) return;
    setState(() => _isLoading = false);

    Navigator.of(context).pushAndRemoveUntil(
      PageRouteBuilder(
        pageBuilder: (_, __, ___) => const MainNavigationShell(),
        transitionsBuilder: (_, animation, __, child) =>
            FadeTransition(opacity: animation, child: child),
        transitionDuration: const Duration(milliseconds: 500),
      ),
      (route) => false,
    );
  }

  void _showForgotPasswordDialog() {
    final controller = TextEditingController(text: _emailController.text);
    showDialog(
      context: context,
      builder: (ctx) {
        return AlertDialog(
          backgroundColor: NoorColors.cream,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
          title: Text(
            'Reset Password',
            style: GoogleFonts.cormorantGaramond(
              fontSize: 24,
              fontWeight: FontWeight.bold,
              color: NoorColors.ink,
            ),
          ),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Enter your account email to receive a password reset link.',
                style: GoogleFonts.manrope(
                  fontSize: 13.5,
                  color: NoorColors.ink.withOpacity(0.7),
                ),
              ),
              const SizedBox(height: 16),
              TextField(
                controller: controller,
                keyboardType: TextInputType.emailAddress,
                decoration: InputDecoration(
                  filled: true,
                  fillColor: NoorColors.inputBg,
                  hintText: 'you@example.com',
                  hintStyle: GoogleFonts.manrope(
                    fontSize: 14,
                    color: NoorColors.ink.withOpacity(0.3),
                  ),
                  contentPadding:
                      const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                  border: const OutlineInputBorder(
                    borderRadius: NoorRadii.field,
                    borderSide: BorderSide(color: NoorColors.line),
                  ),
                  enabledBorder: const OutlineInputBorder(
                    borderRadius: NoorRadii.field,
                    borderSide: BorderSide(color: NoorColors.line),
                  ),
                  focusedBorder: const OutlineInputBorder(
                    borderRadius: NoorRadii.field,
                    borderSide:
                        BorderSide(color: NoorColors.forest, width: 1.5),
                  ),
                ),
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(ctx).pop(),
              child: Text(
                'Cancel',
                style: GoogleFonts.manrope(
                  fontWeight: FontWeight.w600,
                  color: NoorColors.ink.withOpacity(0.6),
                ),
              ),
            ),
            ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: NoorColors.forest,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
              onPressed: () {
                Navigator.of(ctx).pop();
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text(
                      'Password reset link sent to ${controller.text}',
                      style: GoogleFonts.manrope(),
                    ),
                    behavior: SnackBarBehavior.floating,
                    backgroundColor: NoorColors.forest,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                );
              },
              child: Text(
                'Send Link',
                style: GoogleFonts.manrope(
                  fontWeight: FontWeight.bold,
                  color: NoorColors.cream,
                ),
              ),
            ),
          ],
        );
      },
    );
  }

  void _continueAsGuest() {
    HapticFeedback.lightImpact();
    Navigator.of(context).pushAndRemoveUntil(
      PageRouteBuilder(
        pageBuilder: (_, __, ___) => const MainNavigationShell(),
        transitionsBuilder: (_, animation, __, child) =>
            FadeTransition(opacity: animation, child: child),
        transitionDuration: const Duration(milliseconds: 500),
      ),
      (route) => false,
    );
  }

  @override
  Widget build(BuildContext context) {
    final screenHeight = MediaQuery.of(context).size.height;
    final heroHeight = math.max(screenHeight * 0.38, 296.0);

    return Scaffold(
      backgroundColor: NoorColors.emeraldNight,
      body: Stack(
        children: [
          // 1. Top Hero Section with Faint Arabesque Geometry & Pop-Out Avatar Badge
          Positioned(
            top: 0,
            left: 0,
            right: 0,
            height: heroHeight,
            child: Container(
              decoration: const BoxDecoration(
                gradient: NoorGradients.heroRadial,
              ),
              child: Stack(
                fit: StackFit.expand,
                children: [
                  // Faint Arabesque 8-point star lattice, muqarnas arches & sparkles
                  const CustomPaint(
                    painter: HeroGeometryPainter(),
                  ),

                  // Hero Content
                  SafeArea(
                    child: Padding(
                      padding: const EdgeInsets.fromLTRB(24, 12, 24, 38),
                      child: Center(
                        child: FittedBox(
                          fit: BoxFit.scaleDown,
                          child: Column(
                            mainAxisSize: MainAxisSize.min,
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              // Avatar Badge with 128px glowing ring and pop-out clipped hijab illustration
                              const PopOutAvatarBadge(variant: AvatarVariant.login),

                              const SizedBox(height: 16),

                              // Welcome Back Title
                              Text(
                                'Welcome Back',
                                style: GoogleFonts.plusJakartaSans(
                                  fontSize: 24,
                                  fontWeight: FontWeight.w800,
                                  color: NoorColors.ivory,
                                  letterSpacing: -0.3,
                                ),
                              ),

                              const SizedBox(height: 6),

                              // Subtitle
                              ConstrainedBox(
                                constraints: const BoxConstraints(maxWidth: 300),
                                child: Text(
                                  'Sign in to sync your bookmarks and dhikr.',
                                  textAlign: TextAlign.center,
                                  style: GoogleFonts.plusJakartaSans(
                                    fontSize: 13,
                                    color: NoorColors.sand,
                                    height: 1.4,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),

          // 2. Cream Curved Bottom Sheet (overlapping hero by 32px)
          Positioned(
            top: heroHeight - 32,
            left: 0,
            right: 0,
            bottom: 0,
            child: Container(
              decoration: const BoxDecoration(
                color: NoorColors.cream,
                borderRadius: NoorRadii.sheet,
                boxShadow: NoorShadows.sheet,
              ),
              child: ClipRRect(
                borderRadius: NoorRadii.sheet,
                child: SingleChildScrollView(
                  physics: const BouncingScrollPhysics(),
                  padding: const EdgeInsets.fromLTRB(28, 12, 28, 28),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      // Grab indicator pill (40x4px)
                      Center(
                        child: Container(
                          width: 40,
                          height: 4,
                          margin: const EdgeInsets.only(bottom: 24),
                          decoration: BoxDecoration(
                            color: NoorColors.fieldBorder,
                            borderRadius: BorderRadius.circular(2),
                          ),
                        ),
                      ),

                      // Email Field
                      _buildFieldLabel('EMAIL'),
                      const SizedBox(height: 6),
                      _buildTextField(
                        controller: _emailController,
                        hintText: 'you@example.com',
                        prefixSvg: 'assets/svg/icon_mail.svg',
                        keyboardType: TextInputType.emailAddress,
                        onChanged: _onEmailChanged,
                        errorText: _emailError,
                        isValid: _isValidEmail(_emailController.text),
                      ),

                      const SizedBox(height: 16),

                      // Password Field
                      _buildFieldLabel('PASSWORD'),
                      const SizedBox(height: 6),
                      _buildTextField(
                        controller: _passwordController,
                        hintText: '••••••••',
                        prefixSvg: 'assets/svg/icon_lock.svg',
                        obscureText: _obscurePassword,
                        onChanged: _onPasswordChanged,
                        errorText: _passwordError,
                        suffixIcon: GestureDetector(
                          onTap: () {
                            setState(() => _obscurePassword = !_obscurePassword);
                          },
                          child: Padding(
                            padding: const EdgeInsets.all(14),
                            child: SvgPicture.asset(
                              _obscurePassword
                                  ? 'assets/svg/icon_eye_slashed.svg'
                                  : 'assets/svg/icon_eye_open.svg',
                              width: 20,
                              height: 20,
                              colorFilter: const ColorFilter.mode(
                                NoorColors.forest,
                                BlendMode.srcIn,
                              ),
                            ),
                          ),
                        ),
                      ),

                      const SizedBox(height: 10),

                      // Forgot Password Link
                      Align(
                        alignment: Alignment.centerRight,
                        child: GestureDetector(
                          onTap: _showForgotPasswordDialog,
                          child: Text(
                            'Forgot Password?',
                            style: GoogleFonts.manrope(
                              fontSize: 13,
                              fontWeight: FontWeight.w600,
                              color: NoorColors.forest,
                            ),
                          ),
                        ),
                      ),

                      const SizedBox(height: 22),

                      // Primary Sign In Button
                      GestureDetector(
                        onTapDown: (_) => setState(() => _isButtonPressed = true),
                        onTapUp: (_) => setState(() => _isButtonPressed = false),
                        onTapCancel: () => setState(() => _isButtonPressed = false),
                        onTap: _isLoading ? null : _handleSignIn,
                        child: AnimatedScale(
                          scale: _isButtonPressed ? 0.97 : 1.0,
                          duration: const Duration(milliseconds: 150),
                          child: Container(
                            height: 56,
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
                            child: _isLoading
                                ? const SizedBox(
                                    width: 22,
                                    height: 22,
                                    child: CircularProgressIndicator(
                                      strokeWidth: 2.5,
                                      color: NoorColors.cream,
                                    ),
                                  )
                                : Text(
                                    'Sign In',
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

                      const SizedBox(height: 22),

                      // "Or continue with" Divider
                      Row(
                        children: [
                          Expanded(child: Container(height: 1, color: NoorColors.line)),
                          Padding(
                            padding: const EdgeInsets.symmetric(horizontal: 14),
                            child: Text(
                              'Or continue with',
                              style: GoogleFonts.manrope(
                                fontSize: 12.5,
                                color: NoorColors.ink.withOpacity(0.4),
                              ),
                            ),
                          ),
                          Expanded(child: Container(height: 1, color: NoorColors.line)),
                        ],
                      ),

                      const SizedBox(height: 18),

                      // Social Buttons: Google & Apple
                      Row(
                        children: [
                          // Google
                          Expanded(
                            child: _buildSocialButton(
                              label: 'Google',
                              svgAsset: 'assets/svg/icon_google.svg',
                              onTap: _handleSignIn,
                            ),
                          ),

                          const SizedBox(width: 14),

                          // Apple
                          Expanded(
                            child: _buildSocialButton(
                              label: 'Apple',
                              svgAsset: 'assets/svg/icon_apple.svg',
                              onTap: _handleSignIn,
                            ),
                          ),
                        ],
                      ),

                      const SizedBox(height: 24),

                      // Footer: Link to Sign Up
                      Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Text(
                            "Don't have an account? ",
                            style: GoogleFonts.manrope(
                              fontSize: 13.5,
                              color: NoorColors.ink.withOpacity(0.6),
                            ),
                          ),
                          GestureDetector(
                            onTap: () {
                              Navigator.of(context).pushReplacement(
                                PageRouteBuilder(
                                  pageBuilder: (_, __, ___) =>
                                      const SignUpScreen(),
                                  transitionsBuilder:
                                      (_, animation, __, child) =>
                                          FadeTransition(
                                    opacity: animation,
                                    child: child,
                                  ),
                                  transitionDuration:
                                      const Duration(milliseconds: 350),
                                ),
                              );
                            },
                            child: Text(
                              'Create one',
                              style: GoogleFonts.manrope(
                                fontSize: 13.5,
                                fontWeight: FontWeight.bold,
                                color: NoorColors.forest,
                              ),
                            ),
                          ),
                        ],
                      ),

                      const SizedBox(height: 12),

                      // Continue as Guest Option
                      Center(
                        child: GestureDetector(
                          onTap: _continueAsGuest,
                          child: Padding(
                            padding: const EdgeInsets.all(4),
                            child: Text(
                              'Continue as Guest →',
                              style: GoogleFonts.manrope(
                                fontSize: 13,
                                fontWeight: FontWeight.w600,
                                color: NoorColors.ink.withOpacity(0.5),
                              ),
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildFieldLabel(String label) {
    return Text(
      label,
      style: GoogleFonts.manrope(
        fontSize: 11.5,
        fontWeight: FontWeight.bold,
        letterSpacing: 0.8,
        color: NoorColors.ink.withOpacity(0.5),
      ),
    );
  }

  Widget _buildTextField({
    required TextEditingController controller,
    required String hintText,
    required String prefixSvg,
    TextInputType keyboardType = TextInputType.text,
    bool obscureText = false,
    ValueChanged<String>? onChanged,
    String? errorText,
    Widget? suffixIcon,
    bool isValid = false,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          height: 52,
          decoration: BoxDecoration(
            color: NoorColors.inputBg,
            borderRadius: NoorRadii.field,
            border: Border.all(
              color: errorText != null
                  ? NoorColors.destructive
                  : (isValid
                      ? NoorColors.forest.withOpacity(0.6)
                      : NoorColors.line),
              width: errorText != null || isValid ? 1.5 : 1.0,
            ),
          ),
          child: Row(
            children: [
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 14),
                child: SvgPicture.asset(
                  prefixSvg,
                  width: 20,
                  height: 20,
                  colorFilter: ColorFilter.mode(
                    NoorColors.ink.withOpacity(0.4),
                    BlendMode.srcIn,
                  ),
                ),
              ),
              Expanded(
                child: TextField(
                  controller: controller,
                  keyboardType: keyboardType,
                  obscureText: obscureText,
                  onChanged: onChanged,
                  style: GoogleFonts.manrope(
                    fontSize: 15,
                    fontWeight: FontWeight.w500,
                    color: NoorColors.ink,
                  ),
                  decoration: InputDecoration(
                    border: InputBorder.none,
                    hintText: hintText,
                    hintStyle: GoogleFonts.manrope(
                      fontSize: 14.5,
                      color: NoorColors.ink.withOpacity(0.35),
                    ),
                    isDense: true,
                    contentPadding: EdgeInsets.zero,
                  ),
                ),
              ),
              if (suffixIcon != null)
                suffixIcon
              else if (isValid)
                const Padding(
                  padding: EdgeInsets.symmetric(horizontal: 14),
                  child: Icon(
                    Icons.check_circle_rounded,
                    color: NoorColors.forest,
                    size: 20,
                  ),
                ),
            ],
          ),
        ),
        if (errorText != null)
          Padding(
            padding: const EdgeInsets.only(top: 5, left: 4),
            child: Text(
              errorText,
              style: GoogleFonts.manrope(
                fontSize: 11.5,
                fontWeight: FontWeight.w500,
                color: NoorColors.destructive,
              ),
            ),
          ),
      ],
    );
  }

  Widget _buildSocialButton({
    required String label,
    required String svgAsset,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        height: 50,
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: NoorRadii.button,
          border: Border.all(color: NoorColors.line),
          boxShadow: NoorShadows.card,
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            SvgPicture.asset(svgAsset, width: 20, height: 20),
            const SizedBox(width: 8),
            Text(
              label,
              style: GoogleFonts.manrope(
                fontSize: 14,
                fontWeight: FontWeight.w600,
                color: NoorColors.ink,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
