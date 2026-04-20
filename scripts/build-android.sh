#!/bin/bash
#
# Piẻxed OS - Android Build Script (Termux/UserLAnd)
# Version: 1.0.0 Professional Edition
#

set -euo pipefail

PIEXED_VERSION="1.0.0"
PIEXED_CODENAME="Android Edition"
UBUNTU_BASE="jammy"
ARCH="arm64"
OUTPUT_DIR="$(pwd)/output"

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
    ║     Android Edition Build System v1.0.0                ║
    ║     Professional Edition                                 ║
    ╚═══════════════════════════════════════════════════════════╝
EOF
    echo -e "${NC}"
}

check_proot() {
    if ! command -v proot &> /dev/null && ! command -v proot-distro &> /dev/null; then
        log_error "proot or proot-distro is required"
        log_info "Install it with: pkg install proot-distro"
        exit 1
    fi
}

create_ubuntu_chroot() {
    log_info "Creating Ubuntu chroot for Android..."
    
    if command -v proot-distro &> /dev/null; then
        proot-distro add ubuntu-piexed || {
            log_info "Installing Ubuntu with proot-distro..."
            proot-distro install ubuntu
        }
        
        log_info "Configuring Ubuntu..."
        proot-distro login ubuntu-piexed -- /bin/bash << 'PROOTSETUP'
set -e
export DEBIAN_FRONTEND=noninteractive

apt-get update

apt-get install -y \
    sudo \
    curl \
    wget \
    git \
    vim \
    nano \
    tar \
    gzip \
    htop \
    tmux \
    screen \
    fonts-noto \
    xfce4 \
    xfce4-goodies \
    xfce4-terminal \
    thunar \
    lightdm \
    xfwm4 \
    xfce4-panel \
    xfce4-settings \
    network-manager \
    dbus-x11 \
    gtk2-engines-xfce \
    arc-theme \
    papirus-icon-theme \
    firefox \
    vlc \
    libreoffice \
    python3 \
    python3-pip \
    build-essential

useradd -m -s /bin/bash piexed || true
echo "piexed:piexed" | chpasswd
usermod -aG sudo piexed
echo "piexed ALL=(ALL) NOPASSWD:ALL" > /etc/sudoers.d/piexed

cat > /etc/piexed-version << 'VERSION'
PIEXED_VERSION="1.0.0"
PIEXED_CODENAME="Android Edition"
VERSION

cat > /etc/os-release << 'OSRELEASE'
NAME="Piẻxed OS Android"
VERSION="1.0.0 (Android Edition)"
ID=piexed-android
ID_LIKE=ubuntu
PRETTY_NAME="Piẻxed OS 1.0.0 Android Edition"
VERSION_ID="1.0.0"
VERSION_CODENAME=android
UBUNTU_CODENAME=jammy
OSRELEASE

apt-get clean
PROOTSETUP
        
        log_success "Ubuntu chroot created"
    else
        log_info "Using proot..."
        mkdir -p /root/ubuntu-piexed
        
        proot --link2symlink \
            debootstrap --variant=minbase \
            --arch arm64 \
            jammy /root/ubuntu-piexed \
            http://archive.ubuntu.com/ubuntu/ || {
            
            log_warning "Debootstrap failed, installing base manually..."
            apt-get download ubuntu-base 2>/dev/null || true
        }
        
        log_success "Android chroot created"
    fi
}

create_termux_script() {
    log_info "Creating Termux launcher script..."
    
    cat > "${OUTPUT_DIR}/piexed-android-launch.sh" << 'LAUNCHER'
#!/bin/bash
# Piẻxed OS Android Launcher
# Run this in Termux to launch Piẻxed OS

export DISPLAY=:0
export XDG_RUNTIME_DIR=/tmp/runtime-$(id -u)
mkdir -p "$XDG_RUNTIME_DIR"

if command -v proot-distro &> /dev/null; then
    proot-distro login ubuntu-piexed
elif command -v proot &> /dev/null; then
    proot -C /root/ubuntu-piexed -b /dev/busfs:/dev/busfs -b /proc -b /sys --
        /bin/bash -l
else
    echo "Error: proot not found. Install with: pkg install proot"
    exit 1
fi
LAUNCHER

    chmod +x "${OUTPUT_DIR}/piexed-android-launch.sh"
    log_success "Termux script created"
}

