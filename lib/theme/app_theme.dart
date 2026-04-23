import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class AppColors {
  // Primary - Violet Skwilti
  static const Color primary = Color(0xFF6C3EE8);
  static const Color primary2 = Color(0xFF9B6FF5);
  static const Color primaryLight = Color(0xFFEEEDFE);

  // Secondary - Orange
  static const Color orange = Color(0xFFFF6B2C);
  static const Color orange2 = Color(0xFFFF8F5E);
  static const Color orangeLight = Color(0xFFFFF0EA);
  static const Color orangeDark = Color(0xFFCC4A12);

  // Semantic
  static const Color success = Color(0xFF1D9E75);
  static const Color successLight = Color(0xFFE1F5EE);
  static const Color error = Color(0xFFE24B4A);
  static const Color errorLight = Color(0xFFFCEBEB);

  // Neutral
  static const Color dark = Color(0xFF1A1630);
  static const Color background = Color(0xFFF7F5FF);
  static const Color card = Color(0xFFFFFFFF);
  static const Color text = Color(0xFF1A1630);
  static const Color textSub = Color(0xFF7B7593);
  static const Color border = Color(0xFFEAE7F8);
}

class AppTheme {
  static ThemeData get light {
    return ThemeData(
      useMaterial3: true,
      colorScheme: ColorScheme.fromSeed(
        seedColor: AppColors.primary,
        primary: AppColors.primary,
        secondary: AppColors.orange,
        surface: AppColors.card,
        background: AppColors.background,
        error: AppColors.error,
      ),
      scaffoldBackgroundColor: AppColors.background,
      textTheme: GoogleFonts.plusJakartaSansTextTheme().copyWith(
        displayLarge: GoogleFonts.plusJakartaSans(
            fontSize: 28, fontWeight: FontWeight.w800, color: AppColors.text),
        displayMedium: GoogleFonts.plusJakartaSans(
            fontSize: 22, fontWeight: FontWeight.w700, color: AppColors.text),
        headlineLarge: GoogleFonts.plusJakartaSans(
            fontSize: 20, fontWeight: FontWeight.w700, color: AppColors.text),
        headlineMedium: GoogleFonts.plusJakartaSans(
            fontSize: 17, fontWeight: FontWeight.w700, color: AppColors.text),
        titleLarge: GoogleFonts.plusJakartaSans(
            fontSize: 15, fontWeight: FontWeight.w700, color: AppColors.text),
        titleMedium: GoogleFonts.plusJakartaSans(
            fontSize: 13, fontWeight: FontWeight.w600, color: AppColors.text),
        bodyLarge: GoogleFonts.plusJakartaSans(
            fontSize: 15, fontWeight: FontWeight.w400, color: AppColors.text),
        bodyMedium: GoogleFonts.plusJakartaSans(
            fontSize: 13, fontWeight: FontWeight.w400, color: AppColors.textSub),
        labelSmall: GoogleFonts.plusJakartaSans(
            fontSize: 10, fontWeight: FontWeight.w700, color: AppColors.textSub),
      ),
      appBarTheme: AppBarTheme(
        backgroundColor: AppColors.background,
        elevation: 0,
        centerTitle: true,
        iconTheme: const IconThemeData(color: AppColors.text, size: 20),
        titleTextStyle: GoogleFonts.plusJakartaSans(
            fontSize: 15, fontWeight: FontWeight.w700, color: AppColors.text),
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: AppColors.orange,
          foregroundColor: Colors.white,
          elevation: 0,
          shadowColor: AppColors.orange.withOpacity(0.3),
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 14),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
          textStyle: GoogleFonts.plusJakartaSans(
              fontSize: 13, fontWeight: FontWeight.w800),
        ),
      ),
      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          foregroundColor: AppColors.primary,
          side: const BorderSide(color: AppColors.primary, width: 1.5),
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 14),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
          textStyle: GoogleFonts.plusJakartaSans(
              fontSize: 13, fontWeight: FontWeight.w800),
        ),
      ),
      cardTheme: CardThemeData(
        color: AppColors.card,
        elevation: 0,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
          side: const BorderSide(color: AppColors.border, width: 0.5),
        ),
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: AppColors.card,
        contentPadding:
            const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: AppColors.border, width: 0.5),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: AppColors.border, width: 0.5),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: AppColors.primary, width: 1.5),
        ),
      ),
    );
  }
}
