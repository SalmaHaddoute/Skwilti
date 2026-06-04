import 'dart:async';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../models/message.dart';
import '../models/conversation.dart';

class MessagingService {
  final SupabaseClient client = Supabase.instance.client;

  // Realtime channel placeholder (realtime disabled in this build)

  // Stream controller for incoming messages
  final StreamController<MessageModel> _messageController = StreamController.broadcast();
  Stream<MessageModel> get onMessage => _messageController.stream;

  // Listen to messages for a given user (via conversation membership)
  void subscribeToUserMessages(String userId) {
    client.channel('public:messages').onPostgresChanges(
      event: PostgresChangeEvent.insert,
      schema: 'public',
      table: 'messages',
      callback: (payload) {
        final newRecord = payload.newRecord;
        if (newRecord != null && newRecord.isNotEmpty) {
          final newMessage = MessageModel.fromJson(newRecord);
          _messageController.add(newMessage);
        }
      },
    ).subscribe();
  }

  Future<List<Conversation>> fetchConversations(String userId) async {
    try {
      // Use the view that includes unread_count and other metadata
      final res = await client
          .from('v_conversations_for_user')
          .select()
          .eq('user_id', userId)
          .order('updated_at', ascending: false);
      
      final data = res as List<dynamic>;
      return data.map((e) => Conversation.fromJson(e as Map<String, dynamic>)).toList();
    } catch (e) {
      print('[MessagingService] fetchConversations error: $e');
      // Fallback to basic query if view doesn't work
      try {
        final res = await client
            .from('conversation_members')
            .select('conversation_id, unread_count, role, conversations!inner(*)')
            .eq('user_id', userId);
        
        final data = res as List<dynamic>;
        return data.map((e) {
          final convData = (e as Map<String, dynamic>)['conversations'] as Map<String, dynamic>;
          convData['unread_count'] = e['unread_count'];
          convData['member_role'] = e['role'];
          return Conversation.fromJson(convData);
        }).toList();
      } catch (fallbackError) {
        print('[MessagingService] fetchConversations fallback error: $fallbackError');
        rethrow;
      }
    }
  }

  Future<List<MessageModel>> fetchMessages(String conversationId, {int limit = 50}) async {
    final res = await client.from('messages').select().eq('conversation_id', conversationId).order('created_at', ascending: false).limit(limit);
    final data = res as List<dynamic>;
    return data.map((e) => MessageModel.fromJson(e as Map<String, dynamic>)).toList();
  }

  Future<void> sendMessage(String conversationId, String senderId, String content, {Map<String, dynamic>? metadata}) async {
    final payload = {
      'conversation_id': conversationId,
      'sender_id': senderId,
      'content': content,
      'metadata': metadata,
    };
    await client.from('messages').insert(payload);
  }

  Future<String> createConversation({String? name, bool isGroup = false, String? avatarUrl, required List<String> memberIds, required String creatorId}) async {
    try {
      // Ensure created_by is set
      final res = await client.from('conversations').insert({
        'name': name,
        'is_group': isGroup,
        'avatar_url': avatarUrl,
        'created_by': creatorId,
      }).select().single();
      
      final conv = res as Map<String, dynamic>;
      final convId = conv['id'].toString();
      
      // Insert members - ensure creator is included
      final uniqueMemberIds = memberIds.toSet().toList();
      if (!uniqueMemberIds.contains(creatorId)) {
        uniqueMemberIds.add(creatorId);
      }
      
      final members = uniqueMemberIds.map((id) => {
        'conversation_id': convId,
        'user_id': id,
        'role': id == creatorId ? 'creator' : 'member',
      }).toList();
      
      await client.from('conversation_members').insert(members);
      return convId;
    } catch (e) {
      print('[MessagingService] createConversation error: $e');
      rethrow;
    }
  }

  Future<String> getOrCreateDirectConversation(String currentUserId, String otherUserId) async {
    try {
      final myMemberships = await client
          .from('conversation_members')
          .select('conversation_id')
          .eq('user_id', currentUserId);
          
      final List<String> myConvIds = (myMemberships as List)
          .map((m) => m['conversation_id'].toString())
          .toList();
          
      if (myConvIds.isNotEmpty) {
        final commonMemberships = await client
            .from('conversation_members')
            .select('conversation_id, conversation:conversations(is_group)')
            .inFilter('conversation_id', myConvIds)
            .eq('user_id', otherUserId);
            
        for (var membership in (commonMemberships as List)) {
          final conv = membership['conversation'] as Map<String, dynamic>?;
          if (conv != null && conv['is_group'] == false) {
            return membership['conversation_id'].toString();
          }
        }
      }
      
      return await createConversation(
        isGroup: false,
        memberIds: [currentUserId, otherUserId],
        creatorId: currentUserId,
      );
    } catch (e) {
      print('[MessagingService] getOrCreateDirectConversation error: $e');
      rethrow;
    }
  }

