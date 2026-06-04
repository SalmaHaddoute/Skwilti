# 🔍 Guide des Logs de Débogage - Questions Prompt

**Date**: 3 Juin 2026  
**Fichier**: `lib/screens/upload_screen.dart`

---

## 📝 Logs Ajoutés

Des logs détaillés ont été ajoutés pour tracer tout le flux de génération et récupération des questions.

---

## 📊 Structure des Logs

### 1. Réception de la Réponse Webhook

```
=== DONNÉES REÇUES DU WEBHOOK ===
Type: _Map<String, dynamic>
Keys: (success, questions_count, response, course_id, ...)
Réponse webhook: {success: true, questions_count: 8, ...}
questions_count: 8
success: true
course_id: null
====================================
```

**À vérifier**:
- ✅ `success: true`
- ✅ `questions_count: 8` (ou le nombre demandé)
- ✅ `course_id: null` pour les prompts
- ❌ Si `questions_count: null` → Problème dans n8n

---

### 2. Analyse de la Réponse Normalisée

```
🔍 DEBUG - rawResponse type: _Map<String, dynamic>
🔍 DEBUG - normalizedResponse type: _Map<String, dynamic>
🔍 DEBUG - normalizedResponse: {questions_count: 8, difficulte: moyen, ...}
```

**À vérifier**:
- Les types doivent être `Map` ou similaire
- `normalizedResponse` contient bien les données

---

### 3. Extraction Initiale des Questions

```
🔍 DEBUG - Questions extraites de la réponse: 0
ℹ️ Aucune question valide trouvée dans la réponse webhook. Récupération depuis Supabase...
```

**Normal**: Le webhook n8n ne retourne généralement pas les questions complètes, juste `questions_count`. Les questions sont dans Supabase.

---

### 4. Détection du Mode (CRITIQUE)

```
🔍 DEBUG - questionsCount extrait: 8
🔍 DEBUG - returnedCourseId extrait: null
🔍 DEBUG - Condition questionsCount != null && questionsCount > 0: true
🔍 DEBUG - Condition returnedCourseId != null: false
```

**À vérifier**:
- ✅ Pour les **prompts**: `questionsCount: 8` (ou autre nombre) et `returnedCourseId: null`
- ✅ Pour les **cours**: `questionsCount: null` et `returnedCourseId: abc-123-def`

**Si les deux conditions sont false**:
```
⚠️ WARNING - Ni questionsCount ni returnedCourseId ne sont disponibles!
⚠️ WARNING - Impossible de récupérer les questions depuis Supabase
```
→ Problème dans la structure de la réponse webhook!

---

### 5. Mode PROMPT - Récupération par created_at

```
📊 Webhook indique 8 questions générées
🔵 Récupération des 8 dernières questions par created_at...
🔍 DEBUG - Polling tentative 1: 0 questions récupérées
⏳ Polling... aucune question trouvée (tentative 1/15)
🔍 DEBUG - Polling tentative 2: 0 questions récupérées
⏳ Polling... aucune question trouvée (tentative 2/15)
🔍 DEBUG - Polling tentative 3: 8 questions récupérées
🟢 8 questions trouvées après polling !
```

**À vérifier**:
- Les tentatives de polling doivent augmenter (1, 2, 3, ...)
- Après quelques tentatives, `X questions récupérées` doit passer de 0 à un nombre > 0
- Le message `🟢 X questions trouvées après polling !` doit apparaître

**Si bloqué à 0 après 15 tentatives**:
→ Les questions ne sont pas créées dans Supabase (problème n8n)

---

### 6. Mode COURSE - Récupération par course_id

```
🔵 Récupération des questions par course_id: abc-123-def...
🔍 DEBUG - Polling tentative 1: 0 questions récupérées
⏳ Polling... aucune question trouvée (tentative 1/15)
🔍 DEBUG - Polling tentative 2: 10 questions récupérées
🟢 10 questions trouvées après polling !
```

**Similaire au mode PROMPT mais filtre par `course_id`**

---

### 7. Résultat Final

```
=== QUESTIONS RÉCUPÉRÉES (FINAL) ===
Nombre total de questions: 8
Questions récupérées: 8
Première question: Qu'est-ce que la photosynthèse ?
Dernière question: Quel est le rôle de la chlorophylle ?
Résumé présent: true
Mots-clés: [photosynthèse, plantes, chlorophylle]
Normalized response: {questions_count: 8, ...}
====================================
```

