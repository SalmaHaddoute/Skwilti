import 'dart:convert';
import 'dart:io';
import 'package:dio/dio.dart';

class N8nService {
  final Dio _dio = Dio(BaseOptions(
    connectTimeout: const Duration(seconds: 30),
    receiveTimeout: const Duration(seconds: 120),
  ));

  Future<Map<String, dynamic>> generateQcm({
    required File file,
    required int nbQuestions,
    required String difficulty,
    required String language,
    required String webhookUrl, // URL dynamique depuis AppState
    Function(double)? onProgress,
  }) async {
    try {
      final formData = FormData.fromMap({
        'file': await MultipartFile.fromFile(
          file.path,
          filename: file.path.split(Platform.pathSeparator).last,
        ),
        'nb_questions': nbQuestions.toString(),
        'difficulty': difficulty,
        'language': language,
      });

      final response = await _dio.post(
        webhookUrl,
        data: formData,
        onSendProgress: (sent, total) {
          if (total > 0 && onProgress != null) {
            onProgress(sent / total);
          }
        },
      );

      if (response.statusCode == 200) {
        Map<String, dynamic> data;
        if (response.data is Map<String, dynamic>) {
          data = response.data as Map<String, dynamic>;
        } else if (response.data is String) {
          data = jsonDecode(response.data as String) as Map<String, dynamic>;
        } else {
          throw Exception('Réponse n8n invalide: ${response.data}');
        }
        return data;
      }
      throw Exception('Erreur serveur: ${response.statusCode}');
    } on DioException catch (e) {
      throw _handleError(e);
    }
  }

  Exception _handleError(DioException e) {
    switch (e.type) {
      case DioExceptionType.connectionTimeout:
      case DioExceptionType.receiveTimeout:
        return Exception('Délai dépassé. Vérifiez votre connexion.');
      case DioExceptionType.connectionError:
        return Exception('Impossible de se connecter. Vérifiez l\'URL n8n.');
      default:
        return Exception('Erreur réseau: ${e.message}');
    }
  }
}

// ── Données mockées pour démo sans n8n ──────────────────────
class MockN8nService {
  static Future<Map<String, dynamic>> generateMockQcm() async {
    await Future.delayed(const Duration(seconds: 3));
    return {
      'resume':
          'La biologie cellulaire étudie la structure et les fonctions des cellules, '
              'unités fondamentales du vivant. Les cellules eucaryotes possèdent un noyau '
              'délimité par une enveloppe nucléaire.',
      'mots_cles': ['Mitochondrie', 'ADN', 'Membrane', 'Ribosomes', 'Mitose'],
      'questions': [
        {
          'id': '1',
          'question':
              'Quelle est la fonction principale de la mitochondrie dans la cellule eucaryote ?',
          'options': [
            'Synthèse des protéines',
            'Production d\'ATP (énergie)',
            'Digestion cellulaire',
            'Stockage de l\'ADN',
          ],
          'correct': 1,
          'explication':
              'La mitochondrie est le siège de la respiration cellulaire. Elle produit l\'ATP, '
                  'la principale molécule énergétique de la cellule, via la chaîne respiratoire.',
        },
        {
          'id': '2',
          'question': 'Combien de phases comporte la mitose ?',
          'options': ['3 phases', '4 phases', '5 phases', '2 phases'],
          'correct': 1,
          'explication':
              'La mitose comprend 4 phases : prophase, métaphase, anaphase et télophase. '
                  'Elle permet la division cellulaire en deux cellules filles identiques.',
        },
        {
          'id': '3',
          'question':
              'Le réticulum endoplasmique rugueux est caractérisé par la présence de :',
          'options': [
            'Ribosomes',
            'Mitochondries',
            'Lysosomes',
            'Vacuoles',
          ],
          'correct': 0,
          'explication':
              'Le réticulum endoplasmique rugueux (RER) est hérissé de ribosomes fixés '
                  'sur sa membrane, ce qui lui donne son aspect rugueux et lui permet '
                  'la synthèse et le transport des protéines.',
        },
        {
          'id': '4',
          'question':
              'Quelle structure cellulaire est responsable de la synthèse des protéines ?',
          'options': [
            'Mitochondrie',
            'Noyau cellulaire',
            'Ribosome',
            'Appareil de Golgi',
          ],
          'correct': 2,
          'explication':
              'Les ribosomes sont les usines à protéines de la cellule. Ils traduisent '
                  'le message génétique (ARNm) en séquences d\'acides aminés.',
        },
        {
          'id': '5',
          'question':
              'L\'ADN se trouve principalement dans quelle structure cellulaire ?',
          'options': [
            'Cytoplasme',
            'Membrane plasmique',
            'Noyau',
            'Appareil de Golgi',
          ],
          'correct': 2,
          'explication':
              'L\'ADN est principalement localisé dans le noyau cellulaire, protégé '
                  'par l\'enveloppe nucléaire. Il contient toute l\'information génétique.',
        },
      ],
    };
  }
}
