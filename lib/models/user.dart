enum UserRole {
  teacher,
  student,
  parent,
  admin,
}

enum SubscriptionType {
  free,
  basic,
  premium,
}

class User {
  final String id;
  final String email;
  final String firstName;
  final String lastName;
  final String? avatar;
  final UserRole role;
  final SubscriptionType subscription;
  final DateTime createdAt;
  final DateTime? lastActiveAt;
  final int points;
  final int dailyQsmCount;
  final DateTime? dailyQsmResetDate;
  final String? linkedChildId; // For parents
  final String? linkedParentIds; // For students (JSON array)

  const User({
    required this.id,
    required this.email,
    required this.firstName,
    required this.lastName,
    this.avatar,
    required this.role,
    required this.subscription,
    required this.createdAt,
    this.lastActiveAt,
    this.points = 0,
    this.dailyQsmCount = 0,
    this.dailyQsmResetDate,
    this.linkedChildId,
    this.linkedParentIds,
  });

  factory User.fromJson(Map<String, dynamic> json) {
    return User(
      id: json['id']?.toString() ?? '',
      email: json['email']?.toString() ?? '',
      firstName: json['firstName']?.toString() ?? '',
      lastName: json['lastName']?.toString() ?? '',
      avatar: json['avatar']?.toString(),
      role: UserRole.values.firstWhere(
        (r) => r.name == json['role'],
        orElse: () => UserRole.student,
      ),
      subscription: SubscriptionType.values.firstWhere(
        (s) => s.name == json['subscription'],
        orElse: () => SubscriptionType.free,
      ),
      createdAt: DateTime.tryParse(json['createdAt']?.toString() ?? '') ?? DateTime.now(),
      lastActiveAt: json['lastActiveAt'] != null 
          ? DateTime.tryParse(json['lastActiveAt']) 
          : null,
      points: json['points'] as int? ?? 0,
      dailyQsmCount: json['dailyQsmCount'] as int? ?? 0,
      dailyQsmResetDate: json['dailyQsmResetDate'] != null
          ? DateTime.tryParse(json['dailyQsmResetDate'])
          : null,
      linkedChildId: json['linkedChildId']?.toString(),
      linkedParentIds: json['linkedParentIds']?.toString(),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'email': email,
      'firstName': firstName,
      'lastName': lastName,
      'avatar': avatar,
      'role': role.name,
      'subscription': subscription.name,
      'createdAt': createdAt.toIso8601String(),
      'lastActiveAt': lastActiveAt?.toIso8601String(),
      'points': points,
      'dailyQsmCount': dailyQsmCount,
      'dailyQsmResetDate': dailyQsmResetDate?.toIso8601String(),
      'linkedChildId': linkedChildId,
      'linkedParentIds': linkedParentIds,
    };
  }

  String get fullName => '$firstName $lastName';
  
  bool get canCreateQsm {
    switch (subscription) {
      case SubscriptionType.free:
        return dailyQsmCount < 1;
      case SubscriptionType.basic:
        return dailyQsmCount < 5;
      case SubscriptionType.premium:
        return true; // Unlimited
    }
  }

  int get maxDailyQsm {
    switch (subscription) {
      case SubscriptionType.free:
        return 1;
      case SubscriptionType.basic:
        return 5;
      case SubscriptionType.premium:
        return 999; // Unlimited
    }
  }

  User copyWith({
    String? id,
    String? email,
    String? firstName,
    String? lastName,
    String? avatar,
    UserRole? role,
    SubscriptionType? subscription,
    DateTime? createdAt,
    DateTime? lastActiveAt,
    int? points,
    int? dailyQsmCount,
    DateTime? dailyQsmResetDate,
    String? linkedChildId,
    String? linkedParentIds,
  }) {
    return User(
      id: id ?? this.id,
      email: email ?? this.email,
      firstName: firstName ?? this.firstName,
      lastName: lastName ?? this.lastName,
      avatar: avatar ?? this.avatar,
      role: role ?? this.role,
      subscription: subscription ?? this.subscription,
      createdAt: createdAt ?? this.createdAt,
      lastActiveAt: lastActiveAt ?? this.lastActiveAt,
      points: points ?? this.points,
      dailyQsmCount: dailyQsmCount ?? this.dailyQsmCount,
      dailyQsmResetDate: dailyQsmResetDate ?? this.dailyQsmResetDate,
      linkedChildId: linkedChildId ?? this.linkedChildId,
      linkedParentIds: linkedParentIds ?? this.linkedParentIds,
    );
  }
}
