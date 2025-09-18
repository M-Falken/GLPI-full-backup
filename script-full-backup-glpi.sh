#!/bin/bash
#
# GLPI Backup Script (Version améliorée)
# --------------------------------------
# Ce script effectue :
#   - un dump de la base MySQL (avec .my.cnf pour la sécurité)
#   - la création d'une archive compressée du dossier GLPI + dump
#   - le nettoyage automatique pour ne garder que 3 sauvegardes
#   - validation des prérequis et gestion d'erreurs renforcée
#
# Auteur    : Grégory Roussel
# Version   : 2.0
# Date      : 2025-09-18
# Licence   : MIT (voir détails ci-dessous)
#
# Utilisation :
#   1. Créer un fichier ~/.my.cnf avec les identifiants MySQL :
#      [client]
#      user=YOUR_DB_USER
#      password=YOUR_DB_PASSWORD
#      host=localhost
#      
#      chmod 600 ~/.my.cnf
#   
#   2. Modifier les variables de configuration (BACKUP_DIR, GLPI_DIR, DB_NAME)
#   3. Lancer manuellement ou via cron (exemple : tous les jours à 2h du matin)
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
# FONCTIONS UTILITAIRES
# -------------------------

# Fonction de log avec timestamp
log() {
    echo "$(date '+%Y-%m-%d %H:%M:%S') - $1"
}

# Fonction de log d'erreur et sortie
error_exit() {
    log "❌ ERREUR: $1"
    exit 1
}

# -------------------------
# CONFIGURATION
# -------------------------
BACKUP_DIR="YOUR_BACKUP_DIR"
GLPI_DIR="YOUR_GLPI_DIR"
DATE=$(date +%Y%m%d-%H%M%S)
BACKUP_FILE="$BACKUP_DIR/glpi-backup-$DATE.tar.gz"

# Base de données (utilise ~/.my.cnf pour les identifiants)
DB_NAME="YOUR_DB_NAME"
MYSQL_CONFIG="$HOME/.my.cnf"

# Nombre maximum de sauvegardes à conserver
MAX_BACKUPS=3

# -------------------------
# VALIDATION DES PRÉREQUIS
# -------------------------

log "🔍 Vérification des prérequis..."

# Vérifier que les variables essentielles sont définies
if [[ -z "$BACKUP_DIR" || -z "$GLPI_DIR" || -z "$DB_NAME" ]]; then
    error_exit "Variables de configuration manquantes. Vérifiez BACKUP_DIR, GLPI_DIR et DB_NAME."
fi

# Vérifier que les variables ne contiennent pas les valeurs par défaut
if [[ "$BACKUP_DIR" == "YOUR_BACKUP_DIR" || "$GLPI_DIR" == "YOUR_GLPI_DIR" || "$DB_NAME" == "YOUR_DB_NAME" ]]; then
    error_exit "Veuillez modifier les variables de configuration (remplacer YOUR_* par les vraies valeurs)"
fi

# Vérifier la disponibilité des outils requis
for cmd in mysqldump tar gzip; do
    if ! command -v "$cmd" &> /dev/null; then
        error_exit "$cmd n'est pas installé ou accessible"
    fi
done
log "✅ Outils requis disponibles"

# Vérifier l'existence du fichier de configuration MySQL
if [[ ! -f "$MYSQL_CONFIG" ]]; then
    error_exit "Fichier de configuration MySQL non trouvé: $MYSQL_CONFIG"
fi

# Vérifier les permissions du fichier de configuration MySQL
if [[ "$(stat -c %a "$MYSQL_CONFIG")" != "600" ]]; then
    log "⚠️  Permissions du fichier $MYSQL_CONFIG non sécurisées. Application de chmod 600..."
    chmod 600 "$MYSQL_CONFIG"
fi

# Vérifier l'existence du répertoire GLPI
if [[ ! -d "$GLPI_DIR" ]]; then
    error_exit "Répertoire GLPI non trouvé: $GLPI_DIR"
fi
log "✅ Prérequis validés"

# -------------------------
# CRÉATION DU DOSSIER DE BACKUP
# -------------------------
log "📁 Création du dossier de backup..."
if ! mkdir -p "$BACKUP_DIR"; then
    error_exit "Impossible de créer le dossier de backup: $BACKUP_DIR"
fi
log "✅ Dossier de backup créé ou existant: $BACKUP_DIR"

# -------------------------
# DUMP DE LA BASE DE DONNÉES
# -------------------------
log "💾 Dump de la base de données '$DB_NAME'..."
SQL_DUMP="$BACKUP_DIR/glpi-$DATE.sql"

