# Database Backup and Restore Strategy

## Overview
This document outlines the comprehensive backup and restore strategy for the VeggieFresh MongoDB database, ensuring data protection and disaster recovery capabilities.

---

## Backup Strategy

### 1. Automated Daily Backups

**Location:** `./backups/`  
**Retention:** 30 days for compressed backups  
**Format:** Compressed `.tar.gz` archives with gzip compression  
**Naming:** `veggiefresh_backup_YYYYMMDD_HHMMSS.tar.gz`

### 2. Backup Script

**File:** `scripts/backup.sh`

#### Features:
- ✅ Automated MongoDB database backup using `mongodump`
- ✅ Automatic compression with gzip
- ✅ Configurable retention policy (default: 30 days)
- ✅ Automatic cleanup of old backups
- ✅ Detailed logging with timestamps
- ✅ Error handling and validation

#### Usage:

```bash
# Basic backup (uses default settings)
./scripts/backup.sh

# Custom backup directory
BACKUP_DIR=/path/to/backups ./scripts/backup.sh

# Custom retention period (14 days)
RETENTION_DAYS=14 ./scripts/backup.sh

# Custom MongoDB URI
MONGO_URI="mongodb://user:pass@localhost:27017" ./scripts/backup.sh

# All custom settings
BACKUP_DIR=/backups \
MONGO_URI="mongodb://localhost:27017" \
DB_NAME=veggiefresh \
RETENTION_DAYS=30 \
./scripts/backup.sh
```

#### Environment Variables:

| Variable | Default | Description |
|----------|---------|-------------|
| `BACKUP_DIR` | `./backups` | Directory to store backups |
| `MONGO_URI` | `mongodb://localhost:27017` | MongoDB connection URI |
| `DB_NAME` | `veggiefresh` | Database name to backup |
| `RETENTION_DAYS` | `30` | Number of days to keep backups |

---

## Restore Strategy

### Restore Script

**File:** `scripts/restore.sh`

#### Features:
- ✅ Restore from compressed backup archives
- ✅ Safety confirmation before restore
- ✅ Automatic extraction and cleanup
- ✅ Database drop and replace
- ✅ Detailed logging

#### Usage:

```bash
# List available backups
ls -lh backups/*.tar.gz

# Restore from specific backup
./scripts/restore.sh backups/veggiefresh_backup_20251228_120000.tar.gz

# Custom MongoDB URI
MONGO_URI="mongodb://localhost:27017" \
./scripts/restore.sh backups/veggiefresh_backup_20251228_120000.tar.gz

# Custom database name
DB_NAME=veggiefresh_test \
./scripts/restore.sh backups/veggiefresh_backup_20251228_120000.tar.gz
```

#### Safety Features:
- Requires explicit confirmation before restore
- Displays warning about data replacement
- Validates backup file existence
- Automatic cleanup of temporary files

---

## Automated Backup Schedule

### Using Cron (Linux/macOS)

#### 1. Daily Backup at 2 AM

```bash
# Edit crontab
crontab -e

# Add this line for daily backup at 2 AM
0 2 * * * cd /path/to/veggies_backend && ./scripts/backup.sh >> logs/backup.log 2>&1
```

#### 2. Hourly Backup (Production)

```bash
# Backup every hour
0 * * * * cd /path/to/veggies_backend && ./scripts/backup.sh >> logs/backup.log 2>&1
```

#### 3. Weekly Backup (Sunday at 3 AM)

```bash
# Weekly backup on Sunday at 3 AM
0 3 * * 0 cd /path/to/veggies_backend && ./scripts/backup.sh >> logs/backup.log 2>&1
```

### Using systemd Timer (Linux)

#### 1. Create Service File

**File:** `/etc/systemd/system/veggiefresh-backup.service`

```ini
[Unit]
Description=VeggieFresh Database Backup
After=network.target

[Service]
Type=oneshot
User=your-user
WorkingDirectory=/path/to/veggies_backend
Environment="BACKUP_DIR=/var/backups/veggiefresh"
Environment="RETENTION_DAYS=30"
ExecStart=/path/to/veggies_backend/scripts/backup.sh
StandardOutput=append:/var/log/veggiefresh-backup.log
StandardError=append:/var/log/veggiefresh-backup.log
```

#### 2. Create Timer File

**File:** `/etc/systemd/system/veggiefresh-backup.timer`

