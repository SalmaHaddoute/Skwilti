import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../theme/app_theme.dart';

/// Widget système pour afficher les illustrations d'astronautes
/// Gère automatiquement les fallbacks et les animations
class AstronautIllustration extends StatelessWidget {
  final AstronautType type;
  final double? width;
  final double? height;
  final BoxFit fit;
  final bool showAnimation;
  final Widget? fallbackIcon;
  final Color? fallbackColor;

  const AstronautIllustration({
    super.key,
    required this.type,
    this.width,
    this.height,
    this.fit = BoxFit.contain,
    this.showAnimation = true,
    this.fallbackIcon,
    this.fallbackColor,
  });

  @override
  Widget build(BuildContext context) {
    final imagePath = _getImagePath(type);
    
    Widget imageWidget = Image.asset(
      imagePath,
      width: width,
      height: height,
      fit: fit,
      errorBuilder: (context, error, stackTrace) {
        return _buildFallback();
      },
    );

    // Animation disabled temporarily to fix opacity assertion errors
    // The TweenAnimationBuilder was causing opacity values to exceed 1.0
    // TODO: Re-enable animation after investigating the root cause
    return imageWidget;
  }

  Widget _buildFallback() {
    return Container(
      width: width,
      height: height,
      decoration: BoxDecoration(
        color: fallbackColor ?? AppColors.primaryLight,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Center(
        child: fallbackIcon ?? Icon(
          _getFallbackIcon(type),
          size: (width ?? height ?? 100) * 0.4,
          color: AppColors.primary,
        ),
      ),
    );
  }

  String _getImagePath(AstronautType type) {
    switch (type) {
      case AstronautType.login:
        return 'assets/images/astronaut_3d.jpeg';
      case AstronautType.welcome:
        return 'assets/images/astronaut_welcome.jpeg';
      case AstronautType.success:
        return 'assets/images/teacher_astronauts.jpeg';
      case AstronautType.learning:
        return 'assets/images/astronaut_celebration.jpeg';
      case AstronautType.celebration:
        return 'assets/images/astronaut_team.jpeg';
    }
  }

  IconData _getFallbackIcon(AstronautType type) {
    switch (type) {
      case AstronautType.login:
        return Icons.rocket_launch;
      case AstronautType.welcome:
        return Icons.waving_hand;
      case AstronautType.success:
        return Icons.check_circle;
      case AstronautType.learning:
        return Icons.school;
      case AstronautType.celebration:
        return Icons.celebration;
    }
  }
}

/// Types d'illustrations d'astronautes disponibles
enum AstronautType {
  login,        // Pour l'écran de connexion
  welcome,      // Pour les écrans d'accueil
  success,      // Pour les messages de succès
  learning,     // Pour les écrans d'apprentissage
  celebration,  // Pour les réussites et célébrations
}

/// Widget décoratif avec astronaute pour les arrière-plans
class AstronautBackground extends StatelessWidget {
  final AstronautType type;
  final Alignment alignment;
  final double opacity;
  final double scale;

  const AstronautBackground({
    super.key,
    required this.type,
    this.alignment = Alignment.bottomRight,
    this.opacity = 0.1,
    this.scale = 1.0,
  });

  @override
  Widget build(BuildContext context) {
    return Positioned.fill(
      child: Align(
        alignment: alignment,
        child: Transform.scale(
          scale: scale,
          child: Opacity(
            opacity: opacity,
            child: AstronautIllustration(
              type: type,
              showAnimation: false,
              width: 200,
              height: 200,
            ),
          ),
        ),
      ),
    );
  }
}

/// Widget carte avec astronaute pour les sections importantes
class AstronautCard extends StatelessWidget {
  final AstronautType type;
  final String title;
  final String description;
  final VoidCallback? onTap;
  final Color? backgroundColor;
  final double? illustrationSize;

  const AstronautCard({
    super.key,
    required this.type,
    required this.title,
    required this.description,
    this.onTap,
    this.backgroundColor,
    this.illustrationSize = 80,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: backgroundColor ?? Colors.white,
          borderRadius: BorderRadius.circular(16),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.05),
              blurRadius: 16,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Row(
          children: [
            AstronautIllustration(
              type: type,
              width: illustrationSize,
              height: illustrationSize,
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: GoogleFonts.nunito(
                      fontSize: 16,
                      fontWeight: FontWeight.w800,
                      color: AppColors.text,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    description,
                    style: GoogleFonts.nunito(
                      fontSize: 13,
                      color: AppColors.textSecondary,
                      height: 1.4,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// Widget héro avec astronaute pour les écrans d'accueil
class AstronautHero extends StatelessWidget {
  final AstronautType type;
  final String title;
  final String? subtitle;
  final Widget? action;
  final double? height;

  const AstronautHero({
    super.key,
    required this.type,
    required this.title,
    this.subtitle,
    this.action,
    this.height = 300,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      height: height,
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            AppColors.primary.withOpacity(0.1),
            AppColors.primaryLight.withOpacity(0.05),
          ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          AstronautIllustration(
            type: type,
            width: 120,
            height: 120,
          ),
          const SizedBox(height: 20),
          Text(
            title,
            textAlign: TextAlign.center,
            style: GoogleFonts.nunito(
              fontSize: 24,
              fontWeight: FontWeight.w900,
              color: AppColors.primary,
            ),
          ),
          if (subtitle != null) ...[
            const SizedBox(height: 8),
            Text(
              subtitle!,
              textAlign: TextAlign.center,
              style: GoogleFonts.nunito(
                fontSize: 14,
                color: AppColors.textSecondary,
                height: 1.4,
              ),
            ),
          ],
          if (action != null) ...[
            const SizedBox(height: 20),
            action!,
          ],
        ],
      ),
    );
  }
}