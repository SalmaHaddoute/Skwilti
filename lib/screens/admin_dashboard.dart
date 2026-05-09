import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:lucide_icons/lucide_icons.dart';
import 'package:provider/provider.dart';
import '../theme/app_theme.dart';
import '../models/user.dart';
import '../services/app_state.dart';
import 'admin_course_management.dart';
import 'lesson_upload_screen.dart';
import '../widgets/admin_users_table.dart';
import '../widgets/admin_subscription_chart.dart';
import '../widgets/skwilti_nav.dart';
import 'profile_screen.dart';

class AdminDashboard extends StatefulWidget {
  const AdminDashboard({super.key});
  @override
  State<AdminDashboard> createState() => _AdminDashboardState();
}

class _AdminDashboardState extends State<AdminDashboard> {
  int _idx = 0;
  static const _nav = [
    SkwNavItem(icon: LucideIcons.layers, label: 'Dashboard'),
    SkwNavItem(icon: LucideIcons.users, label: 'Utilisateurs'),
    SkwNavItem(icon: LucideIcons.bookOpen, label: 'Bibliothèque'),
  ];

  @override
  Widget build(BuildContext context) {
    final user = context.watch<AppState>().currentUser;
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: SkwiltiTopNav(
        title: ['Skwilti Admin', 'Utilisateurs', 'Bibliothèque'][_idx],
        showLogo: true,
        showNotifications: true,
        onProfileTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const ProfileScreen())),
      ),
      body: IndexedStack(index: _idx, children: [
        _StatsTab(),
        _UsersTab(),
        _CoursesTab(),
      ]),
      bottomNavigationBar: SkwiltiBottomNav(currentIndex: _idx, onTap: (i) => setState(() => _idx = i), items: _nav),
    );
  }
}

class _StatsTab extends StatefulWidget {
  @override
  State<_StatsTab> createState() => _StatsTabState();
}

class _StatsTabState extends State<_StatsTab> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final s = context.read<AppState>();
      s.loadGlobalStats();
      s.loadAdminUsers();
      s.loadAdminCourses();
    });
  }

  @override
  Widget build(BuildContext context) {
    final globalStats = context.watch<AppState>().globalStats;
    final loaded      = context.watch<AppState>().globalStatsLoaded;
    final activity    = context.watch<AppState>().weeklyActivity;

    final stats = [
      (LucideIcons.users, '${globalStats?.totalStudents ?? '--'}', 'Étudiants', AppColors.green, globalStats != null && globalStats.totalUsers > 0 ? globalStats.totalStudents / globalStats.totalUsers : 0.0),
      (LucideIcons.graduationCap, '${globalStats?.totalTeachers ?? '--'}', 'Enseignants', AppColors.primary, globalStats != null && globalStats.totalUsers > 0 ? globalStats.totalTeachers / globalStats.totalUsers : 0.0),
      (LucideIcons.heart, '${globalStats?.totalParents ?? '--'}', 'Parents', const Color(0xFF9B59B6), globalStats != null && globalStats.totalUsers > 0 ? globalStats.totalParents / globalStats.totalUsers : 0.0),
      (LucideIcons.fileText, '${globalStats?.totalQsmCreated ?? '--'}', 'QSM créés', AppColors.info, 0.88),
    ];

    final maxActivity = activity.values.fold(1, (a, b) => a > b ? a : b);

    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Container(
          padding: const EdgeInsets.all(28),
          decoration: BoxDecoration(
            gradient: const LinearGradient(
              colors: [AppColors.primary, Color(0xFFBF4E07)],
              begin: Alignment.topLeft, end: Alignment.bottomRight,
            ),
            borderRadius: BorderRadius.circular(20),
          ),
          child: Row(
            children: [
              Expanded(child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('Bonjour Administrateur',
                      style: GoogleFonts.inter(fontSize: 20, fontWeight: FontWeight.w800, color: Colors.white)),
                  const SizedBox(height: 4),
                  Text('Gestion complète de la plateforme Skwilti',
                      style: GoogleFonts.inter(fontSize: 13, color: Colors.white.withOpacity(0.85))),
                  const SizedBox(height: 16),
                  _AdminRoleChip(),
                ],
              )),
              Container(
                width: 80, height: 80,
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.15), borderRadius: BorderRadius.circular(16),
                ),
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(16),
                  child: const Icon(LucideIcons.shield, color: Colors.white, size: 40),
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 20),
        // Graphe activité réelle
        Container(
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            color: Colors.white, borderRadius: BorderRadius.circular(16),
            border: Border.all(color: AppColors.border, width: 0.5),
            boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.04), blurRadius: 8, offset: const Offset(0, 2))],
          ),
          child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Text('Activité de la semaine',
                style: GoogleFonts.nunito(fontSize: 16, fontWeight: FontWeight.w700, color: AppColors.text)),
            const SizedBox(height: 16),
            if (!loaded)
              const Center(child: CircularProgressIndicator())
            else
              SizedBox(
                height: 150,
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    for (int i = 0; i < 7; i++) ...[
                      if (i > 0) const SizedBox(width: 8),
                      Expanded(child: Column(
                        mainAxisAlignment: MainAxisAlignment.end,
                        children: [
                          Text('${activity[i] ?? 0}', style: GoogleFonts.nunito(fontSize: 10, fontWeight: FontWeight.w800, color: AppColors.primary)),
                          const SizedBox(height: 4),
                          Container(
                            height: maxActivity > 0 ? 80 * ((activity[i] ?? 0) / maxActivity) : 4,
                            decoration: BoxDecoration(
                              gradient: const LinearGradient(
                                colors: [AppColors.primary, AppColors.primary2],
                                begin: Alignment.bottomCenter, end: Alignment.topCenter,
                              ),
                              borderRadius: const BorderRadius.vertical(top: Radius.circular(4)),
                            ),
                          ),
                          const SizedBox(height: 6),
                          Text(['Lu','Ma','Me','Je','Ve','Sa','Di'][i],
                              style: GoogleFonts.nunito(fontSize: 10, color: AppColors.textSub)),
                        ],
                      )),
                    ],
                  ],
                ),
              ),
          ]),
        ),
        const SizedBox(height: 20),
        // Grid des stats réelles
        if (loaded)
          GridView.count(
            crossAxisCount: 2, shrinkWrap: true, physics: const NeverScrollableScrollPhysics(),
            crossAxisSpacing: 10, mainAxisSpacing: 10, childAspectRatio: 1.6,
            children: stats.map((s) => Container(
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(14), border: Border.all(color: AppColors.border, width: 0.5)),
              child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                Row(children: [
                  Container(width: 30, height: 30, decoration: BoxDecoration(color: s.$4.withOpacity(0.12), borderRadius: BorderRadius.circular(8)),
                    child: Icon(s.$1, size: 15, color: s.$4)),
                  const Spacer(),
                  Text('', style: GoogleFonts.nunito(fontSize: 10, fontWeight: FontWeight.w700, color: AppColors.success)),
                ]),
                const Spacer(),
                Text(s.$2, style: GoogleFonts.nunito(fontSize: 22, fontWeight: FontWeight.w900, color: s.$4)),
                Text(s.$3, style: GoogleFonts.nunito(fontSize: 11, color: AppColors.textSub)),
                const SizedBox(height: 6),
                ClipRRect(borderRadius: BorderRadius.circular(3),
                  child: LinearProgressIndicator(value: s.$5.clamp(0.0, 1.0), minHeight: 4, backgroundColor: AppColors.border, valueColor: AlwaysStoppedAnimation(s.$4))),
              ]),
            )).toList(),
          )
        else
          const Center(child: Padding(padding: EdgeInsets.all(24), child: CircularProgressIndicator())),
        const SizedBox(height: 20),
        // Diagramme abonnements réel
        if (globalStats != null)
          Center(child: AdminSubscriptionChart(
            freeUsers: globalStats.subscriptionCounts['free'] ?? 0,
            premiumUsers: (globalStats.subscriptionCounts['premium'] ?? 0) + (globalStats.subscriptionCounts['basic'] ?? 0),
          )),
        const SizedBox(height: 20),
        AdminUsersTable(users: context.watch<AppState>().adminUsers),
      ]),
    );
  }
}

