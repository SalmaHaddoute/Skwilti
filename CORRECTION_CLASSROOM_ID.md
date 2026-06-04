# 🔧 Correction du Problème classroom_id

**Date**: 1er Juin 2026  
**Problème**: `classroom_id` est envoyé comme chaîne vide `""` au lieu de `null`

---

## ❌ Problème Identifié

### Dans n8n
Le nœud "Insert Question" reçoit `classroom_id: ""` (chaîne vide) au lieu de `null`, ce qui cause une erreur d'insertion dans Supabase (UUID attendu).

### Dans Flutter
1. **qcm_service.dart ligne 64**: `'classroom_id': classroomId ?? ''` → Envoie `""` si null
2. **upload_screen.dart ligne 106**: `classroomId: null` → Toujours hardcodé à null
3. **webhook_service.dart**: `classroom_id` n'est pas inclus dans le body du webhook

---

## ✅ Corrections Appliquées

### 1. qcm_service.dart

**Avant**:
```dart
final requestBody = {
  'prompt': prompt.trim(),
  'matiere': matiere ?? '',
  'classroom_id': classroomId ?? '',  // ❌ Envoie ""
  'teacher_id': teacherId ?? '',       // ❌ Envoie ""
  'nombre_questions': nombreQuestions,
  'difficulte': difficulte.toLowerCase(),
  'langue': langue,
  'mode': 'prompt',
};
```

**Après**:
```dart
print('   classroom_id envoyé: $classroomId');  // ✅ Log ajouté
print('   teacher_id envoyé: $teacherId');      // ✅ Log ajouté

final requestBody = {
  'prompt': prompt.trim(),
  'matiere': matiere ?? '',
  'classroom_id': classroomId?.isNotEmpty == true ? classroomId : null,  // ✅ null si vide
  'teacher_id': teacherId?.isNotEmpty == true ? teacherId : null,        // ✅ null si vide
  'nombre_questions': nombreQuestions,
  'difficulte': difficulte.toLowerCase(),
  'langue': langue,
  'mode': 'prompt',
};
```

**Changements**:
- ✅ Vérifie si `classroomId` est non vide avant de l'envoyer, sinon `null`
- ✅ Même chose pour `teacherId`
- ✅ Logs ajoutés pour déboguer

---

### 2. webhook_service.dart

#### A. Ajout du paramètre

**Avant**:
```dart
Future<Map<String, dynamic>?> processPdfUpload({
  required String title,
  required String teacherId,
  String? filiereId,
  String? niveauId,
  String? matiereId,
  String? semestre,
  int nombreQuestions = 10,
  // ... pas de classroomId
```

**Après**:
```dart
Future<Map<String, dynamic>?> processPdfUpload({
  required String title,
  required String teacherId,
  String? filiereId,
  String? niveauId,
  String? matiereId,
  String? semestre,
  String? classroomId,  // ✅ Ajouté
  int nombreQuestions = 10,
```

#### B. Inclusion dans le body

**Avant**:
```dart
final requestBody = {
  'file_url': fileUrl,
  'document_id': documentId,
  'course_id': courseId,
  // classroom_id manquant
  'nombre_questions': nombreQuestions,
  'difficulte': difficulte,
  'langue': langue,
  if (prompt != null && prompt.isNotEmpty) 'prompt': prompt,
  if (prompt != null && prompt.isNotEmpty) 'mode': 'prompt',
};
```

**Après**:
```dart
final requestBody = {
  'file_url': fileUrl,
  'document_id': documentId,
  'course_id': courseId,
  'classroom_id': classroomId?.isNotEmpty == true ? classroomId : null,  // ✅ Ajouté
  'teacher_id': teacherId,  // ✅ Explicite
  'nombre_questions': nombreQuestions,
  'difficulte': difficulte,
  'langue': langue,
  if (prompt != null && prompt.isNotEmpty) 'prompt': prompt,
  if (prompt != null && prompt.isNotEmpty) 'mode': 'prompt',
};

debugPrint('  - classroom_id: $classroomId');  // ✅ Log ajouté
debugPrint('  - teacher_id: $teacherId');      // ✅ Log ajouté
```

---

## 🔧 Correction n8n

### Dans le nœud "Insert Question"

**Champ `classroom_id`**:

**Avant**:
```javascript
={{ $('Webhook').first().json.body.classroom_id }}
```

**Après**:
```javascript
={{ $('Webhook').first().json.body.classroom_id || null }}
```

**Explication**: 
- Si `classroom_id` est `""` (chaîne vide), `|| null` le transforme en `null`
- Supabase accepte `null` pour un champ UUID optionnel
- Supabase rejette `""` car ce n'est pas un UUID valide

---

## ✅ Actions Complétées

### 1. ✅ Passer le classroom_id depuis l'UI (Option A: Via le widget)

**Implémenté dans `upload_screen.dart`**:

