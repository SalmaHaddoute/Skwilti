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
class _HomeTab extends StatelessWidget {
  final User? user;
  const _HomeTab({this.user});

  @override
  Widget build(BuildContext context) {
    final state = context.watch<AppState>();
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
                      Text('Bonjour ${user?.firstName ?? ''} ',
                          style: GoogleFonts.nunito(fontSize: 20, fontWeight: FontWeight.w800, color: Colors.white)),
                      const SizedBox(height: 4),
                      Text('Prêt à apprendre aujourd\'hui ?',
                          style: GoogleFonts.nunito(fontSize: 13, color: Colors.white.withOpacity(0.85))),
                      const SizedBox(height: 16),
                      _StudentLevelChip(user: user),
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
                      width: 80,
                      height: 80,
                      fit: BoxFit.cover,
                      errorBuilder: (context, error, stackTrace) {
                        return const Icon(LucideIcons.graduationCap, color: Colors.white, size: 40);
                      },
                    ),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 20),
          
                    
          // Progress Curves Section
          _SectionHeader('Progression'),
          const SizedBox(height: 12),
          
          // Performance Curve
          Container(
            padding: const EdgeInsets.all(20),
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
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: AppColors.primary.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: const Icon(
                        LucideIcons.trendingUp,
                        size: 20,
                        color: AppColors.primary,
                      ),
                    ),
                    const SizedBox(width: 12),
                    Text(
                      'Performance cette semaine',
                      style: GoogleFonts.inter(
                        fontSize: 16,
                        fontWeight: FontWeight.w700,
                        color: AppColors.text,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                SizedBox(
                  height: 120,
                  child: _PerformanceCurve(),
                ),
                ],
            ),
          ),
          const SizedBox(height: 20),
          
          // Stats Summary Row
          Row(
            children: [
              Expanded(child: _SimpleStatCard(label: 'Meilleur score', value: '92%', icon: LucideIcons.trophy, color: AppColors.success)),
              const SizedBox(width: 10),
              Expanded(child: _SimpleStatCard(label: 'Moyenne', value: '78%', icon: LucideIcons.barChart2, color: AppColors.primary)),
              const SizedBox(width: 10),
              Expanded(child: _SimpleStatCard(label: 'Amélioration', value: '+12%', icon: LucideIcons.trendingUp, color: AppColors.info)),
            ],
          ),
          const SizedBox(height: 20),
          
          // QSM récents
          _SectionHeader('QSM récents'),
          const SizedBox(height: 10),
          // Créer un QSM statique pour démonstration
          _RecentQsmCard(
            title: 'Test de Mathématiques',
            score: 85,
            date: DateTime.now().subtract(const Duration(hours: 2)),
            onTap: () => _createStaticQsm(context),
          ),
          _RecentQsmCard(
            title: 'Physique - Mécanique',
            score: 78,
            date: DateTime.now().subtract(const Duration(days: 1)),
            onTap: () => _createStaticQsm(context),
          ),
          _RecentQsmCard(
            title: 'Français - Grammaire',
            score: 92,
            date: DateTime.now().subtract(const Duration(days: 2)),
            onTap: () => _createStaticQsm(context),
          ),
          
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
  @override
  Widget build(BuildContext context) {
    // Données de performance pour la courbe
    final data = [
      {'day': 'Lun', 'score': 65},
      {'day': 'Mar', 'score': 72},
      {'day': 'Mer', 'score': 78},
      {'day': 'Jeu', 'score': 85},
      {'day': 'Ven', 'score': 82},
      {'day': 'Sam', 'score': 90},
      {'day': 'Dim', 'score': 88},
    ];

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
    final activities = [
      {
        'title': 'QSM Mathématiques',
        'score': '85%',
        'time': 'Il y a 2h',
        'icon': LucideIcons.calculator,
        'color': AppColors.primary,
      },
      {
        'title': 'QSM Physique',
        'score': '92%',
        'time': 'Il y a 5h',
        'icon': LucideIcons.atom,
        'color': AppColors.info,
      },
      {
        'title': 'QSM Chimie',
        'score': '78%',
        'time': 'Hier',
        'icon': LucideIcons.beaker,
        'color': AppColors.success,
      },
    ];

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
    final classrooms = context.watch<AppState>().userClassrooms;
    
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16).copyWith(bottom: 32),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _SectionHeader('Mes classes'),
          const SizedBox(height: 10),
          // Classes par défaut si aucune classe n'est disponible
          if (classrooms.isEmpty) ...[
            _ClassCard(
              name: 'Mathématiques 1AC',
              description: 'Prof: M. Dupont · 28 élèves',
              progress: 0.85,
              onTap: () {
                // Navigation vers la classe de mathématiques
              },
            ),
            _ClassCard(
              name: 'Physique-Chimie 2AC',
              description: 'Prof: Mme. Martin · 32 élèves',
              progress: 0.72,
              onTap: () {
                // Navigation vers la classe de physique-chimie
              },
            ),
          ],
          // Classes de l'utilisateur
          ...classrooms.map((classroom) => _ClassCard(
            name: classroom.name,
            description: '${classroom.name} · ${classroom.id} élèves',
            progress: 0.75,
            onTap: () {
              // Navigation vers la classe
            },
          )),
          const SizedBox(height: 20),
          ElevatedButton.icon(
            onPressed: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const JoinClassScreen())),
            icon: const Icon(LucideIcons.plus, size: 16),
            label: const Text('Rejoindre une classe'),
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.primary,
              foregroundColor: Colors.white,
            ),
          ),
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
  final VoidCallback onTap;
  
  const _ClassCard({
    required this.name,
    required this.description,
    required this.progress,
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
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: AppColors.border, width: 0.5),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: AppColors.primary.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: const Icon(
                    LucideIcons.users,
                    size: 20,
                    color: AppColors.primary,
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
                          fontSize: 14,
                          fontWeight: FontWeight.w700,
                          color: AppColors.text,
                        ),
                      ),
                      Text(
                        description,
                        style: GoogleFonts.inter(
                          fontSize: 12,
                          color: AppColors.textSub,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            LinearProgressIndicator(
              value: progress,
              backgroundColor: AppColors.border,
              valueColor: AlwaysStoppedAnimation<Color>(AppColors.primary),
              minHeight: 6,
            ),
            const SizedBox(height: 8),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  '${(progress * 100).toInt()}% complété',
                  style: GoogleFonts.inter(
                    fontSize: 11,
                    fontWeight: FontWeight.w600,
                    color: AppColors.textSub,
                  ),
                ),
                Text(
                  '12/16 leçons',
                  style: GoogleFonts.inter(
                    fontSize: 11,
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

// ── Rooms Tab ─────────────────────────────────────────----
class _RoomsTab extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    final rooms = [
      {
        'code': 'SKW-4821',
        'title': 'QSM Mathématiques',
        'subject': 'Mathématiques',
        'teacher': 'M. Dupont',
        'time': '15 min',
        'status': 'active',
        'progress': 0.6,
        'color': AppColors.primary,
      },
      {
        'code': 'SKW-3742',
        'title': 'QSM Physique',
        'subject': 'Physique',
        'teacher': 'Mme. Martin',
        'time': '20 min',
        'status': 'completed',
        'progress': 1.0,
        'color': AppColors.success,
      },
      {
        'code': 'SKW-9284',
        'title': 'QSM Chimie',
        'subject': 'Chimie',
        'teacher': 'M. Bernard',
        'time': '25 min',
        'status': 'waiting',
        'progress': 0.0,
        'color': AppColors.warning,
      },
    ];

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
          
          // Rooms List
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
  int _selectedLevel = 0;
  int _selectedSubject = 0;
  final Set<int> _expandedSemesters = {};

  static const _levels = [
    '1AC', '2AC', '3AC', 'TCS', '1BAC SM', '1BAC EXP', '2BAC',
  ];

  static const _subjects = [
    {'label': 'Mathématiques', 'color': AppColors.primary},
    {'label': 'Physique', 'color': AppColors.info},
    {'label': 'Chimie', 'color': AppColors.success},
    {'label': 'SVT', 'color': AppColors.warning},
  ];

  @override
  Widget build(BuildContext context) {
    final courses = [
      'Algèbre', 'Géométrie', 'Fonctions', 'Statistiques',
      'Mécanique', 'Électricité', 'Optique', 'Thermodynamique',
    ];
    
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16).copyWith(bottom: 32),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _SectionHeader('Ma bibliothèque'),
          const SizedBox(height: 10),
          
          // Level navigation
          Container(
            height: 40,
            child: ListView.builder(
              scrollDirection: Axis.horizontal,
              itemCount: _levels.length,
              itemBuilder: (context, index) {
                final isSelected = index == _selectedLevel;
                return Container(
                  margin: const EdgeInsets.only(right: 8),
                  child: Material(
                    color: Colors.transparent,
                    child: InkWell(
                      borderRadius: BorderRadius.circular(20),
                      onTap: () => setState(() => _selectedLevel = index),
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
                            _levels[index],
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
          const SizedBox(height: 14),
          
          // Subject chips
          Container(
            height: 40,
            child: ListView.builder(
              scrollDirection: Axis.horizontal,
              itemCount: _subjects.length,
              itemBuilder: (context, index) {
                final isSelected = index == _selectedSubject;
                final subject = _subjects[index];
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
                          color: isSelected ? subject['color'] as Color : AppColors.background,
                          borderRadius: BorderRadius.circular(20),
                          border: Border.all(
                            color: isSelected ? subject['color'] as Color : AppColors.border,
                            width: 1,
                          ),
                        ),
                        child: Center(
                          child: Text(
                            subject['label'] as String,
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
          ...List.generate(2, (index) {
            final semesterTitle = 'Semestre ${index + 1}';
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
                            semesterTitle,
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
                            child: GridView.builder(
                              shrinkWrap: true,
                              physics: const NeverScrollableScrollPhysics(),
                              gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                                crossAxisCount: 2,
                                mainAxisSpacing: 12,
                                crossAxisSpacing: 12,
                                childAspectRatio: 1.2,
                              ),
                              itemCount: courses.length,
                              itemBuilder: (context, i) => _FolderCard(title: courses[i]),
                            ),
                          )
                        : const SizedBox.shrink(),
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
