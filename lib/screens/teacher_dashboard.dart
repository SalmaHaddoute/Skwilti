import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:lucide_icons/lucide_icons.dart';
import 'package:provider/provider.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:supabase_flutter/supabase_flutter.dart' as sb;
import '../theme/app_theme.dart';
import '../services/app_state.dart';
import '../services/webhook_service.dart';
import '../models/user.dart' as app_user;
import '../widgets/common_widgets.dart';
import '../widgets/skwilti_nav.dart';
import '../widgets/modern_floating_button.dart';
import '../widgets/astronaut_illustration.dart';
import '../widgets/empty_state.dart';
import 'create_classroom_screen.dart';
import 'create_room_screen.dart';
import 'upload_screen.dart';
import 'lesson_upload_screen.dart';
import 'profile_screen.dart';
import 'course_detail_screen.dart';
import '../models/room.dart';
import '../models/classroom.dart';

class TeacherDashboard extends StatefulWidget {
  const TeacherDashboard({super.key});
  @override
  State<TeacherDashboard> createState() => _TeacherDashboardState();
}

class _TeacherDashboardState extends State<TeacherDashboard> {
  int _currentIndex = 0;
  AppState? _appState;

  final _navItems = const [
    SkwNavItem(icon: LucideIcons.home, activeIcon: LucideIcons.home, label: 'Accueil'),
    SkwNavItem(icon: LucideIcons.users, label: 'Classes'),
    SkwNavItem(icon: LucideIcons.layers, label: 'Rooms'),
    SkwNavItem(icon: LucideIcons.barChart2, label: 'Notes'),
    SkwNavItem(icon: LucideIcons.bookOpen, label: 'Mes cours'),
    SkwNavItem(icon: LucideIcons.helpCircle, label: 'Mes QSM'),
    SkwNavItem(icon: LucideIcons.library, label: 'Bibliothèque'),
  ];

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final appState = context.read<AppState>();
      _appState = appState;
      final teacherId = appState.currentUser?.id;
      if (teacherId != null && teacherId.isNotEmpty) {
        appState.subscribeToTeacherNotifications(teacherId);
        appState.onNewNotification = (title, body) {
          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                duration: const Duration(seconds: 5),
                backgroundColor: const Color(0xFF1A1F36),
                behavior: SnackBarBehavior.floating,
                margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                content: Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: AppColors.success.withOpacity(0.2),
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: const Icon(LucideIcons.userCheck, color: AppColors.success, size: 22),
                    ),
                    const SizedBox(width: 14),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Text(title, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w700, fontSize: 14)),
                          Text(body, style: const TextStyle(color: Colors.white70, fontSize: 12), maxLines: 2, overflow: TextOverflow.ellipsis),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            );
          }
        };
      }
    });
  }

  @override
  void dispose() {
    _appState?.unsubscribeFromNotifications();
    if (_appState != null) _appState!.onNewNotification = null;
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final user = context.watch<AppState>().currentUser;
    return Scaffold(
      backgroundColor: Colors.transparent,
      appBar: SkwiltiTopNav(
        title: _getTitle(),
        showLogo: _currentIndex == 0,
        showNotifications: true,
        profileIllustration: 'assets/images/teacher-illustration.webp',
        onProfileTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const ProfileScreen())),
      ),
      body: IndexedStack(
        index: _currentIndex,
        children: [
          _HomeTab(user: user, onNavigate: (i) => setState(() => _currentIndex = i)),
          _ClassesTab(),
          _RoomsTab(),
          _NotesTab(),
          _MyCoursesTab(onNavigateToLibrary: () => setState(() => _currentIndex = 6)),
          _QuizzesTab(),
          _LibraryTab(),
        ],
      ),
      bottomNavigationBar: SkwiltiBottomNav(
        currentIndex: _currentIndex,
        onTap: (i) => setState(() => _currentIndex = i),
        items: _navItems,
      ),
      floatingActionButton: _currentIndex == 0 ? ModernFloatingButton_Create(
        onPressed: _showCreateOptions,
      ) : null,
    );
  }

  String _getTitle() {
    switch (_currentIndex) {
      case 0: return 'Skwilti';
      case 1: return 'Mes Classes';
      case 2: return 'Rooms';
      case 3: return 'Notes';
      case 4: return 'Mes cours';
      case 5: return 'Mes QSM';
      default: return 'Skwilti';
    }
  }

  void _showCreateOptions() {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (_) => _CreateOptionsSheet(
        onUpload: () { Navigator.pop(context); setState(() => _currentIndex = 6); },
        onClassroom: () { Navigator.pop(context); Navigator.push(context, MaterialPageRoute(builder: (_) => const CreateClassroomScreen())); },
        onRoom: () { Navigator.pop(context); Navigator.push(context, MaterialPageRoute(builder: (_) => const CreateRoomScreen())); },
        onQsm: () { Navigator.pop(context); Navigator.push(context, MaterialPageRoute(builder: (_) => const UploadScreen())); },
      ),
    );
  }
}

// ── Home Tab ─────────────────────────────────────────────────
class _HomeTab extends StatefulWidget {
  final app_user.User? user;
  final Function(int) onNavigate;
  const _HomeTab({this.user, required this.onNavigate});
  @override
  State<_HomeTab> createState() => _HomeTabState();
}

class _HomeTabState extends State<_HomeTab> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<AppState>().loadTeacherCourses();
    });
  }

  static Color _getActivityColor(int val, int maxVal) {
    if (val <= 0) return AppColors.border;
    final pct = maxVal > 0 ? (val * 100 ~/ maxVal) : 0;
    if (pct >= 80) return AppColors.success;
    if (pct >= 50) return AppColors.primary;
    return AppColors.warning;
  }

  Future<void> _testN8n() async {
    final scaffoldMessenger = ScaffoldMessenger.of(context);
    try {
      final user = context.read<AppState>().currentUser;
      if (user == null) {
        scaffoldMessenger.showSnackBar(const SnackBar(content: Text('Utilisateur non connecté')));
        return;
      }

      scaffoldMessenger.showSnackBar(const SnackBar(content: Text('Connexion à n8n... Sélectionnez un PDF.')));
      
      final result = await WebhookService().processPdfUpload(
        title: 'Test n8n ${DateTime.now().toLocal()}',
        teacherId: user.id,
        nombreQuestions: 5,
        difficulte: 'moyen',
      );

      if (result != null && result['success'] == true) {
        scaffoldMessenger.showSnackBar(
          const SnackBar(
            content: Text('✅ Connexion n8n réussie ! QCM en cours de génération.'),
            backgroundColor: AppColors.success,
          ),
        );
      } else {
        scaffoldMessenger.showSnackBar(
          SnackBar(
            content: Text('❌ Échec n8n: ${result?['error'] ?? 'Inconnu'}'),
            backgroundColor: AppColors.error,
          ),
        );
      }
    } catch (e) {
      scaffoldMessenger.showSnackBar(SnackBar(content: Text('Erreur: $e'), backgroundColor: AppColors.error));
    }
  }

  @override
  Widget build(BuildContext context) {
    final stats      = context.watch<AppState>().userStats;
    final classrooms = context.watch<AppState>().userClassrooms;
    final courses    = context.watch<AppState>().teacherCourses;
    final activity   = context.watch<AppState>().weeklyActivity;
    final loaded     = context.watch<AppState>().teacherCoursesLoaded;

    // Calcul des stats depuis les données réelles
    final now = DateTime.now();
    final startOfWeek = now.subtract(Duration(days: now.weekday - 1));
    final coursesThisWeek = courses.where((c) {
      final dt = c['created_at'] != null ? DateTime.tryParse(c['created_at']) : null;
      return dt != null && dt.isAfter(startOfWeek);
    }).length;

    final dayLabels = ['Lu', 'Ma', 'Me', 'Je', 'Ve', 'Sa', 'Di'];
    final Map<int, List<int>> byDay = {};
    for (int i = 0; i < 7; i++) {
      final val = activity[i] ?? 0;
      if (val > 0) byDay[i] = [val];
    }
    final weekScores = List.generate(7, (i) => activity[i] ?? 0);
    final maxVal = weekScores.fold(1, (a, b) => a > b ? a : b);

    return SingleChildScrollView(
      padding: const EdgeInsets.all(16).copyWith(bottom: 24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // ── Welcome card ──────────────────────────────────────
          Stack(
            children: [
              const AstronautBackground(
                type: AstronautType.welcome,
                alignment: Alignment.bottomRight,
                opacity: 0.12,
                scale: 0.6,
              ),
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
                              style: GoogleFonts.inter(fontSize: 20, fontWeight: FontWeight.w800, color: Colors.white)),
                          const SizedBox(height: 4),
                          Text('Prêt à créer des QSM aujourd\'hui ?',
                              style: GoogleFonts.inter(fontSize: 13, color: Colors.white.withOpacity(0.85))),
                          const SizedBox(height: 16),
                          _SubscriptionChip(user: widget.user),
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
                          'assets/images/teacher-illustration.webp',
                          width: 80, height: 80, fit: BoxFit.cover,
                          errorBuilder: (_, __, ___) =>
                              const Icon(LucideIcons.graduationCap, color: Colors.white, size: 40),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),

          // ── 4 KPI cards (style parent) ────────────────────────
          Row(children: [
            Expanded(child: _TeacherKpiCard(
              icon: LucideIcons.fileText,
              label: 'Cours',
              value: '${courses.length}',
              color: AppColors.primary,
              sub: 'Total uploadés',
            )),
            const SizedBox(width: 12),
            Expanded(child: _TeacherKpiCard(
              icon: LucideIcons.users,
              label: 'Classes',
              value: '${classrooms.length}',
              color: AppColors.green,
              sub: 'Actives',
            )),
          ]),
          const SizedBox(height: 12),
          Row(children: [
            Expanded(child: _TeacherKpiCard(
              icon: LucideIcons.award,
              label: 'Points',
              value: '${stats?.totalPoints ?? 0}',
              color: const Color(0xFFFF8C00),
              sub: 'Accumulés',
            )),
            const SizedBox(width: 12),
            Expanded(child: _TeacherKpiCard(
              icon: LucideIcons.calendarCheck,
              label: 'Cette semaine',
              value: '$coursesThisWeek',
              color: const Color(0xFF7B1FA2),
              sub: 'Cours ajoutés',
            )),
          ]),
          const SizedBox(height: 24),

          // ── Activité de la semaine (style parent) ─────────────
          Text('Activité de la semaine',
              style: GoogleFonts.inter(fontSize: 14, fontWeight: FontWeight.w800, color: AppColors.text)),
          const SizedBox(height: 12),
          Container(
            padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: AppColors.border),
              boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.04), blurRadius: 12, offset: const Offset(0, 4))],
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('QSM créés par jour',
                    style: GoogleFonts.inter(fontSize: 13, fontWeight: FontWeight.w600, color: AppColors.text)),
                const SizedBox(height: 16),
                SizedBox(
                  height: 120,
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: [
                      for (int i = 0; i < 7; i++) ...[
                        if (i > 0) const SizedBox(width: 8),
                        Expanded(child: Column(
                          mainAxisAlignment: MainAxisAlignment.end,
                          children: [
                            if (weekScores[i] > 0)
                              Text('${weekScores[i]}',
                                  style: GoogleFonts.nunito(
                                      fontSize: 9, fontWeight: FontWeight.w800,
                                      color: _getActivityColor(weekScores[i], maxVal))),
                            const SizedBox(height: 2),
                            AnimatedContainer(
                              duration: const Duration(milliseconds: 500),
                              height: weekScores[i] > 0
                                  ? (80 * weekScores[i] / maxVal).clamp(2.0, 80.0)
                                  : 3.0,
                              decoration: BoxDecoration(
                                color: _getActivityColor(weekScores[i], maxVal),
                                borderRadius: const BorderRadius.vertical(top: Radius.circular(6)),
                              ),
                            ),
                            const SizedBox(height: 6),
                            Text(dayLabels[i],
                                style: GoogleFonts.inter(
                                    fontSize: 10, fontWeight: FontWeight.w600, color: AppColors.textSub)),
                          ],
                        )),
                      ],
                    ],
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 24),

          // ── Dernier cours uploadé ─────────────────────────────
          if (loaded && courses.isNotEmpty) ...[
            Text('Dernier cours',
                style: GoogleFonts.inter(fontSize: 14, fontWeight: FontWeight.w800, color: AppColors.text)),
            const SizedBox(height: 10),
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: AppColors.border),
                boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.04), blurRadius: 12, offset: const Offset(0, 4))],
              ),
              child: Row(
                children: [
                  Container(
                    width: 44, height: 44,
                    decoration: BoxDecoration(
                      color: AppColors.primary.withOpacity(0.12),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: const Icon(LucideIcons.fileText, color: AppColors.primary, size: 22),
                  ),
                  const SizedBox(width: 14),
                  Expanded(child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(courses.first['title'] as String? ?? 'Cours sans titre',
                          style: GoogleFonts.inter(fontSize: 14, fontWeight: FontWeight.w700, color: AppColors.text),
                          maxLines: 1, overflow: TextOverflow.ellipsis),
                      const SizedBox(height: 3),
                      Text(courses.first['subject'] as String? ?? '',
                          style: GoogleFonts.inter(fontSize: 12, color: AppColors.textSub)),
                    ],
                  )),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                    decoration: BoxDecoration(color: AppColors.success, borderRadius: BorderRadius.circular(10)),
                    child: Text('${courses.first['question_count'] ?? 0} Q',
                        style: GoogleFonts.inter(fontSize: 11, fontWeight: FontWeight.w700, color: Colors.white)),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 24),
          ] else if (!loaded) ...[
            const Center(child: Padding(padding: EdgeInsets.all(16), child: CircularProgressIndicator())),
            const SizedBox(height: 24),
          ],

          // ── Actions rapides ───────────────────────────────────
          Text('Actions rapides',
              style: GoogleFonts.inter(fontSize: 14, fontWeight: FontWeight.w800, color: AppColors.text)),
          const SizedBox(height: 10),
          GridView.count(
            crossAxisCount: 2,
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            crossAxisSpacing: 10,
            mainAxisSpacing: 10,
            childAspectRatio: 1.8,
            children: [
              _QuickAction(icon: LucideIcons.fileText, label: 'Créer QSM', sub: 'Questions/Réponses', color: AppColors.primary,
                  onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const UploadScreen()))),
              _QuickAction(icon: LucideIcons.upload, label: 'Uploader cours', sub: 'PDF, DOCX', color: AppColors.warning,
                  onTap: () => widget.onNavigate(6)),
            ],
          ),
          const SizedBox(height: 24),

          // ── Cours récents ─────────────────────────────────────
          Row(children: [
            Text('Cours récents',
                style: GoogleFonts.inter(fontSize: 14, fontWeight: FontWeight.w800, color: AppColors.text)),
            const Spacer(),
            GestureDetector(
              onTap: () => widget.onNavigate(4),
              child: Text('Voir tout',
                  style: GoogleFonts.inter(fontSize: 12, fontWeight: FontWeight.w700, color: AppColors.primary)),
            ),
          ]),
          const SizedBox(height: 10),
          if (!loaded)
            const Center(child: CircularProgressIndicator())
          else if (courses.isEmpty)
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: Colors.white, borderRadius: BorderRadius.circular(12),
                border: Border.all(color: AppColors.border, width: 0.5),
              ),
              child: Column(children: [
                AstronautIllustration(type: AstronautType.learning, width: 60, height: 60, showAnimation: true),
                const SizedBox(height: 12),
                Text('Aucun cours uploadé',
                    style: GoogleFonts.inter(fontSize: 14, fontWeight: FontWeight.w700, color: AppColors.text)),
                const SizedBox(height: 4),
                Text('Cliquez sur "Créer" pour uploader votre premier cours !',
                    style: GoogleFonts.inter(fontSize: 12, color: AppColors.textSub), textAlign: TextAlign.center),
              ]),
            )
          else
            ...courses.take(3).map((course) => _UploadedCourseTile(
              title: course['title'] as String? ?? 'Sans titre',
              fileName: course['file_name'] as String? ?? '',
              filiere: course['description'] as String? ?? '',
              subject: course['subject'] as String? ?? '',
              uploadedAt: course['created_at'] as String? ?? DateTime.now().toIso8601String(),
            )),
        ],
      ),
    );
  }
}

