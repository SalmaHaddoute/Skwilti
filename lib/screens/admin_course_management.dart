import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:lucide_icons/lucide_icons.dart';
import '../theme/app_theme.dart';

class AdminCourseManagementScreen extends StatefulWidget {
  final String filiere;
  final String subject;

  const AdminCourseManagementScreen({
    super.key,
    required this.filiere,
    required this.subject,
  });

  @override
  _AdminCourseManagementScreenState createState() => _AdminCourseManagementScreenState();
}

class _AdminCourseManagementScreenState extends State<AdminCourseManagementScreen> {
  // Cours par filière → matière → semestre
  static const _curriculum = <String, Map<String, List<Map<String, dynamic>>>>{
    'Tronc Commun': {
      'Maths': [
        {'title': 'Semestre 1', 'count': 12, 'lessons': ['Algèbre', 'Géométrie', 'Fonctions', 'Statistiques']},
        {'title': 'Semestre 2', 'count': 14, 'lessons': ['Nombres complexes', 'Suites', 'Intégrales', 'Probabilités']},
      ],
      'Physique-Chimie': [
        {'title': 'Semestre 1', 'count': 10, 'lessons': ['Mécanique', 'Thermodynamique', 'Optique']},
        {'title': 'Semestre 2', 'count': 11, 'lessons': ['Électricité', 'Chimie organique', 'Réactions chimiques']},
      ],
    },
    '1ère Année Baccalauréat': {
      'Maths': [
        {'title': 'Semestre 1', 'count': 15, 'lessons': ['Limites', 'Dérivées', 'Fonctions exponentielles']},
        {'title': 'Semestre 2', 'count': 16, 'lessons': ['Logarithmes', 'Trigonométrie', 'Géométrie analytique']},
      ],
    },
    '2ème Année Baccalauréat': {
      'Maths': [
        {'title': 'Semestre 1', 'count': 18, 'lessons': ['Espaces vectoriels', 'Matrices', 'Systèmes linéaires']},
        {'title': 'Semestre 2', 'count': 20, 'lessons': ['Probabilités avancées', 'Statistiques inférentielles', 'Séries']},
      ],
    },
  };

