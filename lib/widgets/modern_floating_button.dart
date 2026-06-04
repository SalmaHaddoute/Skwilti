import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:lucide_icons/lucide_icons.dart';
import '../theme/app_theme.dart';

class ModernFloatingButton extends StatelessWidget {
  final VoidCallback onPressed;
  final String label;
  final IconData icon;
  final Color? backgroundColor;
  final Color? foregroundColor;
  final double? fontSize;
  final FontWeight? fontWeight;
  final EdgeInsetsGeometry? padding;
  final double? borderRadius;
  final List<BoxShadow>? customShadows;

  const ModernFloatingButton({
    super.key,
    required this.onPressed,
    required this.label,
    this.icon = LucideIcons.plus,
    this.backgroundColor,
    this.foregroundColor = Colors.white,
    this.fontSize = 15,
    this.fontWeight = FontWeight.w700,
    this.padding = const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
    this.borderRadius = 16,
    this.customShadows,
  });

  @override
  Widget build(BuildContext context) {
    final bgColor = backgroundColor ?? AppColors.primary;
    
    return AnimatedContainer(
      duration: const Duration(milliseconds: 300),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(borderRadius!),
        gradient: LinearGradient(
          colors: [
            bgColor,
            bgColor.withOpacity(0.8),
          ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        boxShadow: customShadows ?? [
          BoxShadow(
            color: bgColor.withOpacity(0.4),
            blurRadius: 16,
            offset: const Offset(0, 6),
            spreadRadius: 0,
          ),
          BoxShadow(
            color: bgColor.withOpacity(0.2),
            blurRadius: 32,
            offset: const Offset(0, 12),
            spreadRadius: 0,
          ),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        borderRadius: BorderRadius.circular(borderRadius!),
        child: InkWell(
          onTap: onPressed,
          borderRadius: BorderRadius.circular(borderRadius!),
          child: Container(
            padding: padding,
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  padding: const EdgeInsets.all(6),
                  decoration: BoxDecoration(
                    color: foregroundColor!.withOpacity(0.25),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Icon(
                    icon,
                    size: 20,
                    color: foregroundColor,
                  ),
                ),
                const SizedBox(width: 12),
                Text(
                  label,
                  style: GoogleFonts.nunito(
                    fontWeight: fontWeight,
                    fontSize: fontSize,
                    color: foregroundColor,
                    letterSpacing: 0.3,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

// Variantes prédéfinies pour différents cas d'usage
class ModernFloatingButton_Create extends ModernFloatingButton {
  const ModernFloatingButton_Create({
    super.key,
    required super.onPressed,
    super.label = 'Créer',
    super.icon = LucideIcons.plus,
  });
}

class ModernFloatingButton_Add extends ModernFloatingButton {
  const ModernFloatingButton_Add({
    super.key,
    required super.onPressed,
    super.label = 'Ajouter',
    super.icon = LucideIcons.userPlus,
  });
}

class ModernFloatingButton_Message extends ModernFloatingButton {
  const ModernFloatingButton_Message({
    super.key,
    required super.onPressed,
    super.label = 'Nouveau message',
    super.icon = LucideIcons.plus,
  });
}

class ModernFloatingButton_Upload extends ModernFloatingButton {
  const ModernFloatingButton_Upload({
    super.key,
    required super.onPressed,
    super.label = 'Upload',
    super.icon = LucideIcons.upload,
  });
}

// Version compacte pour les espaces restreints
class ModernFloatingButton_Compact extends StatelessWidget {
  final VoidCallback onPressed;
  final IconData icon;
  final Color? backgroundColor;
  final Color? foregroundColor;

  const ModernFloatingButton_Compact({
    super.key,
    required this.onPressed,
    this.icon = LucideIcons.plus,
    this.backgroundColor,
    this.foregroundColor = Colors.white,
  });

  @override
  Widget build(BuildContext context) {
    final bgColor = backgroundColor ?? AppColors.primary;
    
    return AnimatedContainer(
      duration: const Duration(milliseconds: 300),
      width: 56,
      height: 56,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(16),
        gradient: LinearGradient(
          colors: [
            bgColor,
            bgColor.withOpacity(0.8),
          ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        boxShadow: [
          BoxShadow(
            color: bgColor.withOpacity(0.4),
            blurRadius: 16,
            offset: const Offset(0, 6),
          ),
          BoxShadow(
            color: bgColor.withOpacity(0.2),
            blurRadius: 32,
            offset: const Offset(0, 12),
          ),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        borderRadius: BorderRadius.circular(16),
        child: InkWell(
          onTap: onPressed,
          borderRadius: BorderRadius.circular(16),
          child: Center(
            child: Icon(
              icon,
              size: 24,
              color: foregroundColor,
            ),
          ),
        ),
      ),
    );
  }
}