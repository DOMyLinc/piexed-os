#!/bin/bash
#
# Piexed OS Installation Script
# Version: 1.0.0
# Description: GUI installer for Piexed OS
#

set -e
set -o pipefail

# Configuration
INSTALL_VERSION="1.0.0"
TARGET_DISK=""
INSTALL_PARTITION=""
ROOT_PARTITION=""
SWAP_PARTITION=""
HOME_PARTITION=""
EFI_PARTITION=""
ENCRYPT_ROOT=false
LVM_ENABLED=false

# Colors
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
CYAN='\033[0;36m'
NC='\033[0m'

# Logging
log() {
    echo -e "${GREEN}[INSTALLER]${NC} $1"
}

log_error() {
    echo -e "${RED}[ERROR]${NC} $1"
}

log_warning() {
    echo -e "${YELLOW}[WARNING]${NC} $1"
}

log_info() {
    echo -e "${BLUE}[INFO]${NC} $1"
}

# Check root
check_root() {
    if [ "$EUID" -ne 0 ]; then
        log_error "Please run as root (sudo)"
        exit 1
    fi
}

# Main menu
main_menu() {
    clear
    echo -e "${CYAN}"
    echo "=============================================="
    echo "     Piexed OS Installer v${INSTALL_VERSION}"
    echo "     Codename: Strawberry Fields"
    echo "=============================================="
    echo -e "${NC}"
    echo "1. Guided Installation (Recommended)"
    echo "2. Custom Installation"
    echo "3. Encrypt entire system"
    echo "4. LVM Setup"
    echo "5. Advanced Options"
    echo "6. Exit"
    echo ""
    read -p "Select option [1-6]: " choice

    case $choice in
        1) guided_install ;;
        2) custom_install ;;
        3) encrypted_install ;;
        4) lvm_install ;;
        5) advanced_menu ;;
        6) exit 0 ;;
        *) log_error "Invalid option"; sleep 2; main_menu ;;
    esac
}

