import 'package:flutter/material.dart';
import 'package:lucide_icons/lucide_icons.dart';
import 'package:provider/provider.dart';
import '../theme/app_theme.dart';
import '../services/app_state.dart';
import '../widgets/common_widgets.dart';

class HomeScreen extends StatelessWidget {
  final Function(int) onNavTap;

  const HomeScreen({super.key, required this.onNavTap});

  @override
  Widget build(BuildContext context) {
    final state = context.watch<AppState>();

    return SingleChildScrollView(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildHeader(state),
          Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _buildQuickGrid(context),
                const SizedBox(height: 20),
                _buildProgressCard(state),
                const SizedBox(height: 20),
                SectionTitle(
                    title: 'Cours récents', action: 'Voir tout', onAction: () => onNavTap(2)),
                const SizedBox(height: 12),
                ...state.recentCourses.map((c) => _buildCourseRow(context, c)),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildHeader(AppState state) {
    return Container(
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          colors: [AppColors.primary, Color(0xFF8B4AEA), AppColors.orange],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.only(
          bottomLeft: Radius.circular(24),
          bottomRight: Radius.circular(24),
        ),
      ),
      padding: const EdgeInsets.fromLTRB(18, 14, 18, 20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                const Text('Bonjour 👋',
                    style: TextStyle(fontSize: 12, color: Colors.white70)),
                const SizedBox(height: 2),
                const Text('Yassine',
                    style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.w800,
                        color: Colors.white)),
              ]),
              Container(
                width: 38,
                height: 38,
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.25),
                  shape: BoxShape.circle,
                  border: Border.all(
                      color: Colors.white.withOpacity(0.5), width: 1.5),
                ),
                child: const Icon(LucideIcons.user,
                    size: 18, color: Colors.white),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              _buildStatBadge(
                  LucideIcons.flame, '${state.streak} jours', AppColors.orange),
              const SizedBox(width: 8),
              _buildStatBadge(
                  LucideIcons.zap, '${state.xp} XP', Colors.white.withOpacity(0.25)),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildStatBadge(IconData icon, String label, Color bg) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 5),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(99),
      ),
      child: Row(
        children: [
          Icon(icon, size: 13, color: Colors.white),
          const SizedBox(width: 5),
          Text(label,
              style: const TextStyle(
                  fontSize: 11,
                  fontWeight: FontWeight.w700,
                  color: Colors.white)),
        ],
      ),
    );
  }

  Widget _buildQuickGrid(BuildContext context) {
    return GridView.count(
      crossAxisCount: 2,
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      crossAxisSpacing: 10,
      mainAxisSpacing: 10,
      childAspectRatio: 1.55,
      children: [
        QuickCard(
          icon: LucideIcons.plus,
          label: 'Nouveau QCM',
          subtitle: 'Uploader un cours',
          iconBg: AppColors.orange,
          cardBg: AppColors.orangeLight,
          onTap: () => onNavTap(1),
        ),
        QuickCard(
          icon: LucideIcons.bookOpen,
          label: 'Bibliothèque',
          subtitle: '12 cours sauvegardés',
          iconBg: AppColors.primary,
          cardBg: AppColors.primaryLight,
          onTap: () => onNavTap(2),
        ),
        QuickCard(
          icon: LucideIcons.layers,
          label: 'Flashcards',
          subtitle: '48 cartes actives',
          iconBg: AppColors.primary,
          cardBg: AppColors.primaryLight,
        ),
        QuickCard(
          icon: LucideIcons.barChart2,
          label: 'Mes statistiques',
          subtitle: 'Score moyen ${(context.read<AppState>().avgScore * 100).toInt()}%',
          iconBg: AppColors.orange,
          cardBg: AppColors.orangeLight,
        ),
      ],
    );
  }

  Widget _buildProgressCard(AppState state) {
    return SkwCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(children: [
            const Icon(LucideIcons.trendingUp, size: 16, color: AppColors.orange),
            const SizedBox(width: 7),
            const Text('Ma progression',
                style: TextStyle(fontSize: 13, fontWeight: FontWeight.w700)),
          ]),
          const SizedBox(height: 14),
          Row(children: [
            _buildStatBox('${(state.avgScore * 100).toInt()}%', 'Score moyen',
                AppColors.orange),
            const SizedBox(width: 8),
            _buildStatBox('${state.streak}', 'Jours de suite',
                AppColors.primary),
            const SizedBox(width: 8),
            _buildStatBox('${state.xp}', 'XP total', AppColors.success),
          ]),
        ],
      ),
    );
  }

  Widget _buildStatBox(String value, String label, Color color) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.all(10),
        decoration: BoxDecoration(
          color: AppColors.background,
          borderRadius: BorderRadius.circular(10),
        ),
        child: Column(
          children: [
            Text(value,
                style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.w800,
                    color: color)),
            const SizedBox(height: 2),
            Text(label,
                textAlign: TextAlign.center,
                style: const TextStyle(
                    fontSize: 9, color: AppColors.textSub, height: 1.3)),
          ],
        ),
      ),
    );
  }

  Widget _buildCourseRow(BuildContext context, dynamic course) {
    final iconColors = [AppColors.orangeLight, AppColors.primaryLight, AppColors.successLight];
    final iconFgColors = [AppColors.orange, AppColors.primary, AppColors.success];
    final icons = [LucideIcons.microscope, LucideIcons.sigma, LucideIcons.activity];

    final idx = context.read<AppState>().recentCourses.indexOf(course) % 3;

    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      child: SkwCard(
        padding: const EdgeInsets.all(11),
        child: Row(
          children: [
            Container(
              width: 38,
              height: 38,
              decoration: BoxDecoration(
                color: iconColors[idx],
                borderRadius: BorderRadius.circular(11),
              ),
              child: Icon(icons[idx], size: 18, color: iconFgColors[idx]),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(course.title,
                      style: const TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w700,
                          color: AppColors.text),
                      overflow: TextOverflow.ellipsis),
                  const SizedBox(height: 2),
                  Text('${course.pageCount} pages · ${course.questionCount} questions',
                      style: const TextStyle(
                          fontSize: 10, color: AppColors.textSub)),
                  const SizedBox(height: 6),
                  ClipRRect(
                    borderRadius: BorderRadius.circular(99),
                    child: LinearProgressIndicator(
                      value: course.progress,
                      minHeight: 3,
                      backgroundColor: AppColors.border,
                      valueColor: AlwaysStoppedAnimation(iconFgColors[idx]),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(width: 8),
            const Icon(LucideIcons.chevronRight,
                size: 14, color: AppColors.textSub),
          ],
        ),
      ),
    );
  }
}
