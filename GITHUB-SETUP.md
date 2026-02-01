# 📦 Créer un Repository GitHub Privé - Guide Complet

## 🎯 Méthode 1 : Via l'interface GitHub (Recommandé - 3 minutes)

### Étape 1 : Créer le repository sur GitHub

1. Va sur [GitHub](https://github.com)
2. Connecte-toi à ton compte
3. Clique sur le **+** en haut à droite → **New repository**
4. Configure :
   - **Repository name** : `claim-your-agent` ou `angrymail`
   - **Description** : `AngryMail - Agent Network Platform with public profiles and forum`
   - **Visibility** : ✅ **Private** (important !)
   - **Initialize** : Ne coche RIEN (pas de README, .gitignore, ou license)
5. Clique sur **Create repository**

### Étape 2 : Préparer ton code local

Ouvre un terminal dans le dossier du projet :

```bash
cd c:\VS-Code-Clone-Git-Guillaume\claim-your-agent
```

### Étape 3 : Premier commit

```bash
# Ajouter tous les fichiers
git add .

# Créer le premier commit
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

### Étape 4 : Connecter au repository GitHub

Remplace `TON-USERNAME` par ton username GitHub :

```bash
# Ajouter le remote
git remote add origin https://github.com/TON-USERNAME/claim-your-agent.git

# Renommer la branche en main
git branch -M main

# Push vers GitHub
git push -u origin main
```

GitHub va te demander tes identifiants :
- **Username** : ton username GitHub
- **Password** : ton **Personal Access Token** (PAS ton mot de passe)

#### 🔑 Si tu n'as pas de Personal Access Token :

1. Va sur GitHub → **Settings** (ton profil)
2. Tout en bas : **Developer settings**
3. **Personal access tokens** → **Tokens (classic)**
4. **Generate new token** → **Generate new token (classic)**
5. Configure :
   - **Note** : `AngryMail Deploy`
   - **Expiration** : 90 days ou No expiration
   - **Scopes** : Coche `repo` (tout)
6. **Generate token**
7. **COPIE LE TOKEN** (tu ne le reverras plus !)
8. Utilise ce token comme password

### Étape 5 : Vérification

Va sur `https://github.com/TON-USERNAME/claim-your-agent`

Tu devrais voir tous tes fichiers ! 🎉

---

## 🎯 Méthode 2 : Via GitHub CLI (Pour les ninjas)

### Installation GitHub CLI

**Windows** :
```bash
winget install --id GitHub.cli
```

**Mac** :
```bash
brew install gh
```

**Linux** :
```bash
curl -fsSL https://cli.github.com/packages/githubcli-archive-keyring.gpg | sudo dd of=/usr/share/keyrings/githubcli-archive-keyring.gpg
echo "deb [arch=$(dpkg --print-architecture) signed-by=/usr/share/keyrings/githubcli-archive-keyring.gpg] https://cli.github.com/packages stable main" | sudo tee /etc/apt/sources.list.d/github-cli.list > /dev/null
sudo apt update
sudo apt install gh
```

### Créer le repository

```bash
cd c:\VS-Code-Clone-Git-Guillaume\claim-your-agent

# Login GitHub
gh auth login

# Créer le repo privé
gh repo create claim-your-agent --private --source=. --remote=origin --push

# C'est tout ! 🎉
```

---

## 🎯 Méthode 3 : Via Visual Studio Code

### Avec l'extension GitHub

1. Ouvre VS Code dans le dossier du projet
2. **Source Control** (icône sur la gauche) ou `Ctrl+Shift+G`
3. Clique sur **Initialize Repository**
4. Clique sur **Publish to GitHub**
5. Choisis **Publish to GitHub private repository**
6. Sélectionne les fichiers à inclure
7. Confirme
8. Login GitHub si demandé
9. Terminé ! 🎉

---

## 📝 Après la création du repository

### Inviter des collaborateurs (optionnel)

1. Va sur ton repository GitHub
2. **Settings** → **Collaborators**
3. **Add people**
4. Entre le username GitHub
5. Envoie l'invitation

### Protéger la branche main

1. Repository → **Settings** → **Branches**
2. **Add branch protection rule**
3. **Branch name pattern** : `main`
4. Coche :
   - ✅ Require pull request before merging
   - ✅ Require status checks to pass
5. **Create**

### Ajouter des secrets (pour CI/CD)

1. Repository → **Settings** → **Secrets and variables** → **Actions**
2. **New repository secret**
3. Ajoute :
   - `DB_PASS` : ton mot de passe DB
   - `ADMIN_PASS` : ton mot de passe admin
   - `SESSION_SECRET` : ta clé de session

---

## 🚀 Déployer depuis GitHub

### Sur ton VPS

```bash
# Clone le repo
git clone https://github.com/TON-USERNAME/claim-your-agent.git
cd claim-your-agent

# Ou utilise le script d'installation automatique
curl -fsSL https://raw.githubusercontent.com/TON-USERNAME/claim-your-agent/main/deploy/vps-install.sh | sudo bash
```

### Avec GitHub Actions (CI/CD automatique)

Crée `.github/workflows/deploy.yml` (optionnel, à faire plus tard).

---

## 🔄 Workflow quotidien

### Faire des modifications

```bash
# Modifier des fichiers...

# Voir ce qui a changé
git status

# Ajouter les changements
git add .

# Ou ajouter des fichiers spécifiques
git add server/index.js

# Commit
git commit -m "Fix: correction du bug de connexion"

# Push vers GitHub
git push
```

### Récupérer les dernières modifications

```bash
git pull
```

### Créer une nouvelle fonctionnalité

```bash
# Créer une branche
git checkout -b feature/nouvelle-fonctionnalite

# Faire des modifications...
git add .
git commit -m "Add: nouvelle fonctionnalité XYZ"

# Push la branche
git push -u origin feature/nouvelle-fonctionnalite

# Sur GitHub : créer une Pull Request
# Merge dans main quand prêt
```

---

## 📚 Commandes Git Utiles

```bash
# Voir l'historique
git log --oneline

# Voir les différences
git diff

# Annuler les modifications non commitées
git checkout -- fichier.js

# Revenir au commit précédent
git reset --hard HEAD~1

# Créer un tag (version)
git tag v1.0.0
git push --tags

# Cloner ton repo ailleurs
git clone https://github.com/TON-USERNAME/claim-your-agent.git
```

---

## 🎨 Personnaliser ton README sur GitHub

Le fichier [README.md](README.md) s'affichera automatiquement sur la page du repo.

Tu peux ajouter :
- Un logo
- Des badges (build status, version, etc.)
- Des screenshots
- Un GIF de démo

Exemple de badges :

```markdown
![Node Version](https://img.shields.io/badge/node-%3E%3D18.0.0-brightgreen)
![License](https://img.shields.io/badge/license-MIT-blue)
![Status](https://img.shields.io/badge/status-active-success)
```

---

## 🔒 Sécurité

### ⚠️ NE JAMAIS COMMIT :

- `.env` (déjà dans .gitignore)
- `node_modules/` (déjà dans .gitignore)
- Mots de passe ou clés API
- Certificats SSL
- Fichiers de backup (.sql, .tar.gz)

### ✅ Vérifier avant de push :

```bash
git status
# Assure-toi que .env n'apparaît PAS

# Vérifier le .gitignore
cat .gitignore
```

---

## 💡 Tips

### Changer l'URL du repository

```bash
git remote set-url origin https://github.com/NOUVEAU-USERNAME/nouveau-nom.git
```

### Problème d'authentification GitHub

Si push refuse (deprecated password) :
1. Crée un Personal Access Token (voir méthode 1)
2. Utilise le token comme mot de passe
3. Ou configure SSH :

```bash
# Générer une clé SSH
ssh-keygen -t ed25519 -C "ton-email@example.com"

# Copier la clé publique
cat ~/.ssh/id_ed25519.pub

# Ajouter sur GitHub : Settings → SSH Keys → New SSH key

# Changer l'URL du remote
git remote set-url origin git@github.com:TON-USERNAME/claim-your-agent.git
```

### Taille du repository trop grande

```bash
# Supprimer node_modules du git (si déjà commité)
git rm -r --cached node_modules
git commit -m "Remove node_modules from git"
git push
```

---

## 📞 Besoin d'aide ?

- [Documentation Git](https://git-scm.com/doc)
- [Documentation GitHub](https://docs.github.com)
- [GitHub CLI](https://cli.github.com/manual/)

---

**Ton code est maintenant sur GitHub ! 🎉**

Prochaine étape : [DEPLOYMENT.md](DEPLOYMENT.md) pour déployer sur un VPS.
