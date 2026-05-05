# 🎓 Skwilti App

<div align="center">
  <img src="assets/images/logo.png" alt="Skwilti Logo" width="200"/>
</div>

> **Application Flutter d'apprentissage interactif spécialisée dans les QCM éducatifs**
> 
> Plateforme moderne permettant aux étudiants, enseignants et parents de créer, partager et résoudre des quiz éducatifs avec une interface intuitive et des fonctionnalités avancées.

---

## 📋 Table des matières

- [🎯 Présentation](#-présentation)
- [✨ Fonctionnalités](#-fonctionnalités)
- [🏗️ Architecture](#️-architecture)
- [🎨 Interface](#-interface)
- [👥 Rôles](#-rôles)
- [📊 Abonnements](#-abonnements)
- [🛠️ Installation](#️-installation)
- [📈 Feuille de route](#-feuille-de-route)

---

## 🎯 Présentation

Skwilti révolutionne l'apprentissage en ligne avec une approche gamifiée et interactive. Notre application transforme les documents éducatifs en expériences d'apprentissage engageantes.

### 🎨 Philosophie
- **Accessibilité** : Interface intuitive pour tous les niveaux
- **Personnalisation** : Parcours adaptés à chaque utilisateur
- **Collaboration** : Espaces partagés pour l'apprentissage collectif
- **Innovation** : Technologies modernes pour une expérience optimale

---

## ✨ Fonctionnalités

### 🎓 Pour les Étudiants
- **QCM Interactifs** : Questions variées avec feedback immédiat
- **Upload de Documents** : Import PDF et génération automatique
- **Progression Personnalisée** : Suivi détaillé des apprentissages
- **Classes Virtuelles** : Salles collaboratives avec enseignants
- **Badges et Récompenses** : Système gamifié de motivation

### 👨‍🏫 Pour les Enseignants
- **Création de QCM** : Interface complète de création
- **Gestion de Classes** : Organisation des groupes d'étudiants
- **Statistiques Avancées** : Analyse des performances
- **Partage de Ressources** : Distribution de documents
- **Suivi Individualisé** : Monitoring par étudiant

### 👨‍👩‍👧‍👦 Pour les Parents
- **Monitoring des Enfants** : Accès aux résultats et progression
- **Alertes en Temps Réel** : Notifications des activités importantes
- **Support Pédagogique** : Outils d'aide aux devoirs
- **Communication** : Messagerie avec les enseignants

### 🔧 Pour les Administrateurs
- **Gestion des Utilisateurs** : Création, modification, suppression
- **Tableau de Bord** : Statistiques globales et monitoring
- **Gestion des Cours** : Organisation par filière et matière
- **Contrôle d'Accès** : Permissions et rôles configurables

---

## 🏗️ Architecture

### 📁 Structure du projet
```
skwilti_app/
├── 📱 lib/
│   ├── 📄 screens/           # Écrans principaux
│   ├── 🧩 widgets/           # Composants réutilisables
│   ├── 📊 models/            # Modèles de données
│   ├── ⚙️ services/          # Logique métier
│   ├── 🎨 theme/             # Thème et styles
│   └── 📦 assets/            # Ressources statiques
├── 📋 pubspec.yaml         # Dépendances
├── 📖 README.md             # Documentation
└── 📚 DOCUMENTATION.md      # Documentation détaillée
```

### 🛠️ Technologies
- **Framework** : Flutter 3.x
- **Langage** : Dart 3.x
- **State Management** : Provider
- **Navigation** : Fluro (Routing)
- **UI** : Material Design 3
- **Icons** : Lucide Icons
- **Fonts** : Google Fonts
- **Architecture** : MVC + Services

---

## 🎨 Interface

### 🎨 Design System
- **Couleurs** : Palette cohérente violet/orange
- **Typographie** : Polices modernes (Inter, Nunito)
- **Espacements** : Grille responsive
- **Animations** : Transitions fluides et micro-interactions

### 📱 Responsive Design
- **Mobile** : Optimisé pour smartphones et tablettes
- **Tablette** : Interface adaptée aux écrans moyens
- **Desktop** : Expérience web complète
- **Adaptatif** : Layout dynamique selon la taille

---

## 👥 Rôles

### 🎓 Étudiant
- **Accès** : QCM illimités (Freemium) ou avancés (Premium)
- **Progression** : Statistiques détaillées et badges
- **Social** : Classes virtuelles et collaboration
- **Personnalisation** : Parcours d'apprentissage adaptés

### 👨‍🏫 Enseignant
- **Création** : QCM et contenu pédagogique
- **Gestion** : Classes et suivi des étudiants
- **Analyse** : Performance et engagement
- **Ressources** : Bibliothèque de documents partagés

### 👨‍👩‍👧‍👦 Parent
- **Monitoring** : Résultats et progression des enfants
- **Communication** : Contact avec enseignants
- **Support** : Outils d'aide aux devoirs
- **Alertes** : Notifications en temps réel

### 🔧 Administrateur
- **Supervision** : Vue d'ensemble de la plateforme
- **Gestion** : Utilisateurs, cours, permissions
- **Analytique** : Statistiques globales et rapports
- **Configuration** : Paramètres système et sécurité

---

## 📊 Abonnements

### 🎁 Freemium
- **Prix** : Gratuit
- **Fonctionnalités** :
  - QCM de base (10 questions/session)
  - Progression limitée
  - Support communautaire
  - Accès mobile

### 👑 Premium
- **Prix** : Abonnement mensuel
- **Fonctionnalités** :
  - QCM illimités
  - Analyse avancée des documents
  - Classes virtuelles illimitées
  - Statistiques détaillées
  - Support prioritaire
  - Accès multi-appareils

---

## 🛠️ Installation

### 📋 Prérequis
- **Flutter SDK** : 3.0+
- **Dart SDK** : 3.0+
- **IDE** : VS Code / Android Studio
- **Git** : Pour le versionnement

### 🚀 Lancement rapide
```bash
# 1. Cloner le projet
git clone https://github.com/your-repo/skwilti-app.git

# 2. Installer les dépendances
cd skwilti-app
flutter pub get

# 3. Lancer en développement
flutter run

# 4. Build pour production
flutter build apk --release
```

### 🐛 Résolution des problèmes
```bash
# Nettoyer le cache
flutter clean

# Mettre à jour les dépendances
flutter pub upgrade

# Vérifier les dépendances
flutter doctor
```

---

## 📈 Feuille de route

### 🎯 Version Actuelle : v1.0.0
- ✅ Interface moderne et responsive
- ✅ Authentification multi-rôles
- ✅ Système d'abonnements Freemium/Premium
- ✅ Upload PDF et génération QCM
- ✅ Dashboard administratif complet
- ✅ Classes virtuelles et collaboration

### 🚀 Version v1.1.0 (En développement)
- 🔄 Intelligence artificielle pour génération QCM
- 🔄 Mode hors ligne avancé
- 🔄 Notifications push personnalisées
- 🔄 Chat intégré pour collaboration
- 🔄 Analyse sémantique des documents

### 🌟 Version v2.0.0 (Futur)
- 🤖 Personnalisation adaptative par IA
- 🌍 Support multi-langues
- 🔗 API REST complète
- 📊 Tableau de bord avancé
- 🎮 Gamification avancée avec niveaux

---

## 👥 Équipe de Développement

### 🎨 Rôles
- **Développeurs Flutter** : Architecture et UI/UX
- **Backend Engineers** : API et services
- **UX/UI Designers** : Interface et expérience utilisateur
- **QA Engineers** : Tests et qualité
- **DevOps** : Déploiement et monitoring

### 📞 Support
- **Documentation** : `DOCUMENTATION.md` détaillée
- **Issues** : Suivi sur GitHub/GitLab
- **Discussions** : Canal de communication Slack/Discord
- **Releases** : Notes de version et changelogs

---

## 📄 Licence et Conditions

### 📜 Licence
- **Type** : MIT License
- **Utilisation** : Libre pour usage commercial et personnel
- **Modification** : Autorisée avec attribution
- **Distribution** : Libre avec conditions préservées

### 📋 Conditions d'utilisation
- **Confidentialité** : Protection des données utilisateur
- **Sécurité** : Chiffrement des informations sensibles
- **RGPD** : Conformité réglementaire européenne
- **Cookies** : Transparence sur l'utilisation des données

---

## 🤝 Contribuer

### 🛠️ Comment contribuer
1. **Forker** le projet
2. **Créer** une branche de fonctionnalité
3. **Développer** avec tests unitaires
4. **Soumettre** une Pull Request
5. **Documenter** les changements

### 🎯 Bonnes pratiques
- **Code Style** : Suivre les standards Flutter/Dart
- **Tests** : Couverture minimale de 80%
- **Documentation** : Commentaires clairs et précis
- **Performance** : Optimisation pour mobile et web

---

<div align="center">

### 🚀 **Rejoignez l'aventure Skwilti !**

**[📱 Télécharger l'app]** | **[🌐 Site web]** | **[📖 Documentation]** | **[🐛 Issues]**

---

*Made with ❤️ by the Skwilti Team*  
*Dernière mise à jour : 5 Mai 2026*