// ── Uploaded Course Tile ───────────────────────────────────────
class _UploadedCourseTile extends StatelessWidget {
  final String title;
  final String fileName;
  final String filiere;
  final String subject;
  final String uploadedAt;
  final bool isDefault;
  
  const _UploadedCourseTile({
    required this.title,
    required this.fileName,
    required this.filiere,
    required this.subject,
    required this.uploadedAt,
    this.isDefault = false,
  });

  @override
  Widget build(BuildContext context) {
    final uploadDate = DateTime.parse(uploadedAt);
    final formattedDate = '${uploadDate.day}/${uploadDate.month}/${uploadDate.year}';
    
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: isDefault ? AppColors.primary.withOpacity(0.5) : AppColors.border, width: isDefault ? 1.5 : 0.5),
      ),
      child: Row(
        children: [
          // Image ou icône du fichier
          Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              color: isDefault ? AppColors.primary.withOpacity(0.1) : AppColors.success.withOpacity(0.1),
              borderRadius: BorderRadius.circular(8),
            ),
            child: ClipRRect(
              borderRadius: BorderRadius.circular(8),
              child: isDefault 
                  ? Image.asset(
                      'assets/images/image.png',
                      fit: BoxFit.cover,
                      errorBuilder: (context, error, stackTrace) {
                        return Container(
                          width: double.infinity,
                          height: double.infinity,
                          decoration: BoxDecoration(
                            color: AppColors.primary.withOpacity(0.1),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: const Icon(
                            LucideIcons.fileText,
                            size: 20,
                            color: AppColors.primary,
                          ),
                        );
                      },
                    )
                  : const Icon(
                      LucideIcons.fileText,
                      size: 20,
                      color: AppColors.success,
                    ),
            ),
          ),
          const SizedBox(width: 12),
          
          // Informations du cours
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Expanded(
                      child: Text(
                        title,
                        style: GoogleFonts.inter(
                          fontSize: 15,
                          fontWeight: FontWeight.w900,
                          color: isDefault ? AppColors.primary : AppColors.text,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                    if (isDefault) ...[
                      const SizedBox(width: 8),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                        decoration: BoxDecoration(
                          color: AppColors.primary,
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Text(
                          'Par défaut',
                          style: GoogleFonts.inter(
                            fontSize: 8,
                            fontWeight: FontWeight.w600,
                            color: Colors.white,
                          ),
                        ),
                      ),
                    ],
                  ],
                ),
                const SizedBox(height: 4),
                Text(
                  fileName,
                  style: GoogleFonts.inter(
                    fontSize: 11,
                    color: AppColors.textSub,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 4),
                 Wrap(
                  spacing: 6,
                  runSpacing: 4,
                  children: [
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                      decoration: BoxDecoration(
                        color: AppColors.primary.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Text(
                        filiere,
                        style: GoogleFonts.inter(
                          fontSize: 9,
                          fontWeight: FontWeight.w600,
                          color: AppColors.primary,
                        ),
                      ),
                    ),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                      decoration: BoxDecoration(
                        color: AppColors.info.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Text(
                        subject,
                        style: GoogleFonts.inter(
                          fontSize: 9,
                          fontWeight: FontWeight.w600,
                          color: AppColors.info,
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
          
          // Date d'upload
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text(
                formattedDate,
                style: GoogleFonts.inter(
                  fontSize: 10,
                  color: AppColors.textSub,
                ),
              ),
              const SizedBox(height: 4),
              const Icon(
                LucideIcons.checkCircle,
                size: 16,
                color: AppColors.success,
              ),
            ],
          ),
        ],
      ),
    );
  }
}

// ── Teacher KPI Card (style parent) ──────────────────────────
class _TeacherKpiCard extends StatelessWidget {
  final IconData icon;
  final String label, value, sub;
  final Color color;
  const _TeacherKpiCard({
    required this.icon, required this.label, required this.value,
    required this.color, required this.sub,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: color.withOpacity(0.2)),
        boxShadow: [
          BoxShadow(color: color.withOpacity(0.08), blurRadius: 12, offset: const Offset(0, 4))
        ],
      ),
      child: Row(children: [
        Container(
          width: 44, height: 44,
          decoration: BoxDecoration(color: color.withOpacity(0.12), borderRadius: BorderRadius.circular(12)),
          child: Icon(icon, color: color, size: 22),
        ),
        const SizedBox(width: 12),
        Expanded(child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(value, style: GoogleFonts.inter(fontSize: 22, fontWeight: FontWeight.w900, color: color)),
            Text(label, style: GoogleFonts.inter(fontSize: 11, fontWeight: FontWeight.w600, color: AppColors.text)),
            Text(sub, style: GoogleFonts.inter(fontSize: 10, color: AppColors.textSub)),
          ],
        )),
      ]),
    );
  }
}

class _SubscriptionChip extends StatelessWidget {
  final app_user.User? user;
  const _SubscriptionChip({this.user});

  @override
  Widget build(BuildContext context) {
    final isPremium = user?.subscription == app_user.SubscriptionType.premium;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.2),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(isPremium ? LucideIcons.award : LucideIcons.zap, size: 12, color: Colors.white),
          const SizedBox(width: 5),
          Text(
            isPremium ? 'Premium — QSM illimités' : 'Gratuit — 1 QSM/jour',
            style: GoogleFonts.nunito(fontSize: 11, fontWeight: FontWeight.w700, color: Colors.white),
          ),
        ],
      ),
    );
  }
}

class _StatCard extends StatelessWidget {
  final String label, value;
  final IconData icon;
  final Color color;
  const _StatCard({required this.label, required this.value, required this.icon, required this.color});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.03),
            blurRadius: 10,
            offset: const Offset(0, 2),
          ),
        ],
        border: Border.all(color: AppColors.border.withOpacity(0.5), width: 1),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Container(
                width: 36, height: 36,
                decoration: BoxDecoration(color: color.withOpacity(0.12), borderRadius: BorderRadius.circular(10)),
                child: Icon(icon, size: 18, color: color),
              ),
              Expanded(
                child: Text(
                  value, 
                  textAlign: TextAlign.right,
                  style: GoogleFonts.nunito(fontSize: 22, fontWeight: FontWeight.w800, color: color),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Text(label, style: GoogleFonts.nunito(fontSize: 12, color: AppColors.textSub, fontWeight: FontWeight.w700)),
        ],
      ),
    );
  }
}

