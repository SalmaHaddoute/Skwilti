import 'package:flutter/material.dart';
import 'package:lucide_icons/lucide_icons.dart';
import 'package:provider/provider.dart';
import 'package:google_fonts/google_fonts.dart';
import '../theme/app_theme.dart';
import '../services/app_state.dart';
import '../models/user.dart';
import '../models/question.dart';
import '../models/qsm_session.dart';
import '../models/classroom.dart';
import '../widgets/skwilti_nav.dart';
import '../widgets/common_widgets.dart';
import '../widgets/dashboard_widgets.dart';
import 'profile_screen.dart';
import 'qcm_screen.dart';
import 'room_code_screen.dart';
import 'join_class_screen.dart';

class StudentDashboard extends StatefulWidget {
  const StudentDashboard({super.key});
  @override
  State<StudentDashboard> createState() => _StudentDashboardState();
}

class _StudentDashboardState extends State<StudentDashboard> {
  int _idx = 0;

  static const _nav = [
    SkwNavItem(icon: LucideIcons.home, activeIcon: LucideIcons.home, label: 'Accueil'),
    SkwNavItem(icon: LucideIcons.fileText, activeIcon: LucideIcons.fileText, label: 'QSM'),
    SkwNavItem(icon: LucideIcons.users, activeIcon: LucideIcons.users, label: 'Classes'),
    SkwNavItem(icon: LucideIcons.layers, activeIcon: LucideIcons.layers, label: 'Rooms'),
    SkwNavItem(icon: LucideIcons.library, activeIcon: LucideIcons.library, label: 'Bibliothèque'),
  ];

  @override
  Widget build(BuildContext context) {
    final user = context.watch<AppState>().currentUser;
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: SkwiltiTopNav(
        title: _title,
        showLogo: _idx == 0,
        showNotifications: true,
        leading: _idx != 0 ? Container(
          width: 40,
          height: 40,
          decoration: BoxDecoration(color: AppColors.primaryLight, borderRadius: BorderRadius.circular(10)),
          child: Icon(_currentIcon, size: 20, color: AppColors.primary),
        ) : null,
        onProfileTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const ProfileScreen())),
      ),
      body: IndexedStack(index: _idx, children: [
        _HomeTab(user: user),
        _QsmTab(),
        _ClassesTab(),
        _RoomsTab(),
        _LibraryTab(),
      ]),
      bottomNavigationBar: SkwiltiBottomNav(currentIndex: _idx, onTap: (i) => setState(() => _idx = i), items: _nav),
    );
  }

  String get _title => ['Skwilti', 'Mes QSM', 'Classes', 'Rooms', 'Bibliothèque'][_idx];

  IconData get _currentIcon {
    switch (_idx) {
      case 0: return LucideIcons.home;
      case 1: return LucideIcons.fileText;
      case 2: return LucideIcons.users;
      case 3: return LucideIcons.layers;
      case 4: return LucideIcons.library;
      default: return LucideIcons.home;
    }
  }
}

// ── Home Tab ─────────────────────────────────────────────────
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
      context.read<AppState>().loadStudentSessions();
    });
  }

  @override
  Widget build(BuildContext context) {
    final state = context.watch<AppState>();
    final sessions = state.recentSessions;
    final loaded  = state.sessionsLoaded;
    final stats   = state.userStats;

    // Calcul des stats depuis les sessions réelles
    final scores = sessions
        .where((s) => s['score'] != null && s['total_questions'] != null && (s['total_questions'] as int) > 0)
        .map<int>((s) => ((s['score'] as int) * 100 ~/ (s['total_questions'] as int)))
        .toList();
    final bestScore  = scores.isNotEmpty ? scores.reduce((a, b) => a > b ? a : b) : 0;
    final avgScore   = scores.isNotEmpty ? (scores.reduce((a, b) => a + b) / scores.length).round() : 0;

    return SingleChildScrollView(
      padding: const EdgeInsets.all(16).copyWith(bottom: 32),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Welcome card
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
                      Text('Bonjour ${widget.user?.firstName ?? ''} ',
                          style: GoogleFonts.nunito(fontSize: 20, fontWeight: FontWeight.w800, color: Colors.white)),
                      const SizedBox(height: 4),
                      Text('Prêt à apprendre aujourd\'hui ?',
                          style: GoogleFonts.nunito(fontSize: 13, color: Colors.white.withOpacity(0.85))),
                      const SizedBox(height: 16),
                      _StudentLevelChip(user: widget.user),
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
                      'assets/images/student-illustration.webp',
                      width: 80, height: 80, fit: BoxFit.cover,
                      errorBuilder: (_, __, ___) =>
                          const Icon(LucideIcons.graduationCap, color: Colors.white, size: 40),
                    ),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 20),

          // Performance Curve
          _SectionHeader('Progression'),
          const SizedBox(height: 12),
          Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: AppColors.border, width: 0.5),
              boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 10, offset: const Offset(0, 2))],
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(children: [
                  Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(color: AppColors.primary.withOpacity(0.1), borderRadius: BorderRadius.circular(10)),
                    child: const Icon(LucideIcons.trendingUp, size: 20, color: AppColors.primary),
                  ),
                  const SizedBox(width: 12),
                  Text('Performance cette semaine',
                      style: GoogleFonts.inter(fontSize: 16, fontWeight: FontWeight.w700, color: AppColors.text)),
                ]),
                const SizedBox(height: 16),
                SizedBox(height: 120, child: _PerformanceCurve(weeklyScores: state.weeklyScores)),
              ],
            ),
          ),
          const SizedBox(height: 20),

          // Stats row (données réelles)
          Row(
            children: [
              Expanded(child: _SimpleStatCard(
                label: 'Meilleur score',
                value: scores.isNotEmpty ? '$bestScore%' : '--',
                icon: LucideIcons.trophy,
                color: AppColors.success,
              )),
              const SizedBox(width: 10),
              Expanded(child: _SimpleStatCard(
                label: 'Moyenne',
                value: scores.isNotEmpty ? '$avgScore%' : '--',
                icon: LucideIcons.barChart2,
                color: AppColors.primary,
              )),
              const SizedBox(width: 10),
              Expanded(child: _SimpleStatCard(
                label: 'QSM complétés',
                value: '${stats?.totalQsmCompleted ?? sessions.length}',
                icon: LucideIcons.checkCircle,
                color: AppColors.info,
              )),
            ],
          ),
          const SizedBox(height: 20),

          // QSM récents (données réelles)
          _SectionHeader('QSM récents'),
          const SizedBox(height: 10),
          if (!loaded)
            const Center(child: Padding(
              padding: EdgeInsets.all(24),
              child: CircularProgressIndicator(),
            ))
          else if (sessions.isEmpty)
            Container(
              padding: const EdgeInsets.all(24),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: AppColors.border, width: 0.5),
              ),
              child: Column(
                children: [
                  Icon(LucideIcons.fileText, size: 40, color: AppColors.textSub),
                  const SizedBox(height: 12),
                  Text('Aucun QSM complété pour l\'instant',
                      style: GoogleFonts.inter(fontSize: 14, color: AppColors.textSub)),
                  const SizedBox(height: 4),
                  Text('Rejoignez une classe ou un room pour commencer !',
                      style: GoogleFonts.inter(fontSize: 12, color: AppColors.textSub),
                      textAlign: TextAlign.center),
                ],
              ),
            )
          else
            ...sessions.take(5).map((s) {
              final total    = (s['total_questions'] as int? ?? 0);
              final score    = (s['score'] as int? ?? 0);
              final pct      = total > 0 ? (score * 100 ~/ total) : 0;
              final title    = (s['courses'] as Map?)?['title'] as String? ?? 'QSM sans titre';
              
              final dateRaw = (s['completed_at'] != null 
                  ? DateTime.tryParse(s['completed_at']) 
                  : null) ?? (s['created_at'] != null
                  ? DateTime.tryParse(s['created_at'])
                  : null);
              final completedAt = dateRaw != null ? dateRaw.toLocal() : DateTime.now();

              return _RecentQsmCard(
                title: title,
                score: pct,
                date: completedAt,
                onTap: () {},
              );
            }),

          const SizedBox(height: 20),

          // Actions rapides
          _SectionHeader('Actions rapides'),
          const SizedBox(height: 10),
          GridView.count(
            crossAxisCount: 2,
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            crossAxisSpacing: 10,
            mainAxisSpacing: 10,
            childAspectRatio: 1.8,
            children: [
              _SimpleQuickAction(icon: LucideIcons.fileText, label: 'Rejoindre classe', sub: 'Code d\'accès', color: AppColors.primary,
                  onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const JoinClassScreen()))),
              _SimpleQuickAction(icon: LucideIcons.link, label: 'Code Room', sub: 'Entrer un code', color: AppColors.info,
                  onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const RoomCodeScreen()))),
            ],
          ),
        ],
      ),
    );
  }
}

