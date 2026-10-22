import 'package:flutter/material.dart';

class AppColors {
  // Deep Green Theme (No gradients - pure solid & glass tones)
  static const Color primary = Color(0xFF0D3B2E);       // Imperial Emerald
  static const Color primaryDark = Color(0xFF071E17);   // Midnight Forest Canvas
  static const Color primaryLight = Color(0xFF1B5E4A);  // Lighter Emerald
  static const Color primarySurface = Color(0xFF104637);// Card Surface for Dark Mode

  // Neutral & Parchment (For authentic Quran manuscript feeling)
  static const Color parchment = Color(0xFFF9F7F1);     // Warm Ivory/Parchment
  static const Color parchmentCard = Color(0xFFF2EFE7); // Slightly deeper parchment
  static const Color textDark = Color(0xFF182822);      // Deep charcoal/ink
  static const Color textMuted = Color(0xFF6B7F76);     // Subtle slate green text
  static const Color textLight = Color(0xFFFFFFFF);     // Pure white text

  // Ornamental Accents
  static const Color gold = Color(0xFFC9A86A);          // Champagne Gold
  static const Color goldMuted = Color(0xFF9E8148);     // Muted Antique Gold
  static const Color sage = Color(0xFF3D7A62);          // Soft Sage Green

  // iOS Glassmorphism (Frosted glass with backdrop blur, no gradients)
  static Color glassBackground = Colors.white.withOpacity(0.10);
  static Color glassBackgroundHeavy = Colors.white.withOpacity(0.18);
  static Color glassDarkBackground = const Color(0xFF071E17).withOpacity(0.75);
  static Color glassBorder = Colors.white.withOpacity(0.22);
  static Color glassBorderSubtle = Colors.white.withOpacity(0.12);
  static Color glassDivider = Colors.white.withOpacity(0.15);
}
