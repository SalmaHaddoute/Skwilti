import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../models/question.dart';
import '../models/course.dart';
import '../models/user.dart' as app_user;
import '../models/classroom.dart';
import '../models/room.dart';
import '../models/statistics.dart';
import '../models/qsm_session.dart';
import 'auth_service.dart';
import 'webhook_service.dart';
import 'messaging_service.dart';

class AppState extends ChangeNotifier {
  final AuthService _authService = AuthService();
  bool _isAuthenticated = false;
  
  // ── Configuration n8n ─────────────────────────────────────────
  // URL du webhook n8n pour la génération de QCM
  String n8nWebhookUrl = 'http://10.0.2.2:5678/webhook/generate-qcm';
  
  // Messaging unread count
  int _unreadMessages = 0;
  int get unreadMessagesCount => _unreadMessages;
  void setUnreadMessagesCount(int v) { _unreadMessages = v; notifyListeners(); }
  final MessagingService _messagingService = MessagingService();

  // ── Realtime notification subscription ───────────────────────
  RealtimeChannel? _notifChannel;
  /// Callback called when a new room_join notification arrives (teacher)
  void Function(String title, String body)? onNewNotification;

  // ── Authentication ────────────────────────────────────────────
  app_user.User? get currentUser    => _authService.currentUser;
  bool get isAuthenticated          => _isAuthenticated;
  List<Classroom> get userClassrooms => _authService.userClassrooms;
  List<Room> get userRooms          => _authService.userRooms;
  UserStatistics? get userStats     => _authService.userStats;
  AuthService get authService       => _authService;

  // ── Init ──────────────────────────────────────────────────────
  Future<void> init() async {
    try {
      final user = await _authService.restoreSession();
      if (user != null) {
        _isAuthenticated = true;
        
        // Load initial unread messages count
        await _loadUnreadMessagesCount(user.id);
        
        // subscribe to messages for realtime updates
        _messagingService.subscribeToUserMessages(user.id);
        _messagingService.onMessage.listen((m) {
          // simple unread incrementation; more advanced logic could check active conversation
          _unreadMessages += 1;
          notifyListeners();
        });
        notifyListeners();
      }
    } catch (e) {
      print('🔴 init error: $e');
    }
  }

  // Load total unread messages count
  Future<void> _loadUnreadMessagesCount(String userId) async {
    try {
      final conversations = await _messagingService.fetchConversations(userId);
      int totalUnread = 0;
      for (var conv in conversations) {
        totalUnread += conv.unreadCount ?? 0;
      }
      _unreadMessages = totalUnread;
      notifyListeners();
    } catch (e) {
      print('🔴 Error loading unread messages count: $e');
    }
  }

  // Refresh unread messages count (call this when returning to app or after reading messages)
  Future<void> refreshUnreadMessagesCount() async {
    if (currentUser != null) {
      await _loadUnreadMessagesCount(currentUser!.id);
    }
  }

  // ── QSM Session ───────────────────────────────────────────────
  QsmSession? _currentSession;
  QsmSession? get currentSession => _currentSession;

  // ── Questions ─────────────────────────────────────────────────
  List<Question> _questions = [];
  List<Question> get questions    => _questions.where((q) => !q.isDeleted).toList();
  List<Question> get allQuestions => _questions;

  String _courseTitle   = '';
  String get courseTitle => _courseTitle;

  String? _currentCourseId;
  String? get currentCourseId => _currentCourseId;
  set currentCourseId(String? value) {
    _currentCourseId = value;
    notifyListeners();
  }

  String _courseSummary   = '';
  String get courseSummary => _courseSummary;

  List<String> _keywords = [];
  List<String> get keywords => _keywords;

  // ── Données réelles Supabase (chargées dynamiquement) ─────────

  // Sessions récentes de l'étudiant
  List<Map<String, dynamic>> get recentSessions => _authService.recentSessions;
  bool _sessionsLoaded = false;
  bool get sessionsLoaded => _sessionsLoaded;