class _QuickAction extends StatelessWidget {
  final IconData icon;
  final String label, sub;
  final Color color;
  final VoidCallback? onTap;
  const _QuickAction({required this.icon, required this.label, required this.sub, required this.color, this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: AppColors.border, width: 0.5),
        ),
        child: Row(
          children: [
            Container(
              width: 36, height: 36,
              decoration: BoxDecoration(color: color.withOpacity(0.12), borderRadius: BorderRadius.circular(10)),
              child: Icon(icon, size: 18, color: color),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(label, style: GoogleFonts.nunito(fontSize: 12, fontWeight: FontWeight.w900, color: AppColors.text)),
                  Text(sub, style: GoogleFonts.nunito(fontSize: 10, fontWeight: FontWeight.w700, color: AppColors.textSub)),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _CourseListTile extends StatelessWidget {
  final String title, subtitle;
  final double progress;
  const _CourseListTile({required this.title, required this.subtitle, required this.progress});

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.border, width: 0.5),
      ),
      child: Row(
        children: [
          Container(
            width: 40, height: 40,
            decoration: BoxDecoration(color: AppColors.primaryLight, borderRadius: BorderRadius.circular(10)),
            child: const Icon(LucideIcons.bookOpen, size: 20, color: AppColors.primary),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(title, style: GoogleFonts.nunito(fontSize: 13, fontWeight: FontWeight.w700, color: AppColors.text)),
                Text(subtitle, style: GoogleFonts.nunito(fontSize: 11, color: AppColors.textSub)),
                const SizedBox(height: 6),
                ClipRRect(
                  borderRadius: BorderRadius.circular(4),
                  child: LinearProgressIndicator(
                    value: progress,
                    backgroundColor: AppColors.border,
                    valueColor: const AlwaysStoppedAnimation(AppColors.primary),
                    minHeight: 4,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 10),
          Text(
            '${(progress * 100).round()}%',
            style: GoogleFonts.nunito(fontSize: 13, fontWeight: FontWeight.w800, color: AppColors.primary),
          ),
        ],
      ),
    );
  }
}

// ── Classes Tab ───────────────────────────────────────────────
class _ClassesTab extends StatefulWidget {
  @override
  State<_ClassesTab> createState() => _ClassesTabState();
}

class _ClassesTabState extends State<_ClassesTab> {
  Map<String, List<Map<String, dynamic>>> _classroomStudents = {};
  bool _isLoadingStudents = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _loadData();
    });
  }

  Future<void> _loadData() async {
    setState(() => _isLoadingStudents = true);
    final appState = context.read<AppState>();
    
    // Load classrooms first if needed (should be already loaded in AppState)
    final classrooms = appState.userClassrooms;
    
    Map<String, List<Map<String, dynamic>>> tempStudents = {};
    
    for (var classroom in classrooms) {
      final students = await appState.fetchClassroomStudents(
        classroom.id, 
        schoolClassId: classroom.classeScolaireId
      );
      tempStudents[classroom.id] = students;
    }
    
    if (mounted) {
      setState(() {
        _classroomStudents = tempStudents;
        _isLoadingStudents = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final classrooms = context.watch<AppState>().userClassrooms;

    return RefreshIndicator(
      onRefresh: _loadData,
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        physics: const AlwaysScrollableScrollPhysics(),
        child: Column(
          children: [
            if (classrooms.isEmpty)
              EmptyStateCard(
                margin: const EdgeInsets.only(bottom: 16),
                emptyState: EmptyStateClasses(
                  action: ElevatedButton.icon(
                    onPressed: () async {
                      final result = await Navigator.push(context, MaterialPageRoute(builder: (_) => const CreateClassroomScreen()));
                      if (result != null) _loadData();
                    },
                    icon: const Icon(LucideIcons.plus, size: 16),
                    label: const Text('Créer une classe'),
                    style: ElevatedButton.styleFrom(backgroundColor: AppColors.primary, foregroundColor: Colors.white),
                  ),
                ),
              )
            else
              ...classrooms.map((c) {
                final classStudents = _classroomStudents[c.id] ?? [];
                
                return Padding(
                  padding: const EdgeInsets.only(bottom: 12),
                  child: _buildClassCard(context, c, classStudents, AppColors.green),
                );
              }),
            ElevatedButton.icon(
              onPressed: () async {
                final result = await Navigator.push(context, MaterialPageRoute(builder: (_) => const CreateClassroomScreen()));
                if (result != null) {
                  _loadData();
                }
              },
              icon: const Icon(LucideIcons.plus, size: 16),
              label: const Text('Créer une nouvelle classe'),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildClassCard(BuildContext context, Classroom classroom, List<Map<String, dynamic>> students, Color color) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: AppColors.border, width: 0.5),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.02),
            blurRadius: 6,
            offset: const Offset(0, 1),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header simple
          Row(
            children: [
              Container(
                width: 44,
                height: 44,
                decoration: BoxDecoration(
                  color: color.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Icon(LucideIcons.users, color: color, size: 22),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      classroom.name,
                      style: GoogleFonts.inter(
                        fontSize: 15,
                        fontWeight: FontWeight.w700,
                        color: AppColors.text,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      '${classroom.categoryDisplayName} • ${classroom.levelDisplayName}',
                      style: GoogleFonts.inter(
                        fontSize: 11,
                        fontWeight: FontWeight.w500,
                        color: AppColors.textSub,
                      ),
                    ),
                  ],
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(
                  color: color.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(6),
                ),
                child: Text(
                  '${students.length}',
                  style: GoogleFonts.inter(
                    fontSize: 12,
                    fontWeight: FontWeight.w700,
                    color: color,
                  ),
                ),
              ),
            ],
          ),
          
          const SizedBox(height: 12),
          
          // Code d'invitation
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            decoration: BoxDecoration(
              color: AppColors.background,
              borderRadius: BorderRadius.circular(8),
            ),
            child: Row(
              children: [
                const Icon(LucideIcons.key, size: 14, color: AppColors.textSub),
                const SizedBox(width: 6),
                Text(
                  classroom.inviteCode ?? 'N/A',
                  style: GoogleFonts.inter(
                    fontSize: 12,
                    fontWeight: FontWeight.w700,
                    color: AppColors.text,
                    letterSpacing: 1,
                  ),
                ),
                const Spacer(),
                InkWell(
                  onTap: () {
                    final code = classroom.inviteCode ?? '';
                    if (code.isNotEmpty) {
                      Clipboard.setData(ClipboardData(text: code));
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(
                          content: Row(
                            children: [
                              const Icon(LucideIcons.check, color: Colors.white, size: 16),
                              const SizedBox(width: 8),
                              Text('Code copié !', style: GoogleFonts.inter(fontWeight: FontWeight.w600, fontSize: 12)),
                            ],
                          ),
                          backgroundColor: AppColors.success,
                          behavior: SnackBarBehavior.floating,
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                          duration: const Duration(seconds: 2),
                        ),
                      );
                    }
                  },
                  child: Container(
                    padding: const EdgeInsets.all(6),
                    decoration: BoxDecoration(
                      color: color.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(6),
                    ),
                    child: Icon(LucideIcons.copy, size: 14, color: color),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSimpleStudentRow(String name, String init, Color color) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Row(
        children: [
          CircleAvatar(
            radius: 18,
            backgroundColor: color.withOpacity(0.15),
            child: Text(
              init,
              style: GoogleFonts.inter(
                fontSize: 14,
                fontWeight: FontWeight.w800,
                color: color,
              ),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              name,
              style: GoogleFonts.inter(
                fontSize: 14,
                fontWeight: FontWeight.w600,
                color: AppColors.text,
              ),
            ),
          ),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
            decoration: BoxDecoration(
              color: AppColors.background,
              borderRadius: BorderRadius.circular(6),
            ),
            child: Text(
              'N/A',
              style: GoogleFonts.inter(
                fontSize: 11,
                fontWeight: FontWeight.w600,
                color: AppColors.textSub,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _QuickStat({
    required String label,
    required String value,
    required IconData icon,
    required Color color,
  }) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: color.withOpacity(0.08),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: color.withOpacity(0.2), width: 0.5),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(icon, size: 14, color: color),
              const SizedBox(width: 4),
              Text(
                label,
                style: GoogleFonts.inter(
                  fontSize: 10,
                  fontWeight: FontWeight.w600,
                  color: AppColors.textSub,
                ),
              ),
            ],
          ),
          const SizedBox(height: 4),
          Text(
            value,
            style: GoogleFonts.inter(
              fontSize: 14,
              fontWeight: FontWeight.w700,
              color: color,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCourseRow(Map<String, dynamic> course, Color color) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: InkWell(
        onTap: () {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (_) => CourseDetailScreen(
                course: course,
                canEdit: true,
              ),
            ),
          );
        },
        borderRadius: BorderRadius.circular(10),
        child: Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: color.withOpacity(0.05),
            borderRadius: BorderRadius.circular(10),
            border: Border.all(color: color.withOpacity(0.2), width: 1),
          ),
          child: Row(
            children: [
              Container(
                width: 40,
                height: 40,
                decoration: BoxDecoration(
                  color: color.withOpacity(0.15),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Icon(LucideIcons.fileText, size: 18, color: color),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      course['title'] as String? ?? 'Sans titre',
                      style: GoogleFonts.inter(
                        fontSize: 13,
                        fontWeight: FontWeight.w700,
                        color: AppColors.text,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 2),
                    Text(
                      course['subject'] as String? ?? 'Matière',
                      style: GoogleFonts.inter(
                        fontSize: 11,
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
                  borderRadius: BorderRadius.circular(6),
                ),
                child: Text(
                  '${course['question_count'] ?? 0}Q',
                  style: GoogleFonts.inter(
                    fontSize: 10,
                    fontWeight: FontWeight.w700,
                    color: color,
                  ),
                ),
              ),
              const SizedBox(width: 8),
              Icon(LucideIcons.chevronRight, size: 16, color: AppColors.textSub),
            ],
          ),
        ),
      ),
    );
  }
}

// ── Rooms Tab ─────────────────────────────────────────────────
class _RoomsTab extends StatefulWidget {
  @override
  State<_RoomsTab> createState() => _RoomsTabState();
}

class _RoomsTabState extends State<_RoomsTab> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<AppState>().loadTeacherCourses();
      context.read<AppState>().loadTeacherRooms();
    });
  }

  @override
  Widget build(BuildContext context) {
    final state = context.watch<AppState>();
    final rooms = state.userRooms;

    return RefreshIndicator(
      onRefresh: () => state.loadTeacherRooms(),
      child: SingleChildScrollView(
        physics: const AlwaysScrollableScrollPhysics(),
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: AppColors.primaryLight,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: AppColors.primary.withOpacity(0.2), width: 0.5),
              ),
              child: Row(
                children: [
                  const Icon(LucideIcons.info, size: 16, color: AppColors.primary),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      'Timer activé sur toutes les rooms actives. Les étudiants voient le compte à rebours.',
                      style: GoogleFonts.nunito(fontSize: 12, color: AppColors.primaryDark, fontWeight: FontWeight.w600),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 14),
            
            if (rooms.isEmpty)
              const EmptyStateCard(
                emptyState: EmptyStateRooms(),
              ),

            ...rooms.map((r) {
              // Trouver la classroom correspondante pour avoir le nombre total d'étudiants
              final classroom = state.userClassrooms.firstWhere(
                (c) => c.id == r.classroomId,
                orElse: () => Classroom(
                  id: '', name: '', teacherId: '', teacherName: '', 
                  category: CourseCategory.other, level: CourseLevel.middleSchool, 
                  createdAt: DateTime.now(), inviteCode: ''
                ),
              );
              
              return _RoomCard(
                name: r.name,
                code: r.roomCode ?? '----',
                participants: r.participantIds.length,
                totalStudents: classroom.totalStudents,
                timer: r.timerMinutes ?? 0,
                isLive: r.status == RoomStatus.active,
              );
            }),
            const SizedBox(height: 12),
            ElevatedButton.icon(
              onPressed: () async {
                await Navigator.push(context, MaterialPageRoute(builder: (_) => const CreateRoomScreen()));
                if (mounted) {
                  state.loadTeacherRooms();
                }
              },
              icon: const Icon(LucideIcons.plus, size: 16),
              label: const Text('Créer une nouvelle Room'),
              style: ElevatedButton.styleFrom(minimumSize: const Size.fromHeight(48)),
            ),
          ],
        ),
      ),
    );
  }
}

