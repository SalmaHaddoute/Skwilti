import 'dart:async';
import 'package:flutter/material.dart';
import 'package:lucide_icons/lucide_icons.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../theme/app_theme.dart';
import '../services/app_state.dart';
import '../services/messaging_service.dart';
import '../models/conversation.dart';
import '../models/user.dart' as app_user;
import '../widgets/modern_floating_button.dart';
import '../widgets/empty_state.dart';
import '../widgets/astronaut_illustration.dart';
import 'conversation_screen.dart';
import 'create_group_screen.dart';

class ConversationUIModel {
  final Conversation conversation;
  final String displayName;
  final String? displayAvatar;

  ConversationUIModel({
    required this.conversation,
    required this.displayName,
    this.displayAvatar,
  });
}

class MessagesScreen extends StatefulWidget {
  MessagesScreen({super.key});

  @override
  State<MessagesScreen> createState() => _MessagesScreenState();
}

class _MessagesScreenState extends State<MessagesScreen> with SingleTickerProviderStateMixin {
  final MessagingService _ms = MessagingService();
  late TabController _tabController;
  
  List<ConversationUIModel> _conversations = [];
  List<ConversationUIModel> _filteredConversations = [];
  bool _isLoading = true;
  String _searchQuery = '';
  StreamSubscription? _msgSubscription;
  String? _currentUserId;
  app_user.UserRole? _userRole;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
    
    // Get user info from AppState
    final appState = context.read<AppState>();
    _currentUserId = appState.currentUser?.id;
    _userRole = appState.currentUser?.role;

    _loadConversations();