class _SubRow extends StatelessWidget {
  final String l; final int v; final Color c;
  const _SubRow(this.l, this.v, this.c);
  @override
  Widget build(BuildContext context) => Column(children: [
    Row(children: [
      Text(l, style: GoogleFonts.nunito(fontSize: 12, color: AppColors.text, fontWeight: FontWeight.w600)), const Spacer(),
      Text('$v%', style: GoogleFonts.nunito(fontSize: 12, fontWeight: FontWeight.w800, color: c)),
    ]),
    const SizedBox(height: 5),
    ClipRRect(borderRadius: BorderRadius.circular(3),
      child: LinearProgressIndicator(value: v / 100, minHeight: 6, backgroundColor: AppColors.border, valueColor: AlwaysStoppedAnimation(c))),
  ]);
}

class _UsersTab extends StatefulWidget {
  @override
  _UsersTabState createState() => _UsersTabState();
}

class _UsersTabState extends State<_UsersTab> {
  String _selectedFilter = 'Tous';

  List<Map<String, dynamic>> get _filteredUsers {
    final allUsers = context.read<AppState>().adminUsers;
    switch (_selectedFilter) {
      case 'Enseignants': return allUsers.where((u) => u['role'] == 'teacher').toList();
      case 'Étudiants':   return allUsers.where((u) => u['role'] == 'student').toList();
      case 'Parents':     return allUsers.where((u) => u['role'] == 'parent').toList();
      default:            return allUsers;
    }
  }