  /// CONTACT / DIRECTORY HELPERS
  Future<List<Map<String, dynamic>>> getTeachersForStudent(String studentId) async {
    try {
      final profileRes = await client.from('profiles').select('classe_id').eq('id', studentId).maybeSingle();
      if (profileRes == null || profileRes['classe_id'] == null) return [];
      
      final classeId = profileRes['classe_id'];
      final cpRes = await client.from('classe_professeurs').select('professeur_id').eq('classe_id', classeId);
      final teacherIds = (cpRes as List<dynamic>).map((e) => e['professeur_id']).where((id) => id != null).toSet().toList();
      
      if (teacherIds.isEmpty) return [];
      
      final teachers = await client.from('profiles').select('id, first_name, last_name, avatar_url, role').inFilter('id', teacherIds);
      return List<Map<String, dynamic>>.from(teachers);
    } catch (e) {
      print('[MessagingService] getTeachersForStudent error: $e');
      return [];
    }
  }

  Future<List<Map<String, dynamic>>> getTeachersForParent(String parentId) async {
    try {
      final links = await client.from('parent_enfants').select('enfant_id').eq('parent_id', parentId);
      if ((links as List).isEmpty) return [];
      
      final enfantIds = links.map((l) => l['enfant_id']).where((id) => id != null).toList();
      final profiles = await client.from('profiles').select('classe_id').inFilter('id', enfantIds);
      
      final classeIds = (profiles as List).map((p) => p['classe_id']).where((id) => id != null).toSet().toList();
      if (classeIds.isEmpty) return [];
      
      final cpRes = await client.from('classe_professeurs').select('professeur_id').inFilter('classe_id', classeIds);
      final teacherIds = (cpRes as List).map((e) => e['professeur_id']).where((id) => id != null).toSet().toList();
      
      if (teacherIds.isEmpty) return [];
      final teachers = await client.from('profiles').select('id, first_name, last_name, avatar_url, role').inFilter('id', teacherIds);
      return List<Map<String, dynamic>>.from(teachers);
    } catch(e) {
      print('[MessagingService] getTeachersForParent error: $e');
      return [];
    }
  }

  Future<List<Map<String, dynamic>>> getStudentsForTeacher(String teacherId) async {
    try {
      final cpRes = await client.from('classe_professeurs').select('classe_id').eq('professeur_id', teacherId);
      final classeIds = (cpRes as List<dynamic>).map((e) => e['classe_id']).where((id) => id != null).toSet().toList();
      if (classeIds.isEmpty) return [];
      
      final students = await client.from('profiles').select('id, first_name, last_name, avatar_url, classe_id').eq('role', 'student').inFilter('classe_id', classeIds);
      return List<Map<String, dynamic>>.from(students);
    } catch (e) {
      print('[MessagingService] getStudentsForTeacher error: $e');
      return [];
    }
  }

  Future<List<Map<String, dynamic>>> getParentsForStudents(List<String> studentIds) async {
    if (studentIds.isEmpty) return [];
    try {
      final links = await client.from('parent_enfants').select('parent_id').inFilter('enfant_id', studentIds);
      final parentIds = (links as List).map((l) => l['parent_id']).where((id) => id != null).toSet().toList();
      if (parentIds.isEmpty) return [];
      
      final parents = await client.from('profiles').select('id, first_name, last_name, avatar_url').inFilter('id', parentIds);
      return List<Map<String, dynamic>>.from(parents);
    } catch (e) {
      print('[MessagingService] getParentsForStudents error: $e');
      return [];
    }
  }

  Future<List<Map<String, dynamic>>> getAllOtherTeachers(String excludeId) async {
    try {
      final res = await client.from('profiles').select('id, first_name, last_name, avatar_url').eq('role', 'teacher').neq('id', excludeId);
      return List<Map<String, dynamic>>.from(res);
    } catch (e) {
      print('[MessagingService] getAllOtherTeachers error: $e');
      return [];
    }
  }

