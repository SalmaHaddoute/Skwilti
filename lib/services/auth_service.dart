import 'dart:math';
import '../models/user.dart';
import '../models/classroom.dart';
import '../models/room.dart';
import '../models/statistics.dart';

class AuthService {
  // Mock data for demo - replace with real API calls
  User? _currentUser;
  List<Classroom> _userClassrooms = [];
  List<Room> _userRooms = [];
  UserStatistics? _userStats;

  User? get currentUser => _currentUser;
  List<Classroom> get userClassrooms => _userClassrooms;
  List<Room> get userRooms => _userRooms;
  UserStatistics? get userStats => _userStats;
  bool get isAuthenticated => _currentUser != null;

  // Generate random invite code
  String _generateInviteCode() {
    const chars = 'ABCDEFGHIJKLMNOPQRSTUVWXYZ0123456789';
    final random = Random();
    return String.fromCharCodes(Iterable.generate(
        6, (_) => chars.codeUnitAt(random.nextInt(chars.length))));
  }

  // Login with email and password
  Future<User> login(String email, String password) async {
    try {
      // Mock login - replace with real API call
      await Future.delayed(const Duration(seconds: 1));
      
      if (email == 'teacher@skwilti.com') {
        _currentUser = User(
          id: 'teacher_1',
          email: email,
          firstName: 'Jean',
          lastName: 'Dupont',
          role: UserRole.teacher,
          subscription: SubscriptionType.free,
          createdAt: DateTime.now().subtract(const Duration(days: 30)),
          points: 150,
          dailyQsmCount: 0,
          dailyQsmResetDate: DateTime.now(),
        );
      } else if (email == 'student@skwilti.com') {
        _currentUser = User(
          id: 'student_1',
          email: email,
          firstName: 'Marie',
          lastName: 'Martin',
          role: UserRole.student,
          subscription: SubscriptionType.free,
          createdAt: DateTime.now().subtract(const Duration(days: 15)),
          points: 75,
        );
      } else if (email == 'parent@skwilti.com') {
        _currentUser = User(
          id: 'parent_1',
          email: email,
          firstName: 'Sophie',
          lastName: 'Bernard',
          role: UserRole.parent,
          subscription: SubscriptionType.free,
          createdAt: DateTime.now().subtract(const Duration(days: 45)),
          linkedChildId: 'student_1',
        );
      } else if (email == 'admin@skwilti.com') {
        _currentUser = User(
          id: 'admin_1',
          email: email,
          firstName: 'Admin',
          lastName: 'Skwilti',
          role: UserRole.admin,
          subscription: SubscriptionType.premium,
          createdAt: DateTime.now().subtract(const Duration(days: 365)),
        );
      } else {
        throw Exception('Utilisateur non trouvé');
      }

      await _loadUserData();
      return _currentUser!;
    } catch (e) {
      throw Exception('Erreur de connexion: $e');
    }
  }

  // Register new user
  Future<User> register({
    required String email,
    required String password,
    required String firstName,
    required String lastName,
    required UserRole role,
    SubscriptionType? subscription,
  }) async {
    try {
      // Mock registration - replace with real API call
      await Future.delayed(const Duration(seconds: 1));
      
      _currentUser = User(
        id: 'user_${DateTime.now().millisecondsSinceEpoch}',
        email: email,
        firstName: firstName,
        lastName: lastName,
        role: role,
        subscription: subscription ?? SubscriptionType.free,
        createdAt: DateTime.now(),
        dailyQsmCount: 0,
        dailyQsmResetDate: DateTime.now(),
      );

      await _loadUserData();
      return _currentUser!;
    } catch (e) {
      throw Exception('Erreur d\'inscription: $e');
    }
  }

  // Logout
  Future<void> logout() async {
    _currentUser = null;
    _userClassrooms = [];
    _userRooms = [];
    _userStats = null;
  }