class _RoomCard extends StatelessWidget {
  final String name, code;
  final int participants, totalStudents, timer;
  final bool isLive;
  const _RoomCard({required this.name, required this.code, required this.participants, required this.totalStudents, required this.timer, required this.isLive});

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.03),
            blurRadius: 10,
            offset: const Offset(0, 2),
          ),
        ],
        border: Border.all(color: isLive ? AppColors.success.withOpacity(0.3) : AppColors.border, width: 1),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 10, height: 10,
                decoration: BoxDecoration(
                  color: isLive ? AppColors.success : AppColors.textSub, 
                  shape: BoxShape.circle,
                  boxShadow: isLive ? [BoxShadow(color: AppColors.success.withOpacity(0.4), blurRadius: 6)] : null,
                ),
              ),
              const SizedBox(width: 10),
              Expanded(child: Text(name.isNotEmpty ? name : 'Session QSM', style: GoogleFonts.nunito(fontSize: 15, fontWeight: FontWeight.w800, color: AppColors.text))),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(
                  color: isLive ? AppColors.success.withOpacity(0.1) : AppColors.background,
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Text(
                  isLive ? 'En cours' : 'Terminé',
                  style: GoogleFonts.nunito(fontSize: 11, fontWeight: FontWeight.w800, color: isLive ? AppColors.success : AppColors.textSub),
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),
          Row(
            children: [
              _RoomMeta(icon: LucideIcons.users, label: '$participants / $totalStudents élèves'),
              const SizedBox(width: 16),
              _RoomMeta(icon: LucideIcons.clock, label: timer > 0 ? '$timer min' : 'Illimité'),
              const Spacer(),
              InkWell(
                borderRadius: BorderRadius.circular(8),
                onTap: () {
                  Clipboard.setData(ClipboardData(text: 'https://skwilti.ma/room/$code'));
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('Lien de la room copié !'), duration: Duration(seconds: 2)),
                  );
                },
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                  decoration: BoxDecoration(
                    color: AppColors.primary.withOpacity(0.08),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Icon(LucideIcons.copy, size: 14, color: AppColors.primary),
                      const SizedBox(width: 6),
                      Text(code, style: GoogleFonts.nunito(fontSize: 12, fontWeight: FontWeight.w800, color: AppColors.primary, letterSpacing: 1)),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _RoomMeta extends StatelessWidget {
  final IconData icon;
  final String label;
  const _RoomMeta({required this.icon, required this.label});
  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Icon(icon, size: 13, color: AppColors.textSub),
        const SizedBox(width: 4),
        Text(label, style: GoogleFonts.nunito(fontSize: 11, color: AppColors.textSecondary)),
      ],
    );
  }
}

// ── Notes Tab ─────────────────────────────────────────────────
class _NotesTab extends StatefulWidget {
  @override
  _NotesTabState createState() => _NotesTabState();
}