```dart
// Dans UploadScreen
class UploadScreen extends StatefulWidget {
  final String? classroomId;  // ✅ Ajouté
  
  const UploadScreen({
    super.key,
    this.classroomId,  // ✅ Optionnel
  });
  
  @override
  State<UploadScreen> createState() => _UploadScreenState();
}
```

**Utilisation depuis une page de classe**:

```dart
// Depuis la page de classe
Navigator.push(
  context,
  MaterialPageRoute(
    builder: (_) => UploadScreen(
      classroomId: widget.classroom.id,  // ✅ Passer l'ID
    ),
  ),
);

// Ou sans classroom (général)
Navigator.push(
  context,
  MaterialPageRoute(
    builder: (_) => const UploadScreen(),  // ✅ classroomId sera null
  ),
);
```

### 2. ✅ Utiliser le classroom_id dans les appels

**Mode Prompt** (ligne 106):
```dart
result = await _qcmService.generateQcmByPrompt(
  prompt: _promptController.text.trim(),
  webhookUrl: webhookUrl,
  classroomId: widget.classroomId,  // ✅ Utilise la valeur du widget
  nombreQuestions: _nbQuestions,
  difficulte: _difficulty,
  langue: 'Français',
  matiere: _matiereController.text.trim().isNotEmpty 
      ? _matiereController.text.trim() 
      : null,
  teacherId: appState.currentUser?.id,
);
```

**Mode Course** (ligne 118):
```dart
result = await WebhookService().processPdfUpload(
  title: _selectedCourseTitle ?? 'Mon cours',
  teacherId: appState.currentUser?.id ?? '',
  classroomId: widget.classroomId,  // ✅ Utilise la valeur du widget
  nombreQuestions: _nbQuestions,
  difficulte: _difficulty,
  langue: 'Français',
  existingFile: null,
  existingCourseId: _selectedCourseId,
  prompt: null,
);
```

---

## 📝 Option Alternative (Non implémentée)

**Option B: Via un dropdown** - Peut être ajoutée plus tard si nécessaire

```dart
// Dans _UploadScreenState
String? _selectedClassroomId;

// Dans le UI
DropdownButton<String>(
  value: _selectedClassroomId,
  hint: Text('Classe (optionnel)'),
  items: context.watch<AppState>().userClassrooms.map((classroom) {
    return DropdownMenuItem(
      value: classroom.id,
      child: Text(classroom.name),
    );
  }).toList(),
  onChanged: (value) {
    setState(() => _selectedClassroomId = value);
  },
)

// Puis utiliser: widget.classroomId ?? _selectedClassroomId
```

---

## 🧪 Tests

### 1. Vérifier les logs

Après les corrections, les logs devraient afficher:

```
🔵 [QcmService] Génération QCM par prompt...
   classroom_id envoyé: abc-123-def  // ✅ UUID valide
   teacher_id envoyé: xyz-789-uvw    // ✅ UUID valide
```

OU

```
🔵 [QcmService] Génération QCM par prompt...
   classroom_id envoyé: null  // ✅ null explicite
   teacher_id envoyé: xyz-789-uvw
```

### 2. Vérifier le body envoyé

```
🔵 WebhookService: Body envoyé:
  - classroom_id: abc-123-def  // ✅ UUID valide
```

OU

```
🔵 WebhookService: Body envoyé:
  - classroom_id: null  // ✅ null explicite
```

**JAMAIS**:
```
  - classroom_id:   // ❌ Chaîne vide
```

### 3. Test n8n

Dans n8n, vérifier que le webhook reçoit:

**Cas 1: Avec classroom_id**
```json
{
  "classroom_id": "abc-123-def-456",
  "teacher_id": "xyz-789-uvw-012"
}
```

**Cas 2: Sans classroom_id**
```json
{
  "classroom_id": null,
  "teacher_id": "xyz-789-uvw-012"
}
```

**JAMAIS**:
```json
{
  "classroom_id": "",  // ❌
  "teacher_id": ""     // ❌
}
```

---

## 📊 Résumé

### Corrections Flutter
- ✅ `qcm_service.dart`: Envoie `null` au lieu de `""` si vide
- ✅ `webhook_service.dart`: Paramètre `classroomId` ajouté et inclus dans le body
- ✅ Logs ajoutés pour déboguer

### Correction n8n
- ✅ Nœud "Insert Question": Utiliser `|| null` pour convertir `""` en `null`

### Actions Restantes
- ⏳ Ajouter un moyen de passer/sélectionner le `classroom_id` dans l'UI
- ⏳ Utiliser la valeur dans les appels aux services

---

## 🎯 Résultat Attendu

Après ces corrections:

1. **Si classroom_id est fourni**: UUID valide envoyé et inséré dans Supabase
2. **Si classroom_id n'est pas fourni**: `null` envoyé et accepté par Supabase
3. **Plus d'erreur**: Fini les erreurs `""` is not a valid UUID

---

**Date**: 3 Juin 2026  
**Status**: ✅ Toutes les corrections Flutter complétées - Correction n8n requise
