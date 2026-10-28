#!/bin/sh
set -e
BACKUP_DIR="/data/backups/db"
mkdir -p "$BACKUP_DIR"
STAMP=$(date +%F_%H%M%S)
PGPASSWORD="${POSTGRES_PASSWORD}" pg_dump -h postgres -U "${POSTGRES_USER}" -d "${POSTGRES_DB}" -Fc > "${BACKUP_DIR}/scratchpad_${STAMP}.dump"
find "$BACKUP_DIR" -type f -name "*.dump" -mtime +30 -delete
echo "Backup completed: ${BACKUP_DIR}/scratchpad_${STAMP}.dump"

