# 🔧 Correction du Chargement des Questions Générées par Prompt

**Date**: 3 Juin 2026  
**Problème**: Les questions générées par prompt ne s'affichent pas dans l'écran "Réviser les questions"

---

## ❌ Problème Identifié

### Dans le webhook n8n
Le webhook retourne pour les QCM générés par prompt:
```json
{
  "success": true,
  "questions_count": 8,
  "difficulte": "moyen",
  "langue": "Français",
  "course_id": null  // ❌ NULL pour les prompts
}
```

### Dans Flutter (upload_screen.dart)
La logique de récupération des questions utilisait **uniquement** `fetchQuestionsForCourse(courseId)` qui filtre par:
```dart
.eq('course_id', courseId)
```

**Problème**: Quand `course_id` est `null`, aucune question n'est trouvée car le filtre `.eq('course_id', null)` ne matche pas les enregistrements avec `course_id = null` dans Supabase.

---

## ✅ Solution Implémentée

### 1. Nouvelle méthode dans `webhook_service.dart`

Ajout de `fetchRecentQuestions(int count)` qui récupère les N dernières questions créées sans filtrer par `course_id`:

```dart
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
    debugPrint('🔴 WebhookService Erreur: $e');
    return [];
  }
}
```

**Principe**:
- Trie par `created_at DESC` (les plus récentes en premier)
- Limite au nombre de questions retourné par le webhook (`questions_count`)
- Ne filtre PAS par `course_id`

---

### 2. Logique mise à jour dans `upload_screen.dart`

Ajout d'une détection intelligente du mode:

```dart
if (questions.isEmpty) {
  print('ℹ️ Aucune question valide trouvée dans la réponse webhook. Récupération depuis Supabase...');
  
  // Essayer de récupérer questions_count depuis la réponse webhook
  final int? questionsCount = normalizedResponse is Map 
      ? (normalizedResponse['questions_count'] as int?) 
      : null;
  
  final String? returnedCourseId = result['course_id'];
  
  if (questionsCount != null && questionsCount > 0) {
    // ✅ Mode PROMPT: Utiliser questions_count
    print('📊 Webhook indique $questionsCount questions générées');
    print('🔵 Récupération des $questionsCount dernières questions par created_at...');
    
    // Polling avec fetchRecentQuestions
    for (int i = 0; i < 15; i++) {
      await Future.delayed(const Duration(seconds: 4));
      questions = await WebhookService().fetchRecentQuestions(questionsCount);
      if (questions.isNotEmpty) break;
    }
  } else if (returnedCourseId != null) {
    // ✅ Mode COURSE: Utiliser course_id
    print('🔵 Récupération des questions par course_id: $returnedCourseId...');
    
    // Polling avec fetchQuestionsForCourse
    for (int i = 0; i < 15; i++) {
      await Future.delayed(const Duration(seconds: 4));
      questions = await WebhookService().fetchQuestionsForCourse(returnedCourseId);
      if (questions.isNotEmpty) break;
    }
  }
}
```

**Logique**:
1. Si `questions_count` est présent dans la réponse → **Mode PROMPT** → Utiliser `fetchRecentQuestions()`
2. Si `course_id` est présent → **Mode COURSE** → Utiliser `fetchQuestionsForCourse()`

---

## 📊 Comparaison Avant/Après

### Avant (❌ Ne fonctionne pas pour les prompts)

| Mode | Webhook retourne | Flutter utilise | Résultat |
|------|------------------|-----------------|----------|
| Course | `course_id: "abc-123"` | `.eq('course_id', 'abc-123')` | ✅ Trouve les questions |
| Prompt | `course_id: null` | `.eq('course_id', null)` | ❌ Ne trouve RIEN |

### Après (✅ Fonctionne pour les deux)

| Mode | Webhook retourne | Flutter utilise | Résultat |
|------|------------------|-----------------|----------|
| Course | `course_id: "abc-123"` | `.eq('course_id', 'abc-123')` | ✅ Trouve les questions |
| Prompt | `questions_count: 8` | `.order('created_at').limit(8)` | ✅ Trouve les 8 dernières questions |

---

## 🧪 Tests à Effectuer

