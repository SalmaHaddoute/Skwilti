import 'dart:math';
import 'dart:async';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../models/user.dart' as app_user;
import '../models/classroom.dart';
import '../models/room.dart';
import '../models/statistics.dart';
import 'points_service.dart';

class AuthService {
  final _supabase = Supabase.instance.client;

  app_user.User? _currentUser;
  List<Classroom> _userClassrooms = [];
  List<Room> _userRooms = [];
  List<Map<String, dynamic>> _recentSessions = [];
  List<Map<String, dynamic>> _weeklyScores = [];
  UserStatistics? _userStats;

  app_user.User? get currentUser => _currentUser;
  List<Classroom> get userClassrooms => _userClassrooms;
  List<Room> get userRooms => _userRooms;
  UserStatistics? get userStats => _userStats;
  List<Map<String, dynamic>> get recentSessions => _recentSessions;
  List<Map<String, dynamic>> get weeklyScores => _weeklyScores;
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
      await loadUserData();
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
      await loadUserData();
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

  /// Permet à l'administrateur d'inscrire un utilisateur sans déconnecter sa propre session
  Future<void> adminCreateUser({
    required String email,
    required String password,
    required String firstName,
    required String lastName,
    required app_user.UserRole role,
    required app_user.SubscriptionType subscription,
  }) async {
    try {
      final tempClient = SupabaseClient(
        'https://lipakwyzlrdiooknchfi.supabase.co',
        'sb_publishable_E_R4wDuXn5AvfEW76fDduw_nM6eBQBA',
        authOptions: const AuthClientOptions(
          pkceAsyncStorage: DummyAsyncStorage(),
        ),
      );
      
      final response = await tempClient.auth.signUp(
        email: email,
        password: password,
        data: {
          'first_name': firstName,
          'last_name': lastName,
          'role': role.name,
          'subscription': subscription.name,
        },
      ).timeout(const Duration(seconds: 30));

      if (response.user == null) {
        throw Exception('Erreur lors de l\'inscription Supabase Auth');
      }

      // Insérer ou mettre à jour dans les profiles (avec le client temporaire pour RLS, fallback sur le client principal)
      try {
        await tempClient.from('profiles').upsert({
          'id': response.user!.id,
          'email': email,
          'first_name': firstName,
          'last_name': lastName,
          'role': role.name,
          'subscription': subscription.name,
        }).timeout(const Duration(seconds: 15));
      } catch (e) {
        print('⚠️ tempClient upsert failed: $e. Trying main admin client...');
        await _supabase.from('profiles').upsert({
          'id': response.user!.id,
          'email': email,
          'first_name': firstName,
          'last_name': lastName,
          'role': role.name,
          'subscription': subscription.name,
        }).timeout(const Duration(seconds: 15));
      }

    } catch (e) {
      throw Exception(e.toString());
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
      await loadUserData();
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

   Future<void> loadUserData() async {
    if (_currentUser == null) return;
    switch (_currentUser!.role) {
      case app_user.UserRole.teacher:
        await _loadTeacherData();
        break;
      case app_user.UserRole.student:
        await _loadStudentData();
        break;
      case app_user.UserRole.admin:
        // Admin data loaded on demand
        break;
      case app_user.UserRole.parent:
        // Parent data loaded on demand
        break;
    }
  }

  Future<void> _loadTeacherData() async {
    try {
      final classrooms = await _supabase
          .from('classrooms')
          .select('*, classroom_members(count), classes_scolaires(profiles(count))')
          .eq('teacher_id', _currentUser!.id)
          .order('created_at', ascending: false)
          .timeout(const Duration(seconds: 10));

      _userClassrooms = classrooms.map<Classroom>((c) => _mapSingleClassroom(c)).toList();
      await fetchTeacherRooms(_currentUser!.id);
    } catch (e) {
      print('⚠️ _loadTeacherData: $e');
    }
  }

  Classroom _mapSingleClassroom(Map<String, dynamic> c) {
    return Classroom(
      id: c['id'],
      name: c['name'],
      description: c['description'],
      teacherId: c['teacher_id'],
      teacherName: c['teacher_name'] ?? (_currentUser?.fullName ?? 'Enseignant'),
      category: CourseCategory.values.firstWhere(
        (cat) => cat.name == c['category'],
        orElse: () => CourseCategory.other,
      ),
      level: CourseLevel.values.firstWhere(
        (lvl) => lvl.name == c['level'],
        orElse: () => CourseLevel.middleSchool,
      ),
      createdAt: DateTime.parse(c['created_at']),
      inviteCode: c['invite_code'] ?? '',
      totalStudents: (() {
        int manualCount = 0;
        if (c['classroom_members'] is List && (c['classroom_members'] as List).isNotEmpty) {
          manualCount = (c['classroom_members'] as List)[0]['count'] ?? 0;
        }
        int schoolClassCount = 0;
        if (c['classes_scolaires'] != null) {
          final cs = c['classes_scolaires'];
          if (cs['profiles'] is List && (cs['profiles'] as List).isNotEmpty) {
            schoolClassCount = (cs['profiles'] as List)[0]['count'] ?? 0;
          }
        }
        return manualCount > schoolClassCount ? manualCount : schoolClassCount;
      })(),
      totalQsmCreated: c['total_qsm_created'] ?? 0,
      classeScolaireId: c['classe_scolaire_id']?.toString(),
    );
  }

  Future<void> _loadStudentData() async {
    try {
      // 1. Récupérer les sessions
      final sessions = await _supabase
          .from('quiz_sessions')
          .select('*, courses(title)')
          .eq('user_id', _currentUser!.id)
          .order('completed_at', ascending: false)
          .timeout(const Duration(seconds: 8));

      _recentSessions = List<Map<String, dynamic>>.from(sessions);

      // 1.5 Récupérer les scores de la semaine
      _weeklyScores = await fetchWeeklyScores(_currentUser!.id);

      // 2. Calculer les statistiques réelles
      final scores = sessions
          .where((s) => s['score'] != null && s['total_questions'] != null && (s['total_questions'] as int) > 0)
          .map<int>((s) => ((s['score'] as int) * 100 ~/ (s['total_questions'] as int)))
          .toList();

      double avgScore = scores.isEmpty ? 0 : scores.reduce((a, b) => a + b) / scores.length;
      int bestScore = scores.isEmpty ? 0 : scores.reduce((a, b) => a > b ? a : b);

      _userStats = UserStatistics(
        userId: _currentUser!.id,
        totalQsmCompleted: sessions.length,
        averageScore: avgScore,
        totalPoints: _currentUser!.points,
        lastActivityAt: DateTime.now(),
      );

      // 3. Charger les classes
      List<Classroom> classrooms = [];
      final manualRes = await _supabase
          .from('classroom_members')
          .select('classrooms(*, classroom_members(count), classes_scolaires(profiles(count)))')
          .eq('student_id', _currentUser!.id);
      
      for (var item in manualRes) {
        if (item['classrooms'] != null) {
          classrooms.add(_mapSingleClassroom(item['classrooms']));
        }
      }
      _userClassrooms = classrooms;
    } catch (e) {
      print('⚠️ _loadStudentData: $e');
      _userStats = UserStatistics(userId: _currentUser!.id, lastActivityAt: DateTime.now());
    }
  }

  Future<List<Classroom>> fetchAllClassrooms() async {
    try {
      final response = await _supabase.from('classrooms').select().order('name', ascending: true);
      return response.map<Classroom>((c) => _mapSingleClassroom(c)).toList();
    } catch (e) {
      return [];
    }
  }

  Future<void> assignEtudiantToClasse({required String studentId, required String classeId}) async {
    await _supabase.from('profiles').update({'classe_id': classeId}).eq('id', studentId);
  }

  Future<List<Map<String, dynamic>>> fetchStudentsBySchoolClass(String schoolClassId) async {
    try {
      final res = await _supabase.from('profiles').select().eq('classe_id', schoolClassId).eq('role', 'student');
      return List<Map<String, dynamic>>.from(res);
    } catch (e) {
      return [];
    }
  }

  Future<List<Map<String, dynamic>>> fetchClassroomStudents(String classroomId, {String? schoolClassId}) async {
    try {
      final Map<String, Map<String, dynamic>> uniqueStudents = {};
      final memberResponse = await _supabase
          .from('classroom_members')
          .select('student:profiles(id, first_name, last_name, email, code_massar, avatar_url, classe_id)')
          .eq('classroom_id', classroomId);
      
      for (var m in memberResponse) {
        if (m['student'] != null) {
          final s = Map<String, dynamic>.from(m['student']);
          uniqueStudents[s['id'].toString()] = s;
        }
      }

      if (schoolClassId != null) {
        final schoolStudents = await fetchStudentsBySchoolClass(schoolClassId);
        for (var s in schoolStudents) {
          if (!uniqueStudents.containsKey(s['id'].toString())) {
            uniqueStudents[s['id'].toString()] = s;
          }
        }
      }
      return uniqueStudents.values.toList();
    } catch (e) {
      return [];
    }
  }

  Future<List<Map<String, dynamic>>> fetchNotifications() async {
    if (_currentUser == null) return [];
    try {
      // 🚀 Suppression automatique des notifications étudiantes de plus de 2 heures
      if (_currentUser!.role == app_user.UserRole.student) {
        final twoHoursAgo = DateTime.now().subtract(const Duration(hours: 2)).toIso8601String();
        try {
          await _supabase.from('notifications')
              .delete()
              .eq('user_id', _currentUser!.id)
              .lt('created_at', twoHoursAgo);
        } catch (e) {
          print('⚠️ Erreur lors de la suppression des anciennes notifications: $e');
        }
      }

      final res = await _supabase.from('notifications').select().eq('user_id', _currentUser!.id).order('created_at', ascending: false);
      return List<Map<String, dynamic>>.from(res);
    } catch (e) {
      return [];
    }
  }

  /// Soumet une réclamation et l'envoie à tous les administrateurs
  Future<void> submitComplaint({
    required String email,
    required String subject,
    required String description,
  }) async {
    try {
      // 1. Récupérer tous les administrateurs
      final admins = await _supabase
          .from('profiles')
          .select('id')
          .eq('role', 'admin');

      // 2. Insérer une notification pour chaque administrateur
      if (admins.isNotEmpty) {
        final List<Map<String, dynamic>> notifs = [];
        for (var admin in admins) {
          final adminId = admin['id']?.toString();
          if (adminId != null) {
            notifs.add({
              'user_id': adminId,
              'title': '🚨 Réclamation : $subject',
              'message': 'De $email : $description',
              'type': 'other',
              'is_read': false,
              'created_at': DateTime.now().toIso8601String(),
            });
          }
        }
        if (notifs.isNotEmpty) {
          await _supabase.from('notifications').insert(notifs);
        }
      }
    } catch (e) {
      print('⚠️ Erreur lors de la soumission de la réclamation: $e');
      rethrow;
    }
  }

  /// Envoie une notification à l'enseignant quand un étudiant rejoint sa room
  Future<void> sendRoomJoinNotification({
    required String teacherId,
    required String studentName,
    required String roomName,
    required String roomId,
  }) async {
    try {
      await _supabase.from('notifications').insert({
        'user_id': teacherId,
        'title': 'Nouvel élève dans la room',
        'message': '$studentName vient de rejoindre la room "$roomName"',
        'type': 'room_join',
        'data': {'room_id': roomId, 'student_name': studentName},
        'is_read': false,
        'created_at': DateTime.now().toIso8601String(),
      });
    } catch (e) {
      print('⚠️ sendRoomJoinNotification: $e');
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

  /// Upload un cours simple et retourne son ID
  Future<String> uploadCourse(Map<String, dynamic> courseData) async {
    if (_currentUser == null) throw Exception('Non connecté');
    try {
      final res = await _supabase.from('courses').insert({
        ...courseData,
        'teacher_id': _currentUser!.id,
      }).select('id').single().timeout(const Duration(seconds: 10));
      
      // Award 50 points to the teacher
      try {
        await PointsService.incrementPoints(_currentUser!.id, 50);
        _currentUser = _currentUser!.copyWith(points: _currentUser!.points + 50);
        print('🏆 [uploadCourse] Enseignant a gagné +50 points !');
      } catch (pe) {
        print('🔴 Erreur ajout points enseignant: $pe');
      }
      
      return res['id'].toString();
    } catch (e) {
      print('⚠️ uploadCourse error: $e');
      rethrow;
    }
  }

  /// Récupère les sessions de la semaine pour le graphe d'activité (enseignant)
  Future<Map<int, int>> fetchTeacherWeeklyActivity(String teacherId) async {
    try {
      final sevenDaysAgo = DateTime.now().subtract(const Duration(days: 7));
      
      // 1. Récupérer les cours créés par l'enseignant
      final coursesRes = await _supabase
          .from('courses')
          .select('created_at')
          .eq('teacher_id', teacherId)
          .gte('created_at', sevenDaysAgo.toIso8601String())
          .timeout(const Duration(seconds: 10));

      // 2. Récupérer les rooms créées par l'enseignant
      final roomsRes = await _supabase
          .from('rooms')
          .select('created_at')
          .eq('teacher_id', teacherId)
          .gte('created_at', sevenDaysAgo.toIso8601String())
          .timeout(const Duration(seconds: 10));

      // 3. Récupérer les classes créées par l'enseignant
      final classroomsRes = await _supabase
          .from('classrooms')
          .select('created_at')
          .eq('teacher_id', teacherId)
          .gte('created_at', sevenDaysAgo.toIso8601String())
          .timeout(const Duration(seconds: 10));

      final Map<int, int> byDay = {0: 0, 1: 0, 2: 0, 3: 0, 4: 0, 5: 0, 6: 0};
      final today = DateTime.now();
      final todayStart = DateTime(today.year, today.month, today.day);

      void incrementDay(String? createdAtStr) {
        if (createdAtStr != null) {
          final date = DateTime.tryParse(createdAtStr);
          if (date != null) {
            final localDate = date.toLocal();
            final itemStart = DateTime(localDate.year, localDate.month, localDate.day);
            final dayIndex = todayStart.difference(itemStart).inDays;
            if (dayIndex >= 0 && dayIndex < 7) {
              byDay[6 - dayIndex] = (byDay[6 - dayIndex] ?? 0) + 1;
            }
          }
        }
      }

      for (final c in coursesRes) {
        incrementDay(c['created_at']?.toString());
      }
      for (final r in roomsRes) {
        incrementDay(r['created_at']?.toString());
      }
      for (final cl in classroomsRes) {
        incrementDay(cl['created_at']?.toString());
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

  // ─── CRUD Filières ───────────────────────────────────────
  Future<List<Map<String, dynamic>>> fetchAllFilieres() async {
    try {
      print('🔵 [fetchAllFilieres] Début de la récupération...');
      final response = await _supabase
          .from('filieres')
          .select()
          .order('ordre', ascending: true)
          .timeout(const Duration(seconds: 10));
      print('🟢 [fetchAllFilieres] ${response.length} filières récupérées: $response');
      return List<Map<String, dynamic>>.from(response);
    } catch (e) {
      print('🔴 [fetchAllFilieres] error: $e');
      return [];
    }
  }

  Future<Map<String, dynamic>> createFiliere(Map<String, dynamic> data) async {
    try {
      final response = await _supabase
          .from('filieres')
          .insert(data)
          .select()
          .single()
          .timeout(const Duration(seconds: 10));
      return Map<String, dynamic>.from(response);
    } catch (e) {
      print('⚠️ createFiliere error: $e');
      rethrow;
    }
  }

  Future<Map<String, dynamic>> updateFiliere(String id, Map<String, dynamic> data) async {
    try {
      final response = await _supabase
          .from('filieres')
          .update(data)
          .eq('id', id)
          .select()
          .single()
          .timeout(const Duration(seconds: 10));
      return Map<String, dynamic>.from(response);
    } catch (e) {
      print('⚠️ updateFiliere error: $e');
      rethrow;
    }
  }

  Future<void> deleteFiliere(String id) async {
    try {
      await _supabase
          .from('filieres')
          .delete()
          .eq('id', id)
          .timeout(const Duration(seconds: 10));
    } catch (e) {
      print('⚠️ deleteFiliere error: $e');
      rethrow;
    }
  }

  // ─── CRUD Niveaux ───────────────────────────────────────
  Future<List<Map<String, dynamic>>> fetchNiveauxByFiliere(String filiereId) async {
    try {
      final response = await _supabase
          .from('niveaux')
          .select()
          .eq('filiere_id', filiereId)
          .order('ordre', ascending: true)
          .timeout(const Duration(seconds: 10));
      return List<Map<String, dynamic>>.from(response);
    } catch (e) {
      print('⚠️ fetchNiveauxByFiliere error: $e');
      return [];
    }
  }

  Future<List<Map<String, dynamic>>> fetchAllNiveaux() async {
    try {
      print('🔵 [fetchAllNiveaux] Début de la récupération...');
      final response = await _supabase
          .from('niveaux')
          .select()
          .order('ordre', ascending: true)
          .timeout(const Duration(seconds: 10));
      print('🟢 [fetchAllNiveaux] ${response.length} niveaux récupérés: $response');
      return List<Map<String, dynamic>>.from(response);
    } catch (e) {
      print('🔴 [fetchAllNiveaux] error: $e');
      return [];
    }
  }

  Future<Map<String, dynamic>> createNiveau(Map<String, dynamic> data) async {
    try {
      final response = await _supabase
          .from('niveaux')
          .insert(data)
          .select()
          .single()
          .timeout(const Duration(seconds: 10));
      return Map<String, dynamic>.from(response);
    } catch (e) {
      print('⚠️ createNiveau error: $e');
      rethrow;
    }
  }

  Future<Map<String, dynamic>> updateNiveau(String id, Map<String, dynamic> data) async {
    try {
      final response = await _supabase
          .from('niveaux')
          .update(data)
          .eq('id', id)
          .select()
          .single()
          .timeout(const Duration(seconds: 10));
      return Map<String, dynamic>.from(response);
    } catch (e) {
      print('⚠️ updateNiveau error: $e');
      rethrow;
    }
  }

  Future<void> deleteNiveau(String id) async {
    try {
      await _supabase
          .from('niveaux')
          .delete()
          .eq('id', id)
          .timeout(const Duration(seconds: 10));
    } catch (e) {
      print('⚠️ deleteNiveau error: $e');
      rethrow;
    }
  }

  // ─── CRUD Matières ─────────────────────────────────────
  Future<List<Map<String, dynamic>>> fetchMatieresByNiveau(String niveauId) async {
    try {
      final response = await _supabase
          .from('matieres')
          .select()
          .eq('niveau_id', niveauId)
          .order('ordre', ascending: true)
          .timeout(const Duration(seconds: 10));
      return List<Map<String, dynamic>>.from(response);
    } catch (e) {
      print('⚠️ fetchMatieresByNiveau error: $e');
      return [];
    }
  }

  Future<List<Map<String, dynamic>>> fetchAllMatieres() async {
    try {
      print('🔵 [fetchAllMatieres] Début de la récupération...');
      final response = await _supabase
          .from('matieres')
          .select()
          .order('ordre', ascending: true)
          .timeout(const Duration(seconds: 10));
      print('🟢 [fetchAllMatieres] ${response.length} matières récupérées: $response');
      return List<Map<String, dynamic>>.from(response);
    } catch (e) {
      print('🔴 [fetchAllMatieres] error: $e');
      return [];
    }
  }

  Future<Map<String, dynamic>> createMatiere(Map<String, dynamic> data) async {
    try {
      final response = await _supabase
          .from('matieres')
          .insert(data)
          .select()
          .single()
          .timeout(const Duration(seconds: 10));
      return Map<String, dynamic>.from(response);
    } catch (e) {
      print('⚠️ createMatiere error: $e');
      rethrow;
    }
  }

  Future<Map<String, dynamic>> updateMatiere(String id, Map<String, dynamic> data) async {
    try {
      final response = await _supabase
          .from('matieres')
          .update(data)
          .eq('id', id)
          .select()
          .single()
          .timeout(const Duration(seconds: 10));
      return Map<String, dynamic>.from(response);
    } catch (e) {
      print('⚠️ updateMatiere error: $e');
      rethrow;
    }
  }

  Future<void> deleteMatiere(String id) async {
    try {
      await _supabase
          .from('matieres')
          .delete()
          .eq('id', id)
          .timeout(const Duration(seconds: 10));
    } catch (e) {
      print('⚠️ deleteMatiere error: $e');
      rethrow;
    }
  }

  // ─── CRUD Classes Scolaires ───────────────────────────────
  Future<Map<String, dynamic>> createClasseScolaire({
    required String filiereId,
    required String niveauId,
    required String nom,
    required String anneeScolaire,
  }) async {
    try {
      print('🔵 [createClasseScolaire] Début de la création...');
      final response = await _supabase
          .from('classes_scolaires')
          .insert({
            'filiere_id': filiereId,
            'niveau_id': niveauId,
            'nom': nom,
            'annee_scolaire': anneeScolaire,
            'effectif': 0,
            'is_active': true,
            'created_at': DateTime.now().toIso8601String(),
          })
          .select()
          .single()
          .timeout(const Duration(seconds: 10));
      print('🟢 [createClasseScolaire] Classe créée: $response');
      return Map<String, dynamic>.from(response);
    } catch (e) {
      print('🔴 [createClasseScolaire] error: $e');
      rethrow;
    }
  }

  Future<List<Map<String, dynamic>>> fetchAllClassesScolaires() async {
    try {
      print('🔵 [fetchAllClassesScolaires] Début de la récupération...');
      final response = await _supabase
          .from('classes_scolaires')
          .select('*, filieres(*), niveaux(*)')
          .order('created_at', ascending: false)
          .timeout(const Duration(seconds: 10));
      print('🟢 [fetchAllClassesScolaires] ${response.length} classes récupérées');
      return List<Map<String, dynamic>>.from(response);
    } catch (e) {
      print('🔴 [fetchAllClassesScolaires] error: $e');
      return [];
    }
  }

  // ─── CRUD Classe Professeurs ───────────────────────────────────────
  Future<Map<String, dynamic>> createClasseProf({
    required String classeId,
    required String matiereId,
    required String professeurId,
  }) async {
    try {
      print('🔵 [createClasseProf] Début de la création...');
      final response = await _supabase
          .from('classe_professeurs')
          .insert({
            'classe_id': classeId,
            'matiere_id': matiereId,
            'professeur_id': professeurId,
            'created_at': DateTime.now().toIso8601String(),
          })
          .select('*, matieres(*), profiles(*)')
          .single()
          .timeout(const Duration(seconds: 10));
      print('🟢 [createClasseProf] Affectation créée: $response');
      return Map<String, dynamic>.from(response);
    } catch (e) {
      print('🔴 [createClasseProf] error: $e');
      rethrow;
    }
  }

  Future<List<Map<String, dynamic>>> fetchClasseProfs(String classeId) async {
    try {
      print('🔵 [fetchClasseProfs] Début de la récupération pour classe $classeId...');
      final response = await _supabase
          .from('classe_professeurs')
          .select('*, matieres(*), profiles(*)')
          .eq('classe_id', classeId)
          .timeout(const Duration(seconds: 10));
      print('🟢 [fetchClasseProfs] ${response.length} affectations récupérées');
      return List<Map<String, dynamic>>.from(response);
    } catch (e) {
      print('🔴 [fetchClasseProfs] error: $e');
      return [];
    }
  }

  Future<void> deleteClasseProf(String assignmentId) async {
    try {
      print('🔵 [deleteClasseProf] Suppression de l\'affectation $assignmentId...');
      await _supabase
          .from('classe_professeurs')
          .delete()
          .eq('id', assignmentId)
          .timeout(const Duration(seconds: 10));
      print('🟢 [deleteClasseProf] Affectation supprimée');
    } catch (e) {
      print('🔴 [deleteClasseProf] error: $e');
      rethrow;
    }
  }

  Future<List<Map<String, dynamic>>> fetchAllTeachers() async {
    try {
      print('🔵 [fetchAllTeachers] Début de la récupération...');
      final response = await _supabase
          .from('profiles')
          .select()
          .eq('role', 'teacher')
          .timeout(const Duration(seconds: 10));
      print('🟢 [fetchAllTeachers] ${response.length} professeurs récupérés');
      return List<Map<String, dynamic>>.from(response);
    } catch (e) {
      print('🔴 [fetchAllTeachers] error: $e');
      return [];
    }
  }

  // ─── CRUD Étudiants ───────────────────────────────────────
  Future<Map<String, dynamic>> createEtudiantAndAddToClasse({
    required String classeId,
    required String codeMassar,
    required String prenom,
    required String nom,
    required String dateNaissance,
    required String cin,
    required String email,
    required String telephone,
  }) async {
    try {
      print('🔵 [createEtudiantAndAddToClasse] Début de la création...');
      
      // Créer le profil étudiant avec classe_id direct
      final emailToUse = email.isEmpty ? '$codeMassar@skwilti.ma' : email;
      final response = await _supabase
          .from('profiles')
          .insert({
            'first_name': prenom,
            'last_name': nom,
            'email': emailToUse,
            'role': 'student',
            'subscription': 'free',
            'code_massar': codeMassar,
            'date_naissance': dateNaissance.isNotEmpty ? dateNaissance : null,
            'cin': cin.isNotEmpty ? cin : null,
            'telephone': telephone.isNotEmpty ? telephone : null,
            'classe_id': classeId,
            'annee_scolaire': '2025-2026',
            'created_at': DateTime.now().toIso8601String(),
          })
          .select()
          .single()
          .timeout(const Duration(seconds: 10));

      print('🟢 [createEtudiantAndAddToClasse] Étudiant créé et ajouté à la classe');
      return Map<String, dynamic>.from(response);
    } catch (e) {
      print('🔴 [createEtudiantAndAddToClasse] error: $e');
      rethrow;
    }
  }

  // ─── CRUD Parent ↔ Enfant ──────────────────────────────
  Future<List<Map<String, dynamic>>> fetchAdminParents() async {
    try {
      final response = await _supabase
          .from('vue_admin_parents')
          .select()
          .timeout(const Duration(seconds: 10));
      return List<Map<String, dynamic>>.from(response);
    } catch (e) {
      print('⚠️ fetchAdminParents error: $e');
      return [];
    }
  }

  Future<Map<String, dynamic>> linkParentEnfant(String parentId, String enfantId, {String relation = 'parent'}) async {
    try {
      // 1. Créer la relation dans la table de liaison (parent_enfants)
      final response = await _supabase
          .from('parent_enfants')
          .insert({
            'parent_id': parentId,
            'enfant_id': enfantId,
            'relation': relation,
          })
          .select()
          .single()
          .timeout(const Duration(seconds: 10));

      return Map<String, dynamic>.from(response);
    } catch (e) {
      print('⚠️ linkParentEnfant error: $e');
      rethrow;
    }
  }

  Future<String?> fetchFirstLinkedChildId(String parentId) async {
    try {
      final response = await _supabase
          .from('parent_enfants')
          .select('enfant_id')
          .eq('parent_id', parentId)
          .limit(1)
          .maybeSingle();
      return response?['enfant_id']?.toString();
    } catch (e) {
      print('⚠️ fetchFirstLinkedChildId error: $e');
      return null;
    }
  }




  Future<void> updateParentEnfant(String parentId, String enfantId, Map<String, dynamic> data) async {
    try {
      await _supabase
          .from('parent_enfants')
          .update(data)
          .eq('parent_id', parentId)
          .eq('enfant_id', enfantId)
          .timeout(const Duration(seconds: 10));
    } catch (e) {
      print('⚠️ updateParentEnfant error: $e');
      rethrow;
    }
  }

  Future<void> unlinkParentEnfant(String parentId, String enfantId) async {
    try {
      await _supabase
          .from('parent_enfants')
          .delete()
          .eq('parent_id', parentId)
          .eq('enfant_id', enfantId)
          .timeout(const Duration(seconds: 10));
    } catch (e) {
      print('⚠️ unlinkParentEnfant error: $e');
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

  /// Récupère tous les étudiants pour le parent (avec filière et niveau)
  Future<List<Map<String, dynamic>>> fetchAllStudents() async {
    try {
      print('🔵 [fetchAllStudents] Début de la récupération...');
      
      // On récupère les étudiants avec une jointure sur parent_enfants pour savoir qui est lié
      final students = await _supabase
          .from('profiles')
          .select('id, first_name, last_name, email, code_massar, classe_id, filiere_id, niveau_id, classes_scolaires(filiere_id, niveau_id), linked_parents:parent_enfants!parent_enfants_enfant_id_fkey(parent_id)')
          .eq('role', 'student')
          .order('last_name', ascending: true)
          .timeout(const Duration(seconds: 15));

      // On aplatit les données
      final result = students.map<Map<String, dynamic>>((s) {
        final classe = s['classes_scolaires'] as Map<String, dynamic>?;
        final parents = s['linked_parents'] as List<dynamic>?;
        
        return {
          ...s,
          'filiere_id': (s['filiere_id'] ?? classe?['filiere_id'])?.toString(),
          'niveau_id': (s['niveau_id'] ?? classe?['niveau_id'])?.toString(),
          // On transforme la liste d'objets parent_enfants en une liste d'IDs de parents
          'linked_parent_ids': parents?.map((p) => p['parent_id']).toList() ?? [],
        };
      }).toList();



      print('🟢 [fetchAllStudents] ${result.length} étudiants récupérés');
      return result;
    } catch (e) {
      print('🔴 [fetchAllStudents] error: $e');
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

  /// Récupère l'activité de la plateforme par jour sur les 7 derniers jours (admin)
  Future<Map<int, int>> fetchAdminWeeklyActivity() async {
    try {
      final sevenDaysAgo = DateTime.now().subtract(const Duration(days: 7));
      
      // 1. Sessions terminées
      final sessions = await _supabase
          .from('quiz_sessions')
          .select('completed_at')
          .gte('completed_at', sevenDaysAgo.toIso8601String())
          .timeout(const Duration(seconds: 10));

      // 2. Nouveaux profils inscrits
      final profiles = await _supabase
          .from('profiles')
          .select('created_at')
          .gte('created_at', sevenDaysAgo.toIso8601String())
          .timeout(const Duration(seconds: 10));

      // 3. Nouvelles Rooms créées
      final rooms = await _supabase
          .from('rooms')
          .select('created_at')
          .gte('created_at', sevenDaysAgo.toIso8601String())
          .timeout(const Duration(seconds: 10));

      final Map<int, int> byDay = {0: 0, 1: 0, 2: 0, 3: 0, 4: 0, 5: 0, 6: 0};
      final today = DateTime.now();
      final todayStart = DateTime(today.year, today.month, today.day);

      void incrementDay(String? dateStr) {
        if (dateStr != null) {
          final date = DateTime.tryParse(dateStr);
          if (date != null) {
            final localDate = date.toLocal();
            final itemStart = DateTime(localDate.year, localDate.month, localDate.day);
            final dayIndex = todayStart.difference(itemStart).inDays;
            if (dayIndex >= 0 && dayIndex < 7) {
              byDay[6 - dayIndex] = (byDay[6 - dayIndex] ?? 0) + 1;
            }
          }
        }
      }

      for (final s in sessions) {
        incrementDay(s['completed_at']?.toString());
      }
      for (final p in profiles) {
        incrementDay(p['created_at']?.toString());
      }
      for (final r in rooms) {
        incrementDay(r['created_at']?.toString());
      }

      return byDay;
    } catch (e) {
      print('⚠️ fetchAdminWeeklyActivity: $e');
      return {0: 0, 1: 0, 2: 0, 3: 0, 4: 0, 5: 0, 6: 0};
    }
  }

  /// Récupère les sessions d'un enfant (pour le parent)
  Future<List<Map<String, dynamic>>> fetchChildSessions(String childId) async {
    print('📊 fetchChildSessions → childId=$childId');
    try {
      final sessions = await _supabase
          .from('quiz_sessions')
          .select('id, score, total_questions, completed_at, course_id, classroom_id, courses(title, subject), classrooms(profiles(first_name, last_name))')
          .eq('user_id', childId)
          .order('completed_at', ascending: false)
          .limit(50)
          .timeout(const Duration(seconds: 15));
      print('📊 fetchChildSessions → ${sessions.length} sessions found for child $childId');
      if (sessions.isNotEmpty) print('📊 first session: ${sessions.first}');
      return List<Map<String, dynamic>>.from(sessions);
    } catch (e) {
      print('❌ fetchChildSessions error: $e');
      // Fallback without join in case of FK/RLS issue
      try {
        final fallback = await _supabase
            .from('quiz_sessions')
            .select('id, score, total_questions, completed_at, course_id, classroom_id')
            .eq('user_id', childId)
            .order('completed_at', ascending: false)
            .limit(50)
            .timeout(const Duration(seconds: 15));
        print('📊 fetchChildSessions fallback → ${fallback.length} sessions');
        return List<Map<String, dynamic>>.from(fallback);
      } catch (e2) {
        print('❌ fetchChildSessions fallback error: $e2');
        return [];
      }
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

      // Award 20 points to the teacher
      try {
        await PointsService.incrementPoints(_currentUser!.id, 20);
        _currentUser = _currentUser!.copyWith(points: _currentUser!.points + 20);
        print('🏆 [createClassroom] Enseignant a gagné +20 points !');
      } catch (pe) {
        print('🔴 Erreur ajout points enseignant: $pe');
      }

      return classroom;
    } catch (e) {
      throw Exception('Erreur création classroom: $e');
    }
  }

  // ════════════════════════════════════════════════════════════════
  // CRÉER CLASSROOM AVEC CLASSE SCOLAIRE (import auto des étudiants)
  // ════════════════════════════════════════════════════════════════
  Future<Classroom> createClassroomWithSchoolClass({
    required String name,
    String? description,
    required String filiereId,
    required String niveauId,
    required String matiereId,
    required String classeScolaireId,
  }) async {
    if (_currentUser?.role != app_user.UserRole.teacher) {
      throw Exception('Seuls les enseignants peuvent créer des classrooms');
    }
    try {
      final inviteCode = _generateInviteCode();

      // 1. Créer le classroom avec les références
      final data = await _supabase.from('classrooms').insert({
        'name': name,
        'description': description,
        'teacher_id': _currentUser!.id,
        'teacher_name': _currentUser!.fullName,
        'filiere_id': filiereId,
        'niveau_id': niveauId,
        'matiere_id': matiereId,
        'classe_scolaire_id': classeScolaireId,
        'invite_code': inviteCode,
      }).select().single();

      final classroomId = data['id'];

      // 2. Récupérer les étudiants de la classe scolaire
      final students = await _supabase
          .from('profiles')
          .select('id')
          .eq('classe_id', classeScolaireId)
          .eq('role', 'student')
          .timeout(const Duration(seconds: 10));

      // 3. Importer les étudiants dans classroom_members
      if (students.isNotEmpty) {
        final members = students.map((s) => {
          'classroom_id': classroomId,
          'student_id': s['id'],
          'joined_at': DateTime.now().toIso8601String(),
        }).toList();

        await _supabase.from('classroom_members').insert(members);

        print('🟢 Importé ${members.length} étudiants dans classroom $classroomId');
      }

      // 4. Créer aussi l'affectation professeur-classe-matière (seulement si elle n'existe pas déjà)
      final existingAssignment = await _supabase
          .from('classe_professeurs')
          .select()
          .eq('classe_id', classeScolaireId)
          .eq('matiere_id', matiereId)
          .maybeSingle();

      if (existingAssignment == null) {
        await _supabase.from('classe_professeurs').insert({
          'classe_id': classeScolaireId,
          'matiere_id': matiereId,
          'professeur_id': _currentUser!.id,
          'created_at': DateTime.now().toIso8601String(),
        });
      }

      final classroom = Classroom(
        id: data['id'],
        name: data['name'],
        description: data['description'],
        teacherId: data['teacher_id'],
        teacherName: data['teacher_name'],
        category: CourseCategory.other, // Default since we're using filiere/niveau
        level: CourseLevel.other, // Default since we're using filiere/niveau
        createdAt: DateTime.parse(data['created_at']),
        inviteCode: data['invite_code'],
        totalStudents: students.length,
      );

      _userClassrooms.add(classroom);

      // Award 20 points to the teacher
      try {
        await PointsService.incrementPoints(_currentUser!.id, 20);
        _currentUser = _currentUser!.copyWith(points: _currentUser!.points + 20);
        print('🏆 [createClassroomWithSchoolClass] Enseignant a gagné +20 points !');
      } catch (pe) {
        print('🔴 Erreur ajout points enseignant: $pe');
      }

      return classroom;
    } catch (e) {
      throw Exception('Erreur création classroom avec classe scolaire: $e');
    }
  }

  // ════════════════════════════════════════════════════════════════
  // CRÉER ROOM (mock temporaire)
  // ════════════════════════════════════════════════════════════════
  /// Récupère les rooms de l'enseignant
  Future<List<Room>> fetchTeacherRooms(String teacherId) async {
    try {
      final response = await _supabase
          .from('rooms')
          .select()
          .eq('teacher_id', teacherId)
          .order('created_at', ascending: false)
          .timeout(const Duration(seconds: 10));
          
      _userRooms = response.map<Room>((r) => Room(
        id: r['id']?.toString() ?? '',
        name: r['name']?.toString() ?? '',
        classroomId: r['classroom_id']?.toString() ?? '',
        teacherId: r['teacher_id']?.toString() ?? '',
        qcmSessionId: r['qcm_session_id']?.toString() ?? '',
        inviteLink: r['invite_link']?.toString() ?? '',
        roomCode: r['room_code']?.toString(),
        createdAt: DateTime.tryParse(r['created_at']?.toString() ?? '') ?? DateTime.now(),
        startedAt: r['started_at'] != null ? DateTime.tryParse(r['started_at']) : null,
        expiresAt: r['expires_at'] != null ? DateTime.tryParse(r['expires_at']) : null,
        status: RoomStatus.values.firstWhere(
          (s) => s.name == (r['status'] ?? 'waiting'),
          orElse: () => RoomStatus.waiting,
        ),
        timerMinutes: r['timer_minutes'] as int?,
        maxParticipants: r['max_participants'] as int? ?? 50,
        allowAnonymous: r['allow_anonymous'] as bool? ?? false,
      )).toList();
      return _userRooms;
    } catch (e) {
      print('⚠️ fetchTeacherRooms: $e');
      return [];
    }
  }

  Future<Room> createRoom({
    required String name,
    required String classroomId,
    String? schoolClassId,
    required String qcmSessionId,
    int? timerMinutes,
    int maxParticipants = 50,
    bool allowAnonymous = false,
  }) async {
    if (_currentUser?.role != app_user.UserRole.teacher) {
      throw Exception('Seuls les enseignants peuvent créer des rooms');
    }

    final code = _generateInviteCode();
    final now = DateTime.now();
    final expiresAt = timerMinutes != null ? now.add(Duration(minutes: timerMinutes)) : null;

    final roomData = {
      'name': name,
      'classroom_id': classroomId,
      'teacher_id': _currentUser!.id,
      'qcm_session_id': qcmSessionId,
      'invite_link': 'https://skwilti.app/room/$code',
      'room_code': code,
      'created_at': now.toIso8601String(),
      'expires_at': expiresAt?.toIso8601String(),
      'status': 'active',
      'timer_minutes': timerMinutes,
      'max_participants': maxParticipants,
      'allow_anonymous': allowAnonymous,
    };

    try {
      final response = await _supabase
          .from('rooms')
          .insert(roomData)
          .select()
          .single();

      final room = Room(
        id: response['id'].toString(),
        name: response['name'],
        classroomId: response['classroom_id'],
        teacherId: response['teacher_id'],
        qcmSessionId: response['qcm_session_id'],
        inviteLink: response['invite_link'],
        roomCode: response['room_code'],
        createdAt: DateTime.parse(response['created_at']),
        expiresAt: response['expires_at'] != null ? DateTime.parse(response['expires_at']) : null,
        status: RoomStatus.active,
        timerMinutes: response['timer_minutes'],
        maxParticipants: response['max_participants'],
        allowAnonymous: response['allow_anonymous'],
      );

      _userRooms.insert(0, room);

      // Award 30 points to the teacher
      try {
        await PointsService.incrementPoints(_currentUser!.id, 30);
        _currentUser = _currentUser!.copyWith(points: _currentUser!.points + 30);
        print('🏆 [createRoom] Enseignant a gagné +30 points !');
      } catch (pe) {
        print('🔴 Erreur ajout points enseignant: $pe');
      }

      // Notification aux étudiants
      try {
        final students = await fetchClassroomStudents(classroomId, schoolClassId: schoolClassId);
        if (students.isNotEmpty) {
          final notifications = students.map((s) => {
            'user_id': s['id'],
            'title': 'Nouvelle Room de QSM !',
            'message': 'Rejoignez "$name" avec le code : $code',
            'type': 'room_created',
            'created_at': now.toIso8601String(),
            'is_read': false,
            'data': {'room_id': room.id, 'room_code': code}
          }).toList();
          await _supabase.from('notifications').insert(notifications);
        }
      } catch (e) {
        print('🔴 Erreur notifications: $e');
      }

      return room;
    } catch (e) {
      print('⚠️ createRoom error: $e');
      rethrow;
    }
  }

  Future<Map<String, dynamic>?> fetchRoomByCode(String code) async {
    print('🔍 [fetchRoomByCode] Recherche du code : $code');
    try {
      final roomResponse = await _supabase
          .from('rooms')
          .select()
          .eq('room_code', code.toUpperCase())
          .maybeSingle();
      
      if (roomResponse == null) {
        print('❌ [fetchRoomByCode] Room non trouvée pour le code : $code');
        return null;
      }

      print('✅ [fetchRoomByCode] Room trouvée : ${roomResponse['name']}');

      final sessionId = roomResponse['qcm_session_id']?.toString();
      if (sessionId != null && sessionId.isNotEmpty) {
        print('🆔 [fetchRoomByCode] sessionId trouvé : $sessionId');
        final uuidRegExp = RegExp(r'^[0-9a-f]{8}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{12}$', caseSensitive: false);
        
        if (uuidRegExp.hasMatch(sessionId)) {
          print('💎 [fetchRoomByCode] UUID valide, recherche des questions...');
          final sessionResponse = await _supabase.from('quiz_sessions').select().eq('id', sessionId).maybeSingle();
          roomResponse['quiz_sessions'] = sessionResponse;
          
          if (sessionResponse != null) {
            print('📋 [fetchRoomByCode] Session trouvée, chargement des questions via session...');
            roomResponse['questions'] = await fetchSessionQuestions(sessionId);
          } else {
            print('📝 [fetchRoomByCode] Session non trouvée, tentative de chargement direct par course_id...');
            roomResponse['questions'] = await fetchQuestionsByCourseId(sessionId);
          }
        } else {
          print('⚠️ [fetchRoomByCode] sessionId $sessionId n\'est pas un UUID valide.');
        }
      }
      
      final qCount = (roomResponse['questions'] as List?)?.length ?? 0;
      print('📊 [fetchRoomByCode] Nombre de questions récupérées : $qCount');
      
      return roomResponse;
    } catch (e) {
      print('🔴 [fetchRoomByCode] Erreur critique : $e');
      return null;
    }
  }

  Future<List<Map<String, dynamic>>> fetchSessionQuestions(String sessionId) async {
    try {
      final response = await _supabase
          .from('questions')
          .select()
          .eq('session_id', sessionId)
          .order('order_index', ascending: true);
      return List<Map<String, dynamic>>.from(response);
    } catch (e) {
      return [];
    }
  }

  Future<List<Map<String, dynamic>>> fetchQuestionsByCourseId(String courseId) async {
    try {
      final response = await _supabase
          .from('questions')
          .select()
          .eq('course_id', courseId)
          .order('created_at', ascending: true);
      return List<Map<String, dynamic>>.from(response);
    } catch (e) {
      return [];
    }
  }

  Future<void> saveSessionResult({
    required String sessionId,
    required String courseId,
    String? roomId,
    String? classroomId,
    required int score,
    required int totalQuestions,
    required Map<String, dynamic> answers,
  }) async {
    if (_currentUser == null) return;
    try {
      final now = DateTime.now();
      final dataToInsert = {
        'user_id': _currentUser!.id,
        'course_id': courseId,
        'room_id': roomId,
        'classroom_id': classroomId,
        'score': score,
        'total_questions': totalQuestions,
        'completed_at': now.toIso8601String(),
      };

      await _supabase.from('quiz_sessions').insert(dataToInsert);
      
      // Award 10 points per correct answer to the student
      final pointsToAward = score * 10;
      if (pointsToAward > 0) {
        await PointsService.incrementPoints(_currentUser!.id, pointsToAward);
        _currentUser = _currentUser!.copyWith(points: _currentUser!.points + pointsToAward);
        print('🏆 [saveSessionResult] Élève a gagné +$pointsToAward points !');
      }
      
      print('✅ [saveSessionResult] Score de $score enregistré avec succès !');
      await loadUserData();
    } catch (e) {
      print('🔴 [saveSessionResult] Erreur lors de l\'enregistrement : $e');
    }
  }

  Future<List<Map<String, dynamic>>> fetchRoomSessions(String roomId) async {
    try {
      // 1. Essayer d'abord la requête jointe directe (optimale)
      try {
        final response = await _supabase
            .from('quiz_sessions')
            .select('*, profiles(first_name, last_name, avatar_url)')
            .eq('room_id', roomId)
            .order('completed_at', ascending: false);
        if (response != null && (response as List).isNotEmpty) {
          return List<Map<String, dynamic>>.from(response);
        }
      } catch (e) {
        print('⚠️ fetchRoomSessions joint query failed: $e. Using bulletproof fallback...');
      }

      // 2. Fallback robuste en deux étapes (insensible aux relations de clé étrangère)
      final sessionsResponse = await _supabase
          .from('quiz_sessions')
          .select('*')
          .eq('room_id', roomId)
          .order('completed_at', ascending: false);
      
      final sessions = List<Map<String, dynamic>>.from(sessionsResponse ?? []);
      if (sessions.isEmpty) return [];

      // Extraire tous les user_ids uniques
      final userIds = sessions.map((s) => s['user_id']?.toString()).where((id) => id != null).toSet().toList();
      if (userIds.isEmpty) return sessions;

      // Récupérer les profils correspondants
      final profilesResponse = await _supabase
          .from('profiles')
          .select('id, first_name, last_name, avatar_url')
          .inFilter('id', userIds);
      
      final profiles = List<Map<String, dynamic>>.from(profilesResponse ?? []);
      final Map<String, Map<String, dynamic>> profileMap = {
        for (var p in profiles) p['id'].toString(): p
      };

      // Associer les profils aux sessions
      for (var s in sessions) {
        final uid = s['user_id']?.toString();
        if (uid != null && profileMap.containsKey(uid)) {
          s['profiles'] = profileMap[uid];
        }
      }

      return sessions;
    } catch (e) {
      print('⚠️ fetchRoomSessions ultimate fallback error: $e');
      return [];
    }
  }

  Future<List<Map<String, dynamic>>> fetchAdminCourses() async {
    try {
      final res = await _supabase
          .from('courses')
          .select()
          .order('created_at', ascending: false)
          .limit(100);
      return List<Map<String, dynamic>>.from(res);
    } catch (e) {
      print('⚠️ fetchAdminCourses: $e');
      return [];
    }
  }

  Future<String?> fetchSessionIdByCourseId(String courseId) async {
    try {
      final response = await _supabase.from('quiz_sessions').select('id').eq('course_id', courseId).maybeSingle();
      return response?['id']?.toString();
    } catch (e) {
      return null;
    }
  }

  Future<bool> hasCompletedSession({String? courseId, String? roomId}) async {
    if (_currentUser == null) return false;
    try {
      var query = _supabase.from('quiz_sessions').select().eq('user_id', _currentUser!.id);
      if (roomId != null) {
        query = query.eq('room_id', roomId);
      } else if (courseId != null) {
        query = query.eq('course_id', courseId);
      } else {
        return false;
      }
      
      final res = await query.timeout(const Duration(seconds: 5));
      return (res as List).isNotEmpty;
    } catch (e) {
      print('⚠️ error checking completed session: $e');
      return false;
    }
  }
}

class DummyAsyncStorage extends GotrueAsyncStorage {
  const DummyAsyncStorage();

  @override
  Future<String?> getItem({required String key}) async => null;

  @override
  Future<void> removeItem({required String key}) async {}

  @override
  Future<void> setItem({required String key, required String value}) async {}
}
