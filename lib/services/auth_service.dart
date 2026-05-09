import 'dart:math';
import 'dart:async';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../models/user.dart' as app_user;
import '../models/classroom.dart';
import '../models/room.dart';
import '../models/statistics.dart';

class AuthService {
  final _supabase = Supabase.instance.client;

  app_user.User? _currentUser;
  List<Classroom> _userClassrooms = [];
  List<Room> _userRooms = [];
  UserStatistics? _userStats;

  app_user.User? get currentUser => _currentUser;
  List<Classroom> get userClassrooms => _userClassrooms;
  List<Room> get userRooms => _userRooms;
  UserStatistics? get userStats => _userStats;
  bool get isAuthenticated => _currentUser != null;

  String _generateInviteCode() {
    const chars = 'ABCDEFGHIJKLMNOPQRSTUVWXYZ0123456789';
    final random = Random();
    return String.fromCharCodes(Iterable.generate(
        6, (_) => chars.codeUnitAt(random.nextInt(chars.length))));
  }

  // ✅ LOGIN SUPABASE
  Future<app_user.User> login(String email, String password) async {
    try {
      final response = await _supabase.auth.signInWithPassword(
        email: email,
        password: password,
      ).timeout(const Duration(seconds: 30));

      if (response.user == null) throw Exception('Utilisateur non trouvé');

      final profile = await _supabase
          .from('profiles')
          .select()
          .eq('id', response.user!.id)
          .single()
          .timeout(const Duration(seconds: 20));

      _currentUser = _profileToUser(profile);
      await _loadUserData();
      return _currentUser!;
    } on TimeoutException catch (e) {
      throw Exception('Erreur de connexion: délai dépassé. Vérifiez votre connexion.');
    } on AuthException catch (e) {
      throw Exception('Erreur de connexion: ${e.message}');
    } catch (e) {
      final msg = e.toString().toLowerCase();
      if (msg.contains('socketexception') || msg.contains('connection reset')) {
        throw Exception('Impossible de contacter Supabase. Vérifiez votre réseau.');
      }
      throw Exception('Erreur de connexion: $e');
    }
  }

  // ✅ INSCRIPTION SUPABASE
  Future<app_user.User> register({
    required String email,
    required String password,
    required String firstName,
    required String lastName,
    required app_user.UserRole role,
    required app_user.SubscriptionType? subscription,
  }) async {
    try {
      final response = await _supabase.auth.signUp(
        email: email,
        password: password,
        data: {
          'first_name': firstName,
          'last_name': lastName,
          'role': role.name,
          'subscription': subscription?.name ?? 'free',
        },
      ).timeout(const Duration(seconds: 30));

      if (response.user == null) throw Exception('Erreur lors de l\'inscription');

      try {
        await _supabase.from('profiles').upsert({
          'id': response.user!.id,
          'email': email,
          'first_name': firstName,
          'last_name': lastName,
          'role': role.name,
          'subscription': subscription?.name ?? 'free',
        }).select().timeout(const Duration(seconds: 20));
      } catch (e) {
        print('⚠️ [register] Profile upsert: $e');
      }

      Map<String, dynamic>? profile;
      for (int attempt = 1; attempt <= 3; attempt++) {
        try {
          profile = await _supabase
              .from('profiles')
              .select()
              .eq('id', response.user!.id)
              .single()
              .timeout(const Duration(seconds: 10));
          break;
        } catch (e) {
          if (attempt == 3) rethrow;
          await Future.delayed(const Duration(seconds: 1));
        }
      }
      if (profile == null) throw Exception('Impossible de récupérer le profil.');

      _currentUser = _profileToUser(profile);
      await _loadUserData();
      return _currentUser!;
    } on TimeoutException {
      throw Exception('Erreur d\'inscription: délai dépassé.');
    } on AuthException catch (e) {
      final msg = e.message.toLowerCase();
      if (msg.contains('rate limit')) {
        throw Exception('Trop de tentatives. Réessayez plus tard.');
      }
      throw Exception('Erreur d\'inscription: ${e.message}');
    } catch (e) {
      throw Exception('Erreur d\'inscription: $e');
    }
  }

