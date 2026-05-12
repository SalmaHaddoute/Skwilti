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
import 'create_classroom_screen.dart';
import 'create_room_screen.dart';
import 'upload_screen.dart';
import 'lesson_upload_screen.dart';
import 'profile_screen.dart';

class TeacherDashboard extends StatefulWidget {
  const TeacherDashboard({super.key});
  @override
  State<TeacherDashboard> createState() => _TeacherDashboardState();
}

class _TeacherDashboardState extends State<TeacherDashboard> {
  int _currentIndex = 0;

  final _navItems = const [
    SkwNavItem(icon: LucideIcons.home, activeIcon: LucideIcons.home, label: 'Accueil'),
    SkwNavItem(icon: LucideIcons.users, label: 'Classes'),
    SkwNavItem(icon: LucideIcons.layers, label: 'Rooms'),
    SkwNavItem(icon: LucideIcons.barChart2, label: 'Notes'),
    SkwNavItem(icon: LucideIcons.bookOpen, label: 'Mes cours'),
    SkwNavItem(icon: LucideIcons.library, label: 'Bibliothèque'),
  ];

  @override
  Widget build(BuildContext context) {
    final user = context.watch<AppState>().currentUser;
    return Scaffold(
      backgroundColor: AppColors.background,
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
          _MyCoursesTab(),
          _LibraryTab(),
        ],
      ),
      bottomNavigationBar: SkwiltiBottomNav(
        currentIndex: _currentIndex,
        onTap: (i) => setState(() => _currentIndex = i),
        items: _navItems,
      ),
      floatingActionButton: _currentIndex == 0 ? FloatingActionButton.extended(
        onPressed: _showCreateOptions,
        backgroundColor: AppColors.primary,
        foregroundColor: Colors.white,
        icon: const Icon(LucideIcons.plus, size: 20),
        label: Text(
          'Créer',
          style: GoogleFonts.inter(
            fontSize: 14,
            fontWeight: FontWeight.w600,
          ),
        ),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(28),
        ),
        elevation: 4,
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
      case 5: return 'Bibliothèque';
      default: return 'Skwilti';
    }
  }

  void _showCreateOptions() {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (_) => _CreateOptionsSheet(
        onUpload: () { Navigator.pop(context); Navigator.push(context, MaterialPageRoute(builder: (_) => const LessonUploadScreen(filiere: 'Général', subject: 'Général', semester: 'Général'))); },
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
          SnackBar(
            content: const Text('✅ Connexion n8n réussie ! QCM en cours de génération.'),
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

    return SingleChildScrollView(
      padding: const EdgeInsets.all(16).copyWith(bottom: 24),
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
                      Text('Prêt à créer des QSM aujourd\'hui ?',
                          style: GoogleFonts.nunito(fontSize: 13, color: Colors.white.withOpacity(0.85))),
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
          const SizedBox(height: 16),
          // Stats row
          Row(
            children: [
              Expanded(child: _StatCard(label: 'Cours', value: '${courses.length}', icon: LucideIcons.fileText, color: AppColors.primary)),
              const SizedBox(width: 10),
              Expanded(child: _StatCard(label: 'Points', value: '${stats?.totalPoints ?? 0}', icon: LucideIcons.award, color: AppColors.green)),
              const SizedBox(width: 10),
              Expanded(child: _StatCard(label: 'Classes', value: '${classrooms.length}', icon: LucideIcons.users, color: const Color(0xFF9B59B6))),
            ],
          ),
          const SizedBox(height: 20),
          // Dernier cours uploadé (données réelles)
          if (loaded && courses.isNotEmpty)
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: AppColors.primary.withOpacity(0.05),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: AppColors.primary.withOpacity(0.2), width: 1),
              ),
              child: Row(
                children: [
                  Container(
                    width: 40, height: 40,
                    decoration: BoxDecoration(color: AppColors.primary, borderRadius: BorderRadius.circular(8)),
                    child: const Icon(LucideIcons.fileText, color: Colors.white, size: 20),
                  ),
                  const SizedBox(width: 16),
                  Expanded(child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(courses.first['title'] as String? ?? 'Cours sans titre',
                          style: GoogleFonts.inter(fontSize: 15, fontWeight: FontWeight.w700, color: AppColors.text),
                          maxLines: 1, overflow: TextOverflow.ellipsis),
                      const SizedBox(height: 4),
                      Text(courses.first['subject'] as String? ?? '',
                          style: GoogleFonts.inter(fontSize: 12, color: AppColors.textSub)),
                    ],
                  )),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    decoration: BoxDecoration(color: AppColors.success, borderRadius: BorderRadius.circular(12)),
                    child: Text('${courses.first['question_count'] ?? 0} questions',
                        style: GoogleFonts.inter(fontSize: 10, fontWeight: FontWeight.w700, color: Colors.white)),
                  ),
                ],
              ),
            )
          else if (!loaded)
            const Center(child: Padding(padding: EdgeInsets.all(16), child: CircularProgressIndicator())),
          const SizedBox(height: 20),
          // Diagramme d'activité de la semaine (données réelles)
          Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: AppColors.border, width: 0.5),
              boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.04), blurRadius: 8, offset: const Offset(0, 2))],
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('Activité cette semaine',
                    style: GoogleFonts.nunito(fontSize: 16, fontWeight: FontWeight.w700, color: AppColors.text)),
                const SizedBox(height: 16),
                SizedBox(
                  height: 150,
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: [
                      for (int i = 0; i < 7; i++) ...[
                        if (i > 0) const SizedBox(width: 8),
                        Expanded(child: Builder(builder: (_) {
                          final val = activity[i] ?? 0;
                          final maxVal = activity.values.fold(1, (a, b) => a > b ? a : b);
                          return Column(
                            mainAxisAlignment: MainAxisAlignment.end,
                            children: [
                              Text('$val', style: GoogleFonts.nunito(fontSize: 10, fontWeight: FontWeight.w800, color: AppColors.primary)),
                              const SizedBox(height: 4),
                              Container(
                                height: maxVal > 0 ? 80 * (val / maxVal) : 4,
                                decoration: BoxDecoration(
                                  gradient: const LinearGradient(
                                    colors: [AppColors.primary, AppColors.primary2],
                                    begin: Alignment.bottomCenter, end: Alignment.topCenter,
                                  ),
                                  borderRadius: const BorderRadius.vertical(top: Radius.circular(4)),
                                ),
                              ),
                              const SizedBox(height: 6),
                              Text(['L','M','M','J','V','S','D'][i],
                                  style: GoogleFonts.nunito(fontSize: 10, color: AppColors.textSub)),
                            ],
                          );
                        })),
                      ],
                    ],
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 20),
          // Quick actions
          SectionTitle(title: 'Actions rapides', action: null),
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
                  onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const LessonUploadScreen(filiere: 'Général', subject: 'Général', semester: 'Général')))),
              _QuickAction(icon: LucideIcons.zap, label: 'Tester n8n', sub: 'Vérifier la liaison', color: AppColors.info,
                  onTap: _testN8n),
            ],
          ),
          const SizedBox(height: 20),
          SectionTitle(title: 'Cours uploadés récents', action: 'Voir tout', onAction: () => widget.onNavigate(4)),
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
                Icon(LucideIcons.fileText, size: 36, color: AppColors.textSub),
                const SizedBox(height: 8),
                Text('Aucun cours uploadé', style: GoogleFonts.inter(fontSize: 14, color: AppColors.textSub)),
                const SizedBox(height: 4),
                Text('Cliquez sur "Créer" pour uploader votre premier cours.',
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
                          fontSize: 14,
                          fontWeight: FontWeight.w700,
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
                Row(
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
                    const SizedBox(width: 6),
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
              Icon(
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
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: AppColors.border, width: 0.5),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 30, height: 30,
            decoration: BoxDecoration(color: color.withOpacity(0.12), borderRadius: BorderRadius.circular(8)),
            child: Icon(icon, size: 15, color: color),
          ),
          const SizedBox(height: 8),
          Text(value, style: GoogleFonts.nunito(fontSize: 22, fontWeight: FontWeight.w800, color: color)),
          Text(label, style: GoogleFonts.nunito(fontSize: 10, color: AppColors.textSub, fontWeight: FontWeight.w600)),
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
                  Text(label, style: GoogleFonts.nunito(fontSize: 12, fontWeight: FontWeight.w700, color: AppColors.text)),
                  Text(sub, style: GoogleFonts.nunito(fontSize: 10, color: AppColors.textSub)),
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
class _ClassesTab extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    final classrooms = context.watch<AppState>().userClassrooms;
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        children: [
          if (classrooms.isEmpty)
            Container(
              margin: const EdgeInsets.only(bottom: 16),
              padding: const EdgeInsets.all(24),
              decoration: BoxDecoration(
                color: Colors.white, borderRadius: BorderRadius.circular(16),
                border: Border.all(color: AppColors.border, width: 0.5),
              ),
              child: Column(children: [
                Icon(LucideIcons.users, size: 40, color: AppColors.textSub),
                const SizedBox(height: 12),
                Text('Aucune classe créée', style: GoogleFonts.inter(fontSize: 15, fontWeight: FontWeight.w700, color: AppColors.text)),
                const SizedBox(height: 4),
                Text('Créez votre première classe pour commencer à enseigner.',
                    style: GoogleFonts.inter(fontSize: 13, color: AppColors.textSub), textAlign: TextAlign.center),
              ]),
            )
          else
            ...classrooms.map((c) => Padding(
              padding: const EdgeInsets.only(bottom: 10),
              child: _buildClassCard(context, c.name,
                  '${c.categoryDisplayName} · ${c.levelDisplayName} · ${c.totalStudents} élèves',
                  AppColors.primary),
            )),
          ElevatedButton.icon(
            onPressed: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const CreateClassroomScreen())),
            icon: const Icon(LucideIcons.plus, size: 16),
            label: const Text('Créer une nouvelle classe'),
          ),
        ],
      ),
    );
  }

  Widget _buildClassCard(BuildContext context, String name, String meta, Color color) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.border, width: 0.5),
      ),
      child: Column(
        children: [
          Container(
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              color: color,
              borderRadius: const BorderRadius.vertical(top: Radius.circular(16)),
            ),
            child: Row(
              children: [
                const Icon(LucideIcons.users, color: Colors.white, size: 20),
                const SizedBox(width: 10),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(name, style: GoogleFonts.nunito(fontSize: 14, fontWeight: FontWeight.w800, color: Colors.white)),
                      Text(meta, style: GoogleFonts.nunito(fontSize: 11, color: Colors.white.withOpacity(0.8))),
                    ],
                  ),
                ),
                IconButton(
                  icon: const Icon(LucideIcons.share2, size: 16, color: Colors.white),
                  onPressed: () {},
                ),
              ],
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(12),
            child: Column(
              children: [
                _buildStudentRow('Amira B.', 'AB', 87),
                _buildStudentRow('Youssef M.', 'YM', 64),
                _buildStudentRow('Sara K.', 'SK', 92),
                const SizedBox(height: 8),
                OutlinedButton.icon(
                  onPressed: () {},
                  icon: const Icon(LucideIcons.users, size: 14),
                  label: const Text('Inviter des étudiants'),
                  style: OutlinedButton.styleFrom(minimumSize: const Size.fromHeight(36)),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStudentRow(String name, String init, int score) {
    final c = score >= 80 ? AppColors.success : score >= 60 ? AppColors.primary : AppColors.error;
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        children: [
          CircleAvatar(radius: 14, backgroundColor: c.withOpacity(0.15),
            child: Text(init, style: GoogleFonts.nunito(fontSize: 10, fontWeight: FontWeight.w800, color: c))),
          const SizedBox(width: 10),
          Text(name, style: GoogleFonts.nunito(fontSize: 12, fontWeight: FontWeight.w600, color: AppColors.text)),
          const Spacer(),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
            decoration: BoxDecoration(color: c.withOpacity(0.12), borderRadius: BorderRadius.circular(20)),
            child: Text('$score%', style: GoogleFonts.nunito(fontSize: 11, fontWeight: FontWeight.w800, color: c)),
          ),
        ],
      ),
    );
  }
}

