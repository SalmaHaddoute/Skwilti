import 'package:flutter/material.dart';
import '../models/question.dart';
import '../models/course.dart';
import '../models/user.dart' as app_user;
import '../models/classroom.dart';
import '../models/room.dart';
import '../models/statistics.dart';
import '../models/qsm_session.dart';
import 'auth_service.dart';

class AppState extends ChangeNotifier {
  final AuthService _authService = AuthService();
  bool _isAuthenticated = false;

  // ── Authentication ────────────────────────────────────────────
  app_user.User? get currentUser    => _authService.currentUser;
  bool get isAuthenticated          => _isAuthenticated;
  List<Classroom> get userClassrooms => _authService.userClassrooms;
  List<Room> get userRooms          => _authService.userRooms;
  UserStatistics? get userStats     => _authService.userStats;

  // ── Init ──────────────────────────────────────────────────────
  Future<void> init() async {
    try {
      final user = await _authService.restoreSession();
      if (user != null) {
        _isAuthenticated = true;
        notifyListeners();
      }
    } catch (e) {
      print('🔴 init error: $e');
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

  String _courseSummary   = '';
  String get courseSummary => _courseSummary;

  List<String> _keywords = [];
  List<String> get keywords => _keywords;

  // ── Données réelles Supabase (chargées dynamiquement) ─────────

  // Sessions récentes de l'étudiant
  List<Map<String, dynamic>> _recentSessions = [];
  List<Map<String, dynamic>> get recentSessions => _recentSessions;
  bool _sessionsLoaded = false;
  bool get sessionsLoaded => _sessionsLoaded;

  // Scores hebdomadaires (courbe de performance)
  List<Map<String, dynamic>> _weeklyScores = [];
  List<Map<String, dynamic>> get weeklyScores => _weeklyScores;

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
  String _n8nUrl = 'http://10.0.2.2:5678/webhook-test/skwilti_app';
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

  /// Charge les sessions récentes de l'étudiant connecté
  Future<void> loadStudentSessions() async {
    if (currentUser == null) return;
    _sessionsLoaded = false;
    notifyListeners();
    _recentSessions = await _authService.fetchStudentRecentSessions(currentUser!.id);
    _weeklyScores   = await _authService.fetchWeeklyScores(currentUser!.id);
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
    _teacherCoursesLoaded = true;
    notifyListeners();
  }

  /// Upload un cours vers Supabase
  Future<void> uploadCourse(Map<String, dynamic> courseData) async {
    await _authService.uploadCourse(courseData);
    await loadTeacherCourses(); // Recharger la liste après l'upload
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

  /// Met à jour un cours (admin)
  Future<void> updateCourse(String courseId, Map<String, dynamic> courseData) async {
    await _authService.updateCourse(courseId, courseData);
    await loadAdminCourses();
  }

  /// Supprime un cours (admin)
  Future<void> deleteCourse(String courseId) async {
    await _authService.deleteCourse(courseId);
    await loadAdminCourses();
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
    final childId = currentUser?.linkedChildId;
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
  }) {
    _questions     = questions;
    _courseTitle   = title;
    _courseSummary = summary;
    _keywords      = keywords;
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

  void startSession() {
    if (_currentSession == null) return;
    _currentSession = QsmSession(
      id: _currentSession!.id,
      courseTitle: _currentSession!.courseTitle,
      questions: _currentSession!.questions,
      createdAt: _currentSession!.createdAt,
      userAnswers: _currentSession!.userAnswers,
      completedAt: _currentSession!.completedAt,
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

  void completeSession() {
    if (_currentSession != null) {
      _currentSession!.completedAt = DateTime.now();
      notifyListeners();
    }
  }

  void setCurrentSession(QsmSession session) {
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

  // ── Rooms ─────────────────────────────────────────────────────

  Future<Room> createRoom({
    required String name,
    required String classroomId,
    required String qcmSessionId,
    int? timerMinutes,
    int maxParticipants = 50,
    bool allowAnonymous = false,
  }) async {
    final room = await _authService.createRoom(
      name: name,
      classroomId: classroomId,
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
    _recentSessions    = [];
    _weeklyScores      = [];
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
}
