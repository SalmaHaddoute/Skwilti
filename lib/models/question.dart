import 'package:flutter/foundation.dart';

class Question {
  final String id;
  final String question;
  final List<String> options;
  final int correctIndex;
  final String explication;
  bool isDeleted;

  Question({
    required this.id,
    required this.question,
    required this.options,
    required this.correctIndex,
    required this.explication,
    this.isDeleted = false,
  });

  factory Question.fromJson(Map<String, dynamic> json) {
    return Question(
      id: json['id']?.toString() ?? UniqueKey().toString(),
      question: json['question']?.toString() ?? '',
      options: List<String>.from(json['options'] ?? []),
      correctIndex: (json['correct'] ?? 0) as int,
      explication: json['explication']?.toString() ?? '',
    );
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'question': question,
        'options': options,
        'correct': correctIndex,
        'explication': explication,
      };
}

class QcmSession {
  final String id;
  final String courseTitle;
  final List<Question> questions;
  final DateTime createdAt;
  List<int?> userAnswers;
  DateTime? completedAt;

  QcmSession({
    required this.id,
    required this.courseTitle,
    required this.questions,
    required this.createdAt,
    List<int?>? userAnswers,
    this.completedAt,
  }) : userAnswers = userAnswers ?? List.filled(questions.length, null);

  int get totalQuestions => questions.length;

  int get correctAnswers {
    int count = 0;
    for (int i = 0; i < questions.length; i++) {
      if (userAnswers[i] == questions[i].correctIndex) count++;
    }
    return count;
  }

  double get scorePercent =>
      totalQuestions > 0 ? (correctAnswers / totalQuestions) * 100 : 0;

  bool get isCompleted => completedAt != null;
}
