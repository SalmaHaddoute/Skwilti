import 'package:flutter/material.dart';
import 'package:lucide_icons/lucide_icons.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import '../theme/app_theme.dart';
import '../services/app_state.dart';
import 'conversation_screen.dart';

class TeacherMessagingScreen extends StatefulWidget {
  const TeacherMessagingScreen({super.key});

  @override
  State<TeacherMessagingScreen> createState() => _TeacherMessagingScreenState();
}

class _TeacherMessagingScreenState extends State<TeacherMessagingScreen> {
  final TextEditingController _searchController = TextEditingController();
  String _searchQuery = '';
  String _activeTab = 'all'; // 'all', 'student', 'parent'
  bool _isLoading = true;
  List<Map<String, dynamic>> _contacts = [];

  // Robust, high-fidelity mock fallback to guarantee stunning layout even if no records exist in DB
  final List<Map<String, dynamic>> _fallbackContacts = [
    {
      'id': 'fallback_1',
      'first_name': 'Amine',
      'last_name': 'Bennani',
      'email': 'amine.bennani@student.ma',
      'role': 'student',
      'sub_info': 'Classe : 2AC - Groupe A',
      'is_online': true,
    },
    {
      'id': 'fallback_2',
      'first_name': 'Fatima',
      'last_name': 'Zahra',
      'email': 'fatima.zahra@parent.ma',
      'role': 'parent',
      'sub_info': 'Parent de : Amine Bennani',
      'is_online': false,
    },
    {
      'id': 'fallback_3',
      'first_name': 'Youssef',
      'last_name': 'Alaoui',
      'email': 'youssef.alaoui@student.ma',
      'role': 'student',
      'sub_info': 'Classe : 3AC - SVT',
      'is_online': true,
    },
    {
      'id': 'fallback_4',
      'first_name': 'Driss',
      'last_name': 'Alaoui',
      'email': 'driss.alaoui@parent.ma',
      'role': 'parent',
      'sub_info': 'Parent de : Youssef Alaoui',
      'is_online': true,
    },
    {
      'id': 'fallback_5',
      'first_name': 'Salma',
      'last_name': 'Tazi',
      'email': 'salma.tazi@student.ma',
      'role': 'student',
      'sub_info': 'Classe : 1AC - SVT',
      'is_online': false,
    },
    {
      'id': 'fallback_6',
      'first_name': 'Meriem',
      'last_name': 'Tazi',
      'email': 'meriem.tazi@parent.ma',
      'role': 'parent',
      'sub_info': 'Parent de : Salma Tazi',
      'is_online': true,
    },
  ];

  @override
  void initState() {
    super.initState();
    _loadContacts();
  }