  /// Mark conversation as read for the current user
  Future<void> markConversationAsRead(String conversationId, String userId) async {
    try {
      await client.rpc('mark_conversation_read', params: {
        'p_conversation_id': conversationId,
        'p_user_id': userId,
      });
    } catch (e) {
      print('[MessagingService] markConversationAsRead error: $e');
      // Fallback: manually update if RPC fails
      try {
        await client
            .from('conversation_members')
            .update({'unread_count': 0})
            .eq('conversation_id', conversationId)
            .eq('user_id', userId);
      } catch (fallbackError) {
        print('[MessagingService] markConversationAsRead fallback error: $fallbackError');
      }
    }
  }

  /// Get the other user's profile in a direct conversation
  Future<Map<String, dynamic>?> getOtherUserProfile(String conversationId, String currentUserId) async {
    try {
      final members = await client
          .from('conversation_members')
          .select('user_id')
          .eq('conversation_id', conversationId)
          .neq('user_id', currentUserId);
      
      if (members.isEmpty) return null;
      
      final otherUserId = members[0]['user_id'];
      final profile = await client
          .from('profiles')
          .select('id, first_name, last_name, avatar_url, role')
          .eq('id', otherUserId)
          .single();
      
      return profile as Map<String, dynamic>;
    } catch (e) {
      print('[MessagingService] getOtherUserProfile error: $e');
      return null;
    }
  }

  /// Get all students for a teacher with their parent information
  Future<List<Map<String, dynamic>>> getStudentsWithParentsForTeacher(String teacherId) async {
    try {
      print('[MessagingService] getStudentsWithParentsForTeacher - teacherId: $teacherId');
      
      // Step 1: Get teacher's classes
      final cpRes = await client.from('classe_professeurs').select('classe_id').eq('professeur_id', teacherId);
      print('[MessagingService] Teacher classes: $cpRes');
      
      final classeIds = (cpRes as List<dynamic>).map((e) => e['classe_id']).where((id) => id != null).toSet().toList();
      if (classeIds.isEmpty) {
        print('[MessagingService] No classes found for teacher');
        return [];
      }
      
      print('[MessagingService] Class IDs: $classeIds');
      
      // Step 2: Get students in those classes
      final students = await client
          .from('profiles')
          .select('id, first_name, last_name, avatar_url, classe_id')
          .eq('role', 'student')
          .inFilter('classe_id', classeIds);
      
      print('[MessagingService] Students found: ${students.length}');
      final studentsList = List<Map<String, dynamic>>.from(students);
      
      // Step 3: Get parents for each student
      for (var student in studentsList) {
        final studentId = student['id'].toString();
        print('[MessagingService] Getting parents for student: $studentId');
        
        final links = await client.from('parent_enfants').select('parent_id').eq('enfant_id', studentId);
        print('[MessagingService] Parent links for $studentId: $links');
        
        final parentIds = (links as List).map((l) => l['parent_id']).where((id) => id != null).toList();
        
        if (parentIds.isNotEmpty) {
          print('[MessagingService] Parent IDs: $parentIds');
          final parents = await client
              .from('profiles')
              .select('id, first_name, last_name, avatar_url')
              .inFilter('id', parentIds);
          print('[MessagingService] Parents profiles: $parents');
          student['parents'] = parents;
        } else {
          print('[MessagingService] No parents found for student $studentId');
          student['parents'] = [];
        }
      }
      
      return studentsList;
    } catch (e) {
      print('[MessagingService] getStudentsWithParentsForTeacher error: $e');
      return [];
    }
  }

  /// Get all parents directly (alternative method)
  Future<List<Map<String, dynamic>>> getAllParentsForTeacher(String teacherId) async {
    try {
      print('[MessagingService] getAllParentsForTeacher - teacherId: $teacherId');
      
      // Method 1: Get all parents with role 'parent'
      final allParents = await client
          .from('profiles')
          .select('id, first_name, last_name, avatar_url, role')
          .eq('role', 'parent');
      
      print('[MessagingService] All parents found: ${allParents.length}');
      return List<Map<String, dynamic>>.from(allParents);
    } catch (e) {
      print('[MessagingService] getAllParentsForTeacher error: $e');
      return [];
    }
  }

  /// Create a group conversation
  Future<String> createGroupConversation({
    required String groupName,
    required List<String> memberIds,
    required String creatorId,
    String? avatarUrl,
  }) async {
    try {
      return await createConversation(
        name: groupName,
        isGroup: true,
        avatarUrl: avatarUrl,
        memberIds: memberIds,
        creatorId: creatorId,
      );
    } catch (e) {
      print('[MessagingService] createGroupConversation error: $e');
      rethrow;
    }
  }

  void dispose() {
    client.removeAllChannels();
    _messageController.close();
  }
}