// ── Rooms Tab ─────────────────────────────────────────────────
class _RoomsTab extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    final rooms = [
      ('QSM Bio Cell. — Session 1', 'SKW-4821', 18, 30, true),
      ('QSM Algèbre — Session 3', 'SKW-3312', 22, 20, false),
      ('QSM Thermo — Révision', 'SKW-7734', 15, 45, false),
    ];
    return SingleChildScrollView(
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
          ...rooms.map((r) => _RoomCard(name: r.$1, code: r.$2, students: r.$3, timer: r.$4, isLive: r.$5)),
          const SizedBox(height: 12),
          ElevatedButton.icon(
            onPressed: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const CreateRoomScreen())),
            icon: const Icon(LucideIcons.plus, size: 16),
            label: const Text('Créer une nouvelle Room'),
            style: ElevatedButton.styleFrom(minimumSize: const Size.fromHeight(48)),
          ),
        ],
      ),
    );
  }
}

class _RoomCard extends StatelessWidget {
  final String name, code;
  final int students, timer;
  final bool isLive;
  const _RoomCard({required this.name, required this.code, required this.students, required this.timer, required this.isLive});

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: isLive ? AppColors.success.withOpacity(0.4) : AppColors.border, width: isLive ? 1 : 0.5),
      ),
      child: Column(
        children: [
          Row(
            children: [
              Container(
                width: 8, height: 8,
                decoration: BoxDecoration(color: isLive ? AppColors.success : AppColors.textSub, shape: BoxShape.circle),
              ),
              const SizedBox(width: 8),
              Expanded(child: Text(name, style: GoogleFonts.nunito(fontSize: 13, fontWeight: FontWeight.w700, color: AppColors.text))),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                decoration: BoxDecoration(
                  color: isLive ? AppColors.successLight : AppColors.background,
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Text(
                  isLive ? 'En direct' : 'Terminé',
                  style: GoogleFonts.nunito(fontSize: 10, fontWeight: FontWeight.w800, color: isLive ? AppColors.success : AppColors.textSub),
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          Row(
            children: [
              _RoomMeta(icon: LucideIcons.users, label: '$students étudiants'),
              const SizedBox(width: 14),
              _RoomMeta(icon: LucideIcons.clock, label: '$timer min'),
              const Spacer(),
              GestureDetector(
                onTap: () {
                  Clipboard.setData(ClipboardData(text: 'https://skwilti.ma/room/$code'));
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text('Lien copié !'), duration: const Duration(seconds: 2)),
                  );
                },
                child: Row(
                  children: [
                    const Icon(LucideIcons.link, size: 13, color: AppColors.primary),
                    const SizedBox(width: 4),
                    Text(code, style: GoogleFonts.nunito(fontSize: 11, fontWeight: FontWeight.w700, color: AppColors.primary)),
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
  
  static const _classes = <String>[];
  static const _rooms = <int, List<String>>{};
  static const _students = <int, List<(String, String, int, String, String)>>{};

  double get _averageScore {
    final currentStudents = _students[_selectedClass] ?? [];
    if (currentStudents.isEmpty) return 0.0;
    final total = currentStudents.map((s) => s.$3).reduce((a, b) => a + b);
    return total / currentStudents.length;
  }

  int get _successCount {
    final currentStudents = _students[_selectedClass] ?? [];
    return currentStudents.where((s) => s.$3 >= 80).length;
  }

  int get _difficultyCount {
    final currentStudents = _students[_selectedClass] ?? [];
    return currentStudents.where((s) => s.$3 < 60).length;
  }

  @override
  Widget build(BuildContext context) {
    if (_classes.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const SizedBox(height: 100),
            Icon(LucideIcons.inbox, size: 48, color: AppColors.textSub.withOpacity(0.5)),
            const SizedBox(height: 16),
            Text(
              'Aucune donnée disponible',
              style: GoogleFonts.inter(
                fontSize: 16,
                fontWeight: FontWeight.w600,
                color: AppColors.textSub,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'Les notes de vos étudiants apparaîtront ici.',
              style: GoogleFonts.inter(
                fontSize: 13,
                color: AppColors.textSub.withOpacity(0.8),
              ),
            ),
          ],
        ),
      );
    }

    final currentStudents = _students[_selectedClass] ?? [];
    final currentRooms = _rooms[_selectedClass] ?? [];
    
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // ─── Class Selector ─────────────────────────────────────
          _buildClassSelector(),
          const SizedBox(height: 16),
          
          // ─── Room Selector ─────────────────────────────────────
          _buildRoomSelector(currentRooms),
          const SizedBox(height: 20),
          
          // ─── Stats Cards ───────────────────────────────────────
          Row(
            children: [
              Expanded(child: _StatCard(label: 'Moyenne classe', value: '${_averageScore.toInt()}%', icon: LucideIcons.trendingUp, color: AppColors.primary)),
              const SizedBox(width: 10),
              Expanded(child: _StatCard(label: 'Réussite', value: '$_successCount/${currentStudents.length}', icon: LucideIcons.checkCircle, color: AppColors.primary)),
              const SizedBox(width: 10),
              Expanded(child: _StatCard(label: 'En difficulté', value: '$_difficultyCount', icon: LucideIcons.alertTriangle, color: AppColors.primary)),
            ],
          ),
          const SizedBox(height: 20),
          
          // ─── Students List (Library Style) ─────────────────────
          Text(
            'Résultats par étudiant',
            style: GoogleFonts.inter(
              fontSize: 16,
              fontWeight: FontWeight.w700,
              color: AppColors.text,
            ),
          ),
          const SizedBox(height: 12),
          
          // Students list
          ...currentStudents.map((student) {
            return Padding(
              padding: const EdgeInsets.only(bottom: 8),
              child: _StudentScoreCard(
                name: student.$1,
                initials: student.$2,
                score: student.$3,
                room: student.$4,
                time: student.$5,
              ),
            );
          }),
          const SizedBox(height: 20),
          
          // ─── Export Buttons ───────────────────────────────────
          Row(
            children: [
              Expanded(child: OutlinedButton.icon(
                onPressed: () {},
                icon: const Icon(LucideIcons.table, size: 16),
                label: const Text('Export Excel'),
                style: OutlinedButton.styleFrom(minimumSize: const Size.fromHeight(36)),
              )),
              const SizedBox(width: 10),
              Expanded(child: OutlinedButton.icon(
                onPressed: () {},
                icon: const Icon(LucideIcons.fileText, size: 16),
                label: const Text('Export PDF'),
                style: OutlinedButton.styleFrom(minimumSize: const Size.fromHeight(36)),
              )),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildClassSelector() {
    return Container(
      height: 40,
      child: ListView.builder(
        scrollDirection: Axis.horizontal,
        itemCount: _classes.length,
        itemBuilder: (context, index) {
          final isSelected = index == _selectedClass;
          return Container(
            margin: const EdgeInsets.only(right: 8),
            child: Material(
              color: Colors.transparent,
              child: InkWell(
                borderRadius: BorderRadius.circular(8),
                onTap: () => setState(() {
                  _selectedClass = index;
                  _selectedRoom = 0; // Reset room when class changes
                }),
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 200),
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                  decoration: BoxDecoration(
                    color: isSelected ? AppColors.primary : Colors.white,
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(
                      color: isSelected ? AppColors.primary : AppColors.border,
                      width: 1,
                    ),
                  ),
                  child: Center(
                    child: Text(
                      _classes[index],
                      style: GoogleFonts.inter(
                        fontSize: 12,
                        fontWeight: FontWeight.w500,
                        color: isSelected ? Colors.white : AppColors.text,
                      ),
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

  Widget _buildRoomSelector(List<String> rooms) {
    if (rooms.isEmpty) return const SizedBox.shrink();
    
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Rooms',
          style: GoogleFonts.inter(
            fontSize: 14,
            fontWeight: FontWeight.w700,
            color: AppColors.text,
          ),
        ),
        const SizedBox(height: 8),
        Container(
          height: 40,
          child: ListView.builder(
            scrollDirection: Axis.horizontal,
            itemCount: rooms.length,
            itemBuilder: (context, index) {
              final isSelected = index == _selectedRoom;
              return Container(
                margin: const EdgeInsets.only(right: 8),
                child: Material(
                  color: Colors.transparent,
                  child: InkWell(
                    borderRadius: BorderRadius.circular(20),
                    onTap: () => setState(() => _selectedRoom = index),
                    child: AnimatedContainer(
                      duration: const Duration(milliseconds: 200),
                      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                      decoration: BoxDecoration(
                        color: isSelected ? AppColors.success : AppColors.background,
                        borderRadius: BorderRadius.circular(20),
                        border: Border.all(
                          color: isSelected ? AppColors.success : AppColors.border,
                          width: 1,
                        ),
                      ),
                      child: Center(
                        child: Text(
                          rooms[index],
                          style: GoogleFonts.inter(
                            fontSize: 11,
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
      ],
    );
  }
}

// ── Student Score Card (Simple Style) ───────────────────────────
class _StudentScoreCard extends StatelessWidget {
  final String name;
  final String initials;
  final int score;
  final String room;
  final String time;
  
  const _StudentScoreCard({
    required this.name,
    required this.initials,
    required this.score,
    required this.room,
    required this.time,
  });

  Color get _scoreColor {
    if (score >= 80) return AppColors.success;
    if (score >= 60) return AppColors.primary;
    return AppColors.error;
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () {/* View student details */},
      child: Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: AppColors.border, width: 0.5),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // ── Student Info ─────────────────────────────────────
            Row(
              children: [
                CircleAvatar(
                  radius: 16,
                  backgroundColor: _scoreColor.withOpacity(0.1),
                  child: Text(
                    initials,
                    style: GoogleFonts.inter(
                      fontSize: 10,
                      fontWeight: FontWeight.w700,
                      color: _scoreColor,
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
                          fontSize: 12,
                          fontWeight: FontWeight.w700,
                          color: AppColors.text,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                      Text(
                        room,
                        style: GoogleFonts.inter(
                          fontSize: 10,
                          color: AppColors.textSub,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ],
                  ),
                ),
              ],
            ),
            
            const SizedBox(height: 12),
            
            // ── Score and Time ───────────────────────────────────
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: _scoreColor.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Text(
                    '$score%',
                    style: GoogleFonts.inter(
                      fontSize: 12,
                      fontWeight: FontWeight.w700,
                      color: _scoreColor,
                    ),
                  ),
                ),
                Row(
                  children: [
                    Icon(
                      LucideIcons.clock,
                      size: 12,
                      color: AppColors.textSub,
                    ),
                    const SizedBox(width: 4),
                    Text(
                      time,
                      style: GoogleFonts.inter(
                        fontSize: 10,
                        color: AppColors.textSub,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

// ── My Courses Tab ─────────────────────────────────────────────
class _MyCoursesTab extends StatefulWidget {
  @override
  _MyCoursesTabState createState() => _MyCoursesTabState();
}

class _MyCoursesTabState extends State<_MyCoursesTab> {
  int _selectedFiliere = 0;
  int _selectedSubject = 0;
  
  static const _filieres = [
    'Tronc Commun',
    '1ère Année Baccalauréat',
  ];
  
  static const _myCoursesSubjects = [
    {'label': 'Sciences Vie', 'color': AppColors.green},
    {'label': 'Maths', 'color': AppColors.primary},
    {'label': 'Physique', 'color': AppColors.info},
    {'label': 'Chimie', 'color': AppColors.warning},
  ];

  List<Map<String, dynamic>> get _myCourses {
    // Get courses uploaded by this teacher from Supabase
    final uploadedCourses = context.read<AppState>().teacherCourses;
    final filiere = _filieres[_selectedFiliere];
    final subject = _myCoursesSubjects[_selectedSubject]['label'] as String;
    
    // Filtre les cours de Supabase
    return uploadedCourses
        .where((course) => course['subject'] == subject)
        .map((course) => {
          ...course,
          'fileName': course['file_name'] ?? 'Inconnu',
          'semester': 'Semestre Actuel',
          'uploadedAt': course['created_at'] ?? DateTime.now().toIso8601String(),
          'filiere': filiere, // Fallback to current filiere since column is missing
          'isDefault': false,
        })
        .toList();
  }

  @override
  Widget build(BuildContext context) {
    final currentCourses = _myCourses;
    
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // ─── Upload Button ───────────────────────────────────────
        Padding(
          padding: const EdgeInsets.all(16),
          child: ElevatedButton.icon(
            onPressed: () {
              final filiere = _filieres[_selectedFiliere];
              final subject = _myCoursesSubjects[_selectedSubject]['label'] as String;
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (_) => LessonUploadScreen(
                    filiere: filiere,
                    subject: subject,
                    semester: 'Semestre Actuel',
                  ),
                ),
              );
            },
            icon: const Icon(LucideIcons.upload, size: 18),
            label: Text('Uploader cours', style: GoogleFonts.inter(fontWeight: FontWeight.w700)),
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.primary,
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
            ),
          ),
        ),
                
        // ─── Filière tabs ───────────────────────────────────────────
        Container(
          height: 40,
          padding: const EdgeInsets.symmetric(horizontal: 16),
          child: ListView.builder(
            scrollDirection: Axis.horizontal,
            itemCount: _filieres.length,
            itemBuilder: (context, index) {
              final isSelected = index == _selectedFiliere;
              return Container(
                margin: const EdgeInsets.only(right: 8),
                child: Material(
                  color: Colors.transparent,
                  child: InkWell(
                    borderRadius: BorderRadius.circular(20),
                    onTap: () => setState(() => _selectedFiliere = index),
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
                          _filieres[index],
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
        
        // ─── Subject chips ────────────────────────────────────────
        Container(
          height: 40,
          padding: const EdgeInsets.symmetric(horizontal: 16),
          child: ListView.builder(
            scrollDirection: Axis.horizontal,
            itemCount: _myCoursesSubjects.length,
            itemBuilder: (context, index) {
              final isSelected = index == _selectedSubject;
              final subject = _myCoursesSubjects[index];
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
        
        // ─── Courses List ─────────────────────────────────────────
        Expanded(
          child: ListView.separated(
            padding: const EdgeInsets.symmetric(horizontal: 16).copyWith(bottom: 32),
            itemCount: currentCourses.length,
            separatorBuilder: (_, __) => const SizedBox(height: 12),
            itemBuilder: (context, index) {
              final course = currentCourses[index];
              return _MyCourseCard(
                title: course['title'] as String? ?? 'Sans titre',
                description: course['description'] as String? ?? '',
                fileName: course['fileName'] as String? ?? 'Inconnu',
                semester: course['semester'] as String? ?? 'Semestre Inconnu',
                uploadedAt: course['uploadedAt'] as String? ?? DateTime.now().toIso8601String(),
                isDefault: course['isDefault'] as bool? ?? false,
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
  
  const _MyCourseCard({
    required this.title,
    required this.description,
    required this.fileName,
    required this.semester,
    required this.uploadedAt,
    this.isDefault = false,
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
              Icon(
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
                    onPressed: () {/* View course */},
                    icon: const Icon(LucideIcons.eye, size: 16),
                    color: AppColors.primary,
                  ),
                  if (!isDefault) ...[
                    IconButton(
                      onPressed: () {/* Edit course */},
                      icon: const Icon(LucideIcons.edit, size: 16),
                      color: AppColors.info,
                    ),
                    IconButton(
                      onPressed: () {/* Delete course */},
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
  int _selectedSubject = 0;
  final Set<int> _expandedSemesters = {};

  static const _filieres = [
    'Tronc Commun',
    '1ère Année Baccalauréat',
    '2ème Année Baccalauréat',
  ];

  static const _subjects = [
    {'icon': LucideIcons.calculator, 'label': 'Maths'},
    {'icon': LucideIcons.atom, 'label': 'Physique-Chimie'},
    {'icon': LucideIcons.microscope, 'label': 'SVT'},
    {'icon': LucideIcons.bookOpen, 'label': 'Français'},
    {'icon': LucideIcons.globe, 'label': 'Anglais'},
    {'icon': LucideIcons.history, 'label': 'Histoire-Géo'},
  ];

  // Cours par filière → matière → semestre
  static const _curriculum = <String, Map<String, List<Map<String, dynamic>>>>{
    'Tronc Commun': {
      'Maths': [
        {'title': 'Semestre 1', 'count': 12, 'lessons': ['Algèbre', 'Géométrie', 'Fonctions', 'Statistiques']},
        {'title': 'Semestre 2', 'count': 14, 'lessons': ['Nombres complexes', 'Suites', 'Intégrales', 'Probabilités']},
      ],
      'Physique-Chimie': [
        {'title': 'Semestre 1', 'count': 10, 'lessons': ['Mécanique', 'Thermodynamique', 'Optique']},
        {'title': 'Semestre 2', 'count': 11, 'lessons': ['Électricité', 'Chimie organique', 'Réactions chimiques']},
      ],
    },
    '1ère Année Baccalauréat': {
      'Maths': [
        {'title': 'Semestre 1', 'count': 15, 'lessons': ['Limites', 'Dérivées', 'Fonctions exponentielles']},
        {'title': 'Semestre 2', 'count': 16, 'lessons': ['Logarithmes', 'Trigonométrie', 'Géométrie analytique']},
      ],
    },
  };

  List<Map<String, dynamic>> get _currentSemesters {
    final subject = _subjects[_selectedSubject]['label'] as String;
    
    // Mapper les matières de l'upload vers les catégories de la bibliothèque
    List<String> mappedSubjects;
    if (subject == 'SVT') {
      mappedSubjects = ['Sciences Vie', 'SVT'];
    } else if (subject == 'Physique-Chimie') {
      mappedSubjects = ['Physique', 'Chimie', 'Physique-Chimie'];
    } else {
      mappedSubjects = [subject];
    }
    
    // Récupérer les cours depuis Supabase
    final uploadedLessons = context.read<AppState>().teacherCourses
        .where((course) => mappedSubjects.contains(course['subject'] as String?))
        .toList();
    
    // Filtrer par semestre
    final s1Lessons = uploadedLessons
        .where((course) => (course['description'] as String? ?? '').contains('Semestre 1'))
        .map((lesson) => lesson['title'] as String? ?? 'Sans titre')
        .toList();

    final s2Lessons = uploadedLessons
        .where((course) => (course['description'] as String? ?? '').contains('Semestre 2'))
        .map((lesson) => lesson['title'] as String? ?? 'Sans titre')
        .toList();

    // Pour les cours qui n'ont pas de semestre défini ou différent
    final otherLessons = uploadedLessons
        .where((course) {
          final desc = course['description'] as String? ?? '';
          return !desc.contains('Semestre 1') && !desc.contains('Semestre 2');
        })
        .map((lesson) => lesson['title'] as String? ?? 'Sans titre')
        .toList();
        
    s1Lessons.addAll(otherLessons); // Par défaut on les met dans le S1 s'ils n'ont pas de semestre
      
    return [
      {
        'title': 'Semestre 1',
        'count': s1Lessons.length,
        'lessons': s1Lessons,
        'uploadedCount': s1Lessons.length,
      },
      {
        'title': 'Semestre 2',
        'count': s2Lessons.length,
        'lessons': s2Lessons,
        'uploadedCount': s2Lessons.length,
      }
    ];
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // ─── Titre Bibliothèque ────────────────────────────────────
        const SizedBox(height: 8),

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
              return _SemesterSection(
                title: sem['title'] as String,
                lessonCount: sem['count'] as int,
                lessons: (sem['lessons'] as List<String>),
                isExpanded: expanded,
                semesterData: sem,
                onToggle: () => setState(() {
                  expanded ? _expandedSemesters.remove(i) : _expandedSemesters.add(i);
                }),
                onUpload: () => _showLessonUploadDialog(sem['title'] as String),
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
                Icon(subject['icon'] as IconData, size: 16,
                    color: active ? Colors.white : const Color(0xFF888888)),
                const SizedBox(width: 7),
                Text(
                  subject['label'] as String,
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

  void _showUploadDialog() {
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        title: Text('Créer QSM', style: GoogleFonts.inter(fontWeight: FontWeight.w700)),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text('Choisissez la filière et la matière', style: GoogleFonts.inter()),
            const SizedBox(height: 16),
            Text('Filière: ${_filieres[_selectedFiliere]}', style: GoogleFonts.inter(fontWeight: FontWeight.w600)),
            Text('Matière: ${_subjects[_selectedSubject]['label'] as String}', style: GoogleFonts.inter(fontWeight: FontWeight.w600)),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text('Annuler', style: GoogleFonts.inter()),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(context);
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (_) => UploadScreen(),
                ),
              );
            },
            child: Text('Continuer', style: GoogleFonts.inter(fontWeight: FontWeight.w700)),
          ),
        ],
      ),
    );
  }

  void _showLessonUploadDialog(String semesterTitle) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => LessonUploadScreen(
          filiere: 'Général',
          subject: 'Général',
          semester: semesterTitle,
        ),
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
                    child: Icon(LucideIcons.chevronDown,
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
            Icon(LucideIcons.chevronRight, size: 18, color: AppColors.textSub),
          ],
        ),
      ),
    );
  }
}