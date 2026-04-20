#!/bin/bash
#
# Piẻxed OS - Production Build Script
# Version: 1.0.0 Professional Edition
# Builds production-ready ISO for PC, Server, and Android
#

set -euo pipefail

PIEXED_VERSION="1.0.0"
PIEXED_CODENAME="Professional Edition"
UBUNTU_BASE="jammy"
ARCH="amd64"
BUILD_DIR="/workspace/piexed-os/build"
OUTPUT_DIR="/workspace/piexed-os/output"
WORKSPACE="/workspace/piexed-os/workspace"

RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
CYAN='\033[0;36m'
NC='\033[0m'

log_info() { echo -e "${BLUE}[INFO]${NC} $1"; }
log_success() { echo -e "${GREEN}[SUCCESS]${NC} $1"; }
log_warning() { echo -e "${YELLOW}[WARNING]${NC} $1"; }
log_error() { echo -e "${RED}[ERROR]${NC} $1"; }

print_banner() {
    echo -e "${CYAN}"
    cat << 'EOF'
    ╔═══════════════════════════════════════════════════════════╗
    ║                                                           ║
    ║     _ __     __              _                            ║
    ║     | '_ \   / _|  ___    __| |  ___  _ __  ___          ║
    ║     | | | | | |_  / _ \  / _` | / _ \| '_ \/ __|         ║
    ║     | |_| | |  _|| (_) || (_| ||  __/| | | \__ \         ║
    ║     |____/  |_|   \___/  \__,_||\___||_| |_|___/         ║
    ║                                                           ║
    ║     Production Build System v1.0.0                      ║
    ║     Professional Edition                                 ║
    ╚═══════════════════════════════════════════════════════════╝
EOF
    echo -e "${NC}"
}

check_dependencies() {
    log_info "Checking build dependencies..."
    
    local deps=("debootstrap" "squashfs-tools" "xorriso" "grub-pc-bin" "grub-efi-amd64-bin" "mtools" "gdisk" "parted" "fakeroot" "rsync")
    local missing=()
    
    for dep in "${deps[@]}"; do
        if ! command -v "$dep" &> /dev/null; then
            missing+=("$dep")
        fi
    done
    
    if [ ${#missing[@]} -gt 0 ]; then
        log_warning "Installing missing dependencies: ${missing[*]}"
        sudo apt-get update
        sudo apt-get install -y "${missing[@]}"
    fi
    
    log_success "All dependencies satisfied"
}

create_directories() {
    log_info "Creating build directories..."
    mkdir -p "${BUILD_DIR}"
    mkdir -p "${OUTPUT_DIR}"
    mkdir -p "${WORKSPACE}"/{chroot,image,squashfs,efi,boot}
    log_success "Directories created"
}

download_base_system() {
    log_info "Downloading Ubuntu ${UBUNTU_BASE} base system..."
    
    cd "${WORKSPACE}"
    
    if [ ! -d "chroot/etc" ]; then
        sudo debootstrap --arch="${ARCH}" --variant=minbase --include=ubuntu-standard "${UBUNTU_BASE}" chroot "http://archive.ubuntu.com/ubuntu/" || {
            log_error "Failed to download base system"
            exit 1
        }
    else
        log_warning "Base system already exists"
    fi
    
    log_success "Base system ready"
}

configure_base_system() {
    log_info "Configuring base system..."
    
    sudo tee "${WORKSPACE}/chroot/etc/apt/sources.list" > /dev/null << 'EOF'
deb http://archive.ubuntu.com/ubuntu/ jammy main restricted universe multiverse
deb http://archive.ubuntu.com/ubuntu/ jammy-updates main restricted universe multiverse
deb http://archive.ubuntu.com/ubuntu/ jammy-security main restricted universe multiverse
deb http://archive.ubuntu.com/ubuntu/ jammy-backports main restricted universe multiverse
EOF

    sudo tee "${WORKSPACE}/chroot/etc/hostname" > /dev/null << 'EOF'
piexed-os
EOF

    sudo tee "${WORKSPACE}/chroot/etc/hosts" > /dev/null << 'EOF'
127.0.0.1   localhost
127.0.1.1   piexed-os

# The following lines are desirable for IPv6 capable hosts
::1     ip6-localhost ip6-loopback
fe00::0 ip6-localnet
ff00::0 ip6-mcastprefix
ff02::1 ip6-allnodes
ff02::2 ip6-allrouters
EOF

    log_success "Base system configured"
}

install_packages() {
    log_info "Installing system packages..."
    
    sudo chroot "${WORKSPACE}/chroot" /bin/bash << 'EOF'
set -e
export DEBIAN_FRONTEND=noninteractive

# Update package list
apt-get update

# Install essential packages
apt-get install -y \
    linux-image-generic \
    linux-headers-generic \
    ubuntu-standard \
    initramfs-tools \
    initramfs-tools-core \
    linux-firmware \
    openssh-server \
    sudo \
    adduser \
    passwd \
    locales \
    dbus \
    systemd \
    udev \
    network-manager \
    iputils-ping \
    net-tools \
    dnsutils \
    curl \
    wget \
    git \
    vim \
    nano \
    tar \
    gzip \
    bzip2 \
    xz-utils \
    zip \
    unzip \
    rsync \
    cron \
    logrotate \
    rsyslog \
    apt-listchanges \
    needrestart \
    unfree

# Install desktop environment
apt-get install -y \
    xorg \
    x11-apps \
    x11-utils \
    x11-xserver-utils \
    xfce4 \
    xfce4-goodies \
    xfce4-terminal \
    thunar \
    thunar-volman \
    thunar-archive-plugin \
    mousepad \
    ristretto \
    lightdm \
    lightdm-gtk-greeter \
    xfwm4 \
    xfce4-panel \
    xfce4-settings \
    xfce4-appfinder \
    xfce4-notifyd \
    xfce4-power-manager \
    xfce4-session \
    xfce4-screenshooter \
    xfce4-taskmanager \
    xfce4-systemload-plugin \
    xfce4-pulseaudio-plugin \
    xfce4-battery-plugin \
    xfce4-clipman-plugin \
    gtk2-engines-xfce \
    arc-theme \
    papirus-icon-theme \
    fonts-noto \
    fonts-ubuntu

# Install productivity
apt-get install -y \
    firefox \
    thunderbird \
    vlc \
    libreoffice \
    gimp \
    shotwell \
    evince \
    file-roller \
    gnome-calculator \
    gnome-screenshot

# Install development
apt-get install -y \
    build-essential \
    gcc \
    g++ \
    make \
    cmake \
    ninja-build \
    git \
    python3 \
    python3-pip \
    software-properties-common \
    apt-transport-https \
    ca-certificates

# Install performance
apt-get install -y \
    preload \
    zram-config \
    earlyoom \
    thermald

# Install security
apt-get install -y \
    ufw \
    fail2ban \
    libpam-pwquality \
    libpam-tmpdir \
    auditd

# Install server packages (optional)
apt-get install -y \
    openssh-server \
    net-tools \
    htop \
    tmux \
    wget \
    curl

# Clean up
apt-get autoremove -y
apt-get clean

# Create Piexed user
useradd -m -s /bin/bash piexed || true
echo "piexed:piexed" | chpasswd
usermod -aG sudo piexed

# Enable sudo for piexed
echo "piexed ALL=(ALL) NOPASSWD:ALL" > /etc/sudoers.d/piexed

EOF

    log_success "Packages installed"
}

configure_security() {
    log_info "Configuring security..."
    
    sudo chroot "${WORKSPACE}/chroot" /bin/bash << 'EOF'
set -e

# Configure UFW firewall
ufw default deny incoming
ufw default allow outgoing
ufw enable

# Configure fail2ban
cat > /etc/fail2ban/jail.local << 'FAIL2BAN'
[DEFAULT]
bantime = 3600
findtime = 600
maxretry = 3

[sshd]
enabled = true
port = ssh
filter = sshd
logpath = /var/log/auth.log
maxretry = 3
FAIL2BAN

# Configure PAM password policy
cat > /etc/pam.d/common-password << 'PAM'
password        [success=1 default=ignore]      pam_pwquality.so retry=3 minlen=12 difok=3 ucredit=-1 lcredit=-1 dcredit=-1 ocredit=-1
password        [success=1 default=ignore]      pam_unix.so sha512 use_authtok
PAM

# Disable root login
sed -i 's/^PermitRootLogin.*/PermitRootLogin no/' /etc/ssh/sshd_config
sed -i 's/^#*PasswordAuthentication.*/PasswordAuthentication yes/' /etc/ssh/sshd_config

# Set secure permissions
chmod 755 /etc/sudoers.d
chmod 644 /etc/passwd
chmod 644 /etc/group
chmod 600 /etc/shadow
chmod 700 /root
chmod 700 /home/*

# Configure audit
echo "-w /etc/passwd -p wa -k identity" >> /etc/audit/audit.rules
echo "-w /etc/shadow -p wa -k identity" >> /etc/audit/audit.rules
echo "-w /etc/ssh/sshd_config -p wa -k sshd" >> /etc/audit/audit.rules

EOF

    log_success "Security configured"
}

configure_desktop() {
    log_info "Configuring desktop environment..."
    
    sudo chroot "${WORKSPACE}/chroot" /bin/bash << 'EOF'
set -e

mkdir -p /root/.config
mkdir -p /home/piexed/.config
mkdir -p /etc/xdg/xfce4

# Configure LightDM
cat > /etc/lightdm/lightdm.conf << 'LIGHTDM'
[LightDM]
autologin-user=piexed
autologin-user-timeout=0

[Seat:*]
autologin-guest=false
autologin-user=piexed
autologin-user-timeout=0
greeter-user=lightdm
greeter-session=example-gtk-gnome
session-wrapper=lightdm-session
lightdm-gtk-greeter-configuration=/etc/lightdm/lightdm-gtk-greeter.conf

[VNCServer]
LIGHTDM

cat > /etc/lightdm/lightdm-gtk-greeter.conf << 'GREETER'
[greeter]
background = #1A1A2E
theme-name = Arc-Dark
icon-theme-name = Papirus-Dark
font-name = Ubuntu 12
xft-antialiasing = true
xft-dpi = 96
xft-hinting = true
xft-hintstyle = hintslight
xft-rgba = rgb
cursor-theme-name = Adwaita
cursor-size = 24
show-language-selector = true
show-power-manager = true
user-background = true
default-user-image = /usr/share/pixmaps/avatar.png
GREETER

# Configure XFCE
cat > /etc/xdg/xfce4/xfconf/xfce-perchannel-xml/xfce4-session.xml << 'XFCE'
<?xml version="1.0" encoding="UTF-8"?>
<channel name="xfce4-session" version="1.0">
  <property name="CountSplash" type="bool" value="true"/>
  <property name="CustomCommand" type="string" value="xfce4-session"/>
  <property name="DefaultSession" type="string" value="xfce"/>
  <property name="LastSavedSession" type="string" value="xfce"/>
  <property name="LockCommand" type="string" value="xflock4"/>
  <property name="SecurityLevel" type="uint" value="0"/>
  <property name="SessionCommand" type="string" value="xfce4-session"/>
  <property name="SessionsSplash" type="bool" value="true"/>
  <property name="ShutdownCommand" type="string" value="xfce4-session-logout"/>
</channel>
XFCE

# Create autostart
mkdir -p /etc/xdg/autostart
cat > /etc/xdg/autostart/pulseaudio.desktop << 'AUTOSTART'
[Desktop Entry]
Type=Application
Name=PulseAudio
Exec=pulseaudio --start --log-target=syslog
AUTOSTART

EOF

    log_success "Desktop configured"
}

configure_system() {
    log_info "Configuring system settings..."
    
    sudo chroot "${WORKSPACE}/chroot" /bin/bash << 'EOF'
set -e

# Set timezone
ln -sf /usr/share/zoneinfo/UTC /etc/localtime
dpkg-reconfigure -f noninteractive tzdata

# Generate locales
sed -i 's/# en_US.UTF-8/en_US.UTF-8/' /etc/locale.gen
locale-gen

# Configure network
cat > /etc/network/interfaces << 'NETWORK'
auto lo
iface lo inet loopback
NETWORK

# Enable services
systemctl enable NetworkManager
systemctl enable ssh
systemctl enable fail2ban
systemctl enable ufw
systemctl enable systemd-timesyncd

# Configure logrotate
cat > /etc/logrotate.d/piexed << 'LOGROTATE'
/var/log/piexed/*.log {
    daily
    rotate 7
    compress
    delaycompress
    missingok
    notifempty
    create 0644 root root
}
LOGROTATE

# Create Piẻxed OS info
cat > /etc/piexed-version << 'VERSION'
PIEXED_VERSION="1.0.0"
PIEXED_CODENAME="Professional Edition"
PIEXED_BUILD=$(date +%Y%m%d)
VERSION

cat > /etc/os-release << 'OSRELEASE'
NAME="Piẻxed OS"
VERSION="1.0.0 (Professional Edition)"
ID=piexed
ID_LIKE=ubuntu
PRETTY_NAME="Piẻxed OS 1.0.0 Professional Edition"
VERSION_ID="1.0.0"
HOME_URL="https://piexed-os.org"
SUPPORT_URL="https://github.com/piexed-os"
BUG_REPORT_URL="https://github.com/piexed-os/issues"
PRIVACY_POLICY_URL="https://piexed-os.org/privacy"
VERSION_CODENAME=professional
UBUNTU_CODENAME=jammy
OSRELEASE

# Configure kernel parameters
cat > /etc/sysctl.d/99-piexed.conf << 'SYSCTL'
# Network optimizations
net.ipv4.tcp_timestamps = 1
net.ipv4.tcp_sack = 1
net.ipv4.tcp_window_scaling = 1
net.core.rmem_max = 16777216
net.core.wmem_max = 16777216

# Memory optimizations
vm.swappiness = 10
vm.vfs_cache_pressure = 60

# Security
kernel.dmesg_restrict = 1
kernel.kptr_restrict = 2
net.ipv4.conf.all.rp_filter = 1
net.ipv4.conf.default.rp_filter = 1
net.ipv4.icmp_echo_ignore_broadcasts = 1
net.ipv4.conf.all.accept_redirects = 0
net.ipv4.conf.default.accept_redirects = 0
net.ipv4.conf.all.send_redirects = 0
net.ipv4.conf.default.send_redirects = 0
net.ipv4.conf.all.accept_source_route = 0
net.ipv4.conf.default.accept_source_route = 0
SYSCTL

# Configure limits
cat > /etc/security/limits.d/piexed.conf << 'LIMITS'
* soft nofile 65536
* hard nofile 65536
* soft nproc 65536
* hard nproc 65536
LIMITS

EOF

    log_success "System configured"
}

install_auto_update() {
    log_info "Installing auto-update system..."
    
    sudo mkdir -p "${WORKSPACE}/chroot/usr/local/bin/piexed-updater"
    
    sudo tee "${WORKSPACE}/chroot/usr/local/bin/piexed-updater/piexed-update.sh" > /dev/null << 'UPDATER'
#!/bin/bash
#
# Piẻxed OS Auto-Update System
# Automatically updates from GitHub repository
#

set -e

REPO_URL="https://github.com/piexed-os/piexed-os"
UPDATE_BRANCH="main"
LOG_FILE="/var/log/piexed-update.log"

log() {
    echo "[$(date '+%Y-%m-%d %H:%M:%S')] $1" | tee -a "$LOG_FILE"
}

check_for_updates() {
    log "Checking for updates..."
    
    cd /tmp
    
    if [ -d "/tmp/piexed-update" ]; then
        rm -rf /tmp/piexed-update
    fi
    
    git clone --depth 1 -b "$UPDATE_BRANCH" "$REPO_URL" /tmp/piexed-update || {
        log "Failed to clone repository"
        exit 1
    }
    
    CURRENT_VERSION=$(cat /etc/piexed-version 2>/dev/null | grep VERSION | cut -d'"' -f2 || echo "0.0.0")
    NEW_VERSION=$(cat /tmp/piexed-update/etc/piexed-version 2>/dev/null | grep VERSION | cut -d'"' -f2 || echo "0.0.0")
    
    if [ "$NEW_VERSION" != "$CURRENT_VERSION" ]; then
        log "New version available: $NEW_VERSION (current: $CURRENT_VERSION)"
        return 0
    else
        log "System is up to date"
        return 1
    fi
}

perform_update() {
    log "Starting update process..."
    
    # Backup current system
    log "Creating backup..."
    mkdir -p /var/backup/piexed
    dpkg --get-selections > /var/backup/piexed/package-list.txt
    cp -r /etc /var/backup/piexed/
    
    # Update package lists
    log "Updating package lists..."
    apt-get update -qq
    
    # Upgrade system
    log "Upgrading system packages..."
    DEBIAN_FRONTEND=noninteractive apt-get upgrade -y -qq
    
    # Install new packages
    log "Installing new packages..."
    DEBIAN_FRONTEND=noninteractive apt-get dist-upgrade -y -qq
    
    # Restart services
    log "Restarting services..."
    systemctl restart NetworkManager || true
    systemctl restart ssh || true
    
    # Update Piẻxed OS files
    if [ -d "/tmp/piexed-update/usr" ]; then
        log "Updating Piẻxed OS system files..."
        cp -r /tmp/piexed-update/usr/local/bin/* /usr/local/bin/ || true
    fi
    
    # Clean up
    log "Cleaning up..."
    apt-get autoremove -y -qq
    apt-get clean -qq
    
    log "Update completed successfully!"
    log "System will reboot in 10 seconds..."
    sleep 10
    reboot
}

install_cron() {
    # Install daily update check cron
    cat > /etc/cron.daily/piexed-update << 'CRON'
#!/bin/bash
/usr/local/bin/piexed-updater/piexed-update.sh --check
CRON
    chmod +x /etc/cron.daily/piexed-update
    
    # Install systemd timer
    cat > /etc/systemd/system/piexed-update.timer << 'TIMER'
[Unit]
Description=Piexed OS Auto Update Timer

[Timer]
OnCalendar=daily
Persistent=true

[Install]
WantedBy=timers.target
TIMER

    cat > /etc/systemd/system/piexed-update.service << 'SERVICE'
[Unit]
Description=Piexed OS Auto Update
After=network-online.target
Wants=network-online.target

[Service]
Type=oneshot
ExecStart=/usr/local/bin/piexed-updater/piexed-update.sh --update
StandardOutput=journal
StandardError=journal
SERVICE

    systemctl daemon-reload
    systemctl enable piexed-update.timer || true
}

# Main
if [ "$1" == "--check" ]; then
    check_for_updates
elif [ "$1" == "--update" ]; then
    if check_for_updates; then
        perform_update
    fi
else
    echo "Usage: $0 [--check|--update]"
    exit 1
fi
UPDATER

    sudo chmod +x "${WORKSPACE}/chroot/usr/local/bin/piexed-updater/piexed-update.sh"
    
    # Install cron and systemd timer
    sudo chroot "${WORKSPACE}/chroot" /bin/bash << 'EOF'
chmod +x /usr/local/bin/piexed-updater/piexed-update.sh
bash /usr/local/bin/piexed-updater/piexed-update.sh --install-cron || true
EOF

    log_success "Auto-update system installed"
}

install_piexed_tools() {
    log_info "Installing Piẻxed OS tools..."
    
    sudo tee "${WORKSPACE}/chroot/usr/local/bin/piexed-info" > /dev/null << 'EOF'
#!/bin/bash
echo "============================================="
echo "   Piẻxed OS System Information"
echo "============================================="
echo ""
echo "Version:     $(cat /etc/piexed-version | grep VERSION | cut -d'"' -f2)"
echo "Codename:    $(cat /etc/piexed-version | grep CODENAME | cut -d'"' -f2)"
echo "Build:       $(cat /etc/piexed-version | grep BUILD | cut -d'=' -f2)"
echo "Kernel:      $(uname -r)"
echo "Architecture: $(uname -m)"
echo ""
echo "Uptime:      $(uptime -p)"
echo "Disk Usage:  $(df -h / | tail -1 | awk '{print $3 " / " $2 " (" $5 ")"}')"
echo "Memory:      $(free -h | awk '/^Mem:/ {print $3 " / " $2}')"
echo ""
echo "============================================="
EOF

    sudo tee "${WORKSPACE}/chroot/usr/local/bin/piexed-clean" > /dev/null << 'EOF'
#!/bin/bash
echo "Piẻxed OS System Cleaner"
echo "Cleaning system..."

apt-get clean
apt-get autoremove -y
rm -rf /var/cache/apt/archives/*
rm -rf /var/tmp/*
rm -rf /tmp/*
rm -rf ~/.cache/*

echo "System cleaned!"
EOF

    sudo chmod +x "${WORKSPACE}/chroot/usr/local/bin/piexed-"*

    log_success "Piẻxed tools installed"
}

configure_grub() {
    log_info "Configuring GRUB..."
    
    sudo chroot "${WORKSPACE}/chroot" /bin/bash << 'EOF'
set -e

# Configure GRUB
cat > /etc/default/grub << 'GRUB'
GRUB_DEFAULT=0
GRUB_TIMEOUT=2
GRUB_TIMEOUT_STYLE=hidden
GRUB_DISTRIBUTOR="Piẻxed OS"
GRUB_CMDLINE_LINUX_DEFAULT="quiet splash loglevel=3"
GRUB_CMDLINE_LINUX=""
GRUB_DISABLE_RECOVERY="true"
GRUB_GFXMODE=1920x1080
GRUB_GFXPAYLOAD_LINUX=keep
GRUB_THEME=/boot/grub/themes/piexed/theme.txt
GRUB

# Create GRUB theme directory
mkdir -p /boot/grub/themes/piexed

# Generate GRUB config
update-grub

EOF

    log_success "GRUB configured"
}

create_iso() {
    log_info "Creating ISO image..."
    
    cd "${WORKSPACE}"
    
    # Prepare filesystem
    log_info "Preparing filesystem..."
    sudo rsync -a --exclude='/proc/*' --exclude='/sys/*' --exclude='/dev/*' --exclude='/run/*' --exclude='/tmp/*' chroot/ image/
    
    # Create squashfs
    log_info "Creating squashfs..."
    sudo mksquashfs image squashfs/filesystem.squashfs -noappend -comp xz -e boot
    
    # Create boot image
    log_info "Creating boot image..."
    sudo mkdir -p efi/boot
    
    # Copy kernel
    sudo cp -r image/boot/* efi/boot/ 2>/dev/null || true
    
    # Create EFI boot image
    if [ -f "/usr/lib/shim/shimx64.efi.signed" ]; then
        sudo cp /usr/lib/shim/shimx64.efi.signed efi/boot/shimx64.efi
    fi
    
    if [ -f "/usr/lib/grub/x86_64-efi-signed/grubnetx64.efi.signed" ]; then
        sudo cp /usr/lib/grub/x86_64-efi-signed/grubnetx64.efi.signed efi/boot/grubx64.efi
    fi
    
    # Create boot config
    sudo tee efi/boot/grub.cfg << 'GRUBCFG'
set default="0"
set timeout="2"
set timeout_style="hidden"

menuentry "Piẻxed OS Professional Edition" {
    search --no-floppy --set=root --label=PIEXED
    linux /boot/vmlinuz boot=casper quiet splash loglevel=3 ---
    initrd /boot/initrd.img
}

menuentry "Piẻxed OS (Safe Graphics)" {
    search --no-floppy --set=root --label=PIEXED
    linux /boot/vmlinuz boot=casper nomodeset ---
    initrd /boot/initrd.img
}
GRUBCFG

    # Create ISO
    log_info "Generating ISO..."
    sudo xorriso -as mkisofs \
        -iso-level 3 \
        -full-iso9660-filenames \
        -volid "PIEXED_OS_1.0.0" \
        -appid "Piẻxed OS Professional Edition" \
        -publisher "Piẻxed OS Team" \
        -preparer "Piẻxed OS Build System" \
        -eltorito-boot boot/grub/bios.img \
        -no-emul-boot \
        -boot-load-size 4 \
        -boot-info-table \
        -eltorito-catalog boot/grub/boot.cat \
        --grub2-mbr /usr/lib/grub/i386-pc/boot_hybrid.img \
        -partition_offset 16 \
        -append_partition 2 0xef efi \
        -output "${OUTPUT_DIR}/piexed-os-${PIEXED_VERSION}-professional.iso" \
        . || {
            log_error "ISO creation failed, trying alternative method..."
            
            sudo xorriso -as mkisofs \
                -iso-level 3 \
                -full-iso9660-filenames \
                -volid "PIEXED_OS_1.0.0" \
                -output "${OUTPUT_DIR}/piexed-os-${PIEXED_VERSION}-professional.iso" \
                .
        }
    
    # Verify ISO
    if [ -f "${OUTPUT_DIR}/piexed-os-${PIEXED_VERSION}-professional.iso" ]; then
        log_success "ISO created successfully!"
        ls -lh "${OUTPUT_DIR}/piexed-os-${PIEXED_VERSION}-professional.iso"
    else
        log_error "ISO creation failed"
        exit 1
    fi
}

main() {
    print_banner
    
    check_dependencies
    create_directories
    download_base_system
    configure_base_system
    install_packages
    configure_security
    configure_desktop
    configure_system
    install_auto_update
    install_piexed_tools
    configure_grub
    create_iso
    
    log_success "Build completed successfully!"
    log_success "ISO: ${OUTPUT_DIR}/piexed-os-${PIEXED_VERSION}-professional.iso"
}

main "$@"
