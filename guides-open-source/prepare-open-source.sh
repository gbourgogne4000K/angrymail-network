#!/bin/bash

#############################################
# Script de Préparation Open Source
# Nettoie automatiquement un projet pour publication
#############################################

set -e

echo "╔═══════════════════════════════════════════════╗"
echo "║  Préparation Open Source - Nettoyage Auto    ║"
echo "╚═══════════════════════════════════════════════╝"
echo ""

# Couleurs
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# Variables
PROJECT_DIR=$(pwd)
BACKUP_DIR="${PROJECT_DIR}_backup_$(date +%Y%m%d_%H%M%S)"

# Fonctions
print_success() { echo -e "${GREEN}✓${NC} $1"; }
print_warning() { echo -e "${YELLOW}⚠${NC} $1"; }
print_error() { echo -e "${RED}✗${NC} $1"; }
print_info() { echo -e "${BLUE}ℹ${NC} $1"; }

# Étape 1 : Backup
echo "📦 Étape 1/8 : Création d'une sauvegarde..."
cp -r "$PROJECT_DIR" "$BACKUP_DIR"
print_success "Backup créé : $BACKUP_DIR"
echo ""

# Étape 2 : Scan des secrets
echo "🔍 Étape 2/8 : Scan des secrets potentiels..."
echo ""

SECRETS_FOUND=0

# Patterns à rechercher
declare -a patterns=(
    "password"
    "api[_-]?key"
    "secret"
    "token"
    "private[_-]?key"
    "sk-[a-zA-Z0-9]{20,}"
    "ghp_[a-zA-Z0-9]{36}"
    "AKIA[0-9A-Z]{16}"
)

for pattern in "${patterns[@]}"; do
    results=$(grep -r -i -n "$pattern" . \
        --exclude-dir=node_modules \
        --exclude-dir=.git \
        --exclude-dir=vendor \
        --exclude-dir=venv \
        --exclude-dir=env \
        --exclude="*.log" \
        --exclude="prepare-open-source.sh" \
        --exclude=".env.example" 2>/dev/null || true)

    if [ ! -z "$results" ]; then
        print_warning "Trouvé pattern '$pattern' :"
        echo "$results" | head -5
        SECRETS_FOUND=$((SECRETS_FOUND + 1))
        echo ""
    fi
done

if [ $SECRETS_FOUND -gt 0 ]; then
    print_error "$SECRETS_FOUND patterns suspects trouvés !"
    echo ""
    read -p "Continuer quand même ? (y/N) " -n 1 -r
    echo ""
    if [[ ! $REPLY =~ ^[Yy]$ ]]; then
        exit 1
    fi
else
    print_success "Aucun secret évident trouvé"
fi
echo ""

# Étape 3 : Vérifier .gitignore
echo "📝 Étape 3/8 : Vérification du .gitignore..."

if [ ! -f ".gitignore" ]; then
    print_warning ".gitignore n'existe pas, création..."
    cat > .gitignore << 'EOF'
# Environment
.env
.env.*
!.env.example

# Dependencies
node_modules/
vendor/
venv/
env/

# Secrets
*.key
*.pem
*.p12
credentials.json
secrets.json

# Logs
*.log
logs/

# OS
.DS_Store
Thumbs.db

# IDE
.idea/
.vscode/
*.swp

# Build
dist/
build/

# Backups
*.bak
*.sql
*.dump
EOF
    print_success ".gitignore créé"
else
    print_success ".gitignore existe"
fi
echo ""

# Étape 4 : Chercher et traiter les .env
echo "🔒 Étape 4/8 : Traitement des fichiers .env..."

ENV_FILES=$(find . -name ".env*" -not -name ".env.example" -not -path "*/node_modules/*" -not -path "*/.git/*" 2>/dev/null || true)