  // ✅ DÉCONNEXION
  Future<void> logout() async {
    await _supabase.auth.signOut();
    _currentUser = null;
    _userClassrooms = [];
    _userRooms = [];
    _userStats = null;
  }

  // ✅ RESTAURER SESSION
  Future<app_user.User?> restoreSession() async {
    try {
      final session = _supabase.auth.currentSession;
      if (session == null) return null;

      final profile = await _supabase
          .from('profiles')
          .select()
          .eq('id', session.user.id)
          .single()
          .timeout(const Duration(seconds: 20));

      _currentUser = _profileToUser(profile);
      await _loadUserData();
      return _currentUser;
    } on TimeoutException {
      return null;
    } catch (e) {
      print('⚠️ [restoreSession] error: $e');
      return null;
    }
  }

  // ✅ CONVERTIR profil Supabase → User
  app_user.User _profileToUser(Map<String, dynamic> profile) {
    return app_user.User(
      id: profile['id'],
      email: profile['email'],
      firstName: profile['first_name'] ?? '',
      lastName: profile['last_name'] ?? '',
      role: app_user.UserRole.values.firstWhere(
        (r) => r.name == profile['role'],
        orElse: () => app_user.UserRole.student,
      ),
      subscription: app_user.SubscriptionType.values.firstWhere(
        (s) => s.name == profile['subscription'],
        orElse: () => app_user.SubscriptionType.free,
      ),
      createdAt: DateTime.parse(profile['created_at']),
      points: profile['points'] ?? 0,
      dailyQsmCount: profile['daily_qsm_count'] ?? 0,
      dailyQsmResetDate: profile['daily_qsm_reset_date'] != null
          ? DateTime.parse(profile['daily_qsm_reset_date'])
          : DateTime.now(),
      linkedChildId: profile['linked_child_id'],
    );
  }

  // ✅ CHARGER DONNÉES SELON RÔLE
  Future<void> _loadUserData() async {
    if (_currentUser == null) return;
    switch (_currentUser!.role) {
      case app_user.UserRole.teacher:
        await _loadTeacherData();
        break;
      case app_user.UserRole.student:
        await _loadStudentData();
        break;
      case app_user.UserRole.parent:
        await _loadParentData();
        break;
      case app_user.UserRole.admin:
        _userStats = UserStatistics(
          userId: _currentUser!.id,
          lastActivityAt: DateTime.now(),
        );
        break;
    }
  }

  Future<void> _loadTeacherData() async {
    try {
      final classrooms = await _supabase
          .from('classrooms')
          .select()
          .eq('teacher_id', _currentUser!.id)
          .order('created_at', ascending: false)
          .timeout(const Duration(seconds: 8));

      _userClassrooms = classrooms.map<Classroom>((c) => Classroom(
        id: c['id'],
        name: c['name'],
        description: c['description'],
        teacherId: c['teacher_id'],
        teacherName: c['teacher_name'] ?? _currentUser!.fullName,
        category: CourseCategory.values.firstWhere(
          (cat) => cat.name == c['category'],
          orElse: () => CourseCategory.other,
        ),
        level: CourseLevel.values.firstWhere(
          (lvl) => lvl.name == c['level'],
          orElse: () => CourseLevel.middleSchool,
        ),
        createdAt: DateTime.parse(c['created_at']),
        inviteCode: c['invite_code'] ?? _generateInviteCode(),
        totalStudents: c['total_students'] ?? 0,
        totalQsmCreated: c['total_qsm_created'] ?? 0,
      )).toList();

      final sessions = await _supabase
          .from('quiz_sessions')
          .select()
          .eq('user_id', _currentUser!.id)
          .timeout(const Duration(seconds: 8));

      _userStats = UserStatistics(
        userId: _currentUser!.id,
        totalQsmCreated: _userClassrooms.length,
        totalSessions: sessions.length,
        totalPoints: _currentUser!.points,
        lastActivityAt: DateTime.now(),
      );
    } catch (e) {
      print('⚠️ _loadTeacherData: $e');
      _userClassrooms = [];
      _userStats = UserStatistics(userId: _currentUser!.id, lastActivityAt: DateTime.now());
    }
  }