  @override
  Widget build(BuildContext context) {
    final filteredUsers = _filteredUsers;
    
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16).copyWith(bottom: 32),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const SizedBox(height: 24),
          // Hero Section
          Container(
            padding: const EdgeInsets.all(24),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [AppColors.primary, AppColors.primary.withOpacity(0.8)],
                begin: Alignment.topLeft, end: Alignment.bottomRight,
              ),
              borderRadius: BorderRadius.circular(20),
              boxShadow: [BoxShadow(color: AppColors.primary.withOpacity(0.2), blurRadius: 12, offset: const Offset(0, 4))],
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(children: [
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(color: Colors.white.withOpacity(0.2), borderRadius: BorderRadius.circular(12)),
                    child: const Icon(LucideIcons.users, size: 28, color: Colors.white),
                  ),
                  const SizedBox(width: 16),
                  Expanded(child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('Gestion des utilisateurs',
                          style: GoogleFonts.inter(fontSize: 20, fontWeight: FontWeight.w800, color: Colors.white)),
                      Text('${filteredUsers.length} affichés sur ${context.watch<AppState>().adminUsers.length} au total',
                          style: GoogleFonts.inter(fontSize: 14, color: Colors.white.withOpacity(0.9))),
                    ],
                  )),
                ]),
                const SizedBox(height: 20),
                Row(children: [
                  Expanded(child: _QuickUserStat(
                    label: 'Étudiants',
                    value: '${context.watch<AppState>().adminUsers.where((u) => u['role'] == 'student').length}',
                    icon: LucideIcons.graduationCap, color: Colors.white,
                  )),
                  const SizedBox(width: 12),
                  Expanded(child: _QuickUserStat(
                    label: 'Enseignants',
                    value: '${context.watch<AppState>().adminUsers.where((u) => u['role'] == 'teacher').length}',
                    icon: LucideIcons.bookOpen, color: Colors.white,
                  )),
                  const SizedBox(width: 12),
                  Expanded(child: _QuickUserStat(
                    label: 'Parents',
                    value: '${context.watch<AppState>().adminUsers.where((u) => u['role'] == 'parent').length}',
                    icon: LucideIcons.heart, color: Colors.white,
                  )),
                ]),
              ],
            ),
          ),
          const SizedBox(height: 24),
          
          // Filter Chips
          _SectionHeader('Filtrer par type'),
          const SizedBox(height: 12),
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: Row(
              children: [
                for (final f in ['Tous', 'Enseignants', 'Étudiants', 'Parents'])
                  GestureDetector(
                    onTap: () => setState(() => _selectedFilter = f),
                    child: Container(
                      margin: const EdgeInsets.only(right: 8),
                      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                      decoration: BoxDecoration(
                        color: f == _selectedFilter ? AppColors.primary : Colors.white,
                        borderRadius: BorderRadius.circular(20),
                        border: Border.all(color: f == _selectedFilter ? AppColors.primary : AppColors.border, width: 0.5),
                        boxShadow: [
                          if (f == _selectedFilter)
                            BoxShadow(
                              color: AppColors.primary.withOpacity(0.2),
                              blurRadius: 8,
                              offset: const Offset(0, 2),
                            ),
                        ],
                      ),
                      child: Text(
                        f,
                        style: GoogleFonts.inter(
                          fontSize: 12,
                          fontWeight: FontWeight.w700,
                          color: f == _selectedFilter ? Colors.white : AppColors.text,
                        ),
                      ),
                    ),
                  ),
              ],
            ),
          ),
          const SizedBox(height: 20),
          
          // Users Grid
          _SectionHeader('Liste des utilisateurs'),
          const SizedBox(height: 12),
          if (filteredUsers.isEmpty)
            Container(
              padding: const EdgeInsets.all(32),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: AppColors.border, width: 0.5),
              ),
              child: Column(
                children: [
                  Icon(
                    LucideIcons.users,
                    size: 48,
                    color: AppColors.textSub,
                  ),
                  const SizedBox(height: 16),
                  Text(
                    'Aucun utilisateur trouvé',
                    style: GoogleFonts.inter(
                      fontSize: 16,
                      fontWeight: FontWeight.w700,
                      color: AppColors.text,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Essayez de changer le filtre pour voir plus d\'utilisateurs',
                    style: GoogleFonts.inter(
                      fontSize: 12,
                      color: AppColors.textSub,
                    ),
                  ),
                ],
              ),
            )
          else
            GridView.builder(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: 2,
                crossAxisSpacing: 12,
                mainAxisSpacing: 12,
                childAspectRatio: 1.1,
              ),
              itemCount: filteredUsers.length,
              itemBuilder: (_, i) {
                final u = filteredUsers[i];
                final roleMap = {
                  'student': 'Étudiant',
                  'teacher': 'Enseignant',
                  'parent': 'Parent',
                  'admin': 'Admin',
                };
                final role = roleMap[u['role']] ?? 'Utilisateur';
                
                final firstName = u['first_name'] as String? ?? '';
                final lastName = u['last_name'] as String? ?? '';
                final fullName = ('$firstName $lastName').trim();
                final displayName = fullName.isNotEmpty ? fullName : (u['email'] as String? ?? 'Inconnu');
                final names = displayName.split(' ');
                final initials = names.length > 1 
                    ? '${names[0][0]}${names[1][0]}'.toUpperCase()
                    : displayName.isNotEmpty ? displayName.substring(0, 1).toUpperCase() : 'U';

                Color userColor = AppColors.primary;
                if (u['role'] == 'student') userColor = AppColors.success;
                if (u['role'] == 'parent') userColor = AppColors.warning;

                return _UserCard(
                  name: displayName,
                  initials: initials,
                  role: role,
                  color: userColor,
                  email: u['email'] as String? ?? 'N/A',
                  status: 'Actif', // Todo: add status to db if needed
                  qsmCount: 'N/A', // Not supported directly in profiles
                  score: 'N/A',    // Not supported directly in profiles
                  subscription: u['subscription'] == 'premium' ? 'Premium' : 'Gratuit',
                );
              },
            ),
        ],
      ),
    );
  }
}

