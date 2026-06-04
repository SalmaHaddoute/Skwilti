import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:lucide_icons/lucide_icons.dart';
import 'package:provider/provider.dart';
import '../theme/app_theme.dart';
import '../services/app_state.dart';
import '../widgets/empty_state.dart';
import 'admin_create_class.dart';
import 'admin_assign_teachers.dart';
import 'admin_students_list.dart';

class AdminClassesManagementScreen extends StatefulWidget {
  const AdminClassesManagementScreen({super.key});

  @override
  State<AdminClassesManagementScreen> createState() => _AdminClassesManagementScreenState();
}

class _AdminClassesManagementScreenState extends State<AdminClassesManagementScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<AppState>().loadClassesScolaires();
    });
  }

  @override
  Widget build(BuildContext context) {
    final classes = context.watch<AppState>().classesScolaires;
    final loaded = context.watch<AppState>().classesScolairesLoaded;

    return Scaffold(
      backgroundColor: Colors.transparent,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        title: Text(
          'Gestion des Classes',
          style: GoogleFonts.inter(
            fontSize: 18,
            fontWeight: FontWeight.w700,
            color: AppColors.text,
          ),
        ),
        leading: IconButton(
          icon: const Icon(LucideIcons.arrowLeft, color: AppColors.primary),
          onPressed: () {
            Navigator.pop(context);
          },
        ),
        actions: [
          IconButton(
            icon: const Icon(LucideIcons.plus, color: AppColors.primary),
            onPressed: () async {
              await Navigator.push(
                context,
                MaterialPageRoute(builder: (_) => const AdminCreateClassScreen()),
              );
              if (mounted) {
                context.read<AppState>().loadClassesScolaires();
              }
            },
          ),
        ],
      ),
      body: loaded
          ? classes.isEmpty
              ? const EmptyStatePage(
                  emptyState: EmptyStateClasses(),
                )
              : ListView.builder(
                  padding: const EdgeInsets.all(16),
                  itemCount: classes.length,
                  itemBuilder: (context, index) {
                    final classe = classes[index];
                    return _ClassCard(
                      classe: classe,
                      onAssignTeachers: () async {
                        await Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (_) => AdminAssignTeachersScreen(
                              classeId: classe['id'].toString(),
                              classeNom: _getClasseNom(classe),
                            ),
                          ),
                        );
                        if (mounted) {
                          context.read<AppState>().loadClassesScolaires();
                        }
                      },
                      onAddStudent: () async {
                        await Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (_) => AdminStudentsListScreen(
                              classeId: classe['id'].toString(),
                              classeNom: _getClasseNom(classe),
                            ),
                          ),
                        );
                        if (mounted) {
                          context.read<AppState>().loadClassesScolaires();
                        }
                      },
                    );
                  },
                )
          : const Center(child: CircularProgressIndicator()),
    );
  }

  String _getClasseNom(Map<String, dynamic> classe) {
    final nom = classe['nom']?.toString() ?? '';
    final filiere = classe['filieres']?['nom']?.toString() ?? '';
    final niveau = classe['niveaux']?['nom']?.toString() ?? '';
    final annee = classe['annee_scolaire']?.toString() ?? '';
    
    if (filiere.isNotEmpty && niveau.isNotEmpty) {
      return '$nom - $filiere $niveau ($annee)';
    }
    return '$nom ($annee)';
  }
}

class _ClassCard extends StatelessWidget {
  final Map<String, dynamic> classe;
  final VoidCallback onAssignTeachers;
  final VoidCallback onAddStudent;

  const _ClassCard({
    required this.classe,
    required this.onAssignTeachers,
    required this.onAddStudent,
  });

  @override
  Widget build(BuildContext context) {
    final nom = classe['nom']?.toString() ?? '';
    final filiere = classe['filieres']?['nom']?.toString() ?? '';
    final niveau = classe['niveaux']?['nom']?.toString() ?? '';
    final annee = classe['annee_scolaire']?.toString() ?? '';
    final effectif = classe['effectif'] ?? 0;
    final isActive = classe['is_active'] ?? true;
    
    // Couleur basée sur la filière
    final colors = [
      AppColors.primary, AppColors.info, AppColors.success, 
      AppColors.warning, AppColors.error, Colors.purple
    ];
    final colorIndex = nom.hashCode % colors.length;
    final color = colors[colorIndex];

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
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
              Container(
                width: 48,
                height: 48,
                decoration: BoxDecoration(
                  color: AppColors.primary.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: const Icon(LucideIcons.graduationCap, color: AppColors.primary),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      nom,
                      style: GoogleFonts.inter(
                        fontSize: 16,
                        fontWeight: FontWeight.w700,
                        color: AppColors.text,
                      ),
                    ),
                    const SizedBox(height: 4),
                    if (filiere.isNotEmpty || niveau.isNotEmpty)
                      Text(
                        '$filiere $niveau',
                        style: GoogleFonts.inter(
                          fontSize: 14,
                          color: AppColors.textSub,
                        ),
                      ),
                  ],
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: isActive ? AppColors.success.withOpacity(0.1) : AppColors.textSub.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(
                  isActive ? 'Active' : 'Inactive',
                  style: GoogleFonts.inter(
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                    color: isActive ? AppColors.success : AppColors.textSub,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              const Icon(LucideIcons.calendar, size: 16, color: AppColors.textSub),
              const SizedBox(width: 4),
              Text(
                annee,
                style: GoogleFonts.inter(fontSize: 12, color: AppColors.textSub),
              ),
              const SizedBox(width: 16),
              const Icon(LucideIcons.users, size: 16, color: AppColors.textSub),
              const SizedBox(width: 4),
              Text(
                '$effectif étudiants',
                style: GoogleFonts.inter(fontSize: 12, color: AppColors.textSub),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Container(
            height: 1,
            color: AppColors.border,
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(
                child: OutlinedButton.icon(
                  onPressed: onAssignTeachers,
                  icon: const Icon(LucideIcons.graduationCap, size: 16),
                  label: Text('Affecter profs', style: GoogleFonts.inter(fontSize: 13)),
                  style: OutlinedButton.styleFrom(
                    foregroundColor: AppColors.primary,
                    side: const BorderSide(color: AppColors.primary),
                    padding: const EdgeInsets.symmetric(vertical: 12),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: ElevatedButton.icon(
                  onPressed: onAddStudent,
                  icon: const Icon(LucideIcons.userPlus, size: 16),
                  label: Text('Ajouter étudiant', style: GoogleFonts.inter(fontSize: 13)),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.primary,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 12),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
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