// ── Student Level Chip ───────────────────────────────────────────
class _StudentLevelChip extends StatelessWidget {
  final User? user;
  const _StudentLevelChip({this.user});

  @override
  Widget build(BuildContext context) {
    final level = '1AC';
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.2),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: Colors.white.withOpacity(0.3)),
      ),
      child: Text(
        level,
        style: GoogleFonts.nunito(
          fontSize: 12,
          fontWeight: FontWeight.w700,
          color: Colors.white,
        ),
      ),
    );
  }
}

// ── Recent QSM Card ───────────────────────────────────────────
class _RecentQsmCard extends StatelessWidget {
  final String title;
  final int score;
  final DateTime date;
  final VoidCallback onTap;
  
  const _RecentQsmCard({
    required this.title,
    required this.score,
    required this.date,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        margin: const EdgeInsets.only(bottom: 8),
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
                color: _getScoreColor().withOpacity(0.1),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Icon(
                _getScoreIcon(),
                size: 20,
                color: _getScoreColor(),
              ),
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
                      fontWeight: FontWeight.w700,
                      color: AppColors.text,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 4),
                  Text(
                    '${_formatDate(date)}',
                    style: GoogleFonts.inter(
                      fontSize: 11,
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
                  '$score%',
                  style: GoogleFonts.inter(
                    fontSize: 16,
                    fontWeight: FontWeight.w900,
                    color: _getScoreColor(),
                  ),
                ),
                Text(
                  _getScoreLabel(),
                  style: GoogleFonts.inter(
                    fontSize: 10,
                    color: _getScoreColor().withOpacity(0.7),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Color _getScoreColor() {
    if (score >= 80) return AppColors.success;
    if (score >= 60) return AppColors.primary;
    return AppColors.error;
  }

  IconData _getScoreIcon() {
    if (score >= 80) return LucideIcons.trophy;
    if (score >= 60) return LucideIcons.target;
    return LucideIcons.alertCircle;
  }

  String _getScoreLabel() {
    if (score >= 80) return 'Excellent';
    if (score >= 60) return 'Bien';
    return 'À améliorer';
  }

  String _formatDate(DateTime date) {
    final now = DateTime.now();
    final difference = now.difference(date);
    
    if (difference.inDays > 0) {
      return 'Il y a ${difference.inDays}j';
    } else if (difference.inHours > 0) {
      return 'Il y a ${difference.inHours}h';
    } else if (difference.inMinutes > 0) {
      return 'Il y a ${difference.inMinutes}min';
    } else {
      return 'À l\'instant';
    }
  }
}

// ── Detailed Stat Card ─────────────────────────────────────
class _DetailedStatCard extends StatelessWidget {
  final String title;
  final String value;
  final String subtitle;
  final IconData icon;
  final Color color;
  final String trend;
  final bool isPositive;

  const _DetailedStatCard({
    required this.title,
    required this.value,
    required this.subtitle,
    required this.icon,
    required this.color,
    required this.trend,
    required this.isPositive,
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
                  color: color.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Icon(icon, size: 20, color: color),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: GoogleFonts.inter(
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                        color: AppColors.textSub,
                      ),
                    ),
                    Text(
                      subtitle,
                      style: GoogleFonts.inter(
                        fontSize: 10,
                        color: AppColors.textSub.withOpacity(0.7),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Text(
                value,
                style: GoogleFonts.inter(
                  fontSize: 20,
                  fontWeight: FontWeight.w800,
                  color: AppColors.text,
                ),
              ),
              const SizedBox(width: 8),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                decoration: BoxDecoration(
                  color: isPositive ? AppColors.success.withOpacity(0.1) : AppColors.error.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(
                      isPositive ? LucideIcons.trendingUp : LucideIcons.trendingDown,
                      size: 12,
                      color: isPositive ? AppColors.success : AppColors.error,
                    ),
                    const SizedBox(width: 4),
                    Text(
                      trend,
                      style: GoogleFonts.inter(
                        fontSize: 10,
                        fontWeight: FontWeight.w700,
                        color: isPositive ? AppColors.success : AppColors.error,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

// ── Performance Curve ─────────────────────────────────
class _PerformanceCurve extends StatelessWidget {
  final List<Map<String, dynamic>> weeklyScores;
  const _PerformanceCurve({this.weeklyScores = const []});

  @override
  Widget build(BuildContext context) {
    // Construire les données des 7 derniers jours
    final dayLabels = ['Lun', 'Mar', 'Mer', 'Jeu', 'Ven', 'Sam', 'Dim'];
    final today = DateTime.now();
    final todayStart = DateTime(today.year, today.month, today.day);
    final Map<int, List<int>> byDayIndex = {};
    for (final s in weeklyScores) {
      if (s['completed_at'] != null && s['total_questions'] != null && (s['total_questions'] as int) > 0) {
        final date = DateTime.tryParse(s['completed_at']);
        if (date != null) {
          final localDate = date.toLocal();
          final sessionStart = DateTime(localDate.year, localDate.month, localDate.day);
          final diff = todayStart.difference(sessionStart).inDays;
          if (diff >= 0 && diff < 7) {
            final idx = 6 - diff;
            final pct = ((s['score'] as int? ?? 0) * 100 ~/ (s['total_questions'] as int));
            byDayIndex[idx] = [...(byDayIndex[idx] ?? []), pct];
          }
        }
      }
    }
    final data = List.generate(7, (i) {
      final scores = byDayIndex[i] ?? [];
      final avg = scores.isNotEmpty ? scores.reduce((a, b) => a + b) ~/ scores.length : 0;
      final date = DateTime.now().subtract(Duration(days: 6 - i));
      return {'day': dayLabels[date.weekday - 1], 'score': avg};
    });

    return CustomPaint(
      painter: _CurvePainter(data),
      child: Container(
        width: double.infinity,
        height: double.infinity,
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(8),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceEvenly,
          crossAxisAlignment: CrossAxisAlignment.end,
          children: data.map((point) => Column(
            mainAxisAlignment: MainAxisAlignment.end,
            children: [
              Container(
                width: 4,
                height: 4,
                decoration: BoxDecoration(
                  color: AppColors.primary,
                  shape: BoxShape.circle,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                point['day'] as String,
                style: GoogleFonts.inter(
                  fontSize: 10,
                  fontWeight: FontWeight.w600,
                  color: AppColors.textSub,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                '${point['score']}%',
                style: GoogleFonts.inter(
                  fontSize: 11,
                  fontWeight: FontWeight.w700,
                  color: AppColors.text,
                ),
              ),
            ],
          )).toList(),
        ),
      ),
    );
  }
}

class _CurvePainter extends CustomPainter {
  final List<Map<String, dynamic>> data;

  _CurvePainter(this.data);

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = AppColors.primary
      ..strokeWidth = 3
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round;

    final fillPaint = Paint()
      ..color = AppColors.primary.withOpacity(0.1)
      ..style = PaintingStyle.fill;

    final path = Path();
    final points = <Offset>[];

    // Calculer les points de la courbe
    for (int i = 0; i < data.length; i++) {
      final x = (size.width / (data.length - 1)) * i;
      final score = (data[i]['score'] as int) / 100.0;
      final y = size.height - (score * size.height);
      points.add(Offset(x, y));
    }

    // Dessiner la courbe
    if (points.isNotEmpty) {
      path.moveTo(points.first.dx, points.first.dy);
      
      // Créer une courbe lisse
      for (int i = 1; i < points.length; i++) {
        final prevPoint = points[i - 1];
        final currentPoint = points[i];
        
        // Point de contrôle pour la courbe de Bézier
        final controlX = (prevPoint.dx + currentPoint.dx) / 2;
        final controlY = prevPoint.dy - 20; // Légère courbe vers le haut
        
        path.quadraticBezierTo(
          controlX, 
          controlY, 
          currentPoint.dx, 
          currentPoint.dy,
        );
      }
      
      // Remplir sous la courbe
      final fillPath = Path.from(path);
      fillPath.lineTo(points.last.dx, size.height);
      fillPath.lineTo(0, size.height);
      fillPath.close();
      
      canvas.drawPath(fillPath, fillPaint);
      canvas.drawPath(path, paint);
    }

    // Dessiner les points
    for (final point in points) {
      final pointPaint = Paint()
        ..color = AppColors.primary
        ..style = PaintingStyle.fill;
      
      canvas.drawCircle(point, 6, pointPaint);
      
      // Cercle blanc intérieur
      final whitePaint = Paint()
        ..color = Colors.white
        ..style = PaintingStyle.fill;
      
      canvas.drawCircle(point, 3, whitePaint);
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

// ── QSM Tab ─────────────────────────────────────────────────
class _QsmTab extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16).copyWith(bottom: 32),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Hero Section with gradient background
          Container(
            padding: const EdgeInsets.all(24),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [AppColors.primary, AppColors.primary.withOpacity(0.8)],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              borderRadius: BorderRadius.circular(20),
              boxShadow: [
                BoxShadow(
                  color: AppColors.primary.withOpacity(0.2),
                  blurRadius: 12,
                  offset: const Offset(0, 4),
                ),
              ],
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: Colors.white.withOpacity(0.2),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: const Icon(
                        LucideIcons.trophy,
                        size: 28,
                        color: Colors.white,
                      ),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'QSM Dashboard',
                            style: GoogleFonts.inter(
                              fontSize: 20,
                              fontWeight: FontWeight.w800,
                              color: Colors.white,
                            ),
                          ),
                          Text(
                            'Continuez votre progression !',
                            style: GoogleFonts.inter(
                              fontSize: 14,
                              color: Colors.white.withOpacity(0.9),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 20),
                Row(
                  children: [
                    Expanded(
                      child: _QuickStatCard(
                        label: 'Score Total',
                        value: '1,245',
                        icon: LucideIcons.target,
                        color: Colors.white,
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: _QuickStatCard(
                        label: 'QSM Complétés',
                        value: '23',
                        icon: LucideIcons.checkCircle,
                        color: Colors.white,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
          const SizedBox(height: 24),
          
          _SectionHeader('Progression des scores'),
          const SizedBox(height: 12),
          _ProgressionCard(),
          const SizedBox(height: 24),
          
          // Recent Activity Section
          _SectionHeader('Activité récente'),
          const SizedBox(height: 12),
          _RecentActivityCard(),
        ],
      ),
    );
  }
}

// ── Progression Card ─────────────────────────────────────────--
class _ProgressionCard extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.border, width: 0.5),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: AppColors.primary.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: const Icon(
                  LucideIcons.trendingUp,
                  size: 24,
                  color: AppColors.primary,
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Progression globale',
                      style: GoogleFonts.inter(
                        fontSize: 16,
                        fontWeight: FontWeight.w700,
                        color: AppColors.text,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      '+12% cette semaine',
                      style: GoogleFonts.inter(
                        fontSize: 12,
                        color: AppColors.success,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          LinearProgressIndicator(
            value: 0.75,
            backgroundColor: AppColors.border,
            valueColor: AlwaysStoppedAnimation<Color>(AppColors.primary),
            minHeight: 8,
          ),
          const SizedBox(height: 8),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                '75% complété',
                style: GoogleFonts.inter(
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                  color: AppColors.textSub,
                ),
              ),
              Text(
                'Objectif: 80%',
                style: GoogleFonts.inter(
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
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

// ── Stats Grid ─────────────────────────────────────────────--
class _StatsGrid extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return GridView.count(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      crossAxisCount: 2,
      crossAxisSpacing: 10,
      mainAxisSpacing: 10,
      childAspectRatio: 1.5,
      children: [
        _StatItem(
          icon: LucideIcons.target,
          label: 'Précision moyenne',
          value: '82%',
          color: AppColors.success,
        ),
        _StatItem(
          icon: LucideIcons.clock,
          label: 'Temps moyen',
          value: '18 min',
          color: AppColors.info,
        ),
        _StatItem(
          icon: LucideIcons.zap,
          label: 'Vitesse',
          value: '1.2q/min',
          color: AppColors.warning,
        ),
        _StatItem(
          icon: LucideIcons.award,
          label: 'Points gagnés',
          value: '+245',
          color: AppColors.primary,
        ),
      ],
    );
  }
}

// ── Performance Grid ─────────────────────────────────------
class _PerformanceGrid extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    final subjects = [
      {'name': 'Mathématiques', 'score': 85, 'color': AppColors.primary},
      {'name': 'Physique', 'score': 78, 'color': AppColors.info},
      {'name': 'Français', 'score': 92, 'color': AppColors.success},
      {'name': 'Anglais', 'score': 73, 'color': AppColors.warning},
    ];
    
    return GridView.count(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      crossAxisCount: 2,
      crossAxisSpacing: 10,
      mainAxisSpacing: 10,
      childAspectRatio: 1.5,
      children: subjects.map((subject) => _PerformanceItem(
        name: subject['name'] as String,
        score: subject['score'] as int,
        color: subject['color'] as Color,
      )).toList(),
    );
  }
}

// ── Stat Item ─────────────────────────────────────────----
class _StatItem extends StatelessWidget {
  final IconData icon;
  final String label;
  final String value;
  final Color color;
  
  const _StatItem({
    required this.icon,
    required this.label,
    required this.value,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: color.withOpacity(0.2), width: 0.5),
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(icon, size: 24, color: color),
          const SizedBox(height: 8),
          Text(
            value,
            style: GoogleFonts.inter(
              fontSize: 16,
              fontWeight: FontWeight.w700,
              color: color,
            ),
          ),
          Text(
            label,
            style: GoogleFonts.inter(
              fontSize: 11,
              color: color.withOpacity(0.8),
            ),
          ),
        ],
      ),
    );
  }
}

// ── Performance Item ─────────────────────────────────----
class _PerformanceItem extends StatelessWidget {
  final String name;
  final int score;
  final Color color;
  
  const _PerformanceItem({
    required this.name,
    required this.score,
    required this.color,
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
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                score >= 80 ? LucideIcons.trophy : score >= 60 ? LucideIcons.target : LucideIcons.alertCircle,
                size: 20,
                color: color,
              ),
              const SizedBox(width: 8),
              Text(
                '$score%',
                style: GoogleFonts.inter(
                  fontSize: 18,
                  fontWeight: FontWeight.w900,
                  color: color,
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            name,
            style: GoogleFonts.inter(
              fontSize: 12,
              fontWeight: FontWeight.w600,
              color: AppColors.text,
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }
}

// ── Quick Stat Card ───────────────────────────────────────
class _QuickStatCard extends StatelessWidget {
  final String label;
  final String value;
  final IconData icon;
  final Color color;
  
  const _QuickStatCard({
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

// ── Recent Activity Card ───────────────────────────────────
class _RecentActivityCard extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    final sessions = context.watch<AppState>().recentSessions;
    final activities = sessions.take(3).map((s) {
      final total = (s['total_questions'] as int? ?? 0);
      final score = (s['score'] as int? ?? 0);
      final pct   = total > 0 ? (score * 100 ~/ total) : 0;
      final title = (s['courses'] as Map?)?['title'] as String? ?? 'QSM';
      final completedAt = s['completed_at'] != null ? DateTime.tryParse(s['completed_at']) : null;
      final diff = completedAt != null ? DateTime.now().difference(completedAt) : null;
      String timeStr = 'Récemment';
      if (diff != null) {
        if (diff.inDays > 0) timeStr = 'Il y a ${diff.inDays}j';
        else if (diff.inHours > 0) timeStr = 'Il y a ${diff.inHours}h';
        else timeStr = 'Il y a ${diff.inMinutes}min';
      }
      return {'title': title, 'score': '$pct%', 'time': timeStr,
              'icon': LucideIcons.fileText, 'color': pct >= 80 ? AppColors.success : pct >= 60 ? AppColors.primary : AppColors.error};
    }).toList();

    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.border, width: 0.5),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(16),
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: AppColors.primaryLight,
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: const Icon(
                    LucideIcons.activity,
                    size: 20,
                    color: AppColors.primary,
                  ),
                ),
                const SizedBox(width: 12),
                Text(
                  'Derniers QSM',
                  style: GoogleFonts.inter(
                    fontSize: 16,
                    fontWeight: FontWeight.w700,
                    color: AppColors.text,
                  ),
                ),
                const Spacer(),
                Text(
                  'Voir tout',
                  style: GoogleFonts.inter(
                    fontSize: 12,
                    color: AppColors.primary,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
          ),
          const Divider(height: 1, color: AppColors.border),
          ...activities.map((activity) => _ActivityItem(
            title: activity['title'] as String,
            score: activity['score'] as String,
            time: activity['time'] as String,
            icon: activity['icon'] as IconData,
            color: activity['color'] as Color,
          )).toList(),
        ],
      ),
    );
  }
}

// ── Activity Item ─────────────────────────────────────────
class _ActivityItem extends StatelessWidget {
  final String title;
  final String score;
  final String time;
  final IconData icon;
  final Color color;

  const _ActivityItem({
    required this.title,
    required this.score,
    required this.time,
    required this.icon,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      child: Row(
        children: [
          Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              color: color.withOpacity(0.1),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Icon(icon, size: 20, color: color),
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
                  time,
                  style: GoogleFonts.inter(
                    fontSize: 12,
                    color: AppColors.textSub,
                  ),
                ),
              ],
            ),
          ),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
            decoration: BoxDecoration(
              color: color.withOpacity(0.1),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Text(
              score,
              style: GoogleFonts.inter(
                fontSize: 12,
                fontWeight: FontWeight.w700,
                color: color,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// ── Classes Tab ─────────────────────────────────────────----
class _ClassesTab extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    final appState = context.watch<AppState>();
    final classrooms = appState.userClassrooms;
    final allSessions = appState.recentSessions;
    
    return RefreshIndicator(
      onRefresh: () => appState.loadUserData(),
      child: ListView(
        padding: const EdgeInsets.all(16).copyWith(bottom: 32),
        children: [
          _SectionHeader('Mes classes'),
          const SizedBox(height: 10),
          if (classrooms.isEmpty)
            Container(
              padding: const EdgeInsets.all(32),
              width: double.infinity,
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: AppColors.border, width: 0.5),
              ),
              child: Column(
                children: [
                  Icon(LucideIcons.users, size: 48, color: AppColors.textSub.withOpacity(0.3)),
                  const SizedBox(height: 16),
                  Text(
                    'Vos classes apparaîtront ici automatiquement.',
                    style: GoogleFonts.inter(fontSize: 14, color: AppColors.textSub, fontWeight: FontWeight.w600),
                    textAlign: TextAlign.center,
                  ),
                ],
              ),
            )
          else
            ...classrooms.map((classroom) {
              final classSessions = allSessions.where((s) => s['classroom_id']?.toString() == classroom.id).toList();
              return _ClassCard(
                name: classroom.name,
                description: '${classroom.teacherName} · ${classroom.totalStudents} élèves',
                progress: 0.0,
                sessions: classSessions,
                onTap: () {},
              );
            }),
        ],
      ),
    );
  }
}

// ── Class Card ─────────────────────────────────────────----
class _ClassCard extends StatelessWidget {
  final String name;
  final String description;
  final double progress;
  final List<Map<String, dynamic>> sessions;
  final VoidCallback onTap;
  
  const _ClassCard({
    required this.name,
    required this.description,
    required this.progress,
    this.sessions = const [],
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        margin: const EdgeInsets.only(bottom: 12),
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: AppColors.success.withOpacity(0.3), width: 1),
          boxShadow: [
            BoxShadow(
              color: AppColors.success.withOpacity(0.05),
              blurRadius: 10,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: AppColors.success.withOpacity(0.15),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: const Icon(
                    LucideIcons.users,
                    size: 22,
                    color: AppColors.success,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        name,
                        style: GoogleFonts.inter(
                          fontSize: 16,
                          fontWeight: FontWeight.w700,
                          color: AppColors.text,
                        ),
                      ),
                      Text(
                        description,
                        style: GoogleFonts.inter(
                          fontSize: 13,
                          color: AppColors.textSub,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            LinearProgressIndicator(
              value: progress,
              backgroundColor: AppColors.success.withOpacity(0.1),
              valueColor: AlwaysStoppedAnimation<Color>(AppColors.success),
              borderRadius: BorderRadius.circular(4),
              minHeight: 8,
            ),
            const SizedBox(height: 8),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  '${(progress * 100).toInt()}% complété',
                  style: GoogleFonts.inter(
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                    color: AppColors.success,
                  ),
                ),
                Text(
                  '12/16 leçons',
                  style: GoogleFonts.inter(
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                    color: AppColors.textSub,
                  ),
                ),
              ],
            ),
            if (sessions.isNotEmpty) ...[
              const SizedBox(height: 16),
              const Divider(),
              const SizedBox(height: 8),
              Text(
                'QSM Complétés',
                style: GoogleFonts.inter(
                  fontSize: 13,
                  fontWeight: FontWeight.w700,
                  color: AppColors.text,
                ),
              ),
              const SizedBox(height: 8),
              ...sessions.map((s) {
                final score = (s['score'] as int? ?? 0);
                final total = (s['total_questions'] as int? ?? 1);
                final percentage = (total > 0) ? (score * 100 ~/ total) : 0;
                final title = (s['courses'] as Map?)?['title'] as String? ?? 'QSM';
                
                Color scoreColor = AppColors.success;
                if (percentage < 50) scoreColor = AppColors.error;
                else if (percentage < 70) scoreColor = AppColors.info;

                return Padding(
                  padding: const EdgeInsets.only(bottom: 6.0),
                  child: Row(
                    children: [
                      Icon(LucideIcons.fileText, size: 14, color: AppColors.textSub),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          title,
                          style: GoogleFonts.inter(
                            fontSize: 12,
                            color: AppColors.textSub,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                        decoration: BoxDecoration(
                          color: scoreColor.withOpacity(0.1),
                          borderRadius: BorderRadius.circular(6),
                        ),
                        child: Text(
                          '$percentage%',
                          style: GoogleFonts.inter(
                            fontSize: 11,
                            fontWeight: FontWeight.w700,
                            color: scoreColor,
                          ),
                        ),
                      ),
                    ],
                  ),
                );
              }),
            ]
          ],
        ),
      ),
    );
  }
}

// ── Rooms Tab ─────────────────────────────────────────----
class _RoomsTab extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    final state = context.watch<AppState>();
    
    // Filtrer les sessions récentes qui ont un room_id (donc qui viennent d'un room)
    final roomSessions = state.recentSessions.where((s) => s['room_id'] != null).toList();
    
    final List<Map<String, dynamic>> rooms = roomSessions.map((s) {
      final courseMap = s['courses'] as Map?;
      final title = courseMap?['title'] as String? ?? 'Room Session';
      final subject = courseMap?['subject'] as String? ?? 'QSM';
      final score = s['score'] as int? ?? 0;
      final total = s['total_questions'] as int? ?? 1;
      final progress = total > 0 ? (score / total) : 0.0;
      
      final dateRaw = (s['completed_at'] != null 
          ? DateTime.tryParse(s['completed_at']) 
          : null) ?? (s['created_at'] != null
          ? DateTime.tryParse(s['created_at'])
          : null);
      
      String timeStr = 'À l\'instant';
      if (dateRaw != null) {
        final date = dateRaw.toLocal();
        final diff = DateTime.now().difference(date);
        
        if (diff.inDays > 7) {
          timeStr = '${date.day}/${date.month} à ${date.hour}h${date.minute.toString().padLeft(2, '0')}';
        } else if (diff.inDays > 0) {
          timeStr = 'Il y a ${diff.inDays}j';
        } else if (diff.inHours > 0) {
          timeStr = 'Il y a ${diff.inHours}h';
        } else if (diff.inMinutes > 0) {
          timeStr = 'Il y a ${diff.inMinutes}min';
        }
      }

      return {
        'code': 'Session',
        'title': title,
        'subject': subject,
        'teacher': '',
        'time': timeStr,
        'status': 'completed',
        'progress': progress,
        'color': progress >= 0.8 ? AppColors.success : (progress >= 0.5 ? AppColors.info : AppColors.error),
      };
    }).toList();

    return SingleChildScrollView(
      padding: const EdgeInsets.all(16).copyWith(bottom: 32),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _SectionHeader('Rooms disponibles'),
          const SizedBox(height: 12),
          
          // Join Room Section
          Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [AppColors.primary, AppColors.primary.withOpacity(0.8)],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              borderRadius: BorderRadius.circular(16),
              boxShadow: [
                BoxShadow(
                  color: AppColors.primary.withOpacity(0.2),
                  blurRadius: 10,
                  offset: const Offset(0, 4),
                ),
              ],
            ),
            child: Column(
              children: [
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: Colors.white.withOpacity(0.2),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: const Icon(
                        LucideIcons.plusCircle,
                        size: 24,
                        color: Colors.white,
                      ),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Rejoindre un Room',
                            style: GoogleFonts.inter(
                              fontSize: 18,
                              fontWeight: FontWeight.w700,
                              color: Colors.white,
                            ),
                          ),
                          Text(
                            'Entrez un code pour rejoindre un QSM en direct',
                            style: GoogleFonts.inter(
                              fontSize: 14,
                              color: Colors.white.withOpacity(0.9),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton.icon(
                    onPressed: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const RoomCodeScreen())),
                    icon: const Icon(LucideIcons.logIn, size: 16),
                    label: const Text('Rejoindre avec un code'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.white,
                      foregroundColor: AppColors.primary,
                      padding: const EdgeInsets.symmetric(vertical: 12),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 24),
          
          _SectionHeader('Rooms récents'),
          const SizedBox(height: 12),
          
          if (rooms.isEmpty)
            Container(
              padding: const EdgeInsets.all(24),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: AppColors.border, width: 0.5),
              ),
              child: Center(
                child: Column(
                  children: [
                    Icon(LucideIcons.history, size: 40, color: AppColors.textSub),
                    const SizedBox(height: 12),
                    Text('Aucun room récent',
                        style: GoogleFonts.inter(fontSize: 14, color: AppColors.textSub, fontWeight: FontWeight.w600)),
                  ],
                ),
              ),
            )
          else
            ...rooms.map((room) => _RoomCard(
              code: room['code'] as String,
              title: room['title'] as String,
              subject: room['subject'] as String,
              teacher: room['teacher'] as String,
              time: room['time'] as String,
              status: room['status'] as String,
              progress: room['progress'] as double,
              color: room['color'] as Color,
            )).toList(),
        ],
      ),
    );
  }
}

// ── Room Card ─────────────────────────────────────────----
class _RoomCard extends StatelessWidget {
  final String code;
  final String title;
  final String subject;
  final String teacher;
  final String time;
  final String status;
  final double progress;
  final Color color;

  const _RoomCard({
    required this.code,
    required this.title,
    required this.subject,
    required this.teacher,
    required this.time,
    required this.status,
    required this.progress,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
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
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: color.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Icon(
                    status == 'active' ? LucideIcons.play : 
                    status == 'completed' ? LucideIcons.checkCircle : 
                    LucideIcons.clock,
                    size: 20,
                    color: color,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        title,
                        style: GoogleFonts.inter(
                          fontSize: 16,
                          fontWeight: FontWeight.w700,
                          color: AppColors.text,
                        ),
                      ),
                      Text(
                        '$subject · $teacher',
                        style: GoogleFonts.inter(
                          fontSize: 12,
                          color: AppColors.textSub,
                        ),
                      ),
                    ],
                  ),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: color.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Text(
                    code,
                    style: GoogleFonts.inter(
                      fontSize: 11,
                      fontWeight: FontWeight.w700,
                      color: color,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                Expanded(
                  child: LinearProgressIndicator(
                    value: progress,
                    backgroundColor: AppColors.border,
                    valueColor: AlwaysStoppedAnimation<Color>(color),
                    minHeight: 6,
                  ),
                ),
                const SizedBox(width: 12),
                Text(
                  time,
                  style: GoogleFonts.inter(
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                    color: AppColors.textSub,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

// ── Library Tab ─────────────────────────────────────────----
class _LibraryTab extends StatefulWidget {
  @override
  _LibraryTabState createState() => _LibraryTabState();
}

class _LibraryTabState extends State<_LibraryTab> {
  int _selectedFiliere = 0;
  int _selectedLevel = 0;
  int _selectedSubject = 0;
  final Set<int> _expandedSemesters = {0};

  static const _subjectAliases = <String, List<String>>{
    'Sciences Vie': ['Sciences Vie', 'SVT', 'Biologie', 'sciences vie', 'svt'],
    'Physique-Chimie': ['Physique-Chimie', 'Physique', 'Chimie', 'physique-chimie', 'physique chimie'],
    'Maths': ['Maths', 'Mathématiques', 'maths', 'mathématiques'],
    'Français': ['Français', 'Francais', 'français', 'francais'],
    'Anglais': ['Anglais', 'anglais'],
    'Histoire-Géo': ['Histoire-Géo', 'Histoire', 'Géographie', 'histoire-géo'],
  };

  final List<Color> _fallbackColors = [
    AppColors.primary, AppColors.info, AppColors.success, 
    AppColors.warning, AppColors.error, Colors.purple
  ];

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final s = context.read<AppState>();
      if (!s.adminCoursesLoaded) s.loadAdminCourses();
      if (!s.filieresLoaded) s.loadFilieres();
      if (!s.niveauxLoaded) s.loadNiveaux();
      if (!s.matieresLoaded) s.loadMatieres();
    });
  }

  List<Map<String, dynamic>> _getFilteredCourses(List<Map<String, dynamic>> niveaux, List<Map<String, dynamic>> matieres) {
    if (niveaux.isEmpty || matieres.isEmpty) return [];
    
    // Safety check for indices
    if (_selectedLevel >= niveaux.length) _selectedLevel = 0;
    if (_selectedSubject >= matieres.length) _selectedSubject = 0;

    final level = (niveaux[_selectedLevel]['nom'] as String? ?? '').trim();
    final subject = (matieres[_selectedSubject]['nom'] as String? ?? '').trim();
    final aliases = _subjectAliases[subject] ?? [subject];

    final allCourses = context.read<AppState>().adminCourses;

    final filtered = allCourses.where((c) {
      final courseFiliere = (c['filiere'] as String? ?? '').trim();
      final courseSubject = (c['subject'] as String? ?? '').trim();
      
      final levelMatch = courseFiliere.isEmpty || courseFiliere == level || courseFiliere.contains(level) || level.contains(courseFiliere);
      final subjectMatch = aliases.any((alias) =>
          courseSubject.toLowerCase() == alias.toLowerCase());
          
      return levelMatch && subjectMatch;
    }).toList();

    return filtered;
  }

  List<Map<String, dynamic>> _getCurrentSemesters(List<Map<String, dynamic>> niveaux, List<Map<String, dynamic>> matieres) {
    final filtered = _getFilteredCourses(niveaux, matieres);

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
        'courses': allSem1,
      },
      {
        'title': 'Semestre 2',
        'courses': sem2Courses,
      },
    ];
  }

  @override
  Widget build(BuildContext context) {
    final state = context.watch<AppState>();
    final filieres = state.filieres;
    final niveaux = state.niveaux;
    final allMatieres = state.matieres;
    
    if (!state.filieresLoaded || !state.niveauxLoaded || !state.matieresLoaded || !state.adminCoursesLoaded) {
      return const Center(child: Padding(
        padding: EdgeInsets.all(40),
        child: CircularProgressIndicator(),
      ));
    }

    if (filieres.isEmpty) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(40),
          child: Text('Aucune filière disponible', style: GoogleFonts.inter(color: AppColors.textSub)),
        ),
      );
    }

