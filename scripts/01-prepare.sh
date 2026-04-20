#!/bin/bash
#===============================================================================
# Piẻxed OS Builder - Main Build Script
# Version: 1.0.0 - Strawberry Fields
# A complete, lightweight Linux OS for low-end computers
#===============================================================================

set -euo pipefail

# Piẻxed OS Configuration
PIEXED_VERSION="1.0.0"
PIEXED_CODENAME="Strawberry Fields"
UBUNTU_RELEASE="jammy"
ARCH="amd64"
KERNEL_VERSION="6.1.0-lts-piexed"
BUILD_DIR="/workspace/piexed-os/build"
OUTPUT_DIR="/workspace/piexed-os/output"
WORKSPACE="/workspace/piexed-os/workspace"

# Colors
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
CYAN='\033[0;36m'
NC='\033[0m'

#===============================================================================
# UTILITY FUNCTIONS
#===============================================================================

log_info() {
    echo -e "${BLUE}[INFO]${NC} $1"
}

log_success() {
    echo -e "${GREEN}[SUCCESS]${NC} $1"
}

log_warning() {
    echo -e "${YELLOW}[WARNING]${NC} $1"
}

log_error() {
    echo -e "${RED}[ERROR]${NC} $1"
}

print_banner() {
    echo -e "${CYAN}"
    cat << 'EOF'
     _____ _____   _____         _____           _
    |_   _| ____| |  ___|_   __|_   _|__   __| | ___
      | | |  _|   | |_  | | |  | |/ _ \ / _` |/ _ \
      | | | |___  |  _|  | |_| | |  __/| (_| | (_) |
      |_| |_____| |_|     \__,_|_|\___| \__,_|\___/

    Operating System
    ================================================
    Version: %VERSION%
    Codename: %CODENAME%
    ================================================
EOF
    echo -e "${NC}"
}

#===============================================================================
# CHECK DEPENDENCIES
#===============================================================================

check_dependencies() {
    log_info "Checking build dependencies..."

    local missing_deps=()
    local deps=("debootstrap" "squashfs-tools" "xorriso" "grub-pc-bin" "grub-efi-amd64-bin" "mtools" "gdisk" "parted")

    for dep in "${deps[@]}"; do
        if ! command -v "$dep" &> /dev/null; then
            missing_deps+=("$dep")
        fi
    done

    if [ ${#missing_deps[@]} -gt 0 ]; then
        log_warning "Missing dependencies: ${missing_deps[*]}"
        log_info "Installing dependencies..."
        if command -v apt-get &> /dev/null; then
            sudo apt-get update
            sudo apt-get install -y "${missing_deps[@]}"
        else
            log_error "Cannot install dependencies - apt-get not found"
            exit 1
        fi
    fi

    # Check for required tools
    if ! command -v sudo &> /dev/null; then
        log_error "sudo not found"
        exit 1
    fi

    log_success "All dependencies satisfied"
}

#===============================================================================
# SETUP BUILD ENVIRONMENT
#===============================================================================

setup_environment() {
    log_info "Setting up build environment..."

    # Create directories
    mkdir -p "$BUILD_DIR"
    mkdir -p "$OUTPUT_DIR"
    mkdir -p "$WORKSPACE"
    mkdir -p "$WORKSPACE/chroot"
    mkdir -p "$WORKSPACE/image"
    mkdir -p "$WORKSPACE/squashfs"
    mkdir -p "$WORKSPACE/boot"
    mkdir -p "$WORKSPACE/efi"

    # Set permissions
    chmod 755 "$WORKSPACE"
    chmod 755 "$BUILD_DIR"

    log_success "Build environment ready"
}

#===============================================================================
# CREATE BASE SYSTEM
#===============================================================================

download_base_system() {
    log_info "Downloading Ubuntu base system (${UBUNTU_RELEASE})..."

    cd "$WORKSPACE"

    if [ ! -f "$WORKSPACE/chroot/.base_system_installed" ]; then
        sudo debootstrap --arch="${ARCH}" --variant=minbase "${UBUNTU_RELEASE}" chroot http://archive.ubuntu.com/ubuntu/
        touch "$WORKSPACE/chroot/.base_system_installed"
        log_success "Base system downloaded"
    else
        log_info "Base system already exists, skipping download"
    fi
}

#===============================================================================
# CONFIGURE SYSTEM
#===============================================================================

configure_system() {
    log_info "Configuring system..."

    # Mount filesystems
    sudo mount --bind /dev chroot/dev
    sudo mount --bind /dev/pts chroot/dev/pts
    sudo mount --bind /proc chroot/proc
    sudo mount --bind /sys chroot/sys

    # Configure APT sources
    sudo chroot chroot /bin/bash -c 'cat > /etc/apt/sources.list' << 'EOF'
deb http://archive.ubuntu.com/ubuntu/ jammy main restricted universe multiverse
deb http://archive.ubuntu.com/ubuntu/ jammy-updates main restricted universe multiverse
deb http://archive.ubuntu.com/ubuntu/ jammy-security main restricted universe multiverse
deb http://archive.ubuntu.com/ubuntu/ jammy-backports main restricted universe multiverse
EOF

    # Set hostname
    echo "piexed-os" | sudo tee chroot/etc/hostname
    echo "127.0.1.1    piexed-os" | sudo tee -a chroot/etc/hosts

    # Configure locale
    sudo chroot chroot /bin/bash -c 'cat > /etc/default/locale' << 'EOF'
LANG=en_US.UTF-8
LC_ALL=en_US.UTF-8
LANGUAGE=en_US:en
EOF

    sudo chroot chroot /bin/bash -c "sed -i '/en_US.UTF-8/s/^#//' /etc/locale.gen && locale-gen"

    # Configure network
    sudo chroot chroot /bin/bash -c 'cat > /etc/network/interfaces' << 'EOF'
auto lo
iface lo inet loopback
EOF

    # Configure APT optimization
    sudo chroot chroot /bin/bash -c 'cat > /etc/apt/apt.conf.d/99piexed' << 'EOF'
APT::Install-Recommends "false";
APT::Get::AutomaticRemove "true";
APT::Get::Show-Versions "false";
DPkg::Options "--force-confdef";
DPkg::Options "--force-confold";
EOF

    # Update package index
    sudo chroot chroot /bin/bash -c "apt-get update"

    log_success "System configured"
}

#===============================================================================
# INSTALL PACKAGES
#===============================================================================

install_packages() {
    log_info "Installing packages..."

    # Update first
    sudo chroot chroot /bin/bash -c "export DEBIAN_FRONTEND=noninteractive && apt-get update"

    # Install kernel
    log_info "Installing kernel..."
    sudo chroot chroot /bin/bash -c "export DEBIAN_FRONTEND=noninteractive && apt-get install -y linux-generic-hwe-22.04"

    # Install desktop environment
    log_info "Installing desktop environment..."
    sudo chroot chroot /bin/bash -c "export DEBIAN_FRONTEND=noninteractive && apt-get install -y \
        xfce4 \
        xfce4-goodies \
        xfce4-terminal \
        thunar \
        mousepad \
        ristretto \
        lightdm \
        lightdm-gtk-greeter \
        xfce4-panel \
        xfce4-settings \
        xfce4-appfinder \
        xfwm4 \
        xfce4-notifyd \
        xfce4-power-manager \
        xfce4-session \
        xfce4-screenshooter \
        xfce4-taskmanager \
        xfce4-systemload-plugin \
        xfce4-pulseaudio-plugin \
        xfce4-clipman-plugin \
        xfwm4-themes \
        picom \
        arc-theme \
        papirus-icon-theme"

    # Install network tools
    log_info "Installing network tools..."
    sudo chroot chroot /bin/bash -c "export DEBIAN_FRONTEND=noninteractive && apt-get install -y \
        network-manager \
        network-manager-gnome \
        iw \
        wireless-tools \
        wpasupplicant"

    # Install audio
    log_info "Installing audio..."
    sudo chroot chroot /bin/bash -c "export DEBIAN_FRONTEND=noninteractive && apt-get install -y \
        pulseaudio \
        pulseaudio-utils \
        alsa-base \
        alsa-utils \
        gstreamer1.0-plugins-good \
        gstreamer1.0-plugins-base"

    # Install applications
    log_info "Installing applications..."
    sudo chroot chroot /bin/bash -c "export DEBIAN_FRONTEND=noninteractive && apt-get install -y \
        firefox \
        thunderbird \
        vlc \
        libreoffice \
        libreoffice-gtk3 \
        shotwell \
        evince \
        file-roller \
        gnome-calculator \
        gnome-screenshot \
        gnome-system-monitor"

    # Install development tools
    log_info "Installing development tools..."
    sudo chroot chroot /bin/bash -c "export DEBIAN_FRONTEND=noninteractive && apt-get install -y \
        build-essential \
        git \
        vim \
        nano \
        curl \
        wget \
        openssh-client \
        software-properties-common \
        apt-transport-https \
        ca-certificates \
        python3 \
        python3-pip \
        python3-gi"

    # Install performance tools
    log_info "Installing performance tools..."
    sudo chroot chroot /bin/bash -c "export DEBIAN_FRONTEND=noninteractive && apt-get install -y \
        preload \
        zram-config \
        earlyoom \
        thermald"

    # Install App Store
    log_info "Installing App Store..."
    sudo chroot chroot /bin/bash -c "export DEBIAN_FRONTEND=noninteractive && apt-get install -y \
        gnome-software \
        flatpak \
        snapd"

    # Install boot tools
    log_info "Installing boot tools..."
    sudo chroot chroot /bin/bash -c "export DEBIAN_FRONTEND=noninteractive && apt-get install -y \
        grub-common \
        grub-pc \
        grub-efi-amd64 \
        grub2-common \
        shim-signed \
        os-prober"

    # Install filesystem tools
    log_info "Installing filesystem tools..."
    sudo chroot chroot /bin/bash -c "export DEBIAN_FRONTEND=noninteractive && apt-get install -y \
        ntfs-3g \
        exfat-fuse \
        fuse \
        gparted"

    # Install utilities
    log_info "Installing utilities..."
    sudo chroot chroot /bin/bash -c "export DEBIAN_FRONTEND=noninteractive && apt-get install -y \
        gvfs \
        gvfs-backends \
        gvfs-fuse \
        udisks2 \
        udiskie \
        thunar-volman \
        thunar-archive-plugin \
        xarchiver \
        zip \
        unzip \
        p7zip-full \
        unrar"

    # Install fonts
    log_info "Installing fonts..."
    sudo chroot chroot /bin/bash -c "export DEBIAN_FRONTEND=noninteractive && apt-get install -y \
        fonts-noto \
        fonts-noto-cjk \
        fonts-ubuntu \
        fonts-dejavu"

    # Clean up
    sudo chroot chroot /bin/bash -c "apt-get clean && rm -rf /var/lib/apt/lists/*"

    log_success "Packages installed"
}

#===============================================================================
# CONFIGURE DESKTOP ENVIRONMENT
#===============================================================================

configure_desktop() {
    log_info "Configuring desktop environment..."

    # Set LightDM as default
    sudo chroot chroot /bin/bash -c "echo '/usr/sbin/lightdm' > /etc/X11/default-display-manager"
    sudo chroot chroot /bin/bash -c "systemctl set-default graphical.target"

    # Configure LightDM
    sudo chroot chroot /bin/bash -c 'mkdir -p /etc/lightdm/lightdm.conf.d'
    sudo chroot chroot /bin/bash -c 'cat > /etc/lightdm/lightdm.conf.d/99-piexed.conf' << 'EOF'
[Seat:*]
greeter-session=lightdm-gtk-greeter
user-session=xfce
autologin-user=piexed
allow-user-switching=true
allow-guest=false
EOF

    # Configure XFCE
    sudo chroot chroot /bin/bash -c 'mkdir -p /etc/skel/.config/xfce4'
    sudo chroot chroot /bin/bash -c 'cat > /etc/skel/.config/xfce4/xfconf/xfce-perchannel-xml/xfwm4.xml' << 'EOF'
<?xml version="1.0" encoding="UTF-8"?>
<channel name="xfwm4" version="1.0">
  <property name="theme" type="string" value="Arc-Dark"/>
  <property name="titlefont" type="string" value="Sans Bold 10"/>
  <property name="buttonLayout" type="string" value="|OMHE"/>
</channel>
EOF

    # Configure GTK
    sudo chroot chroot /bin/bash -c 'cat > /etc/skel/.config/gtk-3.0/settings.ini' << 'EOF'
[Settings]
gtk-theme-name=Arc-Dark
gtk-icon-theme-name=Papirus-Dark
gtk-font-name=Sans 11
gtk-cursor-theme-name=default
gtk-toolbar-style=GTK_TOOLBAR_BOTH_HORIZ
EOF

    # Create autostart
    sudo chroot chroot /bin/bash -c 'mkdir -p /etc/skel/.config/autostart'
    sudo chroot chroot /bin/bash -c 'cat > /etc/skel/.config/autostart/picom.desktop' << 'EOF'
[Desktop Entry]
Type=Application
Name=Picom
Comment=Window compositor
Exec=picom -b
Hidden=false
NoDisplay=true
EOF

    sudo chroot chroot /bin/bash -c 'cat > /etc/skel/.config/autostart/nm-applet.desktop' << 'EOF'
[Desktop Entry]
Type=Application
Name=Network Manager
Comment=Network connection manager
Exec=nm-applet
Hidden=false
NoDisplay=true
EOF

    log_success "Desktop configured"
}

#===============================================================================
# CREATE USERS
#===============================================================================

create_users() {
    log_info "Creating users..."

    # Create default user
    sudo chroot chroot /bin/bash -c 'id piexed &>/dev/null || useradd -m -s /bin/bash -G sudo,adm,cdrom,floppy,audio,dip,video,plugdev,netdev,lxd,wireshark,scanner piexed'
    sudo chroot chroot /bin/bash -c 'echo "piexed:piexed" | chpasswd'

    # Set root password
    sudo chroot chroot /bin/bash -c 'echo "root:piexed" | chpasswd'

    # Configure sudo
    sudo chroot chroot /bin/bash -c 'echo "piexed ALL=(ALL) ALL" >> /etc/sudoers.d/piexed'

    # Create user directories
    sudo chroot /bin/bash -c "cp -r /etc/skel/.config /root/ 2>/dev/null || true"
    sudo chroot /bin/bash -c "cp -r /etc/skel/.config /home/piexed/ 2>/dev/null || true"
    sudo chroot /bin/bash -c "cp -r /etc/skel/.local /home/piexed/ 2>/dev/null || true"
    sudo chroot /bin/bash -c "chown -R piexed:piexed /home/piexed/ 2>/dev/null || true"

    log_success "Users created"
}

#===============================================================================
# INSTALL PIE XED OS SPECIFIC
#===============================================================================

install_piexed_specific() {
    log_info "Installing Piexed OS specific packages..."

    # Copy Piẻxed OS configuration
    sudo cp /workspace/piexed-os/config/sources.list chroot/etc/apt/sources.list
    sudo mkdir -p chroot/etc/piexed
    sudo cp /workspace/piexed-os/config/piexed.conf chroot/etc/piexed/piexed.conf

    # Install Piẻxed OS theme
    sudo chroot chroot /bin/bash -c 'mkdir -p /usr/share/themes/Piexed'
    sudo chroot chroot /bin/bash -c 'cat > /usr/share/themes/Piexed/gtk-3.0/gtk.css' << 'EOF'
@define-color theme_primary #E63946;
@define-color theme_bg #1A1A2E;
@define-color theme_fg #FAFAFA;

window.background {
    background-color: @theme_bg;
    color: @theme_fg;
}
EOF

    # Install Piẻxed OS branding
    sudo mkdir -p chroot/usr/share/plymouth/plymouth_default_theme
    sudo cp /workspace/piexed-os/branding/splash.png chroot/usr/share/plymouth/plymouth_default_theme/ 2>/dev/null || true

    # Create Piẻxed OS release file
    sudo chroot chroot /bin/bash -c 'cat > /etc/piexed-release' << 'EOF'
PIEXED_OS="1.0.0"
CODENAME="Strawberry Fields"
NAME="Piexed OS"
VERSION="1.0.0 (Strawberry Fields)"
ID=piexed
ID_LIKE=ubuntu
PRETTY_NAME="Piexed OS 1.0.0 Strawberry Fields"
HOME_URL="https://piexed-os.org"
SUPPORT_URL="https://community.piexed-os.org"
BUG_REPORT_URL="https://github.com/piexed-os/issues"
EOF

    # Create motd
    sudo chroot chroot /bin/bash -c 'cat > /etc/update-motd.d/10-piexed' << 'EOF'
#!/bin/sh
echo ""
echo "  _____ _____   _____         _____           _"
echo " |_   _| ____| |  ___|_   __|_   _|__   __| | ___"
echo "   | | |  _|   | |_  | | |  | |/ _ \ / _\` |/ _ \"
echo "   | | | |___  |  _|  | |_| | |  __/| (_| | (_) |"
echo "   |_| |_____| |_|     \__,_|_|\___| \__,_|\___/"
echo ""
echo "Welcome to Piexed OS ${PIEXED_VERSION:-1.0.0} - ${CODENAME:-Strawberry Fields}"
echo ""
EOF
    sudo chmod +x chroot/etc/update-motd.d/10-piexed

    log_success "Piexed OS specific packages installed"
}

#===============================================================================
# CONFIGURE SERVICES
#===============================================================================

configure_services() {
    log_info "Configuring services..."

    # Enable NetworkManager
    sudo chroot chroot /bin/bash -c "systemctl enable NetworkManager"

    # Enable LightDM
    sudo chroot chroot /bin/bash -c "systemctl enable lightdm"

    # Enable zram
    sudo chroot chroot /bin/bash -c "systemctl enable zram-config"

    # Enable earlyoom
    sudo chroot chroot /bin/bash -c "systemctl enable earlyoom"

    # Disable unnecessary services
    sudo chroot chroot /bin/bash -c "systemctl mask systemd-networkd-wait-online 2>/dev/null || true"

    log_success "Services configured"
}

#===============================================================================
# CLEANUP SYSTEM
#===============================================================================

cleanup_system() {
    log_info "Cleaning up system..."

    # Remove temporary files
    sudo chroot chroot /bin/bash -c "apt-get clean"
    sudo chroot chroot /bin/bash -c "rm -rf /var/lib/apt/lists/*"
    sudo chroot chroot /bin/bash -c "rm -f /tmp/*"
    sudo chroot chroot /bin/bash -c "rm -rf /var/tmp/*"

    # Remove log files
    sudo chroot chroot /bin/bash -c "rm -rf /var/log/*.log"
    sudo chroot chroot /bin/bash -c "rm -rf /var/log/apt/*"

    # Clear machine-id
    sudo chroot chroot /bin/bash -c "rm -f /etc/machine-id"
    sudo chroot chroot /bin/bash -c "touch /etc/machine-id"

    # Clear SSH host keys
    sudo chroot chroot /bin/bash -c "rm -f /etc/ssh/ssh_host_*"
    sudo chroot chroot /bin/bash -c "dpkg-reconfigure openssh-server 2>/dev/null || true"

    log_success "System cleaned"
}

#===============================================================================
# UNMOUNT FILESYSTEMS
#===============================================================================

unmount_filesystems() {
    log_info "Unmounting filesystems..."

    sudo umount -l chroot/proc 2>/dev/null || true
    sudo umount -l chroot/sys 2>/dev/null || true
    sudo umount -l chroot/dev/pts 2>/dev/null || true
    sudo umount -l chroot/dev 2>/dev/null || true

    log_success "Filesystems unmounted"
}

#===============================================================================
# CREATE LIVE SYSTEM
#===============================================================================

create_live_system() {
    log_info "Creating live system..."

    cd "$WORKSPACE"

    # Copy kernel and initrd
    sudo cp chroot/boot/vmlinuz-* image/vmlinuz
    sudo cp chroot/boot/initrd.img-* image/initrd

    # Create squashfs
    sudo mksquashfs chroot squashfs/filesystem.squashfs -comp xz -b 1M -no-exports

    log_success "Live system created"
}

#===============================================================================
# CREATE BOOT IMAGES
#===============================================================================

create_boot_images() {
    log_info "Creating boot images..."

    cd "$WORKSPACE"

    # Create EFI directory
    mkdir -p image/EFI/BOOT
    mkdir -p image/boot/grub/x86_64-efi
    mkdir -p image/boot/grub/i386-pc
    mkdir -p image/boot/isolinux

    # Create GRUB config
    cat > image/boot/grub/grub.cfg << 'EOF'
set default="0"
set timeout="10"

menuentry "Piexed OS" {
    set gfxpayload=keep
    linux /live/vmlinuz boot=live config quiet splash
    initrd /live/initrd
}

menuentry "Piexed OS (safe graphics)" {
    set gfxpayload=keep
    linux /live/vmlinuz boot=live nomodeset
    initrd /live/initrd
}

menuentry "Piexed OS (recovery)" {
    set gfxpayload=keep
    linux /live/vmlinuz boot=live single
    initrd /live/initrd
}
EOF

    # Create ISOLINUX config
    cat > image/boot/isolinux/isolinux.cfg << 'EOF'
DEFAULT piexed
LABEL piexed
    kernel /live/vmlinuz
    append boot=live config quiet splash initrd=/live/initrd
LABEL safe
    kernel /live/vmlinuz
    append boot=live nomodeset initrd=/live/initrd
EOF

    # Copy splash image
    cp branding/splash.png image/boot/splash.png 2>/dev/null || true

    # Build GRUB EFI
    sudo grub-mkimage -O x86_64-efi -o image/EFI/BOOT/BOOTX64.EFI \
        boot part_gpt part_msdos normal search search_fs_file \
        efi_gop efi_uga gfxterm gfxterm_background test all_video png

    # Create EFI boot image
    sudo dd if=/dev/zero of=image/EFI/efiboot.img bs=1M count=50
    sudo mkfs.fat image/EFI/efiboot.img
    sudo mount -o loop image/EFI/efiboot.img /mnt
    sudo mkdir -p /mnt/EFI/BOOT
    sudo cp image/EFI/BOOT/BOOTX64.EFI /mnt/EFI/BOOT/
    sudo cp image/boot/grub/grub.cfg /mnt/EFI/BOOT/
    sudo umount /mnt

    # Copy live files
    cp squashfs/filesystem.squashfs image/live/filesystem.squashfs
    cp image/vmlinuz image/live/vmlinuz
    cp image/initrd image/live/initrd

    log_success "Boot images created"
}

#===============================================================================
# CREATE ISO
#===============================================================================

create_iso() {
    log_info "Creating ISO image..."

    cd "$WORKSPACE"

    # Create ISO label
    VOLID="PIEXED_OS_${PIEXED_VERSION}"

    # Build ISO with xorriso
    sudo xorriso \
        -as mkisofs \
        -iso-level 3 \
        -full-iso9660-filenames \
        -volid "${VOLID}" \
        -appid "Piexed OS" \
        -publisher "Piexed OS Team" \
        -preparer "Piexed OS Build System" \
        -eltorito-boot boot/isoli/linux.bin \
        -no-emul-boot \
        -boot-load-size 4 \
        -boot-info-table \
        -eltorito-catalog boot/isoli/boot.cat \
        -eltorito-alt-boot \
        -e EFI/efiboot.img \
        -no-emul-boot \
        -isohybrid-gpt-basdat \
        -isohybrid-mbr /usr/share/syslinux/isohdpfx.bin \
        -output "${OUTPUT_DIR}/piexed-os-${PIEXED_VERSION}.iso" \
        image/

    # Make ISO hybrid (bootable from USB)
    sudo isohybrid "${OUTPUT_DIR}/piexed-os-${PIEXED_VERSION}.iso" 2>/dev/null || true

    # Create checksums
    cd "${OUTPUT_DIR}"
    sha256sum "piexed-os-${PIEXED_VERSION}.iso" > "piexed-os-${PIEXED_VERSION}.sha256"
    md5sum "piexed-os-${PIEXED_VERSION}.iso" > "piexed-os-${PIEXED_VERSION}.md5"

    log_success "ISO created: ${OUTPUT_DIR}/piexed-os-${PIEXED_VERSION}.iso"
    log_info "Checksums:"
    cat "piexed-os-${PIEXED_VERSION}.sha256"
}

#===============================================================================
# BUILD INSTALLER
#===============================================================================

build_installer() {
    log_info "Building installer..."

    # Copy installer to live system
    sudo cp /workspace/piexed-os/installer/*.sh chroot/usr/local/bin/
    sudo chmod +x chroot/usr/local/bin/*.sh

    # Create desktop entry
    sudo chroot chroot /bin/bash -c 'mkdir -p /etc/skel/.local/share/applications'
    sudo chroot chroot /bin/bash -c 'cat > /etc/skel/.local/share/applications/piexed-installer.desktop' << 'EOF'
[Desktop Entry]
Name=Piexed OS Installer
Comment=Install Piexed OS
Exec=sudo /usr/local/bin/piexed-installer.sh
Icon=system-install
Terminal=true
Type=Application
Categories=System;
EOF

    log_success "Installer built"
}

#===============================================================================
# MAIN BUILD PROCESS
#===============================================================================

main() {
    print_banner

    log_info "Starting Piexed OS build..."
    log_info "Version: ${PIEXED_VERSION}"
    log_info "Codename: ${PIEXED_CODENAME}"
    echo ""

    # Check dependencies
    check_dependencies

    # Setup environment
    setup_environment

    # Download base system
    download_base_system

    # Configure system
    configure_system

    # Install packages
    install_packages

    # Configure desktop
    configure_desktop

    # Create users
    create_users

    # Install Piexed OS specific
    install_piexed_specific

    # Configure services
    configure_services

    # Cleanup
    cleanup_system

    # Unmount filesystems
    unmount_filesystems

    # Create live system
    create_live_system

    # Create boot images
    create_boot_images

    # Build installer
    build_installer

    # Create ISO
    create_iso

    echo ""
    log_success "=============================================="
    log_success "Piexed OS build completed successfully!"
    log_success "=============================================="
    echo ""
    log_info "ISO Location: ${OUTPUT_DIR}/piexed-os-${PIEXED_VERSION}.iso"
    log_info "Size: $(du -h "${OUTPUT_DIR}/piexed-os-${PIEXED_VERSION}.iso" | cut -f1)"
    echo ""
    log_info "To write to USB: sudo dd if=${OUTPUT_DIR}/piexed-os-${PIEXED_VERSION}.iso of=/dev/sdX bs=4M status=progress"
    echo ""
}

# Run main function
main "$@"