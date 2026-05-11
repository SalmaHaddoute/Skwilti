import 'package:flutter/material.dart';
import 'package:lucide_icons/lucide_icons.dart';
import 'package:provider/provider.dart';
import 'package:google_fonts/google_fonts.dart';
import '../theme/app_theme.dart';
import '../services/app_state.dart';
import '../models/user.dart';
import '../widgets/skwilti_nav.dart';
import '../widgets/dashboard_widgets.dart';
import '../widgets/parent_subject_progress.dart';
import '../widgets/recent_grade_card.dart';
import '../widgets/parent_achievement_cards.dart';
import 'profile_screen.dart';
import 'conversation_screen.dart';

class ParentDashboard extends StatefulWidget {
  const ParentDashboard({super.key});
  @override
  State<ParentDashboard> createState() => _ParentDashboardState();
}

class _ParentDashboardState extends State<ParentDashboard> {
  int _idx = 0;
  static const _nav = [
    SkwNavItem(icon: LucideIcons.home, label: 'Accueil'),
    SkwNavItem(icon: LucideIcons.barChart2, label: 'Stats'),
    SkwNavItem(icon: LucideIcons.userPlus, label: 'Lier'),
    SkwNavItem(icon: LucideIcons.messageSquare, label: 'Contact'),
  ];

  @override
  Widget build(BuildContext context) {
    final user = context.watch<AppState>().currentUser;
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: SkwiltiTopNav(
        title: _idx == 0 ? 'Skwilti' : _idx == 1 ? 'Statistiques' : _idx == 2 ? 'Lier un enfant' : 'Contact',
        showLogo: _idx == 0,
        showNotifications: true,
        onProfileTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const ProfileScreen())),
      ),
      body: IndexedStack(index: _idx, children: [
        _HomeTab(user: user),
        _StatsTab(),
        const _LinkChildTab(),
        _ContactTab(),
      ]),
      bottomNavigationBar: SkwiltiBottomNav(currentIndex: _idx, onTap: (i) => setState(() => _idx = i), items: _nav),
    );
  }
}

class _HomeTab extends StatefulWidget {
  final User? user;
  const _HomeTab({this.user});
  @override
  State<_HomeTab> createState() => _HomeTabState();
}

