import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:lucide_icons/lucide_icons.dart';
import 'package:provider/provider.dart';
import '../theme/app_theme.dart';
import '../services/app_state.dart';

class AdminAddStudentScreen extends StatefulWidget {
  final String classeId;
  final String classeNom;
  
  const AdminAddStudentScreen({
    super.key,
    required this.classeId,
    required this.classeNom,
  });

  @override
  State<AdminAddStudentScreen> createState() => _AdminAddStudentScreenState();
}

class _AdminAddStudentScreenState extends State<AdminAddStudentScreen> {
  final _formKey = GlobalKey<FormState>();
  final _codeMassarController = TextEditingController();
  final _prenomController = TextEditingController();
  final _nomController = TextEditingController();
  final _dateNaissanceController = TextEditingController();
  final _cinController = TextEditingController();
  final _emailController = TextEditingController();
  final _telephoneController = TextEditingController();
  
  bool _isLoading = false;

  @override
  void dispose() {
    _codeMassarController.dispose();
    _prenomController.dispose();
    _nomController.dispose();
    _dateNaissanceController.dispose();
    _cinController.dispose();
    _emailController.dispose();
    _telephoneController.dispose();
    super.dispose();
  }

  Future<void> _addStudent() async {
    if (_formKey.currentState!.validate()) {
      setState(() => _isLoading = true);

      try {
        await context.read<AppState>().createEtudiantAndAddToClasse(
          classeId: widget.classeId,
          codeMassar: _codeMassarController.text.trim(),
          prenom: _prenomController.text.trim(),
          nom: _nomController.text.trim(),
          dateNaissance: _dateNaissanceController.text.trim(),
          cin: _cinController.text.trim(),
          email: _emailController.text.trim(),
          telephone: _telephoneController.text.trim(),
        );

        if (mounted) {
          Navigator.pop(context);
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Étudiant ajouté avec succès'), backgroundColor: AppColors.success),
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

  Future<void> _selectDate() async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: DateTime(2005),
      firstDate: DateTime(1990),
      lastDate: DateTime.now(),
    );
    if (picked != null && mounted) {
      _dateNaissanceController.text = picked.toIso8601String().split('T')[0];
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        title: Text(
          'Ajouter un étudiant',
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
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: AppColors.border, width: 0.5),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      widget.classeNom,
                      style: GoogleFonts.inter(
                        fontSize: 16,
                        fontWeight: FontWeight.w700,
                        color: AppColors.text,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      'Classe scolaire',
                      style: GoogleFonts.inter(
                        fontSize: 12,
                        color: AppColors.textSub,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 24),

              // Code Massar
              Text(
                'Code Massar *',
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
                  controller: _codeMassarController,
                  decoration: InputDecoration(
                    hintText: 'Code Massar',
                    prefixIcon: const Icon(LucideIcons.key, color: AppColors.primary, size: 20),
                    border: InputBorder.none,
                    contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
                  ),
                  validator: (v) => v?.isEmpty ?? true ? 'Ce champ est requis' : null,
                ),
              ),

              const SizedBox(height: 16),

              // Prénom
              Text(
                'Prénom *',
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
                  controller: _prenomController,
                  decoration: InputDecoration(
                    hintText: 'Prénom',
                    prefixIcon: const Icon(LucideIcons.user, color: AppColors.primary, size: 20),
                    border: InputBorder.none,
                    contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
                  ),
                  validator: (v) => v?.isEmpty ?? true ? 'Ce champ est requis' : null,
                ),
              ),

              const SizedBox(height: 16),

              // Nom
              Text(
                'Nom *',
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
                    hintText: 'Nom',
                    prefixIcon: const Icon(LucideIcons.user, color: AppColors.primary, size: 20),
                    border: InputBorder.none,
                    contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
                  ),
                  validator: (v) => v?.isEmpty ?? true ? 'Ce champ est requis' : null,
                ),
              ),

              const SizedBox(height: 16),

              // Date de naissance
              Text(
                'Date de naissance',
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
                  controller: _dateNaissanceController,
                  readOnly: true,
                  onTap: _selectDate,
                  decoration: InputDecoration(
                    hintText: 'Date de naissance',
                    prefixIcon: const Icon(LucideIcons.calendar, color: AppColors.primary, size: 20),
                    border: InputBorder.none,
                    contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
                    suffixIcon: const Icon(LucideIcons.chevronDown, color: AppColors.textSub, size: 20),
                  ),
                ),
              ),

              const SizedBox(height: 16),

              // CIN
              Text(
                'CIN',
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
                  controller: _cinController,
                  decoration: InputDecoration(
                    hintText: 'CIN (optionnel)',
                    prefixIcon: const Icon(LucideIcons.creditCard, color: AppColors.primary, size: 20),
                    border: InputBorder.none,
                    contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
                  ),
                ),
              ),

              const SizedBox(height: 16),

              // Email
              Text(
                'Email',
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
                  controller: _emailController,
                  keyboardType: TextInputType.emailAddress,
                  decoration: InputDecoration(
                    hintText: 'Email (optionnel)',
                    prefixIcon: const Icon(LucideIcons.mail, color: AppColors.primary, size: 20),
                    border: InputBorder.none,
                    contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
                  ),
                ),
              ),

              const SizedBox(height: 16),

              // Téléphone
              Text(
                'Téléphone',
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
                  controller: _telephoneController,
                  keyboardType: TextInputType.phone,
                  decoration: InputDecoration(
                    hintText: 'Téléphone',
                    prefixIcon: const Icon(LucideIcons.phone, color: AppColors.primary, size: 20),
                    border: InputBorder.none,
                    contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
                  ),
                ),
              ),

              const SizedBox(height: 32),

              // Bouton d'ajout
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: _isLoading ? null : _addStudent,
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
                          'Ajouter l\'étudiant',
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