  Future<void> _loadStudentData() async {
    try {
      final sessions = await _supabase
          .from('quiz_sessions')
          .select()
          .eq('user_id', _currentUser!.id)
          .order('completed_at', ascending: false)
          .limit(20)
          .timeout(const Duration(seconds: 8));

      final scores = sessions
          .where((s) => s['score'] != null && s['total_questions'] != null && s['total_questions'] > 0)
          .map<int>((s) => ((s['score'] as int) * 100 ~/ (s['total_questions'] as int)))
          .toList();

      final avg = scores.isNotEmpty
          ? scores.reduce((a, b) => a + b) / scores.length
          : 0.0;

      _userStats = UserStatistics(
        userId: _currentUser!.id,
        totalQsmCompleted: sessions.length,
        averageScore: avg,
        totalPoints: _currentUser!.points,
        recentScores: scores.take(10).toList(),
        totalSessions: sessions.length,
        lastActivityAt: DateTime.now(),
      );
    } catch (e) {
      print('⚠️ _loadStudentData: $e');
      _userStats = UserStatistics(userId: _currentUser!.id, lastActivityAt: DateTime.now());
    }
  }

  Future<void> _loadParentData() async {
    try {
      _userStats = UserStatistics(
        userId: _currentUser!.id,
        lastActivityAt: DateTime.now(),
      );
    } catch (e) {
      print('⚠️ _loadParentData: $e');
    }
  }

  // ════════════════════════════════════════════════════════════════
  // NOUVELLES MÉTHODES SUPABASE
  // ════════════════════════════════════════════════════════════════

  /// Récupère les sessions récentes d'un étudiant avec le titre du cours
  Future<List<Map<String, dynamic>>> fetchStudentRecentSessions(String userId) async {
    try {
      final sessions = await _supabase
          .from('quiz_sessions')
          .select('*, courses(title, subject)')
          .eq('user_id', userId)
          .order('completed_at', ascending: false)
          .limit(10)
          .timeout(const Duration(seconds: 10));
      return List<Map<String, dynamic>>.from(sessions);
    } catch (e) {
      print('⚠️ fetchStudentRecentSessions: $e');
      return [];
    }
  }

  /// Récupère les scores des 7 derniers jours pour la courbe de performance
  Future<List<Map<String, dynamic>>> fetchWeeklyScores(String userId) async {
    try {
      final sevenDaysAgo = DateTime.now().subtract(const Duration(days: 7));
      final sessions = await _supabase
          .from('quiz_sessions')
          .select('score, total_questions, completed_at')
          .eq('user_id', userId)
          .gte('completed_at', sevenDaysAgo.toIso8601String())
          .order('completed_at', ascending: true)
          .timeout(const Duration(seconds: 10));
      return List<Map<String, dynamic>>.from(sessions);
    } catch (e) {
      print('⚠️ fetchWeeklyScores: $e');
      return [];
    }
  }

  /// Récupère les cours d'un enseignant
  Future<List<Map<String, dynamic>>> fetchTeacherCourses(String teacherId) async {
    try {
      final courses = await _supabase
          .from('courses')
          .select()
          .eq('teacher_id', teacherId)
          .order('created_at', ascending: false)
          .limit(20)
          .timeout(const Duration(seconds: 10));
      return List<Map<String, dynamic>>.from(courses);
    } catch (e) {
      print('⚠️ fetchTeacherCourses: $e');
      return [];
    }
  }