class _HomeTabState extends State<_HomeTab> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<AppState>().loadChildData();
    });
  }

  @override
  Widget build(BuildContext context) {
    final state   = context.watch<AppState>();
    final child   = state.childProfile;
    final sessions = state.childSessions;
    final loaded  = state.childDataLoaded;

    final childName = child != null
        ? '${child['first_name'] ?? ''} ${child['last_name'] ?? ''}'.trim()
        : null;

    final scores = sessions
        .where((s) => s['total_questions'] != null && (s['total_questions'] as int) > 0)
        .map<int>((s) => ((s['score'] as int? ?? 0) * 100 ~/ (s['total_questions'] as int)))
        .toList();
    final avg = scores.isNotEmpty ? scores.reduce((a, b) => a + b) ~/ scores.length : 0;

    return SingleChildScrollView(
      padding: const EdgeInsets.all(16).copyWith(bottom: 32),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
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
                    Text('Bonjour ${widget.user?.firstName ?? ''} ',
                        style: GoogleFonts.inter(fontSize: 20, fontWeight: FontWeight.w800, color: Colors.white)),
                    const SizedBox(height: 4),
                    Text(childName != null ? 'Suivi de $childName' : 'Aucun enfant lié',
                        style: GoogleFonts.inter(fontSize: 13, color: Colors.white.withOpacity(0.85))),
                    const SizedBox(height: 16),
                    _ParentRoleChip(),
                  ],
                )),
                Container(
                  width: 80, height: 80,
                  decoration: BoxDecoration(color: Colors.white.withOpacity(0.15), borderRadius: BorderRadius.circular(16)),
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(16),
                    child: Image.asset('assets/images/parent-illustration.webp',
                      width: 80, height: 80, fit: BoxFit.cover,
                      errorBuilder: (_, __, ___) => const Icon(LucideIcons.users, color: Colors.white, size: 40)),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),

          if (!loaded)
            const Center(child: Padding(padding: EdgeInsets.all(32), child: CircularProgressIndicator()))
          else if (child == null)
            Container(
              padding: const EdgeInsets.all(24),
              decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: AppColors.border, width: 0.5)),
              child: Column(children: [
                Icon(LucideIcons.userX, size: 40, color: AppColors.textSub),
                const SizedBox(height: 12),
                Text('Aucun enfant lié à ce compte',
                    style: GoogleFonts.inter(fontSize: 14, fontWeight: FontWeight.w600, color: AppColors.text)),
                const SizedBox(height: 4),
                Text('Contactez l\'administration pour lier le compte de votre enfant.',
                    style: GoogleFonts.inter(fontSize: 12, color: AppColors.textSub), textAlign: TextAlign.center),
              ]),
            )
          else ...[
            Row(
              children: [
                Expanded(child: _StatCard(
                  icon: LucideIcons.trendingUp, title: 'Performance',
                  value: scores.isNotEmpty ? '$avg%' : '--',
                  color: AppColors.success, subtitle: 'Moyenne générale',
                )),
                const SizedBox(width: 12),
                Expanded(child: _StatCard(
                  icon: LucideIcons.checkCircle, title: 'QSM faits',
                  value: '${sessions.length}',
                  color: AppColors.info, subtitle: 'Total complétés',
                )),
              ],
            ),
            const SizedBox(height: 20),

            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(16),
                boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 15, offset: const Offset(0, 5))],
                border: Border.all(color: AppColors.border.withOpacity(0.3))),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(children: [
                    Container(width: 50, height: 50,
                      decoration: BoxDecoration(color: AppColors.warning.withOpacity(0.15), borderRadius: BorderRadius.circular(12)),
                      child: const Icon(LucideIcons.graduationCap, color: AppColors.warning, size: 24)),
                    const SizedBox(width: 16),
                    Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                      Text(childName ?? '',
                          style: GoogleFonts.inter(fontSize: 18, fontWeight: FontWeight.w700, color: AppColors.text)),
                      Text('Progression académique',
                          style: GoogleFonts.inter(fontSize: 13, color: AppColors.textSub)),
                    ])),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                      decoration: BoxDecoration(color: AppColors.warning.withOpacity(0.15), borderRadius: BorderRadius.circular(12)),
                      child: Text('$avg%',
                          style: GoogleFonts.inter(fontSize: 16, fontWeight: FontWeight.w700, color: AppColors.warning))),
                  ]),
                  const SizedBox(height: 16),
                  ClipRRect(borderRadius: BorderRadius.circular(4),
                    child: LinearProgressIndicator(
                      value: avg / 100, minHeight: 8, backgroundColor: AppColors.border,
                      valueColor: const AlwaysStoppedAnimation(AppColors.warning))),
                ],
              ),
            ),
            const SizedBox(height: 20),

            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(16),
                boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 15, offset: const Offset(0, 5))],
                border: Border.all(color: AppColors.border.withOpacity(0.3))),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(children: [
                    Text('Activités récentes',
                        style: GoogleFonts.inter(fontSize: 18, fontWeight: FontWeight.w700, color: AppColors.text)),
                    const Spacer(),
                    Text('Voir tout', style: GoogleFonts.inter(fontSize: 13, fontWeight: FontWeight.w600, color: AppColors.primary)),
                  ]),
                  const SizedBox(height: 16),
                  if (sessions.isEmpty)
                    Text('Aucune activité encore.', style: GoogleFonts.inter(fontSize: 13, color: AppColors.textSub))
                  else
                    ...sessions.take(3).map((s) {
                      final total = (s['total_questions'] as int? ?? 0);
                      final score = (s['score'] as int? ?? 0);
                      final pct   = total > 0 ? (score * 100 ~/ total) : 0;
                      final title = (s['courses'] as Map?)?['title'] as String? ?? 'QSM';
                      final dt    = s['completed_at'] != null ? DateTime.tryParse(s['completed_at']) : null;
                      final dateStr = dt != null ? '${dt.day}/${dt.month}' : '';
                      return _ActivityItem(
                        icon: LucideIcons.fileText, title: title,
                        subtitle: 'Score obtenu', value: '$pct%',
                        color: pct >= 80 ? AppColors.success : pct >= 60 ? AppColors.primary : AppColors.warning,
                        time: dateStr,
                      );
                    }),
                ],
              ),
            ),
          ],
        ],
      ),
    );
  }
}

// ── Widget carte statistique ───────────────────────────────────────
class _StatCard extends StatelessWidget {
  final IconData icon;
  final String title;
  final String value;
  final String subtitle;
  final Color color;

  const _StatCard({
    required this.icon,
    required this.title,
    required this.value,
    required this.subtitle,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
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
          Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              color: color.withOpacity(0.15),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Icon(icon, color: color, size: 20),
          ),
          const SizedBox(height: 12),
          Text(
            value,
            style: GoogleFonts.inter(
              fontSize: 24,
              fontWeight: FontWeight.w800,
              color: color,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            title,
            style: GoogleFonts.inter(
              fontSize: 13,
              fontWeight: FontWeight.w600,
              color: AppColors.text,
            ),
          ),
          Text(
            subtitle,
            style: GoogleFonts.inter(
              fontSize: 11,
              fontWeight: FontWeight.w500,
              color: AppColors.textSub,
            ),
          ),
        ],
      ),
    );
  }
}