class _NotesTabState extends State<_NotesTab> {
  int _selectedClass = 0;
  int _selectedRoom = 0;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _fetchInitialRoomSessions();
    });
  }

  void _fetchInitialRoomSessions() {
    final state = context.read<AppState>();
    final classrooms = state.userClassrooms;
    if (classrooms.isNotEmpty) {
      final currentClass = classrooms[_selectedClass];
      final roomsForClass = state.userRooms.where((r) => r.classroomId == currentClass.id).toList();
      if (roomsForClass.isNotEmpty) {
        state.loadRoomSessions(roomsForClass[_selectedRoom].id);
      }
    }
  }

  double _getAverageScore(List<Map<String, dynamic>> sessions) {
    if (sessions.isEmpty) return 0.0;
    final total = sessions.map((s) => (s['score'] as num?)?.toDouble() ?? 0.0).reduce((a, b) => a + b);
    return total / sessions.length;
  }

  int _getSuccessCount(List<Map<String, dynamic>> sessions) {
    return sessions.where((s) {
      final score = (s['score'] as num?)?.toDouble() ?? 0.0;
      final total = (s['total_questions'] as num?)?.toDouble() ?? 100.0;
      return (score / total) * 100 >= 80;
    }).length;
  }

  int _getDifficultyCount(List<Map<String, dynamic>> sessions) {
    return sessions.where((s) {
      final score = (s['score'] as num?)?.toDouble() ?? 0.0;
      final total = (s['total_questions'] as num?)?.toDouble() ?? 100.0;
      return (score / total) * 100 < 60;
    }).length;
  }

  @override
  Widget build(BuildContext context) {
    final state = context.watch<AppState>();
    final classrooms = state.userClassrooms;

    if (classrooms.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const SizedBox(height: 60),
            EmptyState(
              title: 'Aucune donnée disponible',
              subtitle: 'Les notes de vos étudiants apparaîtront ici une fois les QSM complétés.',
              astronautType: AstronautType.success,
            ),
          ],
        ),
      );
    }

    if (_selectedClass >= classrooms.length) _selectedClass = 0;
    final currentClass = classrooms[_selectedClass];
    final currentRooms = state.userRooms.where((r) => r.classroomId == currentClass.id).toList();

    if (_selectedRoom >= currentRooms.length) _selectedRoom = 0;
    
    final currentStudents = state.currentRoomSessions;
    final isLoading = !state.roomSessionsLoaded;
    
    return RefreshIndicator(
      onRefresh: () async {
        final state = context.read<AppState>();
        if (classrooms.isNotEmpty) {
          final currentClass = classrooms[_selectedClass];
          final roomsForClass = state.userRooms.where((r) => r.classroomId == currentClass.id).toList();
          if (roomsForClass.isNotEmpty && _selectedRoom < roomsForClass.length) {
            await state.loadRoomSessions(roomsForClass[_selectedRoom].id);
          }
        }
      },
      child: SingleChildScrollView(
        physics: const AlwaysScrollableScrollPhysics(),
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // ─── Header Banner ───────────────────────────────────────
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                gradient: const LinearGradient(
                  colors: [AppColors.primaryDark, AppColors.primary],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                borderRadius: BorderRadius.circular(20),
                boxShadow: [
                  BoxShadow(color: AppColors.primary.withOpacity(0.3), blurRadius: 16, offset: const Offset(0, 6)),
                ],
              ),
              child: Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(14),
                    decoration: BoxDecoration(color: Colors.white.withOpacity(0.15), borderRadius: BorderRadius.circular(16)),
                    child: const Icon(LucideIcons.graduationCap, color: Colors.white, size: 28),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Suivi des Évaluations',
                          style: GoogleFonts.nunito(fontSize: 22, fontWeight: FontWeight.w800, color: Colors.white),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          'Consultez en temps réel les performances et statistiques de vos classes.',
                          style: GoogleFonts.nunito(fontSize: 13, color: Colors.white.withOpacity(0.85)),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 28),
            
            // ─── Class Selector ─────────────────────────────────────
            Text(
              'Sélectionnez une classe',
              style: GoogleFonts.nunito(fontSize: 16, fontWeight: FontWeight.w800, color: AppColors.textSub),
            ),
            const SizedBox(height: 12),
            _buildClassSelector(classrooms),
            const SizedBox(height: 28),
            
            // ─── Room Selector ─────────────────────────────────────
            _buildRoomSelector(currentRooms),
            const SizedBox(height: 28),
            
            // ─── Stats Overview ────────────────────────────────────
            Text(
              'Vue d\'ensemble de l\'évaluation',
              style: GoogleFonts.nunito(fontSize: 18, fontWeight: FontWeight.w800, color: AppColors.text),
            ),
            const SizedBox(height: 14),
            Row(
              children: [
                Expanded(child: _StatCard(label: 'Moyenne générale', value: '${_getAverageScore(currentStudents).toInt()}%', icon: LucideIcons.barChart2, color: AppColors.primary)),
                const SizedBox(width: 14),
                Expanded(child: _StatCard(label: 'Taux de réussite', value: '${_getSuccessCount(currentStudents)}/${currentStudents.length}', icon: LucideIcons.checkCircle2, color: AppColors.success)),
                const SizedBox(width: 14),
                Expanded(child: _StatCard(label: 'À renforcer', value: '${_getDifficultyCount(currentStudents)}', icon: LucideIcons.alertTriangle, color: AppColors.warning)),
              ],
            ),
            const SizedBox(height: 32),
            
            // ─── Students List (Gradebook Style) ─────────────────────
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'Résultats détaillés des élèves',
                  style: GoogleFonts.nunito(fontSize: 18, fontWeight: FontWeight.w800, color: AppColors.text),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                  decoration: BoxDecoration(color: AppColors.background, borderRadius: BorderRadius.circular(20)),
                  child: Text('${currentStudents.length} copies', style: GoogleFonts.nunito(fontSize: 12, fontWeight: FontWeight.w700, color: AppColors.textSub)),
                ),
              ],
            ),
            const SizedBox(height: 16),
            
            // Students list
            if (isLoading)
              const Center(child: Padding(padding: EdgeInsets.all(32), child: CircularProgressIndicator()))
            else if (currentStudents.isEmpty)
              Container(
                padding: const EdgeInsets.all(32),
                alignment: Alignment.center,
                decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(20), border: Border.all(color: AppColors.border.withOpacity(0.5))),
                child: const EmptyStateResults(),
              )
            else
              ...currentStudents.asMap().entries.map((entry) {
                final index = entry.key;
                final student = entry.value;
                final profile = student['profiles'] as Map<String, dynamic>?;
                final firstName = profile?['first_name'] as String? ?? '';
                final lastName = profile?['last_name'] as String? ?? '';
                final name = '$firstName $lastName'.trim().isEmpty ? 'Élève Anonyme' : '$firstName $lastName';
                final initials = firstName.isNotEmpty ? firstName[0].toUpperCase() : '?';
                
                final scoreRaw = (student['score'] as num?)?.toDouble() ?? 0.0;
                final totalQ = (student['total_questions'] as num?)?.toDouble() ?? 100.0;
                final scorePct = (scoreRaw / totalQ) * 100;

                return Padding(
                  padding: const EdgeInsets.only(bottom: 12),
                  child: _StudentScoreCard(
                    rank: index + 1,
                    name: name,
                    initials: initials,
                    score: scorePct.toInt(),
                    room: currentRooms.isNotEmpty ? currentRooms[_selectedRoom].name : 'Évaluation',
                    time: student['completed_at'] != null 
                        ? '${DateTime.parse(student['completed_at']).toLocal().day}/${DateTime.parse(student['completed_at']).toLocal().month} à ${DateTime.parse(student['completed_at']).toLocal().hour}h${DateTime.parse(student['completed_at']).toLocal().minute.toString().padLeft(2, '0')}'
                        : 'N/A',
                  ),
                );
              }),
            const SizedBox(height: 28),
            
            // ─── Export Buttons ───────────────────────────────────
            Row(
              children: [
                Expanded(
                  child: ElevatedButton.icon(
                    onPressed: () {},
                    icon: const Icon(LucideIcons.fileSpreadsheet, size: 18),
                    label: Text('Exporter Excel', style: GoogleFonts.nunito(fontSize: 14, fontWeight: FontWeight.w700)),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.white,
                      foregroundColor: const Color(0xFF10793F), // Excel green
                      elevation: 0,
                      side: const BorderSide(color: Color(0xFF10793F)),
                      padding: const EdgeInsets.symmetric(vertical: 14),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                    ),
                  ),
                ),
                const SizedBox(width: 14),
                Expanded(
                  child: ElevatedButton.icon(
                    onPressed: () {},
                    icon: const Icon(LucideIcons.fileText, size: 18),
                    label: Text('Exporter PDF', style: GoogleFonts.nunito(fontSize: 14, fontWeight: FontWeight.w700)),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.white,
                      foregroundColor: AppColors.error, // PDF red
                      elevation: 0,
                      side: const BorderSide(color: AppColors.error),
                      padding: const EdgeInsets.symmetric(vertical: 14),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildClassSelector(List<Classroom> classrooms) {
    return SizedBox(
      height: 48,
      child: ListView.builder(
        scrollDirection: Axis.horizontal,
        itemCount: classrooms.length,
        itemBuilder: (context, index) {
          final isSelected = index == _selectedClass;
          return Container(
            margin: const EdgeInsets.only(right: 10),
            child: Material(
              color: Colors.transparent,
              child: InkWell(
                borderRadius: BorderRadius.circular(12),
                onTap: () {
                  setState(() {
                    _selectedClass = index;
                    _selectedRoom = 0;
                  });
                  final roomsForClass = context.read<AppState>().userRooms.where((r) => r.classroomId == classrooms[index].id).toList();
                  if (roomsForClass.isNotEmpty) {
                    context.read<AppState>().loadRoomSessions(roomsForClass[0].id);
                  } else {
                    context.read<AppState>().loadRoomSessions('dummy');
                  }
                },
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 200),
                  padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                  decoration: BoxDecoration(
                    color: isSelected ? AppColors.dark : Colors.white,
                    borderRadius: BorderRadius.circular(12),
                    boxShadow: isSelected ? [BoxShadow(color: AppColors.dark.withOpacity(0.3), blurRadius: 10, offset: const Offset(0, 4))] : [BoxShadow(color: Colors.black.withOpacity(0.02), blurRadius: 6)],
                    border: Border.all(color: isSelected ? AppColors.dark : AppColors.border.withOpacity(0.5), width: 1),
                  ),
                  child: Center(
                    child: Row(
                      children: [
                        Icon(LucideIcons.users, size: 16, color: isSelected ? Colors.white : AppColors.textSub),
                        const SizedBox(width: 8),
                        Text(
                          classrooms[index].name,
                          style: GoogleFonts.nunito(fontSize: 14, fontWeight: isSelected ? FontWeight.w800 : FontWeight.w700, color: isSelected ? Colors.white : AppColors.text),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _buildRoomSelector(List<Room> rooms) {
    if (rooms.isEmpty) return const SizedBox.shrink();
    
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Sessions d\'évaluation (Rooms)',
          style: GoogleFonts.nunito(fontSize: 18, fontWeight: FontWeight.w800, color: AppColors.text),
        ),
        const SizedBox(height: 14),
        SizedBox(
          height: 76,
          child: ListView.builder(
            scrollDirection: Axis.horizontal,
            itemCount: rooms.length,
            itemBuilder: (context, index) {
              final isSelected = index == _selectedRoom;
              final room = rooms[index];
              final dateStr = '${room.createdAt.day}/${room.createdAt.month} à ${room.createdAt.hour}h${room.createdAt.minute.toString().padLeft(2, '0')}';
              
              return Container(
                margin: const EdgeInsets.only(right: 14, bottom: 6),
                child: Material(
                  color: Colors.transparent,
                  child: InkWell(
                    borderRadius: BorderRadius.circular(16),
                    onTap: () {
                      setState(() => _selectedRoom = index);
                      context.read<AppState>().loadRoomSessions(room.id);
                    },
                    child: AnimatedContainer(
                      duration: const Duration(milliseconds: 250),
                      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                      decoration: BoxDecoration(
                        color: isSelected ? AppColors.dark : Colors.white,
                        borderRadius: BorderRadius.circular(16),
                        boxShadow: isSelected ? [BoxShadow(color: AppColors.dark.withOpacity(0.3), blurRadius: 12, offset: const Offset(0, 4))] : [BoxShadow(color: Colors.black.withOpacity(0.03), blurRadius: 8, offset: const Offset(0, 2))],
                        border: Border.all(color: isSelected ? AppColors.dark : AppColors.border.withOpacity(0.5), width: 1),
                      ),
                      child: Row(
                        children: [
                          Container(
                            width: 38, height: 38,
                            decoration: BoxDecoration(color: isSelected ? Colors.white.withOpacity(0.2) : AppColors.primary.withOpacity(0.1), borderRadius: BorderRadius.circular(10)),
                            child: Icon(LucideIcons.fileCheck, size: 20, color: isSelected ? Colors.white : AppColors.primary),
                          ),
                          const SizedBox(width: 14),
                          Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                room.name.isNotEmpty ? room.name : (room.roomCode ?? 'Room'),
                                style: GoogleFonts.nunito(fontSize: 15, fontWeight: FontWeight.w800, color: isSelected ? Colors.white : AppColors.text),
                              ),
                              const SizedBox(height: 2),
                              Row(
                                children: [
                                  Icon(LucideIcons.calendar, size: 12, color: isSelected ? Colors.white.withOpacity(0.8) : AppColors.textSub),
                                  const SizedBox(width: 6),
                                  Text(
                                    dateStr,
                                    style: GoogleFonts.nunito(fontSize: 12, fontWeight: FontWeight.w600, color: isSelected ? Colors.white.withOpacity(0.9) : AppColors.textSub),
                                  ),
                                ],
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              );
            },
          ),
        ),
      ],
    );
  }
}

// ── Student Score Card (Professional Style) ───────────────────────────
class _StudentScoreCard extends StatelessWidget {
  final int rank;
  final String name;
  final String initials;
  final int score;
  final String room;
  final String time;
  
  const _StudentScoreCard({
    required this.rank,
    required this.name,
    required this.initials,
    required this.score,
    required this.room,
    required this.time,
  });

  Color get _scoreColor {
    if (score >= 80) return AppColors.success;
    if (score >= 60) return AppColors.primary;
    return AppColors.warning;
  }
  
  String get _statusLabel {
    if (score >= 80) return 'Maîtrisé';
    if (score >= 60) return 'Validé';
    return 'À revoir';
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(color: Colors.black.withOpacity(0.03), blurRadius: 10, offset: const Offset(0, 2)),
        ],
        border: Border.all(color: AppColors.border.withOpacity(0.4), width: 1),
      ),
      child: Row(
        children: [
          Container(
            width: 32,
            alignment: Alignment.center,
            child: Text('#$rank', style: GoogleFonts.nunito(fontSize: 14, fontWeight: FontWeight.w800, color: AppColors.textSub)),
          ),
          const SizedBox(width: 8),
          CircleAvatar(
            radius: 22,
            backgroundColor: AppColors.primary.withOpacity(0.08),
            child: Text(
              initials,
              style: GoogleFonts.nunito(fontSize: 16, fontWeight: FontWeight.w800, color: AppColors.primary),
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  name,
                  style: GoogleFonts.nunito(fontSize: 16, fontWeight: FontWeight.w800, color: AppColors.text),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 3),
                Row(
                  children: [
                    const Icon(LucideIcons.calendar, size: 12, color: AppColors.textSub),
                    const SizedBox(width: 6),
                    Text(
                      time,
                      style: GoogleFonts.nunito(fontSize: 12, color: AppColors.textSub, fontWeight: FontWeight.w600),
                    ),
                  ],
                ),
              ],
            ),
          ),
          const SizedBox(width: 12),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
            decoration: BoxDecoration(color: _scoreColor.withOpacity(0.12), borderRadius: BorderRadius.circular(8)),
            child: Text(_statusLabel, style: GoogleFonts.nunito(fontSize: 12, fontWeight: FontWeight.w800, color: _scoreColor)),
          ),
          const SizedBox(width: 12),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
            decoration: BoxDecoration(color: _scoreColor, borderRadius: BorderRadius.circular(12), boxShadow: [BoxShadow(color: _scoreColor.withOpacity(0.3), blurRadius: 6, offset: const Offset(0, 2))]),
            child: Text('$score%', style: GoogleFonts.nunito(fontSize: 15, fontWeight: FontWeight.w800, color: Colors.white)),
          ),
        ],
      ),
    );
  }
}

// ── My Courses Tab ─────────────────────────────────────────────
class _MyCoursesTab extends StatefulWidget {
  final VoidCallback onNavigateToLibrary;
  const _MyCoursesTab({super.key, required this.onNavigateToLibrary});

  @override
  _MyCoursesTabState createState() => _MyCoursesTabState();
}

class _MyCoursesTabState extends State<_MyCoursesTab> {
  String _selectedSubjectFilter = 'Tous';

  final List<Color> _fallbackColors = [
    AppColors.primary, AppColors.info, AppColors.success, 
    AppColors.warning, AppColors.error, Colors.purple
  ];

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final s = context.read<AppState>();
      if (!s.teacherCoursesLoaded) s.loadTeacherCourses();
    });
  }

  @override
  Widget build(BuildContext context) {
    final state = context.watch<AppState>();

    if (!state.teacherCoursesLoaded) {
      return const Center(child: Padding(
        padding: EdgeInsets.all(40),
        child: CircularProgressIndicator(),
      ));
    }

    final allCourses = state.teacherCourses.map((course) => {
      ...course,
      'fileName': course['file_name'] ?? 'Inconnu',
      'semester': 'Semestre Actuel',
      'uploadedAt': course['created_at'] ?? DateTime.now().toIso8601String(),
      'isDefault': false,
    }).toList();

    // Extract unique subjects for the filter pill bar
    final Set<String> subjectsSet = {'Tous'};
    for (final c in allCourses) {
      final sub = (c['subject'] as String? ?? '').trim();
      if (sub.isNotEmpty) {
        subjectsSet.add(sub);
      }
    }
    final subjectFilters = subjectsSet.toList();

    final filteredCourses = _selectedSubjectFilter == 'Tous'
        ? allCourses
        : allCourses.where((c) => (c['subject'] as String? ?? '').trim() == _selectedSubjectFilter).toList();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // ─── Header & Upload Button ───────────────────────────────────────
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const SizedBox.shrink(),
              ElevatedButton.icon(
                onPressed: widget.onNavigateToLibrary,
                icon: const Icon(LucideIcons.upload, size: 18),
                label: Text('Uploader cours', style: GoogleFonts.inter(fontWeight: FontWeight.w700)),
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.primary,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                ),
              ),
            ],
          ),
        ),

        // ─── Search Info & Count ───────────────────────────────────────────
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
          child: Text(
            'Vous avez uploadé ${allCourses.length} cours au total',
            style: GoogleFonts.inter(fontSize: 13, color: AppColors.textSub),
          ),
        ),
        const SizedBox(height: 12),
                
        // ─── Subject filter pills ───────────────────────────────────────────
        if (subjectFilters.length > 1) ...[
          Container(
            height: 40,
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: ListView.builder(
              scrollDirection: Axis.horizontal,
              itemCount: subjectFilters.length,
              itemBuilder: (context, index) {
                final subject = subjectFilters[index];
                final isSelected = subject == _selectedSubjectFilter;
                final pillColor = isSelected ? AppColors.primary : AppColors.background;
                final textColor = isSelected ? Colors.white : AppColors.textSub;
                
                return Container(
                  margin: const EdgeInsets.only(right: 8),
                  child: Material(
                    color: Colors.transparent,
                    child: InkWell(
                      borderRadius: BorderRadius.circular(20),
                      onTap: () => setState(() => _selectedSubjectFilter = subject),
                      child: AnimatedContainer(
                        duration: const Duration(milliseconds: 200),
                        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                        decoration: BoxDecoration(
                          color: pillColor,
                          borderRadius: BorderRadius.circular(20),
                          border: Border.all(
                            color: isSelected ? AppColors.primary : AppColors.border,
                            width: 1,
                          ),
                        ),
                        child: Center(
                          child: Text(
                            subject,
                            style: GoogleFonts.inter(
                              fontSize: 12,
                              fontWeight: FontWeight.w700,
                              color: textColor,
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
        ],
        
        // ─── Courses List ─────────────────────────────────────────
        Expanded(
          child: filteredCourses.isEmpty
            ? const EmptyStatePage(emptyState: EmptyStateCours())
            : ListView.separated(
                padding: const EdgeInsets.symmetric(horizontal: 16).copyWith(bottom: 32),
                itemCount: filteredCourses.length,
                separatorBuilder: (_, __) => const SizedBox(height: 12),
                itemBuilder: (context, index) {
                  final course = filteredCourses[index];
                  final courseId = course['id']?.toString() ?? '';
                  final isDefault = course['isDefault'] as bool? ?? false;
                  return _MyCourseCard(
                    title: course['title'] as String? ?? 'Sans titre',
                    description: course['description'] as String? ?? '',
                    fileName: course['file_name'] as String? ?? course['fileName'] as String? ?? 'Inconnu',
                    semester: course['semester'] as String? ?? 'Semestre Actuel',
                    uploadedAt: course['uploadedAt'] as String? ?? course['created_at'] as String? ?? DateTime.now().toIso8601String(),
                    isDefault: isDefault,
                    courseData: course,
                    onView: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (_) => CourseDetailScreen(
                            course: course,
                            canEdit: !isDefault,
                            onEdit: () {
                              Navigator.pop(context); // Retour de CourseDetailScreen
                              Navigator.push(
                                context,
                                MaterialPageRoute(
                                  builder: (_) => LessonUploadScreen(
                                    filiere: course['filiere'] as String? ?? '',
                                    subject: course['subject'] as String? ?? '',
                                    semester: 'Semestre 1',
                                    courseToEdit: course,
                                  ),
                                ),
                              );
                            },
                            onDelete: () async {
                              await context.read<AppState>().deleteCourse(courseId);
                              await context.read<AppState>().loadTeacherCourses();
                            },
                          ),
                        ),
                      );
                    },
                    onEdit: isDefault ? null : () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (_) => LessonUploadScreen(
                            filiere: course['filiere'] as String? ?? '',
                            subject: course['subject'] as String? ?? '',
                            semester: 'Semestre 1',
                            courseToEdit: course,
                          ),
                        ),
                      );
                    },
                    onDelete: isDefault ? null : () async {
                      final confirmed = await showDialog<bool>(
                        context: context,
                        builder: (_) => AlertDialog(
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                          title: const Text('Supprimer ce cours ?'),
                          content: Text('Le cours "${course['title'] ?? ''}" sera supprimé définitivement.'),
                          actions: [
                            TextButton(onPressed: () => Navigator.pop(context, false), child: const Text('Annuler')),
                            TextButton(
                              onPressed: () => Navigator.pop(context, true),
                              child: const Text('Supprimer', style: TextStyle(color: AppColors.error)),
                            ),
                          ],
                        ),
                      );
                      if (confirmed == true && context.mounted) {
                        await context.read<AppState>().deleteCourse(courseId);
                        await context.read<AppState>().loadTeacherCourses();
                      }
                    },
                  );
                },
              ),
        ),
      ],
    );
  }
}

// ── My Course Card ─────────────────────────────────────────────
class _MyCourseCard extends StatelessWidget {
  final String title;
  final String description;
  final String fileName;
  final String semester;
  final String uploadedAt;
  final bool isDefault;
  final Map<String, dynamic> courseData;
  final VoidCallback? onView;
  final VoidCallback? onEdit;
  final VoidCallback? onDelete;
  
  const _MyCourseCard({
    required this.title,
    required this.description,
    required this.fileName,
    required this.semester,
    required this.uploadedAt,
    required this.courseData,
    this.isDefault = false,
    this.onView,
    this.onEdit,
    this.onDelete,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.primary.withOpacity(0.5), width: 1.5),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // ── Header avec badge pour cours par défaut ─────────────────────
          Row(
            children: [
              // Image ou icône
              Container(
                width: 60,
                height: 60,
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(8),
                  color: AppColors.primary.withOpacity(0.1),
                ),
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(8),
                  child: Image.asset(
                    'assets/images/image.png',
                    fit: BoxFit.cover,
                    errorBuilder: (context, error, stackTrace) {
                      return Container(
                        width: double.infinity,
                        height: double.infinity,
                        decoration: BoxDecoration(
                          color: AppColors.primary.withOpacity(0.1),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: const Icon(
                          LucideIcons.bookOpen,
                          size: 24,
                          color: AppColors.primary,
                        ),
                      );
                    },
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Expanded(
                          child: Text(
                            title,
                            style: GoogleFonts.inter(
                              fontSize: 14,
                              fontWeight: FontWeight.w700,
                              color: AppColors.text,
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                        if (isDefault) ...[
                          const SizedBox(width: 8),
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                            decoration: BoxDecoration(
                              color: AppColors.primary,
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: Text(
                              'Par défaut',
                              style: GoogleFonts.inter(
                                fontSize: 8,
                                fontWeight: FontWeight.w600,
                                color: Colors.white,
                              ),
                            ),
                          ),
                        ],
                      ],
                    ),
                    if (description.isNotEmpty) ...[
                      const SizedBox(height: 4),
                      Text(
                        description,
                        style: GoogleFonts.inter(
                          fontSize: 12,
                          color: AppColors.textSub,
                        ),
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ],
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: AppColors.success.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Text(
                  semester,
                  style: GoogleFonts.inter(
                    fontSize: 10,
                    fontWeight: FontWeight.w600,
                    color: AppColors.success,
                  ),
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  fileName,
                  style: GoogleFonts.inter(
                    fontSize: 10,
                    color: AppColors.textSub,
                  ),
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Row(
            children: [
              const Icon(
                LucideIcons.calendar,
                size: 12,
                color: AppColors.textSub,
              ),
              const SizedBox(width: 4),
              Text(
                'Uploadé le ${DateTime.parse(uploadedAt).day}/${DateTime.parse(uploadedAt).month}/${DateTime.parse(uploadedAt).year}',
                style: GoogleFonts.inter(
                  fontSize: 10,
                  color: AppColors.textSub,
                ),
              ),
              const Spacer(),
              Row(
                children: [
                  IconButton(
                    onPressed: onView,
                    icon: const Icon(LucideIcons.eye, size: 16),
                    color: AppColors.primary,
                  ),
                  if (!isDefault) ...[
                    IconButton(
                      onPressed: onEdit,
                      icon: const Icon(LucideIcons.edit, size: 16),
                      color: AppColors.info,
                    ),
                    IconButton(
                      onPressed: onDelete,
                      icon: const Icon(LucideIcons.trash2, size: 16),
                      color: AppColors.error,
                    ),
                  ],
                ],
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _ClassSelector extends StatefulWidget {
  @override
  State<_ClassSelector> createState() => _ClassSelectorState();
}

class _ClassSelectorState extends State<_ClassSelector> {
  int _selected = 0;
  final _classes = ['Terminale S — Bio', '3ème — Maths'];

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 36,
      child: ListView.builder(
        scrollDirection: Axis.horizontal,
        itemCount: _classes.length,
        itemBuilder: (_, i) {
          final sel = i == _selected;
          return GestureDetector(
            onTap: () => setState(() => _selected = i),
            child: Container(
              margin: const EdgeInsets.only(right: 8),
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
              decoration: BoxDecoration(
                color: sel ? AppColors.primary : Colors.white,
                borderRadius: BorderRadius.circular(20),
                border: Border.all(color: sel ? AppColors.primary : AppColors.border, width: 1),
              ),
              child: Text(_classes[i], style: GoogleFonts.nunito(
                fontSize: 12, fontWeight: FontWeight.w700,
                color: sel ? Colors.white : AppColors.textSecondary,
              )),
            ),
          );
        },
      ),
    );
  }
}

// ── Library Tab ───────────────────────────────────────────────
class _LibraryTab extends StatefulWidget {
  @override
  State<_LibraryTab> createState() => _LibraryTabState();
}

class _LibraryTabState extends State<_LibraryTab> {
  int _selectedFiliere = 0;
  int _selectedNiveau = 0;
  int _selectedSubject = 0;
  final Set<int> _expandedSemesters = {0}; // Semestre 1 ouvert par défaut

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

  @override
  Widget build(BuildContext context) {
    final state = context.watch<AppState>();
    final filieres = state.filieres;
    final allMatieres = state.matieres;
    final niveaux = state.niveaux;

    if (!state.adminCoursesLoaded || !state.filieresLoaded || !state.niveauxLoaded || !state.matieresLoaded) {
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
    
    if (_selectedNiveau >= niveauxForFiliere.length) {
      _selectedNiveau = 0;
    }

    final selectedNiveauId = niveauxForFiliere.isNotEmpty ? niveauxForFiliere[_selectedNiveau]['id']?.toString() : null;
    final matieres = allMatieres.where((m) => m['niveau_id']?.toString() == selectedNiveauId).toList();

    if (_selectedSubject >= matieres.length) _selectedSubject = 0;

    final selectedFiliereName = (filieres[_selectedFiliere]['nom'] as String? ?? '').trim();
    final selectedNiveauName = niveauxForFiliere.isNotEmpty ? (niveauxForFiliere[_selectedNiveau]['nom'] as String? ?? '').trim() : '';
    final selectedSubjectName = matieres.isNotEmpty ? (matieres[_selectedSubject]['nom'] as String? ?? '').trim() : '';

    return SingleChildScrollView(
      padding: const EdgeInsets.all(16).copyWith(bottom: 32),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Ma bibliothèque',
                style: GoogleFonts.inter(
                  fontSize: 20,
                  fontWeight: FontWeight.w800,
                  color: AppColors.text,
                ),
              ),
              SkwBtn(
                label: 'Uploader',
                icon: LucideIcons.upload,
                onTap: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (_) => LessonUploadScreen(
                        filiere: selectedFiliereName,
                        subject: selectedSubjectName,
                        semester: 'Semestre Actuel',
                      ),
                    ),
                  );
                },
              ),
            ],
          ),
          const SizedBox(height: 20),
          
          // Level navigation
          SizedBox(
            height: 40,
            child: ListView.builder(
              scrollDirection: Axis.horizontal,
              itemCount: filieres.length,
              itemBuilder: (context, index) {
                final isSelected = index == _selectedFiliere;
                final nom = filieres[index]['nom'] as String? ?? 'Filière';
                return Container(
                  margin: const EdgeInsets.only(right: 8),
                  child: InkWell(
                    borderRadius: BorderRadius.circular(20),
                    onTap: () => setState(() {
                      _selectedFiliere = index;
                      _selectedNiveau = 0; // Reset niveau when filiere changes
                      _selectedSubject = 0;
                    }),
                    child: Container(
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
                );
              },
            ),
          ),
          const SizedBox(height: 10),

          // Niveau navigation
          if (niveauxForFiliere.isNotEmpty) ...[
            SizedBox(
              height: 36,
              child: ListView.builder(
                scrollDirection: Axis.horizontal,
                itemCount: niveauxForFiliere.length,
                itemBuilder: (context, index) {
                  final isSelected = index == _selectedNiveau;
                  final nom = niveauxForFiliere[index]['nom'] as String? ?? 'Niveau';
                  return Container(
                    margin: const EdgeInsets.only(right: 8),
                    child: InkWell(
                      borderRadius: BorderRadius.circular(18),
                      onTap: () => setState(() {
                        _selectedNiveau = index;
                        _selectedSubject = 0; // Reset subject when niveau changes
                      }),
                      child: Container(
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
                  );
                },
              ),
            ),
            const SizedBox(height: 14),
          ],
          
          // Subject chips
          SizedBox(
            height: 40,
            child: ListView.builder(
              scrollDirection: Axis.horizontal,
              itemCount: matieres.length,
              itemBuilder: (context, index) {
                final isSelected = index == _selectedSubject;
                final matiere = matieres[index];
                final label = matiere['nom'] as String? ?? 'Matière';
                final subjectColor = _fallbackColors[index % _fallbackColors.length];
                
                return Container(
                  margin: const EdgeInsets.only(right: 8),
                  child: InkWell(
                    borderRadius: BorderRadius.circular(20),
                    onTap: () => setState(() => _selectedSubject = index),
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                      decoration: BoxDecoration(
                        color: isSelected ? subjectColor : AppColors.background,
                        borderRadius: BorderRadius.circular(20),
                        border: Border.all(
                          color: isSelected ? subjectColor : AppColors.border,
                          width: 1,
                        ),
                      ),
                      child: Row(
                        children: [
                          Icon(
                            LucideIcons.bookOpen,
                            size: 14,
                            color: isSelected ? Colors.white : subjectColor,
                          ),
                          const SizedBox(width: 8),
                          Text(
                            label,
                            style: GoogleFonts.inter(
                              fontSize: 12,
                              fontWeight: FontWeight.w700,
                              color: isSelected ? Colors.white : AppColors.textSub,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                );
              },
            ),
          ),
          const SizedBox(height: 24),
          
          // Semesters list
          Builder(
            builder: (context) {
              final subjectLabel = selectedSubjectName;
              final aliases = _subjectAliases[subjectLabel] ?? [subjectLabel];
              
              // Filter all courses for the selected subject and niveau, ensuring unique titles
              final seenTitles = <String>{};
              final allFilteredCourses = state.adminCourses.where((c) {
                final title = c['title'] as String? ?? '';
                final courseSubject = (c['subject'] as String? ?? '').trim();
                final courseFiliere = (c['filiere'] as String? ?? '').trim(); // Database still uses 'filiere' column for niveau name
                
                final niveauMatch = courseFiliere.isNotEmpty 
                    ? (courseFiliere.toLowerCase() == selectedNiveauName.toLowerCase() ||
                       courseFiliere.toLowerCase() == selectedFiliereName.toLowerCase() ||
                       (selectedNiveauName.isNotEmpty && courseFiliere.toLowerCase().contains(selectedNiveauName.toLowerCase())) ||
                       (selectedNiveauName.isNotEmpty && selectedNiveauName.toLowerCase().contains(courseFiliere.toLowerCase())))
                    : (_selectedFiliere == 0 && _selectedNiveau == 0);
                final subjectMatch = aliases.any((alias) =>
                    courseSubject.toLowerCase() == alias.toLowerCase());
                
                if (niveauMatch && subjectMatch && !seenTitles.contains(title)) {
                  seenTitles.add(title);
                  return true;
                }
                return false;
              }).toList();

              if (allFilteredCourses.isEmpty) {
                return Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(32),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(color: AppColors.border),
                  ),
                  child: Column(
                    children: [
                      Icon(LucideIcons.fileX, size: 48, color: AppColors.textSub.withOpacity(0.3)),
                      const SizedBox(height: 16),
                      Text(
                        'Aucune ressource trouvée pour cette matière.',
                        style: GoogleFonts.inter(fontSize: 14, color: AppColors.textSub, fontWeight: FontWeight.w600),
                        textAlign: TextAlign.center,
                      ),
                    ],
                  ),
                );
              }

              return Column(
                children: List.generate(2, (index) {
                  final semesterNum = index + 1;
                  final isExpanded = _expandedSemesters.contains(index);
                  
                  // Filter courses for this semester
                  final semesterCourses = allFilteredCourses.where((c) {
                    final desc = (c['description'] as String? ?? '').toLowerCase();
                    if (semesterNum == 1) return desc.contains('semestre 1') || !desc.contains('semestre 2');
                    return desc.contains('semestre 2');
                  }).toList();

                  return Container(
                    margin: const EdgeInsets.only(bottom: 12),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(color: AppColors.border, width: 1),
                    ),
                    child: Column(
                      children: [
                        InkWell(
                          onTap: () => setState(() {
                            isExpanded ? _expandedSemesters.remove(index) : _expandedSemesters.add(index);
                          }),
                          borderRadius: BorderRadius.circular(16),
                          child: Padding(
                            padding: const EdgeInsets.all(16),
                            child: Row(
                              children: [
                                Text(
                                  'Semestre $semesterNum',
                                  style: GoogleFonts.inter(
                                    fontSize: 16,
                                    fontWeight: FontWeight.w700,
                                    color: AppColors.text,
                                  ),
                                ),
                                const Spacer(),
                                Text(
                                  '${semesterCourses.length} leçons',
                                  style: GoogleFonts.inter(
                                    fontSize: 13,
                                    fontWeight: FontWeight.w600,
                                    color: AppColors.textSub,
                                  ),
                                ),
                                const SizedBox(width: 8),
                                AnimatedRotation(
                                  turns: isExpanded ? 0.5 : 0,
                                  duration: const Duration(milliseconds: 200),
                                  child: const Icon(LucideIcons.chevronDown, size: 18, color: AppColors.textSub),
                                ),
                              ],
                            ),
                          ),
                        ),
                        if (isExpanded && semesterCourses.isNotEmpty)
                          Padding(
                            padding: const EdgeInsets.fromLTRB(12, 0, 12, 16),
                            child: GridView.builder(
                              shrinkWrap: true,
                              physics: const NeverScrollableScrollPhysics(),
                              gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                                crossAxisCount: 2,
                                mainAxisSpacing: 12,
                                crossAxisSpacing: 12,
                                childAspectRatio: 1.1,
                              ),
                              itemCount: semesterCourses.length,
                              itemBuilder: (context, i) {
                                final course = semesterCourses[i];
                                return _FolderCard(
                                  title: course['title'] as String? ?? 'Sans titre',
                                  onTap: () {
                                    Navigator.push(
                                      context,
                                      MaterialPageRoute(
                                        builder: (_) => CourseDetailScreen(
                                          course: course,
                                          canEdit: false, // Bibliothèque = lecture seule
                                        ),
                                      ),
                                    );
                                  },
                                );
                              },
                            ),
                          ),
                      ],
                    ),
                  );
                }),
              );
            },
          ),
        ],
      ),
    );
  }
}

// ── Folder Card ───────────────────────────────────────────────
class _FolderCard extends StatelessWidget {
  final String title;
  final VoidCallback onTap;

  const _FolderCard({required this.title, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        decoration: BoxDecoration(
          color: const Color(0xFFFFF8E1),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: AppColors.warning.withOpacity(0.2), width: 1),
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Image.asset(
              'assets/images/image.png',
              width: 70,
              height: 70,
              errorBuilder: (context, error, stackTrace) => 
                const Icon(LucideIcons.folder, size: 50, color: AppColors.warning),
            ),
            const SizedBox(height: 8),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 8),
              child: Text(
                title,
                textAlign: TextAlign.center,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
                style: GoogleFonts.inter(
                  fontSize: 12,
                  fontWeight: FontWeight.w700,
                  color: AppColors.text,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _QuizzesTab extends StatefulWidget {
  @override
  State<_QuizzesTab> createState() => _QuizzesTabState();
}

class _QuizzesTabState extends State<_QuizzesTab> {
  @override
  Widget build(BuildContext context) {
    final courses = context.watch<AppState>().teacherCourses;
    final quizzes = courses.where((c) => (c['question_count'] ?? 0) > 0).toList();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [


        Expanded(
          child: quizzes.isEmpty 
            ? const EmptyStatePage(emptyState: EmptyStateQsm())
            : ListView.builder(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
                itemCount: quizzes.length,
                itemBuilder: (context, index) {
                  final quiz = quizzes[index];
                  return _QuizCard(quiz: quiz);
                },
              ),
        ),
      ],
    );
  }
}

class _QuizCard extends StatelessWidget {
  final Map<String, dynamic> quiz;
  const _QuizCard({required this.quiz});

  void _confirmDelete(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: Text('Supprimer le QSM ?', style: GoogleFonts.inter(fontWeight: FontWeight.w700)),
        content: Text('Êtes-vous sûr de vouloir supprimer ce QSM ? Cette action est irréversible.', style: GoogleFonts.inter(fontSize: 14)),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text('Annuler', style: GoogleFonts.inter(color: AppColors.textSub)),
          ),
          ElevatedButton(
            onPressed: () async {
              Navigator.pop(context);
              
              // Afficher un petit indicateur de chargement
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('Suppression du QSM en cours...')),
              );
              
              await context.read<AppState>().deleteCourse(quiz['id'] as String);
              
              if (context.mounted) {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('QSM supprimé avec succès !')),
                );
              }
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.redAccent,
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
            ),
            child: Text('Supprimer', style: GoogleFonts.inter(fontWeight: FontWeight.w600)),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
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
          )
        ],
      ),
      child: Row(
        children: [
          Container(
            width: 48, height: 48,
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [AppColors.primary.withOpacity(0.1), AppColors.primary.withOpacity(0.05)],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              borderRadius: BorderRadius.circular(12),
            ),
            child: const Icon(LucideIcons.fileText, color: AppColors.primary, size: 22),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(quiz['title'] ?? 'QSM sans titre', 
                  style: GoogleFonts.inter(fontWeight: FontWeight.w700, fontSize: 14, color: AppColors.text),
                  maxLines: 1, overflow: TextOverflow.ellipsis),
                const SizedBox(height: 4),
                Text('${quiz['subject'] ?? 'Général'} · ${quiz['question_count'] ?? 0} questions',
                  style: GoogleFonts.inter(fontSize: 11, color: AppColors.textSub, fontWeight: FontWeight.w500)),
              ],
            ),
          ),
          const SizedBox(width: 8),
          IconButton(
            icon: const Icon(LucideIcons.trash2, color: Colors.redAccent, size: 20),
            onPressed: () => _confirmDelete(context),
            tooltip: 'Supprimer',
          ),
          const SizedBox(width: 4),
          SkwBtn(
            label: 'Lancer',
            icon: LucideIcons.play,
            outlined: true,
            onTap: () async {
              // Charger le QCM dans l'état global
              final scaffold = ScaffoldMessenger.of(context);
              
              // Afficher un petit indicateur de chargement
              scaffold.showSnackBar(
                SnackBar(
                  content: Text('Chargement du QSM: ${quiz['title']}...'),
                  duration: const Duration(seconds: 1),
                ),
              );

              await context.read<AppState>().loadQcmForCourse(
                quiz['id'] as String,
                quiz['title'] as String? ?? 'Sans titre',
              );
              
              if (context.mounted) {
                // Naviguer vers la création de room
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (_) => const CreateRoomScreen()),
                );
              }
            },
          ),
        ],
      ),
    );
  }
}



