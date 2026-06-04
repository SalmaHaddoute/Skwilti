# Instructions pour pousser sur GitHub

## Étape 1 : Ajouter le dépôt distant GitHub

Remplacez `<votre-username>` et `<nom-du-repo>` par vos informations GitHub :

```bash
git remote add origin https://github.com/<votre-username>/<nom-du-repo>.git
```

Exemple :
```bash
git remote add origin https://github.com/johndoe/skwilti-app.git
```

## Étape 2 : Vérifier la branche actuelle

```bash
git branch
```

Si vous n'êtes pas sur la branche `main`, créez-la :
```bash
git branch -M main
```

## Étape 3 : Ajouter tous les fichiers modifiés

```bash
git add .
```

## Étape 4 : Créer un commit avec un message descriptif

```bash
git commit -m "feat: Ajout sauvegarde automatique QCM générés par prompt"
```

Ou un message plus détaillé :
```bash
git commit -m "feat: Sauvegarde automatique des QCM générés par prompt dans Supabase

- Ajout méthode saveGeneratedQcm() dans qcm_service.dart
- Détection et sauvegarde automatique dans qcm_screen.dart
- Ajout champ courseId dans qsm_session.dart
- Mise à jour app_state.dart pour gérer courseId
- Les QCM générés par prompt sont maintenant persistés en base"
```

## Étape 5 : Pousser sur GitHub

```bash
git push -u origin main
```

Si le dépôt existe déjà et que vous voulez forcer la mise à jour :
```bash
git push -u origin main --force
```

⚠️ **Attention** : `--force` écrase l'historique distant. À utiliser uniquement si vous êtes sûr.

## En cas d'erreur d'authentification

Si GitHub demande une authentification, vous devez :

1. **Utiliser un Personal Access Token (PAT)** au lieu du mot de passe
2. Allez sur GitHub → Settings → Developer settings → Personal access tokens → Tokens (classic)
3. Générez un nouveau token avec les permissions `repo`
4. Utilisez ce token comme mot de passe lors du push

Ou configurez SSH :
```bash
git remote set-url origin git@github.com:<votre-username>/<nom-du-repo>.git
```

## Commandes complètes (copier-coller)

```bash
# Remplacez par votre URL GitHub
git remote add origin https://github.com/<votre-username>/<nom-du-repo>.git

# Vérifier la branche
git branch -M main

# Ajouter tous les fichiers
git add .

# Commit
git commit -m "feat: Sauvegarde automatique des QCM générés par prompt"

# Push
git push -u origin main
```
