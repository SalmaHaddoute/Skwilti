import 'package:flutter/material.dart';
import 'package:lucide_icons/lucide_icons.dart';
import 'package:google_fonts/google_fonts.dart';
import '../theme/app_theme.dart';
import '../widgets/common_widgets.dart';

class NotificationsScreen extends StatelessWidget {
  const NotificationsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: Text(
          'Notifications',
          style: GoogleFonts.nunito(
            fontSize: 18,
            fontWeight: FontWeight.w700,
            color: Colors.white,
          ),
        ),
        backgroundColor: AppColors.primary,
        foregroundColor: Colors.white,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(LucideIcons.chevronLeft),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          _NotificationItem(
            icon: LucideIcons.award,
            title: 'Nouveau succès débloqué',
            message: 'Vous avez débloqué le badge "Expert QCM"',
            time: 'Il y a 2 heures',
            color: AppColors.success,
            isRead: false,
          ),
          _NotificationItem(
            icon: LucideIcons.users,
            title: 'Nouvel élève inscrit',
            message: 'Jean Dupont a rejoint votre classe',
            time: 'Il y a 5 heures',
            color: AppColors.primary,
            isRead: false,
          ),
          _NotificationItem(
            icon: LucideIcons.fileText,
            title: 'QCM terminé',
            message: 'Marie a complété le QCM de mathématiques',
            time: 'Hier',
            color: AppColors.info,
            isRead: true,
          ),
          _NotificationItem(
            icon: LucideIcons.zap,
            title: 'Room créée avec succès',
            message: 'La room "Test rapide" a été créée',
            time: 'Il y a 2 jours',
            color: AppColors.warning,
            isRead: true,
          ),
          _NotificationItem(
            icon: LucideIcons.heart,
            title: 'Nouveau like',
            message: '5 élèves ont aimé votre dernier QCM',
            time: 'Il y a 3 jours',
            color: AppColors.error,
            isRead: true,
          ),
        ],
      ),
    );
  }
}

class _NotificationItem extends StatelessWidget {
  final IconData icon;
  final String title;
  final String message;
  final String time;
  final Color color;
  final bool isRead;

  const _NotificationItem({
    super.key,
    required this.icon,
    required this.title,
    required this.message,
    required this.time,
    required this.color,
    required this.isRead,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: isRead ? AppColors.border : color.withOpacity(0.3),
          width: isRead ? 1 : 2,
        ),
        boxShadow: isRead ? null : [
          BoxShadow(
            color: color.withOpacity(0.1),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Row(
        children: [
          Container(
            width: 48,
            height: 48,
            decoration: BoxDecoration(
              color: color.withOpacity(0.1),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(icon, color: color, size: 24),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: GoogleFonts.nunito(
                    fontSize: 14,
                    fontWeight: FontWeight.w700,
                    color: AppColors.text,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  message,
                  style: GoogleFonts.nunito(
                    fontSize: 12,
                    color: AppColors.textSub,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  time,
                  style: GoogleFonts.nunito(
                    fontSize: 11,
                    color: AppColors.textSub,
                  ),
                ),
              ],
            ),
          ),
          if (!isRead)
            Container(
              width: 8,
              height: 8,
              decoration: BoxDecoration(
                color: color,
                shape: BoxShape.circle,
              ),
            ),
        ],
      ),
    );
  }
}