// ── Section semestre avec accordion + grille de dossiers ─────────────────────
class _SemesterSection extends StatelessWidget {
  final String title;
  final int lessonCount;
  final List<String> lessons;
  final bool isExpanded;
  final VoidCallback onToggle;
  final VoidCallback onUpload;
  final Map<String, dynamic>? semesterData;

  const _SemesterSection({
    required this.title,
    required this.lessonCount,
    required this.lessons,
    required this.isExpanded,
    required this.onToggle,
    required this.onUpload,
    this.semesterData,
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
                    child: const Icon(LucideIcons.chevronDown,
                        size: 18, color: AppColors.textSub),
                  ),
                ],
              ),
            ),
          ),

          // ── Actions buttons ──────────────────────────────────
          if (isExpanded)
            Container(
              padding: const EdgeInsets.fromLTRB(16, 0, 16, 12),
              child: Row(
                children: [
                  Expanded(
                    child: OutlinedButton.icon(
                      onPressed: onUpload,
                      icon: const Icon(LucideIcons.upload, size: 16),
                      label: Text('Ajouter une leçon', style: GoogleFonts.inter(fontSize: 12, fontWeight: FontWeight.w700)),
                      style: OutlinedButton.styleFrom(
                        padding: const EdgeInsets.symmetric(vertical: 8),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                      ),
                    ),
                  ),
                ],
              ),
            ),

          // ── Leçons list ─────────────────────────────────────
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
                        crossAxisCount: 3, // Changed from 2 to 3 to decrease width
                        mainAxisSpacing: 12,
                        crossAxisSpacing: 12,
                        childAspectRatio: 0.9, // Adjust height slightly for smaller cards
                      ),
                      itemCount: lessons.length,
                      itemBuilder: (context, i) {
                  final isUploaded = i < (semesterData?['uploadedCount'] ?? 0);
                  final teacherName = context.read<AppState>().currentUser?.fullName ?? 'Moi';
                  return _LessonCard(
                    title: lessons[i], 
                    isUploaded: isUploaded,
                    teacherName: teacherName,
                  );
                },
                    ),
                  )
                : const SizedBox.shrink(),
          ),
        ],
      ),
    );
  }
}

