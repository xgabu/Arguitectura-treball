#!/usr/bin/env bash
# ============================================
# CachyOS Setup Script
# Idempotent — safe to run multiple times
# ============================================

set -euo pipefail

# Colors
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m'

# Script directory
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

# ============================================
# Utility functions
# ============================================

log_info()    { echo -e "${BLUE}[INFO]${NC} $1"; }
log_ok()      { echo -e "${GREEN}[OK]${NC} $1"; }
log_warn()    { echo -e "${YELLOW}[WARN]${NC} $1"; }
log_error()   { echo -e "${RED}[ERROR]${NC} $1"; }

run_step() {
    local desc="$1"
    shift
    log_info "$desc"
    if "$@"; then
        log_ok "$desc"
    else
        log_error "$desc — FAILED"
        return 1
    fi
}

# ============================================
# Check prerequisites
# ============================================

check_root() {
    if [[ $EUID -eq 0 ]]; then
        log_error "Do NOT run this script as root. Use your user account."
        exit 1
    fi
}

check_cachyos() {
    if ! grep -qi "cachyos" /etc/os-release 2>/dev/null; then
        log_warn "This script is designed for CachyOS. Some packages may differ on other distros."
        read -rp "Continue anyway? [y/N] " confirm
        [[ "$confirm" =~ ^[Yy] ]] || exit 1
    fi
}

# ============================================
# System packages
# ============================================

