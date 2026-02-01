# 🚀 Commandes à Exécuter - Setup GitHub

## Étape 1 : Configuration de Git (à faire une seule fois)

Ouvre un terminal et exécute :

```bash
# Configure ton nom (remplace par ton vrai nom)
git config --global user.name "Guillaume"

# Configure ton email (utilise l'email de ton compte GitHub)
git config --global user.email "ton-email@example.com"

# Vérifie la configuration
git config --global --list
```

---

## Étape 2 : Premier Commit

```bash
# Va dans le dossier du projet
cd c:\VS-Code-Clone-Git-Guillaume\claim-your-agent

# Ajoute tous les fichiers
git add .

# Crée le premier commit
git commit -m "Initial commit: AngryMail - Agent Network Platform

Features:
- Public agent profiles (Twitter/X style)
- Community forum (Reddit style)
- Claims system
- Admin dashboard
- Full REST API
- Agent hierarchy (parent/sub-agents)
- MySQL database with triggers
- Docker support
- Complete deployment documentation"
```

---

## Étape 3 : Créer le Repository GitHub

### Option A : Via GitHub.com (Simple)

1. Va sur https://github.com/new
2. **Repository name** : `claim-your-agent`
3. **Visibility** : ✅ **Private**
4. **Ne coche rien** d'autre (pas de README, gitignore, etc.)
5. Clique **Create repository**

### Option B : Via GitHub CLI (Plus rapide)

```bash
# Installe GitHub CLI si pas déjà fait
# Windows :
winget install --id GitHub.cli

# Puis login et création :
gh auth login
gh repo create claim-your-agent --private --source=. --remote=origin --push
```

---

## Étape 4 : Push vers GitHub (si Option A)

Remplace `TON-USERNAME` par ton username GitHub :

```bash
# Ajoute le remote
git remote add origin https://github.com/TON-USERNAME/claim-your-agent.git

# Renomme la branche
git branch -M main

# Push
git push -u origin main
```

Quand GitHub demande le mot de passe, utilise un **Personal Access Token** :
1. Va sur GitHub → Settings → Developer settings → Personal access tokens → Tokens (classic)
2. Generate new token (classic)
3. Coche "repo" (tout)
4. Copy le token
5. Colle-le comme mot de passe

---

## Étape 5 : Vérification

Va sur ton repository :
```
https://github.com/TON-USERNAME/claim-your-agent
```

Tu devrais voir tous tes fichiers ! 🎉

---

## 🔄 Commandes Futures

### Faire des modifications

```bash
# Après avoir modifié des fichiers
git add .
git commit -m "Description de tes changements"
git push
```

### Récupérer les modifications

```bash
git pull
```

### Voir le statut

```bash
git status
```

### Voir l'historique

```bash
git log --oneline
```

---

## 🚀 Déploiement VPS

Une fois sur GitHub, sur ton VPS :

```bash
# Installation automatique (recommandé)
curl -fsSL https://raw.githubusercontent.com/TON-USERNAME/claim-your-agent/main/deploy/vps-install.sh | sudo bash

# Ou clone manuel
git clone https://github.com/TON-USERNAME/claim-your-agent.git
cd claim-your-agent
# Puis suis DEPLOYMENT.md
```

---

## 📞 Besoin d'aide ?

Consulte :
- [GITHUB-SETUP.md](GITHUB-SETUP.md) - Guide détaillé GitHub
- [DEPLOYMENT.md](DEPLOYMENT.md) - Guide de déploiement VPS
- [GUIDE-FR.md](GUIDE-FR.md) - Guide complet du projet
