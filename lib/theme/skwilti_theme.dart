import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class SkwiltiTheme {
  // Colors based on the screenshots
  static const Color primaryViolet = Color(0xFF6C3EE8);
  static const Color primaryVioletLight = Color(0xFF9B6FF5);
  static const Color primaryVioletDark = Color(0xFF5528C8);
  static const Color primaryVioletBackground = Color(0xFFEEEDFE);
  
  static const Color accentOrange = Color(0xFFFF6B2C);
  static const Color accentOrangeLight = Color(0xFFFF8F5E);
  static const Color accentOrangeDark = Color(0xFFCC4A12);
  static const Color accentOrangeBackground = Color(0xFFFFF0EA);
  
  static const Color successGreen = Color(0xFF1D9E75);
  static const Color successGreenLight = Color(0xFFE1F5EE);
  
  static const Color errorRed = Color(0xFFE24B4A);
  static const Color errorRedLight = Color(0xFFFCEBEB);
  
  static const Color warningYellow = Color(0xFFF59E0B);
  static const Color infoBlue = Color(0xFF3B82F6);
  
  static const Color backgroundLight = Color(0xFFF7F5FF);
  static const Color cardWhite = Color(0xFFFFFFFF);
  static const Color textDark = Color(0xFF1A1630);
  static const Color textSecondary = Color(0xFF7B7593);
  static const Color borderLight = Color(0xFFEAE7F8);

  // Typography
  static TextStyle get headingLarge {
    return GoogleFonts.inter(
      fontSize: 32,
      fontWeight: FontWeight.w700,
      color: textDark,
      height: 1.2,
    );
  }

  static TextStyle get headingMedium {
    return GoogleFonts.inter(
      fontSize: 24,
      fontWeight: FontWeight.w600,
      color: textDark,
      height: 1.3,
    );
  }

  static TextStyle get headingSmall {
    return GoogleFonts.inter(
      fontSize: 20,
      fontWeight: FontWeight.w600,
      color: textDark,
      height: 1.3,
    );
  }

  static TextStyle get titleLarge {
    return GoogleFonts.inter(
      fontSize: 18,
      fontWeight: FontWeight.w600,
      color: textDark,
      height: 1.4,
    );
  }

  static TextStyle get titleMedium {
    return GoogleFonts.inter(
      fontSize: 16,
      fontWeight: FontWeight.w600,
      color: textDark,
      height: 1.4,
    );
  }

  static TextStyle get bodyLarge {
    return GoogleFonts.inter(
      fontSize: 16,
      fontWeight: FontWeight.w400,
      color: textDark,
      height: 1.5,
    );
  }

  static TextStyle get bodyMedium {
    return GoogleFonts.inter(
      fontSize: 14,
      fontWeight: FontWeight.w400,
      color: textDark,
      height: 1.5,
    );
  }

  static TextStyle get bodySmall {
    return GoogleFonts.inter(
      fontSize: 12,
      fontWeight: FontWeight.w400,
      color: textSecondary,
      height: 1.4,
    );
  }

  static TextStyle get caption {
    return GoogleFonts.inter(
      fontSize: 11,
      fontWeight: FontWeight.w400,
      color: textSecondary,
      height: 1.3,
    );
  }

  // Card theme
  static CardTheme get cardTheme {
    return CardTheme(
      color: cardWhite,
      elevation: 4,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
      ),
      margin: EdgeInsets.zero,
    );
  }

  // Button themes
  static ElevatedButtonThemeData get elevatedButtonTheme {
    return ElevatedButtonThemeData(
      style: ElevatedButton.styleFrom(
        backgroundColor: primaryViolet,
        foregroundColor: Colors.white,
        elevation: 2,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
        ),
        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
        textStyle: GoogleFonts.inter(
          fontSize: 14,
          fontWeight: FontWeight.w600,
        ),
      ),
    );
  }

  static OutlinedButtonThemeData get outlinedButtonTheme {
    return OutlinedButtonThemeData(
      style: OutlinedButton.styleFrom(
        foregroundColor: primaryViolet,
        side: const BorderSide(color: primaryViolet, width: 1.5),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
        ),
        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
        textStyle: GoogleFonts.inter(
          fontSize: 14,
          fontWeight: FontWeight.w600,
        ),
      ),
    );
  }

  static TextButtonThemeData get textButtonTheme {
    return TextButtonThemeData(
      style: TextButton.styleFrom(
        foregroundColor: primaryViolet,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(8),
        ),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        textStyle: GoogleFonts.inter(
          fontSize: 14,
          fontWeight: FontWeight.w500,
        ),
      ),
    );
  }

  // Input decoration theme
  static InputDecorationTheme get inputDecorationTheme {
    return InputDecorationTheme(
      filled: true,
      fillColor: cardWhite,
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: const BorderSide(color: borderLight, width: 1),
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: const BorderSide(color: borderLight, width: 1),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: const BorderSide(color: primaryViolet, width: 2),
      ),
      errorBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: const BorderSide(color: errorRed, width: 1),
      ),
      labelStyle: GoogleFonts.inter(
        fontSize: 14,
        color: textSecondary,
      ),
      hintStyle: GoogleFonts.inter(
        fontSize: 14,
        color: textSecondary,
      ),
    );
  }

  // App bar theme
  static AppBarTheme get appBarTheme {
    return AppBarTheme(
      backgroundColor: primaryViolet,
      foregroundColor: Colors.white,
      elevation: 0,
      centerTitle: true,
      titleTextStyle: GoogleFonts.inter(
        fontSize: 18,
        fontWeight: FontWeight.w600,
        color: Colors.white,
      ),
      iconTheme: const IconThemeData(
        color: Colors.white,
        size: 24,
      ),
    );
  }

  // Bottom navigation theme
  static BottomNavigationBarThemeData get bottomNavigationBarTheme {
    return BottomNavigationBarThemeData(
      backgroundColor: cardWhite,
      selectedItemColor: primaryViolet,
      unselectedItemColor: textSecondary,
      selectedLabelStyle: GoogleFonts.inter(
        fontSize: 11,
        fontWeight: FontWeight.w600,
      ),
      unselectedLabelStyle: GoogleFonts.inter(
        fontSize: 11,
        fontWeight: FontWeight.w400,
      ),
      type: BottomNavigationBarType.fixed,
      elevation: 8,
    );
  }

  // Complete theme data
  static ThemeData get lightTheme {
    return ThemeData(
      useMaterial3: true,
      brightness: Brightness.light,
      colorScheme: ColorScheme.fromSeed(
        seedColor: primaryViolet,
        primary: primaryViolet,
        secondary: accentOrange,
        surface: cardWhite,
        background: backgroundLight,
        error: errorRed,
        onPrimary: Colors.white,
        onSecondary: Colors.white,
        onSurface: textDark,
        onBackground: textDark,
        onError: Colors.white,
      ),
      scaffoldBackgroundColor: backgroundLight,
      appBarTheme: appBarTheme,
      elevatedButtonTheme: elevatedButtonTheme,
      outlinedButtonTheme: outlinedButtonTheme,
      textButtonTheme: textButtonTheme,
      inputDecorationTheme: inputDecorationTheme,
      bottomNavigationBarTheme: bottomNavigationBarTheme,
      textTheme: TextTheme(
        displayLarge: headingLarge,
        displayMedium: headingMedium,
        displaySmall: headingSmall,
        headlineLarge: headingLarge,
        headlineMedium: headingMedium,
        headlineSmall: headingSmall,
        titleLarge: titleLarge,
        titleMedium: titleMedium,
        titleSmall: bodyLarge,
        bodyLarge: bodyLarge,
        bodyMedium: bodyMedium,
        bodySmall: bodySmall,
        labelSmall: caption,
      ),
    );
  }
}

