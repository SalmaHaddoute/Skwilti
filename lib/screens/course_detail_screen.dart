import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:lucide_icons/lucide_icons.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:url_launcher/url_launcher.dart';
import '../theme/app_theme.dart';
import '../widgets/astronaut_illustration.dart';

class CourseDetailScreen extends StatelessWidget {
  final Map<String, dynamic> course;
  final bool canEdit;
  final VoidCallback? onEdit;
  final VoidCallback? onDelete;

  const CourseDetailScreen({
    super.key,
    required this.course,
    this.canEdit = false,
    this.onEdit,
    this.onDelete,
  });

  @override
  Widget build(BuildContext context) {
    final title = course['title'] as String? ?? 'Cours sans titre';
    final description = course['description'] as String? ?? '';
    final fileName = course['file_name'] as String? ?? 'Fichier inconnu';
    final fileUrl = course['file_url'] as String? ?? '';
    final subject = course['subject'] as String? ?? 'Matière';
    final filiere = course['filiere'] as String? ?? 'Filière';
    final createdAt = course['created_at'] != null 
        ? DateTime.tryParse(course['created_at']) ?? DateTime.now()
        : DateTime.now();
    final questionCount = course['question_count'] as int? ?? 0;
    final isDefault = course['isDefault'] as bool? ?? false;

    return Scaffold(
      backgroundColor: Colors.transparent,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(LucideIcons.arrowLeft, color: AppColors.text),
          onPressed: () => Navigator.pop(context),
        ),
        title: Text(
          'Détails du cours',
          style: GoogleFonts.inter(
            fontSize: 18,
            fontWeight: FontWeight.w800,
            color: AppColors.text,
          ),
        ),
        actions: [
          if (canEdit && !isDefault) ...[
            IconButton(
              icon: const Icon(LucideIcons.edit, color: AppColors.primary),
              onPressed: onEdit,
              tooltip: 'Modifier',
            ),
            IconButton(
              icon: const Icon(LucideIcons.trash2, color: AppColors.error),
              onPressed: () => _showDeleteConfirmation(context),
              tooltip: 'Supprimer',
            ),
          ],
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // ── Hero Section avec illustration ──────────────────────────
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(24),
              decoration: BoxDecoration(
                gradient: const LinearGradient(
                  colors: [AppColors.primary, Color(0xFFBF4E07)],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                borderRadius: BorderRadius.circular(20),
                boxShadow: [
                  BoxShadow(
                    color: AppColors.primary.withOpacity(0.3),
                    blurRadius: 20,
                    offset: const Offset(0, 8),
                  ),
                ],
              ),
              child: Column(
                children: [
                  // Illustration
                  Container(
                    width: 120,
                    height: 120,
                    decoration: BoxDecoration(
                      color: Colors.white.withOpacity(0.15),
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(20),
                      child: AstronautIllustration(
                        type: AstronautType.learning,
                        width: 120,
                        height: 120,
                        showAnimation: true,
                        fallbackIcon: const Icon(
                          LucideIcons.bookOpen,
                          color: Colors.white,
                          size: 60,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: 20),
                  
                  // Titre
                  Text(
                    title,
                    style: GoogleFonts.inter(
                      fontSize: 22,
                      fontWeight: FontWeight.w900,
                      color: Colors.white,
                    ),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 8),
                  
                  // Badges
                  Wrap(
                    alignment: WrapAlignment.center,
                    spacing: 8,
                    runSpacing: 8,
                    children: [
                      _Badge(
                        label: subject,
                        icon: LucideIcons.bookOpen,
                        color: Colors.white.withOpacity(0.2),
                        textColor: Colors.white,
                      ),
                      _Badge(
                        label: filiere,
                        icon: LucideIcons.graduationCap,
                        color: Colors.white.withOpacity(0.2),
                        textColor: Colors.white,
                      ),
                      if (isDefault)
                        _Badge(
                          label: 'Par défaut',
                          icon: LucideIcons.star,
                          color: Colors.amber,
                          textColor: Colors.white,
                        ),
                    ],
                  ),
                ],
              ),
            ),
            const SizedBox(height: 24),

            // ── Informations principales ──────────────────────────────
            _SectionTitle('Informations'),
            const SizedBox(height: 12),
            
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: AppColors.border, width: 1),
              ),
              child: Column(
                children: [
                  _InfoRow(
                    icon: LucideIcons.fileText,
                    label: 'Nom du fichier',
                    value: fileName,
                    color: AppColors.primary,
                  ),
                  const Divider(height: 24),
                  _InfoRow(
                    icon: LucideIcons.calendar,
                    label: 'Date d\'ajout',
                    value: '${createdAt.day}/${createdAt.month}/${createdAt.year}',
                    color: AppColors.info,
                  ),
                  if (questionCount > 0) ...[
                    const Divider(height: 24),
                    _InfoRow(
                      icon: LucideIcons.helpCircle,
                      label: 'Questions générées',
                      value: '$questionCount questions',
                      color: AppColors.success,
                    ),
                  ],
                ],
              ),
            ),
            
            if (description.isNotEmpty) ...[
              const SizedBox(height: 24),
              _SectionTitle('Description'),
              const SizedBox(height: 12),
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: AppColors.border, width: 1),
                ),
                child: Text(
                  description,
                  style: GoogleFonts.inter(
                    fontSize: 14,
                    color: AppColors.text,
                    height: 1.6,
                  ),
                ),
              ),
            ],
            
            const SizedBox(height: 24),

            // ── Actions ──────────────────────────────────────────────
            _SectionTitle('Actions'),
            const SizedBox(height: 12),
            
            // Bouton Télécharger
            _ActionButton(
              icon: LucideIcons.download,
              label: 'Télécharger le fichier',
              subtitle: 'Enregistrer sur votre appareil',
              color: AppColors.primary,
              onTap: () => _downloadFile(context, fileUrl, fileName),
            ),
            const SizedBox(height: 12),
            
            // Bouton Ouvrir
            _ActionButton(
              icon: LucideIcons.externalLink,
              label: 'Ouvrir le fichier',
              subtitle: 'Voir dans le navigateur',
              color: AppColors.info,
              onTap: () => _openFile(context, fileUrl),
            ),
            const SizedBox(height: 12),
            
            // Bouton Partager
            _ActionButton(
              icon: LucideIcons.share2,
              label: 'Partager le lien',
              subtitle: 'Copier le lien du fichier',
              color: AppColors.success,
              onTap: () => _shareFile(context, fileUrl, title),
            ),
            
            const SizedBox(height: 40),
          ],
        ),
      ),
    );
  }

  void _showDeleteConfirmation(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: Row(
          children: [
            const Icon(LucideIcons.alertTriangle, color: AppColors.error, size: 24),
            const SizedBox(width: 12),
            const Text('Supprimer ce cours ?'),
          ],
        ),
        content: Text(
          'Cette action est irréversible. Le cours "${course['title'] ?? ''}" sera supprimé définitivement.',
          style: GoogleFonts.inter(fontSize: 14),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Annuler'),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(context); // Fermer le dialog
              Navigator.pop(context); // Retourner à l'écran précédent
              if (onDelete != null) onDelete!();
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.error,
              foregroundColor: Colors.white,
            ),
            child: const Text('Supprimer'),
          ),
        ],
      ),
    );
  }

  Future<void> _downloadFile(BuildContext context, String url, String fileName) async {
    if (url.isEmpty) {
      _showSnackBar(context, 'Aucun fichier disponible', isError: true);
      return;
    }

    try {
      final uri = Uri.parse(url);
      if (await canLaunchUrl(uri)) {
        await launchUrl(uri, mode: LaunchMode.externalApplication);
        _showSnackBar(context, 'Téléchargement démarré...');
      } else {
        _showSnackBar(context, 'Impossible d\'ouvrir le lien', isError: true);
      }
    } catch (e) {
      _showSnackBar(context, 'Erreur: $e', isError: true);
    }
  }

  Future<void> _openFile(BuildContext context, String url) async {
    if (url.isEmpty) {
      _showSnackBar(context, 'Aucun fichier disponible', isError: true);
      return;
    }

    try {
      final uri = Uri.parse(url);
      if (await canLaunchUrl(uri)) {
        await launchUrl(uri, mode: LaunchMode.inAppWebView);
        _showSnackBar(context, 'Ouverture du fichier...');
      } else {
        _showSnackBar(context, 'Impossible d\'ouvrir le fichier', isError: true);
      }
    } catch (e) {
      _showSnackBar(context, 'Erreur: $e', isError: true);
    }
  }

  Future<void> _shareFile(BuildContext context, String url, String title) async {
    if (url.isEmpty) {
      _showSnackBar(context, 'Aucun lien disponible', isError: true);
      return;
    }

    try {
      await Clipboard.setData(ClipboardData(text: url));
      _showSnackBar(context, 'Lien copié dans le presse-papiers !');
    } catch (e) {
      _showSnackBar(context, 'Erreur lors de la copie: $e', isError: true);
    }
  }

  void _showSnackBar(BuildContext context, String message, {bool isError = false}) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          children: [
            Icon(
              isError ? LucideIcons.alertCircle : LucideIcons.checkCircle,
              color: Colors.white,
              size: 20,
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                message,
                style: GoogleFonts.inter(
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                  color: Colors.white,
                ),
              ),
            ),
          ],
        ),
        backgroundColor: isError ? AppColors.error : AppColors.success,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        margin: const EdgeInsets.all(16),
        duration: const Duration(seconds: 3),
      ),
    );
  }
}

