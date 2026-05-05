class UserStatistics {
  final String userId;
  final int totalQsmCreated;
  final int totalQsmCompleted;
  final double averageScore;
  final int totalPoints;
  final int timeSpentMinutes;
  final DateTime lastActivityAt;
  final Map<String, int> qsmByCategory;
  final Map<String, double> scoresByLevel;
  final List<int> recentScores;
  final int streakDays;
  final int totalSessions;

  const UserStatistics({
    required this.userId,
    this.totalQsmCreated = 0,
    this.totalQsmCompleted = 0,
    this.averageScore = 0.0,
    this.totalPoints = 0,
    this.timeSpentMinutes = 0,
    required this.lastActivityAt,
    this.qsmByCategory = const {},
    this.scoresByLevel = const {},
    this.recentScores = const [],
    this.streakDays = 0,
    this.totalSessions = 0,
  });

  factory UserStatistics.fromJson(Map<String, dynamic> json) {
    return UserStatistics(
      userId: json['userId']?.toString() ?? '',
      totalQsmCreated: json['totalQsmCreated'] as int? ?? 0,
      totalQsmCompleted: json['totalQsmCompleted'] as int? ?? 0,
      averageScore: (json['averageScore'] as num?)?.toDouble() ?? 0.0,
      totalPoints: json['totalPoints'] as int? ?? 0,
      timeSpentMinutes: json['timeSpentMinutes'] as int? ?? 0,
      lastActivityAt: DateTime.tryParse(json['lastActivityAt']?.toString() ?? '') ?? DateTime.now(),
      qsmByCategory: Map<String, int>.from(json['qsmByCategory'] ?? {}),
      scoresByLevel: Map<String, double>.from(json['scoresByLevel'] ?? {}),
      recentScores: List<int>.from(json['recentScores'] ?? []),
      streakDays: json['streakDays'] as int? ?? 0,
      totalSessions: json['totalSessions'] as int? ?? 0,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'userId': userId,
      'totalQsmCreated': totalQsmCreated,
      'totalQsmCompleted': totalQsmCompleted,
      'averageScore': averageScore,
      'totalPoints': totalPoints,
      'timeSpentMinutes': timeSpentMinutes,
      'lastActivityAt': lastActivityAt.toIso8601String(),
      'qsmByCategory': qsmByCategory,
      'scoresByLevel': scoresByLevel,
      'recentScores': recentScores,
      'streakDays': streakDays,
      'totalSessions': totalSessions,
    };
  }

  String get formattedTimeSpent {
    final hours = timeSpentMinutes ~/ 60;
    final minutes = timeSpentMinutes % 60;
    if (hours > 0) {
      return '${hours}h ${minutes}min';
    }
    return '${minutes}min';
  }

  double get completionRate {
    if (totalQsmCreated == 0) return 0.0;
    return totalQsmCompleted / totalQsmCreated;
  }

  int? get lastWeekScore {
    if (recentScores.isEmpty) return null;
    return recentScores.first;
  }

  UserStatistics copyWith({
    String? userId,
    int? totalQsmCreated,
    int? totalQsmCompleted,
    double? averageScore,
    int? totalPoints,
    int? timeSpentMinutes,
    DateTime? lastActivityAt,
    Map<String, int>? qsmByCategory,
    Map<String, double>? scoresByLevel,
    List<int>? recentScores,
    int? streakDays,
    int? totalSessions,
  }) {
    return UserStatistics(
      userId: userId ?? this.userId,
      totalQsmCreated: totalQsmCreated ?? this.totalQsmCreated,
      totalQsmCompleted: totalQsmCompleted ?? this.totalQsmCompleted,
      averageScore: averageScore ?? this.averageScore,
      totalPoints: totalPoints ?? this.totalPoints,
      timeSpentMinutes: timeSpentMinutes ?? this.timeSpentMinutes,
      lastActivityAt: lastActivityAt ?? this.lastActivityAt,
      qsmByCategory: qsmByCategory ?? this.qsmByCategory,
      scoresByLevel: scoresByLevel ?? this.scoresByLevel,
      recentScores: recentScores ?? this.recentScores,
      streakDays: streakDays ?? this.streakDays,
      totalSessions: totalSessions ?? this.totalSessions,
    );
  }
}