create_x11_script() {
    log_info "Creating X11 launcher script..."
    
    cat > "${OUTPUT_DIR}/piexed-android-x11.sh" << 'X11LAUNCHER'
#!/bin/bash
# Piẻxed OS Android X11 Launcher
# Run this in Termux with Termux:X11 for GUI

export DISPLAY=:0
export XDG_RUNTIME_DIR=/tmp/runtime-$(id -u)
export PULSE_SERVER=127.0.0.1
mkdir -p "$XDG_RUNTIME_DIR"

echo "Starting Piẻxed OS (X11)..."

if command -v proot-distro &> /dev/null; then
    proot-distro login ubuntu-piexed -- /bin/bash -c "
        startxfce4 || xfwm4 || echo 'Starting XFCE4...'
    "
else
    echo "Error: proot not found"
    exit 1
fi
X11LAUNCHER

    chmod +x "${OUTPUT_DIR}/piexed-android-x11.sh"
    log_success "X11 script created"
}

create_android_install_script() {
    log_info "Creating Android installer script..."
    
    cat > "${OUTPUT_DIR}/piexed-android-install.sh" << 'INSTALLER'
#!/bin/bash
#
# Piẻxed OS - Android Installer
# Install Piẻxed OS on Android (Termux/UserLAnd)
#

set -e

INSTALL_DIR="${INSTALL_DIR:-$HOME/piexed-os}"
PIEXED_VERSION="1.0.0"

echo "=== Piẻxed OS Android Installer ==="
echo "Version: $PIEXED_VERSION"
echo "Installing to: $INSTALL_DIR"
echo ""

# Check if running in Termux
if [ -d "/data/data/com.termux" ]; then
    echo "Running in Termux..."
    
    # Install dependencies
    echo "Installing dependencies..."
    pkg update
    pkg install -y proot-distro wget curl git x11-repo xorg-x11-fonts
    
    # Create Ubuntu rootfs
    echo "Creating Ubuntu environment..."
    proot-distro add ubuntu-piexed || true
    
    # Install Piẻxed OS
    echo "Installing Piẻxed OS packages..."
    proot-distro login ubuntu-piexed -- /bin/bash << 'EOF'
set -e
export DEBIAN_FRONTEND=noninteractive

# Install desktop
apt-get update
apt-get install -y xfce4 xfce4-goodies xfce4-terminal thunar lightdm xfwm4
apt-get install -y network-manager dbus-x11 gtk2-engines-xfce arc-theme papirus-icon-theme
apt-get install -y firefox vlc python3

# Install Piẻxed tools
mkdir -p /usr/local/bin
cat > /usr/local/bin/piexed-info << 'TOOL'
#!/bin/bash
echo "Piexed OS Android Edition v1.0.0"
uname -a
echo "Disk: $(df -h / | tail -1)"
echo "Memory: $(free -h | awk '/^Mem:/ {print $3 "/" $2}')"
TOOL
chmod +x /usr/local/bin/piexed-info

# Create user
useradd -m -s /bin/bash piexed || true
echo "piexed:piexed" | chpasswd

echo "Piẻxed OS installed successfully!"
echo ""
echo "To launch desktop:"
echo "  ./piexed-android-x11.sh"
EOF
    
    # Create launcher scripts
    cat > "$INSTALL_DIR/piexed-android-launch.sh" << 'EOF'
#!/bin/bash
export DISPLAY=:0
proot-distro login ubuntu-piexed
EOF
    chmod +x "$INSTALL_DIR/piexed-android-launch.sh"
    
    cat > "$INSTALL_DIR/piexed-android-x11.sh" << 'EOF'
#!/bin/bash
export DISPLAY=:0
export XDG_RUNTIME_DIR=/tmp/runtime-$(id -u)
mkdir -p "$XDG_RUNTIME_DIR"
termux-x11 :0 &
sleep 2
proot-distro login ubuntu-piexed -- startxfce4
EOF
    chmod +x "$INSTALL_DIR/piexed-android-x11.sh"
    
    echo "Installation complete!"
    echo "Run: $INSTALL_DIR/piexed-android-x11.sh"

elif [ -d "/data/data/com.termux" ] || [ -d "/data/data/com.termux" ]; then
    echo "Running in UserLAnd..."
    
    # Install Piẻxed OS
    apt-get update
    apt-get install -y xfce4 xfce4-goodies lightdm
    apt-get install -y firefox vlc python3
    
    echo "Installation complete!"

else
    echo "Error: Not running in Termux or UserLAnd"
    exit 1
fi

echo ""
echo "=== Installation Complete ==="
echo ""
echo "To start Piẻxed OS Desktop:"
echo "  termux-x11 &"
echo "  proot-distro login ubuntu-piexed -- startxfce4"
echo ""
echo "For CLI mode:"
echo "  proot-distro login ubuntu-piexed"
echo ""
echo "Piẻxed OS Android Edition v$PIEXED_VERSION installed!"
INSTALLER

    chmod +x "${OUTPUT_DIR}/piexed-android-install.sh"
    log_success "Android installer created"
}

main() {
    print_banner
    
    check_proot
    mkdir -p "${OUTPUT_DIR}"
    
    create_android_install_script
    create_termux_script
    create_x11_script
    
    log_success "Android build completed!"
}

main "$@"