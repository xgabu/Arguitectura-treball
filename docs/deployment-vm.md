# Guia de Desplegament en VM (CachyOS)

Aquest document descriu el procediment estàndard per desplegar la configuració d'`Arguitectura-treball` en una màquina virtual CachyOS fresca.

## 1. Preparació de la VM

### 1.0. Preparació de l'Host (Espai)
Per defecte, libvirt guarda les imatges a `/var/lib/libvirt/images/`, que pot tenir poc espai.
Es recomana moure les imatges al directori home de l'usuari:

```bash
# 1. Crear directori VMs
mkdir -p ~/VMs

# 2. Moure imatges existents (si n'hi ha)
sudo mv /var/lib/libvirt/images/*.qcow2 ~/VMs/
sudo mv /var/lib/libvirt/images/*.iso ~/VMs/
sudo mv /var/lib/libvirt/images/*_VARS.fd ~/VMs/

# 3. Actualitzar la definició de la VM
virsh -c qemu:///system dumpxml cachyos-test > /tmp/vm.xml
sed -i "s|/var/lib/libvirt/images/|/home/TU_USUARI/VMs/|g" /tmp/vm.xml
virsh -c qemu:///system define /tmp/vm.xml
```

### 1.1. Instal·lació Base
1.  Arrenca la VM amb la ISO de CachyOS.
2.  Segueix l'instal·lador amb aquesta configuració:
    - **Bootloader**: `systemd-boot` (recomanat per UEFI) o `GRUB`.
    - **Desktop**: `Hyprland`.
    - **Paquets**: Selecciona `CachyOS Packages`, `Base-devel`, `Hyprland` i `Firefox`.
    - **Particions**: Deixa que l'instal·lador gestioni el disk automàticament.
3.  Un cop acabada la instal·lació, **reinicia** i treu la ISO del lector virtual.

### 1.2. Configuració Inicial (Primer Arrencada)
1.  Inicia sessió amb l'usuari creat durant la instal·lació.
2.  **Verifica la xarxa**:
    ```bash
    ip addr show
    ping -c 3 cachyos.org
    ```
    *Si no hi ha xarxa, revisa la configuració de la xarxa virtual a libvirt (`default` network).*

3.  **Actualitza el sistema base** (important abans de clonar):
    ```bash
    sudo pacman -Syu --noconfirm
    ```

## 2. Configuració d'Accés SSH

Per automatitzar el desplegament, cal accés SSH des de l'host.

### 2.1. A la VM (Com a usuari normal)
```bash
# 1. Crea la carpeta .ssh
mkdir -p ~/.ssh
chmod 700 ~/.ssh

# 2. Afegeix la teva clau pública de l'host
# (Copia el contingut de ~/.ssh/id_ed25519.pub de l'host i enganxa'l aquí)
nano ~/.ssh/authorized_keys
chmod 600 ~/.ssh/authorized_keys

# 3. Instal·la i activa el servei SSH
sudo pacman -S openssh --noconfirm
sudo systemctl enable --now sshd

# 4. **IMPORTANT**: Obre el tallafocs (CachyOS el té actiu per defecte)
sudo ufw allow ssh
sudo ufw enable

# 5. Verifica que funciona (des de l'host)
# ssh TU_USUARI@IP_DE_LA_VM
```

### 2.2. A l'Host
Troba la IP de la VM:
```bash
virsh -c qemu:///system domifaddr cachyos-test
```

Prova la connexió:
```bash
ssh TU_USUARI@IP_DE_LA_VM
```

### 2.3. Configuració de Clau SSH per GitHub (Opcional però recomanat)
Si la VM necessita accés a GitHub (per clonar el repo o fer push), genera una clau SSH:
```bash
# 1. Genera la clau
ssh-keygen -t ed25519 -C "xaumegb@cachyos-vm"
# (Prem Enter per acceptar defaults i sense contrasenya)

# 2. Mostra la clau pública
cat ~/.ssh/id_ed25519.pub

# 3. Afegeix-la a GitHub Settings > SSH Keys
```

## 3. Desplegament de la Configuració

Un cop tinguis accés SSH, executa els següents passos **dins de la VM** (o via SSH):

### 3.1. Clonar el Repositori
```bash
git clone git@github.com:xgabu/Arguitectura-treball.git
cd Arguitectura-treball
```

### 3.2. Executar el Setup
El script `setup.sh` és idempotent i segur.
```bash
chmod +x setup.sh
./setup.sh
```

**Què fa el script?**
1.  Instal·la paquets base (`pacman`) i AUR (`yay`).
2.  Aplica configs via symlinks (`configs/` → `~/.config/`).
3.  Instal·la LazyVim (Neovim).
4.  Configura Zsh com a shell per defecte.
5.  Executa scripts de post-instal·lació (Ollama, OpenCode, fonts).

### 3.3. Post-Instal·lació Manual
Després del script, és recomanable:
1.  **Reiniciar** la sessió o fer `exec zsh` per carregar la nova configuració.
2.  **Verificar serveis**:
    ```bash
    systemctl --user status hyprland  # Si estàs en sessió gràfica
    ollama list                       # Verificar models
    ```

## 4. Verificació

Executa aquesta llista de comprovació per assegurar que tot és correcte:

| Component | Comprovar | Comandament |
|-----------|-----------|-------------|
| **Shell** | Zsh actiu | `echo $SHELL` → `/bin/zsh` |
| **WM** | Hyprland corrent | `hyprctl version` |
| **Editor** | Neovim + LazyVim | `nvim --version` |
| **AI** | Ollama actiu | `ollama list` |
| **Configs** | Symlinks correctes | `ls -la ~/.config/hypr` |

## 5. Troubleshooting

### Error: `pacman: keyring is outdated`
```bash
sudo pacman-key --init
sudo pacman-key --populate archlinux cachyos
sudo pacman -Sy archlinux-keyring cachyos-keyring
```

### Error: `yay: command not found`
El script hauria d'instal·lar-lo automàticament. Si falla:
```bash
sudo pacman -S --needed base-devel git
cd /tmp && git clone https://aur.archlinux.org/yay-bin.git
cd yay-bin && makepkg -si --noconfirm
```

### Error: `git clone: Permission denied (publickey)`
Assegura't que la clau SSH està ben configurada a `~/.ssh/authorized_keys` a la VM i que `sshd` està corrent.

### Error: `ssh: connect to host ... port 22: Connection timed out`
CachyOS activa el tallafocs (`ufw`) per defecte i bloqueja SSH.
```bash
# A la VM:
sudo ufw allow ssh
sudo ufw enable
```

---
*Última actualització: Maig 2026*
