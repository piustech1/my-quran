import 'package:flutter/material.dart';

class AppColors {
  // Agreed My Quran Palette
  static const Color midnightNavy =
      Color(0xFF171F2D); // Base canvas / dark slate container
  static const Color quranGold =
      Color(0xFFF5CE63); // Warm Gold accent & highlights
  static const Color quranGoldLight = Color(0xFFFDF0CC); // Light gold tint
  static const Color deepEmerald =
      Color(0xFF103C30); // Rich Deep Emerald header & accent

  // Theme Accent Colors (mapped to agreed palette)
  static const Color accentGold = quranGold; // #F5CE63
  static const Color accentGoldDark =
      Color(0xFFD4AF37); // Rich gold for borders/subtitles
  static const Color accentGoldLight = quranGoldLight; // Light gold tint

  // Noor Dark Luxury Surfaces (Midnight Navy & Deep Emerald harmony)
  static const Color darkCanvas = Color(0xFF0F151F); // Deep Midnight Canvas
  static const Color darkCard = Color(0xFF171F2D); // Midnight Navy Card surface
  static const Color darkCardSubtle = Color(0xFF1F293B); // Elevated container
  static const Color darkInnerCard =
      Color(0xFF12241D); // Deep Emerald-tinted inner hour box
  static const Color darkBorder = Color(0xFF233045); // Subtle border
  static const Color darkBorderGold = Color(0x33F5CE63); // Gold border tint
  static const Color darkTextPrimary = Color(0xFFF4F6F5);
  static const Color darkTextSecondary = Color(0xFF94A3B8);
  static const Color darkPillButton = Color(0xFF0F151F);

  // Light Theme (Clean Crisp with Deep Emerald & Gold Accents)
  static const Color lightBackground = Color(0xFFFBF9F5); // Clean warm ivory canvas
  static const Color lightSurface = Color(0xFFFFFFFF); // Pure white card
  static const Color lightSurfaceSubtle =
      Color(0xFFF4EFE6); // Warm sandy beige inner hour card
  static const Color lightQuickAction =
      Color(0xFFF0EBE2); // Soft cream squircle action card
  static const Color lightBorder = Color(0xFFEAE5DC); // Subtle hairline border
  static const Color lightTextPrimary =
      Color(0xFF1D2321); // Charcoal dark ink text
  static const Color lightTextSecondary = Color(0xFF757B78); // Soft grey subtitle
  static const Color lightPillButton =
      Color(0xFF171F2D); // Midnight Navy button

  // Legacy mappings for backwards-compatibility
  static const Color darkBackground = darkCanvas;
  static const Color darkSurface = darkCard;
  static const Color darkSurfaceSubtle = darkInnerCard;
  static const Color forestGreen = deepEmerald;
  static const Color forestGreenSurface = Color(0xFF184E3F);
  static const Color warmGold = quranGold;
  static const Color emeraldPrimary = deepEmerald;
  static const Color emeraldSurface = Color(0xFF1A5242);

  // Parchment for Quran Manuscript Reader
  static const Color parchment = Color(0xFFFAF8F2);
  static const Color parchmentBorder = Color(0xFFEADBCE);
}
