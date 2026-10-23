import 'package:flutter/material.dart';

class AppColors {
  // Theme Accent Colors (matching mockup)
  static const Color accentGold = Color(0xFFF5B842);     // Warm Mustard/Golden Ochre (Last Read card, play buttons)
  static const Color accentGoldDark = Color(0xFFD99B26); // Slightly deeper gold for borders
  static const Color accentGoldLight = Color(0xFFFDEAC1);// Light gold tint

  // Light Theme (Default Priority)
  static const Color lightBackground = Color(0xFFF8F9FA); // Clean off-white
  static const Color lightSurface = Color(0xFFFFFFFF);    // Pure white card
  static const Color lightSurfaceSubtle = Color(0xFFF1F3F5); // Subtle grey surface for prayer card
  static const Color lightBorder = Color(0xFFE9ECEF);     // Light hairline border
  static const Color lightTextPrimary = Color(0xFF191D24);// Deep charcoal ink text
  static const Color lightTextSecondary = Color(0xFF718096); // Slate grey subtitle
  static const Color lightPillButton = Color(0xFF1A202C); // Dark pill button on Last Read card

  // Dark Theme (Toggleable)
  static const Color darkBackground = Color(0xFF191D24);  // Deep slate canvas (from mockup)
  static const Color darkSurface = Color(0xFF222834);     // Dark card surface
  static const Color darkSurfaceSubtle = Color(0xFF161A20);
  static const Color darkBorder = Color(0xFF2D3442);
  static const Color darkTextPrimary = Color(0xFFFFFFFF);
  static const Color darkTextSecondary = Color(0xFF8C98A9);
  static const Color darkPillButton = Color(0xFF12151B);

  // Emerald & Forest Quran Accents
  static const Color forestGreen = Color(0xFF143825); // Solid deep forest green requested by user
  static const Color forestGreenSurface = Color(0xFF1B4931);
  static const Color warmGold = Color(0xFFF3D278);
  static const Color emeraldPrimary = Color(0xFF0D3B2E);
  static const Color emeraldSurface = Color(0xFF164738);

  // Parchment for Quran Manuscript Reader
  static const Color parchment = Color(0xFFFAF8F2);
  static const Color parchmentBorder = Color(0xFFEADBCE);
}
