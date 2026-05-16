#!/usr/bin/env bash
# ============================================
# Post-install: OpenCode setup
# ============================================
set -euo pipefail

echo "[opencode] Setting up OpenCode..."

# Check if opencode is installed
if command -v opencode &>/dev/null; then
    echo "[opencode] Already installed: $(opencode --version 2>/dev/null || echo 'unknown')"
else
    echo "[opencode] Installing via npm..."
    npm install -g opencode
    echo "[opencode] Installed"
fi

# Create default config if not exists
OPCODE_CONFIG="$HOME/.config/opencode/opencode.json"
if [[ ! -f "$OPCODE_CONFIG" ]]; then
    mkdir -p "$HOME/.config/opencode"
    cat > "$OPCODE_CONFIG" << 'EOF'
{
  "agent": {
    "gentle-orchestrator": {
      "model": "opencode/default"
    }
  }
}
EOF
    echo "[opencode] Default config created at $OPCODE_CONFIG"
else
    echo "[opencode] Config already exists at $OPCODE_CONFIG"
fi

echo "[opencode] Setup complete"