    // Listen for realtime messages to auto-refresh the inbox list
    _msgSubscription = _ms.onMessage.listen((msg) {
      if (mounted && _currentUserId != null) {
        _loadConversations(silent: true);
      }
    });
  }

  @override
  void dispose() {
    _tabController.dispose();
    _msgSubscription?.cancel();
    
    // Refresh unread count when leaving messages screen
    if (_currentUserId != null) {
      context.read<AppState>().refreshUnreadMessagesCount();
    }
    
    super.dispose();
  }

  Future<void> _loadConversations({bool silent = false}) async {
    if (_currentUserId == null) return;
    
    if (!silent) {
      setState(() => _isLoading = true);
    }

    try {
      final rawConvs = await _ms.fetchConversations(_currentUserId!);
      final List<ConversationUIModel> resolved = [];

      for (var conv in rawConvs) {
        String displayName = conv.name ?? '';
        String? displayAvatar = conv.avatarUrl;

        // For direct chats, ALWAYS resolve the other user's name and avatar
        if (!conv.isGroup) {
          try {
            final otherUserProfile = await _ms.getOtherUserProfile(conv.id, _currentUserId!);
            
            if (otherUserProfile != null) {
              final firstName = otherUserProfile['first_name'] ?? '';
              final lastName = otherUserProfile['last_name'] ?? '';
              final fullName = '$firstName $lastName'.trim();
              
              if (fullName.isNotEmpty) {
                displayName = fullName;
                displayAvatar = otherUserProfile['avatar_url'];
              }
            }
          } catch (e) {
            print('[MessagesScreen] Failed to load other user profile for conversation ${conv.id}: $e');
          }
        }

        // Final fallback only if displayName is still empty
        if (displayName.isEmpty) {
          displayName = conv.isGroup ? 'Groupe de discussion' : 'Utilisateur';
        }

        resolved.add(ConversationUIModel(
          conversation: conv,
          displayName: displayName,
          displayAvatar: displayAvatar,
        ));
      }

      // Sort: updated_at descending, fallback to created_at
      resolved.sort((a, b) {
        final aTime = a.conversation.updatedAt ?? a.conversation.createdAt;
        final bTime = b.conversation.updatedAt ?? b.conversation.createdAt;
        return bTime.compareTo(aTime);
      });

      if (mounted) {
        setState(() {
          _conversations = resolved;
          _filterConversations();
          _isLoading = false;
        });
      }
    } catch (e) {
      print('[MessagesScreen] Error loading conversations: $e');
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  void _filterConversations() {
    if (_searchQuery.isEmpty) {
      _filteredConversations = _conversations;
    } else {
      _filteredConversations = _conversations.where((c) {
        final nameMatch = c.displayName.toLowerCase().contains(_searchQuery.toLowerCase());
        final msgMatch = (c.conversation.lastMessage ?? '').toLowerCase().contains(_searchQuery.toLowerCase());
        return nameMatch || msgMatch;
      }).toList();
    }
  }

  List<ConversationUIModel> get _directConversations =>
      _filteredConversations.where((c) => !c.conversation.isGroup).toList();

  List<ConversationUIModel> get _groupConversations =>
      _filteredConversations.where((c) => c.conversation.isGroup).toList();

  String _formatMessageTime(DateTime? dateTime) {
    if (dateTime == null) return '';
    final now = DateTime.now();
    final localTime = dateTime.toLocal();
    final diff = now.difference(localTime);

    if (diff.inDays == 0 && now.day == localTime.day) {
      return '${localTime.hour.toString().padLeft(2, '0')}:${localTime.minute.toString().padLeft(2, '0')}';
    } else if (diff.inDays == 1 || (diff.inDays == 0 && now.day != localTime.day)) {
      return 'Hier';
    } else if (diff.inDays < 7) {
      final weekdays = ['Lun', 'Mar', 'Mer', 'Jeu', 'Ven', 'Sam', 'Dim'];
      return weekdays[localTime.weekday - 1];
    } else {
      final months = [
        'janv.', 'févr.', 'mars', 'avr.', 'mai', 'juin',
        'juil.', 'août', 'sept.', 'oct.', 'nov.', 'déc.'
      ];
      return '${localTime.day} ${months[localTime.month - 1]}';
    }
  }

  Color _getGradientColor(String text) {
    final hash = text.codeUnits.fold(0, (prev, element) => prev + element);
    final colors = [
      const Color(0xFFE8630A),
      const Color(0xFF1B6B2E),
      const Color(0xFF2980B9),
      const Color(0xFF8E44AD),
      const Color(0xFFD35400),
      const Color(0xFF2C3E50),
    ];
    return colors[hash % colors.length];
  }

  void _navigateToConversation(ConversationUIModel uiModel) {
    // Reconstruct a Conversation object with resolved values so ConversationScreen has them
    final resolvedConversation = Conversation(
      id: uiModel.conversation.id,
      name: uiModel.displayName,
      avatarUrl: uiModel.displayAvatar,
      isGroup: uiModel.conversation.isGroup,
      lastMessage: uiModel.conversation.lastMessage,
      updatedAt: uiModel.conversation.updatedAt,
      unreadCount: 0, // Clear locally on push
      memberRole: uiModel.conversation.memberRole,
      isOnline: uiModel.conversation.isOnline,
      createdAt: uiModel.conversation.createdAt,
    );

    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => ConversationScreen(conversation: resolvedConversation),
      ),
    ).then((_) => _loadConversations(silent: true));
  }

  void _openContactsBottomSheet() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => _ContactsPickerSheet(
        currentUserId: _currentUserId!,
        userRole: _userRole!,
        onContactSelected: (contactId, contactName, contactAvatar) async {
          Navigator.pop(context); // Close bottom sheet
          
          // Show progress dialog
          showDialog(
            context: this.context,
            barrierDismissible: false,
            builder: (_) => const Center(child: CircularProgressIndicator(color: AppColors.primary)),
          );

          try {
            final convId = await _ms.getOrCreateDirectConversation(_currentUserId!, contactId);
            
            // Dismiss progress dialog
            if (this.context.mounted) {
              Navigator.pop(this.context);
            }

            final newConv = Conversation(
              id: convId,
              name: contactName,
              avatarUrl: contactAvatar,
              isGroup: false,
              createdAt: DateTime.now(),
            );

            if (this.context.mounted) {
              Navigator.push(
                this.context,
                MaterialPageRoute(
                  builder: (_) => ConversationScreen(conversation: newConv),
                ),
              ).then((_) => _loadConversations(silent: true));
            }
          } catch (e) {
            // Dismiss progress dialog
            if (this.context.mounted) {
              Navigator.pop(this.context);
              ScaffoldMessenger.of(this.context).showSnackBar(
                SnackBar(
                  content: Text('Impossible d\'ouvrir la conversation: $e'),
                  backgroundColor: AppColors.error,
                ),
              );
            }
          }
        },
        onCreateGroup: (groupType) {
          Navigator.pop(context); // Close bottom sheet
          _openCreateGroupScreen(groupType);
        },
      ),
    );
  }

  void _openCreateGroupScreen(String groupType) {
    // Import the create_group_screen.dart at the top of the file
    // Then navigate to it
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => CreateGroupScreen(
          currentUserId: _currentUserId!,
          groupType: groupType == 'students' ? GroupType.students : GroupType.parents,
        ),
      ),
    ).then((_) => _loadConversations(silent: true));
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.transparent,
      appBar: AppBar(
        title: Text(
          'Messagerie',
          style: GoogleFonts.nunito(
            fontSize: 22,
            fontWeight: FontWeight.w800,
            color: AppColors.text,
          ),
        ),
        elevation: 0,
        backgroundColor: Colors.white,
        actions: [
          IconButton(
            icon: const Icon(LucideIcons.refreshCw, size: 18),
            onPressed: () => _loadConversations(),
          ),
          const SizedBox(width: 8),
        ],
      ),
      body: Column(
            children: [
              // Search & Filter header
              Container(
                color: Colors.white,
                padding: const EdgeInsets.fromLTRB(16, 8, 16, 12),
                child: Column(
                  children: [
                    // Search Bar
                    Container(
                      decoration: BoxDecoration(
                        color: AppColors.background,
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(color: AppColors.border, width: 0.5),
                      ),
                      child: TextField(
                        onChanged: (val) {
                          setState(() {
                            _searchQuery = val;
                            _filterConversations();
                          });
                        },
                        decoration: InputDecoration(
                          hintText: 'Rechercher une discussion...',
                          hintStyle: GoogleFonts.nunito(color: AppColors.textSub, fontSize: 14),
                          prefixIcon: const Icon(LucideIcons.search, size: 16, color: AppColors.textSub),
                          border: InputBorder.none,
                          enabledBorder: InputBorder.none,
                          focusedBorder: InputBorder.none,
                          contentPadding: const EdgeInsets.symmetric(vertical: 12, horizontal: 16),
                          fillColor: Colors.transparent,
                        ),
                      ),
                    ),
                    const SizedBox(height: 12),
                    // Tab bar selection
                    TabBar(
                      controller: _tabController,
                      labelColor: AppColors.primary,
                      unselectedLabelColor: AppColors.textSecondary,
                      indicatorColor: AppColors.primary,
                      indicatorSize: TabBarIndicatorSize.tab,
                      labelStyle: GoogleFonts.nunito(fontWeight: FontWeight.bold, fontSize: 14),
                      tabs: const [
                        Tab(text: 'Toutes'),
                        Tab(text: 'Directes'),
                        Tab(text: 'Groupes'),
                      ],
                    ),
                  ],
                ),
              ),
              
              // Conversation lists
              Expanded(
                child: _isLoading
                    ? const Center(child: CircularProgressIndicator(color: AppColors.primary))
                    : TabBarView(
                        controller: _tabController,
                        children: [
                          _buildConversationList(_filteredConversations),
                          _buildConversationList(_directConversations),
                          _buildConversationList(_groupConversations),
                        ],
                      ),
              ),
            ],
          ),
      floatingActionButton: ModernFloatingButton_Message(
        onPressed: _openContactsBottomSheet,
      ),
      floatingActionButtonLocation: FloatingActionButtonLocation.endFloat,
    );
  }

  Widget _buildConversationList(List<ConversationUIModel> list) {
    if (list.isEmpty) {
      return RefreshIndicator(
        onRefresh: () => _loadConversations(silent: true),
        color: AppColors.primary,
        child: ListView(
          physics: const AlwaysScrollableScrollPhysics(),
          children: [
            SizedBox(height: MediaQuery.of(context).size.height * 0.1),
            EmptyState(
              title: 'Aucune discussion trouvée',
              subtitle: 'Touchez le bouton + pour démarrer une nouvelle conversation.',
              astronautType: AstronautType.welcome,
              astronautSize: 120,
            ),
          ],
        ),
      );
    }

    return RefreshIndicator(
      onRefresh: () => _loadConversations(silent: true),
      color: AppColors.primary,
      child: ListView.separated(
        physics: const AlwaysScrollableScrollPhysics(),
        padding: const EdgeInsets.symmetric(vertical: 8),
        itemCount: list.length,
        separatorBuilder: (_, __) => const Divider(color: AppColors.border, height: 1),
        itemBuilder: (context, index) {
          final uiModel = list[index];
          final c = uiModel.conversation;
          final unreadCount = c.unreadCount ?? 0;
          final hasUnread = unreadCount > 0;
          final initials = uiModel.displayName.isNotEmpty
              ? uiModel.displayName.substring(0, 1).toUpperCase()
              : 'D';

          return ListTile(
            onTap: () => _navigateToConversation(uiModel),
            contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
            leading: Stack(
              children: [
                uiModel.displayAvatar != null && uiModel.displayAvatar!.isNotEmpty
                    ? CircleAvatar(
                        radius: 26,
                        backgroundImage: NetworkImage(uiModel.displayAvatar!),
                        backgroundColor: Colors.transparent,
                      )
                    : Container(
                        width: 52,
                        height: 52,
                        decoration: BoxDecoration(
                          gradient: LinearGradient(
                            colors: [
                              _getGradientColor(uiModel.displayName),
                              _getGradientColor(uiModel.displayName).withOpacity(0.7),
                            ],
                            begin: Alignment.topLeft,
                            end: Alignment.bottomRight,
                          ),
                          shape: BoxShape.circle,
                        ),
                        child: Center(
                          child: Text(
                            initials,
                            style: GoogleFonts.nunito(
                              color: Colors.white,
                              fontSize: 20,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                      ),
                if (c.isOnline == true)
                  Positioned(
                    right: 0,
                    bottom: 0,
                    child: Container(
                      width: 14,
                      height: 14,
                      decoration: BoxDecoration(
                        color: AppColors.success,
                        shape: BoxShape.circle,
                        border: Border.all(color: Colors.white, width: 2),
                      ),
                    ),
                  ),
              ],
            ),
            title: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Expanded(
                  child: Text(
                    uiModel.displayName,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: GoogleFonts.nunito(
                      fontSize: 16,
                      fontWeight: hasUnread ? FontWeight.w800 : FontWeight.w700,
                      color: AppColors.text,
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                Text(
                  _formatMessageTime(c.updatedAt ?? c.createdAt),
                  style: GoogleFonts.nunito(
                    fontSize: 12,
                    fontWeight: hasUnread ? FontWeight.w700 : FontWeight.normal,
                    color: hasUnread ? AppColors.primary : AppColors.textSub,
                  ),
                ),
              ],
            ),
            subtitle: Padding(
              padding: const EdgeInsets.only(top: 4.0),
              child: Row(
                children: [
                  Expanded(
                    child: Text(
                      c.lastMessage ?? 'Aucun message pour l\'instant',
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: GoogleFonts.nunito(
                        fontSize: 14,
                        fontWeight: hasUnread ? FontWeight.w600 : FontWeight.normal,
                        color: hasUnread ? AppColors.text : AppColors.textSecondary,
                      ),
                    ),
                  ),
                  if (hasUnread) ...[
                    const SizedBox(width: 8),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                      decoration: const BoxDecoration(
                        color: AppColors.primary,
                        shape: BoxShape.circle,
                      ),
                      child: Center(
                        child: Text(
                          '$unreadCount',
                          style: GoogleFonts.nunito(
                            color: Colors.white,
                            fontSize: 11,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    ),
                  ]
                ],
              ),
            ),
          );
        },
      ),
    );
  }
}

class _ContactsPickerSheet extends StatefulWidget {
  final String currentUserId;
  final app_user.UserRole userRole;
  final Function(String contactId, String contactName, String? contactAvatar) onContactSelected;
  final Function(String groupType)? onCreateGroup;

  const _ContactsPickerSheet({
    required this.currentUserId,
    required this.userRole,
    required this.onContactSelected,
    this.onCreateGroup,
  });

  @override
  State<_ContactsPickerSheet> createState() => _ContactsPickerSheetState();
}

class _ContactsPickerSheetState extends State<_ContactsPickerSheet> with SingleTickerProviderStateMixin {
  final MessagingService _ms = MessagingService();
  late TabController _tabController;
  
  List<Map<String, dynamic>> _teachers = [];
  List<Map<String, dynamic>> _students = [];
  bool _loading = true;
  String _searchQuery = '';

  @override
  void initState() {
    super.initState();
    // Teacher sees students and other teachers, so 2 tabs
    // Student/Parent sees only teachers, so no tabs needed
    final hasMultipleTabs = widget.userRole == app_user.UserRole.teacher;
    _tabController = TabController(length: hasMultipleTabs ? 2 : 1, vsync: this);
    _loadContacts();
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  Future<void> _loadContacts() async {
    setState(() => _loading = true);
    try {
      if (widget.userRole == app_user.UserRole.student) {
        final list = await _ms.getTeachersForStudent(widget.currentUserId);
        _teachers = list;
      } else if (widget.userRole == app_user.UserRole.parent) {
        final list = await _ms.getTeachersForParent(widget.currentUserId);
        _teachers = list;
      } else if (widget.userRole == app_user.UserRole.teacher) {
        final studs = await _ms.getStudentsForTeacher(widget.currentUserId);
        final teachs = await _ms.getAllOtherTeachers(widget.currentUserId);
        _students = studs;
        _teachers = teachs;
      } else {
        // Admin or fallback
        final teachs = await _ms.getAllOtherTeachers(widget.currentUserId);
        _teachers = teachs;
      }
    } catch (e) {
      print('[ContactsPickerSheet] Error loading contacts: $e');
    } finally {
      if (mounted) {
        setState(() => _loading = false);
      }
    }
  }

  List<Map<String, dynamic>> _filterList(List<Map<String, dynamic>> original) {
    if (_searchQuery.isEmpty) return original;
    return original.where((c) {
      final firstName = (c['first_name'] ?? '').toString().toLowerCase();
      final lastName = (c['last_name'] ?? '').toString().toLowerCase();
      return firstName.contains(_searchQuery.toLowerCase()) ||
          lastName.contains(_searchQuery.toLowerCase());
    }).toList();
  }

  @override
  Widget build(BuildContext context) {
    final hasMultipleTabs = widget.userRole == app_user.UserRole.teacher;

    return Container(
      height: MediaQuery.of(context).size.height * 0.8,
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      child: Column(
        children: [
          // Drag handle
          const SizedBox(height: 12),
          Container(
            width: 40,
            height: 4,
            decoration: BoxDecoration(
              color: AppColors.border,
              borderRadius: BorderRadius.circular(2),
            ),
          ),
          const SizedBox(height: 12),
          
          // Header
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'Nouveau message',
                  style: GoogleFonts.nunito(
                    fontSize: 18,
                    fontWeight: FontWeight.w800,
                    color: AppColors.text,
                  ),
                ),
                TextButton(
                  onPressed: () => Navigator.pop(context),
                  child: Text(
                    'Annuler',
                    style: GoogleFonts.nunito(
                      fontWeight: FontWeight.bold,
                      color: AppColors.textSecondary,
                    ),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 8),

          // Search Field
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: Container(
              decoration: BoxDecoration(
                color: AppColors.background,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: AppColors.border, width: 0.5),
              ),
              child: TextField(
                onChanged: (val) {
                  setState(() => _searchQuery = val);
                },
                decoration: InputDecoration(
                  hintText: 'Rechercher un contact...',
                  hintStyle: GoogleFonts.nunito(color: AppColors.textSub, fontSize: 14),
                  prefixIcon: const Icon(LucideIcons.search, size: 16, color: AppColors.textSub),
                  border: InputBorder.none,
                  enabledBorder: InputBorder.none,
                  focusedBorder: InputBorder.none,
                  contentPadding: const EdgeInsets.symmetric(vertical: 12, horizontal: 16),
                  fillColor: Colors.transparent,
                ),
              ),
            ),
          ),
          const SizedBox(height: 8),

          // Group creation buttons for teachers
          if (widget.userRole == app_user.UserRole.teacher)
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: Column(
                children: [
                  // Create student group button
                  InkWell(
                    onTap: () {
                      if (widget.onCreateGroup != null) {
                        widget.onCreateGroup!('students');
                      }
                    },
                    borderRadius: BorderRadius.circular(12),
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                      decoration: BoxDecoration(
                        color: AppColors.primaryLight,
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: AppColors.primary, width: 1),
                      ),
                      child: Row(
                        children: [
                          Container(
                            padding: const EdgeInsets.all(8),
                            decoration: const BoxDecoration(
                              color: AppColors.primary,
                              shape: BoxShape.circle,
                            ),
                            child: const Icon(
                              LucideIcons.users,
                              size: 18,
                              color: Colors.white,
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  'Créer un groupe d\'élèves',
                                  style: GoogleFonts.nunito(
                                    fontWeight: FontWeight.bold,
                                    color: AppColors.primary,
                                    fontSize: 15,
                                  ),
                                ),
                                Text(
                                  'Messagerie de groupe avec vos élèves',
                                  style: GoogleFonts.nunito(
                                    fontSize: 12,
                                    color: AppColors.textSecondary,
                                  ),
                                ),
                              ],
                            ),
                          ),
                          const Icon(
                            LucideIcons.chevronRight,
                            size: 18,
                            color: AppColors.primary,
                          ),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: 8),
                  // Create parent group button
                  InkWell(
                    onTap: () {
                      if (widget.onCreateGroup != null) {
                        widget.onCreateGroup!('parents');
                      }
                    },
                    borderRadius: BorderRadius.circular(12),
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                      decoration: BoxDecoration(
                        color: const Color(0xFFFFF4E6),
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: const Color(0xFFFF9800), width: 1),
                      ),
                      child: Row(
                        children: [
                          Container(
                            padding: const EdgeInsets.all(8),
                            decoration: const BoxDecoration(
                              color: Color(0xFFFF9800),
                              shape: BoxShape.circle,
                            ),
                            child: const Icon(
                              LucideIcons.userCheck,
                              size: 18,
                              color: Colors.white,
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  'Créer un groupe de parents',
                                  style: GoogleFonts.nunito(
                                    fontWeight: FontWeight.bold,
                                    color: const Color(0xFFFF9800),
                                    fontSize: 15,
                                  ),
                                ),
                                Text(
                                  'Messagerie de groupe avec les parents',
                                  style: GoogleFonts.nunito(
                                    fontSize: 12,
                                    color: AppColors.textSecondary,
                                  ),
                                ),
                              ],
                            ),
                          ),
                          const Icon(
                            LucideIcons.chevronRight,
                            size: 18,
                            color: Color(0xFFFF9800),
                          ),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: 12),
                  const Divider(color: AppColors.border, height: 1),
                  const SizedBox(height: 8),
                ],
              ),
            ),

          // Tab Bar if multiple categories
          if (hasMultipleTabs)
            TabBar(
              controller: _tabController,
              labelColor: AppColors.primary,
              unselectedLabelColor: AppColors.textSecondary,
              indicatorColor: AppColors.primary,
              indicatorSize: TabBarIndicatorSize.tab,
              labelStyle: GoogleFonts.nunito(fontWeight: FontWeight.bold, fontSize: 14),
              tabs: const [
                Tab(text: 'Élèves'),
                Tab(text: 'Enseignants'),
              ],
            ),

          // Content
          Expanded(
            child: _loading
                ? const Center(child: CircularProgressIndicator(color: AppColors.primary))
                : hasMultipleTabs
                    ? TabBarView(
                        controller: _tabController,
                        children: [
                          _buildContactsList(_filterList(_students)),
                          _buildContactsList(_filterList(_teachers)),
                        ],
                      )
                    : _buildContactsList(_filterList(_teachers)),
          ),
        ],
      ),
    );
  }

  Widget _buildContactsList(List<Map<String, dynamic>> contacts) {
    if (contacts.isEmpty) {
      return EmptyStatePage(
        emptyState: EmptyState(
          title: 'Aucun contact disponible',
          subtitle: 'Vos contacts apparaîtront ici une fois que vous serez dans une classe.',
          astronautType: AstronautType.welcome,
        ),
      );
    }

    return ListView.separated(
      padding: const EdgeInsets.all(16),
      itemCount: contacts.length,
      separatorBuilder: (_, __) => const Divider(color: AppColors.border, height: 1),
      itemBuilder: (context, index) {
        final c = contacts[index];
        final id = c['id'].toString();
        final firstName = c['first_name']?.toString() ?? '';
        final lastName = c['last_name']?.toString() ?? '';
        final fullName = '$firstName $lastName'.trim();
        final avatar = c['avatar_url']?.toString();
        final initials = fullName.isNotEmpty ? fullName.substring(0, 1).toUpperCase() : 'U';

        // Check if there is an additional detail like classroom role or class name
        String? subtitle;
        if (c.containsKey('role')) {
          final role = c['role']?.toString();
          if (role == 'teacher') subtitle = 'Enseignant';
          if (role == 'student') subtitle = 'Élève';
        }

        return ListTile(
          onTap: () => widget.onContactSelected(id, fullName, avatar),
          contentPadding: const EdgeInsets.symmetric(vertical: 4),
          leading: avatar != null && avatar.isNotEmpty
              ? CircleAvatar(
                  radius: 22,
                  backgroundImage: NetworkImage(avatar),
                  backgroundColor: Colors.transparent,
                )
              : Container(
                  width: 44,
                  height: 44,
                  decoration: const BoxDecoration(
                    color: AppColors.primaryLight,
                    shape: BoxShape.circle,
                  ),
                  child: Center(
                    child: Text(
                      initials,
                      style: GoogleFonts.nunito(
                        color: AppColors.primary,
                        fontWeight: FontWeight.bold,
                        fontSize: 16,
                      ),
                    ),
                  ),
                ),
          title: Text(
            fullName,
            style: GoogleFonts.nunito(
              fontWeight: FontWeight.w700,
              color: AppColors.text,
              fontSize: 15,
            ),
          ),
          subtitle: subtitle != null
              ? Text(
                  subtitle,
                  style: GoogleFonts.nunito(
                    color: AppColors.textSecondary,
                    fontSize: 12,
                  ),
                )
              : null,
          trailing: const Icon(LucideIcons.chevronRight, size: 16, color: AppColors.textSub),
        );
      },
    );
  }
}