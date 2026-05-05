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
      width: 280,
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
          SizedBox(
            height: 200,
            width: 240,
            child: PieChart(
              PieChartData(
                sections: [
                  PieChartSectionData(
                    value: freeUsers.toDouble(),
                    title: '${(freePercentage * 100).toInt()}%',
                    titleStyle: GoogleFonts.nunito(
                      fontSize: 14,
                      fontWeight: FontWeight.w700,
                      color: Colors.white,
                    ),
                    color: AppColors.textSub,
                    radius: 50,
                    titlePositionPercentageOffset: 0.6,
                  ),
                  PieChartSectionData(
                    value: premiumUsers.toDouble(),
                    title: '${(premiumPercentage * 100).toInt()}%',
                    titleStyle: GoogleFonts.nunito(
                      fontSize: 14,
                      fontWeight: FontWeight.w700,
                      color: Colors.white,
                    ),
                    color: AppColors.primary,
                    radius: 50,
                    titlePositionPercentageOffset: 0.6,
                  ),
                ],
                sectionsSpace: 2,
                centerSpaceRadius: 60,
                centerSpaceColor: Colors.white,
              ),
            ),
          ),
          const SizedBox(height: 20),
          Column(
            children: [
              _LegendItem(
                color: AppColors.textSub,
                label: 'Gratuit',
                value: '$freeUsers',
                percentage: '${(freePercentage * 100).toInt()}%',
              ),
              const SizedBox(height: 8),
              _LegendItem(
                color: AppColors.primary,
                label: 'Premium',
                value: '$premiumUsers',
                percentage: '${(premiumPercentage * 100).toInt()}%',
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
  final String value;
  final String percentage;

  const _LegendItem({
    required this.color,
    required this.label,
    required this.value,
    required this.percentage,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Container(
          width: 16,
          height: 16,
          decoration: BoxDecoration(
            color: color,
            borderRadius: BorderRadius.circular(4),
          ),
        ),
        const SizedBox(width: 8),
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              label,
              style: GoogleFonts.nunito(
                fontSize: 12,
                fontWeight: FontWeight.w600,
                color: AppColors.text,
              ),
            ),
            Text(
              '$value utilisateurs ($percentage)',
              style: GoogleFonts.nunito(
                fontSize: 10,
                color: AppColors.textSub,
              ),
            ),
          ],
        ),
      ],
    );
  }
}
