import 'package:flutter/material.dart';
import 'package:lucide_icons/lucide_icons.dart';
import 'package:provider/provider.dart';
import 'package:google_fonts/google_fonts.dart';
import '../theme/app_theme.dart';
import '../services/app_state.dart';
import '../models/classroom.dart';

class CreateClassroomScreen extends StatefulWidget {
  const CreateClassroomScreen({super.key});

  @override
  State<CreateClassroomScreen> createState() => _CreateClassroomScreenState();
}

class _CreateClassroomScreenState extends State<CreateClassroomScreen> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _descriptionController = TextEditingController();

  // Dropdown selections
  String? _selectedFiliereId;
  String? _selectedNiveauId;
  String? _selectedMatiereId;
  String? _selectedClasseScolaireId;

  // Lists for dropdowns
  List<Map<String, dynamic>> _filieres = [];
  List<Map<String, dynamic>> _niveaux = [];
  List<Map<String, dynamic>> _matieres = [];
  List<Map<String, dynamic>> _classesScolaires = [];

  bool _isLoading = false;
  bool _isLoadingData = true;

  @override
  void initState() {
    super.initState();
    _loadInitialData();
  }

  @override
  void dispose() {
    _nameController.dispose();
    _descriptionController.dispose();
    super.dispose();
  }

  Future<void> _loadInitialData() async {
    setState(() => _isLoadingData = true);
    try {
      await context.read<AppState>().loadFilieres();
      await context.read<AppState>().loadMatieres();
      setState(() {
        _filieres = context.read<AppState>().filieres;
        _matieres = context.read<AppState>().matieres;
      });
    } catch (e) {
      print('⚠️ Error loading initial data: $e');
    } finally {
      setState(() => _isLoadingData = false);
    }
  }

  Future<void> _onFiliereChanged(String? filiereId) async {
    setState(() {
      _selectedFiliereId = filiereId;
      _selectedNiveauId = null;
      _selectedClasseScolaireId = null;
      _niveaux = [];
      _classesScolaires = [];
    });

    if (filiereId != null) {
      try {
        final niveaux = await context.read<AppState>().authService.fetchNiveauxByFiliere(filiereId);
        setState(() {
          _niveaux = niveaux;
        });
      } catch (e) {
        print('⚠️ Error loading niveaux: $e');
      }
    }
  }

  Future<void> _onNiveauChanged(String? niveauId) async {
    setState(() {
      _selectedNiveauId = niveauId;
      _selectedClasseScolaireId = null;
      _classesScolaires = [];
    });

    if (_selectedFiliereId != null && niveauId != null) {
      try {
        await context.read<AppState>().loadClassesScolaires();
        final allClasses = context.read<AppState>().classesScolaires;
        setState(() {
          _classesScolaires = allClasses.where((c) =>
            c['filiere_id'].toString() == _selectedFiliereId &&
            c['niveau_id'].toString() == niveauId
          ).toList();
        });
      } catch (e) {
        print('⚠️ Error loading classes scolaires: $e');
      }
    }
  }

  Future<void> _createClassroom() async {
    if (!_formKey.currentState!.validate()) return;
    if (_selectedFiliereId == null || _selectedNiveauId == null ||
        _selectedMatiereId == null || _selectedClasseScolaireId == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Veuillez sélectionner tous les champs obligatoires'),
          backgroundColor: AppColors.error,
        ),
      );
      return;
    }

    setState(() => _isLoading = true);

    try {
      // Create classroom with all the selected data
      final classroom = await context.read<AppState>().createClassroomWithSchoolClass(
        name: _nameController.text.trim(),
        description: _descriptionController.text.trim().isEmpty
            ? null
            : _descriptionController.text.trim(),
        filiereId: _selectedFiliereId!,
        niveauId: _selectedNiveauId!,
        matiereId: _selectedMatiereId!,
        classeScolaireId: _selectedClasseScolaireId!,
      );

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Classe créée avec succès! Les étudiants ont été importés automatiquement.'),
            backgroundColor: AppColors.success,
            duration: Duration(seconds: 4),
          ),
        );
        Navigator.pop(context, classroom);
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Erreur: $e'),
            backgroundColor: AppColors.error,
          ),
        );
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
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
          icon: const Icon(LucideIcons.arrowLeft),
          onPressed: () => Navigator.pop(context),
        ),
        title: Text(
          'Nouvelle Classroom',
          style: GoogleFonts.inter(
            fontSize: 18,
            fontWeight: FontWeight.w700,
            color: AppColors.text,
          ),
        ),
      ),
      body: _isLoadingData
          ? const Center(child: CircularProgressIndicator())
          : SingleChildScrollView(
              padding: const EdgeInsets.all(16),
              child: Form(
                key: _formKey,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    // Classroom info
                    Container(
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(color: AppColors.border, width: 0.5),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Informations de la classe',
                            style: GoogleFonts.inter(
                              fontSize: 16,
                              fontWeight: FontWeight.w600,
                              color: AppColors.text,
                            ),
                          ),
                          const SizedBox(height: 16),

                          // Name
                          TextFormField(
                            controller: _nameController,
                            style: GoogleFonts.nunito(fontSize: 14),
                            decoration: InputDecoration(
                              labelText: 'Nom de la classe *',
                              labelStyle: GoogleFonts.nunito(fontSize: 12, color: AppColors.textSub),
                              prefixIcon: const Icon(LucideIcons.tag, color: AppColors.primary, size: 20),
                              hintText: 'Ex: Mathématiques 3ème Année',
                              hintStyle: GoogleFonts.nunito(fontSize: 13, color: AppColors.textSub),
                              border: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(8),
                                borderSide: BorderSide(color: AppColors.border),
                              ),
                              focusedBorder: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(8),
                                borderSide: BorderSide(color: AppColors.primary),
                              ),
                              contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
                            ),
                            validator: (value) {
                              if (value == null || value.trim().isEmpty) {
                                return 'Veuillez entrer le nom de la classe';
                              }
                              return null;
                            },
                          ),
                          const SizedBox(height: 16),

                          // Description
                          TextFormField(
                            controller: _descriptionController,
                            style: GoogleFonts.nunito(fontSize: 14),
                            decoration: InputDecoration(
                              labelText: 'Description (optionnel)',
                              labelStyle: GoogleFonts.nunito(fontSize: 12, color: AppColors.textSub),
                              prefixIcon: const Icon(LucideIcons.fileText, color: AppColors.primary, size: 20),
                              hintText: 'Description détaillée de la classe...',
                              hintStyle: GoogleFonts.nunito(fontSize: 13, color: AppColors.textSub),
                              border: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(8),
                                borderSide: BorderSide(color: AppColors.border),
                              ),
                              focusedBorder: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(8),
                                borderSide: BorderSide(color: AppColors.primary),
                              ),
                              contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
                            ),
                            maxLines: 3,
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 24),

                    // School Structure Selection
                    Container(
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(color: AppColors.border, width: 0.5),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Structure Scolaire',
                            style: GoogleFonts.inter(
                              fontSize: 16,
                              fontWeight: FontWeight.w600,
                              color: AppColors.text,
                            ),
                          ),
                          const SizedBox(height: 16),

                          // Filière Dropdown
                          DropdownButtonFormField<String>(
                            value: _selectedFiliereId,
                            decoration: InputDecoration(
                              labelText: 'Filière *',
                              labelStyle: GoogleFonts.nunito(fontSize: 12, color: AppColors.textSub),
                              prefixIcon: const Icon(LucideIcons.graduationCap, color: AppColors.primary, size: 20),
                              border: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(8),
                                borderSide: BorderSide(color: AppColors.border),
                              ),
                              focusedBorder: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(8),
                                borderSide: BorderSide(color: AppColors.primary),
                              ),
                            ),
                            items: _filieres.map((filiere) {
                              return DropdownMenuItem<String>(
                                value: filiere['id'].toString(),
                                child: Text(
                                  filiere['nom']?.toString() ?? 'Sans nom',
                                  style: GoogleFonts.nunito(fontSize: 14),
                                ),
                              );
                            }).toList(),
                            onChanged: _onFiliereChanged,
                            validator: (value) {
                              if (value == null || value.isEmpty) {
                                return 'Veuillez sélectionner une filière';
                              }
                              return null;
                            },
                          ),
                          const SizedBox(height: 16),

                          // Niveau Dropdown
                          DropdownButtonFormField<String>(
                            value: _selectedNiveauId,
                            decoration: InputDecoration(
                              labelText: 'Niveau *',
                              labelStyle: GoogleFonts.nunito(fontSize: 12, color: AppColors.textSub),
                              prefixIcon: const Icon(LucideIcons.barChart2, color: AppColors.primary, size: 20),
                              border: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(8),
                                borderSide: BorderSide(color: AppColors.border),
                              ),
                              focusedBorder: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(8),
                                borderSide: BorderSide(color: AppColors.primary),
                              ),
                            ),
                            items: _niveaux.map((niveau) {
                              return DropdownMenuItem<String>(
                                value: niveau['id'].toString(),
                                child: Text(
                                  niveau['nom']?.toString() ?? 'Sans nom',
                                  style: GoogleFonts.nunito(fontSize: 14),
                                ),
                              );
                            }).toList(),
                            onChanged: _onNiveauChanged,
                            validator: (value) {
                              if (value == null || value.isEmpty) {
                                return 'Veuillez sélectionner un niveau';
                              }
                              return null;
                            },
                          ),
                          const SizedBox(height: 16),

                          // Matière Dropdown
                          DropdownButtonFormField<String>(
                            value: _selectedMatiereId,
                            decoration: InputDecoration(
                              labelText: 'Matière *',
                              labelStyle: GoogleFonts.nunito(fontSize: 12, color: AppColors.textSub),
                              prefixIcon: const Icon(LucideIcons.bookOpen, color: AppColors.primary, size: 20),
                              border: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(8),
                                borderSide: BorderSide(color: AppColors.border),
                              ),
                              focusedBorder: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(8),
                                borderSide: BorderSide(color: AppColors.primary),
                              ),
                            ),
                            items: _matieres.map((matiere) {
                              return DropdownMenuItem<String>(
                                value: matiere['id'].toString(),
                                child: Text(
                                  matiere['nom']?.toString() ?? 'Sans nom',
                                  style: GoogleFonts.nunito(fontSize: 14),
                                ),
                              );
                            }).toList(),
                            onChanged: (value) {
                              setState(() {
                                _selectedMatiereId = value;
                              });
                            },
                            validator: (value) {
                              if (value == null || value.isEmpty) {
                                return 'Veuillez sélectionner une matière';
                              }
                              return null;
                            },
                          ),
                          const SizedBox(height: 16),

                          // Classe Scolaire Dropdown
                          DropdownButtonFormField<String>(
                            value: _selectedClasseScolaireId,
                            decoration: InputDecoration(
                              labelText: 'Choisir une Classe Scolaire *',
                              labelStyle: GoogleFonts.nunito(fontSize: 12, color: AppColors.textSub),
                              prefixIcon: const Icon(LucideIcons.users, color: AppColors.primary, size: 20),
                              border: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(8),
                                borderSide: BorderSide(color: AppColors.border),
                              ),
                              focusedBorder: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(8),
                                borderSide: BorderSide(color: AppColors.primary),
                              ),
                            ),
                            items: _classesScolaires.map((classe) {
                              final nom = classe['nom']?.toString() ?? 'Sans nom';
                              final annee = classe['annee_scolaire']?.toString() ?? '';
                              final effectif = classe['effectif']?.toString() ?? '0';
                              return DropdownMenuItem<String>(
                                value: classe['id'].toString(),
                                child: Text(
                                  '$nom ($annee) - $effectif étudiants',
                                  style: GoogleFonts.nunito(fontSize: 14),
                                ),
                              );
                            }).toList(),
                            onChanged: (value) {
                              setState(() {
                                _selectedClasseScolaireId = value;
                              });
                            },
                            validator: (value) {
                              if (value == null || value.isEmpty) {
                                return 'Veuillez sélectionner une classe scolaire';
                              }
                              return null;
                            },
                          ),
                          if (_selectedClasseScolaireId != null)
                            Padding(
                              padding: const EdgeInsets.only(top: 8),
                              child: Text(
                                'Les étudiants seront importés automatiquement',
                                style: GoogleFonts.nunito(
                                  fontSize: 12,
                                  color: AppColors.success,
                                  fontStyle: FontStyle.italic,
                                ),
                              ),
                            ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 32),

                    // Submit button
                    Container(
                      width: double.infinity,
                      height: 48,
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          colors: [AppColors.success, AppColors.success.withOpacity(0.8)],
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                        ),
                        borderRadius: BorderRadius.circular(8),
                        boxShadow: [
                          BoxShadow(
                            color: AppColors.success.withOpacity(0.3),
                            blurRadius: 12,
                            offset: const Offset(0, 4),
                          ),
                        ],
                      ),
                      child: Material(
                        color: Colors.transparent,
                        child: InkWell(
                          borderRadius: BorderRadius.circular(8),
                          onTap: _isLoading ? null : _createClassroom,
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              if (_isLoading)
                                const SizedBox(
                                  width: 16,
                                  height: 16,
                                  child: CircularProgressIndicator(
                                    strokeWidth: 2,
                                    valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                                  ),
                                )
                              else ...[
                                const Icon(
                                  LucideIcons.plus,
                                  color: Colors.white,
                                  size: 20,
                                ),
                                const SizedBox(width: 8),
                                Text(
                                  'Créer la classe',
                                  style: GoogleFonts.nunito(
                                    fontSize: 14,
                                    fontWeight: FontWeight.w600,
                                    color: Colors.white,
                                  ),
                                ),
                              ],
                            ],
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
    );
  }
}
