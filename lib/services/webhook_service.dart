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
      return 'http://localhost:5678/webhook-test/pdf-upload';
    }

    if (Platform.isAndroid) {
      // Android emulator address for host machine
      return 'http://10.0.2.2:5678/webhook-test/pdf-upload';
    } else {
      return 'http://localhost:5678/webhook-test/pdf-upload';
    }
  }

  Future<Map<String, dynamic>?> processPdfUpload({
    required String title,
    required String teacherId,
    String? filiereId,
    String? niveauId,
    String? matiereId,
    String? semestre,
    int nombreQuestions = 10,
    String difficulte = 'moyen',
    String langue = 'Français',
    File? existingFile,
  }) async {
    try {
      final supabase = Supabase.instance.client;
      debugPrint('🔵 WebhookService: Démarrage pour "$title"');
      
      File? file = existingFile;
      String? fileName;

      if (file == null) {
        debugPrint('🔵 WebhookService: Sélection d\'un fichier...');
        final result = await FilePicker.platform.pickFiles(
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

      // 1. Create course in Supabase
      debugPrint('🔵 WebhookService: Création de l\'entrée dans "courses" (teacherId: $teacherId)...');
      final coursResponse = await supabase
        .from('courses')
        .insert({
          'title': title,
          'teacher_id': teacherId,
          'filiere_id': filiereId,
          'niveau_id': niveauId,
          'matiere_id': matiereId,
          'semestre': 1,
          'created_at': DateTime.now().toIso8601String(),
        })
        .select()
        .single();

      final courseId = coursResponse['id'];
      debugPrint('🟢 WebhookService: Cours créé avec ID: $courseId');

      // 2. Upload to Storage
      debugPrint('🔵 WebhookService: Upload vers Storage (bucket "courses")...');
      final timestamp = DateTime.now().millisecondsSinceEpoch;
      final storagePath = 'uploads/${timestamp}_$fileName';
      
      await supabase.storage
        .from('courses')
        .upload(storagePath, file);

      final fileUrl = supabase.storage
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

      final documentId = docResponse['id'];
      debugPrint('🟢 WebhookService: Document créé avec ID: $documentId');

      // 4. Call n8n Webhook
      final webhookUrl = await getWebhookUrl();
      debugPrint('🔵 WebhookService: Appel du webhook n8n: $webhookUrl');
      
      try {
        final response = await http.post(
          Uri.parse(webhookUrl),
          headers: {'Content-Type': 'application/json'},
          body: jsonEncode({
            'file_url': fileUrl,
            'document_id': documentId,
            'course_id': courseId,
            'nombre_questions': nombreQuestions,
            'difficulte': difficulte,
            'langue': langue,
          }),
        ).timeout(const Duration(seconds: 30));

        debugPrint('🟢 WebhookService: Réponse n8n reçue (Status: ${response.statusCode})');

        if (response.statusCode == 200) {
          final data = jsonDecode(response.body);
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
}
