import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:lucide_icons/lucide_icons.dart';
import 'package:provider/provider.dart';
import '../theme/app_theme.dart';
import '../services/app_state.dart';
import '../widgets/empty_state.dart';
import '../widgets/astronaut_illustration.dart';

class AdminStructureManagementScreen extends StatefulWidget {
  const AdminStructureManagementScreen({super.key});

  @override
  State<AdminStructureManagementScreen> createState() => _AdminStructureManagementScreenState();
}

class _AdminStructureManagementScreenState extends State<AdminStructureManagementScreen> with SingleTickerProviderStateMixin {
  late TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<AppState>().loadFilieres();
      context.read<AppState>().loadNiveaux();
      context.read<AppState>().loadMatieres();
    });
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.transparent,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        title: Text(
          'Gestion Structure',
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
        bottom: TabBar(
          controller: _tabController,
          labelColor: AppColors.primary,
          unselectedLabelColor: AppColors.textSub,
          indicatorColor: AppColors.primary,
          labelStyle: GoogleFonts.inter(fontWeight: FontWeight.w700, fontSize: 14),
          tabs: const [
            Tab(text: 'Filières'),
            Tab(text: 'Niveaux'),
            Tab(text: 'Matières'),
          ],
        ),
      ),
      body: TabBarView(
        controller: _tabController,
        children: const [
          _FilieresTab(),
          _NiveauxTab(),
          _MatieresTab(),
        ],
      ),
    );
  }
}

Widget _buildStyledTextField({
    required TextEditingController controller,
    required String label,
    required String hint,
    required IconData icon,
    TextInputType? keyboardType,
  }) {
  return Container(
    decoration: BoxDecoration(
      color: Colors.white,
      borderRadius: BorderRadius.circular(12),
      border: Border.all(color: AppColors.border, width: 0.5),
    ),
    child: TextField(
      controller: controller,
      keyboardType: keyboardType,
      decoration: InputDecoration(
        labelText: label,
        hintText: hint,
        prefixIcon: Icon(icon, color: AppColors.primary, size: 20),
        border: InputBorder.none,
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
        labelStyle: GoogleFonts.inter(fontSize: 13, color: AppColors.textSub),
        hintStyle: GoogleFonts.inter(fontSize: 13, color: AppColors.textSub.withOpacity(0.6)),
      ),
      style: GoogleFonts.inter(fontSize: 14, color: AppColors.text),
    ),
  );
}

class _FilieresTab extends StatelessWidget {
  const _FilieresTab();

