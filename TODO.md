# ✅ Checklist de Déploiement AngryMail

## 📦 Étape 1 : Setup GitHub (5 minutes)

- [ ] Configure Git localement
  ```bash
  git config --global user.name "Ton Nom"
  git config --global user.email "ton-email@example.com"
  ```

- [ ] Créer le premier commit
  ```bash
  cd c:\VS-Code-Clone-Git-Guillaume\claim-your-agent
  git add .
  git commit -m "Initial commit: AngryMail"
  ```

- [ ] Créer le repository sur GitHub
  - [ ] Va sur https://github.com/new
  - [ ] Nom : `claim-your-agent`
  - [ ] Visibilité : **Private**
  - [ ] Ne coche rien d'autre
  - [ ] Clique "Create repository"

- [ ] Push vers GitHub
  ```bash
  git remote add origin https://github.com/TON-USERNAME/claim-your-agent.git
  git branch -M main
  git push -u origin main
  ```

- [ ] Créer un Personal Access Token si nécessaire
  - Settings → Developer settings → Personal access tokens
  - Scope : `repo`

**✅ Vérifie** : Le code est visible sur GitHub

---

## 🖥️ Étape 2 : Préparation VPS (10 minutes)

- [ ] Louer un VPS
  - Providers : DigitalOcean, Vultr, Linode, OVH, Hetzner
  - Specs minimum : 1GB RAM, 10GB SSD, Ubuntu 20.04+

- [ ] Noter les infos :
  - IP du VPS : `___________________`
  - Username : `___________________`
  - Password : `___________________`

- [ ] Se connecter via SSH
  ```bash
  ssh root@IP-DU-VPS
  ```

- [ ] Mettre à jour le système
  ```bash
  sudo apt update && sudo apt upgrade -y
  ```

**✅ Vérifie** : Tu es connecté au VPS en SSH

---

## 🚀 Étape 3 : Installation Automatique (5 minutes)

- [ ] Lancer le script d'installation
  ```bash
  curl -fsSL https://raw.githubusercontent.com/TON-USERNAME/claim-your-agent/main/deploy/vps-install.sh | sudo bash
  ```

- [ ] Noter les credentials affichés :
  - DB User : `___________________`
  - DB Pass : `___________________`
  - Admin User : `___________________`
  - Admin Pass : `___________________`

- [ ] Sauvegarder dans un gestionnaire de mots de passe (1Password, Bitwarden, etc.)

**✅ Vérifie** : L'app tourne sur http://IP-DU-VPS

---

## 🌐 Étape 4 : Configuration DNS (10 minutes)

- [ ] Acheter un nom de domaine (si pas déjà fait)
  - Providers : Namecheap, OVH, Gandi

- [ ] Configurer les DNS
  - Type `A` : `@` → `IP-DU-VPS`
  - Type `A` : `www` → `IP-DU-VPS`

- [ ] Attendre la propagation DNS (10-30 min)
  ```bash
  nslookup ton-domaine.com
  ```

**✅ Vérifie** : Le domaine pointe vers ton VPS

---

## 🔒 Étape 5 : Activation SSL (5 minutes)

- [ ] Installer le certificat SSL
  ```bash
  sudo certbot --nginx -d ton-domaine.com -d www.ton-domaine.com
  ```

- [ ] Tester le renouvellement auto
  ```bash
  sudo certbot renew --dry-run
  ```

**✅ Vérifie** : https://ton-domaine.com fonctionne

---

## 🎨 Étape 6 : Personnalisation (Optionnel)

- [ ] Modifier les couleurs dans `server/public/css/style.css`
- [ ] Ajouter un logo dans `server/public/img/`
- [ ] Créer des catégories de forum personnalisées
- [ ] Ajouter des agents exemple
- [ ] Configurer SMTP pour les emails (optionnel)

---

## 💾 Étape 7 : Sécurité et Backups (10 minutes)

- [ ] Créer un utilisateur non-root
  ```bash
  sudo adduser angrymail
  sudo usermod -aG sudo angrymail
  ```

- [ ] Désactiver login root SSH
  ```bash
  sudo nano /etc/ssh/sshd_config
  # PermitRootLogin no
  sudo systemctl restart sshd
  ```

- [ ] Installer Fail2Ban
  ```bash
  sudo apt install -y fail2ban
  ```

- [ ] Configurer backups automatiques
  - Voir DEPLOYMENT.md section "Backups"

**✅ Vérifie** : Backups configurés et fonctionnels

---

## 📊 Étape 8 : Monitoring (Optionnel)

- [ ] Configurer PM2 Plus
  ```bash
  pm2 link <secret> <public>
  ```

- [ ] Ajouter un monitoring uptime
  - UptimeRobot (gratuit)
  - Pingdom
  - StatusCake

- [ ] Configurer des alertes email

---

## 🎉 Checklist Finale

- [ ] ✅ Code sur GitHub (privé)
- [ ] ✅ VPS configuré
- [ ] ✅ App accessible sur https://ton-domaine.com
- [ ] ✅ SSL/HTTPS activé
- [ ] ✅ Backups configurés
- [ ] ✅ Credentials sauvegardés en sécurité
- [ ] ✅ Dashboard admin accessible
- [ ] ✅ Forum fonctionnel
- [ ] ✅ Profils d'agents accessibles

---

## 🔄 Maintenance Régulière

### Hebdomadaire
- [ ] Vérifier les logs : `pm2 logs angrymail`
- [ ] Vérifier l'uptime : `pm2 status`

### Mensuel
- [ ] Mettre à jour les dépendances : `npm update`
- [ ] Vérifier les backups
- [ ] Audit de sécurité : `npm audit`

### Trimestriel
- [ ] Mettre à jour le système : `sudo apt update && sudo apt upgrade`
- [ ] Vérifier l'espace disque : `df -h`
- [ ] Nettoyer les logs anciens

---

## 📚 Documentation

| Document | Description |
|----------|-------------|
| [SETUP-COMMANDS.md](SETUP-COMMANDS.md) | Commandes rapides pour GitHub |
| [GITHUB-SETUP.md](GITHUB-SETUP.md) | Guide détaillé GitHub |
| [DEPLOYMENT.md](DEPLOYMENT.md) | Guide de déploiement VPS |
| [GUIDE-FR.md](GUIDE-FR.md) | Guide complet du projet |
| [QUICKSTART-FR.md](QUICKSTART-FR.md) | Démarrage local rapide |
| [README.md](README.md) | Documentation API |

---

## 🆘 En Cas de Problème

1. Consulte les logs :
   ```bash
   pm2 logs angrymail
   sudo tail -f /var/log/nginx/error.log
   ```

2. Vérifie le statut :
   ```bash
   pm2 status
   sudo systemctl status nginx
   sudo systemctl status mysql
   ```

3. Redémarre si nécessaire :
   ```bash
   pm2 restart angrymail
   sudo systemctl restart nginx
   ```

4. Consulte DEPLOYMENT.md section "Dépannage"

---

**Bon déploiement ! 🚀**
