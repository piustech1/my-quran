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
import 'login_screen.dart';

class SignUpScreen extends StatefulWidget {
  const SignUpScreen({super.key});

  @override
  State<SignUpScreen> createState() => _SignUpScreenState();
}

class _SignUpScreenState extends State<SignUpScreen> {
  final StorageService _storageService = StorageService();

  final TextEditingController _nameController = TextEditingController();
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();
  final TextEditingController _confirmPasswordController =
      TextEditingController();

  bool _obscurePassword = true;
  bool _obscureConfirmPassword = true;
  bool _agreedToTerms = false;
  bool _hasAttemptedSubmit = false;
  bool _isLoading = false;
  bool _isButtonPressed = false;

  @override
  void dispose() {
    _nameController.dispose();
    _emailController.dispose();
    _passwordController.dispose();
    _confirmPasswordController.dispose();
    super.dispose();
  }

  bool _isValidEmail(String email) {
    return RegExp(r'^\S+@\S+\.\S+$').hasMatch(email.trim());
  }

  String? get _nameError {
    if (!_hasAttemptedSubmit && _nameController.text.isEmpty) return null;
    if (_nameController.text.trim().length < 2) {
      return 'Please enter your full name';
    }
    return null;
  }

  String? get _emailError {
    if (!_hasAttemptedSubmit && _emailController.text.isEmpty) return null;
    if (!_isValidEmail(_emailController.text)) {
      return 'Please enter a valid email address';
    }
    return null;
  }

  String? get _passwordError {
    if (!_hasAttemptedSubmit && _passwordController.text.isEmpty) return null;
    if (_passwordController.text.length < 8) {
      return 'Password must be at least 8 characters';
    }
    return null;
  }

  String? get _confirmPasswordError {
    if (!_hasAttemptedSubmit && _confirmPasswordController.text.isEmpty) {
      return null;
    }
    if (_confirmPasswordController.text != _passwordController.text) {
      return 'Passwords do not match';
    }
    return null;
  }

  bool get _isFormValid {
    return _nameError == null &&
        _emailError == null &&
        _passwordError == null &&
        _confirmPasswordError == null &&
        _agreedToTerms &&
        _nameController.text.isNotEmpty &&
        _emailController.text.isNotEmpty &&
        _passwordController.text.isNotEmpty;
  }

