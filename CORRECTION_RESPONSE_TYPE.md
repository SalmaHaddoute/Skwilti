# 🔧 Correction du Type de Réponse Webhook

**Date**: 3 Juin 2026  
**Problème**: `type 'List<dynamic>' is not a subtype of type 'Map<String, dynamic>'`

---

## ❌ Problème Identifié

### Erreur Observée

```
I/flutter (13324): 🔴 [QcmService] Erreur lors de la génération: 
type 'List<dynamic>' is not a subtype of type 'Map<String, dynamic>'
```

### Cause Racine

Le webhook n8n retourne **directement une List de questions**:

```json
[
  {
    "id": "e525de7f-1f8f-459f-bfcb-3498dacfa25d",
    "course_id": null,
    "text": "Qui est le personnage principal dans la pièce Antigone de Sophocle ?",
    "options": "[\"Antigone\",\"Créon\",\"Hémon\",\"Ismène\"]",
    "correct_answer": 0,
    "difficulty": "moyen",
    "points": 10,
    "explication": "Antigone est la fille de Jocaste et d'Œdipe...",
    "created_at": "2026-06-03T11:21:20.400888+00:00",
    "source": "prompt",
    "classroom_id": null
  },
  {...}
]
```

**Mais** le code attendait un objet Map:

```dart
final Map<String, dynamic> result = jsonDecode(response.body); // ❌ ERREUR
```

---

## ✅ Solution Implémentée

### 1. Correction dans `qcm_service.dart`

**Avant** (ligne 97):
```dart
final Map<String, dynamic> result = jsonDecode(response.body);

return {
  'success': true,
  ...result,
};
```

**Après**:
```dart
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

return {
  'success': true,
  ...result,
};
```

**Principe**:
- Décode d'abord comme `dynamic` pour déterminer le type
- Si c'est une `List`, on la wrappe dans un `Map` avec les clés attendues
- Si c'est un `Map`, on l'utilise directement
- Ajoute `questions_count` automatiquement basé sur la longueur de la liste

---

### 2. Correction dans `upload_screen.dart`

**Avant** (ligne 167):
```dart
final dynamic rawResponse = result['response'];
```

**Après**:
```dart
// Pour QcmService (mode PROMPT), les questions peuvent être directement dans result['questions']
// Pour WebhookService (mode COURSE), les questions sont dans result['response']
final dynamic rawResponse = result['questions'] ?? result['response'];
```

**Principe**:
- Vérifie d'abord si `questions` existe (venant de QcmService)
- Sinon, utilise `response` (venant de WebhookService)
- Compatible avec les deux modes

---

## 📊 Structure des Données Après Correction

### Réponse Webhook n8n (brute)
```json
[
  {"id": "...", "text": "Question 1", "options": "[...]", "correct_answer": 0, ...},
  {"id": "...", "text": "Question 2", "options": "[...]", "correct_answer": 1, ...}
]
```

### Après traitement dans QcmService
```dart
{
  'success': true,
  'questions': [
    {"id": "...", "text": "Question 1", ...},
    {"id": "...", "text": "Question 2", ...}
  ],
  'questions_count': 2,
  'course_id': null,
  'classroom_id': null
}
```

### Dans upload_screen.dart
```dart
result['questions']  // List de 2 questions
result['questions_count']  // 2
result['success']  // true
```

---

## 🧪 Tests à Effectuer

### Test 1: Mode PROMPT avec Liste de Questions

**Action**: Créer un QCM par prompt (8 questions sur Antigone)

**Logs attendus**:
```
🔵 [QcmService] Réponse reçue
   Status code: 200
   Body: [{"id":"...","text":"Question 1",...}, ...]

🔍 [QcmService] Type de réponse: List<dynamic>
🔍 [QcmService] Réponse est une Liste de 8 questions
🟢 [QcmService] QCM généré avec succès!
   Questions count: 8

=== DONNÉES REÇUES DU WEBHOOK ===
questions_count: 8
success: true
course_id: null
====================================

🔍 DEBUG - rawResponse type: List<dynamic>
🔍 DEBUG - Questions extraites de la réponse: 8
```

**Résultat attendu**: ✅ Les 8 questions s'affichent dans "Réviser les questions"

---

### Test 2: Vérifier le Parsing des Questions

**Données n8n**:
```json
{
  "text": "Qui est le personnage principal ?",
  "options": "[\"Antigone\",\"Créon\",\"Hémon\",\"Ismène\"]",
  "correct_answer": 0
}
```

**Conversion par Question.fromJson()**:
```dart
Question(
  question: "Qui est le personnage principal ?",
  options: ["Antigone", "Créon", "Hémon", "Ismène"],
  correctIndex: 0
)
```

**Logs attendus**:
```
=== CONVERSION QUESTION ===
JSON reçu: {text: Qui est..., options: ["Antigone",...], correct_answer: 0, ...}
Question: Qui est le personnage principal ?
Options: [Antigone, Créon, Hémon, Ismène]
Correct: 0
========================
```

---

## 📝 Format des Questions n8n

Le webhook retourne les questions avec:

| Champ n8n | Champ Question Flutter | Type | Notes |
|-----------|----------------------|------|-------|
| `text` | `question` | String | Texte de la question |
| `options` | `options` | String (JSON) | Format: `"[\"A\",\"B\",\"C\"]"` |
| `correct_answer` | `correctIndex` | int | Index 0-based |
| `explication` | `explication` | String | Explication de la réponse |
| `id` | `id` | String (UUID) | Généré par Supabase |
| `course_id` | - | null | Toujours null pour les prompts |
| `classroom_id` | - | null | null ou UUID |
| `created_at` | - | timestamp | ISO 8601 |
| `source` | - | "prompt" | Indique la source |

**Important**: Le champ `options` est une **chaîne JSON** qui doit être parsée:
```dart
"[\"Antigone\",\"Créon\",\"Hémon\",\"Ismène\"]"
→ ["Antigone", "Créon", "Hémon", "Ismène"]
```

---

## 🐛 Dépannage

### Problème: Encore l'erreur "List is not a subtype of Map"

**Vérifier**:
1. Les modifications dans `qcm_service.dart` sont bien appliquées
2. L'application a été hot restarted (pas hot reload)
3. Les logs montrent bien `Type de réponse: List<dynamic>`

---

### Problème: Questions vides ou mal parsées

**Logs à vérifier**:
```
=== CONVERSION QUESTION ===
Question: 
Options: []
```

**Causes possibles**:
- Le champ `text` est absent (vérifier le nœud n8n "Insert Question")
- Le champ `options` n'est pas un JSON valide
- Le format des données a changé

**Solution**: Vérifier la structure exacte retournée par le webhook avec:
```dart
print('Body webhook brut: ${response.body}');
```

---

## 📋 Fichiers Modifiés

| Fichier | Lignes | Modification |
|---------|--------|--------------|
| `lib/services/qcm_service.dart` | 97-119 | Gestion des réponses List et Map |
| `lib/screens/upload_screen.dart` | 167 | Vérification `questions` avant `response` |

---

## 🎯 Résultat Attendu

Après ces corrections:

1. ✅ Le webhook peut retourner soit une List soit un Map
2. ✅ Les questions sont correctement wrappées dans une structure attendue
3. ✅ `questions_count` est automatiquement calculé
4. ✅ Les questions s'affichent dans l'écran "Réviser les questions"
5. ✅ Le parsing des options JSON fonctionne correctement

---

**Date**: 3 Juin 2026  
**Status**: ✅ Corrections appliquées - Test requis  
**Compilation**: ✅ Aucune erreur
