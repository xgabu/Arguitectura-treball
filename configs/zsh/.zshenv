# ============================================
# Zsh environment variables
# ============================================

# Editor
export EDITOR="nvim"
export VISUAL="nvim"

# Path additions
export PATH="$HOME/.local/bin:$HOME/go/bin:$HOME/.cargo/bin:$PATH"

# Go
export GOPATH="$HOME/go"

# Rust
export RUSTUP_HOME="$HOME/.rustup"
export CARGO_HOME="$HOME/.cargo"

# Neovim
export NVIM_APPNAME="nvim"

# Less (use bat as pager)
export MANPAGER="sh -c 'col -bx | bat -l man -p'"
export MANROFFOPT="-c"

# XDG directories
export XDG_CONFIG_HOME="$HOME/.config"
export XDG_DATA_HOME="$HOME/.local/share"
export XDG_STATE_HOME="$HOME/.local/state"
export XDG_CACHE_HOME="$HOME/.cache"

# Disable oh-my-zsh update prompt (we use zinit)
export DISABLE_AUTO_UPDATE="true"

# Locale
export LANG="en_US.UTF-8"
export LC_ALL="en_US.UTF-8"
