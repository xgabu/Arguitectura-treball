#!/usr/bin/env bash
# ============================================
# Post-install: Ollama setup
# ============================================
set -euo pipefail

echo "[ollama] Setting up Ollama..."

# Enable and start service
if systemctl is-active --quiet ollama 2>/dev/null; then
    echo "[ollama] Service already running"
else
    sudo systemctl enable ollama
    sudo systemctl start ollama
    echo "[ollama] Service enabled and started"
fi

# Pull small models (~1GB)
MODELS=("qwen2.5:1.5b" "phi3:mini")

for model in "${MODELS[@]}"; do
    if ollama list 2>/dev/null | grep -q "$model"; then
        echo "[ollama] Model already pulled: $model"
    else
        echo "[ollama] Pulling model: $model (this may take a while)..."
        ollama pull "$model" || echo "[ollama] Warning: Failed to pull $model"
    fi
done

echo "[ollama] Setup complete"
