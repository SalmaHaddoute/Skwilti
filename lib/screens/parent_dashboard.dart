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
    SkwNavItem(icon: LucideIcons.messageSquare, label: 'Contact'),
  ];

  @override
  Widget build(BuildContext context) {
    final user = context.watch<AppState>().currentUser;
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: SkwiltiTopNav(
        title: _idx == 0 ? 'Skwilti' : _idx == 1 ? 'Statistiques' : 'Contact',
        showLogo: _idx == 0,
        showNotifications: true,
        onProfileTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const ProfileScreen())),
      ),
      body: IndexedStack(index: _idx, children: [
        _HomeTab(user: user),
        _StatsTab(),
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

class _ContactTab extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    final teachers = context.watch<AppState>().childTeachers;
    final loaded   = context.watch<AppState>().childDataLoaded;
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(color: AppColors.infoLight, borderRadius: BorderRadius.circular(12), border: Border.all(color: AppColors.info.withOpacity(0.2))),
          child: Row(children: [
            const Icon(LucideIcons.info, size: 16, color: AppColors.info),
            const SizedBox(width: 8),
            Expanded(child: Text('Contactez les enseignants directement depuis l\'app.',
              style: GoogleFonts.nunito(fontSize: 12, color: AppColors.info, fontWeight: FontWeight.w600))),
          ]),
        ),
        const SizedBox(height: 16),
        _SectionLabel('Enseignants'),
        const SizedBox(height: 10),
        if (!loaded)
          const Center(child: CircularProgressIndicator())
        else if (teachers.isEmpty)
          Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(12), border: Border.all(color: AppColors.border, width: 0.5)),
            child: Column(children: [
              Icon(LucideIcons.users, size: 36, color: AppColors.textSub),
              const SizedBox(height: 8),
              Text('Aucun enseignant trouvé', style: GoogleFonts.inter(fontSize: 13, color: AppColors.textSub)),
            ]),
          )
        else
          ...teachers.map((t) {
            final name    = t['teacher_name'] as String? ?? 'Enseignant';
            final subject = t['category'] as String? ?? '';
            return Container(
              margin: const EdgeInsets.only(bottom: 8),
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(14), border: Border.all(color: AppColors.border, width: 0.5)),
              child: Row(children: [
                Container(width: 44, height: 44,
                  decoration: BoxDecoration(color: AppColors.primaryLight, borderRadius: BorderRadius.circular(12)),
                  child: const Icon(LucideIcons.graduationCap, size: 22, color: AppColors.primary)),
                const SizedBox(width: 12),
                Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                  Text(name, style: GoogleFonts.nunito(fontSize: 13, fontWeight: FontWeight.w700, color: AppColors.text)),
                  Text(subject, style: GoogleFonts.nunito(fontSize: 11, color: AppColors.textSub)),
                ])),
                GestureDetector(
                  onTap: () => Navigator.push(context, MaterialPageRoute(
                    builder: (_) => ConversationScreen(teacherName: name, subject: subject, teacherIcon: LucideIcons.messageSquare))),
                  child: Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(color: AppColors.primaryLight, borderRadius: BorderRadius.circular(10)),
                    child: const Icon(LucideIcons.messageSquare, size: 18, color: AppColors.primary)),
                ),
              ]),
            );
          }),
      ]),
    );
  }
}

class _SectionLabel extends StatelessWidget {
  final String t;
  const _SectionLabel(this.t);
  @override
  Widget build(BuildContext context) => Text(t, style: GoogleFonts.nunito(fontSize: 14, fontWeight: FontWeight.w800, color: AppColors.text));
}
