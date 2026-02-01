#!/bin/bash
# Script pour initialiser Git et préparer le premier commit

echo "🚀 Initialisation du repository Git..."

# Initialiser Git
git init

# Ajouter tous les fichiers
git add .

# Premier commit
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
- Complete deployment docs"

echo "✅ Repository Git initialisé avec succès!"
echo ""
echo "Prochaines étapes:"
echo "1. Crée un repository sur GitHub"
echo "2. Exécute: git remote add origin https://github.com/TON-USERNAME/claim-your-agent.git"
echo "3. Exécute: git branch -M main"
echo "4. Exécute: git push -u origin main"