install_pacman_packages() {
    local pkg_file="$SCRIPT_DIR/packages.txt"
    [[ -f "$pkg_file" ]] || { log_error "packages.txt not found"; return 1; }

    # Extract pacman packages (before AUR section)
    local packages=()
    while IFS= read -r line; do
        # Skip comments and empty lines
        [[ "$line" =~ ^[[:space:]]*# ]] && continue
        [[ -z "${line// /}" ]] && continue
        # Stop at AUR section
        [[ "$line" =~ ^#.*AUR ]] && break
        packages+=("$line")
    done < "$pkg_file"

    if [[ ${#packages[@]} -eq 0 ]]; then
        log_warn "No pacman packages found in packages.txt"
        return 0
    fi

    log_info "Installing ${#packages[@]} pacman packages..."
    sudo pacman -S --needed --noconfirm "${packages[@]}"
}

install_aur_helper() {
    if command -v yay &>/dev/null; then
        log_info "yay already installed"
        return 0
    fi
    if command -v paru &>/dev/null; then
        log_info "paru already installed"
        return 0
    fi

    log_info "Installing yay (AUR helper)..."
    sudo pacman -S --needed --noconfirm base-devel git
    cd /tmp
    git clone https://aur.archlinux.org/yay-bin.git
    cd yay-bin
    makepkg -si --noconfirm
    cd /
    rm -rf /tmp/yay-bin
    log_ok "yay installed"
}

install_aur_packages() {
    local pkg_file="$SCRIPT_DIR/packages.txt"
    [[ -f "$pkg_file" ]] || return 0

    # Extract AUR packages (after AUR section)
    local packages=()
    local in_aur=false
    while IFS= read -r line; do
        if [[ "$line" =~ ^#.*AUR ]]; then
            in_aur=true
            continue
        fi
        [[ "$line" =~ ^[[:space:]]*# ]] && continue
        [[ -z "${line// /}" ]] && continue
        if $in_aur; then
            packages+=("$line")
        fi
    done < "$pkg_file"

    if [[ ${#packages[@]} -eq 0 ]]; then
        log_info "No AUR packages to install"
        return 0
    fi

    log_info "Installing ${#packages[@]} AUR packages..."
    yay -S --needed --noconfirm "${packages[@]}"
}

# ============================================
# Configuration via symlinks
# ============================================

link_config() {
    local src="$1"    # relative to configs/
    local target="$2" # absolute path in home

    if [[ -L "$target" ]]; then
        log_info "Symlink already exists: $target"
        return 0
    fi

    if [[ -e "$target" ]]; then
        log_warn "File exists (not a symlink): $target — backing up"
        mv "$target" "${target}.bak.$(date +%Y%m%d%H%M%S)"
    fi

    mkdir -p "$(dirname "$target")"
    ln -sf "$src" "$target"
    log_ok "Linked: $target -> $src"
}

apply_configs() {
    local configs_dir="$SCRIPT_DIR/configs"

    # Zsh
    [[ -f "$configs_dir/zsh/.zshrc" ]] && \
        link_config "$configs_dir/zsh/.zshrc" "$HOME/.zshrc"
    [[ -f "$configs_dir/zsh/.zshenv" ]] && \
        link_config "$configs_dir/zsh/.zshenv" "$HOME/.zshenv"

    # Shell (starship, tmux)
    [[ -f "$configs_dir/shell/starship.toml" ]] && \
        link_config "$configs_dir/shell/starship.toml" "$HOME/.config/starship.toml"
    [[ -f "$configs_dir/shell/.tmux.conf" ]] && \
        link_config "$configs_dir/shell/.tmux.conf" "$HOME/.tmux.conf"

    # Hyprland
    if [[ -d "$configs_dir/hyprland" ]]; then
        mkdir -p "$HOME/.config/hypr"
        for f in "$configs_dir/hyprland"/*; do
            [[ -f "$f" ]] || continue
            link_config "$f" "$HOME/.config/hypr/$(basename "$f")"
        done
    fi

    # Brave flags
    [[ -f "$configs_dir/brave/brave-flags.conf" ]] && \
        link_config "$configs_dir/brave/brave-flags.conf" "$HOME/.config/brave-flags.conf"

    # OpenCode / Gentle AI
    [[ -f "$configs_dir/opencode/opencode.json" ]] && \
        link_config "$configs_dir/opencode/opencode.json" "$HOME/.config/opencode/opencode.json"
    [[ -f "$configs_dir/opencode/AGENTS.md" ]] && \
        link_config "$configs_dir/opencode/AGENTS.md" "$HOME/.config/opencode/AGENTS.md"

    log_ok "All configs applied"
}

# ============================================
# Post-install scripts
# ============================================

run_post_install() {
    local scripts_dir="$SCRIPT_DIR/scripts"
    [[ -d "$scripts_dir" ]] || return 0

    for script in "$scripts_dir"/post-*.sh; do
        [[ -f "$script" ]] || continue
        [[ -x "$script" ]] || chmod +x "$script"
        log_info "Running: $(basename "$script")"
        "$script"
    done
}

# ============================================
# LazyVim
# ============================================

install_lazyvim() {
    if [[ -d "$HOME/.config/nvim" ]]; then
        log_info "Neovim config already exists at ~/.config/nvim"
        if [[ -L "$HOME/.config/nvim" ]]; then
            log_info "It's a symlink — assuming it's managed by this repo"
            return 0
        fi
        log_warn "Existing nvim config is NOT a symlink — skipping LazyVim install"
        log_warn "To use this repo's config, remove ~/.config/nvim and re-run"
        return 0
    fi

    log_info "Installing LazyVim..."
    # Backup any existing config
    [[ -d "$HOME/.local/share/nvim" ]] && mv "$HOME/.local/share/nvim" "$HOME/.local/share/nvim.bak"
    [[ -d "$HOME/.local/state/nvim" ]] && mv "$HOME/.local/state/nvim" "$HOME/.local/state/nvim.bak"
    [[ -d "$HOME/.cache/nvim" ]] && mv "$HOME/.cache/nvim" "$HOME/.cache/nvim.bak"

    # Clone LazyVim starter
    git clone https://github.com/LazyVim/starter "$HOME/.config/nvim"

    # If we have custom lazyvim config, overlay it
    if [[ -d "$SCRIPT_DIR/configs/lazyvim" ]]; then
        cp -r "$SCRIPT_DIR/configs/lazyvim/"* "$HOME/.config/nvim/"
    fi

    log_ok "LazyVim installed"
}

# ============================================
# Default shell
# ============================================

set_default_shell() {
    if [[ "$SHELL" != */zsh ]]; then
        log_info "Setting zsh as default shell..."
        chsh -s "$(which zsh)"
        log_ok "Default shell changed to zsh"
    else
        log_info "zsh is already the default shell"
    fi
}

# ============================================
# Main
# ============================================

main() {
    echo ""
    echo "============================================"
    echo "  CachyOS Setup — Arguitectura-treball"
    echo "============================================"
    echo ""

    check_root
    check_cachyos

    echo ""
    read -rp "This will install packages and apply configs. Continue? [y/N] " confirm
    [[ "$confirm" =~ ^[Yy] ]] || { log_info "Aborted"; exit 0; }

    run_step "Installing pacman packages" install_pacman_packages
    run_step "Installing AUR helper" install_aur_helper
    run_step "Installing AUR packages" install_aur_packages
    run_step "Applying configs (symlinks)" apply_configs
    run_step "Installing LazyVim" install_lazyvim
    run_step "Setting default shell" set_default_shell
    run_step "Running post-install scripts" run_post_install

    echo ""
    echo "============================================"
    echo "  Setup complete!"
    echo "============================================"
    echo ""
    log_info "Reboot recommended to apply all changes"
    log_info "Open a new terminal or run 'exec zsh' to switch shell"
    echo ""
}

main "$@"
