class Course {
  final String id;
  final String title;
  final String fileName;
  final int pageCount;
  final int questionCount;
  final double progress;
  final DateTime createdAt;
  final String? summary;
  final List<String> keywords;

  Course({
    required this.id,
    required this.title,
    required this.fileName,
    this.pageCount = 0,
    this.questionCount = 0,
    this.progress = 0.0,
    required this.createdAt,
    this.summary,
    this.keywords = const [],
  });

  factory Course.fromJson(Map<String, dynamic> json) {
    return Course(
      id: json['id'] ?? '',
      title: json['title'] ?? '',
      fileName: json['fileName'] ?? '',
      pageCount: json['pageCount'] ?? 0,
      questionCount: json['questionCount'] ?? 0,
      progress: (json['progress'] ?? 0.0).toDouble(),
      createdAt: DateTime.tryParse(json['createdAt'] ?? '') ?? DateTime.now(),
      summary: json['summary'],
      keywords: List<String>.from(json['keywords'] ?? []),
    );
  }
}