  /// Upload un cours simple
  Future<void> uploadCourse(Map<String, dynamic> courseData) async {
    if (_currentUser == null) return;
    try {
      await _supabase.from('courses').insert({
        ...courseData,
        'teacher_id': _currentUser!.id,
      }).timeout(const Duration(seconds: 10));
    } catch (e) {
      print('⚠️ uploadCourse error: $e');
      rethrow;
    }
  }

  /// Récupère les sessions de la semaine pour le graphe d'activité (enseignant)
  Future<Map<int, int>> fetchTeacherWeeklyActivity(String teacherId) async {
    try {
      final sevenDaysAgo = DateTime.now().subtract(const Duration(days: 7));
      final sessions = await _supabase
          .from('quiz_sessions')
          .select('completed_at, classroom_id')
          .gte('completed_at', sevenDaysAgo.toIso8601String())
          .inFilter('classroom_id', _userClassrooms.map((c) => c.id).toList())
          .timeout(const Duration(seconds: 10));

      final Map<int, int> byDay = {0: 0, 1: 0, 2: 0, 3: 0, 4: 0, 5: 0, 6: 0};
      for (final s in sessions) {
        if (s['completed_at'] != null) {
          final date = DateTime.parse(s['completed_at']);
          final dayIndex = DateTime.now().difference(date).inDays;
          if (dayIndex >= 0 && dayIndex < 7) {
            byDay[6 - dayIndex] = (byDay[6 - dayIndex] ?? 0) + 1;
          }
        }
      }
      return byDay;
    } catch (e) {
      print('⚠️ fetchTeacherWeeklyActivity: $e');
      return {0: 0, 1: 0, 2: 0, 3: 0, 4: 0, 5: 0, 6: 0};
    }
  }

  /// Récupère tous les cours (admin)
  Future<List<Map<String, dynamic>>> fetchAllCourses() async {
    try {
      final response = await _supabase
          .from('courses')
          .select()
          .order('created_at', ascending: false)
          .timeout(const Duration(seconds: 10));
      return List<Map<String, dynamic>>.from(response);
    } catch (e) {
      print('⚠️ fetchAllCourses: $e');
      return [];
    }
  }

  /// Crée un nouveau cours (admin)
  Future<Map<String, dynamic>> createCourse(Map<String, dynamic> courseData) async {
    try {
      final response = await _supabase
          .from('courses')
          .insert(courseData)
          .select()
          .single()
          .timeout(const Duration(seconds: 10));
      return Map<String, dynamic>.from(response);
    } catch (e) {
      print('⚠️ createCourse error: $e');
      rethrow;
    }
  }

  /// Met à jour un cours (admin)
  Future<Map<String, dynamic>> updateCourse(String courseId, Map<String, dynamic> courseData) async {
    try {
      final response = await _supabase
          .from('courses')
          .update(courseData)
          .eq('id', courseId)
          .select()
          .single()
          .timeout(const Duration(seconds: 10));
      return Map<String, dynamic>.from(response);
    } catch (e) {
      print('⚠️ updateCourse error: $e');
      rethrow;
    }
  }

  /// Supprime un cours (admin)
  Future<void> deleteCourse(String courseId) async {
    try {
      await _supabase
          .from('courses')
          .delete()
          .eq('id', courseId)
          .timeout(const Duration(seconds: 10));
    } catch (e) {
      print('⚠️ deleteCourse error: $e');
      rethrow;
    }
  }