```ini
[Unit]
Description=VeggieFresh Database Backup Timer
Requires=veggiefresh-backup.service

[Timer]
OnCalendar=daily
OnCalendar=02:00
Persistent=true

[Install]
WantedBy=timers.target
```

#### 3. Enable and Start Timer

```bash
sudo systemctl daemon-reload
sudo systemctl enable veggiefresh-backup.timer
sudo systemctl start veggiefresh-backup.timer

# Check timer status
sudo systemctl status veggiefresh-backup.timer
sudo systemctl list-timers
```

---

## Backup Storage Recommendations

### 1. Local Storage
- **Location:** `./backups/` (development)
- **Location:** `/var/backups/veggiefresh/` (production)
- **Pros:** Fast, immediate access
- **Cons:** Vulnerable to hardware failure

### 2. Remote Storage (Recommended for Production)

#### AWS S3
```bash
# Install AWS CLI
pip install awscli

# Sync backups to S3
aws s3 sync ./backups/ s3://your-bucket/veggiefresh-backups/

# Add to backup script
echo "aws s3 sync $BACKUP_DIR s3://your-bucket/veggiefresh-backups/" >> scripts/backup.sh
```

#### Google Cloud Storage
```bash
# Install gsutil
pip install gsutil

# Sync backups to GCS
gsutil -m rsync -r ./backups/ gs://your-bucket/veggiefresh-backups/
```

#### Rsync to Remote Server
```bash
# Sync to remote server
rsync -avz --delete ./backups/ user@remote-server:/backups/veggiefresh/
```

### 3. Multi-Location Strategy (Best Practice)
- **Primary:** Local storage for quick access
- **Secondary:** Cloud storage (S3/GCS) for disaster recovery
- **Tertiary:** Off-site physical backup (weekly)

---

## Backup Verification

### 1. Automated Verification Script

**File:** `scripts/verify-backup.sh`

```bash
#!/bin/bash

BACKUP_FILE="$1"

if [ -z "$BACKUP_FILE" ]; then
    echo "Usage: $0 <backup_file>"
    exit 1
fi

echo "Verifying backup: $BACKUP_FILE"

# Check file integrity
if tar -tzf "$BACKUP_FILE" > /dev/null 2>&1; then
    echo "✅ Backup archive is valid"
else
    echo "❌ Backup archive is corrupted"
    exit 1
fi

# Check backup size
SIZE=$(du -h "$BACKUP_FILE" | cut -f1)
echo "Backup size: $SIZE"

# List contents
echo "Backup contents:"
tar -tzf "$BACKUP_FILE" | head -20

echo "✅ Backup verification complete"
```

### 2. Test Restore (Monthly)

```bash
# Create test database
DB_NAME=veggiefresh_test ./scripts/restore.sh backups/latest_backup.tar.gz

# Verify data
mongo veggiefresh_test --eval "db.stats()"

# Drop test database
mongo veggiefresh_test --eval "db.dropDatabase()"
```

---

## Disaster Recovery Plan

### 1. Complete Database Loss

**Recovery Time Objective (RTO):** 1 hour  
**Recovery Point Objective (RPO):** 24 hours (daily backups)

#### Steps:
1. Identify latest valid backup
2. Verify backup integrity
3. Stop application server
4. Restore database from backup
5. Verify data integrity
6. Restart application server
7. Monitor for issues

```bash
# 1. List available backups
ls -lh backups/*.tar.gz

# 2. Verify backup
./scripts/verify-backup.sh backups/veggiefresh_backup_LATEST.tar.gz

# 3. Stop application
pm2 stop veggiefresh-api

# 4. Restore database
./scripts/restore.sh backups/veggiefresh_backup_LATEST.tar.gz

# 5. Verify data
mongo veggiefresh --eval "db.stats()"

# 6. Restart application
pm2 start veggiefresh-api

# 7. Check logs
pm2 logs veggiefresh-api
```

### 2. Partial Data Loss

**Scenario:** Accidental deletion of specific collection

```bash
# Restore to temporary database
DB_NAME=veggiefresh_temp ./scripts/restore.sh backups/latest.tar.gz

# Export specific collection
mongoexport --db=veggiefresh_temp --collection=orders --out=orders.json

# Import to production
mongoimport --db=veggiefresh --collection=orders --file=orders.json

# Clean up
mongo veggiefresh_temp --eval "db.dropDatabase()"
```