  @override
  Widget build(BuildContext context) {
    final filieres = context.watch<AppState>().filieres;
    final loaded = context.watch<AppState>().filieresLoaded;

    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.all(16),
          child: Row(
            children: [
              Expanded(
                child: Text(
                  '${filieres.length} filière(s)',
                  style: GoogleFonts.inter(
                    fontSize: 14,
                    color: AppColors.textSub,
                  ),
                ),
              ),
              ElevatedButton.icon(
                onPressed: () => _showAddFiliereDialog(context),
                icon: const Icon(LucideIcons.plus, size: 16),
                label: Text('Ajouter', style: GoogleFonts.inter(fontWeight: FontWeight.w600)),
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.primary,
                  foregroundColor: Colors.white,
                ),
              ),
            ],
          ),
        ),
        Expanded(
          child: !loaded
              ? const Center(child: CircularProgressIndicator())
              : filieres.isEmpty
                  ? EmptyStatePage(
                      emptyState: EmptyState(
                        title: 'Aucune filière',
                        subtitle: 'Ajoutez votre première filière pour structurer les cours.',
                        astronautType: AstronautType.learning,
                      ),
                    )
                  : ListView.separated(
                      padding: const EdgeInsets.symmetric(horizontal: 16),
                      itemCount: filieres.length,
                      separatorBuilder: (_, __) => const SizedBox(height: 12),
                      itemBuilder: (context, i) {
                        final filiere = filieres[i];
                        return _FiliereCard(
                          filiere: filiere,
                          onEdit: () => _showEditFiliereDialog(context, filiere),
                          onDelete: () => _confirmDeleteFiliere(context, filiere['id']),
                        );
                      },
                    ),
        ),
      ],
    );
  }

  void _showAddFiliereDialog(BuildContext context) {
    final nomController = TextEditingController();
    final codeController = TextEditingController();
    final ordreController = TextEditingController(text: '0');

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: AppColors.primary.withOpacity(0.1),
                borderRadius: BorderRadius.circular(12),
              ),
              child: const Icon(LucideIcons.folderPlus, color: AppColors.primary, size: 24),
            ),
            const SizedBox(width: 12),
            Text('Ajouter une filière', style: GoogleFonts.inter(fontWeight: FontWeight.w700, fontSize: 18)),
          ],
        ),
        content: SizedBox(
          width: 400,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              _buildStyledTextField(
                controller: nomController,
                label: 'Nom',
                hint: 'ex: Tronc Commun',
                icon: LucideIcons.type,
              ),
              const SizedBox(height: 16),
              _buildStyledTextField(
                controller: codeController,
                label: 'Code',
                hint: 'ex: TC',
                icon: LucideIcons.hash,
              ),
              const SizedBox(height: 16),
              _buildStyledTextField(
                controller: ordreController,
                label: 'Ordre',
                hint: '0',
                icon: LucideIcons.arrowUpDown,
                keyboardType: TextInputType.number,
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
            onPressed: () async {
              if (nomController.text.isEmpty || codeController.text.isEmpty) {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Veuillez remplir tous les champs'), backgroundColor: AppColors.error),
                );
                return;
              }
              try {
                await context.read<AppState>().createFiliere({
                  'nom': nomController.text,
                  'code': codeController.text,
                  'ordre': int.tryParse(ordreController.text) ?? 0,
                  'is_active': true,
                });
                if (context.mounted) {
                  Navigator.pop(context);
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('Filière ajoutée avec succès'), backgroundColor: AppColors.success),
                  );
                }
              } catch (e) {
                if (context.mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text('Erreur: $e'), backgroundColor: AppColors.error),
                  );
                }
              }
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.primary,
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            ),
            child: Text('Ajouter', style: GoogleFonts.inter(fontWeight: FontWeight.w600)),
          ),
        ],
      ),
    );
  }

  void _showEditFiliereDialog(BuildContext context, Map<String, dynamic> filiere) {
    final nomController = TextEditingController(text: filiere['nom']);
    final codeController = TextEditingController(text: filiere['code']);
    final ordreController = TextEditingController(text: filiere['ordre']?.toString() ?? '0');

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: AppColors.info.withOpacity(0.1),
                borderRadius: BorderRadius.circular(12),
              ),
              child: const Icon(LucideIcons.pencil, color: AppColors.info, size: 24),
            ),
            const SizedBox(width: 12),
            Text('Modifier la filière', style: GoogleFonts.inter(fontWeight: FontWeight.w700, fontSize: 18)),
          ],
        ),
        content: SizedBox(
          width: 400,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              _buildStyledTextField(
                controller: nomController,
                label: 'Nom',
                hint: 'ex: Tronc Commun',
                icon: LucideIcons.type,
              ),
              const SizedBox(height: 16),
              _buildStyledTextField(
                controller: codeController,
                label: 'Code',
                hint: 'ex: TC',
                icon: LucideIcons.hash,
              ),
              const SizedBox(height: 16),
              _buildStyledTextField(
                controller: ordreController,
                label: 'Ordre',
                hint: '0',
                icon: LucideIcons.arrowUpDown,
                keyboardType: TextInputType.number,
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
            onPressed: () async {
              if (nomController.text.isEmpty || codeController.text.isEmpty) {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Veuillez remplir tous les champs'), backgroundColor: AppColors.error),
                );
                return;
              }
              try {
                await context.read<AppState>().updateFiliere(filiere['id'], {
                  'nom': nomController.text,
                  'code': codeController.text,
                  'ordre': int.tryParse(ordreController.text) ?? 0,
                });
                if (context.mounted) {
                  Navigator.pop(context);
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('Filière modifiée avec succès'), backgroundColor: AppColors.success),
                  );
                }
              } catch (e) {
                if (context.mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text('Erreur: $e'), backgroundColor: AppColors.error),
                  );
                }
              }
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.info,
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            ),
            child: Text('Modifier', style: GoogleFonts.inter(fontWeight: FontWeight.w600)),
          ),
        ],
      ),
    );
  }

  void _confirmDeleteFiliere(BuildContext context, String id) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Supprimer la filière', style: GoogleFonts.inter(fontWeight: FontWeight.w700)),
        content: const Text('Cette action supprimera aussi tous les niveaux et matières associés. Continuer ?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Annuler'),
          ),
          ElevatedButton(
            onPressed: () async {
              try {
                await context.read<AppState>().deleteFiliere(id);
                if (context.mounted) Navigator.pop(context);
              } catch (e) {
                if (context.mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text('Erreur: $e'), backgroundColor: AppColors.error),
                  );
                }
              }
            },
            style: ElevatedButton.styleFrom(backgroundColor: AppColors.error),
            child: const Text('Supprimer'),
          ),
        ],
      ),
    );
  }
}

