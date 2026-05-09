import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:lucide_icons/lucide_icons.dart';
import 'package:provider/provider.dart';
import '../theme/app_theme.dart';
import '../services/app_state.dart';
import 'lesson_upload_screen.dart';

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
  List<Map<String, dynamic>> _courses = [];
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    _loadCourses();
  }

  Future<void> _loadCourses() async {
    setState(() => _isLoading = true);
    try {
      await context.read<AppState>().loadAdminCourses();
      final allCourses = context.read<AppState>().adminCourses;
      // Filtrer par filière et matière si ces colonnes existent
      setState(() {
        _courses = allCourses.where((course) {
          final courseFiliere = course['filiere'] as String?;
          final courseSubject = course['subject'] as String?;
          return (courseFiliere == widget.filiere || courseFiliere == null) &&
                 (courseSubject == widget.subject || courseSubject == null);
        }).toList();
      });
    } catch (e) {
      print('⚠️ Error loading courses: $e');
    } finally {
      setState(() => _isLoading = false);
    }
  }

  Future<void> _deleteCourse(String courseId) async {
    try {
      await context.read<AppState>().deleteCourse(courseId);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Cours supprimé', style: GoogleFonts.inter(fontWeight: FontWeight.w600)),
          backgroundColor: AppColors.error,
          duration: const Duration(seconds: 2),
        ),
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Erreur: $e', style: GoogleFonts.inter(fontWeight: FontWeight.w600)),
          backgroundColor: AppColors.error,
          duration: const Duration(seconds: 2),
        ),
      );
    }
  }

  Future<void> _showAddCourseDialog() async {
    final result = await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => LessonUploadScreen(
          filiere: widget.filiere,
          subject: widget.subject,
          semester: 'Semestre 1',
        ),
      ),
    );
    
    if (result == true) {
      _loadCourses();
    }
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
          IconButton(
            onPressed: _showAddCourseDialog,
            icon: Icon(LucideIcons.plus, color: AppColors.primary),
            tooltip: 'Ajouter un cours',
          ),
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
                          label: 'Cours',
                          value: '${_courses.length}',
                          icon: LucideIcons.layers,
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: _QuickStat(
                          label: 'Total',
                          value: '${context.watch<AppState>().adminCourses.length}',
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
              'Liste des cours',
              style: GoogleFonts.inter(
                fontSize: 18,
                fontWeight: FontWeight.w700,
                color: AppColors.text,
              ),
            ),
            const SizedBox(height: 16),
            
            if (_isLoading)
              const Center(child: CircularProgressIndicator())
            else if (_courses.isEmpty)
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
                      'Aucun cours disponible pour ${widget.filiere} - ${widget.subject}',
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
                itemCount: _courses.length,
                separatorBuilder: (_, __) => const SizedBox(height: 12),
                itemBuilder: (context, i) {
                  final course = _courses[i];
                  return _CourseCard(
                    course: course,
                    onDelete: () => _deleteCourse(course['id']),
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

class _CourseCard extends StatelessWidget {
  final Map<String, dynamic> course;
  final VoidCallback onDelete;

  const _CourseCard({
    required this.course,
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
                      course['title'] ?? 'Sans titre',
                      style: GoogleFonts.inter(
                        fontSize: 16,
                        fontWeight: FontWeight.w700,
                        color: AppColors.text,
                      ),
                    ),
                    Text(
                      course['file_name'] ?? 'Sans fichier',
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
        ],
      ),
    );
  }
}