class GlobalStatistics {
  final int totalUsers;
  final int totalTeachers;
  final int totalStudents;
  final int totalParents;
  final int totalQsmCreated;
  final int totalQsmCompleted;
  final int totalClassrooms;
  final int totalActiveRooms;
  final Map<String, int> usersByRole;
  final Map<String, int> qsmByCategory;
  final Map<String, double> averageScoresByLevel;
  final DateTime lastUpdated;

  const GlobalStatistics({
    this.totalUsers = 0,
    this.totalTeachers = 0,
    this.totalStudents = 0,
    this.totalParents = 0,
    this.totalQsmCreated = 0,
    this.totalQsmCompleted = 0,
    this.totalClassrooms = 0,
    this.totalActiveRooms = 0,
    this.usersByRole = const {},
    this.qsmByCategory = const {},
    this.averageScoresByLevel = const {},
    required this.lastUpdated,
  });

  factory GlobalStatistics.fromJson(Map<String, dynamic> json) {
    return GlobalStatistics(
      totalUsers: json['totalUsers'] as int? ?? 0,
      totalTeachers: json['totalTeachers'] as int? ?? 0,
      totalStudents: json['totalStudents'] as int? ?? 0,
      totalParents: json['totalParents'] as int? ?? 0,
      totalQsmCreated: json['totalQsmCreated'] as int? ?? 0,
      totalQsmCompleted: json['totalQsmCompleted'] as int? ?? 0,
      totalClassrooms: json['totalClassrooms'] as int? ?? 0,
      totalActiveRooms: json['totalActiveRooms'] as int? ?? 0,
      usersByRole: Map<String, int>.from(json['usersByRole'] ?? {}),
      qsmByCategory: Map<String, int>.from(json['qsmByCategory'] ?? {}),
      averageScoresByLevel: Map<String, double>.from(json['averageScoresByLevel'] ?? {}),
      lastUpdated: DateTime.tryParse(json['lastUpdated']?.toString() ?? '') ?? DateTime.now(),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'totalUsers': totalUsers,
      'totalTeachers': totalTeachers,
      'totalStudents': totalStudents,
      'totalParents': totalParents,
      'totalQsmCreated': totalQsmCreated,
      'totalQsmCompleted': totalQsmCompleted,
      'totalClassrooms': totalClassrooms,
      'totalActiveRooms': totalActiveRooms,
      'usersByRole': usersByRole,
      'qsmByCategory': qsmByCategory,
      'averageScoresByLevel': averageScoresByLevel,
      'lastUpdated': lastUpdated.toIso8601String(),
    };
  }

  double get overallCompletionRate {
    if (totalQsmCreated == 0) return 0.0;
    return totalQsmCompleted / totalQsmCreated;
  }

  GlobalStatistics copyWith({
    int? totalUsers,
    int? totalTeachers,
    int? totalStudents,
    int? totalParents,
    int? totalQsmCreated,
    int? totalQsmCompleted,
    int? totalClassrooms,
    int? totalActiveRooms,
    Map<String, int>? usersByRole,
    Map<String, int>? qsmByCategory,
    Map<String, double>? averageScoresByLevel,
    DateTime? lastUpdated,
  }) {
    return GlobalStatistics(
      totalUsers: totalUsers ?? this.totalUsers,
      totalTeachers: totalTeachers ?? this.totalTeachers,
      totalStudents: totalStudents ?? this.totalStudents,
      totalParents: totalParents ?? this.totalParents,
      totalQsmCreated: totalQsmCreated ?? this.totalQsmCreated,
      totalQsmCompleted: totalQsmCompleted ?? this.totalQsmCompleted,
      totalClassrooms: totalClassrooms ?? this.totalClassrooms,
      totalActiveRooms: totalActiveRooms ?? this.totalActiveRooms,
      usersByRole: usersByRole ?? this.usersByRole,
      qsmByCategory: qsmByCategory ?? this.qsmByCategory,
      averageScoresByLevel: averageScoresByLevel ?? this.averageScoresByLevel,
      lastUpdated: lastUpdated ?? this.lastUpdated,
    );
  }
}
