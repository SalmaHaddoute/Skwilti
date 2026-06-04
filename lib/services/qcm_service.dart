import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:supabase_flutter/supabase_flutter.dart';
import '../models/question.dart';

/// Service dédié à la génération de QCM par prompt
/// Communique avec le webhook n8n pour générer des QCM via IA
class QcmService {
  /// Génère un QCM à partir d'un prompt textuel
  /// 
  /// Paramètres:
  /// - [prompt]: Description du sujet du QCM
  /// - [classroomId]: ID de la classe (optionnel)
  /// - [nombreQuestions]: Nombre de questions à générer (défaut: 10)
  /// - [difficulte]: Niveau de difficulté ('facile', 'moyen', 'difficile')
  /// - [langue]: Langue du QCM (défaut: 'Français')
  /// - [matiere]: Matière/sujet (optionnel)
  /// - [webhookUrl]: URL du webhook n8n
  /// 
  /// Retourne un Map contenant:
  /// - success: bool
  /// - course_id: String (ID du cours créé)
  /// - questions: List (questions générées)
  /// - resume: String (résumé du contenu)
  /// - mots_cles: List<String> (mots-clés)
  Future<Map<String, dynamic>> generateQcmByPrompt({
    required String prompt,
    required String webhookUrl,
    String? classroomId,
    int nombreQuestions = 10,
    String difficulte = 'moyen',
    String langue = 'Français',
    String? matiere,
    String? teacherId,
  }) async {
    try {
      // Validation du prompt
      if (prompt.trim().isEmpty) {
        throw Exception('Le prompt ne peut pas être vide');
      }

      // Validation du nombre de questions
      if (nombreQuestions < 1 || nombreQuestions > 50) {
        throw Exception('Le nombre de questions doit être entre 1 et 50');
      }

      // Validation de la difficulté
      final difficultesValides = ['facile', 'moyen', 'difficile'];
      if (!difficultesValides.contains(difficulte.toLowerCase())) {
        throw Exception('Difficulté invalide. Valeurs acceptées: facile, moyen, difficile');
      }

      print('🔵 [QcmService] Génération QCM par prompt...');
      print('   Prompt: ${prompt.substring(0, prompt.length > 50 ? 50 : prompt.length)}...');
      print('   Nombre de questions: $nombreQuestions');
      print('   Difficulté: $difficulte');
      print('   Langue: $langue');
      print('   Matière: ${matiere ?? 'Non spécifiée'}');
      print('   classroom_id envoyé: $classroomId');
      print('   teacher_id envoyé: $teacherId');

      // Préparation des données
      final requestBody = {
        'prompt': prompt.trim(),
        'matiere': matiere ?? '',
        'classroom_id': classroomId?.isNotEmpty == true ? classroomId : null,
        'teacher_id': teacherId?.isNotEmpty == true ? teacherId : null,
        'nombre_questions': nombreQuestions,
        'difficulte': difficulte.toLowerCase(),
        'langue': langue,
        'mode': 'prompt', // Indique au webhook qu'il s'agit d'une génération par prompt
      };

      print('🔵 [QcmService] Envoi de la requête au webhook...');
      print('   URL: $webhookUrl');
      print('   Body: ${jsonEncode(requestBody)}');

      // Envoi de la requête HTTP POST
      final response = await http.post(
        Uri.parse(webhookUrl),
        headers: {
          'Content-Type': 'application/json',
          'Accept': 'application/json',
        },
        body: jsonEncode(requestBody),
      ).timeout(
        const Duration(seconds: 120), // Timeout de 2 minutes
        onTimeout: () {
          throw Exception('Délai d\'attente dépassé. Le serveur n8n ne répond pas.');
        },
      );

      print('🔵 [QcmService] Réponse reçue');
      print('   Status code: ${response.statusCode}');
      print('   Body: ${response.body}');

      // Vérification du code de statut
      if (response.statusCode == 200 || response.statusCode == 201) {
        // Décoder la réponse (peut être List ou Map)
        final dynamic decodedResponse = jsonDecode(response.body);
        
        print('🔍 [QcmService] Type de réponse: ${decodedResponse.runtimeType}');
        
        // Si la réponse est une List (questions directes), la wrapper dans un Map
        final Map<String, dynamic> result;
        if (decodedResponse is List) {
          print('🔍 [QcmService] Réponse est une Liste de ${decodedResponse.length} questions');
          result = {
            'questions': decodedResponse,
            'questions_count': decodedResponse.length,
            'course_id': null,
            'classroom_id': null,
          };
        } else if (decodedResponse is Map) {
          print('🔍 [QcmService] Réponse est un Map');
          result = Map<String, dynamic>.from(decodedResponse);
        } else {
          throw Exception('Type de réponse inattendu: ${decodedResponse.runtimeType}');
        }
        
        print('🟢 [QcmService] QCM généré avec succès!');
        print('   Course ID: ${result['course_id']}');
        print('   Questions count: ${result['questions_count'] ?? result['questions']?.length ?? 0}');
        
        return {
          'success': true,
          ...result,
        };
      } else {
        print('🔴 [QcmService] Erreur serveur: ${response.statusCode}');
        throw Exception('Erreur serveur (${response.statusCode}): ${response.body}');
      }
    } catch (e) {
      print('🔴 [QcmService] Erreur lors de la génération: $e');
      
      // Gestion des erreurs spécifiques
      if (e.toString().contains('SocketException')) {
        throw Exception('Impossible de contacter le serveur. Vérifiez votre connexion internet.');
      } else if (e.toString().contains('TimeoutException')) {
        throw Exception('Le serveur met trop de temps à répondre. Réessayez plus tard.');
      } else if (e.toString().contains('FormatException')) {
        throw Exception('Réponse invalide du serveur. Contactez l\'administrateur.');
      }
      
      rethrow;
    }
  }

