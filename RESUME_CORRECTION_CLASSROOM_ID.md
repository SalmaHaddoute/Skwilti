# ✅ Correction classroom_id COMPLÉTÉE

**Date**: 3 Juin 2026  
**Problème initial**: `classroom_id` envoyé comme `""` (chaîne vide) au lieu de `null`

---

## 🎯 Corrections Appliquées

### ✅ 1. Flutter - Backend Services

#### `lib/services/qcm_service.dart`
- Remplacé `classroomId ?? ''` par `classroomId?.isNotEmpty == true ? classroomId : null`
- Même chose pour `teacherId`
- Ajout de logs de débogage

#### `lib/services/webhook_service.dart`
- Ajout du paramètre `String? classroomId` à `processPdfUpload()`
- Inclusion de `classroom_id` dans le body du webhook avec null-check
- Ajout de logs de débogage

### ✅ 2. Flutter - Interface Utilisateur

#### `lib/screens/upload_screen.dart`
- **Ajout du paramètre widget**: `final String? classroomId;` dans `UploadScreen`
- **Mode Prompt** (ligne 106): Utilise `widget.classroomId` au lieu de `null`
- **Mode Course** (ligne 118): Utilise `widget.classroomId` au lieu de ne pas passer le paramètre

---

## 📱 Utilisation

### Depuis une page de classe (avec classroom_id)
```dart
Navigator.push(
  context,
  MaterialPageRoute(
    builder: (_) => UploadScreen(
      classroomId: classroom.id,  // ✅ Passe l'UUID de la classe
    ),
  ),
);
```

### Depuis la page d'accueil (sans classroom_id)
```dart
Navigator.push(
  context,
  MaterialPageRoute(
    builder: (_) => const UploadScreen(),  // ✅ classroomId sera null
  ),
);
```

---

## 🔧 Correction n8n REQUISE

### ⚠️ ACTION NÉCESSAIRE

Dans le workflow n8n **"Flutter uploade PDF"**, nœud **"Insert Question"**:

**Champ `classroom_id`** doit être modifié:

**Avant**:
```javascript
={{ $('Webhook').first().json.body.classroom_id }}
```

**Après**:
```javascript
={{ $('Webhook').first().json.body.classroom_id || null }}
```

**Pourquoi?**
- L'opérateur `|| null` convertit les chaînes vides `""` en `null`
- Supabase accepte `null` pour un champ UUID optionnel
- Supabase rejette `""` car ce n'est pas un UUID valide

---

## 🧪 Tests à Effectuer

### 1. Vérifier les logs Flutter

**Avec classroom_id**:
```
🔵 [QcmService] Génération QCM par prompt...
   classroom_id envoyé: abc-123-def-456-uuid
   teacher_id envoyé: xyz-789-uvw-012-uuid
```

**Sans classroom_id**:
```
🔵 [QcmService] Génération QCM par prompt...
   classroom_id envoyé: null
   teacher_id envoyé: xyz-789-uvw-012-uuid
```

### 2. Vérifier le body webhook

**Avec classroom_id**:
```
🔵 WebhookService: Body envoyé:
  - classroom_id: abc-123-def-456-uuid  ✅
  - teacher_id: xyz-789-uvw-012-uuid    ✅
```

**Sans classroom_id**:
```
🔵 WebhookService: Body envoyé:
  - classroom_id: null  ✅
  - teacher_id: xyz-789-uvw-012-uuid
```

**JAMAIS** (c'était le bug):
```
  - classroom_id:   ❌ (chaîne vide)
```

### 3. Test Complet

1. **Test A - Création QCM depuis une classe**:
   - Ouvrir une classe
   - Cliquer sur "Créer un QCM"
   - Générer le QCM
   - ✅ Le QCM doit être associé à la classe

2. **Test B - Création QCM général**:
   - Depuis la page d'accueil, cliquer sur "Créer un QCM"
   - Générer le QCM
   - ✅ Le QCM est créé sans association à une classe

---

## 📊 Résumé

| Composant | Status | Notes |
|-----------|--------|-------|
| `qcm_service.dart` | ✅ | Envoie `null` au lieu de `""` |
| `webhook_service.dart` | ✅ | Paramètre ajouté, logs ajoutés |
| `upload_screen.dart` | ✅ | Widget accepte `classroomId` optionnel |
| **n8n workflow** | ⚠️ | **ACTION REQUISE: Ajouter `\|\| null`** |
| Compilation | ✅ | Aucune erreur |
| Tests | ⏳ | À effectuer après correction n8n |

---

## 🎯 Résultat Attendu

Après correction n8n:

1. ✅ Si `classroom_id` est fourni → UUID valide inséré dans Supabase
2. ✅ Si `classroom_id` est `null` → Accepté par Supabase (champ optionnel)
3. ✅ Plus d'erreur `"" is not a valid UUID`

---

## 📝 Prochaines Étapes

1. ⚠️ **Modifier le workflow n8n** (nœud "Insert Question", champ `classroom_id`)
2. ⏳ Effectuer les tests A et B ci-dessus
3. ⏳ Vérifier les logs Flutter et n8n
4. ✅ Valider que les QCM sont correctement créés avec/sans classe

---

**Date**: 3 Juin 2026  
**Auteur**: Kiro AI  
**Status Global**: ✅ Corrections Flutter complètes - ⚠️ Correction n8n requise


---

# ✅ CORRECTION BONUS: Chargement des Questions par Prompt

## Problème Découvert

Les questions générées par prompt n'apparaissaient pas dans l'écran "Réviser les questions" car:
- Le webhook retourne `course_id: null` pour les prompts
- Le code filtrait par `.eq('course_id', null)` qui ne trouve rien dans Supabase

## Solution Implémentée

### 1. Nouvelle méthode dans `webhook_service.dart`

```dart
Future<List<Question>> fetchRecentQuestions(int count)
```

Récupère les N dernières questions par `created_at DESC` au lieu de filtrer par `course_id`.

### 2. Détection automatique dans `upload_screen.dart`

- Si `questions_count` dans la réponse webhook → **Mode PROMPT** → `fetchRecentQuestions()`
- Si `course_id` dans la réponse webhook → **Mode COURSE** → `fetchQuestionsForCourse()`

## Fichiers Modifiés

- ✅ `lib/services/webhook_service.dart` (+20 lignes)
- ✅ `lib/screens/upload_screen.dart` (logique conditionnelle)
- ✅ Aucune erreur de compilation

## Test Requis

Créer un QCM par prompt et vérifier que les questions s'affichent dans "Réviser les questions".

**Voir**: `CORRECTION_QUESTIONS_PROMPT.md` pour les détails complets.
