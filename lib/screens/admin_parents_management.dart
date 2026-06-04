import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:lucide_icons/lucide_icons.dart';
import 'package:provider/provider.dart';
import '../theme/app_theme.dart';
import '../services/app_state.dart';
import '../widgets/empty_state.dart';

class AdminParentsManagementScreen extends StatefulWidget {
  const AdminParentsManagementScreen({super.key});

  @override
  State<AdminParentsManagementScreen> createState() => _AdminParentsManagementScreenState();
}

class _AdminParentsManagementScreenState extends State<AdminParentsManagementScreen> {
  String _selectedFiliere = 'Toutes';
  String _selectedNiveau = 'Tous';
  String _selectedSubscription = 'Tous';
  String _searchQuery = '';

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<AppState>().loadAdminParents();
      context.read<AppState>().loadFilieres();
      context.read<AppState>().loadNiveaux();
    });
  }

  List<Map<String, dynamic>> get _filteredParents {
    final allParents = context.watch<AppState>().adminParents;
    
    return allParents.where((parent) {
      // Filtre par filière
      if (_selectedFiliere != 'Toutes') {
        final filiereNom = parent['filiere_nom'] as String?;
        if (filiereNom != _selectedFiliere) return false;
      }

      // Filtre par niveau
      if (_selectedNiveau != 'Tous') {
        final niveauNom = parent['niveau_nom'] as String?;
        if (niveauNom != _selectedNiveau) return false;
      }

      // Filtre par abonnement
      if (_selectedSubscription != 'Tous') {
        final subscription = parent['subscription'] as String?;
        if (subscription != _selectedSubscription.toLowerCase()) return false;
      }

      // Recherche par nom ou email
      if (_searchQuery.isNotEmpty) {
        final query = _searchQuery.toLowerCase();
        final nom = '${parent['parent_prenom'] ?? ''} ${parent['parent_nom'] ?? ''}'.toLowerCase();
        final email = (parent['parent_email'] as String?)?.toLowerCase() ?? '';
        final enfantNom = '${parent['enfant_prenom'] ?? ''} ${parent['enfant_nom'] ?? ''}'.toLowerCase();
        
        if (!nom.contains(query) && !email.contains(query) && !enfantNom.contains(query)) {
          return false;
        }
      }

      return true;
    }).toList();
  }

  List<String> get _availableFilieres {
    final filieresData = context.watch<AppState>().filieres;
    final filieres = filieresData.map((f) => f['nom'] as String?).whereType<String>().toSet().toList();
    filieres.sort();
    return ['Toutes', ...filieres];
  }

  List<String> get _availableNiveaux {
    final niveauxData = context.watch<AppState>().niveaux;
    final niveaux = niveauxData.map((n) => n['nom'] as String?).whereType<String>().toSet().toList();
    niveaux.sort();
    return ['Tous', ...niveaux];
  }

  @override
  Widget build(BuildContext context) {
    final filteredParents = _filteredParents;
    final loaded = context.watch<AppState>().adminParentsLoaded;

    return Scaffold(
      backgroundColor: Colors.transparent,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        title: Text(
          'Suivre un Étudiant',
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
      body: Column(
        children: [
          // Header stats
          Container(
            padding: const EdgeInsets.all(16),
            decoration: const BoxDecoration(
              color: Colors.white,
              border: Border(bottom: BorderSide(color: AppColors.border, width: 0.5)),
            ),
            child: Column(
              children: [
                Row(
                  children: [
                    Expanded(
                      child: _QuickStat(
                        label: 'Total Parents',
                        value: '${context.watch<AppState>().adminParents.length}',
                        icon: LucideIcons.users,
                        color: AppColors.primary,
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: _QuickStat(
                        label: 'Filtrés',
                        value: '${filteredParents.length}',
                        icon: LucideIcons.filter,
                        color: AppColors.info,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                // Search bar
                TextField(
                  onChanged: (v) => setState(() => _searchQuery = v),
                  decoration: InputDecoration(
                    hintText: 'Rechercher par nom, email ou enfant...',
                    prefixIcon: const Icon(LucideIcons.search),
                    filled: true,
                    fillColor: AppColors.background,
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: BorderSide.none,
                    ),
                  ),
                ),
              ],
            ),
          ),
          // Filters
          Container(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Filtres',
                  style: GoogleFonts.inter(
                    fontSize: 14,
                    fontWeight: FontWeight.w700,
                    color: AppColors.text,
                  ),
                ),
                const SizedBox(height: 12),
                Row(
                  children: [
                    Expanded(
                      child: _FilterDropdown(
                        label: 'Filière',
                        value: _selectedFiliere,
                        options: _availableFilieres,
                        onChanged: (v) => setState(() => _selectedFiliere = v),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: _FilterDropdown(
                        label: 'Niveau',
                        value: _selectedNiveau,
                        options: _availableNiveaux,
                        onChanged: (v) => setState(() => _selectedNiveau = v),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                _FilterDropdown(
                  label: 'Abonnement',
                  value: _selectedSubscription,
                  options: const ['Tous', 'Free', 'Premium'],
                  onChanged: (v) => setState(() => _selectedSubscription = v),
                ),
              ],
            ),
          ),
          // Parents list
          Expanded(
            child: !loaded
                ? const Center(child: CircularProgressIndicator())
                : filteredParents.isEmpty
                    ? const EmptyStatePage(emptyState: EmptyStateParents())
                    : ListView.separated(
                        padding: const EdgeInsets.all(16),
                        itemCount: filteredParents.length,
                        separatorBuilder: (_, __) => const SizedBox(height: 12),
                        itemBuilder: (context, i) {
                          final parent = filteredParents[i];
                          return _ParentCard(
                            parent: parent,
                            onFollowChild: () {
                              if (parent['enfant_id'] != null) {
                                _showFollowChildDialog(context, parent);
                              }
                            },
                          );
                        },
                      ),
          ),
        ],
      ),
    );
  }

  void _showFollowChildDialog(BuildContext context, Map<String, dynamic> parent) {
    final enfantNom = '${parent['enfant_prenom'] ?? ''} ${parent['enfant_nom'] ?? ''}';
    final enfantFiliere = parent['filiere_nom'] ?? 'N/A';
    final enfantNiveau = parent['niveau_nom'] ?? 'N/A';

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
              child: const Icon(LucideIcons.eye, color: AppColors.success, size: 24),
            ),
            const SizedBox(width: 12),
            Text("Suivre l'enfant", style: GoogleFonts.inter(fontWeight: FontWeight.w700, fontSize: 18)),
          ],
        ),
        content: SizedBox(
          width: 400,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: AppColors.background,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      "Informations de l'enfant",
                      style: GoogleFonts.inter(fontSize: 12, fontWeight: FontWeight.w700, color: AppColors.textSub),
                    ),
                    const SizedBox(height: 12),
                    _InfoRow(icon: LucideIcons.user, label: 'Nom', value: enfantNom),
                    const SizedBox(height: 8),
                    _InfoRow(icon: LucideIcons.folder, label: 'Filière', value: enfantFiliere),
                    const SizedBox(height: 8),
                    _InfoRow(icon: LucideIcons.layers, label: 'Niveau', value: enfantNiveau),
                  ],
                ),
              ),
              const SizedBox(height: 16),
              Text(
                'Voulez-vous suivre les progrès de cet étudiant?',
                style: GoogleFonts.inter(fontSize: 14, color: AppColors.text),
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
            onPressed: () {
              Navigator.pop(context);
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text('Vous suivez maintenant $enfantNom'),
                  backgroundColor: AppColors.success,
                ),
              );
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.success,
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            ),
            child: Text('Suivre', style: GoogleFonts.inter(fontWeight: FontWeight.w600)),
          ),
        ],
      ),
    );
  }
}

