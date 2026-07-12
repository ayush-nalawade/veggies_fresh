#!/bin/bash

###############################################################################
# MongoDB Backup Script for VeggieFresh
# This script creates automated backups of the MongoDB database
###############################################################################

# Configuration
BACKUP_DIR="${BACKUP_DIR:-./backups}"
MONGO_URI="${MONGO_URI:-mongodb://localhost:27017}"
DB_NAME="${DB_NAME:-veggiefresh}"
RETENTION_DAYS="${RETENTION_DAYS:-30}"
TIMESTAMP=$(date +"%Y%m%d_%H%M%S")
BACKUP_NAME="veggiefresh_backup_${TIMESTAMP}"

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

# Logging function
log() {
    echo -e "${GREEN}[$(date +'%Y-%m-%d %H:%M:%S')]${NC} $1"
}

error() {
    echo -e "${RED}[$(date +'%Y-%m-%d %H:%M:%S')] ERROR:${NC} $1"
}

warn() {
    echo -e "${YELLOW}[$(date +'%Y-%m-%d %H:%M:%S')] WARNING:${NC} $1"
}

# Create backup directory if it doesn't exist
mkdir -p "$BACKUP_DIR"

log "Starting MongoDB backup for database: $DB_NAME"

# Check if mongodump is available
if ! command -v mongodump &> /dev/null; then
    error "mongodump command not found. Please install MongoDB Database Tools."
    error "Visit: https://www.mongodb.com/try/download/database-tools"
    exit 1
fi

# Create backup
log "Creating backup: $BACKUP_NAME"
if mongodump --uri="$MONGO_URI" --db="$DB_NAME" --out="$BACKUP_DIR/$BACKUP_NAME" --gzip; then
    log "Backup created successfully: $BACKUP_DIR/$BACKUP_NAME"
    
    # Create a compressed archive
    log "Compressing backup..."
    cd "$BACKUP_DIR" || exit 1
    tar -czf "${BACKUP_NAME}.tar.gz" "$BACKUP_NAME"
    
    if [ $? -eq 0 ]; then
        log "Backup compressed: ${BACKUP_NAME}.tar.gz"
        # Remove uncompressed backup
        rm -rf "$BACKUP_NAME"
        log "Removed uncompressed backup directory"
    else
        error "Failed to compress backup"
        exit 1
    fi
    
    # Calculate backup size
    BACKUP_SIZE=$(du -h "${BACKUP_NAME}.tar.gz" | cut -f1)
    log "Backup size: $BACKUP_SIZE"
    
    # Clean up old backups
    log "Cleaning up backups older than $RETENTION_DAYS days..."
    find "$BACKUP_DIR" -name "veggiefresh_backup_*.tar.gz" -type f -mtime +$RETENTION_DAYS -delete
    
    # Count remaining backups
    BACKUP_COUNT=$(find "$BACKUP_DIR" -name "veggiefresh_backup_*.tar.gz" -type f | wc -l)
    log "Total backups retained: $BACKUP_COUNT"
    
    log "Backup completed successfully!"
    exit 0
else
    error "Backup failed!"
    exit 1
fi