class _FiliereCard extends StatelessWidget {
  final Map<String, dynamic> filiere;
  final VoidCallback onEdit;
  final VoidCallback onDelete;

  const _FiliereCard({
    required this.filiere,
    required this.onEdit,
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
      child: Row(
        children: [
          Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              color: AppColors.primary.withOpacity(0.1),
              borderRadius: BorderRadius.circular(8),
            ),
            child: const Icon(LucideIcons.folder, color: AppColors.primary),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  filiere['nom'] ?? 'Sans nom',
                  style: GoogleFonts.inter(fontSize: 16, fontWeight: FontWeight.w700, color: AppColors.text),
                ),
                Text(
                  '${filiere['code'] ?? ''} • Ordre: ${filiere['ordre'] ?? 0}',
                  style: GoogleFonts.inter(fontSize: 12, color: AppColors.textSub),
                ),
              ],
            ),
          ),
          IconButton(
            onPressed: onEdit,
            icon: const Icon(LucideIcons.pencil, size: 18, color: AppColors.primary),
          ),
          IconButton(
            onPressed: onDelete,
            icon: const Icon(LucideIcons.trash2, size: 18, color: AppColors.error),
          ),
        ],
      ),
    );
  }
}

class _NiveauxTab extends StatelessWidget {
  const _NiveauxTab();

