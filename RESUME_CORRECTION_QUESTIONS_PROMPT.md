# ✅ Correction Questions Prompt - Résumé

**Problème**: Les questions générées par prompt ne s'affichaient pas car le code filtrait par `course_id` qui est `null` pour les prompts.

---

## 🔧 Solution Implémentée

### 1. Nouvelle méthode `fetchRecentQuestions()` 
**Fichier**: `lib/services/webhook_service.dart`

Récupère les N dernières questions créées (triées par `created_at DESC`) au lieu de filtrer par `course_id`:

```dart
Future<List<Question>> fetchRecentQuestions(int count) async {
  final response = await Supabase.instance.client
      .from('questions')
      .select()
      .order('created_at', ascending: false)
      .limit(count);
  return data.map((q) => Question.fromJson(q)).toList();
}
```

### 2. Logique conditionnelle mise à jour
**Fichier**: `lib/screens/upload_screen.dart`

Détecte automatiquement le mode:
- **Si `questions_count` présent** → Mode PROMPT → Utilise `fetchRecentQuestions()`
- **Si `course_id` présent** → Mode COURSE → Utilise `fetchQuestionsForCourse()`

---

## 📊 Avant vs Après

| Mode | Webhook | Avant | Après |
|------|---------|-------|-------|
| Prompt | `questions_count: 8` | ❌ Filtre `.eq('course_id', null)` → Rien | ✅ `.order('created_at').limit(8)` → 8 questions |
| Course | `course_id: "abc-123"` | ✅ Filtre `.eq('course_id', 'abc-123')` | ✅ Même chose |

---

## 🧪 Test Rapide

1. Créer un QCM par prompt (8 questions sur la photosynthèse)
2. Attendre le polling (max 60s)
3. ✅ Vérifier que les 8 questions s'affichent dans "Réviser les questions"

**Logs attendus**:
```
📊 Webhook indique 8 questions générées
🔵 Récupération des 8 dernières questions par created_at...
🟢 8 questions trouvées après polling !
```

---

## 📋 Fichiers Modifiés

- ✅ `lib/services/webhook_service.dart` (nouvelle méthode)
- ✅ `lib/screens/upload_screen.dart` (détection conditionnelle)
- ✅ Aucune erreur de compilation

---

**Status**: ✅ Prêt pour test  
**Date**: 3 Juin 2026