# Guided installation
guided_install() {
    clear
    echo -e "${CYAN}"
    echo "=============================================="
    echo "     Guided Installation"
    echo "=============================================="
    echo -e "${NC}"

    # Show available disks
    log_info "Available disks:"
    echo ""
    lsblk -o NAME,SIZE,TYPE,FSTYPE,MOUNTPOINT
    echo ""

    # Select target disk
    read -p "Enter target disk (e.g., sda, nvme0n1): " TARGET_DISK

    if [ ! -b "/dev/${TARGET_DISK}" ]; then
        log_error "Invalid disk selected"
        sleep 2
        guided_install
    fi

    # Partition confirmation
    echo ""
    log_warning "This will erase ALL data on /dev/${TARGET_DISK}"
    read -p "Continue? (yes/no): " confirm

    if [ "$confirm" != "yes" ]; then
        log_info "Installation cancelled"
        sleep 2
        main_menu
    fi

    # Calculate partition sizes
    DISK_SIZE=$(blockdev --getsize64 /dev/${TARGET_DISK})
    DISK_SIZE_GB=$((DISK_SIZE / 1024 / 1024 / 1024))

    log_info "Disk size: ${DISK_SIZE_GB} GB"

    # EFI partition (500MB)
    EFI_SIZE=500M
    # Swap partition (2GB or 2xRAM if <8GB)
    RAM_KB=$(grep MemTotal /proc/meminfo | awk '{print $2}')
    RAM_GB=$((RAM_KB / 1024 / 1024))
    if [ $RAM_GB -lt 8 ]; then
        SWAP_SIZE="${RAM_GB}G"
    else
        SWAP_SIZE=2G
    fi
    # Root partition (rest)
    ROOT_SIZE="rest"

    log_info "Partition scheme:"
    echo "  EFI: ${EFI_SIZE}"
    echo "  Swap: ${SWAP_SIZE}"
    echo "  Root (/): ${ROOT_SIZE}"

    # Partition disk
    partition_disk() {
        log_info "Creating partitions..."

        # Clear partition table
        wipefs -af /dev/${TARGET_DISK}
        sgdisk -Z /dev/${TARGET_DISK}

        # Create GPT
        parted -s /dev/${TARGET_DISK} mklabel gpt

        # EFI partition
        parted -s /dev/${TARGET_DISK} mkpart primary fat32 1MiB 513MiB
        parted -s /dev/${TARGET_DISK} set 1 esp on

        # Swap partition
        SWAP_START=513MiB
        SWAP_END=$((SWAP_START + ${SWAP_SIZE%\G*}${SWAP_SIZE##*[0-9]}))
        parted -s /dev/${TARGET_DISK} mkpart primary linux-swap ${SWAP_START} ${SWAP_END}

        # Root partition (remaining space)
        parted -s /dev/${TARGET_DISK} mkpart primary ext4 ${SWAP_END} 100%

        # Refresh partition table
        partprobe /dev/${TARGET_DISK}

        log_success "Partitions created"
    }

    partition_disk

    # Format partitions
    format_partitions() {
        log_info "Formatting partitions..."

        # EFI
        mkfs.fat -F32 /dev/${TARGET_DISK}1
        SWAP_PART=$(echo /dev/${TARGET_DISK}*2)
        mkswap $SWAP_PART
        ROOT_PART=$(echo /dev/${TARGET_DISK}*3)
        mkfs.ext4 -F $ROOT_PART

        log_success "Partitions formatted"
    }

    format_partitions

    # Mount partitions
    mount_partitions() {
        log_info "Mounting partitions..."

        ROOT_PART=$(echo /dev/${TARGET_DISK}*3)

        mount $ROOT_PART /mnt
        mkdir -p /mnt/boot/efi
        mount /dev/${TARGET_DISK}1 /mnt/boot/efi
        swapon $(echo /dev/${TARGET_DISK}*2)

        log_success "Partitions mounted"
    }

    mount_partitions

    # Install system
    install_system
}

# Custom installation
custom_install() {
    clear
    echo -e "${CYAN}"
    echo "=============================================="
    echo "     Custom Installation"
    echo "=============================================="
    echo -e "${NC}"

    echo "Enter partition information:"
    echo ""

    read -p "Root partition (e.g., sda2): " ROOT_PART
    read -p "EFI partition (e.g., sda1) [optional]: " EFI_PART
    read -p "Swap partition [optional]: " SWAP_PART
    read -p "Home partition [optional]: " HOME_PART

    ROOT_PART="/dev/${ROOT_PART}"
    if [ -n "$EFI_PART" ]; then
        EFI_PART="/dev/${EFI_PART}"
    fi
    if [ -n "$SWAP_PART" ]; then
        SWAP_PART="/dev/${SWAP_PART}"
    fi
    if [ -n "$HOME_PART" ]; then
        HOME_PART="/dev/${HOME_PART}"
    fi

    # Mount
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

# Encrypted installation
encrypted_install() {
    clear
    echo -e "${CYAN}"
    echo "=============================================="
    echo "     Encrypted Installation"
    echo "=============================================="
    echo -e "${NC}"

    log_info "This will set up full disk encryption with LUKS"

    read -p "Enter target disk (e.g., sda): " TARGET_DISK

    # Partition
    log_info "Creating partitions..."
    wipefs -af /dev/${TARGET_DISK}
    sgdisk -Z /dev/${TARGET_DISK}
    parted -s /dev/${TARGET_DISK} mklabel gpt

    # EFI
    parted -s /dev/${TARGET_DISK} mkpart primary fat32 1MiB 513MiB
    parted -s /dev/${TARGET_DISK} set 1 esp on

    # Encrypted partition
    parted -s /dev/${TARGET_DISK} mkpart primary ext4 513MiB 100%

    partprobe /dev/${TARGET_DISK}

    # Format EFI
    mkfs.fat -F32 /dev/${TARGET_DISK}1

    # Setup LUKS
    log_info "Setting up LUKS encryption..."
    read -p "Enter encryption password: " -s CRYPT_PASS
    echo ""

    echo -n "$CRYPT_PASS" | cryptsetup luksFormat /dev/${TARGET_DISK}2 -
    echo -n "$CRYPT_PASS" | cryptsetup open /dev/${TARGET_DISK}2 cryptroot -

    # Create LVM
    pvcreate /dev/mapper/cryptroot
    vgcreate piexed-vg /dev/mapper/cryptroot

    # Ask for swap size
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

    # Install with encryption support
    install_system encrypted
}

# LVM installation
lvm_install() {
    clear
    echo -e "${CYAN}"
    echo "=============================================="
    echo "     LVM Installation"
    echo "=============================================="
    echo -e "${NC}"

    read -p "Enter target disk (e.g., sda): " TARGET_DISK

    # Partition
    log_info "Creating partitions..."
    wipefs -af /dev/${TARGET_DISK}
    sgdisk -Z /dev/${TARGET_DISK}
    parted -s /dev/${TARGET_DISK} mklabel gpt

    # EFI
    parted -s /dev/${TARGET_DISK} mkpart primary fat32 1MiB 513MiB
    parted -s /dev/${TARGET_DISK} set 1 esp on

    # LVM partition
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

# Advanced menu
advanced_menu() {
    clear
    echo -e "${CYAN}"
    echo "=============================================="
    echo "     Advanced Options"
    echo "=============================================="
    echo -e "${NC}"

    echo "1. Manual partitioning with fdisk/cfdisk"
    echo "2. Network installation"
    echo "3. Install with custom kernel"
    echo "4. Back to main menu"
    echo ""
    read -p "Select option: " choice

    case $choice in
        1)
            clear
            log_info "Starting cfdisk for manual partitioning..."
            read -p "Enter disk (e.g., sda): " TARGET_DISK
            cfdisk /dev/${TARGET_DISK}
            custom_install
            ;;
        2) network_install ;;
        3) custom_kernel_install ;;
        4) main_menu ;;
        *) log_error "Invalid option"; sleep 2; advanced_menu ;;
    esac
}