  @override
  Widget build(BuildContext context) {
    final niveaux = context.watch<AppState>().niveaux;
    final filieres = context.watch<AppState>().filieres;
    final loaded = context.watch<AppState>().niveauxLoaded;

    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.all(16),
          child: Row(
            children: [
              Expanded(
                child: Text(
                  '${niveaux.length} niveau(x)',
                  style: GoogleFonts.inter(
                    fontSize: 14,
                    color: AppColors.textSub,
                  ),
                ),
              ),
              ElevatedButton.icon(
                onPressed: () => _showAddNiveauDialog(context, filieres),
                icon: const Icon(LucideIcons.plus, size: 16),
                label: Text('Ajouter', style: GoogleFonts.inter(fontWeight: FontWeight.w600)),
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.primary,
                  foregroundColor: Colors.white,
                ),
              ),
            ],
          ),
        ),
        Expanded(
          child: !loaded
              ? const Center(child: CircularProgressIndicator())
              : niveaux.isEmpty
                  ? Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          const Icon(LucideIcons.layers, size: 48, color: AppColors.textSub),
                          const SizedBox(height: 16),
                          Text(
                            'Aucun niveau',
                            style: GoogleFonts.inter(fontSize: 16, fontWeight: FontWeight.w700, color: AppColors.text),
                          ),
                        ],
                      ),
                    )
                  : ListView.separated(
                      padding: const EdgeInsets.symmetric(horizontal: 16),
                      itemCount: niveaux.length,
                      separatorBuilder: (_, __) => const SizedBox(height: 12),
                      itemBuilder: (context, i) {
                        final niveau = niveaux[i];
                        final filiere = filieres.firstWhere((f) => f['id'] == niveau['filiere_id'], orElse: () => {});
                        return _NiveauCard(
                          niveau: niveau,
                          filiereNom: filiere['nom'] ?? 'Inconnu',
                          onEdit: () => _showEditNiveauDialog(context, niveau, filieres),
                          onDelete: () => _confirmDeleteNiveau(context, niveau['id']),
                        );
                      },
                    ),
        ),
      ],
    );
  }

  void _showAddNiveauDialog(BuildContext context, List<Map<String, dynamic>> filieres) {
    if (filieres.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Créez d\'abord une filière'), backgroundColor: AppColors.error),
      );
      return;
    }

    final nomController = TextEditingController();
    final codeController = TextEditingController();
    final ordreController = TextEditingController(text: '0');
    String? selectedFiliereId = filieres.first['id']?.toString();

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: AppColors.info.withOpacity(0.1),
                borderRadius: BorderRadius.circular(12),
              ),
              child: const Icon(LucideIcons.layers, color: AppColors.info, size: 24),
            ),
            const SizedBox(width: 12),
            Text('Ajouter un niveau', style: GoogleFonts.inter(fontWeight: FontWeight.w700, fontSize: 18)),
          ],
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
                  initialValue: selectedFiliereId,
                  decoration: InputDecoration(
                    labelText: 'Filière',
                    prefixIcon: const Icon(LucideIcons.folder, color: AppColors.primary, size: 20),
                    border: InputBorder.none,
                    contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
                    labelStyle: GoogleFonts.inter(fontSize: 13, color: AppColors.textSub),
                  ),
                  items: filieres.map((f) => DropdownMenuItem<String>(
                    value: f['id']?.toString(),
                    child: Text(f['nom']?.toString() ?? '', style: GoogleFonts.inter(fontSize: 14)),
                  )).toList(),
                  onChanged: (v) => selectedFiliereId = v,
                ),
              ),
              const SizedBox(height: 16),
              _buildStyledTextField(
                controller: nomController,
                label: 'Nom',
                hint: 'ex: 1ère Bac Sciences Maths',
                icon: LucideIcons.type,
              ),
              const SizedBox(height: 16),
              _buildStyledTextField(
                controller: codeController,
                label: 'Code',
                hint: 'ex: 1BAC_SM',
                icon: LucideIcons.hash,
              ),
              const SizedBox(height: 16),
              _buildStyledTextField(
                controller: ordreController,
                label: 'Ordre',
                hint: '0',
                icon: LucideIcons.arrowUpDown,
                keyboardType: TextInputType.number,
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
            onPressed: () async {
              if (nomController.text.isEmpty || codeController.text.isEmpty || selectedFiliereId == null) {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Veuillez remplir tous les champs'), backgroundColor: AppColors.error),
                );
                return;
              }
              try {
                await context.read<AppState>().createNiveau({
                  'filiere_id': selectedFiliereId,
                  'nom': nomController.text,
                  'code': codeController.text,
                  'ordre': int.tryParse(ordreController.text) ?? 0,
                  'is_active': true,
                });
                if (context.mounted) {
                  Navigator.pop(context);
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('Niveau ajouté avec succès'), backgroundColor: AppColors.success),
                  );
                }
              } catch (e) {
                if (context.mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text('Erreur: $e'), backgroundColor: AppColors.error),
                  );
                }
              }
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.info,
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            ),
            child: Text('Ajouter', style: GoogleFonts.inter(fontWeight: FontWeight.w600)),
          ),
        ],
      ),
    );
  }

  void _showEditNiveauDialog(BuildContext context, Map<String, dynamic> niveau, List<Map<String, dynamic>> filieres) {
    final nomController = TextEditingController(text: niveau['nom']);
    final codeController = TextEditingController(text: niveau['code']);
    final ordreController = TextEditingController(text: niveau['ordre']?.toString() ?? '0');
    String? selectedFiliereId = niveau['filiere_id']?.toString();

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: AppColors.warning.withOpacity(0.1),
                borderRadius: BorderRadius.circular(12),
              ),
              child: const Icon(LucideIcons.pencil, color: AppColors.warning, size: 24),
            ),
            const SizedBox(width: 12),
            Text('Modifier le niveau', style: GoogleFonts.inter(fontWeight: FontWeight.w700, fontSize: 18)),
          ],
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
                  initialValue: selectedFiliereId,
                  decoration: InputDecoration(
                    labelText: 'Filière',
                    prefixIcon: const Icon(LucideIcons.folder, color: AppColors.primary, size: 20),
                    border: InputBorder.none,
                    contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
                    labelStyle: GoogleFonts.inter(fontSize: 13, color: AppColors.textSub),
                  ),
                  items: filieres.map((f) => DropdownMenuItem<String>(
                    value: f['id']?.toString(),
                    child: Text(f['nom']?.toString() ?? '', style: GoogleFonts.inter(fontSize: 14)),
                  )).toList(),
                  onChanged: (v) => selectedFiliereId = v,
                ),
              ),
              const SizedBox(height: 16),
              _buildStyledTextField(
                controller: nomController,
                label: 'Nom',
                hint: 'ex: 1ère Bac Sciences Maths',
                icon: LucideIcons.type,
              ),
              const SizedBox(height: 16),
              _buildStyledTextField(
                controller: codeController,
                label: 'Code',
                hint: 'ex: 1BAC_SM',
                icon: LucideIcons.hash,
              ),
              const SizedBox(height: 16),
              _buildStyledTextField(
                controller: ordreController,
                label: 'Ordre',
                hint: '0',
                icon: LucideIcons.arrowUpDown,
                keyboardType: TextInputType.number,
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
            onPressed: () async {
              if (nomController.text.isEmpty || codeController.text.isEmpty || selectedFiliereId == null) {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Veuillez remplir tous les champs'), backgroundColor: AppColors.error),
                );
                return;
              }
              try {
                await context.read<AppState>().updateNiveau(niveau['id'], {
                  'filiere_id': selectedFiliereId,
                  'nom': nomController.text,
                  'code': codeController.text,
                  'ordre': int.tryParse(ordreController.text) ?? 0,
                });
                if (context.mounted) {
                  Navigator.pop(context);
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('Niveau modifié avec succès'), backgroundColor: AppColors.success),
                  );
                }
              } catch (e) {
                if (context.mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text('Erreur: $e'), backgroundColor: AppColors.error),
                  );
                }
              }
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.warning,
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            ),
            child: Text('Modifier', style: GoogleFonts.inter(fontWeight: FontWeight.w600)),
          ),
        ],
      ),
    );
  }

  void _confirmDeleteNiveau(BuildContext context, String id) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Supprimer le niveau', style: GoogleFonts.inter(fontWeight: FontWeight.w700)),
        content: const Text('Cette action supprimera aussi toutes les matières associées. Continuer ?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Annuler'),
          ),
          ElevatedButton(
            onPressed: () async {
              try {
                await context.read<AppState>().deleteNiveau(id);
                if (context.mounted) Navigator.pop(context);
              } catch (e) {
                if (context.mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text('Erreur: $e'), backgroundColor: AppColors.error),
                  );
                }
              }
            },
            style: ElevatedButton.styleFrom(backgroundColor: AppColors.error),
            child: const Text('Supprimer'),
          ),
        ],
      ),
    );
  }
}

