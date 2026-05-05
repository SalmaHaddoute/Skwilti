enum RoomStatus {
  waiting,
  active,
  completed,
  expired,
}

class Room {
  final String id;
  final String name;
  final String classroomId;
  final String teacherId;
  final String qcmSessionId;
  final String inviteLink;
  final String? roomCode;
  final DateTime createdAt;
  final DateTime? startedAt;
  final DateTime? expiresAt;
  final RoomStatus status;
  final int? timerMinutes;
  final List<String> participantIds;
  final int maxParticipants;
  final bool allowAnonymous;
  final Map<String, dynamic> settings;

  const Room({
    required this.id,
    required this.name,
    required this.classroomId,
    required this.teacherId,
    required this.qcmSessionId,
    required this.inviteLink,
    this.roomCode,
    required this.createdAt,
    this.startedAt,
    this.expiresAt,
    this.status = RoomStatus.waiting,
    this.timerMinutes,
    this.participantIds = const [],
    this.maxParticipants = 50,
    this.allowAnonymous = false,
    this.settings = const {},
  });

  factory Room.fromJson(Map<String, dynamic> json) {
    return Room(
      id: json['id']?.toString() ?? '',
      name: json['name']?.toString() ?? '',
      classroomId: json['classroomId']?.toString() ?? '',
      teacherId: json['teacherId']?.toString() ?? '',
      qcmSessionId: json['qcmSessionId']?.toString() ?? '',
      inviteLink: json['inviteLink']?.toString() ?? '',
      roomCode: json['roomCode']?.toString(),
      createdAt: DateTime.tryParse(json['createdAt']?.toString() ?? '') ?? DateTime.now(),
      startedAt: json['startedAt'] != null
          ? DateTime.tryParse(json['startedAt'])
          : null,
      expiresAt: json['expiresAt'] != null
          ? DateTime.tryParse(json['expiresAt'])
          : null,
      status: RoomStatus.values.firstWhere(
        (s) => s.name == json['status'],
        orElse: () => RoomStatus.waiting,
      ),
      timerMinutes: json['timerMinutes'] as int?,
      participantIds: List<String>.from(json['participantIds'] ?? []),
      maxParticipants: json['maxParticipants'] as int? ?? 50,
      allowAnonymous: json['allowAnonymous'] as bool? ?? false,
      settings: Map<String, dynamic>.from(json['settings'] ?? {}),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'classroomId': classroomId,
      'teacherId': teacherId,
      'qcmSessionId': qcmSessionId,
      'inviteLink': inviteLink,
      'roomCode': roomCode,
      'createdAt': createdAt.toIso8601String(),
      'startedAt': startedAt?.toIso8601String(),
      'expiresAt': expiresAt?.toIso8601String(),
      'status': status.name,
      'timerMinutes': timerMinutes,
      'participantIds': participantIds,
      'maxParticipants': maxParticipants,
      'allowAnonymous': allowAnonymous,
      'settings': settings,
    };
  }

  bool get isActive => status == RoomStatus.active;
  bool get isExpired => expiresAt != null && DateTime.now().isAfter(expiresAt!);
  bool get canJoin => status == RoomStatus.active && !isExpired;
  bool get isFull => participantIds.length >= maxParticipants;

  Duration? get remainingTime {
    if (expiresAt == null) return null;
    return expiresAt!.difference(DateTime.now());
  }

  String get statusDisplay {
    switch (status) {
      case RoomStatus.waiting:
        return 'En attente';
      case RoomStatus.active:
        return isExpired ? 'Expirée' : 'Active';
      case RoomStatus.completed:
        return 'Terminée';
      case RoomStatus.expired:
        return 'Expirée';
    }
  }

  Room copyWith({
    String? id,
    String? name,
    String? classroomId,
    String? teacherId,
    String? qcmSessionId,
    String? inviteLink,
    String? roomCode,
    DateTime? createdAt,
    DateTime? startedAt,
    DateTime? expiresAt,
    RoomStatus? status,
    int? timerMinutes,
    List<String>? participantIds,
    int? maxParticipants,
    bool? allowAnonymous,
    Map<String, dynamic>? settings,
  }) {
    return Room(
      id: id ?? this.id,
      name: name ?? this.name,
      classroomId: classroomId ?? this.classroomId,
      teacherId: teacherId ?? this.teacherId,
      qcmSessionId: qcmSessionId ?? this.qcmSessionId,
      inviteLink: inviteLink ?? this.inviteLink,
      roomCode: roomCode ?? this.roomCode,
      createdAt: createdAt ?? this.createdAt,
      startedAt: startedAt ?? this.startedAt,
      expiresAt: expiresAt ?? this.expiresAt,
      status: status ?? this.status,
      timerMinutes: timerMinutes ?? this.timerMinutes,
      participantIds: participantIds ?? this.participantIds,
      maxParticipants: maxParticipants ?? this.maxParticipants,
      allowAnonymous: allowAnonymous ?? this.allowAnonymous,
      settings: settings ?? this.settings,
    );
  }
}
