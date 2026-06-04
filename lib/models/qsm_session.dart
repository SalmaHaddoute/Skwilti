import 'question.dart';

// QSM Session - Extended QCM with timer and room features
class QsmSession extends QcmSession {
  final String? courseId; // ID du cours associé (null si généré par prompt)
  final String? classroomId;
  final String? roomId;
  final int? timerMinutes;
  final DateTime? startedAt;
  final DateTime? endedAt;
  final bool allowBackNavigation;
  final bool showResultsImmediately;
  final Map<String, dynamic> settings;

  QsmSession({
    required super.id,
    required super.courseTitle,
    required super.questions,
    required super.createdAt,
    List<int?> super.userAnswers = const [],
    super.completedAt,
    this.courseId,
    this.classroomId,
    this.roomId,
    this.timerMinutes,
    this.startedAt,
    this.endedAt,
    this.allowBackNavigation = true,
    this.showResultsImmediately = true,
    this.settings = const {},
  });

  factory QsmSession.fromJson(Map<String, dynamic> json) {
    return QsmSession(
      id: json['id']?.toString() ?? '',
      courseTitle: json['courseTitle']?.toString() ?? '',
      questions: (json['questions'] as List?)
          ?.map((q) => Question.fromJson(q as Map<String, dynamic>))
          .toList() ?? [],
      createdAt: DateTime.tryParse(json['createdAt']?.toString() ?? '') ?? DateTime.now(),
      userAnswers: (json['userAnswers'] as List?)
          ?.map((a) => a as int?)
          .toList() ?? [],
      completedAt: json['completedAt'] != null
          ? DateTime.tryParse(json['completedAt'])
          : null,
      courseId: json['courseId']?.toString(),
      classroomId: json['classroomId']?.toString(),
      roomId: json['roomId']?.toString(),
      timerMinutes: json['timerMinutes'] as int?,
      startedAt: json['startedAt'] != null
          ? DateTime.tryParse(json['startedAt'])
          : null,
      endedAt: json['endedAt'] != null
          ? DateTime.tryParse(json['endedAt'])
          : null,
      allowBackNavigation: json['allowBackNavigation'] as bool? ?? true,
      showResultsImmediately: json['showResultsImmediately'] as bool? ?? true,
      settings: Map<String, dynamic>.from(json['settings'] ?? {}),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'courseTitle': courseTitle,
      'questions': questions.map((q) => q.toJson()).toList(),
      'createdAt': createdAt.toIso8601String(),
      'userAnswers': userAnswers,
      'completedAt': completedAt?.toIso8601String(),
      'courseId': courseId,
      'classroomId': classroomId,
      'roomId': roomId,
      'timerMinutes': timerMinutes,
      'startedAt': startedAt?.toIso8601String(),
      'endedAt': endedAt?.toIso8601String(),
      'allowBackNavigation': allowBackNavigation,
      'showResultsImmediately': showResultsImmediately,
      'settings': settings,
    };
  }

  Duration? get elapsedTime {
    if (startedAt == null) return null;
    final end = endedAt ?? DateTime.now();
    return end.difference(startedAt!);
  }

  Duration? get remainingTime {
    if (timerMinutes == null || startedAt == null) return null;
    final totalDuration = Duration(minutes: timerMinutes!);
    final elapsed = elapsedTime ?? Duration.zero;
    final remaining = totalDuration - elapsed;
    return remaining.isNegative ? Duration.zero : remaining;
  }

  bool get isTimedOut {
    final remaining = remainingTime;
    return remaining != null && remaining.inSeconds <= 0;
  }

  String get formattedElapsedTime {
    final elapsed = elapsedTime;
    if (elapsed == null) return '00:00';
    
    final minutes = elapsed.inMinutes;
    final seconds = elapsed.inSeconds % 60;
    return '${minutes.toString().padLeft(2, '0')}:${seconds.toString().padLeft(2, '0')}';
  }

  String get formattedRemainingTime {
    final remaining = remainingTime;
    if (remaining == null) return '--:--';
    
    final minutes = remaining.inMinutes;
    final seconds = remaining.inSeconds % 60;
    return '${minutes.toString().padLeft(2, '0')}:${seconds.toString().padLeft(2, '0')}';
  }

  QsmSession copyWith({
    String? id,
    String? courseTitle,
    List<Question>? questions,
    DateTime? createdAt,
    List<int?>? userAnswers,
    DateTime? completedAt,
    String? courseId,
    String? classroomId,
    String? roomId,
    int? timerMinutes,
    DateTime? startedAt,
    DateTime? endedAt,
    bool? allowBackNavigation,
    bool? showResultsImmediately,
    Map<String, dynamic>? settings,
  }) {
    return QsmSession(
      id: id ?? this.id,
      courseTitle: courseTitle ?? this.courseTitle,
      questions: questions ?? this.questions,
      createdAt: createdAt ?? this.createdAt,
      userAnswers: userAnswers ?? this.userAnswers,
      completedAt: completedAt ?? this.completedAt,
      courseId: courseId ?? this.courseId,
      classroomId: classroomId ?? this.classroomId,
      roomId: roomId ?? this.roomId,
      timerMinutes: timerMinutes ?? this.timerMinutes,
      startedAt: startedAt ?? this.startedAt,
      endedAt: endedAt ?? this.endedAt,
      allowBackNavigation: allowBackNavigation ?? this.allowBackNavigation,
      showResultsImmediately: showResultsImmediately ?? this.showResultsImmediately,
      settings: settings ?? this.settings,
    );
  }
}