class _NiveauCard extends StatelessWidget {
  final Map<String, dynamic> niveau;
  final String filiereNom;
  final VoidCallback onEdit;
  final VoidCallback onDelete;

  const _NiveauCard({
    required this.niveau,
    required this.filiereNom,
    required this.onEdit,
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
      child: Row(
        children: [
          Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              color: AppColors.info.withOpacity(0.1),
              borderRadius: BorderRadius.circular(8),
            ),
            child: const Icon(LucideIcons.layers, color: AppColors.info),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  niveau['nom'] ?? 'Sans nom',
                  style: GoogleFonts.inter(fontSize: 16, fontWeight: FontWeight.w700, color: AppColors.text),
                ),
                Text(
                  '$filiereNom • ${niveau['code'] ?? ''} • Ordre: ${niveau['ordre'] ?? 0}',
                  style: GoogleFonts.inter(fontSize: 12, color: AppColors.textSub),
                ),
              ],
            ),
          ),
          IconButton(
            onPressed: onEdit,
            icon: const Icon(LucideIcons.pencil, size: 18, color: AppColors.primary),
          ),
          IconButton(
            onPressed: onDelete,
            icon: const Icon(LucideIcons.trash2, size: 18, color: AppColors.error),
          ),
        ],
      ),
    );
  }
}