  // Scores hebdomadaires (courbe de performance)
  List<Map<String, dynamic>> get weeklyScores => _authService.weeklyScores;

  // Cours de l'enseignant
  List<Map<String, dynamic>> _teacherCourses = [];
  List<Map<String, dynamic>> get teacherCourses => _teacherCourses;
  bool _teacherCoursesLoaded = false;
  bool get teacherCoursesLoaded => _teacherCoursesLoaded;

  // Activité hebdomadaire enseignant/admin
  Map<int, int> _weeklyActivity = {0: 0, 1: 0, 2: 0, 3: 0, 4: 0, 5: 0, 6: 0};
  Map<int, int> get weeklyActivity => _weeklyActivity;

  // Utilisateurs admin
  List<Map<String, dynamic>> _adminUsers = [];
  List<Map<String, dynamic>> get adminUsers => _adminUsers;
  bool _adminUsersLoaded = false;
  bool get adminUsersLoaded => _adminUsersLoaded;

  // Cours pour l'admin
  List<Map<String, dynamic>> _adminCourses = [];
  List<Map<String, dynamic>> get adminCourses => _adminCourses;
  bool _adminCoursesLoaded = false;
  bool get adminCoursesLoaded => _adminCoursesLoaded;

  // Stats globales admin
  GlobalStatistics? _globalStats;
  GlobalStatistics? get globalStats => _globalStats;
  bool _globalStatsLoaded = false;
  bool get globalStatsLoaded => _globalStatsLoaded;

  // Toutes les classes (pour création de room)
  List<Classroom> _allClassrooms = [];
  bool _allClassroomsLoaded = false;
  List<Classroom> get allClassrooms => _allClassrooms;
  bool get allClassroomsLoaded => _allClassroomsLoaded;

  // Données enfant (pour parent)
  Map<String, dynamic>? _childProfile;
  Map<String, dynamic>? get childProfile => _childProfile;
  List<Map<String, dynamic>> _childSessions = [];
  List<Map<String, dynamic>> get childSessions => _childSessions;
  List<Map<String, dynamic>> _childTeachers = [];
  List<Map<String, dynamic>> get childTeachers => _childTeachers;
  bool _childDataLoaded = false;
  bool get childDataLoaded => _childDataLoaded;

  // n8n configuration
  String _n8nUrl = 'http://10.0.2.2:5678/webhook/skwilti_app';
  String get n8nUrl => _n8nUrl;
  void setN8nUrl(String url) { _n8nUrl = url; notifyListeners(); }

  // Loading state
  bool _isLoading = false;
  bool get isLoading => _isLoading;
  double _loadingProgress = 0.0;
  double get loadingProgress => _loadingProgress;
  String _loadingStep = '';
  String get loadingStep => _loadingStep;

  // Leçons uploadées
  final List<Map<String, dynamic>> _uploadedLessons = [];
  List<Map<String, dynamic>> get uploadedLessons => _uploadedLessons;
  void addLesson(Map<String, dynamic> lesson) {
    _uploadedLessons.add(lesson);
    notifyListeners();
  }

  // ── Chargement dynamique ──────────────────────────────────────
  
  // Notifications
  List<Map<String, dynamic>> _notifications = [];
  bool _notificationsLoaded = false;
  List<Map<String, dynamic>> get notifications => _notifications;
  bool get notificationsLoaded => _notificationsLoaded;

  Future<void> loadNotifications() async {
    _notifications = await _authService.fetchNotifications();
    _notificationsLoaded = true;
    notifyListeners();
  }

  Future<void> submitComplaint({
    required String email,
    required String subject,
    required String description,
  }) async {
    await _authService.submitComplaint(
      email: email,
      subject: subject,
      description: description,
    );
  }

  int get unreadNotificationsCount => _notifications.where((n) => !(n['is_read'] ?? false)).length;

