# Skwilti App - Documentation

## 📋 Table des matières

1. [Présentation du projet](#présentation-du-projet)
2. [Architecture technique](#architecture-technique)
3. [Écrans principaux](#écrans-principaux)
4. [Services et gestion d'état](#services-et-gestion-détat)
5. [Modèles de données](#modèles-de-données)
6. [Widgets réutilisables](#widgets-réutilisables)
7. [Thème et style](#thème-et-style)
8. [Authentification](#authentification)
9. [Fonctionnalités principales](#fonctionnalités-principales)
10. [Installation et développement](#installation-et-développement)

---

## 🎯 Présentation du projet

Skwilti est une application Flutter d'apprentissage interactif spécialisée dans les QCM (Questionnaires à Choix Multiples). L'application permet aux étudiants, enseignants et parents de créer, partager et résoudre des quiz éducatifs.

### 🎨 Caractéristiques principales
- **Multi-rôles** : Étudiants, Enseignants, Parents, Admin
- **Types d'abonnement** : Freemium et Premium
- **Tableau de bord** : Interface moderne et intuitive
- **Gestion de classes** : Salles virtuelles pour l'organisation
- **Progression** : Suivi détaillé des apprentissages
- **QCM interactifs** : Questions variées avec feedback immédiat

---

## 🏗️ Architecture technique

### Structure du projet
```
lib/
├── screens/           # Écrans principaux
├── widgets/           # Widgets réutilisables
├── models/            # Modèles de données
├── services/          # Services métier et API
├── theme/             # Thème et styles
└── assets/            # Images et ressources
```

### Technologies utilisées
- **Framework** : Flutter 3.x
- **Langage** : Dart 3.x
- **State Management** : Provider
- **Navigation** : Fluro (routing)
- **UI Components** : Material Design 3
- **Icons** : Lucide Icons
- **Fonts** : Google Fonts (Nunito, Inter)
- **Architecture** : MVC (Model-View-Controller)

---

## 📱 Écrans principaux

### 1. Écran d'authentification (`auth_screen.dart`)
- **Fonctionnalités** :
  - Connexion par email/mot de passe
  - Inscription avec rôle (Étudiant/Enseignant/Parent)
  - Sélection du type d'abonnement (Freemium/Premium)
  - Validation des formulaires
  - Comptes de démonstration

### 2. Dashboard Admin (`admin_dashboard.dart`)
- **Fonctionnalités** :
  - Gestion des utilisateurs avec filtres
  - Statistiques d'utilisation
  - Gestion des cours avec suppression
  - Affichage des abonnements (Freemium/Premium)
  - Navigation par onglets

### 3. Suivre un Étudiant (`admin_parents_management.dart`)
- **Fonctionnalités** :
  - Affichage des parents avec enfants liés
  - Filtres par filière, niveau et type d'abonnement (données depuis Supabase)
  - Bouton "Suivre l'enfant" pour permettre à l'admin de suivre un étudiant
  - Dialogue de confirmation avec informations de l'enfant (nom, filière, niveau)
  - Affichage du type d'abonnement (FREE/PREMIUM)
  - Interface responsive avec correction des overflow dans les dropdowns

### 4. Dashboard Étudiant (`student_dashboard.dart`)
- **Fonctionnalités** :
  - Accès aux QCM
  - Suivi de progression
  - Statistiques personnelles
  - Accès aux classes

### 5. Écran d'upload (`upload_screen.dart`)
- **Fonctionnalités** :
  - Upload de documents PDF
  - Génération automatique de QCM
  - Configuration des questions
  - Prévisualisation avant génération

### 6. Bibliothèque (`library_screen.dart`)
- **Fonctionnalités** :
  - Organisation par filière/matière
  - Accès aux cours et leçons
  - Interface de navigation intuitive

---

## 🔧 Services et gestion d'état

### AppState (`services/app_state.dart`)
- **Rôle** : Gestion centralisée de l'état de l'application
- **Authentification** : Gestion des sessions utilisateurs
- **Données utilisateur** : Classes, salles, statistiques
- **QCM** : Gestion des questions et sessions

### AuthService (`services/auth_service.dart`)
- **Authentification** : Login/inscription avec mock data
- **Gestion des rôles** : Attribution des permissions
- **Types d'abonnement** : Gestion Freemium/Premium

---

## 📊 Modèles de données

### User (`models/user.dart`)
- **Champs** : id, email, firstName, lastName, avatar, role, subscription
- **Rôles** : Enum UserRole (teacher, student, parent, admin)
- **Abonnements** : Enum SubscriptionType (free, basic, premium)

### Question (`models/question.dart`)
- **Structure** : Texte, options, réponse correcte
- **Types** : Multiple choix, vrai/faux
- **Métadonnées** : Difficulté, catégorie, points

### Course (`models/course.dart`)
- **Organisation** : Titre, description, nombre de questions
- **Progression** : Suivi d'avancement
- **Mots-clés** : Tags pour la recherche

---

## 🎨 Widgets réutilisables

### SkwiltiNav (`widgets/skwilti_nav.dart`)
- **Navigation** : Barre de navigation inférieure personnalisée
- **Items** : Configurables avec icônes et labels
- **Responsive** : Adaptation aux différentes tailles d'écran

### DashboardWidgets (`widgets/dashboard_widgets.dart`)
- **Cartes** : Widgets pour statistiques et informations
- **Graphiques** : Composants de visualisation
- **Formulaires** : Champs de saisie stylisés

### CommonWidgets (`widgets/common_widgets.dart`)
- **Boutons** : Styles cohérents pour les actions
- **Cartes** : Conteneurs réutilisables
- **Alertes** : Dialogues et messages

---

## 🎨 Thème et style

### AppTheme (`theme/app_theme.dart`)
- **Couleurs principales** : Violet (primaire), Orange (secondaire)
- **Typographie** : Google Fonts (Inter, Nunito)
- **Espacements** : Design system cohérent
- **Composants** : Surcharge des thèmes Material

### Palette de couleurs
```dart
primaryViolet     = Color(0xFF6C3EE8)    // Violet principal
primaryVioletLight = Color(0xFF9B6FF5)    // Violet clair
accentOrange      = Color(0xFFFF6B2C)     // Orange secondaire
successGreen      = Color(0xFF1D9E75)     // Vert succès
errorRed         = Color(0xFFE24B4A)     // Rouge erreur
```

---

## 🔐 Authentification

### Flux d'authentification
1. **Connexion** : Email + mot de passe → Vérification → Session
2. **Inscription** : Formulaire complet → Validation → Création compte
3. **Rôles** : Attribution automatique des permissions
4. **Abonnements** : Sélection Freemium/Premium avec fonctionnalités adaptées

### Gestion des sessions
- **Tokens** : Stockage sécurisé des sessions
- **Expiration** : Gestion automatique de la durée
- **Rafraîchissement** : Maintien de la connexion active

---

## ⚡ Fonctionnalités principales

### Gestion des QCM
- **Création** : Interface intuitive pour créer des questions
- **Import** : Upload de documents PDF avec extraction
- **Génération** : Création automatique depuis documents
- **Correction** : Validation et feedback immédiat

### Suivi de progression
- **Statistiques** : Taux de réussite, temps passé
- **Badges** : Récompenses et accomplissements
- **Historique** : Trace des activités passées
- **Objectifs** : Définition et suivi des buts

### Gestion administrative
- **Utilisateurs** : Création, modification, suppression
- **Cours** : Organisation par filière et matière
- **Permissions** : Gestion fine des accès
- **Rapports** : Export des données et statistiques

---

## 🛠️ Installation et développement

### Prérequis
- **Flutter SDK** : Version 3.0 ou supérieure
- **Dart SDK** : Version 3.0 ou supérieure
- **IDE** : VS Code (recommandé) ou Android Studio
- **Plateformes** : iOS, Android, Web, Desktop

### Installation
```bash
# Cloner le projet
git clone <repository-url>

# Installer les dépendances
flutter pub get

# Lancer l'application
flutter run
```

### Développement
```bash
# Mode développement avec rechargement à chaud
flutter run --hot

# Build pour production
flutter build apk --release
flutter build web --release
```

### Bonnes pratiques
- **Code propre** : Suivi des standards de codage Flutter
- **Widgets réutilisables** : Factorisation du code UI
- **Tests unitaires** : Couverture des fonctionnalités critiques
- **Documentation** : Commentaires et mise à jour régulière

---

## 📞 Support et maintenance

### Logs et debugging
- **Console Flutter** : Logs en temps réel
- **Firebase Crashlytics** : Suivi des erreurs
- **Analytics** : Mesure d'utilisation

### Mises à jour
- **Version sémantique** : X.Y.Z (ex: 1.2.3)
- **Mises à jour mineures** : Corrections et améliorations
- **Mises à jour majeures** : Nouvelles fonctionnalités

---

## 📈 Feuille de route

### Version 1.0.0 (Actuelle)
- ✅ Authentification multi-rôles
- ✅ Dashboard Étudiant/Enseignant/Admin
- ✅ Gestion des QCM avec upload PDF
- ✅ Système d'abonnements Freemium/Premium
- ✅ Interface responsive et moderne

### Version 1.1.0 (Prévue)
- 🔄 Amélioration des algorithmes de QCM
- 🔄 Mode hors ligne avancé
- 🔄 Notifications push
- 🔄 Chat intégré
- 🔄 Gamification avancée

### Version 2.0.0 (Futur)
- 🚀 Intelligence artificielle intégrée
- 🚀 Analyse avancée des documents
- 🚀 Personnalisation adaptative
- 🚀 Multi-langues
- 🚀 API REST complète

---

*Document mis à jour le 11 Mai 2026*