// ── User Card ───────────────────────────────────────────────
class _UserCard extends StatelessWidget {
  final String name;
  final String initials;
  final String role;
  final Color color;
  final String email;
  final String status;
  final String qsmCount;
  final String score;
  final String subscription;

  const _UserCard({
    required this.name,
    required this.initials,
    required this.role,
    required this.color,
    required this.email,
    required this.status,
    required this.qsmCount,
    required this.score,
    required this.subscription,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.border, width: 0.5),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 40,
                height: 40,
                decoration: BoxDecoration(
                  color: color.withOpacity(0.15),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Center(
                  child: Text(
                    initials,
                    style: GoogleFonts.inter(
                      fontSize: 14,
                      fontWeight: FontWeight.w900,
                      color: color,
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      name,
                      style: GoogleFonts.inter(
                        fontSize: 14,
                        fontWeight: FontWeight.w700,
                        color: AppColors.text,
                      ),
                      overflow: TextOverflow.ellipsis,
                    ),
                    Text(
                      role,
                      style: GoogleFonts.inter(
                        fontSize: 10,
                        color: AppColors.textSub,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
            decoration: BoxDecoration(
              color: status == 'Actif' ? AppColors.success.withOpacity(0.1) : AppColors.error.withOpacity(0.1),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  width: 6,
                  height: 6,
                  decoration: BoxDecoration(
                    color: status == 'Actif' ? AppColors.success : AppColors.error,
                    shape: BoxShape.circle,
                  ),
                ),
                const SizedBox(width: 4),
                Text(
                  status,
                  style: GoogleFonts.inter(
                    fontSize: 9,
                    fontWeight: FontWeight.w700,
                    color: status == 'Actif' ? AppColors.success : AppColors.error,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 8),
          // Subscription Badge
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
            decoration: BoxDecoration(
              color: subscription == 'Premium' 
                ? AppColors.primary.withOpacity(0.1) 
                : AppColors.warning.withOpacity(0.1),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(
                color: subscription == 'Premium' 
                  ? AppColors.primary.withOpacity(0.3) 
                  : AppColors.warning.withOpacity(0.3),
                width: 0.5,
              ),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(
                  subscription == 'Premium' ? LucideIcons.crown : LucideIcons.gift,
                  size: 10,
                  color: subscription == 'Premium' ? AppColors.primary : AppColors.warning,
                ),
                const SizedBox(width: 4),
                Text(
                  subscription,
                  style: GoogleFonts.inter(
                    fontSize: 9,
                    fontWeight: FontWeight.w800,
                    color: subscription == 'Premium' ? AppColors.primary : AppColors.warning,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 8),
          if (qsmCount != 'N/A') ...[
            Row(
              children: [
                Icon(LucideIcons.fileText, size: 12, color: AppColors.textSub),
                const SizedBox(width: 4),
                Text(
                  qsmCount,
                  style: GoogleFonts.inter(
                    fontSize: 10,
                    fontWeight: FontWeight.w600,
                    color: AppColors.textSub,
                  ),
                ),
                if (score != 'N/A') ...[
                  const Spacer(),
                  Text(
                    score,
                    style: GoogleFonts.inter(
                      fontSize: 10,
                      fontWeight: FontWeight.w700,
                      color: AppColors.primary,
                    ),
                  ),
                ],
              ],
            ),
          ],
        ],
      ),
    );
  }
}

class _CoursesTab extends StatefulWidget {
  @override
  State<_CoursesTab> createState() => _CoursesTabState();
}

class _CoursesTabState extends State<_CoursesTab> {
  int _selectedFiliere = 0;
  int _selectedSubject = 0;
  final Set<int> _expandedSemesters = {};

  static const _filieres = [
    'Tronc Commun',
    '1ère Année Baccalauréat',
    '2ème Année Baccalauréat',
  ];

  static const _subjects = [
    (icon: LucideIcons.calculator, label: 'Maths'),
    (icon: LucideIcons.atom, label: 'Physique-Chimie'),
    (icon: LucideIcons.microscope, label: 'Sciences Vie'),
    (icon: LucideIcons.bookOpen, label: 'Français'),
    (icon: LucideIcons.globe, label: 'Anglais'),
    (icon: LucideIcons.history, label: 'Histoire-Géo'),
  ];

  // Aliases: what teachers might store vs what the tab label says
  static const _subjectAliases = <String, List<String>>{
    'Sciences Vie': ['Sciences Vie', 'SVT', 'Biologie', 'sciences vie', 'svt'],
    'Physique-Chimie': ['Physique-Chimie', 'Physique', 'Chimie', 'physique-chimie', 'physique chimie'],
    'Maths': ['Maths', 'Mathématiques', 'maths', 'mathématiques'],
    'Français': ['Français', 'Francais', 'français', 'francais'],
    'Anglais': ['Anglais', 'anglais'],
    'Histoire-Géo': ['Histoire-Géo', 'Histoire', 'Géographie', 'histoire-géo'],
  };

  /// Builds semesters dynamically from real Supabase courses
  List<Map<String, dynamic>> get _currentSemesters {
    final filiere = _filieres[_selectedFiliere];
    final subject = _subjects[_selectedSubject].label;
    final aliases = _subjectAliases[subject] ?? [subject];

    final allCourses = context.read<AppState>().adminCourses;

    // Filter by selected filiere (flexible: null/empty = show in all) and subject (with aliases)
    final filtered = allCourses.where((c) {
      final courseFiliere = (c['filiere'] as String? ?? '').trim();
      final courseSubject = (c['subject'] as String? ?? '').trim();
      // Filiere: match or ignore if empty
      final filiereMatch = courseFiliere.isEmpty || courseFiliere == filiere;
      // Subject: match with aliases (case-insensitive)
      final subjectMatch = aliases.any((alias) =>
          courseSubject.toLowerCase() == alias.toLowerCase());
      return filiereMatch && subjectMatch;
    }).toList();

    // Group into Semestre 1 and Semestre 2
    final sem1Courses = filtered.where((c) {
      final desc = (c['description'] as String? ?? '').toLowerCase();
      final sem = (c['semester'] as String? ?? '').toLowerCase();
      return sem.contains('semestre 1') || sem.contains('semester 1') || desc.contains('semestre 1');
    }).toList();

    final sem2Courses = filtered.where((c) {
      final desc = (c['description'] as String? ?? '').toLowerCase();
      final sem = (c['semester'] as String? ?? '').toLowerCase();
      return sem.contains('semestre 2') || sem.contains('semester 2') || desc.contains('semestre 2');
    }).toList();

    // Default: if no semester tag found, put in semestre 1
    final untagged = filtered.where((c) {
      final desc = (c['description'] as String? ?? '').toLowerCase();
      final sem = (c['semester'] as String? ?? '').toLowerCase();
      return !sem.contains('semestre') && !sem.contains('semester') &&
             !desc.contains('semestre 1') && !desc.contains('semestre 2');
    }).toList();

    final allSem1 = [...sem1Courses, ...untagged];

    return [
      {
        'title': 'Semestre 1',
        'count': allSem1.length,
        'courses': allSem1,
        'lessons': allSem1.map((c) => c['title'] as String? ?? 'Sans titre').toList(),
      },
      {
        'title': 'Semestre 2',
        'count': sem2Courses.length,
        'courses': sem2Courses,
        'lessons': sem2Courses.map((c) => c['title'] as String? ?? 'Sans titre').toList(),
      },
    ];
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // ─── Titre Bibliothèque ────────────────────────────────────
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 8, 16, 0),
          child: Text(
            'Bibliothèque',
            style: GoogleFonts.inter(
              fontSize: 26,
              fontWeight: FontWeight.w700,
              color: AppColors.text,
            ),
          ),
        ),

        // ─── Espace entre titre et filière tabs ─────────────────────
        const SizedBox(height: 20),

        // ─── Filière tabs ───────────────────────────────────────────
        _buildFiliereTabs(),
        const SizedBox(height: 14),

        // ─── Subject chips ────────────────────────────────────────
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16),
          child: _buildSubjectChips(),
        ),
        const SizedBox(height: 24),

        // ─── Admin actions ──────────────────────────────────────────
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16),
          child: Row(
            children: [
              Expanded(
                child: ElevatedButton.icon(
                  onPressed: _showAddCourseDialog,
                  icon: const Icon(LucideIcons.plus, size: 18),
                  label: Text('Ajouter un cours', style: GoogleFonts.inter(fontWeight: FontWeight.w700)),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.primary,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: OutlinedButton.icon(
                  onPressed: _showManageDialog,
                  icon: const Icon(LucideIcons.settings, size: 18),
                  label: Text('Gérer', style: GoogleFonts.inter(fontWeight: FontWeight.w700)),
                  style: OutlinedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                  ),
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 20),

        // ─── Accordion + dossiers ─────────────────────────────────
        Expanded(
          child: ListView.separated(
            padding: const EdgeInsets.symmetric(horizontal: 16).copyWith(bottom: 32),
            itemCount: _currentSemesters.length,
            separatorBuilder: (_, __) => const SizedBox(height: 10),
            itemBuilder: (context, i) {
              final sem = _currentSemesters[i];
              final expanded = _expandedSemesters.contains(i);
              final lessons = (sem['lessons'] as List).cast<String>();
              return _AdminSemesterSection(
                title: sem['title'] as String,
                lessonCount: sem['count'] as int,
                lessons: lessons,
                isExpanded: expanded,
                onToggle: () => setState(() {
                  expanded ? _expandedSemesters.remove(i) : _expandedSemesters.add(i);
                }),
              );
            },
          ),
        ),
      ],
    );
  }

  Widget _buildFiliereTabs() {
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
      child: Row(
        children: List.generate(_filieres.length, (i) {
          final active = i == _selectedFiliere;
          return GestureDetector(
            onTap: () => setState(() {
              _selectedFiliere = i;
              _expandedSemesters.clear();
            }),
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 200),
              margin: const EdgeInsets.only(right: 8),
              padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 9),
              decoration: BoxDecoration(
                color: active ? AppColors.primary : const Color(0xFFEEEEEE),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Text(
                _filieres[i],
                style: GoogleFonts.inter(
                  fontSize: 13,
                  fontWeight: FontWeight.w700,
                  color: active ? Colors.white : const Color(0xFF888888),
                ),
              ),
            ),
          );
        }),
      ),
    );
  }

  Widget _buildSubjectChips() {
    return Wrap(
      spacing: 8,
      runSpacing: 8,
      children: List.generate(_subjects.length, (i) {
        final active = i == _selectedSubject;
        final subject = _subjects[i];
        return GestureDetector(
          onTap: () => setState(() {
            _selectedSubject = i;
            _expandedSemesters.clear();
          }),
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 200),
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
            decoration: BoxDecoration(
              color: active ? AppColors.primary : const Color(0xFFEEEEEE),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(
                color: active ? AppColors.primary : const Color(0xFFDDDDDD),
                width: 0.5,
              ),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(subject.icon, size: 16,
                    color: active ? Colors.white : const Color(0xFF888888)),
                const SizedBox(width: 7),
                Text(
                  subject.label,
                  style: GoogleFonts.inter(
                    fontSize: 13,
                    fontWeight: FontWeight.w700,
                    color: active ? Colors.white : const Color(0xFF888888),
                  ),
                ),
              ],
            ),
          ),
        );
      }),
    );
  }

  void _showAddCourseDialog() {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => LessonUploadScreen(
          filiere: _filieres[_selectedFiliere],
          subject: _subjects[_selectedSubject].label,
          semester: 'Semestre 1',
        ),
      ),
    );
  }

  void _showManageDialog() {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => AdminCourseManagementScreen(
          filiere: _filieres[_selectedFiliere],
          subject: _subjects[_selectedSubject].label,
        ),
      ),
    );
  }

  void _showEditDialog(String semesterTitle) {
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        title: Text('Modifier', style: GoogleFonts.inter(fontWeight: FontWeight.w700)),
        content: Text('Modifier le semestre: $semesterTitle', style: GoogleFonts.inter()),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text('Annuler', style: GoogleFonts.inter()),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(context);
              // Edit logic
            },
            child: Text('Modifier', style: GoogleFonts.inter(fontWeight: FontWeight.w700)),
          ),
        ],
      ),
    );
  }

  void _showDeleteDialog(String semesterTitle) {
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        title: Text('Supprimer', style: GoogleFonts.inter(fontWeight: FontWeight.w700)),
        content: Text('Supprimer le semestre: $semesterTitle ?', style: GoogleFonts.inter()),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text('Annuler', style: GoogleFonts.inter()),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(context);
              // Delete logic
            },
            child: Text('Supprimer', style: GoogleFonts.inter(fontWeight: FontWeight.w700)),
          ),
        ],
      ),
    );
  }
}