**À vérifier**:
- ✅ `Nombre total de questions: 8` (doit correspondre à ce qui a été demandé)
- ✅ Les questions ont du contenu réel
- ✅ `Résumé présent: true` (si le webhook retourne un résumé)

---

## 🐛 Scénarios de Débogage

### Scénario 1: questions_count est null

**Logs**:
```
questions_count: null
🔍 DEBUG - questionsCount extrait: null
🔍 DEBUG - Condition questionsCount != null && questionsCount > 0: false
⚠️ WARNING - Ni questionsCount ni returnedCourseId ne sont disponibles!
```

**Cause**: Le webhook n8n ne retourne pas `questions_count`

**Solution**:
1. Vérifier le nœud "Respond to Webhook" dans n8n
2. S'assurer qu'il retourne un objet avec `questions_count`:
```json
{
  "success": true,
  "questions_count": {{ $json.nombre_questions }},
  "difficulte": "{{ $json.difficulte }}",
  "langue": "{{ $json.langue }}"
}
```

---

### Scénario 2: Polling ne trouve jamais de questions

**Logs**:
```
🔍 DEBUG - Polling tentative 1: 0 questions récupérées
⏳ Polling... aucune question trouvée (tentative 1/15)
...
🔍 DEBUG - Polling tentative 15: 0 questions récupérées
⏳ Polling... aucune question trouvée (tentative 15/15)
Nombre total de questions: 0
```

**Cause**: Les questions ne sont pas insérées dans Supabase

**Solution**:
1. Vérifier le nœud "Insert Question" dans n8n
2. Vérifier les logs n8n pour voir si l'insertion réussit
3. Vérifier manuellement dans Supabase table `questions` si des questions ont été créées
4. Vérifier que le champ `created_at` est bien rempli avec un timestamp récent

---

### Scénario 3: Questions trouvées mais liste vide dans l'UI

**Logs**:
```
🟢 8 questions trouvées après polling !
Nombre total de questions: 8
Première question: Qu'est-ce que la photosynthèse ?
```

**Mais**: L'écran "Réviser les questions" est vide

**Cause**: Problème dans `AppState.setQuestions()` ou navigation

**Solution**:
1. Vérifier que `context.read<AppState>().setQuestions()` est bien appelé
2. Vérifier les logs du `AppState`
3. Vérifier que `Navigator.push()` vers `ReviewScreen` est exécuté

---

### Scénario 4: Mauvaises questions récupérées

**Logs**:
```
Première question: Question d'un autre professeur
```

**Cause**: Collision temporelle - un autre enseignant a généré des questions en même temps

**Solution**:
1. Ajouter un filtre par `teacher_id` dans `fetchRecentQuestions()`
2. Modifier `webhook_service.dart`:
```dart
Future<List<Question>> fetchRecentQuestions(int count, String? teacherId) async {
  var query = Supabase.instance.client
      .from('questions')
      .select();
  
  if (teacherId != null) {
    query = query.eq('teacher_id', teacherId);
  }
  
  final response = await query
      .order('created_at', ascending: false)
      .limit(count);
  ...
}
```

---

## 📋 Checklist de Vérification

Lors du test, vérifier dans l'ordre:

- [ ] **Webhook reçoit la requête**: Logs n8n montrent l'appel
- [ ] **Webhook retourne success: true**: Log Flutter
- [ ] **questions_count est présent**: `questions_count: 8`
- [ ] **Condition détectée**: `Condition questionsCount != null && questionsCount > 0: true`
- [ ] **Mode PROMPT activé**: Message `📊 Webhook indique X questions générées`
- [ ] **Polling démarre**: Messages `⏳ Polling... tentative X/15`
- [ ] **Questions trouvées**: `🔍 DEBUG - Polling tentative X: 8 questions récupérées`
- [ ] **Polling s'arrête**: `🟢 8 questions trouvées après polling !`
- [ ] **Questions finales**: `Nombre total de questions: 8`
- [ ] **Navigation**: L'écran "Réviser les questions" s'affiche
- [ ] **Questions visibles**: Les 8 questions apparaissent dans la liste

---

## 🚀 Utilisation

1. Lancer l'application en mode debug
2. Créer un QCM par prompt
3. Observer la console Flutter
4. Comparer les logs avec les scénarios ci-dessus
5. Identifier le problème exact

---

**Date**: 3 Juin 2026  
**Fichier modifié**: `lib/screens/upload_screen.dart`  
**Logs ajoutés**: ~25 lignes de débogage