# Utilisation du fichier .my.cnf pour la connexion sécurisée
if ! mysqldump --defaults-file="$MYSQL_CONFIG" \
               --single-transaction \
               --routines \
               --triggers \
               "$DB_NAME" > "$SQL_DUMP"; then
    error_exit "Échec du dump de la base de données"
fi

# Vérifier que le dump n'est pas vide
if [[ ! -s "$SQL_DUMP" ]]; then
    error_exit "Le fichier dump est vide"
fi

log "✅ Dump réussi: $SQL_DUMP ($(du -h "$SQL_DUMP" | cut -f1))"

# -------------------------
# PRÉPARATION DES CHEMINS POUR TAR
# -------------------------
GLPI_PARENT="$(dirname "$GLPI_DIR")"
GLPI_BASE="$(basename "$GLPI_DIR")"

# -------------------------
# CRÉATION DE L'ARCHIVE
# -------------------------
log "📦 Création de l'archive avec chemins relatifs..."
if ! tar -czf "$BACKUP_FILE" \
         --exclude="$GLPI_BASE/files/_cache" \
         --exclude="$GLPI_BASE/files/_tmp" \
         --exclude="$GLPI_BASE/files/_log/*.log" \
         -C "$GLPI_PARENT" "$GLPI_BASE" \
         -C "$BACKUP_DIR" "$(basename "$SQL_DUMP")"; then
    error_exit "Échec de la création de l'archive"
fi

# Sécuriser les permissions de l'archive
chmod 600 "$BACKUP_FILE"

log "✅ Archive créée: $BACKUP_FILE ($(du -h "$BACKUP_FILE" | cut -f1))"

# Supprimer le dump SQL temporaire
rm -f "$SQL_DUMP"
log "🗑️ Dump SQL temporaire supprimé"

# -------------------------
# NETTOYAGE DES ANCIENNES SAUVEGARDES
# -------------------------
log "🗑️ Nettoyage des anciennes sauvegardes (max $MAX_BACKUPS)..."

cd "$BACKUP_DIR" || error_exit "Impossible d'accéder au dossier de backup"

# Compter le nombre de sauvegardes existantes
BACKUP_COUNT=$(ls -1 glpi-backup-*.tar.gz 2>/dev/null | wc -l)

if [[ $BACKUP_COUNT -gt $MAX_BACKUPS ]]; then
    # Supprimer les sauvegardes les plus anciennes
    BACKUPS_TO_DELETE=$((BACKUP_COUNT - MAX_BACKUPS))
    DELETED_FILES=$(ls -1t glpi-backup-*.tar.gz | tail -n "+$((MAX_BACKUPS + 1))" | xargs -r rm -fv)
    
    if [[ -n "$DELETED_FILES" ]]; then
        log "🗑️ Sauvegardes supprimées:"
        echo "$DELETED_FILES" | while read -r file; do
            log "  - $(basename "$file")"
        done
    fi
else
    log "✅ Aucune sauvegarde à supprimer ($BACKUP_COUNT/$MAX_BACKUPS)"
fi

# -------------------------
# RÉSUMÉ FINAL
# -------------------------
FINAL_COUNT=$(ls -1 glpi-backup-*.tar.gz 2>/dev/null | wc -l)
TOTAL_SIZE=$(du -sh glpi-backup-*.tar.gz 2>/dev/null | awk '{sum += $1} END {print sum}' | numfmt --to=iec --suffix=B)

log "🎉 Sauvegarde terminée avec succès!"
log "📊 Résumé:"
log "   - Fichier créé: $(basename "$BACKUP_FILE")"
log "   - Taille: $(du -h "$BACKUP_FILE" | cut -f1)"
log "   - Sauvegardes totales: $FINAL_COUNT/$MAX_BACKUPS"
log "   - Espace utilisé: ${TOTAL_SIZE:-N/A}"

# -------------------------
# ENVOI SUR S3 CUSTOM (désactivé pour l'instant)
# -------------------------
# Décommentez et configurez cette section pour l'envoi automatique sur S3
#
# S3_ENDPOINT="YOUR_S3_ENDPOINT"
# S3_BUCKET="YOUR_S3_BUCKET"
# S3_PATH="glpi-backups"
# AWS_CMD="aws"
#
# log "☁️ Envoi sur S3..."
# if "$AWS_CMD" --endpoint-url "$S3_ENDPOINT" s3 cp "$BACKUP_FILE" "s3://$S3_BUCKET/$S3_PATH/" --no-verify-ssl; then
#     log "✅ Envoi S3 réussi: s3://$S3_BUCKET/$S3_PATH/$(basename "$BACKUP_FILE")"
# else
#     error_exit "Échec de l'envoi S3"
# fi

exit 0
