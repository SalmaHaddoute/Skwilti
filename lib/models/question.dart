import 'dart:convert';
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
    print('=== CONVERSION QUESTION ===');
    print('JSON reçu: $json');
    
    // Support both 'question' and 'text' (Supabase/n8n format)
    final questionText = json['question'] ?? json['text'] ?? '';
    
    // Support both 'correct' and 'correct_answer'
    final correctVal = json['correct'] ?? json['correct_answer'];
    
    final options = _parseOptions(json['options']);

    print('ID: ${json['id']}');
    print('Question: $questionText');
    print('Options: $options');
    print('Correct: $correctVal');
    print('Explication: ${json['explication']}');
    print('========================');
    
    return Question(
      id: json['id']?.toString() ?? UniqueKey().toString(),
      question: questionText.toString(),
      options: options,
      correctIndex: Question._parseCorrectIndex(correctVal, options),
      explication: json['explication']?.toString() ?? '',
    );
  }

  static List<String> _parseOptions(dynamic options) {
    if (options == null) return [];
    if (options is List) return options.map((e) => e.toString()).toList();
    if (options is String) {
      try {
        final decoded = jsonDecode(options);
        if (decoded is List) return decoded.map((e) => e.toString()).toList();
      } catch (e) {
        print('DEBUG: Erreur parsing options string: $e');
      }
    }
    return [];
  }

  static int _parseCorrectIndex(dynamic correctValue, List<dynamic> options) {
    print('DEBUG: Parsing correctIndex: $correctValue, options: $options');
    
    if (correctValue == null) {
      print('DEBUG: correctIndex est null, défaut à 0.');
      return 0;
    }
    
    try {
      int index = (correctValue is int) ? correctValue : int.parse(correctValue.toString());
      print('DEBUG: Parsed index: $index, options length: ${options.length}');
      
      if (index >= 0 && index < options.length) {
        print('DEBUG: Index valide: $index');
        return index;
      } else {
        print('DEBUG: correctIndex ($index) hors limites pour ${options.length} options. Défaut à 0.');
        return 0;
      }
    } catch (e) {
      print('DEBUG: Erreur parsing correctIndex ($correctValue): $e. Défaut à 0.');
      return 0;
    }
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
