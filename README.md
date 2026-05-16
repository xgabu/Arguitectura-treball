# Arguitectura-treball

Dotfiles i configuració per reinstal·lar CachyOS de zero.

## Reinstal·lació ràpida

```bash
# 1. Clonar el repo
git clone git@github.com:xgabu/Arguitectura-treball.git
cd Arguitectura-treball

# 2. Executar el setup
chmod +x setup.sh
./setup.sh

# 3. Reboot
reboot
```

## Estructura

```
├── setup.sh              # Script principal (idempotent)
├── packages.txt          # Llista de paquets pacman + AUR
├── configs/
│   ├── hyprland/         # Hyprland WM config
│   ├── lazyvim/          # LazyVim (Neovim) config
│   ├── opencode/         # OpenCode + Gentle AI (opencode.json, AGENTS.md)
│   ├── zsh/              # .zshrc, .zshenv
│   ├── shell/            # starship.toml, .tmux.conf
│   └── brave/            # brave-flags.conf
└── scripts/              # Scripts individuals
```

## Stack

| Component | Elecció |
|-----------|---------|
| OS | CachyOS |
| WM | Hyprland (Wayland) |
| Terminal | Foot / Kitty |
| Shell | Zsh + zinit + starship |
| Editor | Neovim (LazyVim) |
| Browser | Brave |
| AI | OpenCode + Ollama (models ~1GB) |
| Multiplexer | Tmux |

## Com funciona

El `setup.sh` és **idempotent** — es pot executar múltiples vegades sense trencar res:

1. **Instal·la paquets** — `pacman -S --needed` (només els que falten)
2. **Instal·la yay** — AUR helper (si no existeix)
3. **Instal·la paquets AUR** — `yay -S --needed`
4. **Aplica configs** — Crea symlinks de `configs/` a `~/.config/` (inclòs Gentle AI)
5. **Instal·la LazyVim** — Clona starter si no existeix `~/.config/nvim`
6. **Configura zsh** — Canvia shell per defecte
7. **Executa post-install** — Ollama, OpenCode, fonts

## Afegir nous paquets

Edita `packages.txt`:
- Secció superior → paquets pacman
- Secció `# AUR` → paquets AUR

Executa `./setup.sh` de nou — només instal·larà els nous.

## Afegir noves configs

1. Crea el fitxer a `configs/<categoria>/`
2. Afegeix la regla de symlink a `setup.sh` (funció `apply_configs`)
3. Executa `./setup.sh`

## Dreceres Hyprland

| Drecera | Acció |
|---------|-------|
| `SUPER + Return` | Terminal (foot) |
| `SUPER + Space` | Launcher (rofi) |
| `SUPER + B` | Brave |
| `SUPER + E` | Nautilus |
| `SUPER + Q` | Tancar finestra |
| `SUPER + F` | Fullscreen |
| `SUPER + T` | Toggle floating |
| `SUPER + 1-0` | Canviar workspace |
| `SUPER + ←↑↓→` | Moure focus |
| `Print` | Screenshot (selecció) |

## LazyVim (Neovim)

Dreceres bàsiques:

| Drecera | Acció |
|---------|-------|
| `<leader>ff` | Buscar fitxer |
| `<leader>fg` | Buscar text al projecte |
| `<leader>ft` | Toggle terminal |
| `<leader>u` | Undo tree |
| `]c` / `[c` | Saltar canvis git |
| `gd` | Anar a definició |
| `gr` | Referències |
| `<C-d>` / `<C-u>` | Pàgina avall/amunt |

## Notes

- Els fitxers de config existents es fan backup automàticament (`.bak.TIMESTAMP`)
- LazyVim només s'instal·la si no existeix `~/.config/nvim`
- El script detecta si ja tens zsh com a shell per defecte