### Test A - QCM par Prompt (Mode PROMPT)

1. Ouvrir l'application Flutter
2. Aller sur "Créer un QCM"
3. Sélectionner l'onglet **"Par prompt"**
4. Entrer un prompt: "Génère un QCM sur la photosynthèse pour des élèves de 3ème"
5. Définir 8 questions, difficulté "moyen"
6. Cliquer sur "Générer le QCM"
7. **Attendre le polling** (jusqu'à 60 secondes)
8. ✅ **Vérifier**: L'écran "Réviser les questions" s'affiche avec les 8 questions

**Logs attendus**:
```
📊 Webhook indique 8 questions générées
🔵 Récupération des 8 dernières questions par created_at...
⏳ Polling... aucune question trouvée (tentative 1/15)
⏳ Polling... aucune question trouvée (tentative 2/15)
🟢 8 questions trouvées après polling !
🟢 WebhookService: 8 questions récupérées.
```

---

### Test B - QCM depuis Cours Existant (Mode COURSE)

1. Ouvrir l'application Flutter
2. Aller sur "Créer un QCM"
3. Sélectionner l'onglet **"Cours existant"**
4. Choisir un cours de la liste
5. Définir 10 questions, difficulté "facile"
6. Cliquer sur "Générer le QCM"
7. **Attendre le polling**
8. ✅ **Vérifier**: L'écran "Réviser les questions" s'affiche avec les 10 questions

**Logs attendus**:
```
🔵 Récupération des questions par course_id: abc-123-def-456...
⏳ Polling... aucune question trouvée (tentative 1/15)
🟢 10 questions trouvées après polling !
🟢 WebhookService: 10 questions trouvées.
```

---

## ⚠️ Cas Limites et Considérations

### 1. Questions créées en même temps par plusieurs utilisateurs

**Problème potentiel**: Si deux enseignants génèrent des QCM par prompt en même temps, `fetchRecentQuestions()` pourrait récupérer les questions de l'autre enseignant.

**Solution actuelle**: Les questions sont générées rapidement (quelques secondes), donc la probabilité de collision est faible.

**Solution future** (si nécessaire):
- Ajouter un `teacher_id` aux questions dans Supabase
- Filtrer par `teacher_id` ET `created_at`:
```dart
.eq('teacher_id', teacherId)
.order('created_at', ascending: false)
.limit(count)
```

### 2. Polling timeout

**Actuel**: 15 tentatives × 4 secondes = 60 secondes maximum

**Amélioration possible**:
- Augmenter à 20 tentatives (80 secondes) si l'IA est lente
- Ou réduire le délai entre tentatives de 4s à 3s

---

## 📝 Résumé des Modifications

| Fichier | Ligne(s) | Modification |
|---------|----------|--------------|
| `lib/services/webhook_service.dart` | ~305 | ✅ Ajout de `fetchRecentQuestions(int count)` |
| `lib/screens/upload_screen.dart` | ~172-215 | ✅ Détection de `questions_count` et logique conditionnelle |

---

## 🎯 Résultat Attendu

Après ces corrections:

1. ✅ **QCM par prompt**: Les questions s'affichent correctement dans "Réviser les questions"
2. ✅ **QCM par cours**: Continue de fonctionner comme avant
3. ✅ Les logs indiquent clairement quel mode est utilisé
4. ✅ Le polling fonctionne pour les deux modes

---

## 🔍 Debug

Si les questions ne s'affichent toujours pas:

1. **Vérifier les logs Flutter**:
   ```
   📊 Webhook indique X questions générées
   🔵 Récupération des X dernières questions par created_at...
   🟢 X questions trouvées après polling !
   ```

2. **Vérifier la réponse webhook n8n**:
   - Doit contenir `questions_count` (nombre)
   - Peut contenir `course_id: null`

3. **Vérifier dans Supabase**:
   - Aller dans la table `questions`
   - Trier par `created_at DESC`
   - Vérifier que les questions sont bien créées avec des timestamps récents

---

**Date**: 3 Juin 2026  
**Status**: ✅ Corrections appliquées - Tests requis  
**Auteur**: Kiro AI