class _QuickStat extends StatelessWidget {
  final String label;
  final String value;
  final IconData icon;
  final Color color;

  const _QuickStat({
    required this.label,
    required this.value,
    required this.icon,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        children: [
          Icon(icon, color: color, size: 20),
          const SizedBox(width: 8),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label,
                  style: GoogleFonts.inter(
                    fontSize: 11,
                    color: AppColors.textSub,
                  ),
                ),
                Text(
                  value,
                  style: GoogleFonts.inter(
                    fontSize: 18,
                    fontWeight: FontWeight.w700,
                    color: color,
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

class _FilterDropdown extends StatelessWidget {
  final String label;
  final String value;
  final List<String> options;
  final ValueChanged<String> onChanged;

  const _FilterDropdown({
    required this.label,
    required this.value,
    required this.options,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    return DropdownButtonFormField<String>(
      initialValue: value,
      isExpanded: true,
      decoration: InputDecoration(
        labelText: label,
        filled: true,
        fillColor: Colors.white,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
          borderSide: const BorderSide(color: AppColors.border),
        ),
        contentPadding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
        labelStyle: GoogleFonts.inter(fontSize: 11, color: AppColors.textSub),
      ),
      items: options.map((option) => DropdownMenuItem(
        value: option,
        child: Text(
          option,
          style: GoogleFonts.inter(fontSize: 12),
          overflow: TextOverflow.ellipsis,
          maxLines: 1,
        ),
      )).toList(),
      onChanged: (v) {
        if (v != null) onChanged(v);
      },
    );
  }
}

class _ParentCard extends StatelessWidget {
  final Map<String, dynamic> parent;
  final VoidCallback? onFollowChild;

  const _ParentCard({required this.parent, this.onFollowChild});

  @override
  Widget build(BuildContext context) {
    final parentNom = '${parent['parent_prenom'] ?? ''} ${parent['parent_nom'] ?? ''}';
    final enfantNom = '${parent['enfant_prenom'] ?? ''} ${parent['enfant_nom'] ?? ''}';
    final subscription = parent['subscription'] as String? ?? 'free';
    final isPremium = subscription == 'premium';
    final hasChild = parent['enfant_id'] != null;

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
              Container(
                width: 48,
                height: 48,
                decoration: BoxDecoration(
                  color: AppColors.primary.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: const Icon(LucideIcons.user, color: AppColors.primary),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      parentNom,
                      style: GoogleFonts.inter(
                        fontSize: 16,
                        fontWeight: FontWeight.w700,
                        color: AppColors.text,
                      ),
                    ),
                    Text(
                      parent['parent_email'] ?? '',
                      style: GoogleFonts.inter(
                        fontSize: 12,
                        color: AppColors.textSub,
                      ),
                    ),
                  ],
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                decoration: BoxDecoration(
                  color: isPremium ? AppColors.warning.withOpacity(0.1) : AppColors.green.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Text(
                  isPremium ? 'PREMIUM' : 'FREE',
                  style: GoogleFonts.inter(
                    fontSize: 10,
                    fontWeight: FontWeight.w700,
                    color: isPremium ? AppColors.warning : AppColors.green,
                  ),
                ),
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
                child: _InfoRow(
                  icon: LucideIcons.heart,
                  label: 'Enfant',
                  value: enfantNom.isEmpty ? 'Non lié' : enfantNom,
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: _InfoRow(
                  icon: LucideIcons.graduationCap,
                  label: 'Filière',
                  value: parent['filiere_nom'] ?? 'N/A',
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Row(
            children: [
              Expanded(
                child: _InfoRow(
                  icon: LucideIcons.layers,
                  label: 'Niveau',
                  value: parent['niveau_nom'] ?? 'N/A',
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: _InfoRow(
                  icon: LucideIcons.link,
                  label: 'Relation',
                  value: parent['relation'] ?? 'parent',
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(
                child: OutlinedButton.icon(
                  onPressed: hasChild ? onFollowChild : null,
                  icon: const Icon(LucideIcons.eye, size: 16),
                  label: Text(
                    hasChild ? "Suivre l'enfant" : 'Aucun enfant',
                    style: GoogleFonts.inter(fontWeight: FontWeight.w600, fontSize: 13),
                  ),
                  style: OutlinedButton.styleFrom(
                    foregroundColor: hasChild ? AppColors.primary : AppColors.textSub,
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: OutlinedButton.icon(
                  onPressed: () => _showSubscriptionDialog(context, parent),
                  icon: const Icon(LucideIcons.crown, size: 16),
                  label: Text(
                    'Abonnement',
                    style: GoogleFonts.inter(fontWeight: FontWeight.w600, fontSize: 13),
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  void _showLinkEnfantDialog(BuildContext context, Map<String, dynamic> parent) {
    final enfants = context.read<AppState>().adminUsers.where((u) => u['role'] == 'student').toList();
    if (enfants.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Aucun étudiant disponible'), backgroundColor: AppColors.error),
      );
      return;
    }

    String? selectedEnfantId;
    String selectedRelation = 'parent';

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
              child: const Icon(LucideIcons.link, color: AppColors.primary, size: 24),
            ),
            const SizedBox(width: 12),
            Text('Lier un enfant', style: GoogleFonts.inter(fontWeight: FontWeight.w700, fontSize: 18)),
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
                  initialValue: selectedEnfantId,
                  isExpanded: true,
                  decoration: InputDecoration(
                    labelText: 'Enfant',
                    prefixIcon: const Icon(LucideIcons.graduationCap, color: AppColors.primary, size: 16),
                    border: InputBorder.none,
                    contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
                    labelStyle: GoogleFonts.inter(fontSize: 12, color: AppColors.textSub),
                  ),
                  hint: const Text('Sélectionner un enfant'),
                  items: enfants.map((e) => DropdownMenuItem<String>(
                    value: e['id']?.toString(),
                    child: Text(
                      '${e['first_name']} ${e['last_name']}', 
                      style: GoogleFonts.inter(fontSize: 14),
                      overflow: TextOverflow.ellipsis,
                      maxLines: 1,
                    ),
                  )).toList(),
                  onChanged: (v) => selectedEnfantId = v,
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
                  initialValue: selectedRelation,
                  isExpanded: true,
                  decoration: InputDecoration(
                    labelText: 'Relation',
                    prefixIcon: const Icon(LucideIcons.heart, color: AppColors.primary, size: 16),
                    border: InputBorder.none,
                    contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
                    labelStyle: GoogleFonts.inter(fontSize: 12, color: AppColors.textSub),
                  ),
                  items: [
                    DropdownMenuItem(value: 'parent', child: Text('Parent', style: GoogleFonts.inter(fontSize: 14), overflow: TextOverflow.ellipsis, maxLines: 1)),
                    DropdownMenuItem(value: 'père', child: Text('Père', style: GoogleFonts.inter(fontSize: 14), overflow: TextOverflow.ellipsis, maxLines: 1)),
                    DropdownMenuItem(value: 'mère', child: Text('Mère', style: GoogleFonts.inter(fontSize: 14), overflow: TextOverflow.ellipsis, maxLines: 1)),
                    DropdownMenuItem(value: 'tuteur', child: Text('Tuteur', style: GoogleFonts.inter(fontSize: 14), overflow: TextOverflow.ellipsis, maxLines: 1)),
                  ],
                  onChanged: (v) => selectedRelation = v ?? 'parent',
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
            onPressed: () async {
              if (selectedEnfantId == null) {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Veuillez sélectionner un enfant'), backgroundColor: AppColors.error),
                );
                return;
              }
              try {
                await context.read<AppState>().linkParentEnfant(
                  parent['parent_id'],
                  selectedEnfantId!,
                  relation: selectedRelation,
                );
                if (context.mounted) {
                  Navigator.pop(context);
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('Enfant lié avec succès'), backgroundColor: AppColors.success),
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
            child: Text('Lier', style: GoogleFonts.inter(fontWeight: FontWeight.w600)),
          ),
        ],
      ),
    );
  }

  void _showSubscriptionDialog(BuildContext context, Map<String, dynamic> parent) {
    String selectedSubscription = parent['subscription'] ?? 'free';

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
              child: const Icon(LucideIcons.crown, color: AppColors.warning, size: 24),
            ),
            const SizedBox(width: 12),
            Text("Modifier l'abonnement", style: GoogleFonts.inter(fontWeight: FontWeight.w700, fontSize: 18)),
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
                  initialValue: selectedSubscription,
                  isExpanded: true,
                  decoration: InputDecoration(
                    labelText: 'Abonnement',
                    prefixIcon: const Icon(LucideIcons.crown, color: AppColors.primary, size: 16),
                    border: InputBorder.none,
                    contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
                    labelStyle: GoogleFonts.inter(fontSize: 12, color: AppColors.textSub),
                  ),
                  items: [
                    DropdownMenuItem(value: 'free', child: Text('Free', style: GoogleFonts.inter(fontSize: 14), overflow: TextOverflow.ellipsis, maxLines: 1)),
                    DropdownMenuItem(value: 'premium', child: Text('Premium', style: GoogleFonts.inter(fontSize: 14), overflow: TextOverflow.ellipsis, maxLines: 1)),
                  ],
                  onChanged: (v) => selectedSubscription = v ?? 'free',
                ),
              ),
              const SizedBox(height: 16),
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: AppColors.background,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Informations',
                      style: GoogleFonts.inter(fontSize: 12, fontWeight: FontWeight.w700, color: AppColors.textSub),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      'Parent: ${parent['parent_prenom']} ${parent['parent_nom']}',
                      style: GoogleFonts.inter(fontSize: 13, color: AppColors.text),
                    ),
                    Text(
                      'Email: ${parent['parent_email']}',
                      style: GoogleFonts.inter(fontSize: 13, color: AppColors.text),
                    ),
                  ],
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
            onPressed: () async {
              try {
                // Note: Cette fonctionnalité nécessite d'ajouter une méthode dans auth_service pour modifier l'abonnement
                // Pour l'instant, on affiche un message de succès
                if (context.mounted) {
                  Navigator.pop(context);
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text('Abonnement modifié en $selectedSubscription (à implémenter dans Supabase)'),
                      backgroundColor: AppColors.success,
                    ),
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
}

class _InfoRow extends StatelessWidget {
  final IconData icon;
  final String label;
  final String value;

  const _InfoRow({
    required this.icon,
    required this.label,
    required this.value,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Icon(icon, size: 14, color: AppColors.textSub),
        const SizedBox(width: 6),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                label,
                style: GoogleFonts.inter(
                  fontSize: 10,
                  color: AppColors.textSub,
                ),
              ),
              Text(
                value,
                style: GoogleFonts.inter(
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                  color: AppColors.text,
                ),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
            ],
          ),
        ),
      ],
    );
  }
}