// ── Widget item activité ───────────────────────────────────────────
class _ActivityItem extends StatelessWidget {
  final IconData icon;
  final String title;
  final String subtitle;
  final String value;
  final Color color;
  final String time;

  const _ActivityItem({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.value,
    required this.color,
    required this.time,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
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
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: GoogleFonts.inter(
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                    color: AppColors.text,
                  ),
                ),
                Text(
                  subtitle,
                  style: GoogleFonts.inter(
                    fontSize: 12,
                    fontWeight: FontWeight.w500,
                    color: AppColors.textSub,
                  ),
                ),
              ],
            ),
          ),
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text(
                value,
                style: GoogleFonts.inter(
                  fontSize: 14,
                  fontWeight: FontWeight.w700,
                  color: color,
                ),
              ),
              Text(
                time,
                style: GoogleFonts.inter(
                  fontSize: 11,
                  fontWeight: FontWeight.w500,
                  color: AppColors.textSub,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

// ── Widget chip rôle parent ───────────────────────────────────────────
class _ParentRoleChip extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.2),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: Colors.white.withOpacity(0.3),
          width: 1,
        ),
      ),
      child: Text(
        'Parent',
        style: GoogleFonts.inter(
          fontSize: 12,
          fontWeight: FontWeight.w600,
          color: Colors.white,
        ),
      ),
    );
  }
}

class _StatBox extends StatelessWidget {
  final String v, l; final Color c;
  const _StatBox(this.v, this.l, this.c);
  @override
  Widget build(BuildContext context) => Expanded(child: Container(
    padding: const EdgeInsets.all(12),
    decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(12), border: Border.all(color: AppColors.border, width: 0.5)),
    child: Column(children: [
      Text(v, style: GoogleFonts.nunito(fontSize: 20, fontWeight: FontWeight.w900, color: c)),
      Text(l, style: GoogleFonts.nunito(fontSize: 10, color: AppColors.textSub, fontWeight: FontWeight.w600)),
    ]),
  ));
}

class _NoteTile extends StatelessWidget {
  final String title, date; final int score;
  const _NoteTile({required this.title, required this.score, required this.date});
  Color get _c => score >= 80 ? AppColors.success : score >= 60 ? AppColors.primary : AppColors.error;
  @override
  Widget build(BuildContext context) => Container(
    margin: const EdgeInsets.only(bottom: 8),
    padding: const EdgeInsets.all(12),
    decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(12), border: Border.all(color: AppColors.border, width: 0.5)),
    child: Row(children: [
      Container(width: 40, height: 40, decoration: BoxDecoration(color: _c.withOpacity(0.1), borderRadius: BorderRadius.circular(10)),
        child: Icon(LucideIcons.fileText, size: 20, color: _c)),
      const SizedBox(width: 12),
      Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Text(title, style: GoogleFonts.nunito(fontSize: 13, fontWeight: FontWeight.w700, color: AppColors.text)),
        Text(date, style: GoogleFonts.nunito(fontSize: 11, color: AppColors.textSub)),
      ])),
      Text('$score%', style: GoogleFonts.nunito(fontSize: 20, fontWeight: FontWeight.w900, color: _c)),
    ]),
  );
}

class _StatsTab extends StatefulWidget {
  @override
  State<_StatsTab> createState() => _StatsTabState();
}

