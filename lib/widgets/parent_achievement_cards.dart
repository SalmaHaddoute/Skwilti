import 'package:flutter/material.dart';
import 'package:lucide_icons/lucide_icons.dart';
import 'package:google_fonts/google_fonts.dart';
import '../theme/app_theme.dart';

class ParentAchievementCards extends StatelessWidget {
  final int points;
  final int badges;
  final int certificates;
  final int? attendanceRate; // Taux de présence
  final int? activeDays; // Jours d'activité

  const ParentAchievementCards({
    super.key,
    required this.points,
    required this.badges,
    required this.certificates,
    this.attendanceRate,
    this.activeDays,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Row(
          children: [
            Expanded(child: _ParentAchievementCard(
              value: '$points',
              label: 'Points',
              icon: LucideIcons.trophy,
              color: AppColors.primary,
              subtitle: 'Total accumulé',
              onTap: () {
                // Navigation vers détails des points
              },
            )),
            const SizedBox(width: 12),
            Expanded(child: _ParentAchievementCard(
              value: '$badges',
              label: 'Badges',
              icon: LucideIcons.award,
              color: AppColors.primary,
              subtitle: 'Obtenus',
              onTap: () {
                // Navigation vers détails des badges
              },
            )),
            const SizedBox(width: 12),
            Expanded(child: _ParentAchievementCard(
              value: '$certificates',
              label: 'Certificats',
              icon: LucideIcons.fileText,
              color: AppColors.primary,
              subtitle: 'Reçus',
              onTap: () {
                // Navigation vers détails des certificats
              },
            )),
          ],
        ),
        if (attendanceRate != null || activeDays != null) ...[
          const SizedBox(height: 16),
          Row(
            children: [
              if (attendanceRate != null) ...[
                Expanded(
                  child: _ParentAchievementCard(
                    value: '$attendanceRate%',
                    label: 'Présence',
                    icon: LucideIcons.calendar,
                    color: AppColors.primary,
                    subtitle: 'Ce mois',
                    onTap: () {
                      // Navigation vers détails de présence
                    },
                  ),
                ),
                const SizedBox(width: 12),
              ],
              if (activeDays != null) ...[
                Expanded(
                  child: _ParentAchievementCard(
                    value: '$activeDays',
                    label: 'Jours actifs',
                    icon: LucideIcons.activity,
                    color: AppColors.primary,
                    subtitle: 'Consécutifs',
                    onTap: () {
                      // Navigation vers détails d'activité
                    },
                  ),
                ),
              ],
            ],
          ),
        ],
      ],
    );
  }
}

class _ParentAchievementCard extends StatelessWidget {
  final String value;
  final String label;
  final IconData icon;
  final Color color;
  final String subtitle;
  final VoidCallback? onTap;

  const _ParentAchievementCard({
    required this.value,
    required this.label,
    required this.icon,
    required this.color,
    required this.subtitle,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: color.withOpacity(0.2), width: 1),
          boxShadow: [
            BoxShadow(
              color: color.withOpacity(0.1),
              blurRadius: 8,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Column(
          children: [
            Row(
              children: [
                Container(
                  width: 40,
                  height: 40,
                  decoration: BoxDecoration(
                    color: color.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Icon(icon, color: color, size: 20),
                ),
                const Spacer(),
                Container(
                  padding: const EdgeInsets.all(4),
                  decoration: BoxDecoration(
                    color: color.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(6),
                  ),
                  child: Icon(
                    LucideIcons.chevronRight,
                    color: color,
                    size: 16,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            Text(
              value,
              style: GoogleFonts.nunito(
                fontSize: 20,
                fontWeight: FontWeight.w900,
                color: color,
                height: 1.0,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              label,
              style: GoogleFonts.nunito(
                fontSize: 12,
                fontWeight: FontWeight.w700,
                color: AppColors.textSub,
              ),
            ),
            const SizedBox(height: 2),
            Text(
              subtitle,
              style: GoogleFonts.nunito(
                fontSize: 10,
                fontWeight: FontWeight.w500,
                color: AppColors.textSub.withOpacity(0.7),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
