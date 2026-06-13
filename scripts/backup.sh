#!/bin/bash
set -e

BACKUP_DIR="backups/$(date +%Y%m%d_%H%M%S)"
mkdir -p "$BACKUP_DIR"

echo "Backing up Postgres database from Docker..."
docker exec postgres_container pg_dump -U postgres kero_space_db > "$BACKUP_DIR/postgres_backup.sql" || echo "Postgres backup failed or container not running"

echo "Pulling Isar database via ADB..."
# Ensure app is debuggable or use run-as
adb shell "run-as com.example.kero_space cat databases/default.isar" > "$BACKUP_DIR/default.isar" || echo "ADB pull failed"

echo "Backup complete: $BACKUP_DIR"
