#!/usr/bin/env bash
# ============================================
# Restore from QNAP backup via NFS
# ============================================
# Usage: ./restore-nas.sh [--dry-run] [directory]
#
# Restores backed up directories from QNAP to local machine.
# If no directory specified, restores all.
# ============================================

set -euo pipefail

# Configuration
NAS_MOUNT="/mnt/SHARED_QNAP"
BACKUP_ROOT="$NAS_MOUNT/backup-pc"

DRY_RUN=""
TARGET="${1:-}"

if [[ "$TARGET" == "--dry-run" ]]; then
    DRY_RUN="--dry-run"
    TARGET="${2:-all}"
    echo "[restore] DRY RUN MODE — no files will be restored"
fi

# ============================================
# Check mount
# ============================================

check_mount() {
    if mountpoint -q "$NAS_MOUNT"; then
        echo "[restore] NAS mounted at $NAS_MOUNT ✓"
        return 0
    fi

    echo "[restore] NAS not mounted — triggering automount..."
    ls "$NAS_MOUNT" &>/dev/null || true
    sleep 2

    if mountpoint -q "$NAS_MOUNT"; then
        echo "[restore] NAS now mounted ✓"
        return 0
    fi

    echo "[restore] ERROR: Could not mount NAS"
    exit 1
}

# ============================================
# List available backups
# ============================================

list_backups() {
    echo ""
    echo "Available backups on NAS:"
    echo ""
    if [[ -d "$BACKUP_ROOT" ]]; then
        ls -1 "$BACKUP_ROOT"
    else
        echo "  No backup found at $BACKUP_ROOT"
        echo "  Run backup-nas.sh first"
    fi
    echo ""
}

# ============================================
# Restore a single directory
# ============================================

restore_dir() {
    local name="$1"
    local src="$BACKUP_ROOT/$name"
    local dest="$HOME/$name"

    if [[ ! -d "$src" ]]; then
        echo "[restore] WARNING: No backup found for '$name' on NAS"
        return 1
    fi

    echo "[restore] Restoring: $name"
    echo "  From: $src"
    echo "  To:   $dest"
    echo ""

    mkdir -p "$dest"

    rsync -avh --info=progress2 \
        $DRY_RUN \
        "$src/" "$dest/"

    echo "[restore] Done: $name"
    echo ""
}

# ============================================
# Main
# ============================================

main() {
    echo ""
    echo "============================================"
    echo "  Restore from QNAP — $(date '+%Y-%m-%d %H:%M')"
    echo "============================================"
    echo ""

    check_mount

    if [[ ! -d "$BACKUP_ROOT" ]]; then
        echo "[restore] ERROR: No backup found at $BACKUP_ROOT"
        echo "[restore] Run backup-nas.sh first to create a backup"
        exit 1
    fi

    if [[ "$TARGET" == "all" || -z "$TARGET" ]]; then
        list_backups
        echo "Restoring ALL directories..."
        echo ""

        for dir in "$BACKUP_ROOT"/*/; do
            [[ -d "$dir" ]] || continue
            local name
            name=$(basename "$dir")
            restore_dir "$name"
        done
    else
        restore_dir "$TARGET"
    fi

    echo "============================================"
    echo "  Restore complete"
    echo "============================================"
}

main "$@"
