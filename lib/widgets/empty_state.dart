import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:lucide_icons/lucide_icons.dart';
import '../theme/app_theme.dart';
import 'astronaut_illustration.dart';

/// Widget d'état vide réutilisable avec illustration astronaute
/// Remplace les icônes génériques dans tous les états vides de l'app
class EmptyState extends StatelessWidget {
  final String title;
  final String? subtitle;
  final AstronautType astronautType;
  final Widget? action;
  final double astronautSize;
  final EdgeInsetsGeometry? padding;

  const EmptyState({
    super.key,
    required this.title,
    this.subtitle,
    this.astronautType = AstronautType.welcome,
    this.action,
    this.astronautSize = 100,
    this.padding,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: padding ?? const EdgeInsets.all(32),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          AstronautIllustration(
            type: astronautType,
            width: astronautSize,
            height: astronautSize,
            showAnimation: true,
          ),
          const SizedBox(height: 20),
          Text(
            title,
            textAlign: TextAlign.center,
            style: GoogleFonts.nunito(
              fontSize: 16,
              fontWeight: FontWeight.w800,
              color: AppColors.text,
            ),
          ),
          if (subtitle != null) ...[
            const SizedBox(height: 8),
            Text(
              subtitle!,
              textAlign: TextAlign.center,
              style: GoogleFonts.nunito(
                fontSize: 13,
                color: AppColors.textSecondary,
                height: 1.5,
              ),
            ),
          ],
          if (action != null) ...[
            const SizedBox(height: 24),
            action!,
          ],
        ],
      ),
    );
  }
}

/// Variantes prédéfinies pour les cas d'usage courants

class EmptyStateMessages extends EmptyState {
  const EmptyStateMessages({super.key})
      : super(
          title: 'Aucune conversation',
          subtitle: 'Commencez une nouvelle discussion en appuyant sur le bouton +',
          astronautType: AstronautType.welcome,
        );
}

class EmptyStateClasses extends EmptyState {
  const EmptyStateClasses({super.key, super.action})
      : super(
          title: 'Aucune classe créée',
          subtitle: 'Créez votre première classe pour commencer à gérer vos élèves.',
          astronautType: AstronautType.learning,
        );
}

class EmptyStateQsm extends EmptyState {
  const EmptyStateQsm({super.key, super.action})
      : super(
          title: 'Aucun QSM disponible',
          subtitle: 'Uploadez un cours pour générer vos premiers QSM automatiquement.',
          astronautType: AstronautType.learning,
        );
}

class EmptyStateCours extends EmptyState {
  const EmptyStateCours({super.key, super.action})
      : super(
          title: 'Aucun cours uploadé',
          subtitle: 'Uploadez votre premier cours PDF ou DOCX pour commencer.',
          astronautType: AstronautType.learning,
        );
}

class EmptyStateResults extends EmptyState {
  const EmptyStateResults({super.key})
      : super(
          title: 'Aucun résultat disponible',
          subtitle: 'Les résultats apparaîtront ici une fois les QSM complétés.',
          astronautType: AstronautType.success,
        );
}

class EmptyStateUsers extends EmptyState {
  const EmptyStateUsers({super.key, String? title, String? subtitle})
      : super(
          title: title ?? 'Aucun utilisateur trouvé',
          subtitle: subtitle ?? 'Aucun utilisateur ne correspond à votre recherche.',
          astronautType: AstronautType.welcome,
        );
}

class EmptyStateSearch extends EmptyState {
  const EmptyStateSearch({super.key, String? query})
      : super(
          title: 'Aucun résultat',
          subtitle: 'Essayez avec d\'autres mots-clés.',
          astronautType: AstronautType.welcome,
        );
}

class EmptyStateRooms extends EmptyState {
  const EmptyStateRooms({super.key, super.action})
      : super(
          title: 'Aucun room disponible',
          subtitle: 'Rejoignez un room avec un code ou attendez qu\'un enseignant en crée un.',
          astronautType: AstronautType.learning,
        );
}

class EmptyStateHistory extends EmptyState {
  const EmptyStateHistory({super.key})
      : super(
          title: 'Aucun historique',
          subtitle: 'Votre historique d\'activité apparaîtra ici.',
          astronautType: AstronautType.celebration,
        );
}

class EmptyStateParents extends EmptyState {
  const EmptyStateParents({super.key})
      : super(
          title: 'Aucun parent trouvé',
          subtitle: 'Les parents liés à vos élèves apparaîtront ici.',
          astronautType: AstronautType.welcome,
        );
}

class EmptyStateTeachers extends EmptyState {
  const EmptyStateTeachers({super.key})
      : super(
          title: 'Aucun enseignant trouvé',
          subtitle: 'Les enseignants assignés à cette classe apparaîtront ici.',
          astronautType: AstronautType.welcome,
        );
}

/// Widget d'état vide dans une Card blanche
class EmptyStateCard extends StatelessWidget {
  final EmptyState emptyState;
  final EdgeInsetsGeometry? margin;

  const EmptyStateCard({
    super.key,
    required this.emptyState,
    this.margin,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: margin,
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.border, width: 0.5),
      ),
      child: emptyState,
    );
  }
}

/// Widget d'état vide centré pour les pages entières
class EmptyStatePage extends StatelessWidget {
  final EmptyState emptyState;

  const EmptyStatePage({super.key, required this.emptyState});

  @override
  Widget build(BuildContext context) {
    return Center(child: emptyState);
  }
}