  // Load user-specific data
  Future<void> _loadUserData() async {
    if (_currentUser == null) return;

    // Load mock data based on user role
    await Future.delayed(const Duration(milliseconds: 500));

    switch (_currentUser!.role) {
      case UserRole.teacher:
        _userClassrooms = [
          Classroom(
            id: 'class_1',
            name: 'Mathématiques 3ème',
            description: 'Classe de mathématiques pour le niveau 3ème',
            teacherId: _currentUser!.id,
            teacherName: _currentUser!.fullName,
            category: CourseCategory.maths,
            level: CourseLevel.middleSchool,
            createdAt: DateTime.now().subtract(const Duration(days: 20)),
            inviteCode: _generateInviteCode(),
            totalStudents: 25,
          ),
          Classroom(
            id: 'class_2',
            name: 'Physique-Chimie 2nde',
            description: 'Classe de physique-chimie pour le niveau seconde',
            teacherId: _currentUser!.id,
            teacherName: _currentUser!.fullName,
            category: CourseCategory.physics,
            level: CourseLevel.highSchool,
            createdAt: DateTime.now().subtract(const Duration(days: 15)),
            inviteCode: _generateInviteCode(),
            totalStudents: 18,
          ),
        ];

        _userRooms = [
          Room(
            id: 'room_1',
            name: 'QSM Mathématiques - Test',
            classroomId: 'class_1',
            teacherId: _currentUser!.id,
            qcmSessionId: 'qcm_1',
            inviteLink: 'https://skwilti.app/room/ABC123',
            roomCode: 'ABC123',
            createdAt: DateTime.now().subtract(const Duration(hours: 2)),
            startedAt: DateTime.now().subtract(const Duration(hours: 1)),
            expiresAt: DateTime.now().add(const Duration(minutes: 30)),
            status: RoomStatus.active,
            timerMinutes: 20,
            participantIds: ['student_1', 'student_2'],
          ),
        ];

        _userStats = UserStatistics(
          userId: _currentUser!.id,
          totalQsmCreated: 15,
          totalQsmCompleted: 0,
          averageScore: 0.0,
          totalPoints: 150,
          timeSpentMinutes: 240,
          lastActivityAt: DateTime.now(),
          qsmByCategory: {'maths': 8, 'physics': 7},
          scoresByLevel: {'middleSchool': 8, 'highSchool': 7},
          recentScores: [85, 92, 78, 88],
          streakDays: 3,
          totalSessions: 15,
        );
        break;

      case UserRole.student:
        _userStats = UserStatistics(
          userId: _currentUser!.id,
          totalQsmCreated: 0,
          totalQsmCompleted: 12,
          averageScore: 82.5,
          totalPoints: 75,
          timeSpentMinutes: 180,
          lastActivityAt: DateTime.now(),
          qsmByCategory: {'maths': 7, 'physics': 5},
          scoresByLevel: {'middleSchool': 12},
          recentScores: [88, 85, 79, 90],
          streakDays: 5,
          totalSessions: 12,
        );
        break;

      case UserRole.parent:
        _userStats = UserStatistics(
          userId: _currentUser!.id,
          totalQsmCreated: 0,
          totalQsmCompleted: 0,
          averageScore: 0.0,
          totalPoints: 0,
          timeSpentMinutes: 0,
          lastActivityAt: DateTime.now(),
          recentScores: [],
          streakDays: 0,
          totalSessions: 0,
        );
        break;

      case UserRole.admin:
        _userStats = UserStatistics(
          userId: _currentUser!.id,
          totalQsmCreated: 0,
          totalQsmCompleted: 0,
          averageScore: 0.0,
          totalPoints: 0,
          timeSpentMinutes: 0,
          lastActivityAt: DateTime.now(),
          recentScores: [],
          streakDays: 0,
          totalSessions: 0,
        );
        break;
    }
  }

  // Create classroom
  Future<Classroom> createClassroom({
    required String name,
    String? description,
    required CourseCategory category,
    required CourseLevel level,
  }) async {
    if (_currentUser?.role != UserRole.teacher) {
      throw Exception('Seuls les enseignants peuvent créer des classrooms');
    }

    try {
      await Future.delayed(const Duration(seconds: 1));
      
      final classroom = Classroom(
        id: 'class_${DateTime.now().millisecondsSinceEpoch}',
        name: name,
        description: description,
        teacherId: _currentUser!.id,
        teacherName: _currentUser!.fullName,
        category: category,
        level: level,
        createdAt: DateTime.now(),
        inviteCode: _generateInviteCode(),
      );

      _userClassrooms.add(classroom);
      return classroom;
    } catch (e) {
      throw Exception('Erreur lors de la création de la classroom: $e');
    }
  }

  // Create room
  Future<Room> createRoom({
    required String name,
    required String classroomId,
    required String qcmSessionId,
    int? timerMinutes,
    int maxParticipants = 50,
    bool allowAnonymous = false,
  }) async {
    if (_currentUser?.role != UserRole.teacher) {
      throw Exception('Seuls les enseignants peuvent créer des rooms');
    }

    try {
      await Future.delayed(const Duration(seconds: 1));
      
      final room = Room(
        id: 'room_${DateTime.now().millisecondsSinceEpoch}',
        name: name,
        classroomId: classroomId,
        teacherId: _currentUser!.id,
        qcmSessionId: qcmSessionId,
        inviteLink: 'https://skwilti.app/room/${_generateInviteCode()}',
        roomCode: _generateInviteCode(),
        createdAt: DateTime.now(),
        expiresAt: timerMinutes != null 
            ? DateTime.now().add(Duration(minutes: timerMinutes))
            : null,
        timerMinutes: timerMinutes,
        maxParticipants: maxParticipants,
        allowAnonymous: allowAnonymous,
      );

      _userRooms.add(room);
      return room;
    } catch (e) {
      throw Exception('Erreur lors de la création de la room: $e');
    }
  }

  // Get global statistics (admin only)
  Future<GlobalStatistics> getGlobalStatistics() async {
    if (_currentUser?.role != UserRole.admin) {
      throw Exception('Accès réservé aux administrateurs');
    }

    try {
      await Future.delayed(const Duration(seconds: 1));
      
      return GlobalStatistics(
        totalUsers: 150,
        totalTeachers: 25,
        totalStudents: 100,
        totalParents: 25,
        totalQsmCreated: 500,
        totalQsmCompleted: 450,
        totalClassrooms: 50,
        totalActiveRooms: 12,
        usersByRole: {
          'teacher': 25,
          'student': 100,
          'parent': 25,
          'admin': 5,
        },
        qsmByCategory: {
          'maths': 150,
          'physics': 100,
          'chemistry': 80,
          'biology': 70,
          'history': 60,
          'geography': 40,
        },
        averageScoresByLevel: {
          'primary': 75.0,
          'middleSchool': 78.5,
          'highSchool': 82.0,
          'university': 85.5,
        },
        lastUpdated: DateTime.now(),
      );
    } catch (e) {
      throw Exception('Erreur lors de la récupération des statistiques: $e');
    }
  }
}
