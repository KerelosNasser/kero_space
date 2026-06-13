$ErrorActionPreference = "Stop"

$timestamp = Get-Date -Format "yyyyMMdd_HHmmss"
$backupDir = "backups\$timestamp"
New-Item -ItemType Directory -Force -Path $backupDir | Out-Null

Write-Host "Backing up Postgres database from Docker..."
try {
    docker exec postgres_container pg_dump -U postgres kero_space_db > "$backupDir\postgres_backup.sql"
} catch {
    Write-Host "Postgres backup failed or container not running" -ForegroundColor Yellow
}

Write-Host "Pulling Isar database via ADB..."
try {
    # This requires the app to be debuggable
    adb shell "run-as com.example.kero_space cat databases/default.isar" > "$backupDir\default.isar"
} catch {
    Write-Host "ADB pull failed" -ForegroundColor Yellow
}

Write-Host "Backup complete: $backupDir" -ForegroundColor Green