class _StatsTabState extends State<_StatsTab> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => context.read<AppState>().loadChildData());
  }

  @override
  Widget build(BuildContext context) {
    final sessions = context.watch<AppState>().childSessions;
    final loaded   = context.watch<AppState>().childDataLoaded;
    final dayLabels = ['Lu', 'Ma', 'Me', 'Je', 'Ve', 'Sa', 'Di'];

    // Scores des 7 derniers jours
    final Map<int, List<int>> byDay = {};
    for (final s in sessions) {
      if (s['completed_at'] != null && s['total_questions'] != null && (s['total_questions'] as int) > 0) {
        final dt   = DateTime.tryParse(s['completed_at']);
        if (dt != null) {
          final diff = DateTime.now().difference(dt).inDays;
          if (diff >= 0 && diff < 7) {
            final idx = 6 - diff;
            byDay[idx] = [...(byDay[idx] ?? []), ((s['score'] as int? ?? 0) * 100 ~/ (s['total_questions'] as int))];
          }
        }
      }
    }
    final scores = List.generate(7, (i) {
      final day = byDay[i] ?? [];
      return day.isNotEmpty ? day.reduce((a, b) => a + b) ~/ day.length : 0;
    });

    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        _SectionLabel('Évolution de la semaine'),
        const SizedBox(height: 10),
        Container(
          height: 130, padding: const EdgeInsets.fromLTRB(12, 12, 12, 4),
          decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(16), border: Border.all(color: AppColors.border, width: 0.5)),
          child: loaded
            ? Row(crossAxisAlignment: CrossAxisAlignment.end, children: [
                for (int i = 0; i < scores.length; i++) ...[
                  if (i > 0) const SizedBox(width: 8),
                  Expanded(child: Column(mainAxisAlignment: MainAxisAlignment.end, children: [
                    Text('${scores[i]}', style: GoogleFonts.nunito(fontSize: 9, fontWeight: FontWeight.w800, color: AppColors.green)),
                    const SizedBox(height: 3),
                    SizedBox(height: scores[i] > 0 ? 60 * (scores[i] / 100) : 2,
                      child: Container(decoration: BoxDecoration(color: AppColors.green, borderRadius: const BorderRadius.vertical(top: Radius.circular(4))))),
                    const SizedBox(height: 4),
                    Text(dayLabels[i], style: GoogleFonts.nunito(fontSize: 9, color: AppColors.textSub)),
                  ])),
                ],
              ])
            : const Center(child: CircularProgressIndicator()),
        ),
        const SizedBox(height: 16),
        Text('Activités récentes', style: GoogleFonts.nunito(fontSize: 14, fontWeight: FontWeight.w800, color: AppColors.text)),
        const SizedBox(height: 10),
        if (!loaded)
          const Center(child: CircularProgressIndicator())
        else if (sessions.isEmpty)
          Text('Aucune session pour l\'instant.', style: GoogleFonts.inter(fontSize: 13, color: AppColors.textSub))
        else
          ...sessions.take(5).map((s) {
            final total = (s['total_questions'] as int? ?? 0);
            final score = (s['score'] as int? ?? 0);
            final pct   = total > 0 ? (score * 100 ~/ total) : 0;
            final title = (s['courses'] as Map?)?['title'] as String? ?? 'QSM';
            final dt    = s['completed_at'] != null ? DateTime.tryParse(s['completed_at']) : null;
            final dateStr = dt != null ? '${dt.day}/${dt.month}/${dt.year}' : '';
            return _NoteTile(title: title, score: pct, date: dateStr);
          }),
      ]),
    );
  }
}

class _ContactTab extends StatefulWidget {
  @override
  State<_ContactTab> createState() => _ContactTabState();
}

class _ContactTabState extends State<_ContactTab> {
  final TextEditingController _searchController = TextEditingController();
  String _searchQuery = '';
  bool _showAllTeachers = false;
  List<Map<String, dynamic>> _allTeachers = [];
  bool _loadingAll = false;

  @override
  void initState() {
    super.initState();
    _searchController.addListener(() {
      setState(() => _searchQuery = _searchController.text.toLowerCase());
    });
  }