  /// S'abonne aux notifications Realtime pour l'enseignant connecté
  void subscribeToTeacherNotifications(String teacherId) {
    _notifChannel?.unsubscribe();
    _notifChannel = Supabase.instance.client
        .channel('teacher_notifs_$teacherId')
        .onPostgresChanges(
          event: PostgresChangeEvent.insert,
          schema: 'public',
          table: 'notifications',
          filter: PostgresChangeFilter(
            type: PostgresChangeFilterType.eq,
            column: 'user_id',
            value: teacherId,
          ),
          callback: (payload) {
            final newRow = payload.newRecord;
            final title = newRow['title']?.toString() ?? 'Notification';
            final body  = newRow['body']?.toString()  ?? '';
            // Ajouter en tête de liste
            _notifications = [newRow, ..._notifications];
            notifyListeners();
            // Déclencher le callback UI (snackbar)
            onNewNotification?.call(title, body);
          },
        )
        .subscribe();
  }

  /// Se désabonne des notifications Realtime
  void unsubscribeFromNotifications() {
    _notifChannel?.unsubscribe();
    _notifChannel = null;
  }

  /// Charge les données complètes de l'utilisateur (classes, stats, etc.)
  Future<void> loadUserData() async {
    if (currentUser == null) return;
    await _authService.loadUserData();
    notifyListeners();
  }
 
  /// Rejoindre une room par son code
  Future<Map<String, dynamic>?> joinRoomByCode(String code) async {
    final roomData = await _authService.fetchRoomByCode(code);
    if (roomData == null) return null;

    final roomId = roomData['id']?.toString();
    if (roomId != null && currentUser != null) {
      final alreadyDone = await _authService.hasCompletedSession(roomId: roomId);
      if (alreadyDone) {
        throw Exception('Vous avez déjà complété le QSM de cette room.');
      }
    }
 
    final sessionData = roomData['quiz_sessions'];
    final questionsData = roomData['questions'] as List<dynamic>? ?? [];
    
    if (questionsData.isEmpty) {
      print('⚠️ joinRoomByCode: Aucune question trouvée pour cette room');
      return null;
    }

    final questions = questionsData.map((q) => Question.fromJson(q)).toList();

    // Utiliser les données de session si dispo, sinon fallback sur la room
    final session = QsmSession(
      id: sessionData?['id']?.toString() ?? roomData['qcm_session_id']?.toString() ?? 'session_tmp',
      courseTitle: sessionData?['title'] ?? roomData['name'] ?? 'QSM',
      questions: questions,
      createdAt: DateTime.tryParse(sessionData?['created_at'] ?? roomData['created_at'] ?? '') ?? DateTime.now(),
      courseId: sessionData?['course_id']?.toString(), // Ajouter le courseId depuis la session
      timerMinutes: roomData['timer_minutes'],
      roomId: roomData['id'].toString(),
      classroomId: roomData['classroom_id']?.toString(),
      userAnswers: List.filled(questions.length, null),
    );
 
    _currentSession = session;
    _currentCourseId = sessionData?['course_id']?.toString() ?? roomData['qcm_session_id']?.toString();
    notifyListeners();

    // 🔔 Notifier l'enseignant qu'un élève a rejoint
    final teacherId = roomData['teacher_id']?.toString();
    if (teacherId != null && teacherId.isNotEmpty && currentUser != null) {
      final studentName = currentUser!.fullName.isNotEmpty
          ? currentUser!.fullName
          : (currentUser!.email ?? 'Un élève');
      final roomName = roomData['name']?.toString() ?? 'la room';
      final roomId = roomData['id']?.toString() ?? '';
      _authService.sendRoomJoinNotification(
        teacherId: teacherId,
        studentName: studentName,
        roomName: roomName,
        roomId: roomId,
      );
    }

    return roomData;
  }
 