  /// Génère un QCM à partir d'un cours existant
  /// 
  /// Paramètres:
  /// - [courseId]: ID du cours existant
  /// - [nombreQuestions]: Nombre de questions à générer
  /// - [difficulte]: Niveau de difficulté
  /// - [langue]: Langue du QCM
  /// - [webhookUrl]: URL du webhook n8n
  Future<Map<String, dynamic>> generateQcmFromCourse({
    required String courseId,
    required String webhookUrl,
    int nombreQuestions = 10,
    String difficulte = 'moyen',
    String langue = 'Français',
  }) async {
    try {
      print('🔵 [QcmService] Génération QCM depuis cours existant...');
      print('   Course ID: $courseId');
      print('   Nombre de questions: $nombreQuestions');

      final requestBody = {
        'course_id': courseId,
        'nombre_questions': nombreQuestions,
        'difficulte': difficulte.toLowerCase(),
        'langue': langue,
        'mode': 'course', // Indique qu'il s'agit d'un cours existant
      };

      final response = await http.post(
        Uri.parse(webhookUrl),
        headers: {
          'Content-Type': 'application/json',
          'Accept': 'application/json',
        },
        body: jsonEncode(requestBody),
      ).timeout(const Duration(seconds: 120));

      if (response.statusCode == 200 || response.statusCode == 201) {
        final Map<String, dynamic> result = jsonDecode(response.body);
        
        print('🟢 [QcmService] QCM généré avec succès depuis le cours!');
        
        return {
          'success': true,
          ...result,
        };
      } else {
        throw Exception('Erreur serveur (${response.statusCode}): ${response.body}');
      }
    } catch (e) {
      print('🔴 [QcmService] Erreur: $e');
      rethrow;
    }
  }

  /// Valide un prompt avant l'envoi
  /// Retourne true si le prompt est valide, false sinon
  bool validatePrompt(String prompt) {
    final trimmed = prompt.trim();
    
    // Vérifier la longueur minimale
    if (trimmed.length < 10) {
      return false;
    }
    
    // Vérifier la longueur maximale
    if (trimmed.length > 2000) {
      return false;
    }
    
    // Vérifier qu'il contient au moins quelques mots
    final words = trimmed.split(RegExp(r'\s+'));
    if (words.length < 3) {
      return false;
    }
    
    return true;
  }

  /// Retourne des suggestions de prompts selon la matière
  List<String> getSuggestedPrompts(String? matiere) {
    final Map<String, List<String>> promptsBySubject = {
      'Mathématiques': [
        'Génère un QCM sur les équations du second degré avec le discriminant et les formules.',
        'Crée un QCM sur les fonctions affines et linéaires pour des élèves de 3ème.',
        'Génère des questions sur les théorèmes de Pythagore et Thalès.',
      ],
      'SVT': [
        'Génère un QCM sur la photosynthèse avec les réactifs, produits et le rôle de la chlorophylle.',
        'Crée un QCM sur le système digestif humain et ses organes.',
        'Génère des questions sur la mitose et la division cellulaire.',
      ],
      'Histoire': [
        'Crée un QCM sur la Révolution française de 1789 avec les causes et conséquences.',
        'Génère un QCM sur la Seconde Guerre mondiale et ses événements majeurs.',
        'Crée des questions sur la Renaissance et ses grands personnages.',
      ],
      'Français': [
        'Génère un QCM sur les figures de style (métaphore, comparaison, personnification).',
        'Crée un QCM sur la conjugaison des verbes du 3ème groupe au passé simple.',
        'Génère des questions sur l\'analyse de texte littéraire.',
      ],
      'Physique': [
        'Génère un QCM sur les lois de Newton et le mouvement.',
        'Crée un QCM sur l\'électricité : tension, intensité et résistance.',
        'Génère des questions sur l\'énergie cinétique et potentielle.',
      ],
      'Chimie': [
        'Génère un QCM sur les atomes, molécules et ions.',
        'Crée un QCM sur les réactions chimiques et les équations.',
        'Génère des questions sur le tableau périodique des éléments.',
      ],
    };

    // Retourner les prompts de la matière ou des prompts génériques
    if (matiere != null && promptsBySubject.containsKey(matiere)) {
      return promptsBySubject[matiere]!;
    }

    // Prompts génériques
    return [
      'Génère un QCM sur [votre sujet] pour des élèves de [niveau].',
      'Crée un QCM avec des questions sur [thème principal] incluant [sous-thèmes].',
      'Génère des questions de difficulté progressive sur [sujet].',
    ];
  }