// ── Carte leçon ─────────────────────────────────────────────────────
class _LessonCard extends StatelessWidget {
  final String title;
  final bool isUploaded;
  final String? teacherName;
  const _LessonCard({required this.title, this.isUploaded = false, this.teacherName});

  String _getLessonImage(String title) {
    // Use the specific image for all lessons
    return 'assets/images/image.png';
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () {/* View lesson details */},
      child: Container(
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: AppColors.border, width: 1), // Removed green border
        ),
        child: Column(
          children: [
            // ── Image leçon ──────────────────────────────────
            Expanded(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(16, 16, 16, 4), // Increased padding to make image smaller
                child: Container(
                  decoration: const BoxDecoration(
                    color: Colors.transparent, // Removed green background
                  ),
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(8),
                    child: Image.asset(
                      _getLessonImage(title),
                      fit: BoxFit.contain,
                      errorBuilder: (context, error, stackTrace) {
                        return Container(
                          width: double.infinity,
                          height: double.infinity,
                          decoration: BoxDecoration(
                            color: AppColors.success.withOpacity(0.1),
                            borderRadius: BorderRadius.circular(8),
                            border: Border.all(
                              color: AppColors.success,
                              width: 1,
                            ),
                          ),
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              const Icon(
                                LucideIcons.image,
                                size: 24,
                                color: AppColors.success,
                              ),
                              const SizedBox(height: 4),
                              Text(
                                'Image',
                                style: GoogleFonts.inter(
                                  fontSize: 10,
                                  color: AppColors.success,
                                ),
                              ),
                            ],
                          ),
                        );
                      },
                    ),
                  ),
                ),
              ),
            ),

            // ── Titre et Enseignant ───────────────────────────────────────
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
              child: Column(
                children: [
                  Text(
                    title,
                    textAlign: TextAlign.center,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: GoogleFonts.inter(
                      fontSize: 12,
                      fontWeight: FontWeight.w700,
                      color: AppColors.text,
                    ),
                  ),
                  if (teacherName != null) ...[
                    const SizedBox(height: 2),
                    Text(
                      'Par $teacherName',
                      textAlign: TextAlign.center,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: GoogleFonts.inter(
                        fontSize: 10,
                        fontWeight: FontWeight.w500,
                        color: AppColors.textSub,
                      ),
                    ),
                  ],
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _CatCard extends StatelessWidget {
  final IconData icon;
  final String label;
  final Color color;
  const _CatCard({required this.icon, required this.label, required this.color});

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: color.withOpacity(0.08),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: color.withOpacity(0.2), width: 0.5),
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(icon, size: 24, color: color),
          const SizedBox(height: 6),
          Text(label, style: GoogleFonts.nunito(fontSize: 11, fontWeight: FontWeight.w700, color: color)),
        ],
      ),
    );
  }
}

