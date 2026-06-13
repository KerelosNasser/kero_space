# Backup Setup Guide

The `scripts/` directory contains tools to extract data from Kero Space and its backing Postgres (if applicable).

## Android / Linux / macOS
To run daily backups, you can set up a `cron` job:

1. Open crontab:
   ```bash
   crontab -e
   ```
2. Add the following entry to backup every day at 3:00 AM:
   ```bash
   0 3 * * * /path/to/kero_space/scripts/backup.sh >> /var/log/kero_backup.log 2>&1
   ```

## Windows
To run daily backups using Task Scheduler:

1. Open **Task Scheduler** and click **Create Basic Task...**
2. Name it "Kero Space Backup" and set Trigger to **Daily**.
3. Set Action to **Start a program**.
4. Program/script: `powershell.exe`
5. Add arguments: `-ExecutionPolicy Bypass -File "C:\path\to\kero_space\scripts\backup.ps1"`
6. Finish and save.

> Note: To backup the local Android Isar database, your device must be connected via USB or wireless debugging, and ADB must be authorized.