  /// Sauvegarde les questions générées par prompt dans Supabase
  /// Crée un nouveau cours et associe les questions à ce cours
  /// 
  /// Paramètres:
  /// - [questions]: Liste des questions à sauvegarder
  /// - [title]: Titre du cours/QCM
  /// - [teacherId]: ID du professeur (requis)
  /// - [classroomId]: ID de la classe (optionnel)
  /// - [matiere]: Matière/sujet du QCM (optionnel)
  /// - [summary]: Résumé du contenu (optionnel)
  /// - [keywords]: Mots-clés (optionnel)
  /// 
  /// Retourne l'ID du cours créé
  Future<String?> saveGeneratedQcm({
    required List<Question> questions,
    required String title,
    required String teacherId,
    String? classroomId,
    String? matiere,
    String? summary,
    List<String>? keywords,
  }) async {
    try {
      final supabase = Supabase.instance.client;
      
      print('🔵 [QcmService] Sauvegarde du QCM généré par prompt...');
      print('   Titre: $title');
      print('   Nombre de questions: ${questions.length}');
      print('   Teacher ID: $teacherId');
      print('   Classroom ID: $classroomId');
      
      // 1. Créer le cours dans Supabase
      final courseResponse = await supabase
        .from('courses')
        .insert({
          'title': title,
          'description': summary ?? 'QCM généré par IA via prompt',
          'teacher_id': teacherId,
          'file_name': 'qcm_prompt_${DateTime.now().millisecondsSinceEpoch}.json',
          'subject': matiere ?? 'Général',
          'question_count': questions.length,
          'created_at': DateTime.now().toIso8601String(),
        })
        .select()
        .single();

      final courseId = courseResponse['id'] as String;
      print('🟢 [QcmService] Cours créé avec ID: $courseId');

      // 2. Préparer les données des questions
      final List<Map<String, dynamic>> questionsData = questions.map((q) => {
        'course_id': courseId,
        'text': q.question,
        'options': q.options,
        'correct_answer': q.correctIndex,
        'explication': q.explication,
        'difficulty': 'medium',
        'points': 10,
        'created_at': DateTime.now().toIso8601String(),
      }).toList();

      // 3. Insérer les questions dans Supabase
      await supabase.from('questions').insert(questionsData);
      print('🟢 [QcmService] ${questions.length} questions sauvegardées');

      // 4. Si un classroomId est fourni, associer le cours à la classe
      if (classroomId != null && classroomId.isNotEmpty) {
        try {
          await supabase.from('classroom_courses').insert({
            'classroom_id': classroomId,
            'course_id': courseId,
            'created_at': DateTime.now().toIso8601String(),
          });
          print('🟢 [QcmService] Cours associé à la classe $classroomId');
        } catch (e) {
          print('⚠️ [QcmService] Erreur lors de l\'association à la classe: $e');
          // Ne pas bloquer si l'association échoue
        }
      }

      // 5. Optionnel: Sauvegarder les mots-clés et le résumé
      if (keywords != null && keywords.isNotEmpty || summary != null) {
        try {
          await supabase
            .from('courses')
            .update({
              if (summary != null) 'summary': summary,
              if (keywords != null && keywords.isNotEmpty) 
                'keywords': keywords,
            })
            .eq('id', courseId);
          print('🟢 [QcmService] Métadonnées sauvegardées (résumé et mots-clés)');
        } catch (e) {
          print('⚠️ [QcmService] Erreur lors de la sauvegarde des métadonnées: $e');
        }
      }

      print('🎉 [QcmService] QCM sauvegardé avec succès!');
      return courseId;
    } catch (e) {
      print('🔴 [QcmService] Erreur lors de la sauvegarde: $e');
      rethrow;
    }
  }
}
