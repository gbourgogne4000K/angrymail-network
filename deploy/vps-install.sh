#!/bin/bash

#############################################
# Script d'installation automatique AngryMail
# Pour Ubuntu 20.04+ / Debian 11+
#############################################

set -e  # Arrête en cas d'erreur

echo "╔════════════════════════════════════════════╗"
echo "║   Installation AngryMail - VPS Setup      ║"
echo "╚════════════════════════════════════════════╝"
echo ""

# Couleurs
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

# Fonctions
log_info() {
    echo -e "${GREEN}✓${NC} $1"
}

log_warn() {
    echo -e "${YELLOW}⚠${NC} $1"
}

log_error() {
    echo -e "${RED}✗${NC} $1"
}

# Vérifier si root ou sudo
if [[ $EUID -ne 0 ]]; then
   log_error "Ce script doit être exécuté en tant que root ou avec sudo"
   exit 1
fi

# Variables
INSTALL_DIR="/var/www/angrymail"
DB_NAME="angrymail_db"
DB_USER="angrymail_user"
DB_PASS=$(openssl rand -base64 32)
ADMIN_USER="admin"
ADMIN_PASS=$(openssl rand -base64 16)
SESSION_SECRET=$(openssl rand -base64 48)

echo "Configuration :"
echo "  - Dossier : $INSTALL_DIR"
echo "  - DB User : $DB_USER"
echo "  - Admin User : $ADMIN_USER"
echo ""

read -p "Nom de domaine (ex: angrymail.com, laisser vide pour IP) : " DOMAIN
if [ -z "$DOMAIN" ]; then
    DOMAIN=$(curl -s ifconfig.me)
    log_warn "Utilisation de l'IP : $DOMAIN"
fi

read -p "Repository GitHub (ex: username/claim-your-agent) : " REPO
if [ -z "$REPO" ]; then
    log_error "Repository requis"
    exit 1
fi

echo ""
log_info "Mise à jour du système..."
apt update && apt upgrade -y

log_info "Installation de Git..."
apt install -y git curl wget

log_info "Installation de Node.js 18..."
curl -fsSL https://deb.nodesource.com/setup_18.x | bash -
apt install -y nodejs

log_info "Installation de MySQL..."
apt install -y mysql-server

log_info "Configuration de MySQL..."
mysql -u root <<MYSQL_SCRIPT
CREATE DATABASE IF NOT EXISTS $DB_NAME CHARACTER SET utf8mb4 COLLATE utf8mb4_unicode_ci;
CREATE USER IF NOT EXISTS '$DB_USER'@'localhost' IDENTIFIED BY '$DB_PASS';
GRANT ALL PRIVILEGES ON $DB_NAME.* TO '$DB_USER'@'localhost';
FLUSH PRIVILEGES;
MYSQL_SCRIPT

log_info "Clonage du projet..."
mkdir -p $INSTALL_DIR
cd $INSTALL_DIR
git clone https://github.com/$REPO.git .

log_info "Configuration de l'application..."
cat > .env <<ENV_FILE
PORT=3000
NODE_ENV=production

DB_HOST=localhost
DB_PORT=3306
DB_USER=$DB_USER
DB_PASS=$DB_PASS
DB_NAME=$DB_NAME

ADMIN_USER=$ADMIN_USER
ADMIN_PASS=$ADMIN_PASS

SESSION_SECRET=$SESSION_SECRET
SITE_DOMAIN=$DOMAIN

ENABLE_EMAIL_NOTIFICATIONS=false
ENV_FILE

log_info "Installation des dépendances..."
npm install --production

log_info "Migration de la base de données..."
npm run migrate

log_info "Ajout de données exemple..."
npm run seed

log_info "Installation de PM2..."
npm install -g pm2
pm2 start server/index.js --name angrymail
pm2 save
pm2 startup | tail -n 1 | bash

log_info "Installation de Nginx..."
apt install -y nginx

log_info "Configuration de Nginx..."
cat > /etc/nginx/sites-available/angrymail <<NGINX_CONF
server {
    listen 80;
    server_name $DOMAIN www.$DOMAIN;

    location / {
        proxy_pass http://localhost:3000;
        proxy_http_version 1.1;
        proxy_set_header Upgrade \$http_upgrade;
        proxy_set_header Connection 'upgrade';
        proxy_set_header Host \$host;
        proxy_set_header X-Real-IP \$remote_addr;
        proxy_set_header X-Forwarded-For \$proxy_add_x_forwarded_for;
        proxy_set_header X-Forwarded-Proto \$scheme;
        proxy_cache_bypass \$http_upgrade;
    }

    location /static {
        alias $INSTALL_DIR/server/public;
        expires 30d;
        add_header Cache-Control "public, immutable";
    }
}
NGINX_CONF

ln -sf /etc/nginx/sites-available/angrymail /etc/nginx/sites-enabled/
rm -f /etc/nginx/sites-enabled/default
nginx -t
systemctl restart nginx
systemctl enable nginx

log_info "Configuration du firewall..."
apt install -y ufw
ufw allow OpenSSH
ufw allow 'Nginx Full'
echo "y" | ufw enable

log_info "Installation de Certbot pour SSL..."
apt install -y certbot python3-certbot-nginx

echo ""
echo "╔════════════════════════════════════════════╗"
echo "║         Installation Terminée ! 🎉        ║"
echo "╚════════════════════════════════════════════╝"
echo ""
echo "📝 INFORMATIONS IMPORTANTES (SAUVEGARDE-LES) :"
echo ""
echo "🌐 URL : http://$DOMAIN"
echo ""
echo "🔐 Credentials Base de Données :"
echo "   User     : $DB_USER"
echo "   Password : $DB_PASS"
echo "   Database : $DB_NAME"
echo ""
echo "👤 Credentials Admin Dashboard :"
echo "   URL      : http://$DOMAIN/dashboard"
echo "   User     : $ADMIN_USER"
echo "   Password : $ADMIN_PASS"
echo ""
echo "📂 Fichier .env : $INSTALL_DIR/.env"
echo ""
echo "🔒 Pour activer HTTPS (recommandé) :"
echo "   sudo certbot --nginx -d $DOMAIN -d www.$DOMAIN"
echo ""
echo "📊 Commandes utiles :"
echo "   pm2 status         - Voir l'état de l'app"
echo "   pm2 logs angrymail - Voir les logs"
echo "   pm2 restart angrymail - Redémarrer l'app"
echo ""
echo "💾 Backup DB :"
echo "   mysqldump -u $DB_USER -p'$DB_PASS' $DB_NAME > backup.sql"
echo ""
echo "🎯 Prochaines étapes :"
echo "   1. Pointe ton domaine vers l'IP de ce serveur"
echo "   2. Exécute : sudo certbot --nginx -d $DOMAIN"
echo "   3. Visite : http://$DOMAIN"
echo ""

# Sauvegarder les credentials
cat > /root/angrymail-credentials.txt <<CREDS
AngryMail Installation - $(date)
================================

URL: http://$DOMAIN

Database:
  User: $DB_USER
  Pass: $DB_PASS
  Name: $DB_NAME

Admin:
  User: $ADMIN_USER
  Pass: $ADMIN_PASS

Session Secret: $SESSION_SECRET

.env file location: $INSTALL_DIR/.env
CREDS

log_info "Credentials sauvegardés dans /root/angrymail-credentials.txt"
echo ""