if [ ! -z "$ENV_FILES" ]; then
    echo "$ENV_FILES" | while read envfile; do
        print_warning "Trouvé : $envfile"

        # Créer .env.example si n'existe pas
        examplefile="${envfile}.example"
        if [ ! -f "$examplefile" ]; then
            print_info "Création de ${examplefile}..."

            # Copie et remplace les valeurs
            cat "$envfile" | sed -E \
                -e 's/=.+$/=your_value_here/' \
                -e 's/(API_KEY=).*/\1your_api_key_here/' \
                -e 's/(SECRET=).*/\1your_secret_here/' \
                -e 's/(PASSWORD=).*/\1your_password_here/' \
                -e 's/(TOKEN=).*/\1your_token_here/' \
                > "$examplefile"

            print_success "${examplefile} créé"
        fi

        # Supprimer le .env original de Git
        git rm --cached "$envfile" 2>/dev/null || true
        print_success "$envfile retiré de Git"
    done
else
    print_info "Aucun fichier .env trouvé"
fi
echo ""

# Étape 5 : Vérifier LICENSE
echo "📄 Étape 5/8 : Vérification de la LICENSE..."

if [ ! -f "LICENSE" ]; then
    print_warning "LICENSE n'existe pas, création (MIT)..."

    YEAR=$(date +%Y)
    read -p "Ton nom pour la license ? " AUTHOR_NAME

    cat > LICENSE << EOF
MIT License

Copyright (c) $YEAR $AUTHOR_NAME

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
EOF
    print_success "LICENSE MIT créée"
else
    print_success "LICENSE existe"
fi
echo ""

# Étape 6 : Vérifier README
echo "📖 Étape 6/8 : Vérification du README..."

if [ ! -f "README.md" ]; then
    print_warning "README.md n'existe pas"
    echo ""
    print_info "Utilise le template dans GUIDE-OPEN-SOURCE.md section 5"
else
    print_success "README.md existe"
fi
echo ""

# Étape 7 : Nettoyer l'historique Git (optionnel)
echo "🗑️  Étape 7/8 : Nettoyage de l'historique Git..."
echo ""
print_warning "ATTENTION : Cette étape est IRRÉVERSIBLE !"
echo ""
read -p "Veux-tu réinitialiser l'historique Git ? (y/N) " -n 1 -r
echo ""

if [[ $REPLY =~ ^[Yy]$ ]]; then
    print_info "Sauvegarde de l'ancien .git..."
    mv .git .git_backup_$(date +%Y%m%d_%H%M%S)

    print_info "Initialisation d'un nouveau repo Git..."
    git init
    git add .
    git commit -m "Initial commit: Clean version for open source"

    print_success "Historique Git nettoyé"
else
    print_info "Historique Git conservé"
fi
echo ""

# Étape 8 : Résumé et recommandations
echo "✅ Étape 8/8 : Résumé"
echo ""
echo "╔═══════════════════════════════════════════════╗"
echo "║              Nettoyage Terminé !              ║"
echo "╚═══════════════════════════════════════════════╝"
echo ""
print_success "Backup créé : $BACKUP_DIR"
print_success ".gitignore configuré"
print_success "Fichiers .env traités"
print_success "LICENSE ajoutée"
echo ""
print_warning "PROCHAINES ÉTAPES :"
echo ""
echo "1. 📝 Vérifie manuellement les fichiers suivants :"
echo "   - README.md (ajoute description, usage, etc.)"
echo "   - .env.example (vérifie que toutes les valeurs sont des placeholders)"
echo "   - CODE_OF_CONDUCT.md (optionnel)"
echo "   - CONTRIBUTING.md (optionnel)"
echo ""
echo "2. 🔍 Lance un scan final :"
echo "   git diff --cached | grep -i 'password\\|secret\\|api'"
echo ""
echo "3. 🧪 Test :"
echo "   - Clone dans un nouveau dossier"
echo "   - Vérifie que ça fonctionne avec .env.example"
echo ""
echo "4. 🚀 Push vers GitHub :"
echo "   git remote add origin https://github.com/username/repo.git"
echo "   git branch -M main"
echo "   git push -u origin main"
echo ""
echo "5. 🔒 Révoque les anciennes clés API !"
echo ""
print_info "Guide complet : GUIDE-OPEN-SOURCE.md"
echo ""