  Future<void> _loadAllTeachers() async {
    if (_allTeachers.isNotEmpty) return;
    setState(() => _loadingAll = true);
    final teachers = await context.read<AppState>().authService.fetchAllUsers(roleFilter: 'teacher');
    if (mounted) {
      setState(() {
        _allTeachers = teachers;
        _loadingAll = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final appState = context.watch<AppState>();
    final childTeachers = appState.childTeachers;
    final childDataLoaded = appState.childDataLoaded;

    final List<Map<String, dynamic>> displayedTeachers = _showAllTeachers 
        ? _allTeachers 
        : childTeachers.map((t) => {
            'id': t['teacher_id'],
            'first_name': t['teacher_name']?.split(' ').first ?? 'Enseignant',
            'last_name': t['teacher_name']?.split(' ').skip(1).join(' ') ?? '',
            'category': t['category'] ?? '',
          }).toList();

    final filteredTeachers = displayedTeachers.where((t) {
      final name = '${t['first_name'] ?? ''} ${t['last_name'] ?? ''}'.toLowerCase();
      final category = (t['category'] ?? '').toString().toLowerCase();
      return name.contains(_searchQuery) || category.contains(_searchQuery);
    }).toList();

    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        // Search Bar
        Container(
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(16),
            boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 10, offset: const Offset(0, 4))],
          ),
          child: TextField(
            controller: _searchController,
            decoration: InputDecoration(
              hintText: 'Rechercher un enseignant ou une matière...',
              hintStyle: GoogleFonts.inter(color: AppColors.textSub, fontSize: 14),
              prefixIcon: const Icon(LucideIcons.search, size: 20, color: AppColors.primary),
              border: InputBorder.none,
              contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
            ),
          ),
        ),
        const SizedBox(height: 16),

        // Filters
        Row(
          children: [
            _FilterChip(
              label: "Profs de l'enfant",
              isSelected: !_showAllTeachers,
              onTap: () => setState(() => _showAllTeachers = false),
            ),
            const SizedBox(width: 8),
            _FilterChip(
              label: "Tous les enseignants",
              isSelected: _showAllTeachers,
              onTap: () {
                setState(() => _showAllTeachers = true);
                _loadAllTeachers();
              },
            ),
          ],
        ),
        const SizedBox(height: 24),

        _SectionLabel(_showAllTeachers ? 'Annuaire des enseignants' : 'Enseignants de l\'enfant'),
        const SizedBox(height: 12),

        if (_showAllTeachers && _loadingAll)
          const Center(child: Padding(padding: EdgeInsets.all(40), child: CircularProgressIndicator()))
        else if (!_showAllTeachers && !childDataLoaded)
          const Center(child: Padding(padding: EdgeInsets.all(40), child: CircularProgressIndicator()))
        else if (filteredTeachers.isEmpty)
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(32),
            decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(16), border: Border.all(color: AppColors.border.withOpacity(0.5))),
            child: Column(children: [
              Icon(LucideIcons.users, size: 48, color: AppColors.textSub.withOpacity(0.3)),
              const SizedBox(height: 16),
              Text('Aucun enseignant trouvé', style: GoogleFonts.inter(fontSize: 15, color: AppColors.textSub, fontWeight: FontWeight.w600)),
              Text('Essayez une autre recherche', style: GoogleFonts.inter(fontSize: 13, color: AppColors.textSub.withOpacity(0.7))),
            ]),
          )
        else
          ...filteredTeachers.map((t) {
            final name = '${t['first_name'] ?? ''} ${t['last_name'] ?? ''}'.trim();
            final category = t['category'] ?? 'Enseignant';
            
            return Container(
              margin: const EdgeInsets.only(bottom: 12),
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: AppColors.border.withOpacity(0.5)),
                boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.02), blurRadius: 4, offset: const Offset(0, 2))],
              ),
              child: Row(children: [
                Container(
                  width: 48, height: 48,
                  decoration: BoxDecoration(color: AppColors.primaryLight, borderRadius: BorderRadius.circular(14)),
                  child: const Icon(LucideIcons.graduationCap, size: 24, color: AppColors.primary),
                ),
                const SizedBox(width: 14),
                Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                  Text(name.isEmpty ? 'Enseignant' : name, style: GoogleFonts.nunito(fontSize: 14, fontWeight: FontWeight.w700, color: AppColors.text)),
                  Text(category, style: GoogleFonts.nunito(fontSize: 12, color: AppColors.textSub, fontWeight: FontWeight.w600)),
                ])),
                GestureDetector(
                  onTap: () => Navigator.push(context, MaterialPageRoute(
                    builder: (_) => ConversationScreen(
                      teacherName: name.isEmpty ? 'Enseignant' : name,
                      subject: category,
                      teacherIcon: LucideIcons.messageSquare,
                    ),
                  )),
                  child: Container(
                    padding: const EdgeInsets.all(10),
                    decoration: BoxDecoration(color: AppColors.primaryLight, borderRadius: BorderRadius.circular(12)),
                    child: const Icon(LucideIcons.messageSquare, size: 20, color: AppColors.primary),
                  ),
                ),
              ]),
            );
          }),
      ]),
    );
  }
}

class _FilterChip extends StatelessWidget {
  final String label;
  final bool isSelected;
  final VoidCallback onTap;

  const _FilterChip({required this.label, required this.isSelected, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        decoration: BoxDecoration(
          color: isSelected ? AppColors.primary : Colors.white,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: isSelected ? AppColors.primary : AppColors.border),
        ),
        child: Text(
          label,
          style: GoogleFonts.inter(
            fontSize: 12,
            fontWeight: isSelected ? FontWeight.w700 : FontWeight.w600,
            color: isSelected ? Colors.white : AppColors.textSub,
          ),
        ),
      ),
    );
  }
}


class _LinkChildTab extends StatefulWidget {
  const _LinkChildTab();
  @override
  State<_LinkChildTab> createState() => _LinkChildTabState();
}

