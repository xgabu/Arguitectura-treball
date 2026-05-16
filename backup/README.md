# Backup Strategy

## Architecture

```
PC Local (1TB)          QNAP (2TB)              MEGA (20GB)
├── Documents ──────────► Documents ────────────► Documents
├── Pictures  ──────────► Pictures  ────────────► Pictures (selectiu)
├── Videos    ──────────► Videos                (via HBS 3 al QNAP)
├── Downloads ──────────► Downloads
└── Projects (git)      (NO sync — ja és a GitHub)
```

## NFS Mount

Configurat a `/etc/fstab`:

```
192.168.2.105:/multimedia    /mnt/SHARED_QNAP    nfs    defaults,_netdev,nofail,x-systemd.automount    0 0
```

## Scripts

### Backup (PC → QNAP)

```bash
# Backup everything
./backup/backup-nas.sh

# Preview what would be synced
./backup/backup-nas.sh --dry-run
```

Syncs via `rsync` with `--delete` (mirrors local state).
Excludes: `.git/`, `node_modules/`, `.cache/`, browser profiles, thumbnails.

### Restore (QNAP → PC)

```bash
# Restore everything
./backup/restore-nas.sh

# Restore specific directory
./backup/restore-nas.sh Documents

# Preview restore
./backup/restore-nas.sh --dry-run
```

### Automatització (systemd timer)

```bash
# Copy timer files
cp backup/backup-nas.timer ~/.config/systemd/user/
cp backup/backup-nas.service ~/.config/systemd/user/

# Enable
systemctl --user enable --now backup-nas.timer

# Check status
systemctl --user status backup-nas.timer
```

## QNAP → MEGA (via HBS 3)

**Això es configura al QNAP, no al PC.**

1. Obre QNAP → **Hybrid Backup Sync 3**
2. **Sync** → **Create** → **One-way Sync**
3. Remote: **Cloud Storage** → **MEGA**
4. Autentica amb el teu compte MEGA
5. Selecciona carpetes a sincronitzar:
   - `backup-pc/Documents/`
   - `backup-pc/Pictures/` (només importants)
6. Programa: **Daily** o **Weekly**
7. **Important**: No sincronitzis `Videos/` ni `Downloads/` — ocupen massa per 20GB

### Què sincronitzar a MEGA (<20GB)

| Carpeta | Mida estimada | Sync? |
|---------|---------------|-------|
| Documents | ~2-5GB | ✅ Sí |
| .ssh, .gnupg | ~10MB | ✅ Sí |
| Pictures (selectiu) | ~5-10GB | ✅ Parcial |
| Videos | ~100GB+ | ❌ No |
| Downloads | Variable | ❌ No |

## Flux de recuperació completa

Si et peta el PC:

```bash
# 1. Instal·la CachyOS
# 2. Clona dotfiles
git clone git@github.com:xgabu/Arguitectura-treball.git
cd Arguitectura-treball
./setup.sh
reboot

# 3. Restaura dades
./backup/restore-nas.sh

# 4. Clona projectes git
# (ja són a GitHub, clona'ls un per un)
```

## Exclusions

Edita `backup-ignore.txt` per afegir patrons a excloure.
Per defecte exclou: `.git/`, `node_modules/`, `.cache/`, browser profiles, thumbnails.