class _MatieresTab extends StatelessWidget {
  const _MatieresTab();

  @override
  Widget build(BuildContext context) {
    final matieres = context.watch<AppState>().matieres;
    final niveaux = context.watch<AppState>().niveaux;
    final loaded = context.watch<AppState>().matieresLoaded;

    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.all(16),
          child: Row(
            children: [
              Expanded(
                child: Text(
                  '${matieres.length} matière(s)',
                  style: GoogleFonts.inter(
                    fontSize: 14,
                    color: AppColors.textSub,
                  ),
                ),
              ),
              ElevatedButton.icon(
                onPressed: () => _showAddMatiereDialog(context, niveaux),
                icon: const Icon(LucideIcons.plus, size: 16),
                label: Text('Ajouter', style: GoogleFonts.inter(fontWeight: FontWeight.w600)),
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.primary,
                  foregroundColor: Colors.white,
                ),
              ),
            ],
          ),
        ),
        Expanded(
          child: !loaded
              ? const Center(child: CircularProgressIndicator())
              : matieres.isEmpty
                  ? Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          const Icon(LucideIcons.bookOpen, size: 48, color: AppColors.textSub),
                          const SizedBox(height: 16),
                          Text(
                            'Aucune matière',
                            style: GoogleFonts.inter(fontSize: 16, fontWeight: FontWeight.w700, color: AppColors.text),
                          ),
                        ],
                      ),
                    )
                  : ListView.separated(
                      padding: const EdgeInsets.symmetric(horizontal: 16),
                      itemCount: matieres.length,
                      separatorBuilder: (_, __) => const SizedBox(height: 12),
                      itemBuilder: (context, i) {
                        final matiere = matieres[i];
                        final niveauData = matiere['niveaux'] as Map<String, dynamic>?;
                        final filiereData = niveauData?['filieres'] as Map<String, dynamic>?;
                        return _MatiereCard(
                          matiere: matiere,
                          niveauNom: niveauData?['nom'] ?? 'Inconnu',
                          filiereNom: filiereData?['nom'] ?? 'Inconnu',
                          onEdit: () => _showEditMatiereDialog(context, matiere, niveaux),
                          onDelete: () => _confirmDeleteMatiere(context, matiere['id']),
                        );
                      },
                    ),
        ),
      ],
    );
  }

  void _showAddMatiereDialog(BuildContext context, List<Map<String, dynamic>> niveaux) {
    if (niveaux.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Créez d\'abord un niveau'), backgroundColor: AppColors.error),
      );
      return;
    }

    final nomController = TextEditingController();
    final codeController = TextEditingController();
    final ordreController = TextEditingController(text: '0');
    final iconeController = TextEditingController();
    String? selectedNiveauId = niveaux.first['id']?.toString();

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: AppColors.success.withOpacity(0.1),
                borderRadius: BorderRadius.circular(12),
              ),
              child: const Icon(LucideIcons.bookOpen, color: AppColors.success, size: 24),
            ),
            const SizedBox(width: 12),
            Text('Ajouter une matière', style: GoogleFonts.inter(fontWeight: FontWeight.w700, fontSize: 18)),
          ],
        ),
        content: SizedBox(
          width: 400,
          child: SingleChildScrollView(
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
                    initialValue: selectedNiveauId,
                    decoration: InputDecoration(
                      labelText: 'Niveau',
                      prefixIcon: const Icon(LucideIcons.layers, color: AppColors.primary, size: 20),
                      border: InputBorder.none,
                      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
                      labelStyle: GoogleFonts.inter(fontSize: 13, color: AppColors.textSub),
                    ),
                    items: niveaux.map((n) => DropdownMenuItem<String>(
                      value: n['id']?.toString(),
                      child: Text(n['nom']?.toString() ?? '', style: GoogleFonts.inter(fontSize: 14)),
                    )).toList(),
                    onChanged: (v) => selectedNiveauId = v,
                  ),
                ),
                const SizedBox(height: 16),
                _buildStyledTextField(
                  controller: nomController,
                  label: 'Nom',
                  hint: 'ex: Mathématiques',
                  icon: LucideIcons.type,
                ),
                const SizedBox(height: 16),
                _buildStyledTextField(
                  controller: codeController,
                  label: 'Code',
                  hint: 'ex: MATH',
                  icon: LucideIcons.hash,
                ),
                const SizedBox(height: 16),
                _buildStyledTextField(
                  controller: iconeController,
                  label: 'Icône',
                  hint: 'optionnel',
                  icon: LucideIcons.image,
                ),
                const SizedBox(height: 16),
                _buildStyledTextField(
                  controller: ordreController,
                  label: 'Ordre',
                  hint: '0',
                  icon: LucideIcons.arrowUpDown,
                  keyboardType: TextInputType.number,
                ),
              ],
            ),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text('Annuler', style: GoogleFonts.inter(color: AppColors.textSub)),
          ),
          ElevatedButton(
            onPressed: () async {
              if (nomController.text.isEmpty || codeController.text.isEmpty || selectedNiveauId == null) {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Veuillez remplir tous les champs'), backgroundColor: AppColors.error),
                );
                return;
              }
              try {
                await context.read<AppState>().createMatiere({
                  'niveau_id': selectedNiveauId,
                  'nom': nomController.text,
                  'code': codeController.text,
                  'icone': iconeController.text,
                  'ordre': int.tryParse(ordreController.text) ?? 0,
                  'is_active': true,
                });
                if (context.mounted) {
                  Navigator.pop(context);
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('Matière ajoutée avec succès'), backgroundColor: AppColors.success),
                  );
                }
              } catch (e) {
                if (context.mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text('Erreur: $e'), backgroundColor: AppColors.error),
                  );
                }
              }
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.success,
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            ),
            child: Text('Ajouter', style: GoogleFonts.inter(fontWeight: FontWeight.w600)),
          ),
        ],
      ),
    );
  }

  void _showEditMatiereDialog(BuildContext context, Map<String, dynamic> matiere, List<Map<String, dynamic>> niveaux) {
    final nomController = TextEditingController(text: matiere['nom']);
    final codeController = TextEditingController(text: matiere['code']);
    final ordreController = TextEditingController(text: matiere['ordre']?.toString() ?? '0');
    final iconeController = TextEditingController(text: matiere['icone'] ?? '');
    String? selectedNiveauId = matiere['niveau_id']?.toString();

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: AppColors.warning.withOpacity(0.1),
                borderRadius: BorderRadius.circular(12),
              ),
              child: const Icon(LucideIcons.pencil, color: AppColors.warning, size: 24),
            ),
            const SizedBox(width: 12),
            Text('Modifier la matière', style: GoogleFonts.inter(fontWeight: FontWeight.w700, fontSize: 18)),
          ],
        ),
        content: SizedBox(
          width: 400,
          child: SingleChildScrollView(
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
                    initialValue: selectedNiveauId,
                    decoration: InputDecoration(
                      labelText: 'Niveau',
                      prefixIcon: const Icon(LucideIcons.layers, color: AppColors.primary, size: 20),
                      border: InputBorder.none,
                      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
                      labelStyle: GoogleFonts.inter(fontSize: 13, color: AppColors.textSub),
                    ),
                    items: niveaux.map((n) => DropdownMenuItem<String>(
                      value: n['id']?.toString(),
                      child: Text(n['nom']?.toString() ?? '', style: GoogleFonts.inter(fontSize: 14)),
                    )).toList(),
                    onChanged: (v) => selectedNiveauId = v,
                  ),
                ),
                const SizedBox(height: 16),
                _buildStyledTextField(
                  controller: nomController,
                  label: 'Nom',
                  hint: 'ex: Mathématiques',
                  icon: LucideIcons.type,
                ),
                const SizedBox(height: 16),
                _buildStyledTextField(
                  controller: codeController,
                  label: 'Code',
                  hint: 'ex: MATH',
                  icon: LucideIcons.hash,
                ),
                const SizedBox(height: 16),
                _buildStyledTextField(
                  controller: iconeController,
                  label: 'Icône',
                  hint: 'optionnel',
                  icon: LucideIcons.image,
                ),
                const SizedBox(height: 16),
                _buildStyledTextField(
                  controller: ordreController,
                  label: 'Ordre',
                  hint: '0',
                  icon: LucideIcons.arrowUpDown,
                  keyboardType: TextInputType.number,
                ),
              ],
            ),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text('Annuler', style: GoogleFonts.inter(color: AppColors.textSub)),
          ),
          ElevatedButton(
            onPressed: () async {
              if (nomController.text.isEmpty || codeController.text.isEmpty || selectedNiveauId == null) {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Veuillez remplir tous les champs'), backgroundColor: AppColors.error),
                );
                return;
              }
              try {
                await context.read<AppState>().updateMatiere(matiere['id'], {
                  'niveau_id': selectedNiveauId,
                  'nom': nomController.text,
                  'code': codeController.text,
                  'icone': iconeController.text,
                  'ordre': int.tryParse(ordreController.text) ?? 0,
                });
                if (context.mounted) {
                  Navigator.pop(context);
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('Matière modifiée avec succès'), backgroundColor: AppColors.success),
                  );
                }
              } catch (e) {
                if (context.mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text('Erreur: $e'), backgroundColor: AppColors.error),
                  );
                }
              }
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.warning,
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            ),
            child: Text('Modifier', style: GoogleFonts.inter(fontWeight: FontWeight.w600)),
          ),
        ],
      ),
    );
  }

  void _confirmDeleteMatiere(BuildContext context, String id) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Supprimer la matière', style: GoogleFonts.inter(fontWeight: FontWeight.w700)),
        content: const Text('Êtes-vous sûr de vouloir supprimer cette matière ?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Annuler'),
          ),
          ElevatedButton(
            onPressed: () async {
              try {
                await context.read<AppState>().deleteMatiere(id);
                if (context.mounted) Navigator.pop(context);
              } catch (e) {
                if (context.mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text('Erreur: $e'), backgroundColor: AppColors.error),
                  );
                }
              }
            },
            style: ElevatedButton.styleFrom(backgroundColor: AppColors.error),
            child: const Text('Supprimer'),
          ),
        ],
      ),
    );
  }
}