class _LinkChildTabState extends State<_LinkChildTab> {
  String? _selectedFiliereId;
  String? _selectedNiveauId;
  String _alphabetFilter = '';
  List<Map<String, dynamic>> _students = [];
  List<Map<String, dynamic>> _filteredStudents = [];
  List<Map<String, dynamic>> _filieres = [];
  List<Map<String, dynamic>> _niveaux = [];
  bool _isLoading = true;
  bool _isLinking = false;
  final TextEditingController _searchController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _loadData();
    _searchController.addListener(_applyFilters);
  }

  @override
  void dispose() {
    _searchController.removeListener(_applyFilters);
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _loadData() async {
    setState(() => _isLoading = true);
    try {
      final appState = context.read<AppState>();
      await appState.loadFilieres();
      await appState.loadNiveaux();
      final students = await appState.authService.fetchAllStudents();
      setState(() {
        _filieres = appState.filieres;
        _niveaux = appState.niveaux;
        _students = students;
        _filteredStudents = students;
      });
    } catch (e) {
      print('🔴 Error loading data: $e');
    } finally {
      setState(() => _isLoading = false);
    }
  }

  void _applyFilters() {
    final searchQuery = _searchController.text.toLowerCase();
    setState(() {
      _filteredStudents = _students.where((s) {
        final filiereMatch = _selectedFiliereId == null ||
            s['filiere_id']?.toString() == _selectedFiliereId;
        final niveauMatch = _selectedNiveauId == null ||
            s['niveau_id']?.toString() == _selectedNiveauId;
        
        final firstName = (s['first_name'] ?? '').toString().toLowerCase();
        final lastName = (s['last_name'] ?? '').toString().toLowerCase();
        final email = (s['email'] ?? '').toString().toLowerCase();
        final codeMassar = (s['code_massar'] ?? '').toString().toLowerCase();
        
        final nameMatch = searchQuery.isEmpty ||
            firstName.contains(searchQuery) ||
            lastName.contains(searchQuery) ||
            email.contains(searchQuery) ||
            codeMassar.contains(searchQuery);

        final alphabetMatch = _alphabetFilter.isEmpty ||
            firstName.startsWith(_alphabetFilter.toLowerCase()) ||
            lastName.startsWith(_alphabetFilter.toLowerCase());

        return filiereMatch && niveauMatch && nameMatch && alphabetMatch;
      }).toList();
    });
  }

  Future<void> _onFiliereChanged(String? value) async {
    setState(() => _selectedFiliereId = value);
    if (value != null) {
      final niveaux = await context.read<AppState>().authService.fetchNiveauxByFiliere(value);
      setState(() => _niveaux = niveaux);
    }
    _applyFilters();
  }

  Future<void> _linkChild(String childId) async {
    final parentId = context.read<AppState>().currentUser?.id;
    if (parentId == null) return;

    setState(() => _isLinking = true);
    try {
      await context.read<AppState>().linkParentEnfant(parentId, childId);
      if (mounted) {
        // Update local state for immediate feedback
        setState(() {
          for (var s in _students) {
            if (s['id'].toString() == childId) {
              final ids = s['linked_parent_ids'] != null ? List.from(s['linked_parent_ids']) : [];
              if (!ids.contains(parentId)) ids.add(parentId);
              s['linked_parent_ids'] = ids;
            }
          }
          _applyFilters();
        });

        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Enfant lié avec succès!'),
            backgroundColor: AppColors.success,
          ),
        );
        await context.read<AppState>().loadChildData();
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
      setState(() => _isLinking = false);
    }
  }

  Future<void> _unlinkChild(String childId) async {
    final parentId = context.read<AppState>().currentUser?.id;
    if (parentId == null) return;

    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Délier l\'étudiant', style: GoogleFonts.inter(fontWeight: FontWeight.w700)),
        content: const Text('Voulez-vous vraiment délier cet étudiant de votre compte ?'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context, false), child: const Text('Annuler')),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, true),
            style: ElevatedButton.styleFrom(backgroundColor: AppColors.error),
            child: const Text('Délier', style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );

    if (confirm != true) return;

    setState(() => _isLinking = true);
    try {
      await context.read<AppState>().authService.unlinkParentEnfant(parentId, childId);
      if (mounted) {
        // Update local state for immediate feedback
        setState(() {
          for (var s in _students) {
            if (s['id'].toString() == childId) {
              final ids = s['linked_parent_ids'] != null ? List.from(s['linked_parent_ids']) : [];
              ids.remove(parentId);
              s['linked_parent_ids'] = ids;
            }
          }
          _applyFilters();
        });

        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Étudiant délié avec succès!'),
            backgroundColor: AppColors.warning,
          ),
        );
        await context.read<AppState>().loadChildData();
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
      if (mounted) setState(() => _isLinking = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: AppColors.primary.withOpacity(0.1),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: AppColors.primary.withOpacity(0.2)),
            ),
            child: Row(
              children: [
                Icon(LucideIcons.info, color: AppColors.primary, size: 20),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    'Sélectionnez un étudiant à lier à votre compte parent.',
                    style: GoogleFonts.inter(fontSize: 13, color: AppColors.text),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 24),

          // Search Bar
          Text(
            'Recherche',
            style: GoogleFonts.inter(fontSize: 14, fontWeight: FontWeight.w700, color: AppColors.text),
          ),
          const SizedBox(height: 12),
          TextField(
            controller: _searchController,
            onChanged: (_) => _applyFilters(),
            decoration: InputDecoration(
              hintText: 'Rechercher par nom, email ou code Massar...',
              hintStyle: GoogleFonts.inter(fontSize: 13, color: AppColors.textSub),
              prefixIcon: const Icon(LucideIcons.search, size: 18, color: AppColors.primary),
              suffixIcon: _searchController.text.isNotEmpty
                  ? IconButton(
                      icon: const Icon(LucideIcons.x, size: 16),
                      onPressed: () {
                        _searchController.clear();
                        _applyFilters();
                      },
                    )
                  : null,
              filled: true,
              fillColor: Colors.white,
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: const BorderSide(color: AppColors.border, width: 0.5),
              ),
              enabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: const BorderSide(color: AppColors.border, width: 0.5),
              ),
              focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: const BorderSide(color: AppColors.primary, width: 1),
              ),
              contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
            ),
          ),
          const SizedBox(height: 24),

          // Filters
          Text(
            'Filtres',
            style: GoogleFonts.inter(fontSize: 14, fontWeight: FontWeight.w700, color: AppColors.text),
          ),

          const SizedBox(height: 12),

          // Filière Dropdown
          DropdownButtonFormField<String>(
            value: _selectedFiliereId,
            decoration: InputDecoration(
              labelText: 'Filière',
              labelStyle: GoogleFonts.nunito(fontSize: 12, color: AppColors.textSub),
              prefixIcon: const Icon(LucideIcons.graduationCap, color: AppColors.primary, size: 20),
              border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
              contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
            ),
            items: [
              const DropdownMenuItem(value: null, child: Text('Toutes les filières')),
              ..._filieres.map((f) => DropdownMenuItem(
                value: f['id'].toString(),
                child: Text(f['nom']?.toString() ?? 'Sans nom', style: GoogleFonts.nunito(fontSize: 14)),
              )),
            ],
            onChanged: _onFiliereChanged,
          ),
          const SizedBox(height: 12),

          // Niveau Dropdown
          DropdownButtonFormField<String>(
            value: _selectedNiveauId,
            decoration: InputDecoration(
              labelText: 'Niveau',
              labelStyle: GoogleFonts.nunito(fontSize: 12, color: AppColors.textSub),
              prefixIcon: const Icon(LucideIcons.barChart2, color: AppColors.primary, size: 20),
              border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
              contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
            ),
            items: [
              const DropdownMenuItem(value: null, child: Text('Tous les niveaux')),
              ..._niveaux.map((n) => DropdownMenuItem(
                value: n['id'].toString(),
                child: Text(n['nom']?.toString() ?? 'Sans nom', style: GoogleFonts.nunito(fontSize: 14)),
              )),
            ],
            onChanged: (value) {
              setState(() => _selectedNiveauId = value);
              _applyFilters();
            },
          ),
          const SizedBox(height: 20),
          Text(
            'Filtrer par lettre',
            style: GoogleFonts.inter(fontSize: 13, fontWeight: FontWeight.w600, color: AppColors.textSub),
          ),
          const SizedBox(height: 8),
          SizedBox(
            height: 40,
            child: ListView.separated(
              scrollDirection: Axis.horizontal,
              itemCount: 27, // All + A-Z
              separatorBuilder: (_, __) => const SizedBox(width: 8),
              itemBuilder: (context, index) {
                final letters = ['', ...'ABCDEFGHIJKLMNOPQRSTUVWXYZ'.split('')];
                final letter = letters[index];
                final isSelected = _alphabetFilter == letter;
                return GestureDetector(
                  onTap: () {
                    setState(() => _alphabetFilter = letter);
                    _applyFilters();
                  },
                  child: AnimatedContainer(
                    duration: const Duration(milliseconds: 200),
                    width: letter.isEmpty ? 60 : 40,
                    alignment: Alignment.center,
                    decoration: BoxDecoration(
                      color: isSelected ? AppColors.primary : Colors.white,
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(
                        color: isSelected ? AppColors.primary : AppColors.border,
                        width: 1,
                      ),
                      boxShadow: isSelected
                          ? [BoxShadow(color: AppColors.primary.withOpacity(0.3), blurRadius: 8, offset: const Offset(0, 4))]
                          : [],
                    ),
                    child: Text(
                      letter.isEmpty ? 'Tous' : letter,
                      style: GoogleFonts.inter(
                        fontSize: 13,
                        fontWeight: isSelected ? FontWeight.w700 : FontWeight.w500,
                        color: isSelected ? Colors.white : AppColors.text,
                      ),
                    ),
                  ),
                );
              },
            ),
          ),

          const SizedBox(height: 24),

          // Results count
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                '${_filteredStudents.length} étudiants trouvés',
                style: GoogleFonts.inter(fontSize: 14, fontWeight: FontWeight.w600, color: AppColors.text),
              ),
              if (_isLoading)
                const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(strokeWidth: 2)),
            ],
          ),
          const SizedBox(height: 16),

          // Student List
          if (_isLoading)
            const Center(child: Padding(padding: EdgeInsets.all(32), child: CircularProgressIndicator()))
          else if (_filteredStudents.isEmpty)
            Container(
              padding: const EdgeInsets.all(32),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: AppColors.border),
              ),
              child: Column(
                children: [
                  Icon(LucideIcons.searchX, size: 48, color: AppColors.textSub),
                  const SizedBox(height: 16),
                  Text(
                    'Aucun étudiant trouvé',
                    style: GoogleFonts.inter(fontSize: 14, fontWeight: FontWeight.w600, color: AppColors.text),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    'Essayez d\'autres filtres',
                    style: GoogleFonts.inter(fontSize: 12, color: AppColors.textSub),
                  ),
                ],
              ),
            )
          else
            ..._filteredStudents.map((student) {
              final name = '${student['first_name'] ?? ''} ${student['last_name'] ?? ''}'.trim();
              final email = student['email']?.toString() ?? '';
              final codeMassar = student['code_massar']?.toString() ?? '';
              final isLinked = student['linked_parent_ids'] != null &&
                  (student['linked_parent_ids'] as List).contains(context.read<AppState>().currentUser?.id);

              return Container(
                margin: const EdgeInsets.only(bottom: 12),
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: isLinked ? AppColors.success : AppColors.border),
                  boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.03), blurRadius: 8, offset: const Offset(0, 2))],
                ),
                child: Row(
                  children: [
                    Container(
                      width: 50,
                      height: 50,
                      decoration: BoxDecoration(
                        color: isLinked ? AppColors.success.withOpacity(0.1) : AppColors.primary.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Icon(
                        isLinked ? LucideIcons.userCheck : LucideIcons.user,
                        color: isLinked ? AppColors.success : AppColors.primary,
                        size: 24,
                      ),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            name,
                            style: GoogleFonts.inter(fontSize: 15, fontWeight: FontWeight.w700, color: AppColors.text),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            'Code Massar: $codeMassar',
                            style: GoogleFonts.inter(fontSize: 12, color: AppColors.textSub),
                          ),
                          Text(
                            email,
                            style: GoogleFonts.inter(fontSize: 11, color: AppColors.textSub.withOpacity(0.7)),
                          ),
                        ],
                      ),
                    ),
                    if (isLinked)
                      Column(
                        children: [
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                            decoration: BoxDecoration(
                              color: AppColors.success.withOpacity(0.1),
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: Text(
                              'Lié',
                              style: GoogleFonts.inter(fontSize: 12, fontWeight: FontWeight.w600, color: AppColors.success),
                            ),
                          ),
                          const SizedBox(height: 8),
                          TextButton.icon(
                            onPressed: _isLinking ? null : () => _unlinkChild(student['id'].toString()),
                            icon: const Icon(LucideIcons.link2Off, size: 14, color: AppColors.error),
                            label: Text('Délier', style: GoogleFonts.inter(fontSize: 11, color: AppColors.error, fontWeight: FontWeight.w600)),
                            style: TextButton.styleFrom(
                              padding: EdgeInsets.zero,
                              minimumSize: Size.zero,
                              tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                            ),
                          ),
                        ],
                      )
                    else
                      ElevatedButton.icon(
                        onPressed: _isLinking ? null : () async {
                          final confirm = await showDialog<bool>(
                            context: context,
                            builder: (context) => AlertDialog(
                              title: Text('Lier l\'étudiant', style: GoogleFonts.inter(fontWeight: FontWeight.w700)),
                              content: Text('Voulez-vous lier $name à votre compte parent ?'),
                              actions: [
                                TextButton(onPressed: () => Navigator.pop(context, false), child: const Text('Annuler')),
                                ElevatedButton(
                                  onPressed: () => Navigator.pop(context, true),
                                  style: ElevatedButton.styleFrom(backgroundColor: AppColors.primary),
                                  child: const Text('Lier', style: TextStyle(color: Colors.white)),
                                ),
                              ],
                            ),
                          );
                          if (confirm == true) {
                            _linkChild(student['id'].toString());
                          }
                        },
                        icon: _isLinking
                            ? const SizedBox(width: 16, height: 16, child: CircularProgressIndicator(strokeWidth: 2))
                            : const Icon(LucideIcons.link, size: 16),
                        label: Text('Lier', style: GoogleFonts.inter(fontSize: 13)),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: AppColors.primary,
                          foregroundColor: Colors.white,
                          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                        ),
                      ),
                  ],
                ),
              );
            }),
        ],
      ),
    );
  }
}

class _SectionLabel extends StatelessWidget {
  final String t;
  const _SectionLabel(this.t);
  @override
  Widget build(BuildContext context) => Text(t, style: GoogleFonts.nunito(fontSize: 14, fontWeight: FontWeight.w800, color: AppColors.text));
}