// ── Section semestre admin avec accordion + actions ─────────────────────
class _AdminSemesterSection extends StatelessWidget {
  final String title;
  final int lessonCount;
  final List<String> lessons;
  final bool isExpanded;
  final VoidCallback onToggle;

  const _AdminSemesterSection({
    required this.title,
    required this.lessonCount,
    required this.lessons,
    required this.isExpanded,
    required this.onToggle,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        border: Border.all(color: AppColors.border, width: 0.8),
        borderRadius: BorderRadius.circular(14),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // ── Header ──────────────────────────────────────────────
          InkWell(
            onTap: onToggle,
            borderRadius: BorderRadius.circular(14),
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
              child: Row(
                children: [
                  Text(
                    title,
                    style: GoogleFonts.inter(
                      fontSize: 16,
                      fontWeight: FontWeight.w700,
                      color: AppColors.text,
                    ),
                  ),
                  const Spacer(),
                  Text(
                    '$lessonCount leçons',
                    style: GoogleFonts.inter(
                      fontSize: 13,
                      fontWeight: FontWeight.w600,
                      color: AppColors.textSub,
                    ),
                  ),
                  const SizedBox(width: 6),
                  AnimatedRotation(
                    turns: isExpanded ? 0.5 : 0,
                    duration: const Duration(milliseconds: 220),
                    child: Icon(LucideIcons.chevronDown,
                        size: 18, color: AppColors.textSub),
                  ),
                ],
              ),
            ),
          ),

          // Buttons removed

          // ─── Leçons list ─────────────────────────────────────
          AnimatedSize(
            duration: const Duration(milliseconds: 280),
            curve: Curves.easeInOut,
            child: isExpanded && lessons.isNotEmpty
                ? Padding(
                    padding: const EdgeInsets.fromLTRB(12, 0, 12, 16),
                    child: GridView.builder(
                      shrinkWrap: true,
                      physics: const NeverScrollableScrollPhysics(),
                      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                        crossAxisCount: 2,
                        mainAxisSpacing: 12,
                        crossAxisSpacing: 12,
                        childAspectRatio: 1.0,
                      ),
                      itemCount: lessons.length,
                      itemBuilder: (context, i) => _AdminLessonCard(title: lessons[i]),
                    ),
                  )
                : const SizedBox.shrink(),
          ),
        ],
      ),
    );
  }
}

