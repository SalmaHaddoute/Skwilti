import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:google_fonts/google_fonts.dart';
import '../theme/app_theme.dart';

class AdminSubscriptionChart extends StatelessWidget {
  final int freeUsers;
  final int premiumUsers;

  const AdminSubscriptionChart({
    super.key,
    required this.freeUsers,
    required this.premiumUsers,
  });

  @override
  Widget build(BuildContext context) {
    final total = freeUsers + premiumUsers;
    final freePercentage = total > 0 ? (freeUsers / total) : 0.0;
    final premiumPercentage = total > 0 ? (premiumUsers / total) : 0.0;

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.border, width: 0.5),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.04),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Répartition des abonnements',
            style: GoogleFonts.nunito(
              fontSize: 16,
              fontWeight: FontWeight.w700,
              color: AppColors.text,
            ),
          ),
          const SizedBox(height: 20),
          Row(
            children: [
              SizedBox(
                height: 140,
                width: 140,
                child: PieChart(
                  PieChartData(
                    sections: [
                      PieChartSectionData(
                        value: freeUsers > 0 ? freeUsers.toDouble() : 1.0,
                        title: freeUsers > 0 ? '${(freePercentage * 100).round()}%' : '0%',
                        titleStyle: GoogleFonts.nunito(
                          fontSize: 11,
                          fontWeight: FontWeight.w800,
                          color: Colors.white,
                        ),
                        color: AppColors.textSub.withOpacity(0.8),
                        radius: 26,
                        titlePositionPercentageOffset: 0.5,
                      ),
                      PieChartSectionData(
                        value: premiumUsers > 0 ? premiumUsers.toDouble() : 1.0,
                        title: premiumUsers > 0 ? '${(premiumPercentage * 100).round()}%' : '0%',
                        titleStyle: GoogleFonts.nunito(
                          fontSize: 11,
                          fontWeight: FontWeight.w800,
                          color: Colors.white,
                        ),
                        color: AppColors.primary,
                        radius: 26,
                        titlePositionPercentageOffset: 0.5,
                      ),
                    ],
                    sectionsSpace: 3,
                    centerSpaceRadius: 36,
                    centerSpaceColor: Colors.white,
                  ),
                ),
              ),
              const SizedBox(width: 20),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    _LegendItem(
                      color: AppColors.textSub,
                      label: 'Gratuit',
                      value: freeUsers,
                      percentage: freePercentage,
                    ),
                    const SizedBox(height: 16),
                    _LegendItem(
                      color: AppColors.primary,
                      label: 'Premium',
                      value: premiumUsers,
                      percentage: premiumPercentage,
                    ),
                  ],
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _LegendItem extends StatelessWidget {
  final Color color;
  final String label;
  final int value;
  final double percentage;

  const _LegendItem({
    required this.color,
    required this.label,
    required this.value,
    required this.percentage,
  });

  @override
  Widget build(BuildContext context) {
    final pctText = '${(percentage * 100).round()}%';
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Container(
              width: 10,
              height: 10,
              decoration: BoxDecoration(
                color: color,
                borderRadius: BorderRadius.circular(3),
              ),
            ),
            const SizedBox(width: 8),
            Text(
              label,
              style: GoogleFonts.nunito(
                fontSize: 13,
                fontWeight: FontWeight.w700,
                color: AppColors.text,
              ),
            ),
            const Spacer(),
            Text(
              pctText,
              style: GoogleFonts.nunito(
                fontSize: 12,
                fontWeight: FontWeight.w800,
                color: color,
              ),
            ),
          ],
        ),
        const SizedBox(height: 4),
        Text(
          '$value utilisateurs',
          style: GoogleFonts.nunito(
            fontSize: 11,
            color: AppColors.textSub,
          ),
        ),
        const SizedBox(height: 6),
        ClipRRect(
          borderRadius: BorderRadius.circular(2),
          child: LinearProgressIndicator(
            value: percentage,
            minHeight: 4,
            backgroundColor: AppColors.border,
            valueColor: AlwaysStoppedAnimation(color),
          ),
        ),
      ],
    );
  }
}