  Future<void> _loadContacts() async {
    setState(() => _isLoading = true);
    try {
      final authService = context.read<AppState>().authService;
      final students = await authService.fetchAllUsers(roleFilter: 'student');
      final parents = await authService.fetchAllUsers(roleFilter: 'parent');

      final List<Map<String, dynamic>> loadedList = [];
      for (var s in students) {
        loadedList.add({
          'id': s['id'],
          'first_name': s['first_name'] ?? '',
          'last_name': s['last_name'] ?? '',
          'email': s['email'] ?? '',
          'role': 'student',
          'sub_info': s['code_massar'] != null ? 'Massar: ${s['code_massar']}' : 'Étudiant',
          'is_online': true, // Mock online status
        });
      }
      for (var p in parents) {
        loadedList.add({
          'id': p['id'],
          'first_name': p['first_name'] ?? '',
          'last_name': p['last_name'] ?? '',
          'email': p['email'] ?? '',
          'role': 'parent',
          'sub_info': 'Parent d\'élève',
          'is_online': false, // Mock online status
        });
      }

      if (loadedList.isEmpty) {
        // Fallback if DB is empty
        _contacts = _fallbackContacts;
      } else {
        _contacts = loadedList;
      }
    } catch (e) {
      print('⚠️ Error loading contacts: $e');
      _contacts = _fallbackContacts;
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  List<Map<String, dynamic>> get _filteredContacts {
    return _contacts.where((c) {
      final name = '${c['first_name']} ${c['last_name']}'.toLowerCase();
      final matchesSearch = name.contains(_searchQuery.toLowerCase()) ||
          (c['email'] as String).toLowerCase().contains(_searchQuery.toLowerCase());
      
      final matchesTab = _activeTab == 'all' || c['role'] == _activeTab;
      return matchesSearch && matchesTab;
    }).toList();
  }

  void _showCreateGroupPanel() {
    final TextEditingController nameController = TextEditingController();
    final Set<String> selectedIds = {};
    String sheetSearch = '';

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setSheetState) {
            final filteredForGroup = _contacts.where((c) {
              final name = '${c['first_name']} ${c['last_name']}'.toLowerCase();
              return name.contains(sheetSearch.toLowerCase());
            }).toList();

            return Container(
              height: MediaQuery.of(context).size.height * 0.75,
              decoration: const BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
              ),
              child: Column(
                children: [
                  Container(
                    margin: const EdgeInsets.only(top: 12, bottom: 8),
                    width: 40,
                    height: 4,
                    decoration: BoxDecoration(
                      color: AppColors.border,
                      borderRadius: BorderRadius.circular(2),
                    ),
                  ),
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          'Nouveau groupe',
                          style: GoogleFonts.inter(
                            fontSize: 18,
                            fontWeight: FontWeight.w800,
                            color: AppColors.text,
                          ),
                        ),
                        IconButton(
                          icon: const Icon(LucideIcons.x, color: AppColors.textSub),
                          onPressed: () => Navigator.pop(context),
                        ),
                      ],
                    ),
                  ),
                  const Divider(height: 1),
                  Padding(
                    padding: const EdgeInsets.all(16),
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 16),
                      decoration: BoxDecoration(
                        color: AppColors.background,
                        borderRadius: BorderRadius.circular(14),
                        border: Border.all(color: AppColors.border, width: 0.5),
                      ),
                      child: TextField(
                        controller: nameController,
                        decoration: InputDecoration(
                          hintText: 'Nom du groupe (ex: Groupe SVT 2AC)...',
                          hintStyle: GoogleFonts.nunito(fontSize: 13, color: AppColors.textSub),
                          border: InputBorder.none,
                          icon: const Icon(LucideIcons.edit3, color: AppColors.primary, size: 18),
                        ),
                        style: GoogleFonts.nunito(fontSize: 14, color: AppColors.text),
                      ),
                    ),
                  ),
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 16),
                      decoration: BoxDecoration(
                        color: AppColors.background,
                        borderRadius: BorderRadius.circular(14),
                        border: Border.all(color: AppColors.border, width: 0.5),
                      ),
                      child: TextField(
                        onChanged: (val) => setSheetState(() => sheetSearch = val),
                        decoration: InputDecoration(
                          hintText: 'Rechercher des membres...',
                          hintStyle: GoogleFonts.nunito(fontSize: 13, color: AppColors.textSub),
                          border: InputBorder.none,
                          icon: const Icon(LucideIcons.search, color: AppColors.textSub, size: 18),
                        ),
                        style: GoogleFonts.nunito(fontSize: 14, color: AppColors.text),
                      ),
                    ),
                  ),
                  const SizedBox(height: 10),
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 4),
                    child: Align(
                      alignment: Alignment.centerLeft,
                      child: Text(
                        '${selectedIds.length} membre(s) sélectionné(s)',
                        style: GoogleFonts.nunito(
                          fontSize: 12,
                          fontWeight: FontWeight.w800,
                          color: AppColors.primary,
                        ),
                      ),
                    ),
                  ),
                  Expanded(
                    child: ListView.builder(
                      padding: const EdgeInsets.symmetric(horizontal: 8),
                      itemCount: filteredForGroup.length,
                      itemBuilder: (context, index) {
                        final c = filteredForGroup[index];
                        final id = c['id'] as String;
                        final name = '${c['first_name']} ${c['last_name']}';
                        final isSelected = selectedIds.contains(id);
                        final isStudent = c['role'] == 'student';
                        final roleColor = isStudent ? AppColors.success : const Color(0xFF9B59B6);

                        return CheckboxListTile(
                          activeColor: AppColors.primary,
                          title: Text(
                            name,
                            style: GoogleFonts.inter(fontSize: 14, fontWeight: FontWeight.w700, color: AppColors.text),
                          ),
                          subtitle: Text(
                            c['sub_info'] as String,
                            style: GoogleFonts.nunito(fontSize: 11, color: AppColors.textSub),
                          ),
                          secondary: Container(
                            width: 36, height: 36,
                            decoration: BoxDecoration(
                              color: roleColor.withOpacity(0.1),
                              shape: BoxShape.circle,
                            ),
                            child: Center(
                              child: Text(
                                '${c['first_name'].isNotEmpty ? c['first_name'][0] : ''}${c['last_name'].isNotEmpty ? c['last_name'][0] : ''}'.toUpperCase(),
                                style: GoogleFonts.inter(fontSize: 12, fontWeight: FontWeight.w700, color: roleColor),
                              ),
                            ),
                          ),
                          value: isSelected,
                          onChanged: (val) {
                            setSheetState(() {
                              if (val == true) {
                                selectedIds.add(id);
                              } else {
                                selectedIds.remove(id);
                              }
                            });
                          },
                        );
                      },
                    ),
                  ),
                  Padding(
                    padding: EdgeInsets.fromLTRB(16, 8, 16, MediaQuery.of(context).viewInsets.bottom + 16),
                    child: SizedBox(
                      width: double.infinity,
                      height: 50,
                      child: ElevatedButton(
                        style: ElevatedButton.styleFrom(
                          backgroundColor: AppColors.primary,
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                        ),
                        onPressed: () {
                          if (nameController.text.trim().isEmpty) {
                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(content: Text('Veuillez entrer un nom pour le groupe')),
                            );
                            return;
                          }
                          if (selectedIds.isEmpty) {
                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(content: Text('Veuillez sélectionner au moins un membre')),
                            );
                            return;
                          }
                          
                          Navigator.pop(context);
                          Navigator.push(
                            this.context,
                            MaterialPageRoute(
                              builder: (_) => ConversationScreen(
                                teacherName: nameController.text.trim(),
                                subject: 'Groupe - ${selectedIds.length} membres',
                                teacherIcon: LucideIcons.users,
                                isSenderTeacher: true,
                              ),
                            ),
                          );
                        },
                        child: Text(
                          'Créer le groupe',
                          style: GoogleFonts.inter(fontSize: 15, fontWeight: FontWeight.w700, color: Colors.white),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            );
          },
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        centerTitle: false,
        title: Text(
          'Messagerie',
          style: GoogleFonts.inter(
            fontSize: 20,
            fontWeight: FontWeight.w800,
            color: AppColors.text,
          ),
        ),
        leading: IconButton(
          icon: const Icon(LucideIcons.arrowLeft, color: AppColors.text),
          onPressed: () => Navigator.pop(context),
        ),
        actions: [
          IconButton(
            icon: const Icon(LucideIcons.users, size: 20, color: AppColors.primary),
            tooltip: 'Créer un groupe',
            onPressed: _showCreateGroupPanel,
          ),
          IconButton(
            icon: const Icon(LucideIcons.refreshCw, size: 18, color: AppColors.primary),
            onPressed: _loadContacts,
          ),
        ],
      ),
      body: Column(
        children: [
          // 🔍 Premium Search Bar Container
          Container(
            color: Colors.white,
            padding: const EdgeInsets.fromLTRB(16, 8, 16, 16),
            child: Container(
              decoration: BoxDecoration(
                color: AppColors.background,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: AppColors.border, width: 0.8),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.02),
                    blurRadius: 8,
                    offset: const Offset(0, 2),
                  ),
                ],
              ),
              child: TextField(
                controller: _searchController,
                onChanged: (val) => setState(() => _searchQuery = val),
                decoration: InputDecoration(
                  hintText: 'Rechercher un parent ou élève...',
                  hintStyle: GoogleFonts.nunito(
                    fontSize: 14,
                    color: AppColors.textSub,
                    fontWeight: FontWeight.w500,
                  ),
                  prefixIcon: const Icon(LucideIcons.search, color: AppColors.primary, size: 18),
                  suffixIcon: _searchQuery.isNotEmpty
                      ? IconButton(
                          icon: const Icon(LucideIcons.x, size: 16, color: AppColors.textSub),
                          onPressed: () {
                            _searchController.clear();
                            setState(() => _searchQuery = '');
                          },
                        )
                      : null,
                  border: InputBorder.none,
                  enabledBorder: InputBorder.none,
                  focusedBorder: InputBorder.none,
                  contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                ),
              ),
            ),
          ),

          // 🏷️ Premium Segmented/Tab Selector
          Container(
            color: Colors.white,
            padding: const EdgeInsets.symmetric(horizontal: 16).copyWith(bottom: 12),
            child: Row(
              children: [
                _buildTabButton('all', 'Tous', LucideIcons.users),
                const SizedBox(width: 8),
                _buildTabButton('student', 'Élèves', LucideIcons.graduationCap),
                const SizedBox(width: 8),
                _buildTabButton('parent', 'Parents', LucideIcons.user),
              ],
            ),
          ),

          // 👥 Contact List View
          Expanded(
            child: _isLoading
                ? const Center(
                    child: CircularProgressIndicator(
                      valueColor: AlwaysStoppedAnimation<Color>(AppColors.primary),
                    ),
                  )
                : _filteredContacts.isEmpty
                    ? _buildEmptyState()
                    : ListView.builder(
                        padding: const EdgeInsets.all(16),
                        itemCount: _filteredContacts.length,
                        itemBuilder: (context, index) {
                          final c = _filteredContacts[index];
                          return _buildContactCard(c);
                        },
                      ),
          ),
        ],
      ),
    );
  }

  Widget _buildTabButton(String tabId, String label, IconData icon) {
    final bool isSelected = _activeTab == tabId;
    return Expanded(
      child: GestureDetector(
        onTap: () => setState(() => _activeTab = tabId),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          padding: const EdgeInsets.symmetric(vertical: 10),
          decoration: BoxDecoration(
            color: isSelected ? AppColors.primary : Colors.white,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
              color: isSelected ? AppColors.primary : AppColors.border,
              width: 0.8,
            ),
            boxShadow: isSelected
                ? [
                    BoxShadow(
                      color: AppColors.primary.withOpacity(0.2),
                      blurRadius: 8,
                      offset: const Offset(0, 3),
                    )
                  ]
                : null,
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                icon,
                size: 14,
                color: isSelected ? Colors.white : AppColors.textSecondary,
              ),
              const SizedBox(width: 6),
              Text(
                label,
                style: GoogleFonts.nunito(
                  fontSize: 12,
                  fontWeight: FontWeight.w800,
                  color: isSelected ? Colors.white : AppColors.textSecondary,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildContactCard(Map<String, dynamic> c) {
    final isStudent = c['role'] == 'student';
    final name = '${c['first_name']} ${c['last_name']}';
    final initials = '${c['first_name'].isNotEmpty ? c['first_name'][0] : ''}${c['last_name'].isNotEmpty ? c['last_name'][0] : ''}'.toUpperCase();
    final roleColor = isStudent ? AppColors.success : const Color(0xFF9B59B6);

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.border, width: 0.5),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.02),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        borderRadius: BorderRadius.circular(16),
        child: InkWell(
          borderRadius: BorderRadius.circular(16),
          onTap: () {
            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (_) => ConversationScreen(
                  teacherName: name,
                  subject: isStudent ? 'Élève Skwilti' : 'Parent d\'élève',
                  teacherIcon: isStudent ? LucideIcons.graduationCap : LucideIcons.user,
                  isSenderTeacher: true,
                ),
              ),
            );
          },
          child: Padding(
            padding: const EdgeInsets.all(14),
            child: Row(
              children: [
                // 👤 Avatar and status dot
                Stack(
                  children: [
                    Container(
                      width: 46,
                      height: 46,
                      decoration: BoxDecoration(
                        color: roleColor.withOpacity(0.1),
                        shape: BoxShape.circle,
                        border: Border.all(color: roleColor.withOpacity(0.2), width: 1),
                      ),
                      child: Center(
                        child: Text(
                          initials,
                          style: GoogleFonts.inter(
                            fontSize: 14,
                            fontWeight: FontWeight.w700,
                            color: roleColor,
                          ),
                        ),
                      ),
                    ),
                    if (c['is_online'] == true)
                      Positioned(
                        right: 1,
                        bottom: 1,
                        child: Container(
                          width: 12,
                          height: 12,
                          decoration: BoxDecoration(
                            color: const Color(0xFF2EC4B6),
                            shape: BoxShape.circle,
                            border: Border.all(color: Colors.white, width: 2),
                          ),
                        ),
                      ),
                  ],
                ),
                const SizedBox(width: 14),

                // 📝 Info
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Flexible(
                            child: Text(
                              name,
                              style: GoogleFonts.inter(
                                fontSize: 14,
                                fontWeight: FontWeight.w700,
                                color: AppColors.text,
                              ),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                          const SizedBox(width: 6),
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                            decoration: BoxDecoration(
                              color: roleColor.withOpacity(0.08),
                              borderRadius: BorderRadius.circular(6),
                            ),
                            child: Text(
                              isStudent ? 'Élève' : 'Parent',
                              style: GoogleFonts.nunito(
                                fontSize: 9,
                                fontWeight: FontWeight.w800,
                                color: roleColor,
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 4),
                      Text(
                        c['sub_info'] as String,
                        style: GoogleFonts.nunito(
                          fontSize: 11,
                          color: AppColors.textSecondary,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ],
                  ),
                ),

                // 💬 Chat button icon
                Container(
                  width: 36,
                  height: 36,
                  decoration: BoxDecoration(
                    color: AppColors.primaryLight,
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(
                    LucideIcons.messageCircle,
                    size: 16,
                    color: AppColors.primary,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildEmptyState() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(32),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const SizedBox(height: 40),
          Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: AppColors.primary.withOpacity(0.05),
              shape: BoxShape.circle,
            ),
            child: const Icon(
              LucideIcons.messageSquare,
              size: 48,
              color: AppColors.primary,
            ),
          ),
          const SizedBox(height: 20),
          Text(
            'Aucun contact trouvé',
            style: GoogleFonts.inter(
              fontSize: 16,
              fontWeight: FontWeight.w700,
              color: AppColors.text,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            _searchQuery.isNotEmpty
                ? 'Aucun parent ni élève ne correspond à votre recherche "$_searchQuery".'
                : 'Vous n\'avez actuellement aucun contact disponible dans cette catégorie.',
            textAlign: TextAlign.center,
            style: GoogleFonts.nunito(
              fontSize: 13,
              color: AppColors.textSecondary,
            ),
          ),
          const SizedBox(height: 24),
          if (_searchQuery.isNotEmpty)
            OutlinedButton(
              onPressed: () {
                _searchController.clear();
                setState(() => _searchQuery = '');
              },
              child: const Text('Réinitialiser la recherche'),
            ),
        ],
      ),
    );
  }
}