// Custom widgets for consistent styling
class SkwiltiCard extends StatelessWidget {
  final Widget child;
  final EdgeInsets? padding;
  final EdgeInsets? margin;
  final VoidCallback? onTap;
  final Color? backgroundColor;
  final double? elevation;
  final BorderRadius? borderRadius;

  const SkwiltiCard({
    super.key,
    required this.child,
    this.padding,
    this.margin,
    this.onTap,
    this.backgroundColor,
    this.elevation,
    this.borderRadius,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: margin ?? EdgeInsets.zero,
      child: Material(
        color: backgroundColor ?? SkwiltiTheme.cardWhite,
        elevation: elevation ?? 4,
        shadowColor: Colors.black.withOpacity(0.08),
        borderRadius: borderRadius ?? BorderRadius.circular(16),
        child: InkWell(
          onTap: onTap,
          borderRadius: borderRadius ?? BorderRadius.circular(16),
          child: Padding(
            padding: padding ?? const EdgeInsets.all(16),
            child: child,
          ),
        ),
      ),
    );
  }
}

class SkwiltiButton extends StatelessWidget {
  final String text;
  final VoidCallback? onPressed;
  final SkwiltiButtonType type;
  final IconData? icon;
  final bool isLoading;
  final double? width;
  final double? height;