// ── Carte leçon admin ─────────────────────────────────────────────────────
class _AdminLessonCard extends StatelessWidget {
  final String title;
  const _AdminLessonCard({required this.title});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () {/* View lesson details */},
      child: Container(
        decoration: BoxDecoration(
          color: const Color(0xFFF5F5F5),
          borderRadius: BorderRadius.circular(14),
        ),
        child: Column(
          children: [
            // ── Image leçon ──────────────────────────────────
            Expanded(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(8, 10, 8, 0),
                child: Image.asset(
                  'assets/images/image.png',
                  fit: BoxFit.contain,
                ),
              ),
            ),

            // ── Label titre ───────────────────────────────────────
            Container(
              width: double.infinity,
              margin: const EdgeInsets.all(8),
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
              decoration: BoxDecoration(
                color: const Color(0xFF1C1C1C),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Text(
                title,
                textAlign: TextAlign.center,
                maxLines: 3,
                overflow: TextOverflow.ellipsis,
                style: GoogleFonts.inter(
                  fontSize: 12,
                  fontWeight: FontWeight.w700,
                  color: Colors.white,
                  height: 1.35,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ── Admin Role Chip ─────────────────────────────────────────
class _AdminRoleChip extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.2),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Text(
        'Administrateur',
        style: GoogleFonts.inter(
          fontSize: 11,
          fontWeight: FontWeight.w700,
          color: Colors.white,
        ),
      ),
    );
  }
}

class _SettingsTab extends StatelessWidget {
  final User? user;
  const _SettingsTab({this.user});

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // ─── Header Paramètres ───────────────────────────────────────
          Container(
            margin: const EdgeInsets.only(bottom: 24),
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              gradient: const LinearGradient(
                colors: [AppColors.primary, Color(0xFFBF4E07)],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              borderRadius: BorderRadius.circular(16),
              boxShadow: [
                BoxShadow(
                  color: AppColors.primary.withOpacity(0.15),
                  blurRadius: 20,
                  offset: const Offset(0, 8),
                ),
              ],
            ),
            child: Row(
              children: [
                Container(
                  width: 50,
                  height: 50,
                  decoration: BoxDecoration(
                    color: Colors.white.withOpacity(0.2),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: const Icon(
                    LucideIcons.settings,
                    color: Colors.white,
                    size: 24,
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Paramètres Système',
                        style: GoogleFonts.inter(
                          fontSize: 18,
                          fontWeight: FontWeight.w700,
                          color: Colors.white,
                        ),
                      ),
                      Text(
                        'Gestion complète de la plateforme',
                        style: GoogleFonts.inter(
                          fontSize: 13,
                          fontWeight: FontWeight.w500,
                          color: Colors.white.withOpacity(0.85),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),

          // ─── Sections de paramètres ─────────────────────────────────────
          _SettingsSection(
            title: 'Gestion des Utilisateurs',
            icon: LucideIcons.users,
            color: AppColors.primary,
            items: [
              _SettingsItem(
                icon: LucideIcons.userPlus,
                title: 'Ajouter un utilisateur',
                subtitle: 'Créer un nouveau compte',
                onTap: () {},
              ),
              _SettingsItem(
                icon: LucideIcons.users,
                title: 'Gérer les utilisateurs',
                subtitle: 'Liste complète des utilisateurs',
                onTap: () {},
              ),
              _SettingsItem(
                icon: LucideIcons.shield,
                title: 'Permissions & Rôles',
                subtitle: 'Configurer les accès',
                onTap: () {},
              ),
            ],
          ),

          _SettingsSection(
            title: 'Contenu & Cours',
            icon: LucideIcons.bookOpen,
            color: AppColors.success,
            items: [
              _SettingsItem(
                icon: LucideIcons.upload,
                title: 'Importer des cours',
                subtitle: 'Ajouter du contenu en masse',
                onTap: () {},
              ),
              _SettingsItem(
                icon: LucideIcons.fileText,
                title: 'Gérer la bibliothèque',
                subtitle: 'Organiser tous les cours',
                onTap: () {},
              ),
              _SettingsItem(
                icon: LucideIcons.tags,
                title: 'Catégories & Mots-clés',
                subtitle: 'Classifier le contenu',
                onTap: () {},
              ),
            ],
          ),

          _SettingsSection(
            title: 'Système & Sécurité',
            icon: LucideIcons.shieldCheck,
            color: AppColors.info,
            items: [
              _SettingsItem(
                icon: LucideIcons.bell,
                title: 'Notifications globales',
                subtitle: 'Envoyer des annonces',
                onTap: () {},
              ),
              _SettingsItem(
                icon: LucideIcons.database,
                title: 'Sauvegarde des données',
                subtitle: 'Backup automatique',
                onTap: () {},
              ),
              _SettingsItem(
                icon: LucideIcons.lock,
                title: 'Sécurité & Authentification',
                subtitle: 'Protéger la plateforme',
                onTap: () {},
              ),
            ],
          ),

          _SettingsSection(
            title: 'Rapports & Analytics',
            icon: LucideIcons.barChart2,
            color: const Color(0xFF9B59B6),
            items: [
              _SettingsItem(
                icon: LucideIcons.trendingUp,
                title: 'Statistiques d\'utilisation',
                subtitle: 'Vue d\'ensemble complète',
                onTap: () {},
              ),
              _SettingsItem(
                icon: LucideIcons.fileBarChart,
                title: 'Rapports avancés',
                subtitle: 'Export et analyse',
                onTap: () {},
              ),
              _SettingsItem(
                icon: LucideIcons.activity,
                title: 'Monitoring système',
                subtitle: 'Performance en temps réel',
                onTap: () {},
              ),
            ],
          ),

          // ─── Action de déconnexion ───────────────────────────────────────
          Container(
            margin: const EdgeInsets.only(top: 24),
            child: ElevatedButton.icon(
              onPressed: () => context.read<AppState>().logout(),
              icon: const Icon(LucideIcons.logOut, size: 18),
              label: Text('Déconnexion', style: GoogleFonts.inter(fontWeight: FontWeight.w700)),
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.error,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// ── Widget section paramètres ───────────────────────────────────────
class _SettingsSection extends StatelessWidget {
  final String title;
  final IconData icon;
  final Color color;
  final List<_SettingsItem> items;

  const _SettingsSection({
    required this.title,
    required this.icon,
    required this.color,
    required this.items,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 15,
            offset: const Offset(0, 5),
          ),
        ],
        border: Border.all(
          color: AppColors.border.withOpacity(0.3),
          width: 1,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header de section
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: color.withOpacity(0.1),
              borderRadius: const BorderRadius.only(
                topLeft: Radius.circular(16),
                topRight: Radius.circular(16),
              ),
            ),
            child: Row(
              children: [
                Container(
                  width: 40,
                  height: 40,
                  decoration: BoxDecoration(
                    color: color.withOpacity(0.15),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Icon(icon, color: color, size: 20),
                ),
                const SizedBox(width: 12),
                Text(
                  title,
                  style: GoogleFonts.inter(
                    fontSize: 16,
                    fontWeight: FontWeight.w700,
                    color: AppColors.text,
                  ),
                ),
              ],
            ),
          ),
          // Items de la section
          ...items.map((item) => _SettingsItemTile(item: item)),
        ],
      ),
    );
  }
}

// ── Widget item paramètres ───────────────────────────────────────────
class _SettingsItem {
  final IconData icon;
  final String title;
  final String subtitle;
  final VoidCallback onTap;

  const _SettingsItem({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.onTap,
  });
}

class _SettingsItemTile extends StatelessWidget {
  final _SettingsItem item;

  const _SettingsItemTile({required this.item});

  @override
  Widget build(BuildContext context) {
    return ListTile(
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
      leading: Container(
        width: 38,
        height: 38,
        decoration: BoxDecoration(
          color: AppColors.background,
          borderRadius: BorderRadius.circular(10),
        ),
        child: Icon(item.icon, size: 18, color: AppColors.textSub),
      ),
      title: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            item.title,
            style: GoogleFonts.inter(
              fontSize: 14,
              fontWeight: FontWeight.w600,
              color: AppColors.text,
            ),
          ),
          Text(
            item.subtitle,
            style: GoogleFonts.inter(
              fontSize: 12,
              fontWeight: FontWeight.w500,
              color: AppColors.textSub,
            ),
          ),
        ],
      ),
      trailing: const Icon(LucideIcons.chevronRight, size: 16, color: AppColors.textSub),
      onTap: item.onTap,
    );
  }
}

// ── Section Header ─────────────────────────────────────────────
class _SectionHeader extends StatelessWidget {
  final String title;
  const _SectionHeader(this.title);

  @override
  Widget build(BuildContext context) {
    return Text(
      title,
      style: GoogleFonts.inter(
        fontSize: 18,
        fontWeight: FontWeight.w700,
        color: AppColors.text,
      ),
    );
  }
}

// ── Quick User Stat ───────────────────────────────────────────
class _QuickUserStat extends StatelessWidget {
  final String label;
  final String value;
  final IconData icon;
  final Color color;

  const _QuickUserStat({
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
        color: color.withOpacity(0.15),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: color.withOpacity(0.3), width: 1),
      ),
      child: Row(
        children: [
          Icon(icon, size: 16, color: color),
          const SizedBox(width: 8),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  value,
                  style: GoogleFonts.inter(
                    fontSize: 16,
                    fontWeight: FontWeight.w800,
                    color: color,
                  ),
                ),
                Text(
                  label,
                  style: GoogleFonts.inter(
                    fontSize: 10,
                    color: color.withOpacity(0.8),
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

class _Label extends StatelessWidget {
  final String t;
  const _Label(this.t);
  @override
  Widget build(BuildContext context) => Text(t, style: GoogleFonts.nunito(fontSize: 14, fontWeight: FontWeight.w800, color: AppColors.text));
}
