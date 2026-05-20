import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:lucide_icons/lucide_icons.dart';
import 'package:provider/provider.dart';
import 'package:fl_chart/fl_chart.dart';
import '../theme/app_theme.dart';
import '../models/user.dart' as app_user;
import '../services/app_state.dart';
import 'admin_course_management.dart';
import 'admin_structure_management.dart';
import 'admin_parents_management.dart';
import 'admin_classes_management.dart';
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
    SkwNavItem(icon: LucideIcons.layout, label: 'Structure'),
    SkwNavItem(icon: LucideIcons.heart, label: 'Parents'),
    SkwNavItem(icon: LucideIcons.graduationCap, label: 'Classes'),
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: SkwiltiTopNav(
        title: ['Skwilti Admin', 'Utilisateurs', 'Bibliothèque', 'Structure', 'Parents', 'Classes'][_idx],
        showLogo: true,
        showNotifications: true,
        onProfileTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const ProfileScreen())),
      ),
      body: IndexedStack(index: _idx, children: [
        _StatsTab(),
        _UsersTab(),
        _CoursesTab(),
        _StructureTab(),
        _ParentsTab(),
        _ClassesTab(),
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
      s.loadFilieres();
      s.loadNiveaux();
      s.loadMatieres();
      s.loadAdminParents();
      s.loadClassesScolaires();
      s.loadNotifications();

      if (s.currentUser != null) {
        s.subscribeToTeacherNotifications(s.currentUser!.id);
        s.onNewNotification = (title, body) {
          if (!mounted) return;
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(title, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13)),
                  const SizedBox(height: 2),
                  Text(body, style: const TextStyle(fontSize: 11)),
                ],
              ),
              backgroundColor: AppColors.error,
              behavior: SnackBarBehavior.floating,
              duration: const Duration(seconds: 4),
            ),
          );
        };
      }
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
      (LucideIcons.fileText, '${globalStats?.totalQsmCreated ?? '--'}', 'QSM créés', AppColors.info, globalStats?.overallCompletionRate ?? 0.0),
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
        // Graphe d'activité de la semaine interactif et moderne
        Container(
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            color: Colors.white, borderRadius: BorderRadius.circular(16),
            border: Border.all(color: AppColors.border, width: 0.5),
            boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.04), blurRadius: 8, offset: const Offset(0, 2))],
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Activité de la semaine',
                        style: GoogleFonts.nunito(fontSize: 16, fontWeight: FontWeight.w800, color: AppColors.text),
                      ),
                      Text(
                        'Volume cumulé des actions de la plateforme',
                        style: GoogleFonts.nunito(fontSize: 11, color: AppColors.textSub),
                      ),
                    ],
                  ),
                  const Spacer(),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    decoration: BoxDecoration(
                      color: AppColors.primary.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Text(
                      'Live 7j',
                      style: GoogleFonts.nunito(
                        fontSize: 10,
                        fontWeight: FontWeight.w800,
                        color: AppColors.primary,
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 24),
              if (!loaded)
                const SizedBox(
                  height: 160,
                  child: Center(child: CircularProgressIndicator()),
                )
              else
                SizedBox(
                  height: 160,
                  child: BarChart(
                    BarChartData(
                      alignment: BarChartAlignment.spaceAround,
                      maxY: maxActivity > 0 ? (maxActivity * 1.25).ceilToDouble() : 5,
                      barTouchData: BarTouchData(
                        touchTooltipData: BarTouchTooltipData(
                          getTooltipColor: (_) => AppColors.text.withOpacity(0.95),
                          tooltipBorderRadius: BorderRadius.circular(8),
                          tooltipPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                          getTooltipItem: (group, groupIndex, rod, rodIndex) {
                            final value = rod.toY.round();
                            final today = DateTime.now();
                            final targetDate = today.subtract(Duration(days: 6 - groupIndex));
                            final dayLabel = ['Lundi','Mardi','Mercredi','Jeudi','Vendredi','Samedi','Dimanche'][targetDate.weekday - 1];
                            return BarTooltipItem(
                              '$dayLabel\n',
                              GoogleFonts.nunito(
                                color: Colors.white,
                                fontWeight: FontWeight.w800,
                                fontSize: 11,
                              ),
                              children: [
                                TextSpan(
                                  text: '$value actions',
                                  style: GoogleFonts.nunito(
                                    color: AppColors.primary2,
                                    fontWeight: FontWeight.w900,
                                    fontSize: 13,
                                  ),
                                ),
                              ],
                            );
                          },
                        ),
                      ),
                      titlesData: FlTitlesData(
                        show: true,
                        bottomTitles: AxisTitles(
                          sideTitles: SideTitles(
                            showTitles: true,
                            getTitlesWidget: (value, meta) {
                              final index = value.toInt();
                              if (index >= 0 && index < 7) {
                                final today = DateTime.now();
                                final targetDate = today.subtract(Duration(days: 6 - index));
                                final isToday = targetDate.day == today.day && targetDate.month == today.month && targetDate.year == today.year;
                                final label = ['Lu','Ma','Me','Je','Ve','Sa','Di'][targetDate.weekday - 1];
                                return Padding(
                                  padding: const EdgeInsets.only(top: 8),
                                  child: Text(
                                    label,
                                    style: GoogleFonts.nunito(
                                      fontSize: 11,
                                      fontWeight: isToday ? FontWeight.w900 : FontWeight.w700,
                                      color: isToday ? AppColors.primary : AppColors.textSub,
                                    ),
                                  ),
                                );
                              }
                              return const Text('');
                            },
                          ),
                        ),
                        leftTitles: AxisTitles(
                          sideTitles: SideTitles(
                            showTitles: true,
                            reservedSize: 24,
                            getTitlesWidget: (value, meta) {
                              if (value == meta.max) return const Text('');
                              return Text(
                                '${value.toInt()}',
                                style: GoogleFonts.nunito(
                                  fontSize: 10,
                                  fontWeight: FontWeight.w700,
                                  color: AppColors.textSub,
                                ),
                              );
                            },
                          ),
                        ),
                        topTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                        rightTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                      ),
                      gridData: FlGridData(
                        show: true,
                        drawVerticalLine: false,
                        getDrawingHorizontalLine: (value) => FlLine(
                          color: AppColors.border,
                          strokeWidth: 0.8,
                          dashArray: [4, 4],
                        ),
                      ),
                      borderData: FlBorderData(show: false),
                      barGroups: [
                        for (int i = 0; i < 7; i++)
                          BarChartGroupData(
                            x: i,
                            barRods: [
                              BarChartRodData(
                                toY: (activity[i] ?? 0).toDouble(),
                                gradient: const LinearGradient(
                                  colors: [AppColors.primary, AppColors.primary2],
                                  begin: Alignment.bottomCenter,
                                  end: Alignment.topCenter,
                                ),
                                width: 14,
                                borderRadius: BorderRadius.circular(4),
                                backDrawRodData: BackgroundBarChartRodData(
                                  show: true,
                                  toY: maxActivity > 0 ? (maxActivity * 1.25).ceilToDouble() : 5,
                                  color: AppColors.border.withOpacity(0.3),
                                ),
                              ),
                            ],
                          ),
                      ],
                    ),
                  ),
                ),
            ],
          ),
        ),
        const SizedBox(height: 20),
        // Grid des stats réelles
        if (loaded)
          GridView.count(
            crossAxisCount: 2, shrinkWrap: true, physics: const NeverScrollableScrollPhysics(),
            crossAxisSpacing: 12, mainAxisSpacing: 12, childAspectRatio: 1.35,
            children: stats.map((s) => Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: AppColors.border, width: 0.5),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.03),
                    blurRadius: 10,
                    offset: const Offset(0, 4),
                  ),
                ],
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Container(
                        width: 34,
                        height: 34,
                        decoration: BoxDecoration(
                          color: s.$4.withOpacity(0.1),
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: Icon(s.$1, size: 16, color: s.$4),
                      ),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                        decoration: BoxDecoration(
                          color: s.$4.withOpacity(0.08),
                          borderRadius: BorderRadius.circular(6),
                        ),
                        child: Text(
                          '${(s.$5 * 100).round()}%',
                          style: GoogleFonts.nunito(
                            fontSize: 10,
                            fontWeight: FontWeight.w800,
                            color: s.$4,
                          ),
                        ),
                      ),
                    ],
                  ),
                  const Spacer(),
                  Text(
                    s.$2,
                    style: GoogleFonts.nunito(
                      fontSize: 26,
                      fontWeight: FontWeight.w900,
                      color: AppColors.text,
                    ),
                  ),
                  Text(
                    s.$3,
                    style: GoogleFonts.nunito(
                      fontSize: 12,
                      fontWeight: FontWeight.w700,
                      color: AppColors.textSub,
                    ),
                  ),
                  const SizedBox(height: 8),
                  ClipRRect(
                    borderRadius: BorderRadius.circular(3),
                    child: LinearProgressIndicator(
                      value: s.$5.clamp(0.0, 1.0),
                      minHeight: 4,
                      backgroundColor: AppColors.border,
                      valueColor: AlwaysStoppedAnimation(s.$4),
                    ),
                  ),
                ],
              ),
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

class _StructureTab extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return const AdminStructureManagementScreen();
  }
}

class _ParentsTab extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return const AdminParentsManagementScreen();
  }
}

class _ClassesTab extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return const AdminClassesManagementScreen();
  }
}

class _UsersTab extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Center(child: Text('Users Tab Placeholder'));
  }
}

class _CoursesTab extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Center(child: Text('Courses Tab Placeholder'));
  }
}