  Future<void> _handleSignUp() async {
    HapticFeedback.lightImpact();
    setState(() => _hasAttemptedSubmit = true);

    if (!_isFormValid) {
      if (!_agreedToTerms) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              'Please agree to the Terms of Service and Privacy Policy',
              style: GoogleFonts.manrope(),
            ),
            backgroundColor: NoorColors.destructive,
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          ),
        );
      }
      return;
    }

    setState(() => _isLoading = true);
    await Future.delayed(const Duration(milliseconds: 650));

    // Sign up via Firebase if connected
    try {
      await FirebaseSyncService().signUpWithEmail(
        name: _nameController.text.trim(),
        email: _emailController.text.trim(),
        password: _passwordController.text,
      );
    } catch (e) {
      debugPrint('[SignUpScreen] Firebase sign-up note: $e');
    }

    // Save session to local storage and sync
    await _storageService.saveUserSession(
      name: _nameController.text.trim(),
      email: _emailController.text.trim(),
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

  Widget _buildRequirementChip(String label, bool ok) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
        color: ok ? NoorColors.forest.withOpacity(0.12) : NoorColors.field,
        borderRadius: BorderRadius.circular(50),
        border: Border.all(
          color: ok ? NoorColors.forest.withOpacity(0.3) : NoorColors.fieldBorder,
          width: 0.8,
        ),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 14,
            height: 14,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: ok ? NoorColors.forest : Colors.transparent,
              border: ok ? null : Border.all(color: NoorColors.fieldBorder),
            ),
            child: ok
                ? const Icon(Icons.check, size: 9, color: NoorColors.ivory)
                : null,
          ),
          const SizedBox(width: 4),
          Text(
            label,
            style: GoogleFonts.plusJakartaSans(
              fontSize: 11,
              fontWeight: FontWeight.w600,
              color: ok ? NoorColors.forest : NoorColors.inkSoft,
            ),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final screenHeight = MediaQuery.of(context).size.height;
    final heroHeight = math.max(screenHeight * 0.38, 296.0);

    final pass = _passwordController.text;
    final hasLength = pass.length >= 8;
    final hasLetter = RegExp(r'[a-zA-Z]').hasMatch(pass);
    final hasNumber = RegExp(r'[0-9]').hasMatch(pass);
    final confirmPass = _confirmPasswordController.text;
    final passwordsMatch = confirmPass.isNotEmpty && confirmPass == pass;

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
                              const PopOutAvatarBadge(variant: AvatarVariant.signup),

                              const SizedBox(height: 16),

                              // Title
                              Text(
                                'Create Your Account',
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
                                  'Begin your spiritual journey with daily recitation.',
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

                      // Full Name Field
                      _buildFieldLabel('FULL NAME'),
                      const SizedBox(height: 5),
                      _buildTextField(
                        controller: _nameController,
                        hintText: 'Abdullah Rahman',
                        prefixSvg: 'assets/svg/icon_user.svg',
                        onChanged: (_) => setState(() {}),
                        errorText: _nameError,
                        isValid: _nameController.text.trim().length >= 2,
                      ),

                      const SizedBox(height: 14),

                      // Email Field
                      _buildFieldLabel('EMAIL'),
                      const SizedBox(height: 5),
                      _buildTextField(
                        controller: _emailController,
                        hintText: 'you@example.com',
                        prefixSvg: 'assets/svg/icon_mail.svg',
                        keyboardType: TextInputType.emailAddress,
                        onChanged: (_) => setState(() {}),
                        errorText: _emailError,
                        isValid: _isValidEmail(_emailController.text),
                      ),

                      const SizedBox(height: 14),

                      // Password Field
                      _buildFieldLabel('PASSWORD'),
                      const SizedBox(height: 5),
                      _buildTextField(
                        controller: _passwordController,
                        hintText: 'At least 8 characters',
                        prefixSvg: 'assets/svg/icon_lock.svg',
                        obscureText: _obscurePassword,
                        onChanged: (_) => setState(() {}),
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
                        isValid: _passwordController.text.length >= 8,
                      ),

                      // Password Criteria Chips
                      const SizedBox(height: 8),
                      Wrap(
                        spacing: 6,
                        runSpacing: 6,
                        children: [
                          _buildRequirementChip('8+ characters', hasLength),
                          _buildRequirementChip('A letter', hasLetter),
                          _buildRequirementChip('A number', hasNumber),
                        ],
                      ),

                      const SizedBox(height: 14),

                      // Confirm Password Field
                      _buildFieldLabel('CONFIRM PASSWORD'),
                      const SizedBox(height: 5),
                      _buildTextField(
                        controller: _confirmPasswordController,
                        hintText: 'Repeat password',
                        prefixSvg: 'assets/svg/icon_lock.svg',
                        obscureText: _obscureConfirmPassword,
                        onChanged: (_) => setState(() {}),
                        errorText: _confirmPasswordError,
                        suffixIcon: GestureDetector(
                          onTap: () {
                            setState(() =>
                                _obscureConfirmPassword = !_obscureConfirmPassword);
                          },
                          child: Padding(
                            padding: const EdgeInsets.all(14),
                            child: SvgPicture.asset(
                              _obscureConfirmPassword
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
                        isValid: passwordsMatch,
                      ),

                      // Passwords match indicator
                      if (passwordsMatch) ...[
                        const SizedBox(height: 6),
                        Row(
                          children: [
                            const Icon(
                              Icons.check_circle_rounded,
                              size: 14,
                              color: NoorColors.forest,
                            ),
                            const SizedBox(width: 4),
                            Text(
                              'Passwords match',
                              style: GoogleFonts.plusJakartaSans(
                                fontSize: 12,
                                fontWeight: FontWeight.w600,
                                color: NoorColors.forest,
                              ),
                            ),
                          ],
                        ),
                      ],

                      const SizedBox(height: 14),

                      // Terms & Privacy Checkbox
                      GestureDetector(
                        onTap: () {
                          HapticFeedback.selectionClick();
                          setState(() => _agreedToTerms = !_agreedToTerms);
                        },
                        behavior: HitTestBehavior.opaque,
                        child: Row(
                          crossAxisAlignment: CrossAxisAlignment.center,
                          children: [
                            Container(
                              width: 22,
                              height: 22,
                              decoration: BoxDecoration(
                                color: _agreedToTerms
                                    ? NoorColors.forest
                                    : NoorColors.inputBg,
                                borderRadius: BorderRadius.circular(6),
                                border: Border.all(
                                  color: _agreedToTerms
                                      ? NoorColors.forest
                                      : (_hasAttemptedSubmit && !_agreedToTerms
                                          ? NoorColors.destructive
                                          : NoorColors.line),
                                  width: 1.5,
                                ),
                              ),
                              alignment: Alignment.center,
                              child: _agreedToTerms
                                  ? const Icon(
                                      Icons.check_rounded,
                                      color: NoorColors.goldLight,
                                      size: 16,
                                    )
                                  : null,
                            ),
                            const SizedBox(width: 10),
                            Expanded(
                              child: RichText(
                                text: TextSpan(
                                  style: GoogleFonts.manrope(
                                    fontSize: 12.5,
                                    color: NoorColors.ink.withOpacity(0.75),
                                  ),
                                  children: const [
                                    TextSpan(text: 'I agree to the '),
                                    TextSpan(
                                      text: 'Terms of Service',
                                      style: TextStyle(
                                        color: NoorColors.forest,
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                                    TextSpan(text: ' & '),
                                    TextSpan(
                                      text: 'Privacy Policy',
                                      style: TextStyle(
                                        color: NoorColors.forest,
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),

                      const SizedBox(height: 20),

                      // Primary Create Account Button
                      GestureDetector(
                        onTapDown: (_) => setState(() => _isButtonPressed = true),
                        onTapUp: (_) => setState(() => _isButtonPressed = false),
                        onTapCancel: () => setState(() => _isButtonPressed = false),
                        onTap: _isLoading ? null : _handleSignUp,
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
                                    'Create Account',
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

                      const SizedBox(height: 20),

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

                      const SizedBox(height: 16),

                      // Social Buttons: Google & Apple
                      Row(
                        children: [
                          Expanded(
                            child: _buildSocialButton(
                              label: 'Google',
                              svgAsset: 'assets/svg/icon_google.svg',
                              onTap: _handleSignUp,
                            ),
                          ),
                          const SizedBox(width: 14),
                          Expanded(
                            child: _buildSocialButton(
                              label: 'Apple',
                              svgAsset: 'assets/svg/icon_apple.svg',
                              onTap: _handleSignUp,
                            ),
                          ),
                        ],
                      ),

                      const SizedBox(height: 22),

                      // Footer: Link to Sign In
                      Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Text(
                            'Already have an account? ',
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
                                      const LoginScreen(),
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
                              'Sign In',
                              style: GoogleFonts.manrope(
                                fontSize: 13.5,
                                fontWeight: FontWeight.bold,
                                color: NoorColors.forest,
                              ),
                            ),
                          ),
                        ],
                      ),

                      const SizedBox(height: 10),

                      // Continue as Guest
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
