import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../constants/app_colors.dart';

class AppTheme {
  // 1. Light Theme (Default Priority)
  static ThemeData get lightTheme {
    return ThemeData(
      useMaterial3: true,
      brightness: Brightness.light,
      scaffoldBackgroundColor: AppColors.lightBackground,
      primaryColor: AppColors.quranGold,
      colorScheme: const ColorScheme.light(
        primary: AppColors.quranGold,
        secondary: AppColors.deepEmerald,
        surface: AppColors.lightSurface,
        onPrimary: AppColors.midnightNavy,
        onSurface: AppColors.lightTextPrimary,
      ),
      cardTheme: CardTheme(
        color: AppColors.lightSurface,
        elevation: 0,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(24),
          side: const BorderSide(color: AppColors.lightBorder, width: 1),
        ),
      ),
      textTheme: GoogleFonts.plusJakartaSansTextTheme(
        ThemeData.light().textTheme,
      ).copyWith(
        displayLarge: GoogleFonts.plusJakartaSans(
          color: AppColors.lightTextPrimary,
          fontWeight: FontWeight.bold,
          fontSize: 28,
        ),
        titleLarge: GoogleFonts.plusJakartaSans(
          color: AppColors.lightTextPrimary,
          fontWeight: FontWeight.bold,
          fontSize: 20,
        ),
        titleMedium: GoogleFonts.plusJakartaSans(
          color: AppColors.lightTextPrimary,
          fontWeight: FontWeight.w600,
          fontSize: 16,
        ),
        bodyLarge: GoogleFonts.plusJakartaSans(
          color: AppColors.lightTextPrimary,
          fontSize: 15,
        ),
        bodyMedium: GoogleFonts.plusJakartaSans(
          color: AppColors.lightTextSecondary,
          fontSize: 13,
        ),
      ),
      appBarTheme: const AppBarTheme(
        backgroundColor: Colors.transparent,
        elevation: 0,
        centerTitle: true,
        iconTheme: IconThemeData(color: AppColors.lightTextPrimary),
        titleTextStyle: TextStyle(
          color: AppColors.lightTextPrimary,
          fontSize: 18,
          fontWeight: FontWeight.bold,
        ),
      ),
    );
  }

  // 2. Dark Theme (Noor Luxury Mode)
  static ThemeData get darkTheme {
    return ThemeData(
      useMaterial3: true,
      brightness: Brightness.dark,
      scaffoldBackgroundColor: AppColors.darkCanvas,
      primaryColor: AppColors.quranGold,
      colorScheme: const ColorScheme.dark(
        primary: AppColors.quranGold,
        secondary: AppColors.deepEmerald,
        surface: AppColors.darkCard,
        onPrimary: AppColors.midnightNavy,
        onSurface: AppColors.darkTextPrimary,
      ),
      cardTheme: CardTheme(
        color: AppColors.darkCard,
        elevation: 0,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(24),
          side: const BorderSide(color: AppColors.darkBorder, width: 1),
        ),
      ),
      textTheme: GoogleFonts.plusJakartaSansTextTheme(
        ThemeData.dark().textTheme,
      ).copyWith(
        displayLarge: GoogleFonts.plusJakartaSans(
          color: AppColors.darkTextPrimary,
          fontWeight: FontWeight.bold,
          fontSize: 28,
        ),
        titleLarge: GoogleFonts.plusJakartaSans(
          color: AppColors.darkTextPrimary,
          fontWeight: FontWeight.bold,
          fontSize: 20,
        ),
        titleMedium: GoogleFonts.plusJakartaSans(
          color: AppColors.darkTextPrimary,
          fontWeight: FontWeight.w600,
          fontSize: 16,
        ),
        bodyLarge: GoogleFonts.plusJakartaSans(
          color: AppColors.darkTextPrimary,
          fontSize: 15,
        ),
        bodyMedium: GoogleFonts.plusJakartaSans(
          color: AppColors.darkTextSecondary,
          fontSize: 13,
        ),
      ),
      appBarTheme: const AppBarTheme(
        backgroundColor: Colors.transparent,
        elevation: 0,
        centerTitle: true,
        iconTheme: IconThemeData(color: AppColors.darkTextPrimary),
        titleTextStyle: TextStyle(
          color: AppColors.darkTextPrimary,
          fontSize: 18,
          fontWeight: FontWeight.bold,
        ),
      ),
    );
  }
}