  /// Met à jour le profil utilisateur
  Future<void> updateProfile({
    required String firstName,
    required String lastName,
    required String email,
  }) async {
    if (_currentUser == null) return;
    try {
      await _supabase
          .from('profiles')
          .update({
            'first_name': firstName,
            'last_name': lastName,
            'email': email,
          })
          .eq('id', _currentUser!.id)
          .timeout(const Duration(seconds: 10));

      // Mettre à jour l'utilisateur en mémoire
      _currentUser = app_user.User(
        id: _currentUser!.id,
        email: email,
        firstName: firstName,
        lastName: lastName,
        role: _currentUser!.role,
        subscription: _currentUser!.subscription,
        createdAt: _currentUser!.createdAt,
        lastActiveAt: _currentUser!.lastActiveAt,
        points: _currentUser!.points,
        dailyQsmCount: _currentUser!.dailyQsmCount,
        dailyQsmResetDate: _currentUser!.dailyQsmResetDate,
        linkedChildId: _currentUser!.linkedChildId,
        linkedParentIds: _currentUser!.linkedParentIds,
      );
    } catch (e) {
      print('⚠️ updateProfile error: $e');
      rethrow;
    }
  }

  /// Récupère tous les utilisateurs (admin) avec filtre optionnel par rôle
  Future<List<Map<String, dynamic>>> fetchAllUsers({String? roleFilter}) async {
    try {
      var query = _supabase.from('profiles').select();
      if (roleFilter != null && roleFilter != 'all') {
        query = query.eq('role', roleFilter);
      }
      final users = await query
          .order('created_at', ascending: false)
          .limit(100)
          .timeout(const Duration(seconds: 15));
      return List<Map<String, dynamic>>.from(users);
    } catch (e) {
      print('⚠️ fetchAllUsers: $e');
      return [];
    }
  }

  /// Récupère les statistiques globales pour l'admin
  Future<GlobalStatistics> getGlobalStatistics() async {
    try {
      final profiles = await _supabase.from('profiles').select('role, subscription');
      final courses = await _supabase.from('courses').select('id');
      final sessions = await _supabase.from('quiz_sessions').select('id');
      final classrooms = await _supabase.from('classrooms').select('id');

      final byRole = <String, int>{};
      final bySubscription = <String, int>{};
      for (final p in profiles) {
        final role = p['role'] as String;
        byRole[role] = (byRole[role] ?? 0) + 1;
        final sub = p['subscription'] as String? ?? 'free';
        bySubscription[sub] = (bySubscription[sub] ?? 0) + 1;
      }

      return GlobalStatistics(
        totalUsers: profiles.length,
        totalTeachers: byRole['teacher'] ?? 0,
        totalStudents: byRole['student'] ?? 0,
        totalParents: byRole['parent'] ?? 0,
        totalQsmCreated: courses.length,
        totalQsmCompleted: sessions.length,
        totalClassrooms: classrooms.length,
        totalActiveRooms: 0,
        usersByRole: byRole,
        subscriptionCounts: bySubscription,
        lastUpdated: DateTime.now(),
      );
    } catch (e) {
      throw Exception('Erreur statistiques: $e');
    }
  }

  /// Récupère les sessions par jour des 7 derniers jours (admin)
  Future<Map<int, int>> fetchAdminWeeklyActivity() async {
    try {
      final sevenDaysAgo = DateTime.now().subtract(const Duration(days: 7));
      final sessions = await _supabase
          .from('quiz_sessions')
          .select('completed_at')
          .gte('completed_at', sevenDaysAgo.toIso8601String())
          .timeout(const Duration(seconds: 10));

      final Map<int, int> byDay = {0: 0, 1: 0, 2: 0, 3: 0, 4: 0, 5: 0, 6: 0};
      for (final s in sessions) {
        if (s['completed_at'] != null) {
          final date = DateTime.parse(s['completed_at']);
          final dayIndex = DateTime.now().difference(date).inDays;
          if (dayIndex >= 0 && dayIndex < 7) {
            byDay[6 - dayIndex] = (byDay[6 - dayIndex] ?? 0) + 1;
          }
        }
      }
      return byDay;
    } catch (e) {
      print('⚠️ fetchAdminWeeklyActivity: $e');
      return {0: 0, 1: 0, 2: 0, 3: 0, 4: 0, 5: 0, 6: 0};
    }
  }