  /// Charge les sessions récentes de l'étudiant connecté
  Future<void> loadStudentSessions() async {
    if (currentUser == null) return;
    _sessionsLoaded = false;
    notifyListeners();
    await _authService.loadUserData();
    _sessionsLoaded = true;
    notifyListeners();
  }

  /// Charge les cours de l'enseignant connecté
  Future<void> loadTeacherCourses() async {
    if (currentUser == null) return;
    _teacherCoursesLoaded = false;
    notifyListeners();
    _teacherCourses       = await _authService.fetchTeacherCourses(currentUser!.id);
    _weeklyActivity       = await _authService.fetchTeacherWeeklyActivity(currentUser!.id);
    await loadTeacherRooms(); // Charger les rooms
    _teacherCoursesLoaded = true;
    notifyListeners();
  }

  /// Charge les rooms de l'enseignant
  Future<void> loadTeacherRooms() async {
    if (currentUser == null) return;
    await _authService.fetchTeacherRooms(currentUser!.id);
    notifyListeners();
  }

  /// Sessions de la room sélectionnée (pour Notes)
  List<Map<String, dynamic>> _currentRoomSessions = [];
  bool _roomSessionsLoaded = false;
  List<Map<String, dynamic>> get currentRoomSessions => _currentRoomSessions;
  bool get roomSessionsLoaded => _roomSessionsLoaded;

  Future<void> loadRoomSessions(String roomId) async {
    _roomSessionsLoaded = false;
    notifyListeners();
    _currentRoomSessions = await _authService.fetchRoomSessions(roomId);
    _roomSessionsLoaded = true;
    notifyListeners();
  }

  /// Upload un cours vers Supabase et retourne l'ID
  Future<String> uploadCourse(Map<String, dynamic> courseData) async {
    final id = await _authService.uploadCourse(courseData);
    await loadTeacherCourses(); // Recharger la liste après l'upload
    return id;
  }

  /// Charge les utilisateurs pour l'admin
  Future<void> loadAdminUsers({String? roleFilter}) async {
    _adminUsersLoaded = false;
    notifyListeners();
    _adminUsers       = await _authService.fetchAllUsers(roleFilter: roleFilter);
    _adminUsersLoaded = true;
    notifyListeners();
  }

  /// Charge tous les cours pour l'admin
  Future<void> loadAdminCourses() async {
    _adminCoursesLoaded = false;
    notifyListeners();
    _adminCourses       = await _authService.fetchAllCourses();
    _adminCoursesLoaded = true;
    notifyListeners();
  }

  /// Crée un nouveau cours (admin)
  Future<void> createCourse(Map<String, dynamic> courseData) async {
    await _authService.createCourse(courseData);
    await loadAdminCourses();
  }

  /// Crée un cours enseignant pour les QSM générés sans enregistrement initial
  Future<String?> createTeacherCourse(Map<String, dynamic> courseData) async {
    if (currentUser == null) return null;
    final response = await _authService.createCourse({
      ...courseData,
      'teacher_id': currentUser!.id,
    });
    await loadTeacherCourses();
    return response['id']?.toString();
  }

  /// Met à jour un cours (admin)
  Future<void> updateCourse(String courseId, Map<String, dynamic> courseData) async {
    await _authService.updateCourse(courseId, courseData);
    await loadAdminCourses();
  }

  /// Supprime un cours (admin)
  Future<void> deleteCourse(String courseId) async {
    await _authService.deleteCourse(courseId);
    await loadAdminCourses();
    await loadTeacherCourses();
  }

  /// Met à jour le profil utilisateur
  Future<void> updateProfile({
    required String firstName,
    required String lastName,
    required String email,
  }) async {
    await _authService.updateProfile(
      firstName: firstName,
      lastName: lastName,
      email: email,
    );
    notifyListeners();
  }

  // ─── Filières ───────────────────────────────────────────
  List<Map<String, dynamic>> _filieres = [];
  bool _filieresLoaded = false;
  List<Map<String, dynamic>> get filieres => _filieres;
  bool get filieresLoaded => _filieresLoaded;