    if (_selectedFiliere >= filieres.length) _selectedFiliere = 0;

    final selectedFiliereId = filieres[_selectedFiliere]['id']?.toString();
    final niveauxForFiliere = niveaux.where((n) => n['filiere_id']?.toString() == selectedFiliereId).toList();

    if (_selectedLevel >= niveauxForFiliere.length) _selectedLevel = 0;

    final selectedNiveauId = niveauxForFiliere.isNotEmpty ? niveauxForFiliere[_selectedLevel]['id']?.toString() : null;
    final matieres = allMatieres.where((m) => m['niveau_id']?.toString() == selectedNiveauId).toList();

    if (_selectedSubject >= matieres.length && matieres.isNotEmpty) _selectedSubject = 0;

    final semesters = _getCurrentSemesters(niveauxForFiliere, matieres);
    
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16).copyWith(bottom: 32),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _SectionHeader('Ma bibliothèque'),
          const SizedBox(height: 10),
          
          // Filière navigation
          Container(
            height: 40,
            child: ListView.builder(
              scrollDirection: Axis.horizontal,
              itemCount: filieres.length,
              itemBuilder: (context, index) {
                final isSelected = index == _selectedFiliere;
                final nom = filieres[index]['nom'] as String? ?? 'Filière';
                return Container(
                  margin: const EdgeInsets.only(right: 8),
                  child: Material(
                    color: Colors.transparent,
                    child: InkWell(
                      borderRadius: BorderRadius.circular(20),
                      onTap: () => setState(() {
                        _selectedFiliere = index;
                        _selectedLevel = 0;
                        _selectedSubject = 0;
                      }),
                      child: AnimatedContainer(
                        duration: const Duration(milliseconds: 200),
                        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                        decoration: BoxDecoration(
                          color: isSelected ? AppColors.primary : AppColors.background,
                          borderRadius: BorderRadius.circular(20),
                          border: Border.all(
                            color: isSelected ? AppColors.primary : AppColors.border,
                            width: 1,
                          ),
                        ),
                        child: Center(
                          child: Text(
                            nom,
                            style: GoogleFonts.inter(
                              fontSize: 12,
                              fontWeight: FontWeight.w700,
                              color: isSelected ? Colors.white : AppColors.textSub,
                            ),
                          ),
                        ),
                      ),
                    ),
                  ),
                );
              },
            ),
          ),
          const SizedBox(height: 10),
          
          // Level navigation
          if (niveauxForFiliere.isNotEmpty) ...[
            Container(
              height: 36,
              child: ListView.builder(
                scrollDirection: Axis.horizontal,
                itemCount: niveauxForFiliere.length,
                itemBuilder: (context, index) {
                  final isSelected = index == _selectedLevel;
                  final nom = niveauxForFiliere[index]['nom'] as String? ?? 'Niveau';
                  return Container(
                    margin: const EdgeInsets.only(right: 8),
                    child: Material(
                      color: Colors.transparent,
                      child: InkWell(
                        borderRadius: BorderRadius.circular(18),
                        onTap: () => setState(() {
                          _selectedLevel = index;
                          _selectedSubject = 0;
                        }),
                        child: AnimatedContainer(
                          duration: const Duration(milliseconds: 200),
                          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
                          decoration: BoxDecoration(
                            color: isSelected ? AppColors.primary.withOpacity(0.1) : Colors.transparent,
                            borderRadius: BorderRadius.circular(8),
                            border: Border.all(
                              color: isSelected ? AppColors.primary : AppColors.border,
                              width: 1,
                            ),
                          ),
                          child: Center(
                            child: Text(
                              nom,
                              style: GoogleFonts.inter(
                                fontSize: 12,
                                fontWeight: FontWeight.w600,
                                color: isSelected ? AppColors.primary : AppColors.textSub,
                              ),
                            ),
                          ),
                        ),
                      ),
                    ),
                  );
                },
              ),
            ),
            const SizedBox(height: 14),
          ],
          
          // Subject chips
          Container(
            height: 40,
            child: ListView.builder(
              scrollDirection: Axis.horizontal,
              itemCount: matieres.length,
              itemBuilder: (context, index) {
                final isSelected = index == _selectedSubject;
                final matiere = matieres[index];
                final label = matiere['nom'] as String? ?? 'Matière';
                // Pick a color for the subject
                final subjectColor = _fallbackColors[index % _fallbackColors.length];
                
                return Container(
                  margin: const EdgeInsets.only(right: 8),
                  child: Material(
                    color: Colors.transparent,
                    child: InkWell(
                      borderRadius: BorderRadius.circular(20),
                      onTap: () => setState(() => _selectedSubject = index),
                      child: AnimatedContainer(
                        duration: const Duration(milliseconds: 200),
                        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                        decoration: BoxDecoration(
                          color: isSelected ? subjectColor : AppColors.background,
                          borderRadius: BorderRadius.circular(20),
                          border: Border.all(
                            color: isSelected ? subjectColor : AppColors.border,
                            width: 1,
                          ),
                        ),
                        child: Center(
                          child: Text(
                            label,
                            style: GoogleFonts.inter(
                              fontSize: 12,
                              fontWeight: FontWeight.w700,
                              color: isSelected ? Colors.white : AppColors.textSecondary,
                            ),
                          ),
                        ),
                      ),
                    ),
                  ),
                );
              },
            ),
          ),
          const SizedBox(height: 20),
          
          // Semesters list
          ...semesters.asMap().entries.map((entry) {
            final index = entry.key;
            final semester = entry.value;
            final title = semester['title'] as String;
            final courses = semester['courses'] as List<Map<String, dynamic>>;
            final isExpanded = _expandedSemesters.contains(index);
            
            return Container(
              margin: const EdgeInsets.only(bottom: 10),
              decoration: BoxDecoration(
                color: Colors.white,
                border: Border.all(color: AppColors.border, width: 0.8),
                borderRadius: BorderRadius.circular(14),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Header
                  InkWell(
                    onTap: () => setState(() {
                      isExpanded ? _expandedSemesters.remove(index) : _expandedSemesters.add(index);
                    }),
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
                            '${courses.length} leçons',
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

                  // Courses list
                  AnimatedSize(
                    duration: const Duration(milliseconds: 280),
                    curve: Curves.easeInOut,
                    child: isExpanded
                        ? Padding(
                            padding: const EdgeInsets.fromLTRB(12, 0, 12, 16),
                            child: courses.isEmpty 
                              ? Padding(
                                  padding: const EdgeInsets.symmetric(vertical: 24),
                                  child: Center(
                                    child: Text('Aucun cours disponible', style: GoogleFonts.inter(color: AppColors.textSub)),
                                  ),
                                )
                              : GridView.builder(
                                  shrinkWrap: true,
                                  physics: const NeverScrollableScrollPhysics(),
                                  gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                                    crossAxisCount: 2,
                                    mainAxisSpacing: 12,
                                    crossAxisSpacing: 12,
                                    childAspectRatio: 1.2,
                                  ),
                                  itemCount: courses.length,
                                  itemBuilder: (context, i) {
                                    final course = courses[i];
                                    return _FolderCard(title: course['title'] as String? ?? 'Sans titre');
                                  },
                                ),
                          )
                        : const SizedBox.shrink(),
                  ),
                ],
              ),
            );
          }).toList(),
        ],
      ),
    );
  }
}

