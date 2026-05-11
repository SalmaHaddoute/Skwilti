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
  AuthService get authService       => _authService;

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
    if (childId == null) {
      childId = await _authService.fetchFirstLinkedChildId(currentUser!.id);
    }

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