class _MatiereCard extends StatelessWidget {
  final Map<String, dynamic> matiere;
  final String niveauNom;
  final String filiereNom;
  final VoidCallback onEdit;
  final VoidCallback onDelete;

  const _MatiereCard({
    required this.matiere,
    required this.niveauNom,
    required this.filiereNom,
    required this.onEdit,
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
      child: Row(
        children: [
          Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              color: AppColors.success.withOpacity(0.1),
              borderRadius: BorderRadius.circular(8),
            ),
            child: const Icon(LucideIcons.bookOpen, color: AppColors.success),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  matiere['nom'] ?? 'Sans nom',
                  style: GoogleFonts.inter(fontSize: 16, fontWeight: FontWeight.w700, color: AppColors.text),
                ),
                Text(
                  '$filiereNom > $niveauNom • ${matiere['code'] ?? ''} • Ordre: ${matiere['ordre'] ?? 0}',
                  style: GoogleFonts.inter(fontSize: 12, color: AppColors.textSub),
                ),
              ],
            ),
          ),
          IconButton(
            onPressed: onEdit,
            icon: const Icon(LucideIcons.pencil, size: 18, color: AppColors.primary),
          ),
          IconButton(
            onPressed: onDelete,
            icon: const Icon(LucideIcons.trash2, size: 18, color: AppColors.error),
          ),
        ],
      ),
    );
  }
}
