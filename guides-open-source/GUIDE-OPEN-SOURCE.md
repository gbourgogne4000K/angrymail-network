# 🔓 Guide Complet : Passer un Projet Privé en Open Source

Ce guide te permet de nettoyer et publier n'importe quel projet en toute sécurité, sans leaker de données sensibles.

---

## 📋 Table des Matières

1. [Checklist de Sécurité](#1-checklist-de-sécurité)
2. [Audit et Nettoyage](#2-audit-et-nettoyage)
3. [Créer les Fichiers de Configuration Exemple](#3-créer-les-fichiers-de-configuration-exemple)
4. [Nettoyer l'Historique Git](#4-nettoyer-lhistorique-git)
5. [Générer le README](#5-générer-le-readme)
6. [Ajouter la License](#6-ajouter-la-license)
7. [Push vers GitHub](#7-push-vers-github)
8. [Vérification Finale](#8-vérification-finale)

---

## 1. Checklist de Sécurité

### ✅ Fichiers à SUPPRIMER ou EXCLURE

Copie ce checklist dans un fichier texte et coche au fur et à mesure :

```
☐ .env (TOUS les fichiers .env*)
☐ .env.local
☐ .env.production
☐ .env.development
☐ config.json (avec secrets)
☐ credentials.json
☐ secrets.yaml
☐ *.key (clés privées)
☐ *.pem (certificats)
☐ *.p12 (certificats)
☐ id_rsa (clés SSH)
☐ service-account.json (GCP)
☐ .aws/credentials
☐ firebase-adminsdk-*.json
☐ .npmrc (si contient tokens)
☐ .pypirc (si contient tokens)
☐ docker-compose.override.yml (si secrets)
☐ Fichiers de backup (*.sql, *.dump, *.bak)
☐ Logs personnels (*.log avec données)
☐ node_modules/ (toujours exclure)
☐ vendor/ (PHP)
☐ venv/ ou env/ (Python)
☐ .idea/ (IntelliJ)
☐ .vscode/settings.json (si secrets)
☐ thumbs.db, .DS_Store
```

### 🔍 Données Sensibles à Chercher

```
☐ Clés API (OpenAI, AWS, Google, Stripe, etc.)
☐ Tokens (GitHub, npm, PyPI, etc.)
☐ Mots de passe en dur
☐ URLs de base de données avec credentials
☐ Secrets JWT
☐ Clés de chiffrement
☐ Adresses email personnelles
☐ Noms de domaine internes
☐ IPs de serveurs privés
☐ Noms d'utilisateurs réels
☐ Chemins absolus vers ton système (/Users/toi/...)
```

---

## 2. Audit et Nettoyage

### Étape 1 : Scanner le Projet

Crée ce script `scan-secrets.sh` :

```bash
#!/bin/bash
# scan-secrets.sh - Détecte les secrets potentiels

echo "🔍 Scan de secrets dans le projet..."
echo ""

# Patterns de secrets courants
patterns=(
    "password"
    "api[_-]?key"
    "secret"
    "token"
    "private[_-]?key"
    "access[_-]?key"
    "client[_-]?secret"
    "sk-[a-zA-Z0-9]+"  # OpenAI
    "ghp_[a-zA-Z0-9]+"  # GitHub
    "AKIA[0-9A-Z]{16}"  # AWS
    "AIza[0-9A-Za-z\\-_]{35}"  # Google
)

for pattern in "${patterns[@]}"; do
    echo "Recherche : $pattern"
    grep -r -i -n "$pattern" . \
        --exclude-dir=node_modules \
        --exclude-dir=.git \
        --exclude-dir=vendor \
        --exclude-dir=venv \
        --exclude="*.log" \
        --exclude="scan-secrets.sh" \
        --color=always | head -20
    echo ""
done

echo "✅ Scan terminé. Vérifie les résultats ci-dessus."
```

Exécute :
```bash
chmod +x scan-secrets.sh
./scan-secrets.sh > scan-results.txt
```

### Étape 2 : Vérifier les Fichiers Git

```bash
# Liste tous les fichiers trackés par git
git ls-files

# Cherche les fichiers .env dans l'historique
git log --all --full-history -- "*.env*"

# Cherche les secrets dans l'historique
git log -p | grep -i "api.key\|password\|secret" | head -50
```

### Étape 3 : Nettoyer les Fichiers

Pour chaque fichier avec des secrets :

**Option A : Supprimer le fichier**
```bash
git rm --cached fichier-avec-secrets.txt
rm fichier-avec-secrets.txt
```

**Option B : Remplacer les secrets par des placeholders**

Exemple dans `config.js` :
```javascript
// AVANT (À NE PAS PUBLIER)
const config = {
  apiKey: 'sk-proj-abc123xyz789',
  dbPassword: 'MonMotDePasse123!'
};

// APRÈS (Sécurisé pour open source)
const config = {
  apiKey: process.env.API_KEY || 'your_api_key_here',
  dbPassword: process.env.DB_PASSWORD || 'your_db_password'
};
```

### Étape 4 : Créer/Compléter .gitignore

```bash
# Crée ou ajoute à .gitignore
cat >> .gitignore << 'EOF'

# Secrets et environnement
.env
.env.*
!.env.example
*.key
*.pem
*.p12
config.local.js
secrets.json
credentials.json

# Clés SSH
id_rsa
id_rsa.pub
id_ed25519
id_ed25519.pub

# AWS
.aws/

# Google Cloud
*-service-account.json
gcloud-key.json

# Firebase
firebase-adminsdk-*.json

# Dependencies
node_modules/
vendor/
venv/
env/
__pycache__/

# Logs
*.log
logs/

# OS
.DS_Store
Thumbs.db

# IDE
.idea/
.vscode/settings.json
*.swp
*.swo

# Build
dist/
build/
*.egg-info/

# Backups
*.bak
*.sql
*.dump
*.sqlite

# Local development
docker-compose.override.yml
EOF
```

---

## 3. Créer les Fichiers de Configuration Exemple

Pour chaque fichier de config avec secrets, crée une version `.example` :

### Exemple : .env → .env.example

```bash
# Si tu as un .env, crée .env.example
cp .env .env.example
```

Puis édite `.env.example` pour remplacer les vraies valeurs :

```env
# .env.example - Configuration template

# API Keys
OPENAI_API_KEY=sk-your_openai_key_here
ANTHROPIC_API_KEY=sk-ant-your_anthropic_key_here
STRIPE_SECRET_KEY=sk_test_your_stripe_key_here

# Database
DB_HOST=localhost
DB_PORT=5432
DB_USER=your_db_user
DB_PASSWORD=your_secure_password
DB_NAME=your_database_name

# Application
PORT=3000
NODE_ENV=development
SESSION_SECRET=generate_a_random_secret_32_chars_minimum

# OAuth
GOOGLE_CLIENT_ID=your_google_client_id.apps.googleusercontent.com
GOOGLE_CLIENT_SECRET=your_google_client_secret

# Email
SMTP_HOST=smtp.gmail.com
SMTP_PORT=587
SMTP_USER=your_email@gmail.com
SMTP_PASS=your_app_password

# Optional Features
ENABLE_ANALYTICS=false
ENABLE_NOTIFICATIONS=true
```

**Règles pour .env.example** :
- ✅ Structure identique au vrai .env
- ✅ Commentaires pour expliquer chaque variable
- ✅ Valeurs par défaut ou placeholders clairs
- ✅ Exemples de formats (URLs, IDs, etc.)
- ❌ JAMAIS de vraies clés ou secrets

---

## 4. Nettoyer l'Historique Git

⚠️ **ATTENTION** : Nettoyer l'historique Git est IRRÉVERSIBLE !

### Option A : Nouveau Repo Git (Recommandé)

La méthode la plus sûre :

```bash
# 1. Sauvegarde le dossier actuel
cp -r mon-projet mon-projet-backup

# 2. Supprime le .git actuel
cd mon-projet
rm -rf .git

# 3. Initialise un nouveau repo
git init
git add .
git commit -m "Initial commit: Clean version for open source"
```

### Option B : Nettoyer avec BFG Cleaner (Avancé)

Si tu veux garder l'historique mais supprimer des secrets :

```bash
# 1. Clone BFG
wget https://repo1.maven.org/maven2/com/madgag/bfg/1.14.0/bfg-1.14.0.jar

# 2. Crée un fichier avec les patterns à supprimer
cat > secrets.txt << EOF
password
api_key
secret_key
sk-proj-
ghp_
EOF

# 3. Nettoie l'historique
java -jar bfg-1.14.0.jar --replace-text secrets.txt mon-projet

# 4. Force cleanup
cd mon-projet
git reflog expire --expire=now --all
git gc --prune=now --aggressive

# 5. Vérifie
git log -p | grep -i "api.key\|password"
```

### Option C : git-filter-repo (Moderne)

```bash
# Installe git-filter-repo
pip install git-filter-repo

# Supprime un fichier de tout l'historique
git filter-repo --path .env --invert-paths

# Supprime tous les .env*
git filter-repo --path-glob '.env*' --invert-paths

# Remplace du texte dans l'historique
git filter-repo --replace-text <(echo "sk-proj-abc123==><API_KEY_REMOVED>")
```

---

## 5. Générer le README

Utilise ce template pour créer un README professionnel :

```markdown
# 🚀 [Nom du Projet]

[![License](https://img.shields.io/badge/license-MIT-blue.svg)](LICENSE)
[![Node Version](https://img.shields.io/badge/node-%3E%3D18.0.0-brightgreen)](https://nodejs.org)
[![PRs Welcome](https://img.shields.io/badge/PRs-welcome-brightgreen.svg)](pulls)

> [Une phrase accrocheuse qui décrit ton projet]

[2-3 phrases qui expliquent ce que fait le projet, pourquoi il existe, et pour qui]

---

## ✨ Features

- 🎯 Feature principale 1
- 🔥 Feature principale 2
- 💡 Feature principale 3
- 🚀 Feature principale 4

---

## 🚀 Quick Start

### Prerequisites

- Node.js 18+ (ou autre)
- [Autre dépendance]

### Installation

\`\`\`bash
# Clone le repository
git clone https://github.com/username/project-name.git
cd project-name

# Install dependencies
npm install

# Configure environment
cp .env.example .env
# Édite .env avec tes valeurs

# Run
npm start
\`\`\`

---

## 📖 Documentation

### Configuration

Crée un fichier \`.env\` basé sur \`.env.example\` :

\`\`\`env
API_KEY=your_api_key_here
DATABASE_URL=your_database_url
\`\`\`

### Usage

\`\`\`bash
# Development
npm run dev

# Production
npm start

# Tests
npm test
\`\`\`

---

## 🏗️ Architecture

\`\`\`
project-name/
├── src/
│   ├── components/
│   ├── services/
│   └── utils/
├── tests/
├── docs/
├── .env.example
└── README.md
\`\`\`

---

## 🔧 Tech Stack

- **Backend**: Node.js, Express
- **Database**: PostgreSQL, Redis
- **Frontend**: React, TailwindCSS
- **Other**: Docker, Jest

---

## 🤝 Contributing

Contributions are welcome! Please:

1. Fork the repository
2. Create a feature branch (\`git checkout -b feature/AmazingFeature\`)
3. Commit your changes (\`git commit -m 'Add some AmazingFeature'\`)
4. Push to the branch (\`git push origin feature/AmazingFeature\`)
5. Open a Pull Request

---

## 📝 License

This project is licensed under the MIT License - see the [LICENSE](LICENSE) file for details.

---

## 🙏 Acknowledgments

- [Librairie ou ressource utilisée]
- [Inspiration ou crédit]

---

## 📞 Support

- 📖 [Documentation](docs/)
- 🐛 [Report Issues](issues)
- 💬 [Discussions](discussions)

---

**Built with ❤️ by [Ton Nom]**
```

---

## 6. Ajouter la License

### License MIT (Recommandée pour Open Source)

Crée `LICENSE` :

```
MIT License

Copyright (c) 2025 [Ton Nom]

Permission is hereby granted, free of charge, to any person obtaining a copy
of this software and associated documentation files (the "Software"), to deal
in the Software without restriction, including without limitation the rights
to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
copies of the Software, and to permit persons to whom the Software is
furnished to do so, subject to the following conditions:

The above copyright notice and this permission notice shall be included in all
copies or substantial portions of the Software.

THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE
SOFTWARE.
```

### Autres Licenses Populaires

- **Apache 2.0** : Plus protecteur contre les brevets
- **GPL v3** : Oblige les modifications à rester open source
- **BSD 3-Clause** : Simple et permissive

Choisis sur : https://choosealicense.com/

---

## 7. Push vers GitHub

### Étape 1 : Vérification Finale Avant Push

```bash
# Vérifie qu'aucun secret n'est commité
git diff --cached | grep -i "api.key\|password\|secret\|token"

# Liste tous les fichiers qui seront pushés
git ls-files

# Vérifie .gitignore
cat .gitignore

# Test : essaie d'ajouter .env (doit être ignoré)
touch .env
git add .env
# Si ça dit "nothing to commit", c'est bon !
```

### Étape 2 : Crée le Repo GitHub

1. Va sur https://github.com/new
2. **Repository name** : `nom-du-projet`
3. **Description** : [Ta description en 1 ligne]
4. **Visibility** : ✅ **Public**
5. **Ne coche rien** d'autre
6. Clique **Create repository**

### Étape 3 : Push

```bash
git remote add origin https://github.com/ton-username/nom-du-projet.git
git branch -M main
git push -u origin main
```

---

## 8. Vérification Finale

### Checklist Post-Publication

```
☐ Visite le repo sur GitHub
☐ Vérifie qu'aucun .env n'est visible
☐ Cherche "password" dans la recherche GitHub du repo
☐ Cherche "api_key" dans la recherche GitHub du repo
☐ Cherche "secret" dans la recherche GitHub du repo
☐ Vérifie que .env.example existe
☐ Vérifie que LICENSE existe
☐ Vérifie que README.md s'affiche bien
☐ Clone le repo dans un nouveau dossier et teste
☐ Vérifie les commits dans l'historique
☐ Lance un scan de sécurité
```

### Scan de Sécurité avec GitHub

GitHub détecte automatiquement les secrets. Vérifie :

1. Repository → **Security** → **Secret scanning**
2. S'il y a des alertes, **SUPPRIME LE REPO** et recommence

### Scan avec GitGuardian (Gratuit)

```bash
# Installe GitGuardian CLI
pip install ggshield

# Scan le repo
ggshield secret scan repo .
```

### Révoque les Clés (Par Précaution)

Si tu avais des clés dans l'ancien code :

- **OpenAI** : https://platform.openai.com/api-keys → Révoque
- **GitHub** : Settings → Developer settings → Tokens → Révoque
- **Stripe** : Dashboard → Developers → API keys → Roll
- **AWS** : IAM → Access keys → Deactivate
- **Google Cloud** : Credentials → Delete

Puis génère de nouvelles clés.

---

## 🎯 Template de Description GitHub

Utilise ce format pour la description de ton repo :

### Format Court (Max 160 caractères)
```
[Emoji] [Action Verb] [Ce que ça fait] [Tech Stack]. [Caractéristique unique]
```

### Exemples

**Pour une API** :
```
🚀 Fast & lightweight REST API for [use case] built with Node.js & Express. Features JWT auth, rate limiting & OpenAPI docs.
```

**Pour une Web App** :
```
💼 Modern task management app with real-time collaboration. Built with React, Node.js, WebSockets & PostgreSQL.
```

**Pour un CLI Tool** :
```
⚡ CLI tool to automate [task]. Fast, zero-config, works with [platform]. Written in Go.
```

**Pour une Library** :
```
📦 Lightweight [type] library for [language]. Zero dependencies, TypeScript support, <5KB minified.
```

**Pour le projet actuel (exemple)** :
```
🔥 AI agent social network platform with Twitter/X profiles & Reddit forums. Node.js, Express, MySQL. Self-hosted.
```

---

## 🔄 Workflow Récapitulatif

```bash
# 1. AUDIT
./scan-secrets.sh
git log -p | grep -i "password\|secret\|api"

# 2. NETTOYER
rm .env
git rm --cached .env
echo ".env" >> .gitignore

# 3. CRÉER .env.example
cp .env .env.example
# Éditer pour remplacer les secrets

# 4. NOUVEAU GIT (si historique compromis)
rm -rf .git
git init

# 5. COMMIT
git add .
git commit -m "Initial commit: Clean version for open source"

# 6. LICENSE & README
# Créer LICENSE et README.md

# 7. VÉRIFICATION
git diff --cached | grep -i "api.key\|password"
git ls-files | grep ".env"

# 8. PUSH
git remote add origin https://github.com/username/repo.git
git branch -M main
git push -u origin main

# 9. SCAN GITHUB
# Vérifie Security → Secret scanning

# 10. RÉVOQUE LES CLÉS
# Révoque toutes les anciennes clés API
```

---

## 🆘 Si tu as Déjà Pusé un Secret

**NE PANIQUE PAS**, mais agis vite :

### 1. Révoque IMMÉDIATEMENT la Clé

Va sur le service (OpenAI, AWS, etc.) et révoque la clé.

### 2. Supprime le Repo GitHub

Settings → Danger Zone → Delete this repository

### 3. Nettoie l'Historique

Utilise BFG ou git-filter-repo (voir section 4).

### 4. Recrée le Repo

Avec l'historique nettoyé.

### 5. Vérifie les Logs

Vérifie si la clé a été utilisée (logs API, facturation, etc.).

---

## 📚 Ressources Utiles

- **GitGuardian** : https://www.gitguardian.com/ (scan gratuit)
- **git-secrets** : https://github.com/awslabs/git-secrets
- **BFG Repo-Cleaner** : https://rtyley.github.io/bfg-repo-cleaner/
- **Choose a License** : https://choosealicense.com/
- **GitHub Badges** : https://shields.io/
- **.gitignore Templates** : https://github.com/github/gitignore

---

## ✅ Checklist Finale Avant Publication

```
SÉCURITÉ
☐ Aucun .env dans le repo
☐ .env.example créé avec placeholders
☐ .gitignore complet
☐ Aucune clé API dans le code
☐ Aucun mot de passe en dur
☐ Aucune URL avec credentials
☐ Aucun chemin absolu personnel
☐ Historique Git nettoyé
☐ Scan de sécurité passé

DOCUMENTATION
☐ README.md complet
☐ LICENSE ajoutée (MIT recommandé)
☐ .env.example documenté
☐ Installation testée
☐ Description GitHub remplie
☐ Topics/tags ajoutés

POST-PUBLICATION
☐ Repo cloné et testé ailleurs
☐ Secret scanning GitHub vérifié
☐ Anciennes clés révoquées
☐ Nouvelles clés générées
☐ Documentation à jour
```

---

**Félicitations ! Ton projet est maintenant prêt pour l'open source ! 🎉**

---

*Guide créé pour passer sereinement d'un projet privé à un projet open source sécurisé.*
