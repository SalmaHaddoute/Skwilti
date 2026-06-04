# ✅ Logs de Débogage Ajoutés

**Fichier**: `lib/screens/upload_screen.dart`  
**Date**: 3 Juin 2026

---

## 🔍 Logs Ajoutés

### 1. Réception du Webhook
```dart
print('Réponse webhook: $result');
print('questions_count: ${result['questions_count']}');
print('success: ${result['success']}');
print('course_id: ${result['course_id']}');
```

### 2. Analyse de la Réponse
```dart
print('🔍 DEBUG - rawResponse type: ${rawResponse.runtimeType}');
print('🔍 DEBUG - normalizedResponse type: ${normalizedResponse.runtimeType}');
print('🔍 DEBUG - normalizedResponse: $normalizedResponse');
print('🔍 DEBUG - Questions extraites de la réponse: ${questions.length}');
```

### 3. Détection du Mode
```dart
print('🔍 DEBUG - questionsCount extrait: $questionsCount');
print('🔍 DEBUG - returnedCourseId extrait: $returnedCourseId');
print('🔍 DEBUG - Condition questionsCount != null && questionsCount > 0: ${...}');
print('🔍 DEBUG - Condition returnedCourseId != null: ${...}');
```

### 4. Polling et Récupération
```dart
print('🔍 DEBUG - Polling tentative ${i + 1}: ${questions.length} questions récupérées');
```

### 5. Warning si Problème
```dart
print('⚠️ WARNING - Ni questionsCount ni returnedCourseId ne sont disponibles!');
print('⚠️ WARNING - Impossible de récupérer les questions depuis Supabase');
```

### 6. Résultat Final
```dart
print('Nombre total de questions: ${questions.length}');
print('Questions récupérées: ${questions.length}');
print('Première question: ${questions.first.question}');
print('Dernière question: ${questions.last.question}');
```

---

## 📊 Exemple de Sortie Attendue (Succès)

```
=== DONNÉES REÇUES DU WEBHOOK ===
Réponse webhook: {success: true, questions_count: 8, ...}
questions_count: 8
success: true
course_id: null
====================================

🔍 DEBUG - normalizedResponse: {questions_count: 8, difficulte: moyen, langue: Français}
🔍 DEBUG - Questions extraites de la réponse: 0
ℹ️ Aucune question valide trouvée dans la réponse webhook. Récupération depuis Supabase...

🔍 DEBUG - questionsCount extrait: 8
🔍 DEBUG - returnedCourseId extrait: null
🔍 DEBUG - Condition questionsCount != null && questionsCount > 0: true

📊 Webhook indique 8 questions générées
🔵 Récupération des 8 dernières questions par created_at...

🔍 DEBUG - Polling tentative 1: 0 questions récupérées
⏳ Polling... aucune question trouvée (tentative 1/15)

🔍 DEBUG - Polling tentative 2: 8 questions récupérées
🟢 8 questions trouvées après polling !

=== QUESTIONS RÉCUPÉRÉES (FINAL) ===
Nombre total de questions: 8
Questions récupérées: 8
Première question: Qu'est-ce que la photosynthèse ?
Dernière question: Quel est le rôle de la chlorophylle ?
====================================
```

---

## 🐛 Points Critiques à Surveiller

1. **questions_count doit être présent**: Si `null`, le webhook n8n ne retourne pas cette valeur
2. **Condition doit être true**: Si false, la logique ne rentre pas dans le mode PROMPT
3. **Polling doit trouver des questions**: Si toujours 0, les questions ne sont pas créées dans Supabase
4. **Nombre final doit correspondre**: Si `questions_count: 8` mais `Nombre total: 0`, problème de récupération

---

## 📖 Documentation Complète

Voir `DEBUG_LOGS_GUIDE.md` pour:
- Scénarios de débogage détaillés
- Solutions aux problèmes courants
- Checklist de vérification

---

**Status**: ✅ Prêt pour test  
**Compilation**: ✅ Aucune erreur
