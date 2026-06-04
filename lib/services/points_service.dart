import 'package:supabase_flutter/supabase_flutter.dart';

class PointsService {
  static Future<void> incrementPoints(String userId, int pointsToAdd) async {
    try {
      final supabase = Supabase.instance.client;
      
      await supabase.rpc('increment_points', params: {
        'user_id': userId,
        'points_to_add': pointsToAdd,
      });
      
      print('✅ Points ajoutés: $pointsToAdd pour l\'utilisateur $userId');
    } catch (e) {
      print('💥 Erreur lors de l\'ajout de points: $e');
    }
  }

  static Future<int?> getUserPoints(String userId) async {
    try {
      final supabase = Supabase.instance.client;
      
      final response = await supabase
        .from('profiles')
        .select('points')
        .eq('id', userId)
        .single();
      
      return response['points'] as int?;
    } catch (e) {
      print('💥 Erreur lors de la récupération des points: $e');
      return null;
    }
  }

  static Future<void> addPointsForQuizCompletion(
    String userId, 
    int questionId, 
    bool isCorrect,
  ) async {
    try {
      final supabase = Supabase.instance.client;
      
      // Récupérer les points pour cette question
      final questionResponse = await supabase
        .from('questions')
        .select('points')
        .eq('id', questionId)
        .single();
      
      final points = questionResponse['points'] as int? ?? 1;
      
      if (isCorrect) {
        await incrementPoints(userId, points);
        
        // Enregistrer la session de quiz
        await supabase.from('quiz_sessions').insert({
          'user_id': userId,
          'question_id': questionId,
          'is_correct': true,
          'points_earned': points,
          'created_at': DateTime.now().toIso8601String(),
        });
      } else {
        // Enregistrer la réponse incorrecte sans points
        await supabase.from('quiz_sessions').insert({
          'user_id': userId,
          'question_id': questionId,
          'is_correct': false,
          'points_earned': 0,
          'created_at': DateTime.now().toIso8601String(),
        });
      }
    } catch (e) {
      print('💥 Erreur lors de l\'ajout de points pour le quiz: $e');
    }
  }
}