### 3. Data Corruption

**Scenario:** Database corruption detected

```bash
# 1. Create emergency backup of current state
./scripts/backup.sh

# 2. Restore from last known good backup
./scripts/restore.sh backups/veggiefresh_backup_GOOD.tar.gz

# 3. Verify integrity
mongo veggiefresh --eval "db.runCommand({validate: 'orders'})"
```

---

## Monitoring and Alerts

### 1. Backup Success Monitoring

```bash
# Check last backup age
find backups/ -name "*.tar.gz" -mtime -1 -ls

# Alert if no backup in last 24 hours
if [ $(find backups/ -name "*.tar.gz" -mtime -1 | wc -l) -eq 0 ]; then
    echo "ALERT: No backup created in last 24 hours!"
    # Send alert email/SMS
fi
```

### 2. Backup Size Monitoring

```bash
# Monitor backup size trends
du -sh backups/*.tar.gz | tail -5

# Alert on unusual size changes
LATEST_SIZE=$(du -b backups/*.tar.gz | tail -1 | cut -f1)
PREVIOUS_SIZE=$(du -b backups/*.tar.gz | tail -2 | head -1 | cut -f1)

if [ $LATEST_SIZE -lt $((PREVIOUS_SIZE / 2)) ]; then
    echo "ALERT: Backup size dropped significantly!"
fi
```

### 3. Storage Space Monitoring

```bash
# Check available disk space
df -h backups/

# Alert if less than 10GB available
AVAILABLE=$(df backups/ | tail -1 | awk '{print $4}' | sed 's/G//')
if [ $AVAILABLE -lt 10 ]; then
    echo "ALERT: Low disk space for backups!"
fi
```

---

## Best Practices

### 1. Backup Frequency
- **Development:** Daily backups
- **Staging:** Daily backups with 14-day retention
- **Production:** Hourly backups with 30-day retention

### 2. Testing
- ✅ Test restore process monthly
- ✅ Verify backup integrity weekly
- ✅ Document restore procedures
- ✅ Train team on recovery process

### 3. Security
- ✅ Encrypt backups at rest
- ✅ Encrypt backups in transit
- ✅ Restrict access to backup files
- ✅ Use separate credentials for backup user

### 4. Documentation
- ✅ Document backup locations
- ✅ Document restore procedures
- ✅ Maintain backup logs
- ✅ Track backup success/failure

---

## Troubleshooting

### Backup Fails

```bash
# Check mongodump is installed
which mongodump

# Check MongoDB connection
mongo $MONGO_URI --eval "db.stats()"

# Check disk space
df -h

# Check permissions
ls -la backups/
```

### Restore Fails

```bash
# Verify backup file
tar -tzf backup_file.tar.gz

# Check mongorestore is installed
which mongorestore

# Check MongoDB connection
mongo $MONGO_URI --eval "db.stats()"

# Try manual restore
tar -xzf backup_file.tar.gz
mongorestore --uri=$MONGO_URI --db=veggiefresh --gzip backup_dir/
```

### Backup Too Large

```bash
# Compress older backups
gzip backups/*.bson

# Archive old backups to cold storage
tar -czf archive_2024.tar.gz backups/veggiefresh_backup_2024*.tar.gz
mv archive_2024.tar.gz /archive/

# Clean up archived backups
rm backups/veggiefresh_backup_2024*.tar.gz
```

---

## Quick Reference

### Common Commands

```bash
# Create backup
./scripts/backup.sh

# List backups
ls -lh backups/*.tar.gz

# Restore from backup
./scripts/restore.sh backups/veggiefresh_backup_YYYYMMDD_HHMMSS.tar.gz

# Verify backup
tar -tzf backups/veggiefresh_backup_YYYYMMDD_HHMMSS.tar.gz

# Check backup age
find backups/ -name "*.tar.gz" -mtime -1

# Clean old backups manually
find backups/ -name "*.tar.gz" -mtime +30 -delete
```

### Emergency Contacts

- **Database Admin:** [Contact Info]
- **DevOps Team:** [Contact Info]
- **On-Call Engineer:** [Contact Info]

---

**Version:** 1.0.0  
**Last Updated:** 2025-12-28  
**Maintained By:** VeggieFresh DevOps Team
