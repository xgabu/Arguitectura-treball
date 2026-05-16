# ============================================
# Zsh Configuration
# ============================================

# --- Plugins (managed by zinit or manual) ---
# Using zinit for plugin management
if [[ ! -d "$HOME/.local/share/zinit/zinit.git" ]]; then
    print -P "%F{33} Installing zinit... %f"
    mkdir -p "$HOME/.local/share/zinit"
    git clone https://github.com/zdharma-continuum/zinit.git \
        "$HOME/.local/share/zinit/zinit.git"
fi

source "$HOME/.local/share/zinit/zinit.git/zinit.zsh"

# --- Core plugins ---
zinit light zsh-users/zsh-autosuggestions
zinit light zsh-users/zsh-completions
zinit light zsh-users/zsh-syntax-highlighting

# --- Options ---
setopt AUTO_CD              # cd by typing directory name
setopt AUTO_PUSHD           # push directories onto stack
setopt PUSHD_IGNORE_DUPS    # no duplicate entries
setopt COMPLETE_ALIASES     # complete aliases
setopt NO_BEEP              # no beep
setopt SHARE_HISTORY        # share history between sessions
setopt HIST_IGNORE_ALL_DUPS # remove older duplicate entries
setopt HIST_REDUCE_BLANKS   # remove superfluous blanks
setopt INC_APPEND_HISTORY   # append immediately

# --- History ---
HISTFILE=~/.zsh_history
HISTSIZE=10000
SAVEHIST=10000

# --- Key bindings ---
bindkey '^[[H' beginning-of-line   # Home
bindkey '^[[F' end-of-line          # End
bindkey '^[[3~' delete-char         # Delete
bindkey '^?' backward-delete-char   # Backspace

# --- Aliases ---
alias ls='eza --icons --group-directories-first'
alias ll='eza -la --icons --group-directories-first'
alias tree='eza -T --icons'
alias cat='bat --plain'
alias grep='rg'
alias find='fd'
alias top='btop'
alias vim='nvim'
alias vi='nvim'

# Git aliases
alias gs='git status'
alias gp='git push'
alias gl='git pull'
alias gc='git commit'
alias gco='git checkout'
alias gb='git branch'
alias gd='git diff'
alias lg='lazygit'

# Directory navigation
alias ..='cd ..'
alias ...='cd ../..'
alias ....='cd ../../..'

# --- Zoxide (smarter cd) ---
eval "$(zoxide init zsh)"

# --- Fzf ---
eval "$(fzf --zsh)"

# --- Starship prompt ---
eval "$(starship init zsh)"

# --- Functions ---

# Extract any archive
extract() {
    if [[ -f "$1" ]]; then
        case "$1" in
            *.tar.bz2)   tar xjf "$1" ;;
            *.tar.gz)    tar xzf "$1" ;;
            *.bz2)       bunzip2 "$1" ;;
            *.rar)       unrar x "$1" ;;
            *.gz)        gunzip "$1" ;;
            *.tar)       tar xf "$1" ;;
            *.tbz2)      tar xjf "$1" ;;
            *.tgz)       tar xzf "$1" ;;
            *.zip)       unzip "$1" ;;
            *.Z)         uncompress "$1" ;;
            *.7z)        7z x "$1" ;;
            *)           echo "'$1' cannot be extracted" ;;
        esac
    else
        echo "'$1' is not a valid file"
    fi
}

# Quick mkdir + cd
mkcd() {
    mkdir -p "$1" && cd "$1"
}

# ============================================
# OpenCode helper
# ============================================

# Quick start opencode in current project
oc() {
    if [[ -d ".git" ]] || [[ -f ".git" ]]; then
        command opencode "$@"
    else
        echo "Not in a git repository. OpenCode works best in a project."
        read -rp "Continue anyway? [y/N] " confirm
        [[ "$confirm" =~ ^[Yy] ]] && command opencode "$@"
    fi
}
