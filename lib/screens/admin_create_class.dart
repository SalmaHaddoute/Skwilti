import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:lucide_icons/lucide_icons.dart';
import 'package:provider/provider.dart';
import '../theme/app_theme.dart';
import '../services/app_state.dart';

class AdminCreateClassScreen extends StatefulWidget {
  const AdminCreateClassScreen({super.key});

  @override
  State<AdminCreateClassScreen> createState() => _AdminCreateClassScreenState();
}

class _AdminCreateClassScreenState extends State<AdminCreateClassScreen> {
  final _formKey = GlobalKey<FormState>();
  final _nomController = TextEditingController();
  final _anneeScolaireController = TextEditingController(text: '2025-2026');
  
  String? _selectedFiliereId;
  String? _selectedNiveauId;
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<AppState>().loadFilieres();
      context.read<AppState>().loadNiveaux();
    });
  }

  @override
  void dispose() {
    _nomController.dispose();
    _anneeScolaireController.dispose();
    super.dispose();
  }

  Future<void> _createClass() async {
    if (_formKey.currentState!.validate()) {
      if (_selectedFiliereId == null || _selectedNiveauId == null) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Veuillez sélectionner une filière et un niveau'), backgroundColor: AppColors.error),
        );
        return;
      }

      setState(() => _isLoading = true);

      try {
        await context.read<AppState>().createClasseScolaire(
          filiereId: _selectedFiliereId!,
          niveauId: _selectedNiveauId!,
          nom: _nomController.text.trim(),
          anneeScolaire: _anneeScolaireController.text.trim(),
        );

        if (mounted) {
          Navigator.pop(context);
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Classe créée avec succès'), backgroundColor: AppColors.success),
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
  }

  @override
  Widget build(BuildContext context) {
    final filieres = context.watch<AppState>().filieres;
    final niveaux = context.watch<AppState>().niveaux;
    
    // Filtrer les niveaux par filière sélectionnée
    final filteredNiveaux = _selectedFiliereId == null
        ? niveaux
        : niveaux.where((n) => n['filiere_id']?.toString() == _selectedFiliereId).toList();

    return Scaffold(
      backgroundColor: Colors.transparent,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        title: Text(
          'Créer une classe scolaire',
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
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Filière
              const SizedBox(height: 16),
              Text(
                'Filière',
                style: GoogleFonts.inter(fontSize: 14, fontWeight: FontWeight.w600, color: AppColors.text),
              ),
              const SizedBox(height: 8),
              Container(
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: AppColors.border, width: 0.5),
                ),
                child: DropdownButtonFormField<String>(
                  initialValue: _selectedFiliereId,
                  isExpanded: true,
                  decoration: InputDecoration(
                    labelText: 'Sélectionner une filière',
                    prefixIcon: const Icon(LucideIcons.folder, color: AppColors.primary, size: 20),
                    border: InputBorder.none,
                    contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
                    labelStyle: GoogleFonts.inter(fontSize: 13, color: AppColors.textSub),
                  ),
                  items: filieres.map((f) => DropdownMenuItem<String>(
                    value: f['id']?.toString(),
                    child: Text(
                      f['nom']?.toString() ?? '',
                      style: GoogleFonts.inter(fontSize: 14),
                      overflow: TextOverflow.ellipsis,
                      maxLines: 1,
                    ),
                  )).toList(),
                  onChanged: (v) {
                    setState(() {
                      _selectedFiliereId = v;
                      _selectedNiveauId = null; // Reset niveau quand filière change
                    });
                  },
                ),
              ),

              // Niveau
              const SizedBox(height: 24),
              Text(
                'Niveau',
                style: GoogleFonts.inter(fontSize: 14, fontWeight: FontWeight.w600, color: AppColors.text),
              ),
              const SizedBox(height: 8),
              Container(
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: AppColors.border, width: 0.5),
                ),
                child: DropdownButtonFormField<String>(
                  initialValue: _selectedNiveauId,
                  isExpanded: true,
                  decoration: InputDecoration(
                    labelText: 'Sélectionner un niveau',
                    prefixIcon: const Icon(LucideIcons.layers, color: AppColors.primary, size: 20),
                    border: InputBorder.none,
                    contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
                    labelStyle: GoogleFonts.inter(fontSize: 13, color: AppColors.textSub),
                  ),
                  items: filteredNiveaux.map((n) => DropdownMenuItem<String>(
                    value: n['id']?.toString(),
                    child: Text(
                      n['nom']?.toString() ?? '',
                      style: GoogleFonts.inter(fontSize: 14),
                      overflow: TextOverflow.ellipsis,
                      maxLines: 1,
                    ),
                  )).toList(),
                  onChanged: (v) {
                    setState(() => _selectedNiveauId = v);
                  },
                ),
              ),

              // Nom du groupe
              const SizedBox(height: 24),
              Text(
                'Nom de la classe',
                style: GoogleFonts.inter(fontSize: 14, fontWeight: FontWeight.w600, color: AppColors.text),
              ),
              const SizedBox(height: 8),
              Container(
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: AppColors.border, width: 0.5),
                ),
                child: TextFormField(
                  controller: _nomController,
                  decoration: InputDecoration(
                    labelText: 'Ex: Groupe A',
                    hintText: 'Nom de la classe',
                    prefixIcon: const Icon(LucideIcons.users, color: AppColors.primary, size: 20),
                    border: InputBorder.none,
                    contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
                    labelStyle: GoogleFonts.inter(fontSize: 13, color: AppColors.textSub),
                  ),
                  validator: (v) => v?.isEmpty ?? true ? 'Ce champ est requis' : null,
                ),
              ),

              // Année scolaire
              const SizedBox(height: 24),
              Text(
                'Année scolaire',
                style: GoogleFonts.inter(fontSize: 14, fontWeight: FontWeight.w600, color: AppColors.text),
              ),
              const SizedBox(height: 8),
              Container(
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: AppColors.border, width: 0.5),
                ),
                child: TextFormField(
                  controller: _anneeScolaireController,
                  decoration: InputDecoration(
                    labelText: 'Ex: 2025-2026',
                    hintText: 'Année scolaire',
                    prefixIcon: const Icon(LucideIcons.calendar, color: AppColors.primary, size: 20),
                    border: InputBorder.none,
                    contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
                    labelStyle: GoogleFonts.inter(fontSize: 13, color: AppColors.textSub),
                  ),
                  validator: (v) => v?.isEmpty ?? true ? 'Ce champ est requis' : null,
                ),
              ),

              // Bouton de création
              const SizedBox(height: 32),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: _isLoading ? null : _createClass,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.primary,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  ),
                  child: _isLoading
                      ? const SizedBox(
                          height: 20,
                          width: 20,
                          child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2),
                        )
                      : Text(
                          'Créer la classe',
                          style: GoogleFonts.inter(fontSize: 16, fontWeight: FontWeight.w600),
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
