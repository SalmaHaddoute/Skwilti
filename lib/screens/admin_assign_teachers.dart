import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:lucide_icons/lucide_icons.dart';
import 'package:provider/provider.dart';
import '../theme/app_theme.dart';
import '../services/app_state.dart';
import '../widgets/empty_state.dart';
import '../widgets/astronaut_illustration.dart';

class AdminAssignTeachersScreen extends StatefulWidget {
  final String classeId;
  final String classeNom;
  
  const AdminAssignTeachersScreen({
    super.key,
    required this.classeId,
    required this.classeNom,
  });

  @override
  State<AdminAssignTeachersScreen> createState() => _AdminAssignTeachersScreenState();
}

class _AdminAssignTeachersScreenState extends State<AdminAssignTeachersScreen> {
  List<Map<String, dynamic>> _assignments = [];
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    _loadAssignments();
  }

  Future<void> _loadAssignments() async {
    setState(() => _isLoading = true);
    try {
      final assignments = await context.read<AppState>().fetchClasseProfs(widget.classeId);
      setState(() => _assignments = assignments);
    } catch (e) {
      print('Error loading assignments: $e');
    } finally {
      setState(() => _isLoading = false);
    }
  }

  void _showAddAssignmentDialog() {
    showDialog(
      context: context,
      builder: (context) => _AddAssignmentDialog(
        classeId: widget.classeId,
        onAdded: () {
          _loadAssignments();
        },
      ),
    );
  }

  Future<void> _removeAssignment(String assignmentId) async {
    try {
      await context.read<AppState>().deleteClasseProf(assignmentId);
      _loadAssignments();
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Affectation supprimée'), backgroundColor: AppColors.success),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Erreur: $e'), backgroundColor: AppColors.error),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.transparent,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        title: Text(
          'Affecter les professeurs',
          style: GoogleFonts.inter(
            fontSize: 18,
            fontWeight: FontWeight.w700,
            color: AppColors.text,
          ),
        ),
        leading: IconButton(
          icon: const Icon(LucideIcons.chevronLeft, color: AppColors.primary),
          onPressed: () => Navigator.pop(context),
        ),
        actions: [
          IconButton(
            icon: const Icon(LucideIcons.plus, color: AppColors.primary),
            onPressed: _showAddAssignmentDialog,
          ),
        ],
      ),
      body: Column(
        children: [
          Container(
            padding: const EdgeInsets.all(16),
            color: Colors.white,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  widget.classeNom,
                  style: GoogleFonts.inter(
                    fontSize: 20,
                    fontWeight: FontWeight.w700,
                    color: AppColors.text,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  'Affectez des professeurs aux matières de cette classe',
                  style: GoogleFonts.inter(
                    fontSize: 14,
                    color: AppColors.textSub,
                  ),
                ),
              ],
            ),
          ),
          Expanded(
            child: _isLoading
                ? const Center(child: CircularProgressIndicator())
                : _assignments.isEmpty
                    ? EmptyStatePage(
                        emptyState: EmptyState(
                          title: 'Aucune affectation',
                          subtitle: 'Appuyez sur + pour ajouter une affectation d\'enseignant.',
                          astronautType: AstronautType.welcome,
                        ),
                      )
                    : ListView.builder(
                        padding: const EdgeInsets.all(16),
                        itemCount: _assignments.length,
                        itemBuilder: (context, index) {
                          final assignment = _assignments[index];
                          return _AssignmentCard(
                            assignment: assignment,
                            onRemove: () => _removeAssignment(assignment['id'].toString()),
                          );
                        },
                      ),
          ),
        ],
      ),
    );
  }
}

class _AssignmentCard extends StatelessWidget {
  final Map<String, dynamic> assignment;
  final VoidCallback onRemove;

  const _AssignmentCard({
    required this.assignment,
    required this.onRemove,
  });

  @override
  Widget build(BuildContext context) {
    final matiereNom = assignment['matieres']?['nom'] ?? 'N/A';
    final profNom = '${assignment['profiles']?['first_name'] ?? ''} ${assignment['profiles']?['last_name'] ?? ''}';

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.border, width: 0.5),
      ),
      child: Row(
        children: [
          Container(
            width: 48,
            height: 48,
            decoration: BoxDecoration(
              color: AppColors.primary.withOpacity(0.1),
              borderRadius: BorderRadius.circular(12),
            ),
            child: const Icon(LucideIcons.bookOpen, color: AppColors.primary),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  matiereNom,
                  style: GoogleFonts.inter(
                    fontSize: 16,
                    fontWeight: FontWeight.w700,
                    color: AppColors.text,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  profNom,
                  style: GoogleFonts.inter(
                    fontSize: 14,
                    color: AppColors.textSub,
                  ),
                ),
              ],
            ),
          ),
          IconButton(
            icon: const Icon(LucideIcons.trash2, color: AppColors.error),
            onPressed: onRemove,
          ),
        ],
      ),
    );
  }
}