  Future<void> loadFilieres() async {
    _filieresLoaded = false;
    notifyListeners();
    _filieres = await _authService.fetchAllFilieres();
    _filieresLoaded = true;
    notifyListeners();
  }

  Future<void> createFiliere(Map<String, dynamic> data) async {
    await _authService.createFiliere(data);
    await loadFilieres();
  }

  Future<void> updateFiliere(String id, Map<String, dynamic> data) async {
    await _authService.updateFiliere(id, data);
    await loadFilieres();
  }

  Future<void> deleteFiliere(String id) async {
    await _authService.deleteFiliere(id);
    await loadFilieres();
  }

  // ─── Niveaux ────────────────────────────────────────────
  List<Map<String, dynamic>> _niveaux = [];
  bool _niveauxLoaded = false;
  List<Map<String, dynamic>> get niveaux => _niveaux;
  bool get niveauxLoaded => _niveauxLoaded;

  Future<void> loadNiveaux() async {
    _niveauxLoaded = false;
    notifyListeners();
    _niveaux = await _authService.fetchAllNiveaux();
    _niveauxLoaded = true;
    notifyListeners();
  }

  /// Charge toutes les classes du système
  Future<void> loadAllClassrooms() async {
    _allClassroomsLoaded = false;
    notifyListeners();
    _allClassrooms = await _authService.fetchAllClassrooms();
    _allClassroomsLoaded = true;
    notifyListeners();
  }

  Future<void> createNiveau(Map<String, dynamic> data) async {
    await _authService.createNiveau(data);
    await loadNiveaux();
  }

  Future<void> updateNiveau(String id, Map<String, dynamic> data) async {
    await _authService.updateNiveau(id, data);
    await loadNiveaux();
  }

  Future<void> deleteNiveau(String id) async {
    await _authService.deleteNiveau(id);
    await loadNiveaux();
  }

  // ─── Matières ───────────────────────────────────────────
  List<Map<String, dynamic>> _matieres = [];
  bool _matieresLoaded = false;
  List<Map<String, dynamic>> get matieres => _matieres;
  bool get matieresLoaded => _matieresLoaded;

  Future<void> loadMatieres() async {
    _matieresLoaded = false;
    notifyListeners();
    _matieres = await _authService.fetchAllMatieres();
    _matieresLoaded = true;
    notifyListeners();
  }

  Future<void> createMatiere(Map<String, dynamic> data) async {
    await _authService.createMatiere(data);
    await loadMatieres();
  }

  Future<void> updateMatiere(String id, Map<String, dynamic> data) async {
    await _authService.updateMatiere(id, data);
    await loadMatieres();
  }

  Future<void> deleteMatiere(String id) async {
    await _authService.deleteMatiere(id);
    await loadMatieres();
  }

  // ─── Classes Scolaires ────────────────────────────────────
  List<Map<String, dynamic>> _classesScolaires = [];
  bool _classesScolairesLoaded = false;
  List<Map<String, dynamic>> get classesScolaires => _classesScolaires;
  bool get classesScolairesLoaded => _classesScolairesLoaded;

  Future<void> loadClassesScolaires() async {
    _classesScolairesLoaded = false;
    notifyListeners();
    _classesScolaires = await _authService.fetchAllClassesScolaires();
    _classesScolairesLoaded = true;
    notifyListeners();
  }

  Future<void> createClasseScolaire({
    required String filiereId,
    required String niveauId,
    required String nom,
    required String anneeScolaire,
  }) async {
    await _authService.createClasseScolaire(
      filiereId: filiereId,
      niveauId: niveauId,
      nom: nom,
      anneeScolaire: anneeScolaire,
    );
    await loadClassesScolaires();
  }

  // ─── Teachers ────────────────────────────────────────────
  List<Map<String, dynamic>> _teachers = [];
  bool _teachersLoaded = false;
  List<Map<String, dynamic>> get teachers => _teachers;
  bool get teachersLoaded => _teachersLoaded;