// ── Widgets auxiliaires ──────────────────────────────────────

class _SectionTitle extends StatelessWidget {
  final String title;
  const _SectionTitle(this.title);

  @override
  Widget build(BuildContext context) {
    return Text(
      title,
      style: GoogleFonts.inter(
        fontSize: 18,
        fontWeight: FontWeight.w800,
        color: AppColors.text,
      ),
    );
  }
}

class _Badge extends StatelessWidget {
  final String label;
  final IconData icon;
  final Color color;
  final Color textColor;

  const _Badge({
    required this.label,
    required this.icon,
    required this.color,
    required this.textColor,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: color,
        borderRadius: BorderRadius.circular(20),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 14, color: textColor),
          const SizedBox(width: 6),
          Text(
            label,
            style: GoogleFonts.inter(
              fontSize: 12,
              fontWeight: FontWeight.w700,
              color: textColor,
            ),
          ),
        ],
      ),
    );
  }
}

class _InfoRow extends StatelessWidget {
  final IconData icon;
  final String label;
  final String value;
  final Color color;

  const _InfoRow({
    required this.icon,
    required this.label,
    required this.value,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Container(
          width: 40,
          height: 40,
          decoration: BoxDecoration(
            color: color.withOpacity(0.1),
            borderRadius: BorderRadius.circular(10),
          ),
          child: Icon(icon, size: 20, color: color),
        ),
        const SizedBox(width: 16),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                label,
                style: GoogleFonts.inter(
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                  color: AppColors.textSub,
                ),
              ),
              const SizedBox(height: 2),
              Text(
                value,
                style: GoogleFonts.inter(
                  fontSize: 14,
                  fontWeight: FontWeight.w700,
                  color: AppColors.text,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

class _ActionButton extends StatelessWidget {
  final IconData icon;
  final String label;
  final String subtitle;
  final Color color;
  final VoidCallback onTap;

  const _ActionButton({
    required this.icon,
    required this.label,
    required this.subtitle,
    required this.color,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(16),
        child: Container(
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: color.withOpacity(0.3), width: 1.5),
            boxShadow: [
              BoxShadow(
                color: color.withOpacity(0.1),
                blurRadius: 10,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: Row(
            children: [
              Container(
                width: 50,
                height: 50,
                decoration: BoxDecoration(
                  color: color.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(icon, size: 24, color: color),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      label,
                      style: GoogleFonts.inter(
                        fontSize: 15,
                        fontWeight: FontWeight.w800,
                        color: AppColors.text,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      subtitle,
                      style: GoogleFonts.inter(
                        fontSize: 12,
                        color: AppColors.textSub,
                      ),
                    ),
                  ],
                ),
              ),
              Icon(
                LucideIcons.chevronRight,
                size: 20,
                color: color,
              ),
            ],
          ),
        ),
      ),
    );
  }
}
