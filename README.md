# Skwilti AI Study — Application Flutter

Application mobile de génération de QCM par IA, développée dans le cadre d'un Projet de Fin d'Études.

## Palette de couleurs
- Violet principal : `#6C3EE8` (Skwilti brand)
- Orange accent : `#FF6B2C` (CTA, actions)

## Architecture
```
Flutter (frontend)  ←──HTTP──→  n8n (backend IA)
```

## Structure du projet
```
lib/
├── main.dart                 # Point d'entrée
├── theme/
│   └── app_theme.dart        # Couleurs + ThemeData
├── models/
│   ├── question.dart         # Modèles Question + QcmSession
│   └── course.dart           # Modèle Course
├── services/
│   ├── app_state.dart        # Provider - état global
│   └── n8n_service.dart      # Appels HTTP vers n8n
├── screens/
│   ├── home_screen.dart      # Tableau de bord
│   ├── upload_screen.dart    # Upload + config QCM
│   ├── review_screen.dart    # Révision des questions
│   ├── qcm_screen.dart       # Interface QCM + timer
│   ├── results_screen.dart   # Résultats + corrections
│   ├── library_screen.dart   # Bibliothèque
│   └── profile_screen.dart   # Profil + config n8n
└── widgets/
    ├── common_widgets.dart   # Boutons, cards, badges
    └── bottom_nav.dart       # Navigation bas
```

## Installation

### 1. Prérequis
- Flutter SDK >= 3.10
- Dart >= 3.0
- Android Studio ou VS Code

### 2. Installer les dépendances
```bash
flutter pub get
```

### 3. Lancer l'application
```bash
flutter run
```

### 4. Configurer n8n
Dans l'écran **Profil** → **Configuration n8n**, entrez l'URL de votre webhook :
```
https://votre-n8n.com/webhook/skwilti-qcm
```

Dans `lib/services/n8n_service.dart`, remplacez :
```dart
static const String _baseUrl = 'https://votre-n8n.com/webhook';
```

## Workflow n8n

Le workflow n8n doit recevoir :
```json
{
  "file": "<fichier multipart>",
  "nb_questions": 10,
  "difficulty": "moyen",
  "language": "Français"
}
```

Et retourner :
```json
{
  "resume": "Résumé du cours...",
  "mots_cles": ["Mitose", "ADN", "Membrane"],
  "questions": [
    {
      "id": "1",
      "question": "Quelle est la fonction de la mitochondrie ?",
      "options": ["Option A", "Option B", "Option C", "Option D"],
      "correct": 1,
      "explication": "Explication de la bonne réponse..."
    }
  ]
}
```

## Dépendances principales
| Package | Usage |
|---------|-------|
| `file_picker` | Sélection de fichiers PDF/Word/Image |
| `dio` | Appels HTTP multipart vers n8n |
| `provider` | Gestion de l'état global |
| `lucide_icons` | Icônes vectorielles professionnelles |
| `google_fonts` | Police Plus Jakarta Sans |
| `hive_flutter` | Stockage local |
| `fl_chart` | Graphiques de progression |

## Mode démo
Sans n8n configuré, l'app utilise des **données mockées** (5 questions de biologie cellulaire) pour démontrer toutes les fonctionnalités.

## Développé avec
- Flutter 3.x
- Dart 3.x
- n8n (workflow automation)
- OpenAI / Gemini (via n8n)