  const SkwiltiButton({
    super.key,
    required this.text,
    this.onPressed,
    this.type = SkwiltiButtonType.primary,
    this.icon,
    this.isLoading = false,
    this.width,
    this.height,
  });

  @override
  Widget build(BuildContext context) {
    Widget button;
    
    switch (type) {
      case SkwiltiButtonType.primary:
        button = ElevatedButton(
          onPressed: isLoading ? null : onPressed,
          style: ElevatedButton.styleFrom(
            backgroundColor: SkwiltiTheme.primaryViolet,
            foregroundColor: Colors.white,
            elevation: 2,
            shadowColor: SkwiltiTheme.primaryViolet.withOpacity(0.3),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
            minimumSize: Size(width ?? 0, height ?? 48),
          ),
          child: _buildButtonContent(),
        );
        break;
      case SkwiltiButtonType.secondary:
        button = OutlinedButton(
          onPressed: isLoading ? null : onPressed,
          style: OutlinedButton.styleFrom(
            foregroundColor: SkwiltiTheme.primaryViolet,
            side: const BorderSide(color: SkwiltiTheme.primaryViolet, width: 1.5),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
            minimumSize: Size(width ?? 0, height ?? 48),
          ),
          child: _buildButtonContent(),
        );
        break;
      case SkwiltiButtonType.outline:
        button = OutlinedButton(
          onPressed: isLoading ? null : onPressed,
          style: OutlinedButton.styleFrom(
            foregroundColor: SkwiltiTheme.textSecondary,
            side: const BorderSide(color: SkwiltiTheme.borderLight, width: 1),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
            minimumSize: Size(width ?? 0, height ?? 48),
          ),
          child: _buildButtonContent(),
        );
        break;
    }

    return button;
  }

  Widget _buildButtonContent() {
    if (isLoading) {
      return const SizedBox(
        width: 20,
        height: 20,
        child: CircularProgressIndicator(
          strokeWidth: 2,
          valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
        ),
      );
    }

    if (icon != null) {
      return Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 18),
          const SizedBox(width: 8),
          Text(text),
        ],
      );
    }

    return Text(text);
  }
}

enum SkwiltiButtonType {
  primary,
  secondary,
  outline,
}

class SkwiltiIcon extends StatelessWidget {
  final IconData icon;
  final double? size;
  final Color? color;
  final SkwiltiIconVariant variant;

  const SkwiltiIcon({
    super.key,
    required this.icon,
    this.size,
    this.color,
    this.variant = SkwiltiIconVariant.solid,
  });

  @override
  Widget build(BuildContext context) {
    Color iconColor = color ?? SkwiltiTheme.textSecondary;
    double iconSize = size ?? 24.0;

    switch (variant) {
      case SkwiltiIconVariant.solid:
        return Icon(icon, size: iconSize, color: iconColor);
      case SkwiltiIconVariant.light:
        return Icon(icon, size: iconSize, color: iconColor.withOpacity(0.7));
      case SkwiltiIconVariant.background:
        return Container(
          width: iconSize + 8,
          height: iconSize + 8,
          decoration: BoxDecoration(
            color: iconColor.withOpacity(0.1),
            borderRadius: BorderRadius.circular(8),
          ),
          child: Icon(icon, size: iconSize, color: iconColor),
        );
      case SkwiltiIconVariant.circle:
        return Container(
          width: iconSize + 16,
          height: iconSize + 16,
          decoration: BoxDecoration(
            color: iconColor.withOpacity(0.1),
            shape: BoxShape.circle,
          ),
          child: Icon(icon, size: iconSize, color: iconColor),
        );
    }
  }
}

enum SkwiltiIconVariant {
  solid,
  light,
  background,
  circle,
}
