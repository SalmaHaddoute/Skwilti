enum CourseCategory {
  maths,
  physics,
  chemistry,
  biology,
  history,
  geography,
  literature,
  languages,
  computerScience,
  other,
}

enum CourseLevel {
  primary,
  middleSchool,
  highSchool,
  university,
  other,
}

class Classroom {
  final String id;
  final String name;
  final String? description;
  final String teacherId;
  final String teacherName;
  final List<String> studentIds;
  final CourseCategory category;
  final CourseLevel level;
  final String? coverImage;
  final DateTime createdAt;
  final DateTime? lastActivityAt;
  final bool isActive;
  final String inviteCode;
  final int totalQsmCreated;
  final int totalStudents;

  const Classroom({
    required this.id,
    required this.name,
    this.description,
    required this.teacherId,
    required this.teacherName,
    this.studentIds = const [],
    required this.category,
    required this.level,
    this.coverImage,
    required this.createdAt,
    this.lastActivityAt,
    this.isActive = true,
    required this.inviteCode,
    this.totalQsmCreated = 0,
    this.totalStudents = 0,
  });

  factory Classroom.fromJson(Map<String, dynamic> json) {
    return Classroom(
      id: json['id']?.toString() ?? '',
      name: json['name']?.toString() ?? '',
      description: json['description']?.toString(),
      teacherId: json['teacherId']?.toString() ?? '',
      teacherName: json['teacherName']?.toString() ?? '',
      studentIds: List<String>.from(json['studentIds'] ?? []),
      category: CourseCategory.values.firstWhere(
        (c) => c.name == json['category'],
        orElse: () => CourseCategory.other,
      ),
      level: CourseLevel.values.firstWhere(
        (l) => l.name == json['level'],
        orElse: () => CourseLevel.other,
      ),
      coverImage: json['coverImage']?.toString(),
      createdAt: DateTime.tryParse(json['createdAt']?.toString() ?? '') ?? DateTime.now(),
      lastActivityAt: json['lastActivityAt'] != null
          ? DateTime.tryParse(json['lastActivityAt'])
          : null,
      isActive: json['isActive'] as bool? ?? true,
      inviteCode: json['inviteCode']?.toString() ?? '',
      totalQsmCreated: json['totalQsmCreated'] as int? ?? 0,
      totalStudents: json['totalStudents'] as int? ?? 0,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'description': description,
      'teacherId': teacherId,
      'teacherName': teacherName,
      'studentIds': studentIds,
      'category': category.name,
      'level': level.name,
      'coverImage': coverImage,
      'createdAt': createdAt.toIso8601String(),
      'lastActivityAt': lastActivityAt?.toIso8601String(),
      'isActive': isActive,
      'inviteCode': inviteCode,
      'totalQsmCreated': totalQsmCreated,
      'totalStudents': totalStudents,
    };
  }

  String get categoryDisplayName {
    switch (category) {
      case CourseCategory.maths:
        return 'Mathématiques';
      case CourseCategory.physics:
        return 'Physique';
      case CourseCategory.chemistry:
        return 'Chimie';
      case CourseCategory.biology:
        return 'Biologie';
      case CourseCategory.history:
        return 'Histoire';
      case CourseCategory.geography:
        return 'Géographie';
      case CourseCategory.literature:
        return 'Littérature';
      case CourseCategory.languages:
        return 'Langues';
      case CourseCategory.computerScience:
        return 'Informatique';
      case CourseCategory.other:
        return 'Autre';
    }
  }

  String get levelDisplayName {
    switch (level) {
      case CourseLevel.primary:
        return 'Primaire';
      case CourseLevel.middleSchool:
        return 'Collège';
      case CourseLevel.highSchool:
        return 'Lycée';
      case CourseLevel.university:
        return 'Université';
      case CourseLevel.other:
        return 'Autre';
    }
  }

  Classroom copyWith({
    String? id,
    String? name,
    String? description,
    String? teacherId,
    String? teacherName,
    List<String>? studentIds,
    CourseCategory? category,
    CourseLevel? level,
    String? coverImage,
    DateTime? createdAt,
    DateTime? lastActivityAt,
    bool? isActive,
    String? inviteCode,
    int? totalQsmCreated,
    int? totalStudents,
  }) {
    return Classroom(
      id: id ?? this.id,
      name: name ?? this.name,
      description: description ?? this.description,
      teacherId: teacherId ?? this.teacherId,
      teacherName: teacherName ?? this.teacherName,
      studentIds: studentIds ?? this.studentIds,
      category: category ?? this.category,
      level: level ?? this.level,
      coverImage: coverImage ?? this.coverImage,
      createdAt: createdAt ?? this.createdAt,
      lastActivityAt: lastActivityAt ?? this.lastActivityAt,
      isActive: isActive ?? this.isActive,
      inviteCode: inviteCode ?? this.inviteCode,
      totalQsmCreated: totalQsmCreated ?? this.totalQsmCreated,
      totalStudents: totalStudents ?? this.totalStudents,
    );
  }
}
