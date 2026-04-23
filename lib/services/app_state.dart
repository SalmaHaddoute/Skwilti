import 'package:flutter/foundation.dart';
import '../models/question.dart';
import '../models/course.dart';

class AppState extends ChangeNotifier {
  // Current QCM session
  QcmSession? _currentSession;
  QcmSession? get currentSession => _currentSession;

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

  void startSession() {
    final active = questions;
    _currentSession = QcmSession(
      id: DateTime.now().millisecondsSinceEpoch.toString(),
      courseTitle: _courseTitle,
      questions: active,
      createdAt: DateTime.now(),
    );
    notifyListeners();
  }

  void answerQuestion(int questionIndex, int answerIndex) {
    if (_currentSession != null) {
      _currentSession!.userAnswers[questionIndex] = answerIndex;
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

  void reset() {
    _questions = [];
    _currentSession = null;
    _courseTitle = '';
    _courseSummary = '';
    _keywords = [];
    notifyListeners();
  }
}
