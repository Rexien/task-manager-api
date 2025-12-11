#!/bin/bash

# Configuration
BACKUP_DIR="./backups"
TIMESTAMP=$(date +"%Y%m%d_%H%M%S")
BACKUP_FILE="$BACKUP_DIR/backup_$TIMESTAMP.sql"

# Create backup dir if not exists
mkdir -p $BACKUP_DIR

echo "📦 Backing up database to $BACKUP_FILE..."

# Dump database from the 'db' container
docker-compose exec -T db pg_dump -U postgres taskmanager > $BACKUP_FILE

# Keep only last 7 days of backups
find $BACKUP_DIR -type f -name "*.sql" -mtime +7 -delete

echo "✅ Backup complete!"
