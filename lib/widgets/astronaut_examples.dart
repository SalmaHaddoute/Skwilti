import 'package:flutter/material.dart';
import 'astronaut_illustration.dart';
import '../theme/app_theme.dart';

/// Exemples d'utilisation du système d'illustrations d'astronautes
/// Ce fichier montre comment intégrer les astronautes dans différents contextes

class AstronautExamples {
  
  /// Exemple 1: Écran de bienvenue avec héro astronaute
  static Widget welcomeHero() {
    return AstronautHero(
      type: AstronautType.welcome,
      title: 'Bienvenue dans Skwilti !',
      subtitle: 'Explorez l\'univers de l\'apprentissage avec nos astronautes',
      action: ElevatedButton(
        onPressed: () {},
        style: ElevatedButton.styleFrom(
          backgroundColor: AppColors.primary,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        ),
        child: const Text('Commencer l\'aventure'),
      ),
    );
  }

  /// Exemple 2: Carte de succès avec astronaute
  static Widget successCard() {
    return AstronautCard(
      type: AstronautType.success,
      title: 'Félicitations !',
      description: 'Vous avez terminé ce QCM avec succès. Continuez votre progression !',
      backgroundColor: AppColors.primaryLight,
      onTap: () {
        // Action au tap
      },
    );
  }

  /// Exemple 3: Section d'apprentissage
  static Widget learningSection() {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 16,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        children: [
          AstronautIllustration(
            type: AstronautType.learning,
            width: 100,
            height: 100,
          ),
          const SizedBox(height: 16),
          const Text(
            'Prêt à apprendre ?',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: AppColors.primary,
            ),
          ),
          const SizedBox(height: 8),
          const Text(
            'Nos astronautes vous accompagnent dans votre parcours d\'apprentissage.',
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: 14,
              color: AppColors.textSecondary,
            ),
          ),
        ],
      ),
    );
  }

  /// Exemple 4: État vide avec astronaute
  static Widget emptyState({
    required String title,
    required String description,
    Widget? action,
  }) {
    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        AstronautIllustration(
          type: AstronautType.welcome,
          width: 150,
          height: 150,
        ),
        const SizedBox(height: 24),
        Text(
          title,
          textAlign: TextAlign.center,
          style: const TextStyle(
            fontSize: 20,
            fontWeight: FontWeight.bold,
            color: AppColors.text,
          ),
        ),
        const SizedBox(height: 8),
        Text(
          description,
          textAlign: TextAlign.center,
          style: const TextStyle(
            fontSize: 14,
            color: AppColors.textSecondary,
          ),
        ),
        if (action != null) ...[
          const SizedBox(height: 24),
          action,
        ],
      ],
    );
  }

  /// Exemple 5: Notification de célébration
  static Widget celebrationNotification() {
    return Container(
      margin: const EdgeInsets.all(16),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            AppColors.primary.withOpacity(0.1),
            AppColors.primaryLight.withOpacity(0.05),
          ],
        ),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: AppColors.primary.withOpacity(0.2),
        ),
      ),
      child: Row(
        children: [
          AstronautIllustration(
            type: AstronautType.celebration,
            width: 40,
            height: 40,
            showAnimation: true,
          ),
          const SizedBox(width: 12),
          const Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Nouveau niveau débloqué !',
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.bold,
                    color: AppColors.primary,
                  ),
                ),
                Text(
                  'Vous progressez bien, continuez !',
                  style: TextStyle(
                    fontSize: 12,
                    color: AppColors.textSecondary,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

/// Widget pour intégrer facilement les astronautes dans les AppBar
class AstronautAppBar extends StatelessWidget implements PreferredSizeWidget {
  final String title;
  final AstronautType astronautType;
  final List<Widget>? actions;
  final bool showAstronaut;

  const AstronautAppBar({
    super.key,
    required this.title,
    this.astronautType = AstronautType.welcome,
    this.actions,
    this.showAstronaut = true,
  });

  @override
  Widget build(BuildContext context) {
    return AppBar(
      backgroundColor: Colors.white,
      elevation: 0,
      title: Row(
        children: [
          if (showAstronaut) ...[
            AstronautIllustration(
              type: astronautType,
              width: 24,
              height: 24,
              showAnimation: false,
            ),
            const SizedBox(width: 8),
          ],
          Text(
            title,
            style: const TextStyle(
              color: AppColors.text,
              fontWeight: FontWeight.bold,
            ),
          ),
        ],
      ),
      actions: actions,
    );
  }

  @override
  Size get preferredSize => const Size.fromHeight(kToolbarHeight);
}