# GLPI Backup Script v2.0

Ce script Bash permet d'automatiser la sauvegarde d'une instance **GLPI** (fichiers applicatifs et base de données MySQL/MariaDB) avec une **sécurité renforcée** et une **validation complète des prérequis**.

Il génère une archive compressée et conserve uniquement les **3 dernières sauvegardes locales**.

## ✨ Fonctionnalités

- **Dump complet** de la base de données GLPI avec options avancées (transactions, routines, triggers)
- **Sauvegarde sécurisée** des fichiers applicatifs (exclusion cache, tmp, logs)
- **Compression** au format `.tar.gz` avec permissions sécurisées
- **Rotation automatique** (max 3 archives conservées, configurable)
- **Validation complète** des prérequis (outils, fichiers, permissions)
- **Logging avec timestamps** et gestion centralisée des erreurs
- **Configuration MySQL sécurisée** via fichier `.my.cnf` (plus de mots de passe en clair)
- **Compatible avec `cron`** pour automatiser les sauvegardes
- **Statistiques détaillées** (tailles, nombres de fichiers)
- **(Optionnel)** Prévu pour l'envoi vers un stockage **S3 compatible** (désactivé par défaut)

## 🛠️ Prérequis

- **Bash** >= 4
- **mysqldump** (MySQL/MariaDB client)
- **tar** et **gzip**
- **Droits de lecture** sur le répertoire GLPI
- **Utilisateur MySQL** avec permissions `SELECT`, `LOCK TABLES`, `SHOW VIEW` sur la base GLPI

## 📥 Installation

### 1. Cloner le dépôt
```bash
git clone https://github.com/<ton-utilisateur>/<ton-repo>.git
cd <ton-repo>
```

### 2. Configurer MySQL de manière sécurisée
Créer le fichier de configuration MySQL :
```bash
nano ~/.my.cnf
```

Ajouter le contenu suivant :
```ini
[client]
user=votre_utilisateur_mysql
password=votre_mot_de_passe_mysql
host=localhost
port=3306
default-character-set=utf8mb4

[mysqldump]
single-transaction=true
routines=true
triggers=true
add-drop-table=true
default-character-set=utf8mb4
```

Sécuriser le fichier :
```bash
chmod 600 ~/.my.cnf
```

### 3. Adapter le script
Modifier les variables dans `script-full-backup-glpi.sh` :
- `BACKUP_DIR` → répertoire de sauvegarde local
- `GLPI_DIR` → chemin de l'installation GLPI  
- `DB_NAME` → nom de la base de données GLPI

### 4. Rendre le script exécutable
```bash
chmod +x script-full-backup-glpi.sh
```

### 5. Test initial
```bash
./script-full-backup-glpi.sh
```

## ⏰ Automatisation avec Cron

Pour lancer la sauvegarde automatiquement tous les jours à 2h du matin :
```bash
# Éditer la crontab
crontab -e

# Ajouter la ligne suivante
0 2 * * * /chemin/vers/script-full-backup-glpi.sh >> /var/log/backup-glpi.log 2>&1
```

### Exemples de planification
```bash
# Tous les jours à 2h du matin
0 2 * * * /chemin/vers/script-full-backup-glpi.sh

# Tous les dimanche à 3h du matin
0 3 * * 0 /chemin/vers/script-full-backup-glpi.sh

# Toutes les 6 heures
0 */6 * * * /chemin/vers/script-full-backup-glpi.sh
```

## 📊 Exemple de sortie

