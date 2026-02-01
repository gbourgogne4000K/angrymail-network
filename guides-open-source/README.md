# 📦 Guides Open Source - Kit Complet

Ce dossier contient tous les outils nécessaires pour publier un projet privé en open source de manière sécurisée.

---

## 📁 Contenu

| Fichier | Description | Ordre d'utilisation |
|---------|-------------|---------------------|
| **GUIDE-OPEN-SOURCE.md** | 📖 Guide complet étape par étape | 1️⃣ Lis en premier |
| **CHECKLIST-OPEN-SOURCE.md** | ✅ Checklist imprimable | 2️⃣ Imprime et coche |
| **prepare-open-source.sh** | 🤖 Script automatique | 3️⃣ Exécute dans ton projet |
| **README-TEMPLATE.md** | 📝 Template de README | 4️⃣ Copie et personnalise |

---

## 🚀 Utilisation Rapide

### Pour un nouveau projet à publier :

```bash
# 1. Copie tout ce dossier dans ton projet
cp -r guides-open-source /chemin/vers/ton-projet/

# 2. Va dans ton projet
cd /chemin/vers/ton-projet

# 3. Rends le script exécutable
chmod +x guides-open-source/prepare-open-source.sh

# 4. Exécute le script
./guides-open-source/prepare-open-source.sh

# 5. Suis la checklist
# Ouvre guides-open-source/CHECKLIST-OPEN-SOURCE.md

# 6. Crée ton README
cp guides-open-source/README-TEMPLATE.md README.md
# Puis édite README.md avec les infos de ton projet
```

---

## 📚 Guide Détaillé

### Étape 1 : Préparation

Avant de commencer, assure-toi d'avoir :
- ✅ Un backup de ton projet
- ✅ La liste de toutes les clés API utilisées
- ✅ Accès aux services pour révoquer les clés
- ✅ 30-60 minutes de temps disponible

### Étape 2 : Lecture

1. Ouvre `GUIDE-OPEN-SOURCE.md`
2. Lis les sections 1-3 pour comprendre le processus
3. Imprime `CHECKLIST-OPEN-SOURCE.md`

### Étape 3 : Exécution

1. Lance `prepare-open-source.sh`
2. Réponds aux questions du script
3. Vérifie les résultats

### Étape 4 : Vérification Manuelle

Le script automatise beaucoup, mais vérifie manuellement :
- Les secrets dans le code
- Les commentaires avec infos sensibles
- Les fichiers de configuration
- L'historique Git

### Étape 5 : Documentation

1. Copie `README-TEMPLATE.md` → `README.md`
2. Remplis toutes les sections :
   - Nom du projet
   - Description
   - Features
   - Installation
   - Configuration
   - Usage
   - etc.

### Étape 6 : Publication

```bash
# Initialise Git (si nettoyage d'historique)
git init
git add .
git commit -m "Initial commit: Clean version for open source"

# Configure le remote
git remote add origin https://github.com/ton-username/ton-projet.git
git branch -M main

# Push
git push -u origin main
```

### Étape 7 : Post-Publication

1. ✅ Vérifie le repo sur GitHub
2. 🔒 **RÉVOQUE toutes les anciennes clés API**
3. ✅ Configure GitHub (description, topics, etc.)
4. ✅ Active Secret Scanning dans Security
5. ✅ Génère de nouvelles clés pour ton usage

---

## 🎯 Cas d'Usage

### Cas 1 : Petit Projet Simple

Si ton projet est petit (< 50 fichiers, peu de secrets) :

```bash
# Quick mode
./guides-open-source/prepare-open-source.sh
# Réponds "No" au nettoyage d'historique Git
# Vérifie manuellement les quelques fichiers
# Publie !
```

**Temps estimé** : 15-20 minutes

### Cas 2 : Projet Moyen

Projet avec plusieurs services, API keys, base de données :

```bash
# Full mode
./guides-open-source/prepare-open-source.sh
# Réponds "Yes" au nettoyage d'historique
# Utilise la CHECKLIST complète
# Teste en local avant de publier
```

**Temps estimé** : 30-45 minutes

### Cas 3 : Gros Projet Critique

Gros projet avec beaucoup de secrets, données sensibles :

```bash
# Manual + Script
# 1. Lis GUIDE-OPEN-SOURCE.md en entier
# 2. Fais un audit manuel complet
# 3. Lance le script pour automatiser ce qui peut l'être
# 4. Vérifie tout manuellement
# 5. Teste extensivement
# 6. Scan avec GitGuardian ou similaire
```

**Temps estimé** : 1-2 heures

---

## 🔒 Checklist de Sécurité Minimale

Avant CHAQUE publication, vérifie au minimum :

