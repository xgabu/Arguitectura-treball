# ============================================
# Backup to QNAP via NFS
# ============================================
# Usage: ./backup-nas.sh [--dry-run]
#
# Syncs local directories to QNAP via NFS mount.
# Excludes git projects (already on GitHub) and caches.
# ============================================

set -euo pipefail

# Configuration
NAS_MOUNT="/mnt/SHARED_QNAP"
BACKUP_ROOT="$NAS_MOUNT/backup-pc"
EXCLUDE_FILE="$(dirname "$0")/backup-ignore.txt"

# Directories to backup (relative to $HOME)
BACKUP_DIRS=(
    "Documents"
    "Pictures"
    "Videos"
    "Downloads"
    "Music"
    "Desktop"
    "Templates"
)

# Hidden directories to backup (configs, keys, etc.)
HIDDEN_DIRS=(
    ".ssh"
    ".gnupg"
    ".local/share/keyrings"
)

DRY_RUN=""
if [[ "${1:-}" == "--dry-run" ]]; then
    DRY_RUN="--dry-run"
    echo "[backup] DRY RUN MODE — no files will be copied"
fi

# ============================================
# Check mount
# ============================================

check_mount() {
    if mountpoint -q "$NAS_MOUNT"; then
        echo "[backup] NAS mounted at $NAS_MOUNT ✓"
        return 0
    fi

    echo "[backup] NAS not mounted at $NAS_MOUNT"
    echo "[backup] Trying to access (systemd automount should trigger)..."

    # Trigger automount by accessing the path
    ls "$NAS_MOUNT" &>/dev/null || true
    sleep 2

    if mountpoint -q "$NAS_MOUNT"; then
        echo "[backup] NAS now mounted ✓"
        return 0
    fi

    echo "[backup] ERROR: Could not mount NAS at $NAS_MOUNT"
    echo "[backup] Check: sudo mount -a"
    exit 1
}

# ============================================
# Rsync helper
# ============================================

sync_dir() {
    local src="$1"
    local dest="$2"
    local label="$3"

    echo "[backup] Syncing: $label"

    rsync -avh --delete \
        --info=progress2 \
        --exclude-from="$EXCLUDE_FILE" \
        $DRY_RUN \
        "$src/" "$dest/"

    echo "[backup] Done: $label"
    echo ""
}

# ============================================
# Main
# ============================================

main() {
    echo ""
    echo "============================================"
    echo "  Backup to QNAP — $(date '+%Y-%m-%d %H:%M')"
    echo "============================================"
    echo ""

    check_mount

    # Create backup root
    mkdir -p "$BACKUP_ROOT"

    # Backup XDG user directories
    for dir in "${BACKUP_DIRS[@]}"; do
        local src="$HOME/$dir"
        local dest="$BACKUP_ROOT/$dir"

        if [[ -d "$src" ]]; then
            mkdir -p "$dest"
            sync_dir "$src" "$dest" "$dir"
        else
            echo "[backup] Skipping $dir — does not exist"
        fi
    done

    # Backup hidden directories (configs, keys)
    for dir in "${HIDDEN_DIRS[@]}"; do
        local src="$HOME/$dir"
        local dest="$BACKUP_ROOT/dotfiles/$dir"

        if [[ -d "$src" ]]; then
            mkdir -p "$dest"
            sync_dir "$src" "$dest" "$dir"
        else
            echo "[backup] Skipping $dir — does not exist"
        fi
    done

    echo "============================================"
    echo "  Backup complete"
    echo "============================================"
}

main "$@"
