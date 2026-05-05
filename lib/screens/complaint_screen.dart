import 'package:flutter/material.dart';
import 'package:lucide_icons/lucide_icons.dart';
import 'package:google_fonts/google_fonts.dart';
import '../theme/app_theme.dart';
import '../widgets/common_widgets.dart';

class ComplaintScreen extends StatefulWidget {
  const ComplaintScreen({super.key});

  @override
  State<ComplaintScreen> createState() => _ComplaintScreenState();
}

class _ComplaintScreenState extends State<ComplaintScreen> {
  final _formKey = GlobalKey<FormState>();
  final _subjectController = TextEditingController();
  final _descriptionController = TextEditingController();
  final _emailController = TextEditingController();
  
  String _selectedCategory = 'technical';
  int _priorityLevel = 2; // 1: Low, 2: Medium, 3: High
  bool _isLoading = false;
  List<String> _attachments = [];

  @override
  void dispose() {
    _subjectController.dispose();
    _descriptionController.dispose();
    _emailController.dispose();
    super.dispose();
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
          'Déposer une réclamation',
          style: GoogleFonts.inter(
            fontSize: 18,
            fontWeight: FontWeight.w700,
            color: AppColors.text,
          ),
        ),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // ── Header Info ───────────────────────────────────────
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: AppColors.info.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: AppColors.info.withOpacity(0.3)),
                ),
                child: Row(
                  children: [
                    Icon(
                      LucideIcons.info,
                      color: AppColors.info,
                      size: 24,
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Text(
                        'Votre réclamation sera traitée par notre équipe d\'administration dans les plus brefs délais.',
                        style: GoogleFonts.inter(
                          fontSize: 12,
                          color: AppColors.info,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 24),

              // ── Category Selection ───────────────────────────────
              _SectionHeader(title: 'Catégorie de la réclamation'),
              const SizedBox(height: 12),
              
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: AppColors.border, width: 0.5),
                ),
                child: Column(
                  children: [
                    DropdownButtonFormField<String>(
                      value: _selectedCategory,
                      decoration: InputDecoration(
                        labelText: 'Sélectionnez une catégorie',
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(8),
                          borderSide: BorderSide(color: AppColors.border),
                        ),
                        focusedBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(8),
                          borderSide: BorderSide(color: AppColors.primary),
                        ),
                        contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                      ),
                      items: const [
                        DropdownMenuItem(value: 'technical', child: Text('Problème technique')),
                        DropdownMenuItem(value: 'content', child: Text('Contenu inapproprié')),
                        DropdownMenuItem(value: 'account', child: Text('Problème de compte')),
                        DropdownMenuItem(value: 'billing', child: Text('Facturation/Paiement')),
                        DropdownMenuItem(value: 'other', child: Text('Autre')),
                      ],
                      onChanged: (value) {
                        setState(() {
                          _selectedCategory = value!;
                        });
                      },
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 24),

              // ── Priority Level ───────────────────────────────────
              _SectionHeader(title: 'Niveau de priorité'),
              const SizedBox(height: 12),
              
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
                      'Quel est le niveau d\'urgence ?',
                      style: GoogleFonts.inter(
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                        color: AppColors.text,
                      ),
                    ),
                    const SizedBox(height: 12),
                    Row(
                      children: [
                        Expanded(
                          child: _PriorityOption(
                            title: 'Faible',
                            level: 1,
                            color: AppColors.success,
                            isSelected: _priorityLevel == 1,
                            onTap: () => setState(() => _priorityLevel = 1),
                          ),
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: _PriorityOption(
                            title: 'Moyen',
                            level: 2,
                            color: AppColors.warning,
                            isSelected: _priorityLevel == 2,
                            onTap: () => setState(() => _priorityLevel = 2),
                          ),
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: _PriorityOption(
                            title: 'Élevé',
                            level: 3,
                            color: AppColors.error,
                            isSelected: _priorityLevel == 3,
                            onTap: () => setState(() => _priorityLevel = 3),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 24),

              // ── Subject ─────────────────────────────────────────────
              _SectionHeader(title: 'Sujet de la réclamation'),
              const SizedBox(height: 12),
              
              _buildTextField(
                controller: _subjectController,
                label: 'Sujet',
                icon: LucideIcons.fileText,
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Veuillez entrer un sujet';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 24),

              // ── Description ───────────────────────────────────────
              _SectionHeader(title: 'Description détaillée'),
              const SizedBox(height: 12),
              
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: AppColors.border, width: 0.5),
                ),
                child: TextFormField(
                  controller: _descriptionController,
                  maxLines: 6,
                  validator: (value) {
                    if (value == null || value.isEmpty) {
                      return 'Veuillez décrire votre réclamation';
                    }
                    if (value.length < 20) {
                      return 'La description doit contenir au moins 20 caractères';
                    }
                    return null;
                  },
                  decoration: InputDecoration(
                    hintText: 'Décrivez en détail votre réclamation...',
                    border: InputBorder.none,
                    hintStyle: GoogleFonts.inter(
                      fontSize: 14,
                      color: AppColors.textSub,
                    ),
                  ),
                  style: GoogleFonts.inter(
                    fontSize: 14,
                    color: AppColors.text,
                  ),
                ),
              ),
              const SizedBox(height: 24),

              // ── Email ───────────────────────────────────────────────
              _SectionHeader(title: 'Email de contact'),
              const SizedBox(height: 12),
              
              _buildTextField(
                controller: _emailController,
                label: 'Votre email',
                icon: LucideIcons.mail,
                keyboardType: TextInputType.emailAddress,
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Veuillez entrer votre email';
                  }
                  if (!value.contains('@')) {
                    return 'Veuillez entrer un email valide';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 24),

              // ── Attachments ───────────────────────────────────────
              _SectionHeader(title: 'Pièces jointes'),
              const SizedBox(height: 12),
              
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: AppColors.border, width: 0.5),
                ),
                child: Column(
                  children: [
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Icon(
                              LucideIcons.paperclip,
                              color: AppColors.textSub,
                              size: 20,
                            ),
                            const SizedBox(width: 8),
                            Expanded(
                              child: Text(
                                'Pièces jointes (captures d\'écran, etc.)',
                                style: GoogleFonts.inter(
                                  fontSize: 12,
                                  color: AppColors.textSub,
                                ),
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 12),
                        SizedBox(
                          width: double.infinity,
                          child: ElevatedButton.icon(
                            onPressed: _addAttachment,
                            icon: const Icon(LucideIcons.plus, size: 16),
                            label: const Text('Ajouter une pièce jointe'),
                            style: ElevatedButton.styleFrom(
                              backgroundColor: AppColors.primary,
                              foregroundColor: Colors.white,
                              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                            ),
                          ),
                        ),
                      ],
                    ),
                    if (_attachments.isNotEmpty) ...[
                      const SizedBox(height: 12),
                      ..._attachments.map((attachment) => _AttachmentTile(
                        fileName: attachment,
                        onRemove: () => _removeAttachment(attachment),
                      )),
                    ],
                  ],
                ),
              ),
              const SizedBox(height: 32),

              // ── Submit Button ───────────────────────────────────
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: _isLoading ? null : _submitComplaint,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.primary,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  child: _isLoading
                      ? const SizedBox(
                          height: 20,
                          width: 20,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                          ),
                        )
                      : Text(
                          'Envoyer la réclamation',
                          style: GoogleFonts.inter(
                            fontSize: 16,
                            fontWeight: FontWeight.w600,
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

  Widget _buildTextField({
    required TextEditingController controller,
    required String label,
    required IconData icon,
    TextInputType? keyboardType,
    String? Function(String?)? validator,
  }) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.border, width: 0.5),
      ),
      child: TextFormField(
        controller: controller,
        keyboardType: keyboardType,
        validator: validator,
        decoration: InputDecoration(
          labelText: label,
          prefixIcon: Icon(icon, color: AppColors.primary),
          border: InputBorder.none,
          labelStyle: GoogleFonts.inter(
            fontSize: 14,
            color: AppColors.textSub,
          ),
        ),
        style: GoogleFonts.inter(
          fontSize: 14,
          color: AppColors.text,
        ),
      ),
    );
  }

  Widget _PriorityOption({
    required String title,
    required int level,
    required Color color,
    required bool isSelected,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 12),
        decoration: BoxDecoration(
          color: isSelected ? color : Colors.white,
          borderRadius: BorderRadius.circular(8),
          border: Border.all(
            color: isSelected ? color : AppColors.border,
            width: isSelected ? 2 : 1,
          ),
        ),
        child: Center(
          child: Text(
            title,
            style: GoogleFonts.inter(
              fontSize: 12,
              fontWeight: FontWeight.w600,
              color: isSelected ? Colors.white : AppColors.text,
            ),
          ),
        ),
      ),
    );
  }

  Widget _AttachmentTile({
    required String fileName,
    required VoidCallback onRemove,
  }) {
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: AppColors.background,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: AppColors.border, width: 0.5),
      ),
      child: Row(
        children: [
          Icon(
            LucideIcons.file,
            size: 16,
            color: AppColors.textSub,
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              fileName,
              style: GoogleFonts.inter(
                fontSize: 12,
                color: AppColors.text,
              ),
              overflow: TextOverflow.ellipsis,
            ),
          ),
          IconButton(
            onPressed: onRemove,
            icon: const Icon(
              LucideIcons.x,
              size: 16,
              color: AppColors.error,
            ),
          ),
        ],
      ),
    );
  }

  void _addAttachment() {
    // Simuler l'ajout d'une pièce jointe
    setState(() {
      _attachments.add('capture_${DateTime.now().millisecondsSinceEpoch}.png');
    });
  }

  void _removeAttachment(String fileName) {
    setState(() {
      _attachments.remove(fileName);
    });
  }

  void _submitComplaint() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() {
      _isLoading = true;
    });

    try {
      // Simuler l'envoi de la réclamation
      await Future.delayed(const Duration(seconds: 2));
      
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Réclamation envoyée avec succès! Nous vous répondrons dans les 24h.'),
            backgroundColor: AppColors.success,
            duration: const Duration(seconds: 4),
          ),
        );
        Navigator.pop(context);
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Erreur lors de l\'envoi de la réclamation'),
            backgroundColor: AppColors.error,
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }
}

class _SectionHeader extends StatelessWidget {
  final String title;
  
  const _SectionHeader({required this.title});

  @override
  Widget build(BuildContext context) {
    return Text(
      title,
      style: GoogleFonts.inter(
        fontSize: 16,
        fontWeight: FontWeight.w700,
        color: AppColors.text,
      ),
    );
  }
}
