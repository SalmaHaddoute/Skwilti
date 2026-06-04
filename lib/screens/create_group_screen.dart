import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:lucide_icons/lucide_icons.dart';
import '../theme/app_theme.dart';
import '../services/messaging_service.dart';
import '../models/conversation.dart';
import 'conversation_screen.dart';

enum GroupType { students, parents }

class CreateGroupScreen extends StatefulWidget {
  final String currentUserId;
  final GroupType groupType;

  const CreateGroupScreen({
    super.key,
    required this.currentUserId,
    required this.groupType,
  });

  @override
  State<CreateGroupScreen> createState() => _CreateGroupScreenState();
}

class _CreateGroupScreenState extends State<CreateGroupScreen> {
  final MessagingService _ms = MessagingService();
  final TextEditingController _groupNameController = TextEditingController();
  
  List<Map<String, dynamic>> _availableMembers = [];
  Set<String> _selectedMemberIds = {};
  bool _loading = true;
  String _searchQuery = '';

  @override
  void initState() {
    super.initState();
    _loadMembers();
  }

  @override
  void dispose() {
    _groupNameController.dispose();
    super.dispose();
  }

  Future<void> _loadMembers() async {
    setState(() => _loading = true);
    try {
      if (widget.groupType == GroupType.students) {
        // Load students
        final students = await _ms.getStudentsForTeacher(widget.currentUserId);
        print('[CreateGroupScreen] Students loaded: ${students.length}');
        _availableMembers = students;
      } else {
        // Load parents - try both methods
        print('[CreateGroupScreen] Loading parents for teacher: ${widget.currentUserId}');
        
        // Method 1: Get students with their parents
        final studentsWithParents = await _ms.getStudentsWithParentsForTeacher(widget.currentUserId);
        print('[CreateGroupScreen] Students with parents: ${studentsWithParents.length}');
        
        // Extract unique parents
        final Map<String, Map<String, dynamic>> parentsMap = {};
        for (var student in studentsWithParents) {
          final parents = student['parents'] as List<dynamic>? ?? [];
          print('[CreateGroupScreen] Student ${student['first_name']} has ${parents.length} parents');
          for (var parent in parents) {
            final parentId = parent['id'].toString();
            if (!parentsMap.containsKey(parentId)) {
              parentsMap[parentId] = {
                'id': parentId,
                'first_name': parent['first_name'],
                'last_name': parent['last_name'],
                'avatar_url': parent['avatar_url'],
                'role': 'parent',
              };
            }
          }
        }
        
        print('[CreateGroupScreen] Unique parents found: ${parentsMap.length}');
        
        // If no parents found via students, try getting all parents
        if (parentsMap.isEmpty) {
          print('[CreateGroupScreen] No parents via students, trying all parents method');
          final allParents = await _ms.getAllParentsForTeacher(widget.currentUserId);
          print('[CreateGroupScreen] All parents method returned: ${allParents.length}');
          _availableMembers = allParents;
        } else {
          _availableMembers = parentsMap.values.toList();
        }
      }
      
      print('[CreateGroupScreen] Final available members: ${_availableMembers.length}');
    } catch (e) {
      print('[CreateGroupScreen] Error loading members: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Erreur lors du chargement des membres: $e'),
            backgroundColor: AppColors.error,
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _loading = false);
      }
    }
  }

  List<Map<String, dynamic>> get _filteredMembers {
    if (_searchQuery.isEmpty) return _availableMembers;
    return _availableMembers.where((member) {
      final firstName = (member['first_name'] ?? '').toString().toLowerCase();
      final lastName = (member['last_name'] ?? '').toString().toLowerCase();
      final query = _searchQuery.toLowerCase();
      return firstName.contains(query) || lastName.contains(query);
    }).toList();
  }

  Future<void> _createGroup() async {
    final groupName = _groupNameController.text.trim();
    
    if (groupName.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Veuillez entrer un nom de groupe'),
          backgroundColor: AppColors.error,
        ),
      );
      return;
    }

    if (_selectedMemberIds.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Veuillez sélectionner au moins un membre'),
          backgroundColor: AppColors.error,
        ),
      );
      return;
    }

    // Show loading dialog
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (_) => const Center(
        child: CircularProgressIndicator(color: AppColors.primary),
      ),
    );

    try {
      final conversationId = await _ms.createGroupConversation(
        groupName: groupName,
        memberIds: _selectedMemberIds.toList(),
        creatorId: widget.currentUserId,
      );

      // Dismiss loading dialog
      if (mounted) {
        Navigator.pop(context);
      }

      // Create conversation object
      final newConversation = Conversation(
        id: conversationId,
        name: groupName,
        isGroup: true,
        createdAt: DateTime.now(),
      );

      // Navigate to conversation screen
      if (mounted) {
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(
            builder: (_) => ConversationScreen(conversation: newConversation),
          ),
        );
      }
    } catch (e) {
      // Dismiss loading dialog
      if (mounted) {
        Navigator.pop(context);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Erreur lors de la création du groupe: $e'),
            backgroundColor: AppColors.error,
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final groupTypeLabel = widget.groupType == GroupType.students ? 'Élèves' : 'Parents';
    
    return Scaffold(
      backgroundColor: Colors.transparent,
      appBar: AppBar(
        title: Text(
          'Créer un groupe de $groupTypeLabel',
          style: GoogleFonts.nunito(
            fontSize: 20,
            fontWeight: FontWeight.w800,
            color: AppColors.text,
          ),
        ),
        elevation: 0,
        backgroundColor: Colors.white,
        iconTheme: const IconThemeData(color: AppColors.text),
        actions: [
          TextButton(
            onPressed: _createGroup,
            child: Text(
              'Créer',
              style: GoogleFonts.nunito(
                fontWeight: FontWeight.bold,
                color: AppColors.primary,
                fontSize: 16,
              ),
            ),
          ),
          const SizedBox(width: 8),
        ],
      ),
      body: Column(
        children: [
          // Group name input
          Container(
            color: Colors.white,
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Nom du groupe',
                  style: GoogleFonts.nunito(
                    fontSize: 14,
                    fontWeight: FontWeight.bold,
                    color: AppColors.textSecondary,
                  ),
                ),
                const SizedBox(height: 8),
                Container(
                  decoration: BoxDecoration(
                    color: AppColors.background,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: AppColors.border, width: 0.5),
                  ),
                  child: TextField(
                    controller: _groupNameController,
                    decoration: InputDecoration(
                      hintText: 'Ex: Classe 6ème A, Parents 5ème B...',
                      hintStyle: GoogleFonts.nunito(
                        color: AppColors.textSub,
                        fontSize: 14,
                      ),
                      border: InputBorder.none,
                      enabledBorder: InputBorder.none,
                      focusedBorder: InputBorder.none,
                      contentPadding: const EdgeInsets.symmetric(
                        horizontal: 16,
                        vertical: 12,
                      ),
                    ),
                    style: GoogleFonts.nunito(fontSize: 15),
                  ),
                ),
              ],
            ),
          ),

          const Divider(height: 1, color: AppColors.border),

          // Search bar
          Container(
            color: Colors.white,
            padding: const EdgeInsets.all(16),
            child: Container(
              decoration: BoxDecoration(
                color: AppColors.background,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: AppColors.border, width: 0.5),
              ),
              child: TextField(
                onChanged: (val) {
                  setState(() => _searchQuery = val);
                },
                decoration: InputDecoration(
                  hintText: 'Rechercher un membre...',
                  hintStyle: GoogleFonts.nunito(
                    color: AppColors.textSub,
                    fontSize: 14,
                  ),
                  prefixIcon: const Icon(
                    LucideIcons.search,
                    size: 18,
                    color: AppColors.textSub,
                  ),
                  border: InputBorder.none,
                  enabledBorder: InputBorder.none,
                  focusedBorder: InputBorder.none,
                  contentPadding: const EdgeInsets.symmetric(
                    vertical: 12,
                    horizontal: 16,
                  ),
                ),
              ),
            ),
          ),

          // Selected count
          if (_selectedMemberIds.isNotEmpty)
            Container(
              color: AppColors.primaryLight,
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              child: Row(
                children: [
                  const Icon(
                    LucideIcons.users,
                    size: 18,
                    color: AppColors.primary,
                  ),
                  const SizedBox(width: 8),
                  Text(
                    '${_selectedMemberIds.length} membre(s) sélectionné(s)',
                    style: GoogleFonts.nunito(
                      fontWeight: FontWeight.bold,
                      color: AppColors.primary,
                      fontSize: 14,
                    ),
                  ),
                ],
              ),
            ),

          // Members list
          Expanded(
            child: _loading
                ? const Center(
                    child: CircularProgressIndicator(color: AppColors.primary),
                  )
                : _filteredMembers.isEmpty
                    ? Center(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            const Icon(
                              LucideIcons.users,
                              size: 48,
                              color: AppColors.textSub,
                            ),
                            const SizedBox(height: 12),
                            Text(
                              _searchQuery.isEmpty
                                  ? 'Aucun membre disponible'
                                  : 'Aucun résultat',
                              style: GoogleFonts.nunito(
                                color: AppColors.textSecondary,
                                fontWeight: FontWeight.bold,
                                fontSize: 15,
                              ),
                            ),
                          ],
                        ),
                      )
                    : ListView.separated(
                        padding: const EdgeInsets.symmetric(vertical: 8),
                        itemCount: _filteredMembers.length,
                        separatorBuilder: (_, __) => const Divider(
                          color: AppColors.border,
                          height: 1,
                        ),
                        itemBuilder: (context, index) {
                          final member = _filteredMembers[index];
                          final memberId = member['id'].toString();
                          final firstName = member['first_name']?.toString() ?? '';
                          final lastName = member['last_name']?.toString() ?? '';
                          final fullName = '$firstName $lastName'.trim();
                          final avatar = member['avatar_url']?.toString();
                          final isSelected = _selectedMemberIds.contains(memberId);
                          final initials = fullName.isNotEmpty
                              ? fullName.substring(0, 1).toUpperCase()
                              : 'U';

                          return ListTile(
                            onTap: () {
                              setState(() {
                                if (isSelected) {
                                  _selectedMemberIds.remove(memberId);
                                } else {
                                  _selectedMemberIds.add(memberId);
                                }
                              });
                            },
                            contentPadding: const EdgeInsets.symmetric(
                              horizontal: 16,
                              vertical: 4,
                            ),
                            leading: Stack(
                              children: [
                                avatar != null && avatar.isNotEmpty
                                    ? CircleAvatar(
                                        radius: 24,
                                        backgroundImage: NetworkImage(avatar),
                                        backgroundColor: Colors.transparent,
                                      )
                                    : Container(
                                        width: 48,
                                        height: 48,
                                        decoration: BoxDecoration(
                                          color: AppColors.primaryLight,
                                          shape: BoxShape.circle,
                                        ),
                                        child: Center(
                                          child: Text(
                                            initials,
                                            style: GoogleFonts.nunito(
                                              color: AppColors.primary,
                                              fontWeight: FontWeight.bold,
                                              fontSize: 18,
                                            ),
                                          ),
                                        ),
                                      ),
                                if (isSelected)
                                  Positioned(
                                    right: 0,
                                    bottom: 0,
                                    child: Container(
                                      width: 20,
                                      height: 20,
                                      decoration: BoxDecoration(
                                        color: AppColors.primary,
                                        shape: BoxShape.circle,
                                        border: Border.all(
                                          color: Colors.white,
                                          width: 2,
                                        ),
                                      ),
                                      child: const Icon(
                                        Icons.check,
                                        size: 12,
                                        color: Colors.white,
                                      ),
                                    ),
                                  ),
                              ],
                            ),
                            title: Text(
                              fullName,
                              style: GoogleFonts.nunito(
                                fontWeight: FontWeight.w700,
                                color: AppColors.text,
                                fontSize: 15,
                              ),
                            ),
                            subtitle: member.containsKey('classe_id') &&
                                    member['classe_id'] != null
                                ? Text(
                                    'Classe ID: ${member['classe_id']}',
                                    style: GoogleFonts.nunito(
                                      fontSize: 13,
                                      color: AppColors.textSecondary,
                                    ),
                                  )
                                : null,
                            trailing: Checkbox(
                              value: isSelected,
                              onChanged: (val) {
                                setState(() {
                                  if (val == true) {
                                    _selectedMemberIds.add(memberId);
                                  } else {
                                    _selectedMemberIds.remove(memberId);
                                  }
                                });
                              },
                              activeColor: AppColors.primary,
                            ),
                          );
                        },
                      ),
          ),
        ],
      ),
    );
  }
}