# Install system
install_system() {
    ENCRYPTION=$1

    clear
    echo -e "${CYAN}"
    echo "=============================================="
    echo "     Installing Piexed OS"
    echo "=============================================="
    echo -e "${NC}"

    log_info "Installing base system..."

    # Mount essential filesystems
    mount -t proc proc /mnt/proc
    mount -t sysfs sys /mnt/sys
    mount -t devpts devpts /mnt/dev/pts

    # Install base system
    debootstrap --arch amd64 jammy /mnt http://archive.ubuntu.com/ubuntu/ || debootstrap --arch amd64 jammy /mnt http://ports.ubuntu.com/

    log_success "Base system installed"

    # Configure system
    log_info "Configuring system..."

    # Set hostname
    echo "piexed-os" > /mnt/etc/hostname
    echo "127.0.1.1    piexed-os" >> /mnt/etc/hosts

    # Configure APT
    cat > /mnt/etc/apt/sources.list << 'EOF'
deb http://archive.ubuntu.com/ubuntu/ jammy main restricted universe multiverse
deb http://archive.ubuntu.com/ubuntu/ jammy-updates main restricted universe multiverse
deb http://archive.ubuntu.com/ubuntu/ jammy-security main restricted universe multiverse
EOF

    # Mount special filesystems
    mount --bind /dev /mnt/dev
    mount --bind /proc /mnt/proc
    mount --bind /sys /mnt/sys

    # Chroot installation
    chroot /mnt /bin/bash << 'CHROOT_EOF'
set -e

# Update packages
apt-get update
apt-get install -y linux-generic-hwe-22.04 grub-efi-amd64

# Install desktop
apt-get install -y xfce4 xfce4-goodies lightdm lightdm-gtk-greeter
apt-get install -y xorg xfce4-terminal thunar mousepad ristretto
apt-get install -y network-manager network-manager-gnome
apt-get install -y pulseaudio alsa-base gvfs-fuse

# Install productivity
apt-get install -y firefox thunderbird vlc libreoffice

# Install development
apt-get install -y build-essential git vim nano

# Install performance tools
apt-get install -y preload zram-tools earlyoom

# Install store
apt-get install -y gnome-software flatpak snapd

# Configure fstab
cat > /etc/fstab << 'FSTAB'
/dev/sda3 / ext4 defaults 0 1
/dev/sda1 /boot/efi vfat umask=0077 0 1
/dev/sda2 none swap sw 0 0
FSTAB

# Configure network
cat > /etc/network/interfaces << 'NETWORK'
auto lo
iface lo inet loopback

auto enp0s3
iface enp0s3 inet dhcp
NETWORK

# Configure locale
echo 'LANG=en_US.UTF-8' > /etc/default/locale
locale-gen en_US.UTF-8

# Configure timezone
ln -sf /usr/share/zoneinfo/UTC /etc/localtime

# Install bootloader
update-grub
grub-install /dev/sda

# Create user
useradd -m -s /bin/bash -G sudo,adm,cdrom,floppy,audio,dip,video,plugdev,netdev,lxd piexed
echo 'piexed:piexed' | chpasswd
echo 'root:piexed' | chpasswd

# Set default user autologin
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

echo "Installation completed"
CHROOT_EOF

    # Handle encryption
    if [ "$ENCRYPTION" = "encrypted" ]; then
        log_info "Configuring encryption..."

        cat > /mnt/etc/crypttab << 'CRYPTAB'
cryptroot /dev/sda2 none luks
CRYPTAB

        cat > /mnt/etc/initramfs-tools/conf.d/cryptroot << 'INITRAM'
CRYPTROOT=target=cryptroot,source=/dev/sda2
INITRAM

        update-initramfs -u
    fi

    # Handle LVM
    if [ "$ENCRYPTION" = "lvm" ]; then
        log_info "Configuring LVM..."

        cat > /mnt/etc/fstab << 'FSTAB'
/dev/mapper/piexed-vg-root / ext4 defaults 0 1
/dev/sda1 /boot/efi vfat umask=0077 0 1
/dev/mapper/piexed-vg-swap none swap sw 0 0
FSTAB

        update-initramfs -u
    fi

    # Cleanup
    log_info "Finalizing installation..."

    umount -l /mnt/dev 2>/dev/null || true
    umount -l /mnt/proc 2>/dev/null || true
    umount -l /mnt/sys 2>/dev/null || true

    # Unmount
    swapoff /dev/mapper/piexed-vg-swap 2>/dev/null || swapoff $(echo /dev/sd*2) 2>/dev/null || true
    umount /mnt/boot/efi 2>/dev/null || true
    umount /mnt 2>/dev/null || true

    cryptsetup close cryptroot 2>/dev/null || true

    log_success ""
    log_success "=============================================="
    log_success "     Installation Complete!"
    log_success "=============================================="
    log_success ""
    log_info "You can now reboot your system."
    log_info "Default user: piexed"
    log_info "Password: piexed"
    echo ""

    read -p "Press Enter to reboot or Ctrl+C to exit"

    reboot
}

# Start installation
start_install() {
    check_root

    # Check for Live environment
    if [ ! -f /lib/live/mount/medium/live/filesystem.squashfs ]; then
        log_warning "This installer works best from a Piexed OS Live environment"
        read -p "Continue anyway? (yes/no): " confirm
        if [ "$confirm" != "yes" ]; then
            exit 0
        fi
    fi

    main_menu
}

start_install "$@"