```
☐ Aucun fichier .env (sauf .env.example)
☐ .env.example avec seulement des placeholders
☐ Aucune clé API dans le code
☐ Aucun mot de passe en dur
☐ .gitignore complet
☐ Scan : grep -r "password\|api_key\|secret" .
☐ Test : clone dans nouveau dossier et teste
☐ Révoque TOUTES les anciennes clés après publication
```

---

## 📖 Ressources

### Outils de Scan

- **GitGuardian** : https://www.gitguardian.com/
- **TruffleHog** : https://github.com/trufflesecurity/truffleHog
- **git-secrets** : https://github.com/awslabs/git-secrets
- **Gitleaks** : https://github.com/gitleaks/gitleaks

### Nettoyage d'Historique

- **BFG Repo-Cleaner** : https://rtyley.github.io/bfg-repo-cleaner/
- **git-filter-repo** : https://github.com/newren/git-filter-repo

### Licenses

- **Choose a License** : https://choosealicense.com/
- **TL;DR Legal** : https://www.tldrlegal.com/

### Badges GitHub

- **Shields.io** : https://shields.io/
- **Badgen** : https://badgen.net/

---

## 💡 Tips Pro

### 1. Automatisation

Crée un alias pour réutiliser :

```bash
# Dans ton .bashrc ou .zshrc
alias prepare-oss='bash ~/guides-open-source/prepare-open-source.sh'
```

### 2. Template de Projet

Garde ce dossier dans un endroit accessible :

```bash
# Copie dans ton home
cp -r guides-open-source ~/

# Utilise pour chaque nouveau projet
cp -r ~/guides-open-source /nouveau-projet/
```

### 3. CI/CD Check

Ajoute un check automatique dans GitHub Actions :

```yaml
name: Secret Scan
on: [push, pull_request]
jobs:
  scan:
    runs-on: ubuntu-latest
    steps:
      - uses: actions/checkout@v3
      - name: Gitleaks
        uses: gitleaks/gitleaks-action@v2
```

---

## 🆘 En Cas de Problème

### J'ai poussé un secret par erreur !

1. **STOP** - Ne panique pas
2. **RÉVOQUE** la clé immédiatement
3. **SUPPRIME** le repo GitHub
4. **NETTOIE** l'historique avec BFG
5. **VÉRIFIE** les logs d'utilisation
6. **REPUBLIE** avec historique propre

Voir `GUIDE-OPEN-SOURCE.md` section "Si tu as Déjà Pushé un Secret"

### Le script ne fonctionne pas

```bash
# Vérifie les permissions
chmod +x prepare-open-source.sh

# Lance en mode debug
bash -x prepare-open-source.sh

# Ou fais manuellement en suivant GUIDE-OPEN-SOURCE.md
```

### Je ne sais pas quelle license choisir

**Pour la plupart des cas** : MIT License
- ✅ Simple et permissive
- ✅ Permet usage commercial
- ✅ Aucune obligation de partage des modifications
- ✅ Reconnue et comprise par tous

**Alternatives** :
- **Apache 2.0** : Si tu veux protection brevets
- **GPL v3** : Si tu veux forcer le partage des modifications
- **BSD 3-Clause** : Si tu veux encore plus de liberté

---

## 📊 Statistiques

### Temps Moyen par Taille de Projet

| Taille | Fichiers | Temps Préparation | Temps Total |
|--------|----------|-------------------|-------------|
| Petit | < 50 | 10 min | 20 min |
| Moyen | 50-200 | 20 min | 45 min |
| Grand | 200-1000 | 45 min | 90 min |
| Énorme | 1000+ | 2h+ | 3h+ |

---

## ✅ Validation

Ce kit de guides est complet si tu peux répondre OUI à :

- [ ] Je sais comment scanner mon projet pour des secrets
- [ ] Je sais créer un .env.example sécurisé
- [ ] Je sais nettoyer l'historique Git si nécessaire
- [ ] Je sais rédiger un README professionnel
- [ ] Je sais révoquer mes clés API après publication
- [ ] Je comprends les risques et comment les mitiger

---

## 🎓 Prochaines Étapes

Après avoir publié ton premier projet :

1. **Documente ton expérience** - Que ferais-tu différemment ?
2. **Améliore tes templates** - Personnalise selon tes besoins
3. **Partage** - Aide d'autres devs à publier en open source
4. **Contribue** - Améliore ces guides avec des PRs

---

## 📞 Support

Questions ou problèmes avec ces guides ?

- 📖 Relis `GUIDE-OPEN-SOURCE.md` en détail
- ✅ Vérifie `CHECKLIST-OPEN-SOURCE.md` point par point
- 🔍 Cherche dans les Issues GitHub
- 💬 Demande dans les Discussions

---

**Bonne publication ! 🚀**

*Ces guides sont sous license MIT - réutilise-les librement pour tous tes projets !*