class _AddAssignmentDialog extends StatefulWidget {
  final String classeId;
  final VoidCallback onAdded;

  const _AddAssignmentDialog({
    required this.classeId,
    required this.onAdded,
  });

  @override
  State<_AddAssignmentDialog> createState() => _AddAssignmentDialogState();
}

class _AddAssignmentDialogState extends State<_AddAssignmentDialog> {
  String? _selectedMatiereId;
  String? _selectedProfesseurId;
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<AppState>().loadMatieres();
      context.read<AppState>().loadTeachers();
    });
  }

  Future<void> _addAssignment() async {
    if (_selectedMatiereId == null || _selectedProfesseurId == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Veuillez sélectionner une matière et un professeur'), backgroundColor: AppColors.error),
      );
      return;
    }

    setState(() => _isLoading = true);

    try {
      await context.read<AppState>().createClasseProf(
        classeId: widget.classeId,
        matiereId: _selectedMatiereId!,
        professeurId: _selectedProfesseurId!,
      );

      if (mounted) {
        Navigator.pop(context);
        widget.onAdded();
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Affectation ajoutée'), backgroundColor: AppColors.success),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Erreur: $e'), backgroundColor: AppColors.error),
        );
      }
    } finally {
      setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final matieres = context.watch<AppState>().matieres;
    final teachers = context.watch<AppState>().teachers;

    return AlertDialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      title: Text(
        'Affecter un professeur',
        style: GoogleFonts.inter(fontWeight: FontWeight.w700, fontSize: 18),
      ),
      content: SizedBox(
        width: 400,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: AppColors.border, width: 0.5),
              ),
              child: DropdownButtonFormField<String>(
                initialValue: _selectedMatiereId,
                isExpanded: true,
                decoration: InputDecoration(
                  labelText: 'Matière',
                  prefixIcon: const Icon(LucideIcons.bookOpen, color: AppColors.primary, size: 20),
                  border: InputBorder.none,
                  contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
                  labelStyle: GoogleFonts.inter(fontSize: 13, color: AppColors.textSub),
                ),
                items: matieres.map((m) => DropdownMenuItem<String>(
                  value: m['id']?.toString(),
                  child: Text(
                    m['nom']?.toString() ?? '',
                    style: GoogleFonts.inter(fontSize: 14),
                    overflow: TextOverflow.ellipsis,
                    maxLines: 1,
                  ),
                )).toList(),
                onChanged: (v) => setState(() => _selectedMatiereId = v),
              ),
            ),
            const SizedBox(height: 16),
            Container(
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: AppColors.border, width: 0.5),
              ),
              child: DropdownButtonFormField<String>(
                initialValue: _selectedProfesseurId,
                isExpanded: true,
                decoration: InputDecoration(
                  labelText: 'Professeur',
                  prefixIcon: const Icon(LucideIcons.user, color: AppColors.primary, size: 20),
                  border: InputBorder.none,
                  contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
                  labelStyle: GoogleFonts.inter(fontSize: 13, color: AppColors.textSub),
                ),
                items: teachers.map((t) => DropdownMenuItem<String>(
                  value: t['id']?.toString(),
                  child: Text(
                    '${t['first_name'] ?? ''} ${t['last_name'] ?? ''}',
                    style: GoogleFonts.inter(fontSize: 14),
                    overflow: TextOverflow.ellipsis,
                    maxLines: 1,
                  ),
                )).toList(),
                onChanged: (v) => setState(() => _selectedProfesseurId = v),
              ),
            ),
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: Text('Annuler', style: GoogleFonts.inter(color: AppColors.textSub)),
        ),
        ElevatedButton(
          onPressed: _isLoading ? null : _addAssignment,
          style: ElevatedButton.styleFrom(
            backgroundColor: AppColors.primary,
            foregroundColor: Colors.white,
            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          ),
          child: _isLoading
              ? const SizedBox(height: 20, width: 20, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2))
              : Text('Ajouter', style: GoogleFonts.inter(fontWeight: FontWeight.w600)),
        ),
      ],
    );
  }
}
