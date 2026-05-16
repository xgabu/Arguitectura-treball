#!/usr/bin/env bash
# ============================================
# Post-install: Font cache & XDG dirs
# ============================================
set -euo pipefail

echo "[fonts] Rebuilding font cache..."
fc-cache -fv

echo "[xdg] Setting up XDG user directories..."
xdg-user-dirs-update

echo "[xdg] Setup complete"
