# GLPI Backup Script

Ce script Bash permet d'automatiser la sauvegarde d'une instance **GLPI** (fichiers applicatifs et base de données MySQL/MariaDB).  
Il génère une archive compressée et conserve uniquement les **3 dernières sauvegardes locales**.  

## Fonctionnalités

- Dump complet de la base de données GLPI
- Sauvegarde des fichiers applicatifs (avec exclusion du cache)
- Compression au format `.tar.gz`
- Rotation automatique (max 3 archives conservées)
- Compatible avec `cron` pour automatiser les sauvegardes
- (Optionnel) Prévu pour l'envoi vers un stockage **S3 compatible** (désactivé par défaut)

## Installation

1. Cloner le dépôt :
   ```bash
   git clone https://github.com/<ton-utilisateur>/<ton-repo>.git
   cd <ton-repo>
   ```

2. Adapter le script `backup-glpi.sh` :
   - `BACKUP_DIR` → répertoire de sauvegarde local  
   - `GLPI_DIR` → chemin de l’installation GLPI  
   - `DB_NAME`, `DB_USER`, `DB_PASS` → identifiants MySQL  

3. Rendre le script exécutable :
   ```bash
   chmod +x backup-glpi.sh
   ```

4. Tester manuellement :
   ```bash
   ./backup-glpi.sh
   ```

## Automatisation avec Cron

Pour lancer la sauvegarde automatiquement tous les jours à 2h du matin :  

```bash
0 2 * * * /chemin/vers/backup-glpi.sh >> /var/log/backup-glpi.log 2>&1
```

## Exemple de sortie

```
✅ Dossier de backup créé ou existant
💾 Dump de la base de données...
✅ Dump réussi
📦 Création de l’archive...
✅ Archive créée
🗑️ Nettoyage des anciennes sauvegardes (max 3)...
✅ Nettoyage terminé
🎉 Traitement terminé avec succès
```

## Licence

Ce projet est distribué sous la licence **MIT**.  
Voir le fichier [LICENSE](./LICENSE) pour plus de détails.
