import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class AppColors {
  // === Skwilti Brand (from logo & web) ===
  static const Color primary     = Color(0xFFE8630A);   // Orange logo
  static const Color primaryDark = Color(0xFFBF4E07);
  static const Color primaryLight= Color(0xFFFFF0E6);
  static const Color primary2    = Color(0xFFF4954A);

  static const Color green       = Color(0xFF1B6B2E);   // Vert logo
  static const Color greenMid    = Color(0xFF2D9E4F);
  static const Color greenLight  = Color(0xFFE8F5EC);
  static const Color greenDark   = Color(0xFF145522);

  // Semantic
  static const Color success     = Color(0xFF27AE60);
  static const Color successLight= Color(0xFFD5F5E3);
  static const Color error       = Color(0xFFE74C3C);
  static const Color errorLight  = Color(0xFFFDEDEC);
  static const Color warning     = Color(0xFFF39C12);
  static const Color warningLight= Color(0xFFFEF9E7);
  static const Color info        = Color(0xFF2980B9);
  static const Color infoLight   = Color(0xFFEBF5FB);

  // Aliases
  static const Color orange      = primary;
  static const Color orange2     = primary2;
  static const Color orangeLight = primaryLight;
  static const Color orangeDark  = primaryDark;

  // Neutrals
  static const Color background  = Color(0xFFF8F9FA);
  static const Color card        = Color(0xFFFFFFFF);
  static const Color text        = Color(0xFF1A1A2E);
  static const Color textSecondary = Color(0xFF6B7280);
  static const Color textSub     = Color(0xFF9CA3AF);
  static const Color dark        = Color(0xFF1A1A2E);
  static const Color border      = Color(0xFFE5E7EB);
  static const Color borderMed   = Color(0xFFD1D5DB);
}

class AppTheme {
  static ThemeData get lightTheme => ThemeData(
    useMaterial3: true,
    colorScheme: ColorScheme.fromSeed(
      seedColor: AppColors.primary,
      primary: AppColors.primary,
      secondary: AppColors.green,
      background: AppColors.background,
      surface: AppColors.card,
      error: AppColors.error,
    ),
    scaffoldBackgroundColor: Colors.transparent,
    fontFamily: GoogleFonts.nunito().fontFamily,
    textTheme: GoogleFonts.nunitoTextTheme().copyWith(
      displayLarge:  GoogleFonts.nunito(fontSize: 32, fontWeight: FontWeight.w900, color: AppColors.text, letterSpacing: -0.5),
      displayMedium: GoogleFonts.nunito(fontSize: 26, fontWeight: FontWeight.w800, color: AppColors.text, letterSpacing: -0.3),
      headlineLarge: GoogleFonts.nunito(fontSize: 24, fontWeight: FontWeight.w800, color: AppColors.text),
      headlineMedium:GoogleFonts.nunito(fontSize: 20, fontWeight: FontWeight.w700, color: AppColors.text),
      headlineSmall: GoogleFonts.nunito(fontSize: 17, fontWeight: FontWeight.w700, color: AppColors.text),
      titleLarge:    GoogleFonts.nunito(fontSize: 16, fontWeight: FontWeight.w700, color: AppColors.text),
      titleMedium:   GoogleFonts.nunito(fontSize: 14, fontWeight: FontWeight.w600, color: AppColors.text),
      bodyLarge:     GoogleFonts.nunito(fontSize: 15, fontWeight: FontWeight.w400, color: AppColors.text),
      bodyMedium:    GoogleFonts.nunito(fontSize: 13, fontWeight: FontWeight.w400, color: AppColors.textSecondary),
      bodySmall:     GoogleFonts.nunito(fontSize: 11, fontWeight: FontWeight.w400, color: AppColors.textSub),
      labelLarge:    GoogleFonts.nunito(fontSize: 14, fontWeight: FontWeight.w700, color: Colors.white),
    ),
    elevatedButtonTheme: ElevatedButtonThemeData(
      style: ElevatedButton.styleFrom(
        backgroundColor: AppColors.primary,
        foregroundColor: Colors.white,
        elevation: 0,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
        textStyle: GoogleFonts.nunito(fontSize: 15, fontWeight: FontWeight.w800),
      ),
    ),
    outlinedButtonTheme: OutlinedButtonThemeData(
      style: OutlinedButton.styleFrom(
        foregroundColor: AppColors.text,
        side: const BorderSide(color: AppColors.border, width: 1.5),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
        textStyle: GoogleFonts.nunito(fontSize: 15, fontWeight: FontWeight.w700),
      ),
    ),
    textButtonTheme: TextButtonThemeData(
      style: TextButton.styleFrom(
        foregroundColor: AppColors.primary,
        textStyle: GoogleFonts.nunito(fontSize: 14, fontWeight: FontWeight.w700),
      ),
    ),
    inputDecorationTheme: InputDecorationTheme(
      filled: true,
      fillColor: Colors.white,
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: const BorderSide(color: AppColors.border)),
      enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: const BorderSide(color: AppColors.border)),
      focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: const BorderSide(color: AppColors.primary, width: 2)),
      errorBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: const BorderSide(color: AppColors.error)),
      focusedErrorBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: const BorderSide(color: AppColors.error, width: 2)),
      labelStyle: GoogleFonts.nunito(fontSize: 14, fontWeight: FontWeight.w600, color: AppColors.textSecondary),
      hintStyle: GoogleFonts.nunito(fontSize: 14, color: AppColors.textSub),
      prefixIconColor: AppColors.primary,
    ),
    appBarTheme: AppBarTheme(
      backgroundColor: Colors.white, elevation: 0, scrolledUnderElevation: 0,
      titleTextStyle: GoogleFonts.nunito(fontSize: 17, fontWeight: FontWeight.w800, color: AppColors.text),
      iconTheme: const IconThemeData(color: AppColors.text),
      surfaceTintColor: Colors.transparent,
    ),
    floatingActionButtonTheme: const FloatingActionButtonThemeData(
      backgroundColor: AppColors.primary, foregroundColor: Colors.white,
      elevation: 4, shape: CircleBorder(),
    ),
    dividerTheme: const DividerThemeData(color: AppColors.border, thickness: 0.5, space: 0),
    snackBarTheme: SnackBarThemeData(
      backgroundColor: AppColors.text,
      contentTextStyle: GoogleFonts.nunito(fontSize: 13, color: Colors.white),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      behavior: SnackBarBehavior.floating,
    ),
    bottomNavigationBarTheme: BottomNavigationBarThemeData(
      backgroundColor: Colors.white,
      selectedItemColor: AppColors.primary,
      unselectedItemColor: AppColors.textSub,
      selectedLabelStyle: GoogleFonts.nunito(fontSize: 10, fontWeight: FontWeight.w800),
      unselectedLabelStyle: GoogleFonts.nunito(fontSize: 10, fontWeight: FontWeight.w600),
      elevation: 8, type: BottomNavigationBarType.fixed,
    ),
  );

  static ThemeData get light => lightTheme;
}
