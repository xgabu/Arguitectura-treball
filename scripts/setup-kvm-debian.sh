#!/usr/bin/env bash
# ============================================
# KVM + Virt-Manager Setup for Debian
# Installs lightweight virtualization to test CachyOS
# ============================================

set -euo pipefail

# Colors
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m'

log_info()    { echo -e "${BLUE}[INFO]${NC} $1"; }
log_ok()      { echo -e "${GREEN}[OK]${NC} $1"; }
log_warn()    { echo -e "${YELLOW}[WARN]${NC} $1"; }
log_error()   { echo -e "${RED}[ERROR]${NC} $1"; }

# ============================================
# Checks
# ============================================

check_root() {
    if [[ $EUID -ne 0 ]]; then
        log_error "This script requires sudo. Run with: sudo $0"
        exit 1
    fi
}

check_debian() {
    if [[ -f /etc/debian_version ]]; then
        log_ok "Debian detected"
        return 0
    fi
    if grep -qi "debian" /etc/os-release 2>/dev/null; then
        log_ok "Debian-based system detected"
        return 0
    fi
    log_warn "Not a Debian system. This script is for Debian/Ubuntu."
    read -rp "Continue anyway? [y/N] " confirm
    [[ "$confirm" =~ ^[Yy] ]] || exit 1
}

check_virtualization() {
    if grep -qE "vmx|svm" /proc/cpuinfo; then
        log_ok "Hardware virtualization detected (KVM will use acceleration)"
        return 0
    fi
    log_warn "No hardware virtualization detected (vmx/svm missing)"
    log_warn "QEMU will run in emulation mode — very slow"
    log_warn "Check BIOS/UEFI: enable SVM (AMD) or VT-x (Intel)"
    read -rp "Continue anyway? [y/N] " confirm
    [[ "$confirm" =~ ^[Yy] ]] || exit 1
}

# ============================================
# Installation
# ============================================

install_packages() {
    log_info "Updating package lists..."
    apt-get update -qq

    log_info "Installing KVM + Virt-Manager packages..."
    apt-get install -y --no-install-recommends \
        qemu-kvm \
        libvirt-daemon-system \
        libvirt-clients \
        virt-manager \
        bridge-utils \
        dnsmasq-base \
        ovmf \
        virtinst \
        libosinfo-bin

    log_ok "KVM + Virt-Manager installed"
}

enable_libvirt() {
    log_info "Enabling and starting libvirtd..."
    systemctl enable --now libvirtd
    log_ok "libvirtd running"
}

add_user_to_groups() {
    local user="${SUDO_USER:-$USER}"

    log_info "Adding user '$user' to libvirt and kvm groups..."
    usermod -aG libvirt "$user"
    usermod -aG kvm "$user"

    log_ok "User added to groups"
    log_warn "IMPORTANT: You must LOGOUT and LOGIN again (or reboot) for group changes to apply"
}

# ============================================
# Helper: create a CachyOS VM
# ============================================

print_vm_instructions() {
    echo ""
    echo "============================================"
    echo "  Next steps to create a CachyOS VM"
    echo "============================================"
    echo ""
    echo "Option A — GUI (recommended):"
    echo "  1. Logout and login again (group changes)"
    echo "  2. Run: virt-manager"
    echo "  3. Click 'Create VM' -> Local install media"
    echo "  4. Select your CachyOS ISO"
    echo "  5. Set: 4-8GB RAM, 2-4 CPUs, 50-80GB disk"
    echo "  6. In 'Customize before install': check OVMF (UEFI)"
    echo ""
    echo "Option B — CLI (automated):"
    echo "  virt-install \\"
    echo "    --name cachyos-test \\"
    echo "    --memory 4096 \\"
    echo "    --vcpus 4 \\"
    echo "    --os-variant archlinux \\"
    echo "    --cdrom /path/to/cachyos.iso \\"
    echo "    --disk size=60 \\"
    echo "    --network default \\"
    echo "    --graphics spice \\"
    echo "    --boot uefi"
    echo ""
    echo "============================================"
    echo ""
}

# ============================================
# Main
# ============================================

main() {
    echo ""
    echo "============================================"
    echo "  KVM + Virt-Manager Setup for Debian"
    echo "  (for testing CachyOS deployments)"
    echo "============================================"
    echo ""

    check_root
    check_debian
    check_virtualization

    install_packages
    enable_libvirt
    add_user_to_groups
    print_vm_instructions

    log_info "Setup complete!"
}

main "$@"
