#!/bin/bash
#===============================================================================
# Piẻxed OS Installer
# Version: 1.0.0 - Strawberry Fields
#===============================================================================

set -euo pipefail

# Configuration
VERSION="1.0.0"
TITLE="Piexed OS Installer"

# Colors
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
CYAN='\033[0;36m'
NC='\033[0m'

# Check root
if [ "$EUID" -ne 0 ]; then
    exec sudo bash "$0" "$@"
fi

#===============================================================================
# FUNCTIONS
#===============================================================================

log_info() {
    echo -e "${BLUE}[INFO]${NC} $1"
}

log_success() {
    echo -e "${GREEN}[SUCCESS]${NC} $1"
}

log_error() {
    echo -e "${RED}[ERROR]${NC} $1"
}

print_banner() {
    clear
    echo -e "${CYAN}"
    cat << 'EOF'
     _____ _____   _____         _____           _
    |_   _| ____| |  ___|_   __|_   _|__   __| | ___
      | | |  _|   | |_  | | |  | |/ _ \ / _` |/ _ \
      | | | |___  |  _|  | |_| | |  __/| (_| | (_) |
      |_| |_____| |_|     \__,_|_|\___| \__,_|\___/

    Operating System Installer
    ================================================
    Version: 1.0.0 - Strawberry Fields
    ================================================
EOF
    echo -e "${NC}"
}

#===============================================================================
# MAIN MENU
#===============================================================================

main_menu() {
    print_banner
    echo ""
    echo "Welcome to Piexed OS Installer!"
    echo ""
    echo "Please select an installation option:"
    echo ""
    echo "  1) Guided Installation (Recommended)"
    echo "  2) Custom Installation"
    echo "  3) Encrypted Installation (LUKS)"
    echo "  4) LVM Installation"
    echo "  5) Exit"
    echo ""
    read -p "Select option [1-5]: " choice

    case $choice in
        1) guided_install ;;
        2) custom_install ;;
        3) encrypted_install ;;
        4) lvm_install ;;
        5) exit 0 ;;
        *) echo "Invalid option"; sleep 2; main_menu ;;
    esac
}

#===============================================================================
# GUIDED INSTALLATION
#===============================================================================

guided_install() {
    print_banner
    echo "Guided Installation"
    echo "=================="
    echo ""

    # List available disks
    log_info "Available disks:"
    echo ""
    lsblk -o NAME,SIZE,TYPE,FSTYPE,MOUNTPOINT
    echo ""

    # Select target disk
    read -p "Enter target disk (e.g., sda): " TARGET_DISK

    if [ ! -b "/dev/${TARGET_DISK}" ]; then
        log_error "Invalid disk selected"
        sleep 2
        guided_install
    fi

    # Partition confirmation
    echo ""
    echo "WARNING: This will ERASE ALL DATA on /dev/${TARGET_DISK}"
    read -p "Are you sure you want to continue? (yes/no): " confirm

    if [ "$confirm" != "yes" ]; then
        log_info "Installation cancelled"
        sleep 2
        main_menu
    fi

    # Create partitions
    echo ""
    log_info "Creating partitions..."
    parted -s /dev/${TARGET_DISK} mklabel gpt
    parted -s /dev/${TARGET_DISK} mkpart primary fat32 1MiB 513MiB
    parted -s /dev/${TARGET_DISK} set 1 esp on
    parted -s /dev/${TARGET_DISK} mkpart primary ext4 513MiB 100%
    partprobe /dev/${TARGET_DISK}

    # Format partitions
    echo ""
    log_info "Formatting partitions..."
    mkfs.fat -F32 /dev/${TARGET_DISK}1
    mkswap /dev/${TARGET_DISK}2
    mkfs.ext4 -F /dev/${TARGET_DISK}2

    # Mount partitions
    echo ""
    log_info "Mounting partitions..."
    mount /dev/${TARGET_DISK}2 /mnt
    mkdir -p /mnt/boot/efi
    mount /dev/${TARGET_DISK}1 /mnt/boot/efi
    swapon /dev/${TARGET_DISK}2

    # Install system
    install_system
}

#===============================================================================
# CUSTOM INSTALLATION
#===============================================================================

custom_install() {
    print_banner
    echo "Custom Installation"
    echo "==================="
    echo ""

    echo "Enter partition information:"
    echo ""
    read -p "Root partition (e.g., sda2): " ROOT_PART
    read -p "EFI partition (e.g., sda1) [optional]: " EFI_PART
    read -p "Swap partition [optional]: " SWAP_PART

    ROOT_PART="/dev/${ROOT_PART}"
    if [ -n "$EFI_PART" ]; then
        EFI_PART="/dev/${EFI_PART}"
    fi
    if [ -n "$SWAP_PART" ]; then
        SWAP_PART="/dev/${SWAP_PART}"
    fi

    # Mount
    echo ""
    log_info "Mounting root partition..."
    mount $ROOT_PART /mnt

    if [ -n "$EFI_PART" ]; then
        mkdir -p /mnt/boot/efi
        mount $EFI_PART /mnt/boot/efi
    fi

    if [ -n "$SWAP_PART" ]; then
        swapon $SWAP_PART
    fi

    # Install
    install_system
}

#===============================================================================
# ENCRYPTED INSTALLATION
#===============================================================================

encrypted_install() {
    print_banner
    echo "Encrypted Installation (LUKS)"
    echo "============================="
    echo ""

    log_info "This will set up full disk encryption with LUKS"

    read -p "Enter target disk (e.g., sda): " TARGET_DISK

    # Partition
    echo ""
    log_info "Creating partitions..."
    wipefs -af /dev/${TARGET_DISK}
    sgdisk -Z /dev/${TARGET_DISK}
    parted -s /dev/${TARGET_DISK} mklabel gpt
    parted -s /dev/${TARGET_DISK} mkpart primary fat32 1MiB 513MiB
    parted -s /dev/${TARGET_DISK} set 1 esp on
    parted -s /dev/${TARGET_DISK} mkpart primary ext4 513MiB 100%
    partprobe /dev/${TARGET_DISK}

    # Format EFI
    mkfs.fat -F32 /dev/${TARGET_DISK}1

    # Setup LUKS
    echo ""
    log_info "Setting up LUKS encryption..."
    read -p "Enter encryption password: " -s CRYPT_PASS
    echo ""

    echo -n "$CRYPT_PASS" | cryptsetup luksFormat /dev/${TARGET_DISK}2 -
    echo -n "$CRYPT_PASS" | cryptsetup open /dev/${TARGET_DISK}2 cryptroot -

    # Create LVM
    pvcreate /dev/mapper/cryptroot
    vgcreate piexed-vg /dev/mapper/cryptroot

    RAM_KB=$(grep MemTotal /proc/meminfo | awk '{print $2}')
    RAM_GB=$((RAM_KB / 1024 / 1024))
    if [ $RAM_GB -lt 8 ]; then
        SWAP_SIZE=$((RAM_GB * 1024))
    else
        SWAP_SIZE=2048
    fi

    lvcreate -L ${SWAP_SIZE}M piexed-vg -n swap
    lvcreate -l 100%FREE piexed-vg -n root

    # Format
    mkfs.ext4 -F /dev/mapper/piexed-vg-root
    mkswap /dev/mapper/piexed-vg-swap

    # Mount
    mount /dev/mapper/piexed-vg-root /mnt
    mkdir -p /mnt/boot/efi
    mount /dev/${TARGET_DISK}1 /mnt/boot/efi
    swapon /dev/mapper/piexed-vg-swap

    # Install with encryption
    install_system encrypted
}

#===============================================================================
# LVM INSTALLATION
#===============================================================================

lvm_install() {
    print_banner
    echo "LVM Installation"
    echo "================"
    echo ""

    read -p "Enter target disk (e.g., sda): " TARGET_DISK

    # Partition
    echo ""
    log_info "Creating partitions..."
    wipefs -af /dev/${TARGET_DISK}
    sgdisk -Z /dev/${TARGET_DISK}
    parted -s /dev/${TARGET_DISK} mklabel gpt
    parted -s /dev/${TARGET_DISK} mkpart primary fat32 1MiB 513MiB
    parted -s /dev/${TARGET_DISK} set 1 esp on
    parted -s /dev/${TARGET_DISK} mkpart primary ext4 513MiB 100%
    partprobe /dev/${TARGET_DISK}

    mkfs.fat -F32 /dev/${TARGET_DISK}1

    # Setup LVM
    pvcreate /dev/${TARGET_DISK}2
    vgcreate piexed-vg /dev/${TARGET_DISK}2

    RAM_KB=$(grep MemTotal /proc/meminfo | awk '{print $2}')
    RAM_GB=$((RAM_KB / 1024 / 1024))
    if [ $RAM_GB -lt 8 ]; then
        SWAP_SIZE=$((RAM_GB * 1024))
    else
        SWAP_SIZE=2048
    fi

    lvcreate -L ${SWAP_SIZE}M piexed-vg -n swap
    lvcreate -l 100%FREE piexed-vg -n root

    mkfs.ext4 -F /dev/mapper/piexed-vg-root
    mkswap /dev/mapper/piexed-vg-swap

    mount /dev/mapper/piexed-vg-root /mnt
    mkdir -p /mnt/boot/efi
    mount /dev/${TARGET_DISK}1 /mnt/boot/efi
    swapon /dev/mapper/piexed-vg-swap

    install_system lvm
}

#===============================================================================
# INSTALL SYSTEM
#===============================================================================

install_system() {
    ENCRYPTION=$1
    print_banner
    echo "Installing System"
    echo "=================="
    echo ""

    log_info "Installing base system..."

    # Mount essential filesystems
    mount -t proc proc /mnt/proc
    mount -t sysfs sys /mnt/sys
    mount -t devpts devpts /mnt/dev/pts

    # Install base system
    debootstrap --arch amd64 jammy /mnt http://archive.ubuntu.com/ubuntu/ || \
    debootstrap --arch amd64 jammy /mnt http://ports.ubuntu.com/

    echo ""
    log_success "Base system installed"

    # Configure system
    echo ""
    log_info "Configuring system..."

    # Set hostname
    echo "piexed-os" > /mnt/etc/hostname
    echo "127.0.1.1    piexed-os" >> /mnt/etc/hosts

    # Configure APT
    cat > /mnt/etc/apt/sources.list << 'EOF'
deb http://archive.ubuntu.com/ubuntu/ jammy main restricted universe multiverse
deb http://archive.ubuntu.com/ubuntu/ jammy-updates main restricted universe multiverse
deb http://security.ubuntu.com/ubuntu/ jammy-security main restricted universe multiverse
EOF

    # Mount special filesystems
    mount --bind /dev /mnt/dev
    mount --bind /proc /mnt/proc
    mount --bind /sys /mnt/sys

    # Chroot installation
    chroot /mnt /bin/bash << 'CHROOT_EOF'
set -e

export DEBIAN_FRONTEND=noninteractive

# Update packages
apt-get update

# Install kernel
apt-get install -y linux-generic-hwe-22.04 grub-efi-amd64-signed shim-signed

# Install desktop
apt-get install -y \
    xfce4 xfce4-goodies lightdm lightdm-gtk-greeter \
    xorg xfce4-terminal thunar mousepad ristretto \
    network-manager network-manager-gnome \
    pulseaudio alsa-base gvfs-fuse

# Install applications
apt-get install -y \
    firefox thunderbird vlc libreoffice libreoffice-gtk3 shotwell

# Install development
apt-get install -y build-essential git vim nano

# Install performance
apt-get install -y preload zram-tools earlyoom

# Install store
apt-get install -y gnome-software flatpak snapd

# Create user
useradd -m -s /bin/bash -G sudo,adm,cdrom,floppy,audio,dip,video,plugdev,netdev,lxd piexed
echo 'piexed:piexed' | chpasswd
echo 'root:piexed' | chpasswd

# Set autologin
mkdir -p /etc/lightdm/lightdm.conf.d
cat > /etc/lightdm/lightdm.conf.d/99-piexed.conf << 'LIGHTDM'
[Seat:*]
autologin-user=piexed
user-session=xfce
greeter-session=lightdm-gtk-greeter
LIGHTDM

# Enable services
systemctl enable NetworkManager
systemctl enable lightdm

# Create Piexed release
cat > /etc/piexed-release << 'RELEASE'
PIEXED_OS="1.0.0"
CODENAME="Strawberry Fields"
NAME="Piexed OS"
RELEASE

# Configure fstab (basic)
cat > /etc/fstab << 'FSTAB'
/dev/sda2 / ext4 defaults 0 1
/dev/sda1 /boot/efi vfat umask=0077 0 1
/dev/sda2 none swap sw 0 0
FSTAB

echo "Installation completed"
CHROOT_EOF

    # Install bootloader
    echo ""
    log_info "Installing bootloader..."
    chroot /mnt /bin/bash -c "update-grub"
    chroot /mnt /bin/bash -c "grub-install /dev/sda" 2>/dev/null || \
    chroot /mnt /bin/bash -c "grub-install --target=x86_64-efi --efi-directory=/boot/efi --boot-directory=/boot /dev/sda"

    # Handle encryption
    if [ "$ENCRYPTION" = "encrypted" ]; then
        echo ""
        log_info "Configuring encryption..."
        cat > /mnt/etc/crypttab << 'CRYPTAB'
cryptroot /dev/sda2 none luks
CRYPTAB

        cat > /mnt/etc/initramfs-tools/conf.d/cryptroot << 'INITRAM'
CRYPTROOT=target=cryptroot,source=/dev/sda2
INITRAM

        chroot /mnt /bin/bash -c "update-initramfs -u"
    fi

    # Handle LVM
    if [ "$ENCRYPTION" = "lvm" ]; then
        echo ""
        log_info "Configuring LVM..."
        cat > /mnt/etc/fstab << 'FSTAB'
/dev/mapper/piexed-vg-root / ext4 defaults 0 1
/dev/sda1 /boot/efi vfat umask=0077 0 1
/dev/mapper/piexed-vg-swap none swap sw 0 0
FSTAB

        chroot /mnt /bin/bash -c "update-initramfs -u"
    fi

    # Cleanup
    echo ""
    log_info "Finalizing installation..."

    umount -l /mnt/dev 2>/dev/null || true
    umount -l /mnt/proc 2>/dev/null || true
    umount -l /mnt/sys 2>/dev/null || true

    swapoff /dev/mapper/piexed-vg-swap 2>/dev/null || swapoff $(echo /dev/sd*2) 2>/dev/null || true
    umount /mnt/boot/efi 2>/dev/null || true
    umount /mnt 2>/dev/null || true

    cryptsetup close cryptroot 2>/dev/null || true

    echo ""
    log_success "=============================================="
    log_success "Installation Complete!"
    log_success "=============================================="
    echo ""
    log_success "You can now reboot your system."
    log_success "Default user: piexed"
    log_success "Password: piexed"
    echo ""

    read -p "Press Enter to reboot or Ctrl+C to exit"

    reboot
}

#===============================================================================
# START
#===============================================================================

start_install() {
    # Check for Live environment
    if [ ! -f /lib/live/mount/medium/live/filesystem.squashfs ]; then
        echo ""
        echo "Note: This installer works best from a Piexed OS Live environment"
        echo "But continuing anyway..."
        echo ""
        sleep 3
    fi

    main_menu
}

start_install "$@"