  /// Récupère les sessions d'un enfant (pour le parent)
  Future<List<Map<String, dynamic>>> fetchChildSessions(String childId) async {
    try {
      final sessions = await _supabase
          .from('quiz_sessions')
          .select('*, courses(title, subject)')
          .eq('user_id', childId)
          .order('completed_at', ascending: false)
          .limit(20)
          .timeout(const Duration(seconds: 10));
      return List<Map<String, dynamic>>.from(sessions);
    } catch (e) {
      print('⚠️ fetchChildSessions: $e');
      return [];
    }
  }

  /// Récupère le profil d'un enfant
  Future<Map<String, dynamic>?> fetchChildProfile(String childId) async {
    try {
      final profile = await _supabase
          .from('profiles')
          .select()
          .eq('id', childId)
          .single()
          .timeout(const Duration(seconds: 10));
      return profile;
    } catch (e) {
      print('⚠️ fetchChildProfile: $e');
      return null;
    }
  }

  /// Récupère les enseignants des classes d'un étudiant (pour le parent)
  Future<List<Map<String, dynamic>>> fetchChildTeachers(String childId) async {
    try {
      final memberships = await _supabase
          .from('classroom_members')
          .select('classroom_id')
          .eq('student_id', childId)
          .timeout(const Duration(seconds: 10));

      if (memberships.isEmpty) return [];

      final classroomIds = memberships.map((m) => m['classroom_id']).toList();
      final classrooms = await _supabase
          .from('classrooms')
          .select('teacher_id, teacher_name, category')
          .inFilter('id', classroomIds)
          .timeout(const Duration(seconds: 10));

      return List<Map<String, dynamic>>.from(classrooms);
    } catch (e) {
      print('⚠️ fetchChildTeachers: $e');
      return [];
    }
  }

  // ════════════════════════════════════════════════════════════════
  // CRÉER CLASSROOM (Supabase)
  // ════════════════════════════════════════════════════════════════
  Future<Classroom> createClassroom({
    required String name,
    String? description,
    required CourseCategory category,
    required CourseLevel level,
  }) async {
    if (_currentUser?.role != app_user.UserRole.teacher) {
      throw Exception('Seuls les enseignants peuvent créer des classrooms');
    }
    try {
      final inviteCode = _generateInviteCode();
      final data = await _supabase.from('classrooms').insert({
        'name': name,
        'description': description,
        'teacher_id': _currentUser!.id,
        'teacher_name': _currentUser!.fullName,
        'category': category.name,
        'level': level.name,
        'invite_code': inviteCode,
      }).select().single();

      final classroom = Classroom(
        id: data['id'],
        name: data['name'],
        description: data['description'],
        teacherId: data['teacher_id'],
        teacherName: data['teacher_name'],
        category: category,
        level: level,
        createdAt: DateTime.parse(data['created_at']),
        inviteCode: data['invite_code'],
      );

      _userClassrooms.add(classroom);
      return classroom;
    } catch (e) {
      throw Exception('Erreur création classroom: $e');
    }
  }

  // ════════════════════════════════════════════════════════════════
  // CRÉER ROOM (mock temporaire)
  // ════════════════════════════════════════════════════════════════
  Future<Room> createRoom({
    required String name,
    required String classroomId,
    required String qcmSessionId,
    int? timerMinutes,
    int maxParticipants = 50,
    bool allowAnonymous = false,
  }) async {
    if (_currentUser?.role != app_user.UserRole.teacher) {
      throw Exception('Seuls les enseignants peuvent créer des rooms');
    }
    await Future.delayed(const Duration(seconds: 1));
    final code = _generateInviteCode();
    final room = Room(
      id: 'room_${DateTime.now().millisecondsSinceEpoch}',
      name: name,
      classroomId: classroomId,
      teacherId: _currentUser!.id,
      qcmSessionId: qcmSessionId,
      inviteLink: 'https://skwilti.app/room/$code',
      roomCode: code,
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
  }
}
