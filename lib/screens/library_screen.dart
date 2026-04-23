import 'package:flutter/material.dart';
import 'package:lucide_icons/lucide_icons.dart';
import 'package:provider/provider.dart';
import '../theme/app_theme.dart';
import '../services/app_state.dart';
import '../widgets/common_widgets.dart';

class LibraryScreen extends StatelessWidget {
  const LibraryScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final state = context.watch<AppState>();

    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const SizedBox(height: 8),
          // Search bar
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
            decoration: BoxDecoration(
              color: AppColors.card,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: AppColors.border, width: 0.5),
            ),
            child: Row(
              children: const [
                Icon(LucideIcons.search, size: 16, color: AppColors.textSub),
                SizedBox(width: 10),
                Text('Rechercher un cours…',
                    style: TextStyle(
                        fontSize: 13, color: AppColors.textSub)),
              ],
            ),
          ),
          const SizedBox(height: 20),
          SectionTitle(title: 'Tous mes cours (${state.recentCourses.length})'),
          const SizedBox(height: 12),
          ...state.recentCourses.map((c) => _buildCourseCard(c)),
        ],
      ),
    );
  }

  Widget _buildCourseCard(dynamic course) {
    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      child: SkwCard(
        child: Row(
          children: [
            Container(
              width: 44,
              height: 44,
              decoration: BoxDecoration(
                color: AppColors.primaryLight,
                borderRadius: BorderRadius.circular(12),
              ),
              child: const Icon(LucideIcons.fileText,
                  size: 20, color: AppColors.primary),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(course.title,
                      style: const TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.w700,
                          color: AppColors.text)),
                  const SizedBox(height: 3),
                  Text(
                    '${course.pageCount} pages · ${course.questionCount} questions',
                    style: const TextStyle(
                        fontSize: 10, color: AppColors.textSub),
                  ),
                  const SizedBox(height: 6),
                  Row(children: [
                    SkwBadge(
                      label: '${(course.progress * 100).toInt()}%',
                      bgColor: course.progress >= 0.7
                          ? AppColors.successLight
                          : AppColors.orangeLight,
                      textColor: course.progress >= 0.7
                          ? AppColors.success
                          : AppColors.orangeDark,
                    ),
                    const SizedBox(width: 6),
                    ...course.keywords
                        .take(2)
                        .map<Widget>((k) => Padding(
                              padding: const EdgeInsets.only(right: 4),
                              child: SkwBadge(
                                label: k,
                                bgColor: AppColors.primaryLight,
                                textColor: AppColors.primary,
                              ),
                            ))
                        .toList(),
                  ]),
                ],
              ),
            ),
            const Icon(LucideIcons.chevronRight,
                size: 16, color: AppColors.textSub),
          ],
        ),
      ),
    );
  }
}