```
2025-09-18 02:00:01 - 🔍 Vérification des prérequis...
2025-09-18 02:00:01 - ✅ Outils requis disponibles
2025-09-18 02:00:01 - ✅ Prérequis validés
2025-09-18 02:00:01 - 📁 Création du dossier de backup...
2025-09-18 02:00:01 - ✅ Dossier de backup créé ou existant: /backups/glpi
2025-09-18 02:00:01 - 💾 Dump de la base de données 'glpi_prod'...
2025-09-18 02:00:15 - ✅ Dump réussi: /backups/glpi/glpi-20250918-020001.sql (24M)
2025-09-18 02:00:15 - 📦 Création de l'archive avec chemins relatifs...
2025-09-18 02:00:45 - ✅ Archive créée: /backups/glpi/glpi-backup-20250918-020001.tar.gz (156M)
2025-09-18 02:00:45 - 🗑️ Dump SQL temporaire supprimé
2025-09-18 02:00:45 - 🗑️ Nettoyage des anciennes sauvegardes (max 3)...
2025-09-18 02:00:45 - 🗑️ Sauvegardes supprimées:
2025-09-18 02:00:45 -   - glpi-backup-20250915-020001.tar.gz
2025-09-18 02:00:45 - 🎉 Sauvegarde terminée avec succès!
2025-09-18 02:00:45 - 📊 Résumé:
2025-09-18 02:00:45 -    - Fichier créé: glpi-backup-20250918-020001.tar.gz
2025-09-18 02:00:45 -    - Taille: 156M
2025-09-18 02:00:45 -    - Sauvegardes totales: 3/3
2025-09-18 02:00:45 -    - Espace utilisé: 445M
```

## 🔧 Configuration avancée

### Variables personnalisables
```bash
# Dans le script script-full-backup-glpi.sh
MAX_BACKUPS=3              # Nombre de sauvegardes à conserver
MYSQL_CONFIG="$HOME/.my.cnf"  # Chemin du fichier de config MySQL
```

### Exclusions personnalisées
Le script exclut automatiquement :
- `files/_cache` - Cache applicatif GLPI
- `files/_tmp` - Fichiers temporaires
- `files/_log/*.log` - Logs applicatifs

### Activation de l'envoi S3 (optionnel)
Décommenter et configurer la section S3 dans le script :
```bash
S3_ENDPOINT="https://your-s3-endpoint.com"
S3_BUCKET="your-backup-bucket"
S3_PATH="glpi-backups"
AWS_CMD="aws"
```

## 🚨 Dépannage

### Erreurs courantes

**"Variables de configuration manquantes"**
- Vérifiez que vous avez bien modifié `BACKUP_DIR`, `GLPI_DIR` et `DB_NAME`

**"Fichier de configuration MySQL non trouvé"**
- Créez le fichier `~/.my.cnf` avec les identifiants MySQL

**"mysqldump n'est pas installé"**
- Installez le client MySQL : `apt install mysql-client` ou `yum install mysql`

**"Permissions du fichier .my.cnf non sécurisées"**
- Le script corrige automatiquement avec `chmod 600 ~/.my.cnf`

### Logs détaillés
Les logs incluent des timestamps et peuvent être consultés :
```bash
tail -f /var/log/backup-glpi.log
```

## 🔒 Sécurité

- **Mots de passe** : stockés uniquement dans `~/.my.cnf` avec permissions 600
- **Archives** : permissions 600 (lecture seule propriétaire)
- **Processus** : aucun identifiant visible dans `ps aux`
- **Validation** : vérification complète avant chaque opération

## 🆕 Nouveautés v2.0

- ✅ Configuration MySQL sécurisée via `.my.cnf`
- ✅ Validation complète des prérequis
- ✅ Logging avec timestamps
- ✅ Gestion centralisée des erreurs
- ✅ Permissions sécurisées automatiques
- ✅ Options MySQL avancées (transactions, routines)
- ✅ Exclusions étendues et statistiques détaillées
- ✅ Documentation complète et exemples

## 📄 Licence

Ce projet est distribué sous la licence **MIT**.  
Voir le fichier [LICENSE](./LICENSE) pour plus de détails.

---

**Auteur** : Grégory Roussel  
**Version** : 2.0  
**Date** : 2025-09-18