// ── Folder Card ─────────────────────────────────────────----
class _FolderCard extends StatelessWidget {
  final String title;
  
  const _FolderCard({required this.title});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Ouverture de: $title'),
            backgroundColor: AppColors.success,
          ),
        );
      },
      child: Container(
        decoration: BoxDecoration(
          color: const Color(0xFFF5F5F5),
          borderRadius: BorderRadius.circular(14),
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Image.asset(
              'assets/images/image.png',
              width: 80,
              height: 80,
            ),
            const SizedBox(height: 8),
            Text(
              title,
              style: GoogleFonts.inter(
                fontSize: 12,
                fontWeight: FontWeight.w600,
                color: AppColors.text,
              ),
              textAlign: TextAlign.center,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
            ),
          ],
        ),
      ),
    );
  }
}

// ── Section Header ─────────────────────────────────--------
class _SectionHeader extends StatelessWidget {
  final String title;
  final String? action;
  final VoidCallback? onAction;
  
  const _SectionHeader(this.title, {this.action, this.onAction});

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Text(
          title,
          style: GoogleFonts.nunito(fontSize: 14, fontWeight: FontWeight.w800, color: AppColors.text),
        ),
        if (action != null) ...[
          const Spacer(),
          GestureDetector(
            onTap: onAction,
            child: Text(
              action!,
              style: GoogleFonts.nunito(fontSize: 12, fontWeight: FontWeight.w700, color: AppColors.primary)),
          ),
        ],
      ],
    );
  }
}

