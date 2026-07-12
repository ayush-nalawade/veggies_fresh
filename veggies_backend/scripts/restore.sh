#!/bin/bash

###############################################################################
# MongoDB Restore Script for VeggieFresh
# This script restores MongoDB database from a backup
###############################################################################

# Configuration
BACKUP_DIR="${BACKUP_DIR:-./backups}"
MONGO_URI="${MONGO_URI:-mongodb://localhost:27017}"
DB_NAME="${DB_NAME:-veggiefresh}"

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

# Check if backup file is provided
if [ -z "$1" ]; then
    error "No backup file specified!"
    echo ""
    echo "Usage: $0 <backup_file>"
    echo ""
    echo "Available backups:"
    ls -lh "$BACKUP_DIR"/*.tar.gz 2>/dev/null || echo "No backups found in $BACKUP_DIR"
    exit 1
fi

BACKUP_FILE="$1"

# Check if backup file exists
if [ ! -f "$BACKUP_FILE" ]; then
    error "Backup file not found: $BACKUP_FILE"
    exit 1
fi

log "Starting MongoDB restore from: $BACKUP_FILE"

# Check if mongorestore is available
if ! command -v mongorestore &> /dev/null; then
    error "mongorestore command not found. Please install MongoDB Database Tools."
    error "Visit: https://www.mongodb.com/try/download/database-tools"
    exit 1
fi

# Create temporary directory for extraction
TEMP_DIR=$(mktemp -d)
log "Created temporary directory: $TEMP_DIR"

# Extract backup
log "Extracting backup..."
if tar -xzf "$BACKUP_FILE" -C "$TEMP_DIR"; then
    log "Backup extracted successfully"
else
    error "Failed to extract backup"
    rm -rf "$TEMP_DIR"
    exit 1
fi

# Find the backup directory
BACKUP_NAME=$(basename "$BACKUP_FILE" .tar.gz)
RESTORE_PATH="$TEMP_DIR/$BACKUP_NAME/$DB_NAME"

if [ ! -d "$RESTORE_PATH" ]; then
    error "Backup directory not found: $RESTORE_PATH"
    rm -rf "$TEMP_DIR"
    exit 1
fi

# Confirm restore
warn "WARNING: This will replace the current database: $DB_NAME"
read -p "Are you sure you want to continue? (yes/no): " -r
echo
if [[ ! $REPLY =~ ^[Yy][Ee][Ss]$ ]]; then
    log "Restore cancelled by user"
    rm -rf "$TEMP_DIR"
    exit 0
fi

# Perform restore
log "Restoring database: $DB_NAME"
if mongorestore --uri="$MONGO_URI" --db="$DB_NAME" --gzip --drop "$RESTORE_PATH"; then
    log "Database restored successfully!"
    
    # Clean up
    log "Cleaning up temporary files..."
    rm -rf "$TEMP_DIR"
    
    log "Restore completed successfully!"
    exit 0
else
    error "Restore failed!"
    rm -rf "$TEMP_DIR"
    exit 1
fi
