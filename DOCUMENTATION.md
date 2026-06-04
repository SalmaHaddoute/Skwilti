# 📚 Documentation Complète - Application Skwilti

## 📋 Table des Matières
1. [Vue d'ensemble](#vue-densemble)
2. [Architecture de l'Application](#architecture)
3. [Rôles Utilisateurs](#rôles-utilisateurs)
4. [Fonctionnalités Principales](#fonctionnalités-principales)
5. [Structure des Fichiers](#structure-des-fichiers)
6. [Modèles de Données](#modèles-de-données)
7. [Services](#services)
8. [Écrans](#écrans)
9. [Widgets](#widgets)
10. [Dépendances](#dépendances)

---

## 🎯 Vue d'Ensemble

**Skwilti** est une application mobile Flutter de gestion pédagogique avec génération IA de QCM (Questionnaires à Choix Multiples). L'application permet aux enseignants, étudiants, parents et administrateurs de gérer des classes, des cours, des QCM et suivre la progression académique.

### Informations Principales
- **Nom**: Skwilti App
- **Version**: 1.0.0+1
- **Framework**: Flutter 3.0.0+
- **Backend**: Supabase (PostgreSQL + Auth)
- **Plateforme**: Android, iOS
- **Langue**: Français

---

## 🏗️ Architecture de l'Application

### Architecture Générale
```
┌─────────────────────────────────────────┐
│         Interface Utilisateur            │
│  (Écrans Flutter - Widgets)             │
└──────────────┬──────────────────────────┘
               │
┌──────────────▼──────────────────────────┐
│      Services & State Management        │
│  (AppState, AuthService, etc.)         │
└──────────────┬──────────────────────────┘
               │
┌──────────────▼──────────────────────────┐
│      Modèles de Données                 │
│  (User, Classroom, Course, etc.)       │
└──────────────┬──────────────────────────┘
               │
┌──────────────▼──────────────────────────┐
│      Backend Supabase                   │
│  (PostgreSQL + Auth + Webhooks)        │
└─────────────────────────────────────────┘
```

### Pattern de Gestion d'État
- **Provider**: Gestion centralisée de l'état avec `AppState`
- **ChangeNotifier**: Notifications de changements d'état
- **Consumer**: Widgets réactifs aux changements

---

## 👥 Rôles Utilisateurs

### 1. **Enseignant (Teacher)**
- Créer et gérer des classes
- Créer des QCM et des cours
- Créer des rooms (salles de classe virtuelles)
- Suivre la progression des étudiants
- Voir les statistiques de performance
- Assigner des enseignants à des classes
- Gérer les contenus pédagogiques

### 2. **Étudiant (Student)**
- Rejoindre des classes via code d'invitation
- Répondre aux QCM
- Consulter ses résultats et statistiques
- Voir sa progression académique
- Accumuler des points
- Participer aux rooms

### 3. **Parent (Parent)**
- Suivre la progression de son enfant
- Consulter les résultats académiques
- Voir les statistiques de performance
- Recevoir des notifications

### 4. **Administrateur (Admin)**
- Gérer tous les utilisateurs
- Gérer les classes et les cours
- Gérer les filières, niveaux et matières
- Gérer les structures scolaires
- Voir les statistiques globales
- Gérer les abonnements

---

## ⚙️ Fonctionnalités Principales

### 🔐 Authentification
- **Inscription**: Créer un compte avec email/mot de passe
- **Connexion**: Se connecter avec email/mot de passe
- **Déconnexion**: Quitter l'application
- **Restauration de Session**: Récupérer la session précédente
- **Gestion des Rôles**: Attribution automatique du rôle

### 📚 Gestion des Classes
- **Créer une Classe**: Enseignant crée une classe
- **Rejoindre une Classe**: Étudiant rejoint via code d'invitation
- **Gérer les Étudiants**: Ajouter/supprimer des étudiants
- **Assigner des Enseignants**: Admin assigne des enseignants
- **Voir les Détails**: Consulter les informations de la classe

### 📖 Gestion des Cours
- **Créer un Cours**: Enseignant crée un cours
- **Uploader des Contenus**: Ajouter des fichiers PDF/images
- **Organiser par Matière**: Classer par sujet
- **Voir les Détails**: Consulter le contenu du cours

### ❓ Gestion des QCM
- **Créer un QCM**: Enseignant crée un questionnaire
- **Générer avec IA**: Utiliser l'IA pour générer des questions
- **Répondre aux QCM**: Étudiant répond aux questions
- **Voir les Résultats**: Consulter les scores et réponses
- **Analyser les Performances**: Voir les statistiques

### 🎮 Rooms (Salles Virtuelles)
- **Créer une Room**: Enseignant crée une salle
- **Rejoindre une Room**: Étudiant rejoint avec code
- **Participer en Temps Réel**: Interaction en direct
- **Voir les Participants**: Liste des personnes présentes

### 📊 Statistiques et Suivi
- **Tableau de Bord Étudiant**: Voir sa progression
- **Tableau de Bord Enseignant**: Voir les performances des élèves
- **Tableau de Bord Parent**: Suivre son enfant
- **Graphiques de Performance**: Courbes de progression
- **Historique des Sessions**: Voir les QCM complétés

### 💬 Messagerie et Notifications
- **Conversations**: Discuter avec d'autres utilisateurs
- **Notifications**: Recevoir des alertes
- **Réclamations**: Soumettre des problèmes
- **Webhooks**: Intégration avec n8n

### 💳 Abonnements
- **Freemium**: Accès limité (1 QCM/jour)
- **Basic**: Accès intermédiaire (5 QCM/jour)
- **Premium**: Accès complet (illimité)
- **Gestion des Paiements**: Intégration paiement

### 🏆 Système de Points
- **Gagner des Points**: Pour chaque action
- **Consulter les Points**: Voir le total accumulé
- **Récompenses**: Débloquer des fonctionnalités

---

## 📁 Structure des Fichiers

### Répertoire Principal
```
lib/
├── main.dart                    # Point d'entrée de l'application
├── test_schema.dart             # Tests du schéma
├── config/
│   └── supabase_config.dart     # Configuration Supabase
├── models/                      # Modèles de données
│   ├── user.dart
│   ├── classroom.dart
│   ├── course.dart
│   ├── question.dart
│   ├── qsm_session.dart
│   ├── room.dart
│   ├── message.dart
│   ├── conversation.dart
│   ├── notification.dart
│   └── statistics.dart
├── services/                    # Services métier
│   ├── app_state.dart
│   ├── auth_service.dart
│   ├── messaging_service.dart
│   ├── points_service.dart
│   ├── n8n_service.dart
│   ├── webhook_service.dart
│   └── webhook_test_service.dart
├── screens/                     # Écrans de l'application
│   ├── auth_screen.dart
│   ├── teacher_dashboard.dart
│   ├── student_dashboard.dart
│   ├── parent_dashboard.dart
│   ├── admin_dashboard.dart
│   ├── [autres écrans...]
├── theme/                       # Thème et couleurs
│   ├── app_theme.dart
│   └── skwilti_theme.dart
└── widgets/                     # Composants réutilisables
    ├── astronaut_illustration.dart
    ├── skwilti_logo.dart
    ├── bottom_nav.dart
    ├── [autres widgets...]
```


---

## 📊 Modèles de Données

### User (Utilisateur)
```dart
class User {
  String id;                      // ID unique Supabase
  String email;                   // Email de l'utilisateur
  String firstName;               // Prénom
  String lastName;                // Nom
  String? avatar;                 // URL de l'avatar
  UserRole role;                  // Rôle (teacher, student, parent, admin)
  SubscriptionType subscription;  // Type d'abonnement
  DateTime createdAt;             // Date de création
  DateTime? lastActiveAt;         // Dernière activité
  int points;                     // Points accumulés
  int dailyQsmCount;              // Nombre de QCM créés aujourd'hui
  DateTime? dailyQsmResetDate;    // Date de réinitialisation quotidienne
  String? linkedChildId;          // ID de l'enfant (pour parents)
  String? linkedParentIds;        // IDs des parents (pour étudiants)
  String? classeId;               // ID de la classe scolaire
}
```

### Classroom (Classe)
```dart
class Classroom {
  String id;                      // ID unique
  String name;                    // Nom de la classe
  String description;             // Description
  String teacherId;               // ID de l'enseignant
  String teacherName;             // Nom de l'enseignant
  CourseCategory category;        // Catégorie (math, français, etc.)
  CourseLevel level;              // Niveau (primaire, collège, lycée)
  DateTime createdAt;             // Date de création
  String inviteCode;              // Code d'invitation
  int totalStudents;              // Nombre d'étudiants
  int totalQsmCreated;            // Nombre de QCM créés
  String? classeScolaireId;       // ID de la classe scolaire
}
```

### Course (Cours)
```dart
class Course {
  String id;                      // ID unique
  String title;                   // Titre du cours
  String description;             // Description
  String teacherId;               // ID de l'enseignant
  String subject;                 // Matière
  String? contentUrl;             // URL du contenu
  DateTime createdAt;             // Date de création
  int? duration;                  // Durée en minutes
}
```

### Question
```dart
class Question {
  String id;                      // ID unique
  String courseId;                // ID du cours
  String text;                    // Texte de la question
  List<String> options;           // Options de réponse
  int correctAnswer;              // Index de la bonne réponse
  String? explanation;            // Explication
  DateTime createdAt;             // Date de création
}
```

### QsmSession (Session de QCM)
```dart
class QsmSession {
  String id;                      // ID unique
  String userId;                  // ID de l'utilisateur
  String courseId;                // ID du cours
  int score;                      // Score obtenu
  int totalQuestions;             // Nombre total de questions
  DateTime completedAt;           // Date de complétion
  List<int> answers;              // Réponses de l'utilisateur
}
```

### Room (Salle Virtuelle)
```dart
class Room {
  String id;                      // ID unique
  String name;                    // Nom de la salle
  String teacherId;               // ID de l'enseignant
  String code;                    // Code d'accès
  DateTime createdAt;             // Date de création
  List<String> participants;      // IDs des participants
  bool isActive;                  // Salle active?
}
```

### Message
```dart
class Message {
  String id;                      // ID unique
  String conversationId;          // ID de la conversation
  String senderId;                // ID de l'expéditeur
  String content;                 // Contenu du message
  DateTime createdAt;             // Date d'envoi
  bool isRead;                    // Message lu?
}
```

### Notification
```dart
class Notification {
  String id;                      // ID unique
  String userId;                  // ID de l'utilisateur
  String title;                   // Titre
  String message;                 // Contenu
  String type;                    // Type (room_join, qsm_result, etc.)
  bool isRead;                    // Notification lue?
  DateTime createdAt;             // Date de création
  Map<String, dynamic>? data;     // Données additionnelles
}
```

### UserStatistics (Statistiques)
```dart
class UserStatistics {
  String userId;                  // ID de l'utilisateur
  int totalQsmCompleted;          // Total de QCM complétés
  double averageScore;            // Score moyen
  int totalPoints;                // Points totaux
  DateTime lastActivityAt;        // Dernière activité
}
```

---

## 🔧 Services

### AppState (Gestion d'État Centrale)
**Fichier**: `lib/services/app_state.dart`

Gère l'état global de l'application:
- Authentification de l'utilisateur
- Données utilisateur
- Notifications
- État de chargement

**Méthodes principales**:
- `init()`: Initialiser l'application
- `login()`: Connexion utilisateur
- `register()`: Inscription utilisateur
- `logout()`: Déconnexion
- `updateUser()`: Mettre à jour les données utilisateur

### AuthService (Service d'Authentification)
**Fichier**: `lib/services/auth_service.dart`

Gère l'authentification et les données utilisateur:
- Connexion/Inscription Supabase
- Gestion des sessions
- Récupération des données utilisateur
- CRUD des classes, cours, QCM

**Méthodes principales**:
- `login(email, password)`: Connexion
- `register(...)`: Inscription
- `logout()`: Déconnexion
- `restoreSession()`: Restaurer la session
- `loadUserData()`: Charger les données utilisateur
- `fetchClassroomStudents()`: Récupérer les étudiants d'une classe
- `uploadCourse()`: Uploader un cours
- `fetchTeacherWeeklyActivity()`: Activité hebdomadaire

### PointsService (Service de Points)
**Fichier**: `lib/services/points_service.dart`

Gère le système de points:
- Incrémenter les points
- Décrémenter les points
- Consulter les points

**Méthodes principales**:
- `incrementPoints(userId, points)`: Ajouter des points
- `decrementPoints(userId, points)`: Retirer des points

### MessagingService (Service de Messagerie)
**Fichier**: `lib/services/messaging_service.dart`

Gère les messages et conversations:
- Créer des conversations
- Envoyer des messages
- Récupérer les messages
- Marquer comme lu

### N8nService (Service d'Intégration)
**Fichier**: `lib/services/n8n_service.dart`

Intégration avec n8n pour:
- Webhooks
- Automatisations
- Notifications

### WebhookService (Service de Webhooks)
**Fichier**: `lib/services/webhook_service.dart`

Gère les webhooks:
- Recevoir les événements
- Traiter les données
- Mettre à jour l'application

---

## 📱 Écrans Principaux

### 1. **AuthScreen** (`auth_screen.dart`)
Écran d'authentification avec:
- Formulaire de connexion
- Formulaire d'inscription
- Sélection du rôle
- Sélection du type d'abonnement
- Illustration astronaute

### 2. **TeacherDashboard** (`teacher_dashboard.dart`)
Tableau de bord enseignant:
- Liste des classes
- Statistiques des étudiants
- Créer un QCM
- Créer une classe
- Voir les performances

### 3. **StudentDashboard** (`student_dashboard.dart`)
Tableau de bord étudiant:
- Liste des classes
- QCM disponibles
- Résultats récents
- Statistiques personnelles
- Progression académique

### 4. **ParentDashboard** (`parent_dashboard.dart`)
Tableau de bord parent:
- Suivi de l'enfant
- Résultats académiques
- Statistiques de performance
- Notifications

### 5. **AdminDashboard** (`admin_dashboard.dart`)
Tableau de bord administrateur:
- Gestion des utilisateurs
- Gestion des classes
- Gestion des cours
- Statistiques globales
- Gestion des abonnements

### 6. **QcmScreen** (`qcm_screen.dart`)
Écran de réponse aux QCM:
- Affichage des questions
- Options de réponse
- Minuteur
- Soumission des réponses
- Résultats

### 7. **ProfileScreen** (`profile_screen.dart`)
Profil utilisateur:
- Informations personnelles
- Modifier le profil
- Voir les statistiques
- Gérer les abonnements

### 8. **NotificationsScreen** (`notifications_screen.dart`)
Notifications:
- Liste des notifications
- Marquer comme lu
- Supprimer les notifications

### 9. **MessagesScreen** (`messages_screen.dart`)
Messagerie:
- Liste des conversations
- Envoyer des messages
- Voir l'historique

### 10. **Admin Screens**
- `admin_classes_management.dart`: Gérer les classes
- `admin_course_management.dart`: Gérer les cours
- `admin_students_list.dart`: Liste des étudiants
- `admin_parents_management.dart`: Gérer les parents
- `admin_structure_management.dart`: Gérer les structures

---

## 🎨 Widgets Réutilisables

### AstronautIllustration
Affiche des illustrations d'astronautes:
- Types: login, welcome, success, learning, celebration
- Animation fade-in (désactivée temporairement)
- Fallback avec icône

### SkwiltiLogo
Logo de l'application:
- Versions: normal, compact
- Couleurs personnalisables

### BottomNav
Barre de navigation inférieure:
- Navigation entre les écrans
- Icônes personnalisées
- Badges de notification

### DashboardWidgets
Widgets pour les tableaux de bord:
- Cartes de statistiques
- Graphiques
- Listes

### EmptyState
État vide:
- Icône personnalisée
- Message
- Action

### ModernFloatingButton
Bouton flottant moderne:
- Gradient
- Ombre
- Animation

### SubjectProgressCard
Carte de progression par matière:
- Barre de progression
- Pourcentage
- Couleur personnalisée

### RecentGradeCard
Carte de note récente:
- Score
- Date
- Matière

### ParentAchievementCards
Cartes de réussite pour parents:
- Badges
- Descriptions
- Animations

---

## 📦 Dépendances

### Framework & UI
- **flutter**: Framework principal
- **google_fonts**: Polices Google
- **lucide_icons**: Icônes Lucide
- **flutter_svg**: Support SVG

### État & Gestion
- **provider**: Gestion d'état
- **shared_preferences**: Stockage local

### Réseau & Backend
- **supabase_flutter**: Backend Supabase
- **dio**: Client HTTP
- **http**: Requêtes HTTP

### Fichiers & Stockage
- **file_picker**: Sélecteur de fichiers
- **path_provider**: Chemins système
- **hive_flutter**: Base de données locale

### PDF & Impression
- **pdf**: Génération PDF
- **printing**: Impression

### Utilitaires
- **intl**: Internationalisation
- **cached_network_image**: Cache d'images
- **shimmer**: Effet de chargement
- **percent_indicator**: Indicateurs de pourcentage
- **fl_chart**: Graphiques

---

## 🚀 Flux d'Utilisation

### Flux Enseignant
1. Inscription/Connexion
2. Créer une classe
3. Créer des QCM
4. Uploader des cours
5. Voir les résultats des étudiants
6. Gérer les étudiants

### Flux Étudiant
1. Inscription/Connexion
2. Rejoindre une classe (code d'invitation)
3. Voir les QCM disponibles
4. Répondre aux QCM
5. Consulter les résultats
6. Voir sa progression

### Flux Parent
1. Inscription/Connexion
2. Lier son enfant
3. Consulter les résultats
4. Voir les statistiques
5. Recevoir les notifications

### Flux Admin
1. Connexion
2. Gérer les utilisateurs
3. Gérer les classes
4. Gérer les cours
5. Voir les statistiques globales

---

## 🔒 Sécurité

### Authentification
- Supabase Auth avec email/mot de passe
- Sessions sécurisées
- Tokens JWT

### Autorisation
- Row Level Security (RLS) Supabase
- Vérification des rôles
- Contrôle d'accès par rôle

### Données
- Chiffrement en transit (HTTPS)
- Stockage sécurisé des tokens
- Validation des entrées

---

## 🐛 Dépannage

### Erreur d'Opacité
**Problème**: `'opacity >= 0.0 && opacity <= 1.0': is not true`
**Solution**: Animation désactivée dans `AstronautIllustration`

### Erreur de Connexion
**Problème**: Impossible de se connecter à Supabase
**Solution**: Vérifier la connexion réseau et les identifiants Supabase

### Erreur de Chargement des Données
**Problème**: Les données ne se chargent pas
**Solution**: Vérifier les permissions RLS et les requêtes Supabase

---

## 📞 Support

Pour toute question ou problème:
1. Consulter la documentation
2. Vérifier les logs de l'application
3. Contacter l'équipe de développement

---

**Dernière mise à jour**: Mai 2026
**Version**: 1.0.0
