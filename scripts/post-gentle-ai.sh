#!/usr/bin/env bash
# ============================================
# Post-install: Gentle AI + OpenCode setup
# ============================================
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
REPO_DIR="$(dirname "$SCRIPT_DIR")"
CONFIGS_DIR="$REPO_DIR/configs/opencode"

echo "[gentle-ai] Setting up Gentle AI + OpenCode..."

# --- Install OpenCode if not present ---
if command -v opencode &>/dev/null; then
    echo "[gentle-ai] OpenCode already installed: $(opencode --version 2>/dev/null || echo 'unknown')"
else
    echo "[gentle-ai] Installing OpenCode via npm..."
    npm install -g opencode
    echo "[gentle-ai] OpenCode installed"
fi

# --- Apply configs ---
OPCODE_DIR="$HOME/.config/opencode"

# opencode.json
if [[ -f "$CONFIGS_DIR/opencode.json" ]]; then
    if [[ -L "$OPCODE_DIR/opencode.json" ]]; then
        echo "[gentle-ai] opencode.json already symlinked"
    elif [[ -f "$OPCODE_DIR/opencode.json" ]]; then
        echo "[gentle-ai] opencode.json exists — backing up"
        mv "$OPCODE_DIR/opencode.json" "$OPCODE_DIR/opencode.json.bak.$(date +%Y%m%d%H%M%S)"
        ln -sf "$CONFIGS_DIR/opencode.json" "$OPCODE_DIR/opencode.json"
    else
        mkdir -p "$OPCODE_DIR"
        ln -sf "$CONFIGS_DIR/opencode.json" "$OPCODE_DIR/opencode.json"
    fi
fi

# AGENTS.md
if [[ -f "$CONFIGS_DIR/AGENTS.md" ]]; then
    if [[ -L "$OPCODE_DIR/AGENTS.md" ]]; then
        echo "[gentle-ai] AGENTS.md already symlinked"
    elif [[ -f "$OPCODE_DIR/AGENTS.md" ]]; then
        echo "[gentle-ai] AGENTS.md exists — backing up"
        mv "$OPCODE_DIR/AGENTS.md" "$OPCODE_DIR/AGENTS.md.bak.$(date +%Y%m%d%H%M%S)"
        ln -sf "$CONFIGS_DIR/AGENTS.md" "$OPCODE_DIR/AGENTS.md"
    else
        mkdir -p "$OPCODE_DIR"
        ln -sf "$CONFIGS_DIR/AGENTS.md" "$OPCODE_DIR/AGENTS.md"
    fi
fi

# Skills directory — only if empty or doesn't exist
SKILLS_DIR="$OPCODE_DIR/skills"
if [[ ! -d "$SKILLS_DIR" ]] || [[ -z "$(ls -A "$SKILLS_DIR" 2>/dev/null)" ]]; then
    echo "[gentle-ai] Skills directory is empty — you'll need to install skills separately"
    echo "[gentle-ai] Run: opencode skill install <skill-name>"
else
    echo "[gentle-ai] Skills directory already has content — skipping"
fi

echo "[gentle-ai] Setup complete"
echo "[gentle-ai] Config: $OPCODE_DIR/opencode.json"
echo "[gentle-ai] Persona: $OPCODE_DIR/AGENTS.md"
