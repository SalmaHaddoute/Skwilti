import 'dart:io';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'dart:async';
import 'package:file_picker/file_picker.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:flutter/foundation.dart';
import '../models/question.dart';

class WebhookService {
  static final WebhookService _instance = WebhookService._internal();
  factory WebhookService() => _instance;
  WebhookService._internal();

  String? _customWebhookUrl;

  void setCustomUrl(String url) {
    _customWebhookUrl = url;
  }

  Future<String> getWebhookUrl() async {
    if (_customWebhookUrl != null && _customWebhookUrl!.isNotEmpty) {
      return _customWebhookUrl!;
    }

    if (kIsWeb) {
      return 'http://localhost:5678/webhook/pdf-upload';
    }

    if (Platform.isAndroid) {
      // Android emulator address for host machine
      return 'http://10.0.2.2:5678/webhook/pdf-upload';
    } else {
      return 'http://localhost:5678/webhook/pdf-upload';
    }
  }

  Future<Map<String, dynamic>?> processPdfUpload({
    required String title,
    required String teacherId,
    String? filiereId,
    String? niveauId,
    String? matiereId,
    String? semestre,
    String? classroomId,
    int nombreQuestions = 10,
    String difficulte = 'moyen',
    String langue = 'Français',
    File? existingFile,
    String? existingCourseId,
    String? prompt, // Nouveau: génération par prompt
  }) async {
    try {
      final supabase = Supabase.instance.client;
      debugPrint('🔵 WebhookService: Démarrage pour "$title"');
      
      String courseId;
      String? documentId;
      String? fileUrl;

      if (existingCourseId != null && existingCourseId.isNotEmpty && existingFile == null) {
        // Reuse existing course, no file upload needed
        courseId = existingCourseId;
        debugPrint('🔵 WebhookService: Utilisation du cours existant $courseId sans nouvel upload');
        
        final existingDoc = await supabase
            .from('documents')
            .select('id, file_url')
            .eq('course_id', courseId)
            .order('created_at', ascending: false)
            .limit(1)
            .maybeSingle();

        if (existingDoc == null) {
          throw Exception('Ce cours a été créé sans fichier PDF réel sur le serveur (simulation). Veuillez ré-uploader ce cours avec la nouvelle version de l\'application.');
        }

        documentId = existingDoc['id']?.toString();
        fileUrl = existingDoc['file_url']?.toString();
        
        debugPrint('🟢 WebhookService: Document existant trouvé. URL: $fileUrl');
      } else {
        // Original logic for new upload
        File? file = existingFile;
        String? fileName;

        if (file == null) {
          debugPrint('🔵 WebhookService: Sélection d\'un fichier...');
          final result = await FilePicker.pickFiles(
            type: FileType.custom,
            allowedExtensions: ['pdf'],
          );
          if (result == null) {
            debugPrint('🟡 WebhookService: Aucun fichier sélectionné');
            return null;
          }
          file = File(result.files.single.path!);
          fileName = result.files.single.name;
        } else {
          fileName = file.path.split(Platform.pathSeparator).last;
          debugPrint('🔵 WebhookService: Utilisation du fichier existant: $fileName');
        }

        if (existingCourseId != null && existingCourseId.isNotEmpty) {
          courseId = existingCourseId;
          debugPrint('🔵 WebhookService: Utilisation du cours existant $courseId');
          await supabase
            .from('courses')
            .update({'file_name': fileName ?? 'Document_QCM.pdf'})
            .eq('id', courseId);
        } else {
          // 1. Create course in Supabase
          debugPrint('🔵 WebhookService: Création de l\'entrée dans "courses" (teacherId: $teacherId)...');
          final coursResponse = await supabase
            .from('courses')
            .insert({
              'title': title,
              'description': 'QCM généré avec $nombreQuestions questions ($difficulte)',
              'teacher_id': teacherId,
              'file_name': fileName ?? 'Document_QCM.pdf',
              'subject': 'Général',
              'filiere_id': filiereId,
              'niveau_id': niveauId,
              'matiere_id': matiereId,
              'semestre': 1,
              'created_at': DateTime.now().toIso8601String(),
            })
            .select()
            .single();

          courseId = coursResponse['id'];
          debugPrint('🟢 WebhookService: Cours créé avec ID: $courseId');
        }

        // 2. Upload to Storage
        debugPrint('🔵 WebhookService: Upload vers Storage (bucket "courses")...');
        final timestamp = DateTime.now().millisecondsSinceEpoch;
        final storagePath = 'uploads/${timestamp}_$fileName';
        
        await supabase.storage
          .from('courses')
          .upload(storagePath, file);

        fileUrl = supabase.storage
          .from('courses')
          .getPublicUrl(storagePath);
        
        debugPrint('🟢 WebhookService: Fichier uploadé. URL: $fileUrl');

        // 3. Create document entry
        debugPrint('🔵 WebhookService: Création de l\'entrée dans "documents"...');
        final docResponse = await supabase
          .from('documents')
          .insert({
            'user_id': teacherId,
            'file_url': fileUrl,
            'course_id': courseId,
            'status': 'pending',
            'created_at': DateTime.now().toIso8601String(),
          })
          .select()
          .single();

        documentId = docResponse['id'];
        debugPrint('🟢 WebhookService: Document créé avec ID: $documentId');
      }

      // 4. Call n8n Webhook
      final webhookUrl = await getWebhookUrl();
      debugPrint('🔵 WebhookService: Appel du webhook n8n: $webhookUrl');
      
      // Préparer le body
      final requestBody = {
        'file_url': fileUrl,
        'document_id': documentId,
        'course_id': courseId,
        'classroom_id': classroomId?.isNotEmpty == true ? classroomId : null,
        'teacher_id': teacherId,
        'nombre_questions': nombreQuestions,
        'difficulte': difficulte,
        'langue': langue,
        if (prompt != null && prompt.isNotEmpty) 'prompt': prompt,
        if (prompt != null && prompt.isNotEmpty) 'mode': 'prompt',
      };
      
      debugPrint('🔵 WebhookService: Body envoyé:');
      debugPrint('  - file_url: $fileUrl');
      debugPrint('  - document_id: $documentId');
      debugPrint('  - course_id: $courseId');
      debugPrint('  - classroom_id: $classroomId');
      debugPrint('  - teacher_id: $teacherId');
      debugPrint('  - nombre_questions: $nombreQuestions');
      debugPrint('  - difficulte: $difficulte');
      debugPrint('  - langue: $langue');
      if (prompt != null && prompt.isNotEmpty) {
        debugPrint('  - prompt: ${prompt.substring(0, prompt.length > 50 ? 50 : prompt.length)}...');
        debugPrint('  - mode: prompt');
      }
      
      try {
        final response = await http.post(
          Uri.parse(webhookUrl),
          headers: {'Content-Type': 'application/json'},
          body: jsonEncode(requestBody),
        ).timeout(const Duration(seconds: 120));

        debugPrint('🟢 WebhookService: Réponse n8n reçue (Status: ${response.statusCode})');

        if (response.statusCode == 200 || response.statusCode == 201 || response.statusCode == 204) {
          dynamic data = {};
          if (response.body.isNotEmpty) {
            try {
              data = jsonDecode(response.body);
            } catch (e) {
              debugPrint('⚠️ WebhookService: Le corps de la réponse n\'est pas un JSON valide: ${response.body}');
            }
          }
          return {
            'course_id': courseId,
            'document_id': documentId,
            'success': true,
            'response': data,
          };
        } else {
          debugPrint('🔴 WebhookService: Erreur n8n (${response.statusCode}): ${response.body}');
          return {
            'course_id': courseId,
            'document_id': documentId,
            'success': false,
            'error': 'Server returned ${response.statusCode}: ${response.body}',
          };
        }
      } catch (e) {
        debugPrint('🔴 WebhookService: Erreur lors de l\'appel HTTP: $e');
        return {
          'course_id': courseId,
          'document_id': documentId,
          'success': false,
          'error': e.toString(),
        };
      }
    } catch (e) {
      debugPrint('❌ WebhookService Fatal Error: $e');
      return {
        'success': false,
        'error': e.toString(),
      };
    }
  }