  Future<void> loadTeachers() async {
    _teachersLoaded = false;
    notifyListeners();
    _teachers = await _authService.fetchAllTeachers();
    _teachersLoaded = true;
    notifyListeners();
  }

  // ─── Classe Profs ───────────────────────────────────────
  Future<List<Map<String, dynamic>>> fetchClasseProfs(String classeId) async {
    return await _authService.fetchClasseProfs(classeId);
  }

  Future<void> createClasseProf({
    required String classeId,
    required String matiereId,
    required String professeurId,
  }) async {
    await _authService.createClasseProf(
      classeId: classeId,
      matiereId: matiereId,
      professeurId: professeurId,
    );
  }

  Future<void> deleteClasseProf(String assignmentId) async {
    await _authService.deleteClasseProf(assignmentId);
  }

  // ─── Étudiants ────────────────────────────────────────────
  Future<void> createEtudiantAndAddToClasse({
    required String classeId,
    required String codeMassar,
    required String prenom,
    required String nom,
    required String dateNaissance,
    required String cin,
    required String email,
    required String telephone,
  }) async {
    await _authService.createEtudiantAndAddToClasse(
      classeId: classeId,
      codeMassar: codeMassar,
      prenom: prenom,
      nom: nom,
      dateNaissance: dateNaissance,
      cin: cin,
      email: email,
      telephone: telephone,
    );
  }

  Future<void> assignEtudiantToClasse({
    required String studentId,
    required String classeId,
  }) async {
    await _authService.assignEtudiantToClasse(
      studentId: studentId,
      classeId: classeId,
    );
    await loadAdminUsers(); // Recharger pour voir l'étudiant dans sa nouvelle classe
  }

  // ─── Parents ────────────────────────────────────────────
  List<Map<String, dynamic>> _adminParents = [];
  bool _adminParentsLoaded = false;
  List<Map<String, dynamic>> get adminParents => _adminParents;
  bool get adminParentsLoaded => _adminParentsLoaded;

  Future<void> loadAdminParents() async {
    _adminParentsLoaded = false;
    notifyListeners();
    _adminParents = await _authService.fetchAdminParents();
    _adminParentsLoaded = true;
    notifyListeners();
  }

  Future<void> linkParentEnfant(String parentId, String enfantId, {String relation = 'parent'}) async {
    await _authService.linkParentEnfant(parentId, enfantId, relation: relation);
    await loadAdminParents();
  }

  Future<void> updateParentEnfant(String parentId, String enfantId, Map<String, dynamic> data) async {
    await _authService.updateParentEnfant(parentId, enfantId, data);
    await loadAdminParents();
  }

  Future<void> unlinkParentEnfant(String parentId, String enfantId) async {
    await _authService.unlinkParentEnfant(parentId, enfantId);
    await loadAdminParents();
  }

  /// Charge les stats globales pour l'admin
  Future<void> loadGlobalStats() async {
    _globalStatsLoaded = false;
    notifyListeners();
    try {
      _globalStats       = await _authService.getGlobalStatistics();
      _weeklyActivity    = await _authService.fetchAdminWeeklyActivity();
    } catch (_) {}
    _globalStatsLoaded = true;
    notifyListeners();
  }

  /// Charge les données de l'enfant lié (pour le parent)
  Future<void> loadChildData() async {
    if (currentUser == null) return;
    
    String? childId = currentUser?.linkedChildId;
    
    // Si pas de childId enregistré dans le profil, on cherche le premier lien existant
    childId ??= await _authService.fetchFirstLinkedChildId(currentUser!.id);

    if (childId == null) {
      _childDataLoaded = true;
      notifyListeners();
      return;
    }

    _childDataLoaded = false;
    notifyListeners();
    _childProfile  = await _authService.fetchChildProfile(childId);
    _childSessions = await _authService.fetchChildSessions(childId);
    _childTeachers = await _authService.fetchChildTeachers(childId);
    _childDataLoaded = true;
    notifyListeners();
  }