  List<Map<String, dynamic>> get _currentSemesters {
    final curriculum = _curriculum[widget.filiere]?[widget.subject] ?? [];
    return curriculum;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        leading: IconButton(
          onPressed: () => Navigator.pop(context),
          icon: Icon(LucideIcons.arrowLeft, color: AppColors.text),
        ),
        title: Text(
          'Gestion des cours',
          style: GoogleFonts.inter(
            fontSize: 18,
            fontWeight: FontWeight.w700,
            color: AppColors.text,
          ),
        ),
        actions: [
          Container(
            margin: const EdgeInsets.only(right: 16),
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
            decoration: BoxDecoration(
              color: AppColors.primary.withOpacity(0.1),
              borderRadius: BorderRadius.circular(20),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(LucideIcons.bookOpen, size: 16, color: AppColors.primary),
                const SizedBox(width: 4),
                Text(
                  '${widget.subject}',
                  style: GoogleFonts.inter(
                    fontSize: 12,
                    fontWeight: FontWeight.w700,
                    color: AppColors.primary,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16).copyWith(bottom: 32),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header Section
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [AppColors.primary, AppColors.primary.withOpacity(0.8)],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                borderRadius: BorderRadius.circular(16),
                boxShadow: [
                  BoxShadow(
                    color: AppColors.primary.withOpacity(0.2),
                    blurRadius: 12,
                    offset: const Offset(0, 4),
                  ),
                ],
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: Colors.white.withOpacity(0.2),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Icon(
                          LucideIcons.settings,
                          size: 28,
                          color: Colors.white,
                        ),
                      ),
                      const SizedBox(width: 16),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Gestion complète',
                              style: GoogleFonts.inter(
                                fontSize: 20,
                                fontWeight: FontWeight.w800,
                                color: Colors.white,
                              ),
                            ),
                            Text(
                              '${widget.filiere} - ${widget.subject}',
                              style: GoogleFonts.inter(
                                fontSize: 14,
                                color: Colors.white.withOpacity(0.9),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  Row(
                    children: [
                      Expanded(
                        child: _QuickStat(
                          label: 'Semestres',
                          value: '${_currentSemesters.length}',
                          icon: LucideIcons.layers,
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: _QuickStat(
                          label: 'Total leçons',
                          value: '${_currentSemesters.fold<int>(0, (sum, sem) => sum + (sem['count'] as int))}',
                          icon: LucideIcons.fileText,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            const SizedBox(height: 24),

            // Courses List
            Text(
              'Liste des semestres',
              style: GoogleFonts.inter(
                fontSize: 18,
                fontWeight: FontWeight.w700,
                color: AppColors.text,
              ),
            ),
            const SizedBox(height: 16),
            
            if (_currentSemesters.isEmpty)
              Container(
                padding: const EdgeInsets.all(32),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: AppColors.border, width: 0.5),
                ),
                child: Column(
                  children: [
                    Icon(
                      LucideIcons.bookOpen,
                      size: 48,
                      color: AppColors.textSub,
                    ),
                    const SizedBox(height: 16),
                    Text(
                      'Aucun cours trouvé',
                      style: GoogleFonts.inter(
                        fontSize: 16,
                        fontWeight: FontWeight.w700,
                        color: AppColors.text,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      'Aucun cours disponible pour cette matière',
                      style: GoogleFonts.inter(
                        fontSize: 12,
                        color: AppColors.textSub,
                      ),
                    ),
                  ],
                ),
              )
            else
              ListView.separated(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                itemCount: _currentSemesters.length,
                separatorBuilder: (_, __) => const SizedBox(height: 12),
                itemBuilder: (context, i) {
                  final sem = _currentSemesters[i];
                  return _SemesterCard(
                    title: sem['title'] as String,
                    lessonCount: sem['count'] as int,
                    lessons: (sem['lessons'] as List<String>),
                    onDelete: () {
                      setState(() {
                        // Remove semester logic would go here
                      });
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(
                          content: Text(
                            '${sem['title']} supprimé',
                            style: GoogleFonts.inter(fontWeight: FontWeight.w600),
                          ),
                          backgroundColor: AppColors.error,
                          duration: const Duration(seconds: 2),
                        ),
                      );
                    },
                  );
                },
              ),
          ],
        ),
      ),
    );
  }
}

class _QuickStat extends StatelessWidget {
  final String label;
  final String value;
  final IconData icon;

  const _QuickStat({
    required this.label,
    required this.value,
    required this.icon,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.2),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.white.withOpacity(0.3), width: 1),
      ),
      child: Row(
        children: [
          Icon(icon, size: 16, color: Colors.white),
          const SizedBox(width: 8),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  value,
                  style: GoogleFonts.inter(
                    fontSize: 16,
                    fontWeight: FontWeight.w800,
                    color: Colors.white,
                  ),
                ),
                Text(
                  label,
                  style: GoogleFonts.inter(
                    fontSize: 10,
                    color: Colors.white.withOpacity(0.8),
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

class _SemesterCard extends StatelessWidget {
  final String title;
  final int lessonCount;
  final List<String> lessons;
  final VoidCallback onDelete;

  const _SemesterCard({
    required this.title,
    required this.lessonCount,
    required this.lessons,
    required this.onDelete,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.border, width: 0.5),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: GoogleFonts.inter(
                        fontSize: 16,
                        fontWeight: FontWeight.w700,
                        color: AppColors.text,
                      ),
                    ),
                    Text(
                      '$lessonCount leçons',
                      style: GoogleFonts.inter(
                        fontSize: 12,
                        color: AppColors.textSub,
                      ),
                    ),
                  ],
                ),
              ),
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: AppColors.error.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: IconButton(
                  onPressed: onDelete,
                  icon: Icon(
                    LucideIcons.x,
                    size: 20,
                    color: AppColors.error,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          if (lessons.isNotEmpty)
            Column(
              children: lessons.map((lesson) {
                return Container(
                  width: double.infinity,
                  margin: const EdgeInsets.only(bottom: 8),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: AppColors.border, width: 0.5),
                  ),
                  child: Row(
                    children: [
                      // Image de la leçon
                      Container(
                        width: 60,
                        height: 60,
                        decoration: BoxDecoration(
                          borderRadius: const BorderRadius.horizontal(left: Radius.circular(8)),
                          image: const DecorationImage(
                            image: AssetImage('assets/images/image.png'),
                            fit: BoxFit.cover,
                          ),
                        ),
                      ),
                      Expanded(
                        child: Padding(
                          padding: const EdgeInsets.all(12),
                          child: Row(
                            children: [
                              Expanded(
                                child: Text(
                                  lesson,
                                  style: GoogleFonts.inter(
                                    fontSize: 12,
                                    fontWeight: FontWeight.w600,
                                    color: AppColors.text,
                                  ),
                                ),
                              ),
                              GestureDetector(
                                onTap: () {
                                  ScaffoldMessenger.of(context).showSnackBar(
                                    SnackBar(
                                      content: Text(
                                        'Leçon "$lesson" supprimée',
                                        style: GoogleFonts.inter(fontWeight: FontWeight.w600),
                                      ),
                                      backgroundColor: AppColors.error,
                                      duration: const Duration(seconds: 2),
                                    ),
                                  );
                                },
                                child: Icon(
                                  LucideIcons.x,
                                  size: 16,
                                  color: AppColors.error,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ],
                  ),
                );
              }).toList(),
            ),
        ],
      ),
    );
  }
}
