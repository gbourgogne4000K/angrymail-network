# 🚀 Guide de Déploiement Complet - AngryMail

## Table des matières

1. [Déploiement VPS (Ubuntu/Debian)](#déploiement-vps)
2. [Déploiement Docker](#déploiement-docker)
3. [Déploiement FTP (Hébergement mutualisé)](#déploiement-ftp)
4. [Configuration DNS](#configuration-dns)
5. [SSL/HTTPS](#ssl-https)
6. [Monitoring et Maintenance](#monitoring)

---

## 🖥️ Déploiement VPS

### Prérequis

- VPS avec Ubuntu 20.04+ ou Debian 11+
- Accès SSH root ou sudo
- Au moins 1GB RAM, 10GB disque
- Nom de domaine (optionnel mais recommandé)

### Installation Automatique (Recommandé)

```bash
# Connecte-toi à ton VPS
ssh root@ton-ip-vps

# Télécharge et exécute le script d'installation
curl -fsSL https://raw.githubusercontent.com/TON-USERNAME/claim-your-agent/main/deploy/vps-install.sh | bash
```

### Installation Manuelle

#### 1. Mise à jour du système

```bash
ssh root@ton-ip-vps
sudo apt update && sudo apt upgrade -y
```

#### 2. Installation de Node.js 18+

```bash
curl -fsSL https://deb.nodesource.com/setup_18.x | sudo -E bash -
sudo apt install -y nodejs
node --version  # Vérifie : v18.x.x
```

#### 3. Installation de MySQL

```bash
sudo apt install -y mysql-server
sudo mysql_secure_installation
```

Configuration MySQL :
```bash
sudo mysql -u root -p

CREATE DATABASE angrymail_db CHARACTER SET utf8mb4 COLLATE utf8mb4_unicode_ci;
CREATE USER 'angrymail_user'@'localhost' IDENTIFIED BY 'VotreSuperMotDePasse123!';
GRANT ALL PRIVILEGES ON angrymail_db.* TO 'angrymail_user'@'localhost';
FLUSH PRIVILEGES;
EXIT;
```

#### 4. Cloner le projet

```bash
cd /var/www
sudo mkdir angrymail
sudo chown $USER:$USER angrymail
cd angrymail

# Cloner depuis GitHub
git clone https://github.com/TON-USERNAME/claim-your-agent.git .
```

#### 5. Configuration

```bash
cp .env.example .env
nano .env
```

Configuration `.env` :
```env
PORT=3000
NODE_ENV=production

DB_HOST=localhost
DB_PORT=3306
DB_USER=angrymail_user
DB_PASS=VotreSuperMotDePasse123!
DB_NAME=angrymail_db

ADMIN_USER=admin
ADMIN_PASS=VotreMotDePasseAdmin456!

SESSION_SECRET=GenerezUneChaineAleatoireTresLongueIci789
SITE_DOMAIN=angrymail.com

ENABLE_EMAIL_NOTIFICATIONS=false
```

#### 6. Installation et migration

```bash
npm install --production
npm run migrate
npm run seed  # Optionnel : données exemple
```

#### 7. Installation de PM2

```bash
sudo npm install -g pm2
pm2 start server/index.js --name angrymail
pm2 save
pm2 startup  # Exécute la commande affichée
```

#### 8. Installation de Nginx

```bash
sudo apt install -y nginx

# Crée la config
sudo nano /etc/nginx/sites-available/angrymail.com
```

Configuration Nginx :
```nginx
server {
    listen 80;
    server_name angrymail.com www.angrymail.com;

    location / {
        proxy_pass http://localhost:3000;
        proxy_http_version 1.1;
        proxy_set_header Upgrade $http_upgrade;
        proxy_set_header Connection 'upgrade';
        proxy_set_header Host $host;
        proxy_set_header X-Real-IP $remote_addr;
        proxy_set_header X-Forwarded-For $proxy_add_x_forwarded_for;
        proxy_set_header X-Forwarded-Proto $scheme;
        proxy_cache_bypass $http_upgrade;
    }

    location /static {
        alias /var/www/angrymail/server/public;
        expires 30d;
        add_header Cache-Control "public, immutable";
    }
}
```

Activation :
```bash
sudo ln -s /etc/nginx/sites-available/angrymail.com /etc/nginx/sites-enabled/
sudo rm /etc/nginx/sites-enabled/default  # Optionnel
sudo nginx -t
sudo systemctl restart nginx
sudo systemctl enable nginx
```

#### 9. Firewall

```bash
sudo apt install -y ufw
sudo ufw allow OpenSSH
sudo ufw allow 'Nginx Full'
sudo ufw enable
sudo ufw status
```

#### 10. SSL avec Let's Encrypt

```bash
sudo apt install -y certbot python3-certbot-nginx
sudo certbot --nginx -d angrymail.com -d www.angrymail.com
sudo certbot renew --dry-run  # Test renouvellement auto
```

---

## 🐳 Déploiement Docker

### Méthode 1 : Docker Compose (Recommandé)

```bash
# Clone le projet
git clone https://github.com/TON-USERNAME/claim-your-agent.git
cd claim-your-agent

# Configure .env
cp .env.example .env
nano .env

# Démarre les services
docker-compose -f docker/docker-compose.yml up -d

# Applique les migrations
docker-compose -f docker/docker-compose.yml exec web npm run migrate

# (Optionnel) Seed
docker-compose -f docker/docker-compose.yml exec web npm run seed
```

Accès :
- Application : http://localhost:3000
- Adminer (DB UI) : http://localhost:8080

### Méthode 2 : Docker manuel

```bash
# Build l'image
docker build -t angrymail -f docker/Dockerfile .

# Démarre MySQL
docker run -d \
  --name angrymail-db \
  -e MYSQL_ROOT_PASSWORD=rootpass \
  -e MYSQL_DATABASE=angrymail_db \
  -e MYSQL_USER=angrymail_user \
  -e MYSQL_PASSWORD=userpass \
  -v angrymail-data:/var/lib/mysql \
  mysql:8.0

# Démarre l'app
docker run -d \
  --name angrymail-web \
  --link angrymail-db:db \
  -p 3000:3000 \
  -e DB_HOST=db \
  -e DB_USER=angrymail_user \
  -e DB_PASS=userpass \
  -e DB_NAME=angrymail_db \
  angrymail

# Migrations
docker exec angrymail-web npm run migrate
```

---

## 📁 Déploiement FTP

Voir le guide détaillé : [deploy/ftp_deploy_instructions.txt](deploy/ftp_deploy_instructions.txt)

Résumé :
1. Upload via FTP : server/, migrations/, scripts/, node_modules/, package.json, .env
2. Configure MySQL sur l'hébergeur
3. SSH : `npm run migrate`
4. Configure PM2 ou équivalent
5. Configure reverse proxy

---

## 🌐 Configuration DNS

### Chez ton registrar (Namecheap, GoDaddy, etc.)

Ajoute ces enregistrements DNS :

```
Type    Nom     Valeur              TTL
A       @       IP-DE-TON-VPS       3600
A       www     IP-DE-TON-VPS       3600
CNAME   www     angrymail.com       3600
```

Attends 10-30 minutes pour la propagation DNS.

Vérifie avec :
```bash
nslookup angrymail.com
```

---

## 🔒 SSL/HTTPS

### Let's Encrypt (Gratuit)

```bash
sudo certbot --nginx -d angrymail.com -d www.angrymail.com
```

### Cloudflare (Gratuit + CDN)

1. Crée un compte sur cloudflare.com
2. Ajoute ton domaine
3. Change les nameservers chez ton registrar
4. Active SSL/TLS "Full"
5. Active "Always Use HTTPS"

---

## 📊 Monitoring

### PM2 Monitoring

```bash
# Status
pm2 status

# Logs en temps réel
pm2 logs angrymail

# Monitoring
pm2 monit

# PM2 Plus (gratuit)
pm2 link <secret> <public>
# Obtiens les clés sur https://app.pm2.io
```

### Logs Nginx

```bash
# Erreurs
sudo tail -f /var/log/nginx/error.log

# Accès
sudo tail -f /var/log/nginx/access.log
```

### Logs MySQL

```bash
sudo tail -f /var/log/mysql/error.log
```

---

## 🔄 Mise à jour

### Via Git

```bash
cd /var/www/angrymail
git pull origin main
npm install --production
pm2 restart angrymail
```

### Via FTP

1. Upload les nouveaux fichiers
2. SSH : `npm install --production`
3. SSH : `pm2 restart angrymail`

---

## 💾 Backups

### Backup automatique MySQL

Crée `/usr/local/bin/backup-angrymail.sh` :

```bash
#!/bin/bash
DATE=$(date +%Y%m%d_%H%M%S)
BACKUP_DIR="/var/backups/angrymail"
mkdir -p $BACKUP_DIR

mysqldump -u angrymail_user -p'VotreSuperMotDePasse123!' angrymail_db > $BACKUP_DIR/db_$DATE.sql
gzip $BACKUP_DIR/db_$DATE.sql
find $BACKUP_DIR -name "db_*.sql.gz" -mtime +7 -delete

echo "Backup: $BACKUP_DIR/db_$DATE.sql.gz"
```

Automatise :
```bash
sudo chmod +x /usr/local/bin/backup-angrymail.sh
sudo crontab -e
# Ajoute : 0 3 * * * /usr/local/bin/backup-angrymail.sh
```

### Restauration

```bash
gunzip backup_20250201_030000.sql.gz
mysql -u angrymail_user -p angrymail_db < backup_20250201_030000.sql
```

---

## 🔐 Sécurité

### Checklist

- [ ] Mots de passe forts (DB, admin)
- [ ] SESSION_SECRET aléatoire (32+ chars)
- [ ] NODE_ENV=production
- [ ] HTTPS activé
- [ ] Firewall configuré
- [ ] Fail2Ban installé
- [ ] Backups automatiques
- [ ] Logs surveillés
- [ ] Dépendances à jour (`npm audit`)

### Fail2Ban

```bash
sudo apt install -y fail2ban
sudo systemctl enable fail2ban
sudo systemctl start fail2ban
```

### Utilisateur non-root

```bash
sudo adduser angrymail
sudo usermod -aG sudo angrymail
su - angrymail
```

Désactive root SSH :
```bash
sudo nano /etc/ssh/sshd_config
# PermitRootLogin no
sudo systemctl restart sshd
```

---

## 🐛 Dépannage

### App ne démarre pas

```bash
pm2 logs angrymail --lines 100
cd /var/www/angrymail
node server/index.js  # Test manuel
```

### Erreur DB

```bash
mysql -u angrymail_user -p angrymail_db -e "SHOW TABLES;"
sudo systemctl status mysql
```

### Nginx erreur

```bash
sudo nginx -t
sudo tail -f /var/log/nginx/error.log
```

### Port occupé

```bash
sudo lsof -i :3000
sudo kill -9 <PID>
```

---

## 📞 Support

- GitHub Issues : https://github.com/TON-USERNAME/claim-your-agent/issues
- Documentation : [README.md](README.md)
- Guide FR : [GUIDE-FR.md](GUIDE-FR.md)

---

**Déploiement réussi ? Félicitations ! 🎉**