  // ── Questions / Session ───────────────────────────────────────

  void setQuestions(List<Question> questions, {
    String title = '',
    String summary = '',
    List<String> keywords = const [],
    String? courseId,
  }) {
    _questions     = questions;
    _courseTitle   = title;
    _courseSummary = summary;
    _keywords      = keywords;
    _currentCourseId = courseId;
    notifyListeners();
  }

  void deleteQuestion(String id) {
    final idx = _questions.indexWhere((q) => q.id == id);
    if (idx != -1) {
      _questions[idx].isDeleted = true;
      notifyListeners();
    }
  }

  void answerQuestion(int questionIndex, int answerIndex) {
    if (_currentSession != null) {
      _currentSession!.userAnswers[questionIndex] = answerIndex;
      notifyListeners();
    }
  }

  Future<void> loadQcmForCourse(String courseId, String courseTitle) async {
    try {
      final fetchedQuestions = await WebhookService().fetchQuestionsForCourse(courseId);
      if (fetchedQuestions.isNotEmpty) {
        _questions = fetchedQuestions;
        _courseTitle = courseTitle;
        _currentCourseId = courseId;
        
        // Récupérer le vrai ID de session depuis Supabase
        String? realSessionId = await _authService.fetchSessionIdByCourseId(courseId);
        
        // Utiliser l'ID de session réel, ou l'ID du cours (qui est un UUID), ou le timestamp en dernier recours
        String finalSessionId = realSessionId ?? courseId;
        
        _currentSession = QsmSession(
          id: finalSessionId,
          courseTitle: courseTitle,
          questions: fetchedQuestions,
          createdAt: DateTime.now(),
          userAnswers: List.filled(fetchedQuestions.length, null),
          courseId: courseId, // Ajouter le courseId
        );
        
        notifyListeners();
      }
    } catch (e) {
      debugPrint('Error loading QCM for course: $e');
    }
  }

  void startSession() {
    if (_currentSession == null) return;
    _currentSession = QsmSession(
      id: _currentSession!.id,
      courseTitle: _currentSession!.courseTitle,
      questions: _currentSession!.questions,
      createdAt: _currentSession!.createdAt,
      userAnswers: _currentSession!.userAnswers,
      completedAt: _currentSession!.completedAt,
      courseId: _currentSession!.courseId, // Préserver le courseId
      classroomId: _currentSession!.classroomId,
      roomId: _currentSession!.roomId,
      timerMinutes: _currentSession!.timerMinutes,
      startedAt: DateTime.now(),
      endedAt: _currentSession!.endedAt,
      allowBackNavigation: _currentSession!.allowBackNavigation,
      showResultsImmediately: _currentSession!.showResultsImmediately,
      settings: _currentSession!.settings,
    );
    notifyListeners();
  }

  Future<void> completeSession() async {
    if (_currentSession != null) {
      _currentSession!.completedAt = DateTime.now();
      
      // Enregistrer le résultat dans la base de données
      await _authService.saveSessionResult(
        sessionId: _currentSession!.id,
        courseId: _currentCourseId ?? _currentSession!.id,
        roomId: _currentSession!.roomId,
        classroomId: _currentSession!.classroomId,
        score: _currentSession!.correctAnswers,
        totalQuestions: _currentSession!.totalQuestions,
        answers: {
          'responses': _currentSession!.userAnswers,
        },
      );
      
      notifyListeners();
    }
  }

  void setCurrentSession(QsmSession? session) {
    _currentSession = session;
    notifyListeners();
  }

  void setLoading(bool loading, {double progress = 0, String step = ''}) {
    _isLoading         = loading;
    _loadingProgress   = progress;
    _loadingStep       = step;
    notifyListeners();
  }

  // ── Auth ──────────────────────────────────────────────────────