// ── Simple Stat Card ─────────────────────────────────----
class _SimpleStatCard extends StatelessWidget {
  final String label;
  final String value;
  final IconData icon;
  final Color color;
  
  const _SimpleStatCard({
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
        border: Border.all(color: color.withOpacity(0.3), width: 0.5),
      ),
      child: Column(
        children: [
          Icon(icon, size: 24, color: color),
          const SizedBox(height: 8),
          Text(
            value,
            style: GoogleFonts.inter(
              fontSize: 16,
              fontWeight: FontWeight.w700,
              color: color,
            ),
          ),
          Text(
            label,
            style: GoogleFonts.inter(
              fontSize: 11,
              color: color.withOpacity(0.8),
            ),
          ),
        ],
      ),
    );
  }
}

// ── Simple Quick Action ─────────────────────────────────----
class _SimpleQuickAction extends StatelessWidget {
  final IconData icon;
  final String label;
  final String sub;
  final Color color;
  final VoidCallback onTap;
  
  const _SimpleQuickAction({
    required this.icon,
    required this.label,
    required this.sub,
    required this.color,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        decoration: BoxDecoration(
          color: color.withOpacity(0.1),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: color.withOpacity(0.3), width: 0.5),
        ),
        child: Padding(
          padding: const EdgeInsets.all(12),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(icon, size: 24, color: color),
              const SizedBox(height: 8),
              Text(
                label,
                style: GoogleFonts.inter(
                  fontSize: 12,
                  fontWeight: FontWeight.w700,
                  color: color,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 4),
              Text(
                sub,
                style: GoogleFonts.inter(
                  fontSize: 10,
                  color: color.withOpacity(0.7),
                ),
                textAlign: TextAlign.center,
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// ── Helper functions ─────────────────────────────────----
void _createStaticQsm(BuildContext context) {
  final appState = context.read<AppState>();
  
  // Créer des questions statiques pour le QSM
  final questions = [
    Question(
      id: '1',
      question: 'Quelle est la capitale de la France ?',
      options: ['Londres', 'Berlin', 'Paris', 'Madrid'],
      correctIndex: 2,
      explication: 'Paris est la capitale de la France depuis 987.',
    ),
    Question(
      id: '2',
      question: 'Combien font 5 + 3 ?',
      options: ['6', '7', '8', '9'],
      correctIndex: 2,
      explication: '5 + 3 = 8.',
    ),
    Question(
      id: '3',
      question: 'Quel est le plus grand océan du monde ?',
      options: ['Atlantique', 'Indien', 'Arctique', 'Pacifique'],
      correctIndex: 3,
      explication: 'L\'océan Pacifique est le plus grand océan du monde.',
    ),
    Question(
      id: '4',
      question: 'Qui a écrit "Les Misérables" ?',
      options: ['Victor Hugo', 'Émile Zola', 'Marcel Proust', 'Albert Camus'],
      correctIndex: 0,
      explication: 'Victor Hugo a écrit "Les Misérables" en 1862.',
    ),
    Question(
      id: '5',
      question: 'Quelle est la formule chimique de l\'eau ?',
      options: ['CO2', 'H2O', 'O2', 'N2'],
      correctIndex: 1,
      explication: 'La formule chimique de l\'eau est H2O (2 atomes d\'hydrogène, 1 atome d\'oxygène).',
    ),
  ];

  // Créer la session QSM
  final session = QsmSession(
    id: 'static-qsm-${DateTime.now().millisecondsSinceEpoch}',
    courseTitle: 'QSM Général - Test de connaissances',
    questions: questions,
    createdAt: DateTime.now(),
    userAnswers: List.filled(questions.length, null),
    timerMinutes: 30,
    allowBackNavigation: true,
    showResultsImmediately: false,
  );

  // Définir la session dans l'état de l'application
  appState.setCurrentSession(session);
  
  // Debug pour vérifier la session
  print('Session QSM créée: ${session.courseTitle}');
  print('Nombre de questions: ${session.questions.length}');
  print('Session ID: ${session.id}');
}
