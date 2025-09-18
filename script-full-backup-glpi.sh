#!/bin/bash
#
# GLPI Backup Script
# ------------------
# Ce script effectue :
#   - un dump de la base MySQL
#   - la création d’une archive compressée du dossier GLPI + dump
#   - le nettoyage automatique pour ne garder que 3 sauvegardes
#
# Auteur    : Grégory Roussel
# Version   : 1.0
# Date      : 2025-09-18
# Licence   : MIT (voir détails ci-dessous)
#
# Utilisation :
#   - Modifier les variables de configuration (BACKUP_DIR, GLPI_DIR, DB_NAME, etc.)
#   - Lancer manuellement ou via cron (exemple : tous les jours à 2h du matin)
#
# Exemple de cron :
#   0 2 * * * /home/username/script-backup-glpi.sh >> /var/log/backup-glpi.log 2>&1
#
# Dépendances :
#   - mysqldump
#   - tar
#   - gzip
#   - bash >= 4
#
# Licence MIT :
#   Permission est accordée, gratuitement, à toute personne obtenant une copie
#   de ce logiciel et des fichiers de documentation associés (le "Logiciel"),
#   de commercialiser, utiliser, copier, modifier, fusionner, publier,
#   distribuer, sous-licencier et/ou vendre des copies du Logiciel, et de
#   permettre aux personnes auxquelles le Logiciel est fourni de le faire,
#   sous réserve des conditions suivantes :
#
#   Le texte ci-dessus doit être inclus dans toutes copies ou parties substantielles du Logiciel.
#   LE LOGICIEL EST FOURNI "EN L'ÉTAT", SANS GARANTIE D'AUCUNE SORTE.


# -------------------------
# CONFIGURATION
# -------------------------
BACKUP_DIR="YOUR_ACCOUNTDIR"
GLPI_DIR="YOUR_GLPI_DIR"
DATE=$(date +%Y%m%d-%H%M%S)
BACKUP_FILE="$BACKUP_DIR/glpi-backup-$DATE.tar.gz"

# Base de données
DB_NAME="YOUR_DB_NAME"
DB_USER="YOUR_DB_USER"
DB_PASS="YOUR_DB_PASSWD"

# -------------------------
# CRÉATION DU DOSSIER DE BACKUP
# -------------------------
mkdir -p "$BACKUP_DIR"
echo "✅ Dossier de backup créé ou existant"

# -------------------------
# DUMP DE LA BASE DE DONNÉES
# -------------------------
echo "💾 Dump de la base de données..."
if mysqldump -u"$DB_USER" -p"$DB_PASS" -h localhost "$DB_NAME" > "$BACKUP_DIR/glpi-$DATE.sql"; then
    echo "✅ Dump réussi : $BACKUP_DIR/glpi-$DATE.sql"
else
    echo "❌ Erreur lors du dump de la base"
    exit 1
fi

# -------------------------
# Préparer chemins relatifs pour tar
# -------------------------
GLPI_PARENT="$(dirname "$GLPI_DIR")"
GLPI_BASE="$(basename "$GLPI_DIR")"

# -------------------------
# CRÉATION DE L’ARCHIVE (chemins relatifs)
# -------------------------
echo "📦 Création de l’archive avec chemins relatifs..."
if tar -czf "$BACKUP_FILE" \
       --exclude="$GLPI_BASE/files/_cache" \
       -C "$GLPI_PARENT" "$GLPI_BASE" \
       -C "$BACKUP_DIR" "glpi-$DATE.sql"; then
    echo "✅ Archive créée : $BACKUP_FILE"
else
    echo "❌ Erreur lors de la création de l’archive"
    exit 1
fi

# Supprimer le dump SQL en clair
rm -f "$BACKUP_DIR/glpi-$DATE.sql"

# -------------------------
# Limiter le nombre de backups locaux à 3
# -------------------------
echo "🗑️ Nettoyage des anciennes sauvegardes (max 3)..."
cd "$BACKUP_DIR" || exit 1
ls -1t glpi-backup-*.tar.gz | tail -n +4 | xargs -r rm -f
echo "✅ Nettoyage terminé"

# -------------------------
# ENVOI SUR S3 CUSTOM (désactivé pour l'instant)
# -------------------------
# echo "☁️ Envoi sur S3..."
# if "$AWS_CMD" --endpoint-url "$S3_ENDPOINT" s3 cp "$BACKUP_FILE" "s3://$S3_BUCKET/$S3_PATH/" --no-verify-ssl; then
#     echo "✅ Envoi S3 réussi : s3://$S3_BUCKET/$S3_PATH/$(basename "$BACKUP_FILE")"
# else
#     echo "❌ Erreur lors de l’envoi S3"
#     exit 1
# fi

echo "🎉 Traitement terminé avec succès. Aucun fichier n’a été supprimé hormis les anciens backups dépassant 3."