class _LibraryCourseCard extends StatelessWidget {
  final String title, cat;
  final int questions;
  const _LibraryCourseCard({required this.title, required this.cat, required this.questions});

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.border, width: 0.5),
      ),
      child: Row(
        children: [
          Container(
            width: 40, height: 40,
            decoration: BoxDecoration(color: AppColors.greenLight, borderRadius: BorderRadius.circular(10)),
            child: const Icon(LucideIcons.fileText, size: 20, color: AppColors.green),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(title, style: GoogleFonts.nunito(fontSize: 13, fontWeight: FontWeight.w700, color: AppColors.text)),
                Text('$cat · $questions questions', style: GoogleFonts.nunito(fontSize: 11, color: AppColors.textSub)),
              ],
            ),
          ),
          const Icon(LucideIcons.chevronRight, size: 16, color: AppColors.textSub),
        ],
      ),
    );
  }
}

// ── Create Options Sheet ─────────────────────────────────────
class _CreateOptionsSheet extends StatelessWidget {
  final VoidCallback onUpload, onClassroom, onRoom, onQsm;
  const _CreateOptionsSheet({required this.onUpload, required this.onClassroom, required this.onRoom, required this.onQsm});

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      padding: const EdgeInsets.fromLTRB(20, 16, 20, 32),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(width: 40, height: 4, decoration: BoxDecoration(color: AppColors.border, borderRadius: BorderRadius.circular(2))),
          const SizedBox(height: 16),
          Text('Créer', style: GoogleFonts.nunito(fontSize: 18, fontWeight: FontWeight.w800, color: AppColors.text)),
          const SizedBox(height: 16),
          _SheetOption(icon: LucideIcons.fileText, label: 'Créer QSM', sub: 'Questions et réponses', color: AppColors.warning, onTap: onQsm),
          _SheetOption(icon: LucideIcons.upload, label: 'Uploader cours', sub: 'PDF ou DOCX', color: AppColors.primary, onTap: onUpload),
          _SheetOption(icon: LucideIcons.users, label: 'Nouvelle classe', sub: 'Grouper vos étudiants', color: AppColors.green, onTap: onClassroom),
          _SheetOption(icon: LucideIcons.link, label: 'Lancer une Room', sub: 'Générer un lien de session', color: AppColors.info, onTap: onRoom),
        ],
      ),
    );
  }
}

class _SheetOption extends StatelessWidget {
  final IconData icon;
  final String label, sub;
  final Color color;
  final VoidCallback onTap;
  const _SheetOption({required this.icon, required this.label, required this.sub, required this.color, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        margin: const EdgeInsets.only(bottom: 10),
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: AppColors.background,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: AppColors.border, width: 0.5),
        ),
        child: Row(
          children: [
            Container(
              width: 44, height: 44,
              decoration: BoxDecoration(color: color.withOpacity(0.12), borderRadius: BorderRadius.circular(12)),
              child: Icon(icon, size: 22, color: color),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(label, style: GoogleFonts.nunito(fontSize: 14, fontWeight: FontWeight.w700, color: AppColors.text)),
                  Text(sub, style: GoogleFonts.nunito(fontSize: 12, color: AppColors.textSub)),
                ],
              ),
            ),
            const Icon(LucideIcons.chevronRight, size: 18, color: AppColors.textSub),
          ],
        ),
      ),
    );
  }
}