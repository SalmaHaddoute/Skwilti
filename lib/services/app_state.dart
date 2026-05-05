import 'package:flutter/material.dart';
import '../models/question.dart';
import '../models/course.dart';
import '../models/user.dart';
import '../models/classroom.dart';
import '../models/room.dart';
import '../models/statistics.dart';
import '../models/qsm_session.dart';
import 'auth_service.dart';

class AppState extends ChangeNotifier {
  final AuthService _authService = AuthService();

  // Authentication
  User? get currentUser => _authService.currentUser;
  bool get isAuthenticated => _authService.isAuthenticated;
  List<Classroom> get userClassrooms => _authService.userClassrooms;
  List<Room> get userRooms => _authService.userRooms;
  UserStatistics? get userStats => _authService.userStats;

  // Current QSM session (extended QCM)
  QsmSession? _currentSession;
  QsmSession? get currentSession => _currentSession;

  // Questions list (editable before QCM)
  List<Question> _questions = [];
  List<Question> get questions => _questions.where((q) => !q.isDeleted).toList();
  List<Question> get allQuestions => _questions;

  // Course info
  String _courseTitle = '';
  String get courseTitle => _courseTitle;

  String _courseSummary = '';
  String get courseSummary => _courseSummary;

  List<String> _keywords = [];
  List<String> get keywords => _keywords;

  // Recent courses (mock)
  final List<Course> _recentCourses = [
    Course(
      id: '1',
      title: 'Biologie Cellulaire',
      fileName: 'bio_cellulaire.pdf',
      pageCount: 42,
      questionCount: 10,
      progress: 0.78,
      createdAt: DateTime.now().subtract(const Duration(days: 1)),
      keywords: ['Mitose', 'ADN', 'Membrane'],
    ),
    Course(
      id: '2',
      title: 'Algèbre Linéaire',
      fileName: 'algebre_lineaire.pdf',
      pageCount: 28,
      questionCount: 8,
      progress: 0.55,
      createdAt: DateTime.now().subtract(const Duration(days: 3)),
      keywords: ['Matrices', 'Vecteurs', 'Déterminant'],
    ),
    Course(
      id: '3',
      title: 'Thermodynamique',
      fileName: 'thermodynamique.pdf',
      pageCount: 35,
      questionCount: 12,
      progress: 0.30,
      createdAt: DateTime.now().subtract(const Duration(days: 7)),
      keywords: ['Entropie', 'Enthalpie', 'Énergie'],
    ),
  ];
  List<Course> get recentCourses => _recentCourses;

  // Stats
  int _streak = 7;
  int get streak => _streak;

  int _xp = 340;
  int get xp => _xp;

  double _avgScore = 0.74;
  double get avgScore => _avgScore;

  // n8n configuration
  String _n8nUrl = 'http://10.0.2.2:5678/webhook-test/skwilti_app';
  String get n8nUrl => _n8nUrl;

  void setN8nUrl(String url) {
    _n8nUrl = url;
    notifyListeners();
  }

  // Loading state
  bool _isLoading = false;
  bool get isLoading => _isLoading;

  double _loadingProgress = 0.0;
  double get loadingProgress => _loadingProgress;

  String _loadingStep = '';
  String get loadingStep => _loadingStep;

  void setQuestions(List<Question> questions, {
    String title = '',
    String summary = '',
    List<String> keywords = const [],
  }) {
    _questions = questions;
    _courseTitle = title;
    _courseSummary = summary;
    _keywords = keywords;
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
    if (_currentSession != null) {
      // Create new session with startedAt
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
  }

  void completeSession() {
    if (_currentSession != null) {
      _currentSession!.completedAt = DateTime.now();
      _xp += 85;
      _avgScore = (_avgScore + _currentSession!.scorePercent / 100) / 2;
      notifyListeners();
    }
  }

  void setLoading(bool loading, {double progress = 0, String step = ''}) {
    _isLoading = loading;
    _loadingProgress = progress;
    _loadingStep = step;
    notifyListeners();
  }

  // Authentication methods
  Future<User> login(String email, String password) async {
    final user = await _authService.login(email, password);
    notifyListeners();
    return user;
  }

  Future<User> register({
    required String email,
    required String password,
    required String firstName,
    required String lastName,
    required UserRole role,
    SubscriptionType? subscription,
  }) async {
    final user = await _authService.register(
      email: email,
      password: password,
      firstName: firstName,
      lastName: lastName,
      role: role,
      subscription: subscription ?? SubscriptionType.free,
    );
    notifyListeners();
    return user;
  }

  Future<void> logout() async {
    await _authService.logout();
    reset();
    notifyListeners();
  }

  // Classroom methods
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

  // Room methods
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

  // Admin methods
  Future<GlobalStatistics> getGlobalStatistics() async {
    return await _authService.getGlobalStatistics();
  }

  void setCurrentSession(QsmSession session) {
    _currentSession = session;
    notifyListeners();
  }

  // Lesson upload methods
  final List<Map<String, dynamic>> _uploadedLessons = [];
  List<Map<String, dynamic>> get uploadedLessons => _uploadedLessons;

  void addLesson(Map<String, dynamic> lesson) {
    _uploadedLessons.add(lesson);
    notifyListeners();
  }

  void reset() {
    _questions.clear();
    _currentSession = null;
    _courseTitle = '';
    _courseSummary = '';
    _keywords = [];
    _isLoading = false;
    _loadingProgress = 0.0;
    _loadingStep = '';
    notifyListeners();
  }
}
