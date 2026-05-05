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

class _HomeTab extends StatelessWidget {
  final User? user;
  const _HomeTab({this.user});
  static const _child = ('Amira B.', 'AB', 87, 12, AppColors.green);

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16).copyWith(bottom: 32),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Welcome card comme teacher
          Container(
            padding: const EdgeInsets.all(28),
            decoration: BoxDecoration(
              gradient: const LinearGradient(
                colors: [AppColors.primary, Color(0xFFBF4E07)],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              borderRadius: BorderRadius.circular(20),
            ),
            child: Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('Bonjour ${user?.firstName ?? ''} ',
                          style: GoogleFonts.inter(fontSize: 20, fontWeight: FontWeight.w800, color: Colors.white)),
                      const SizedBox(height: 4),
                      Text('Suivi de ${_child.$1} aujourd\'hui',
                          style: GoogleFonts.inter(fontSize: 13, color: Colors.white.withOpacity(0.85))),
                      const SizedBox(height: 16),
                      _ParentRoleChip(),
                    ],
                  ),
                ),
                Container(
                  width: 80, height: 80,
                  decoration: BoxDecoration(
                    color: Colors.white.withOpacity(0.15), 
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(16),
                    child: Image.asset(
                      'assets/images/parent-illustration.webp',
                      width: 80,
                      height: 80,
                      fit: BoxFit.cover,
                      errorBuilder: (context, error, stackTrace) {
                        return const Icon(LucideIcons.users, color: Colors.white, size: 40);
                      },
                    ),
                  ),
                ),
              ],
            ),
          ),

          // ─── Cartes statistiques principales ─────────────────────────────────
          Row(
            children: [
              Expanded(
                child: _StatCard(
                  icon: LucideIcons.trendingUp,
                  title: 'Performance',
                  value: '${_child.$3}%',
                  color: AppColors.success,
                  subtitle: 'Moyenne générale',
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _StatCard(
                  icon: LucideIcons.calendar,
                  title: 'Présence',
                  value: '95%',
                  color: AppColors.info,
                  subtitle: 'Ce mois-ci',
                ),
              ),
            ],
          ),
          const SizedBox(height: 20),

          // ─── Carte de progression améliorée ──────────────────────────────────
          Container(
            padding: const EdgeInsets.all(20),
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
                Row(
                  children: [
                    Container(
                      width: 50,
                      height: 50,
                      decoration: BoxDecoration(
                        color: AppColors.warning.withOpacity(0.15),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: const Icon(
                        LucideIcons.graduationCap,
                        color: AppColors.warning,
                        size: 24,
                      ),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            '${_child.$1}',
                            style: GoogleFonts.inter(
                              fontSize: 18,
                              fontWeight: FontWeight.w700,
                              color: AppColors.text,
                            ),
                          ),
                          Text(
                            'Progression académique',
                            style: GoogleFonts.inter(
                              fontSize: 13,
                              fontWeight: FontWeight.w500,
                              color: AppColors.textSub,
                            ),
                          ),
                        ],
                      ),
                    ),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                      decoration: BoxDecoration(
                        color: AppColors.warning.withOpacity(0.15),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Text(
                        '${_child.$3}%',
                        style: GoogleFonts.inter(
                          fontSize: 16,
                          fontWeight: FontWeight.w700,
                          color: AppColors.warning,
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                Container(
                  height: 8,
                  decoration: BoxDecoration(
                    color: AppColors.border.withOpacity(0.2),
                    borderRadius: BorderRadius.circular(4),
                  ),
                  child: FractionallySizedBox(
                    alignment: Alignment.centerLeft,
                    widthFactor: _child.$3 / 100,
                    child: Container(
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          colors: [
                            AppColors.warning,
                            AppColors.warning.withOpacity(0.8),
                          ],
                        ),
                        borderRadius: BorderRadius.circular(4),
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 20),

          // ─── Section activités récentes ─────────────────────────────────────
          Container(
            padding: const EdgeInsets.all(20),
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
                Row(
                  children: [
                    Text(
                      'Activités récentes',
                      style: GoogleFonts.inter(
                        fontSize: 18,
                        fontWeight: FontWeight.w700,
                        color: AppColors.text,
                      ),
                    ),
                    const Spacer(),
                    Text(
                      'Voir tout',
                      style: GoogleFonts.inter(
                        fontSize: 13,
                        fontWeight: FontWeight.w600,
                        color: AppColors.primary,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                _ActivityItem(
                  icon: LucideIcons.fileText,
                  title: 'Biologie Cellulaire',
                  subtitle: 'Note obtenue',
                  value: '87/100',
                  color: AppColors.success,
                  time: '25 Avr',
                ),
                _ActivityItem(
                  icon: LucideIcons.bookOpen,
                  title: 'Mitose et Méiose',
                  subtitle: 'Note obtenue',
                  value: '92/100',
                  color: AppColors.success,
                  time: '22 Avr',
                ),
                _ActivityItem(
                  icon: LucideIcons.testTube,
                  title: 'ADN et Génétique',
                  subtitle: 'Note obtenue',
                  value: '78/100',
                  color: AppColors.warning,
                  time: '18 Avr',
                ),
              ],
            ),
          ),
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

class _StatsTab extends StatelessWidget {
  static const _scores = [65, 72, 80, 92, 78, 87, 75];
  static const _days   = ['Lu', 'Ma', 'Me', 'Je', 'Ve', 'Sa', 'Di'];
  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        _SectionLabel('Évolution de la semaine'),
        const SizedBox(height: 10),
        Container(
          height: 130, padding: const EdgeInsets.fromLTRB(12, 12, 12, 4),
          decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(16), border: Border.all(color: AppColors.border, width: 0.5)),
          child: Row(crossAxisAlignment: CrossAxisAlignment.end, children: [
            for (int i = 0; i < _scores.length; i++) ...[
              if (i > 0) const SizedBox(width: 8),
              Expanded(child: Column(mainAxisAlignment: MainAxisAlignment.end, children: [
                Text('${_scores[i]}', style: GoogleFonts.nunito(fontSize: 9, fontWeight: FontWeight.w800, color: AppColors.green)),
                const SizedBox(height: 3),
                SizedBox(
                  height: 60 * (_scores[i] / 100),
                  child: Container(decoration: BoxDecoration(color: AppColors.green, borderRadius: const BorderRadius.vertical(top: Radius.circular(4))))),
                const SizedBox(height: 4),
                Text(_days[i], style: GoogleFonts.nunito(fontSize: 9, color: AppColors.textSub)),
              ])),
            ],
          ]),
        ),
        const SizedBox(height: 16),
        Text(
          'Par matière',
          style: GoogleFonts.nunito(
            fontSize: 14,
            fontWeight: FontWeight.w800,
            color: AppColors.text,
          ),
        ),
        const SizedBox(height: 10),
        ParentSubjectProgress(
          subject: 'Biologie',
          progress: 0.87,
          score: 87,
          color: AppColors.success,
          icon: LucideIcons.dna,
          teacherName: 'Prof. Fatima Z.',
          nextClass: 'Chapitre 5: Photosynthèse',
          onTap: () {
            // Navigation vers détails de la matière
          },
        ),
        ParentSubjectProgress(
          subject: 'Maths',
          progress: 0.64,
          score: 64,
          color: AppColors.primary,
          icon: LucideIcons.functionSquare,
          teacherName: 'Prof. Hassan M.',
          nextClass: 'Exercices sur les fonctions',
          onTap: () {
            // Navigation vers détails de la matière
          },
        ),
        ParentSubjectProgress(
          subject: 'Physique',
          progress: 0.76,
          score: 76,
          color: AppColors.info,
          icon: LucideIcons.zap,
          teacherName: 'Prof. Laila B.',
          nextClass: 'Laboratoire d\'électricité',
          onTap: () {
            // Navigation vers détails de la matière
          },
        ),
      ]),
    );
  }
}

class _ContactTab extends StatelessWidget {
  static const _teachers = [
    ('Prof. Fatima Z.', 'Biologie', LucideIcons.microscope, LucideIcons.testTube),
    ('Prof. Hassan M.', 'Mathématiques', LucideIcons.calculator, LucideIcons.hash),
    ('Prof. Laila B.',  'Physique-Chimie', LucideIcons.atom, LucideIcons.settings),
  ];

  @override
  Widget build(BuildContext context) {
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
        ..._teachers.map((t) => Container(
          margin: const EdgeInsets.only(bottom: 8),
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(14), border: Border.all(color: AppColors.border, width: 0.5)),
          child: Row(children: [
            Container(width: 44, height: 44, decoration: BoxDecoration(color: AppColors.primaryLight, borderRadius: BorderRadius.circular(12)),
              child: Icon(t.$3, size: 22, color: AppColors.primary)),
            const SizedBox(width: 12),
            Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Text(t.$1, style: GoogleFonts.nunito(fontSize: 13, fontWeight: FontWeight.w700, color: AppColors.text)),
              Text(t.$2, style: GoogleFonts.nunito(fontSize: 11, color: AppColors.textSub)),
            ])),
            GestureDetector(
              onTap: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (_) => ConversationScreen(
                      teacherName: t.$1,
                      subject: t.$2,
                      teacherIcon: t.$4,
                    ),
                  ),
                );
              },
              child: Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(color: AppColors.primaryLight, borderRadius: BorderRadius.circular(10)),
                child: const Icon(LucideIcons.messageSquare, size: 18, color: AppColors.primary),
              ),
            ),
          ]),
        )),
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
