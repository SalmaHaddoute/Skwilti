import 'dart:io';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'dart:async';
import 'package:file_picker/file_picker.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class WebhookTestService {
  static Future<Map<String, dynamic>?> testerWebhook({
    // Paramètres du cours
    required String title,
    required String teacherId,
    String? filiereId,
    String? niveauId,
    String? matiereId,
    String? semestre,
    
    // Paramètres du webhook
    int nombreQuestions = 10,
    String difficulte = 'moyen',
    String langue = 'Français',
    String? webhookUrl,
  }) async {
    try {
      final supabase = Supabase.instance.client;
      
      // 1. Choisir un PDF
      final result = await FilePicker.pickFiles(
        type: FileType.custom,
        allowedExtensions: ['pdf'],
      );
      if (result == null) {
        print('❌ Aucun fichier sélectionné');
        return null;
      }

      final file = File(result.files.single.path!);
      final fileName = result.files.single.name;

      print('📄 Fichier sélectionné: $fileName');

      // 2. Créer le cours DANS Supabase AVANT le webhook
      final coursResponse = await supabase
        .from('courses')
        .insert({
          'title': title,
          'teacher_id': teacherId,
          'filiere_id': filiereId,
          'niveau_id': niveauId,
          'matiere_id': matiereId,
          'semestre': semestre,
          'created_at': DateTime.now().toIso8601String(),
        })
        .select()
        .single();

      final courseId = coursResponse['id'];
      print('📚 Cours créé avec ID: $courseId');

      // 3. Upload vers Supabase Storage
      final storagePath = 'courses/$fileName';
      
      await supabase.storage
        .from('courses')
        .upload(storagePath, file);

      final fileUrl = supabase.storage
        .from('courses')
        .getPublicUrl(storagePath);

      print('📤 Fichier uploadé: $fileUrl');

      // 4. Créer le document dans Supabase
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
      print('📋 Document créé avec ID: $documentId');

      // 5. Appeler le webhook n8n
      String finalWebhookUrl = webhookUrl ?? await _getWebhookUrl();
      
      print('🌐 Appel du webhook AVANT modification: $finalWebhookUrl');
      print('📱 Plateforme: ${Platform.operatingSystem}');
      print('🤖 Est Android: ${Platform.isAndroid}');
      
      // Forcer l'URL pour Android émulateur
      if (Platform.isAndroid) {
        finalWebhookUrl = 'http://10.0.2.2:5678/webhook-test/pdf-upload';
        print('🔧 URL forcée pour Android émulateur: $finalWebhookUrl');
      }
      
      print('🌐 URL finale utilisée: $finalWebhookUrl');
      print('📡 Envoi vers n8n...');

      try {
        print('🌐 Tentative de connexion à: $finalWebhookUrl');
        
        final response = await http.post(
          Uri.parse(finalWebhookUrl),
          headers: {'Content-Type': 'application/json'},
          body: jsonEncode({
            'file_url': fileUrl,
            'document_id': documentId,
            'course_id': courseId,
            'nombre_questions': nombreQuestions,
            'difficulte': difficulte,
            'langue': langue,
          }),
        ).timeout(const Duration(seconds: 10));

        // 6. Voir la réponse
        print('📊 Status: ${response.statusCode}');
        print('📄 Body: ${response.body}');
        print('📋 Headers: ${response.headers}');

        if (response.statusCode == 200) {
          final data = jsonDecode(response.body);
          print('✅ QCM générés : ${data['questions_count']}');
          print('✅ Course ID   : ${data['course_id']}');
          
          return {
            'course_id': courseId,
            'document_id': documentId,
            'success': true,
            'response': data,
          };
        } else {
          print('❌ Erreur HTTP ${response.statusCode} : ${response.body}');
          return {
            'course_id': courseId,
            'document_id': documentId,
            'success': false,
            'error': 'HTTP ${response.statusCode}: ${response.body}',
          };
        }
      } on SocketException catch (e) {
        print('💥 Erreur réseau/Socket: $e');
        print('🔍 Vérifie que n8n écoute sur le port 5678');
        return {
          'course_id': courseId,
          'document_id': documentId,
          'success': false,
          'error': 'SocketException: $e',
        };
      } on TimeoutException catch (e) {
        print('💥 Timeout: $e');
        return {
          'course_id': courseId,
          'document_id': documentId,
          'success': false,
          'error': 'Timeout: $e',
        };
      } catch (e) {
        print('💥 Exception générale: $e');
        return null;
      }
    } catch (e) {
      print('💥 Exception lors de la création du document: $e');
      return null;
    }
  }

  static Stream<List<Map<String, dynamic>>>? pollDocumentStatus(String documentId) {
    try {
      final supabase = Supabase.instance.client;
      return supabase
        .from('documents')
        .stream(primaryKey: ['id'])
        .eq('id', documentId);
    } catch (e) {
      print('💥 Erreur polling: $e');
      return null;
    }
  }

  static Future<String> _getWebhookUrl() async {
    if (Platform.isAndroid) {
      // Pour émulateur Android, utiliser 10.0.2.2 (adresse spéciale pour accéder au PC)
      return 'http://10.0.2.2:5678/webhook-test/pdf-upload';
    } else if (Platform.isIOS) {
      return 'http://localhost:5678/webhook-test/pdf-upload';
    } else {
      return 'http://localhost:5678/webhook-test/pdf-upload';
    }
  }

  static Future<String?> _getLocalIpAddress() async {
    try {
      for (var interface in await NetworkInterface.list()) {
        for (var addr in interface.addresses) {
          if (addr.type == InternetAddressType.IPv4 && !addr.isLoopback) {
            if (addr.address.startsWith('192.168.') || 
                addr.address.startsWith('10.') || 
                addr.address.startsWith('172.')) {
              return addr.address;
            }
          }
        }
      }
    } catch (e) {
      print('Erreur lors de la récupération de l\'IP locale: $e');
    }
    return null;
  }
}