  Future<app_user.User> login(String email, String password) async {
    final user = await _authService.login(email, password);
    _isAuthenticated = true;
    notifyListeners();
    return user;
  }

  Future<app_user.User> register({
    required String email,
    required String password,
    required String firstName,
    required String lastName,
    required app_user.UserRole role,
    required app_user.SubscriptionType? subscription,
  }) async {
    final user = await _authService.register(
      email: email,
      password: password,
      firstName: firstName,
      lastName: lastName,
      role: role,
      subscription: subscription ?? app_user.SubscriptionType.free,
    );
    _isAuthenticated = true;
    notifyListeners();
    return user;
  }

  Future<void> adminCreateUser({
    required String email,
    required String password,
    required String firstName,
    required String lastName,
    required app_user.UserRole role,
    required app_user.SubscriptionType subscription,
  }) async {
    await _authService.adminCreateUser(
      email: email,
      password: password,
      firstName: firstName,
      lastName: lastName,
      role: role,
      subscription: subscription,
    );
    await loadAdminUsers();
    await loadGlobalStats();
    notifyListeners();
  }

  Future<void> logout() async {
    await _authService.logout();
    _isAuthenticated = false;
    reset();
    notifyListeners();
  }

  // ── Classrooms ────────────────────────────────────────────────

  Future<Classroom> createClassroom({
    required String name,
    String? description,
    required CourseCategory category,
    required CourseLevel level,
  }) async {
    final classroom = await _authService.createClassroom(
      name: name,
      description: description,
      category: category,
      level: level,
    );
    notifyListeners();
    return classroom;
  }

  Future<Classroom> createClassroomWithSchoolClass({
    required String name,
    String? description,
    required String filiereId,
    required String niveauId,
    required String matiereId,
    required String classeScolaireId,
  }) async {
    final classroom = await _authService.createClassroomWithSchoolClass(
      name: name,
      description: description,
      filiereId: filiereId,
      niveauId: niveauId,
      matiereId: matiereId,
      classeScolaireId: classeScolaireId,
    );
    notifyListeners();
    return classroom;
  }

  // ── Rooms ─────────────────────────────────────────────────────

  Future<Room> createRoom({
    required String name,
    required String classroomId,
    String? schoolClassId,
    required String qcmSessionId,
    int? timerMinutes,
    int maxParticipants = 50,
    bool allowAnonymous = false,
  }) async {
    final room = await _authService.createRoom(
      name: name,
      classroomId: classroomId,
      schoolClassId: schoolClassId,
      qcmSessionId: qcmSessionId,
      timerMinutes: timerMinutes,
      maxParticipants: maxParticipants,
      allowAnonymous: allowAnonymous,
    );
    notifyListeners();
    return room;
  }

  // ── Reset ─────────────────────────────────────────────────────

  void reset() {
    _questions         = [];
    _currentSession    = null;
    _courseTitle       = '';
    _courseSummary     = '';
    _keywords          = [];
    _isLoading         = false;
    _loadingProgress   = 0.0;
    _loadingStep       = '';
    _teacherCourses    = [];
    _adminUsers        = [];
    _globalStats       = null;
    _childProfile      = null;
    _childSessions     = [];
    _childTeachers     = [];
    _sessionsLoaded    = false;
    _teacherCoursesLoaded = false;
    _adminUsersLoaded  = false;
    _globalStatsLoaded = false;
    _childDataLoaded   = false;
    _weeklyActivity    = {0:0,1:0,2:0,3:0,4:0,5:0,6:0};
    notifyListeners();
  }

  Future<List<Map<String, dynamic>>> fetchStudentsBySchoolClass(String schoolClassId) async {
    return await _authService.fetchStudentsBySchoolClass(schoolClassId);
  }

  Future<List<Map<String, dynamic>>> fetchClassroomStudents(String classroomId, {String? schoolClassId}) async {
    return await _authService.fetchClassroomStudents(classroomId, schoolClassId: schoolClassId);
  }
}