  Future<void> saveQuestions({
    required String courseId,
    required List<Question> questions,
  }) async {
    try {
      final supabase = Supabase.instance.client;
      
      final List<Map<String, dynamic>> questionsData = questions.map((q) => {
        'course_id': courseId,
        'text': q.question,
        'options': q.options,
        'correct_answer': q.correctIndex,
        'explication': q.explication,
        'difficulty': 'medium', // Default
        'points': 10, // Default
      }).toList().cast<Map<String, dynamic>>();

      await supabase.from('questions').delete().eq('course_id', courseId);
      await supabase.from('questions').insert(questionsData);

      // Update question count in courses table
      await supabase
          .from('courses')
          .update({'question_count': questions.length})
          .eq('id', courseId);
    } catch (e) {
      debugPrint('Error saving questions: $e');
      rethrow;
    }
  }

  Stream<List<Map<String, dynamic>>> pollDocumentStatus(String documentId) {
    return Supabase.instance.client
        .from('documents')
        .stream(primaryKey: ['id'])
        .eq('id', documentId);
  }

  Future<List<Question>> fetchQuestionsForCourse(String courseId) async {
    try {
      debugPrint('🔵 WebhookService: Récupération des questions pour le cours $courseId...');
      final response = await Supabase.instance.client
          .from('questions')
          .select()
          .eq('course_id', courseId);
      
      final List<dynamic> data = response as List<dynamic>;
      debugPrint('🟢 WebhookService: ${data.length} questions trouvées.');
      
      return data.map((q) => Question.fromJson(q as Map<String, dynamic>)).toList();
    } catch (e) {
      debugPrint('🔴 WebhookService Erreur lors de la récupération des questions: $e');
      return [];
    }
  }

  /// Récupère les N dernières questions créées (pour les QCM générés par prompt)
  /// Utilisé quand course_id est null
  Future<List<Question>> fetchRecentQuestions(int count) async {
    try {
      debugPrint('🔵 WebhookService: Récupération des $count dernières questions créées...');
      final response = await Supabase.instance.client
          .from('questions')
          .select()
          .order('created_at', ascending: false)
          .limit(count);
      
      final List<dynamic> data = response as List<dynamic>;
      debugPrint('🟢 WebhookService: ${data.length} questions récupérées.');
      
      return data.map((q) => Question.fromJson(q as Map<String, dynamic>)).toList();
    } catch (e) {
      debugPrint('🔴 WebhookService Erreur lors de la récupération des questions récentes: $e');
      return [];
    }
  }
}