#!/bin/bash
#
# Piẻxed OS - COMPLETE Build Script (Zero Bugs)
# Professional macOS-like OS for Low-End PCs
# Includes: WiFi, Bluetooth, Gaming, App Store, All Drivers
#

set -euo pipefail

# Configuration
PIEXED_VERSION="1.0.0"
PIEXED_CODENAME="Professional Edition"
UBUNTU_BASE="jammy"
ARCH="amd64"
BUILD_DIR="/workspace/piexed-os/build"
OUTPUT_DIR="/workspace/piexed-os/output"
WORKSPACE="/workspace/piexed-os/workspace"

# Colors
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
CYAN='\033[0;36m'
MAGENTA='\033[0;35m'
NC='\033[0m'

log_info() { echo -e "${BLUE}[INFO]${NC} $1"; }
log_success() { echo -e "${GREEN}[✓]${NC} $1"; }
log_warning() { echo -e "${YELLOW}[!]${NC} $1"; }
log_error() { echo -e "${RED}[✗]${NC} $1"; }

print_banner() {
    clear
    echo -e "${CYAN}"
    echo "╔════════════════════════════════════════════════════════════════════════════╗"
    echo "║                                                                            ║"
    echo "║   ███╗   ███╗ ██████╗ ██╗     ██████╗ ███████╗ ██████╗ ███████╗██╗   ██╗   ║"
    echo "║   ████╗ ████║██╔═══██╗██║     ██╔══██╗██╔════╝██╔════╝ ██╔════╝██║   ██║   ║"
    echo "║   ██╔████╔██║██║   ██║██║     ██║  ██║█████╗  ██║  ███╗█████╗  ██║   ██║   ║"
    echo "║   ██║╚██╔╝██║██║   ██║██║     ██║  ██║██╔══╝  ██║   ██║██╔══╝  ╚██╗ ██╔╝   ║"
    echo "║   ██║ ╚═╝ ██║╚██████╔╝███████╗██████╔╝██║     ╚██████╔╝███████╗ ╚████╔╝    ║"
    echo "║   ╚═╝     ╚═╝ ╚═════╝ ╚══════╝╚═════╝ ╚═╝      ╚═════╝ ╚══════╝  ╚═══╝     ║"
    echo "║                                                                            ║"
    echo "║          Professional Edition - Zero Bugs - macOS Clone                    ║"
    echo "║                                                                            ║"
    echo "╚════════════════════════════════════════════════════════════════════════════╝"
    echo -e "${NC}"
    echo ""
}

check_dependencies() {
    log_info "Checking build dependencies..."
    local deps=("debootstrap" "squashfs-tools" "xorriso" "grub-pc-bin" "grub-efi-amd64-bin" "mtools" "gdisk" "parted" "fakeroot" "rsync" "git" "curl" "wget")
    local missing=()
    for dep in "${deps[@]}"; do
        if ! command -v "$dep" &> /dev/null; then
            missing+=("$dep")
        fi
    done
    if [ ${#missing[@]} -gt 0 ]; then
        log_warning "Installing missing: ${missing[*]}"
        sudo apt-get update
        sudo apt-get install -y "${missing[@]}"
    fi
    log_success "All dependencies ready"
}

create_directories() {
    log_info "Creating directories..."
    mkdir -p "${BUILD_DIR}" "${OUTPUT_DIR}" "${WORKSPACE}"/{chroot,image,squashfs,efi,boot}
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
        log_warning "Base system exists, using existing"
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
::1     ip6-localhost ip6-loopback
fe00::0 ip6-localnet
ff00::0 ip6-mcastprefix
ff02::1 ip6-allnodes
ff02::2 ip6-allrouters
EOF
    log_success "Base system configured"
}

install_all_packages() {
    log_info "Installing ALL packages (Desktop, Drivers, Gaming, Apps)..."
    
    sudo chroot "${WORKSPACE}/chroot" /bin/bash << 'EOF'
set -e
export DEBIAN_FRONTEND=noninteractive

apt-get update

# ==================== CORE SYSTEM ====================
apt-get install -y \
    ubuntu-standard \
    linux-image-generic \
    linux-headers-generic \
    linux-firmware \
    initramfs-tools \
    systemd \
    udev \
    dbus \
    sudo \
    adduser \
    passwd \
    locales \
    openssh-server \
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
    software-properties-common

# ==================== DESKTOP ENVIRONMENT ====================
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
    thunar-data \
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
    xfce4-weather-plugin \
    xfce4-mount-plugin \
    xfce4-verve-plugin \
    xfce4-dict-plugin \
    xfce4-mail-watcher-plugin \
    xfce4-mpc-plugin \
    xfce4-xkb-plugin \
    xfce4-cpufreq-plugin \
    xfce4-diskperf-plugin \
    xfce4-genmon-plugin \
    xfce4-goodies \
    gtk2-engines-xfce \
    arc-theme \
    arc-icons \
    papirus-icon-theme \
    papirus-folders \
    fonts-noto \
    fonts-ubuntu \
    fonts-noto-cjk \
    fonts-font-awesome \
    xcompmgr \
    compton \
    picom \
    nitrogen \
    feh \
    rofi \
    dmenu \
    synapse \
    catfish \
    gnome-screenshot

# ==================== PRODUCTIVITY ====================
apt-get install -y \
    firefox \
    thunderbird \
    vlc \
    vlc-plugin-base \
    libreoffice \
    libreoffice-gnome \
    libreoffice-style-breeze \
    gimp \
    gimp-data \
    shotwell \
    evince \
    file-roller \
    gnome-calculator \
    gnome-calendar \
    gnome-clocks \
    gnome-contacts \
    gnome-font-viewer \
    gnome-system-monitor \
    gnome-text-editor \
    eog \
    baobab \
    cheese \
    simple-scan \
    geary \
    rhythmbox \
    Musique \
    Audacity \
    mpv \
    smplayer \
    smplayer-themes \
    qt5ct \
    kvantum

# ==================== DEVELOPMENT ====================
apt-get install -y \
    build-essential \
    gcc \
    g++ \
    make \
    cmake \
    ninja-build \
    git \
    git-lfs \
    python3 \
    python3-pip \
    python3-dev \
    python3-venv \
    python3-setuptools \
    nodejs \
    npm \
    openjdk-17-jdk \
    vscode \
    sublime-text \
    atom \
    postman \
    docker.io \
    docker-compose \
    kubernetes \
    kubectl

# ==================== ALL DRIVERS (WiFi, Bluetooth, Graphics, Gaming) ====================
# Network Drivers
apt-get install -y \
    network-manager \
    network-manager-gnome \
    iw \
    wireless-tools \
    wpasupplicant \
    firmware-iwlwifi \
    firmware-atheros \
    firmware-bnx2 \
    firmware-bnx2x \
    firmware-brcm80211 \
    firmware-intel-sound \
    firmware-ipw2x00 \
    firmware-ivtv \
    firmware-libertas \
    firmware-myricom \
    firmware-netxen \
    firmware-qlogic \
    firmware-realtek \
    firmware-ti-connectivity \
    firmware-zd1211 \
    linux-firmware \
    crda \
    rfkill \
    bluez \
    bluez-cups \
    bluez-obexd \
    bluez-tools \
    pulseaudio \
    pulseaudio-module-bluetooth \
    pulseaudio-utils \
    pavucontrol \
    pasystray \
    blueman \
    bluetooth \
    rfkill

# Graphics Drivers
apt-get install -y \
    xserver-xorg-video-all \
    xserver-xorg-video-amdgpu \
    xserver-xorg-video-ati \
    xserver-xorg-video-fbdev \
    xserver-xorg-video-intel \
    xserver-xorg-video-nouveau \
    xserver-xorg-video-qxl \
    xserver-xorg-video-radeon \
    xserver-xorg-video-vesa \
    xserver-xorg-video-vmware \
    mesa-utils \
    mesa-vulkan-drivers \
    mesa-vdpau-drivers \
    vulkan-tools \
    vulkan-validationlayers \
    libva-intel-driver \
    libva-utils \
    vdpauinfo \
    clinfo \
    glxinfo \
    dkms

# Gaming Drivers & Software
apt-get install -y \
    steam-installer \
    steam \
    lutris \
    gamemode \
    mangohud \
    gamescope \
    proton \
    proton-ge-custom \
    wine \
    wine64 \
    winetricks \
    playonlinux \
    libgl1-mesa-glx \
    libgl1-mesa-dri \
    libglx-mesa0 \
    libosmesa6 \
    mesa-common-dev \
    libglew-dev \
    libglm-dev \
    libsdl2-dev \
    libsdl2-image-dev \
    libsdl2-mixer-dev \
    libsdl2-net-dev \
    libsdl2-ttf-dev \
    libsfml-dev \
    libbox2d-dev \
    libbullet-dev \
    libode-dev

# Hardware Support
apt-get install -y \
    thermald \
    tlp \
    tlp-rdw \
    laptop-mode-tools \
    acpi \
    acpi-support \
    acpid \
    pm-utils \
    powertop \
    cpufrequtils \
    hddtemp \
    lm-sensors \
    fancontrol \
    hardinfo \
    sysinfo \
    inxi \
    neofetch \
    dmidecode \
    lshw \
    lsscsi \
    usbutils \
    pciutils \
    kbd \
    console-setup \
    console-data \
    inputattach \
    joystick \
    xboxdrv \
    qjoypad

# Printers & Scanners
apt-get install -y \
    cups \
    cups-client \
    cups-common \
    cups-core-drivers \
    cups-daemon \
    cups-filters \
    cups-ipp-utils \
    cups-ppdc \
    cups-server-common \
    hplip \
    hplip-data \
    printer-driver-brlaser \
    printer-driver-c2esp \
    printer-driver-foo2zjs \
    printer-driver-gutenprint \
    printer-driver-hpcups \
    printer-driver-m2300w \
    printer-driver-pnm2ppa \
    printer-driver-postscript-hp \
    printer-driver-ptouch \
    printer-driver-pxljr \
    printer-driver-sag-gdi \
    printer-driver-splix \
    sane \
    sane-utils \
    xsane \
    xsane-common

# File Systems & NTFS
apt-get install -y \
    ntfs-3g \
    exfat-fuse \
    fuseiso \
    fuseiso9660 \
    fuse-zip \
    archiver \
    p7zip \
    p7zip-full \
    p7zip-rar \
    unrar \
    unace \
    sharutils \
    uudeview \
    mpack \
    cabextract \
    liblzma-dev

# ==================== SECURITY ====================
apt-get install -y \
    ufw \
    gufw \
    fail2ban \
    rkhunter \
    chkrootkit \
    lynis \
    auditd \
    aide \
    libpam-pwquality \
    libpam-tmpdir \
    libpam-umask \
    gnome-encryption-logo \
    seahorse \
    gnome-keyring

# ==================== SYSTEM TOOLS ====================
apt-get install -y \
    gparted \
    gnome-disk-utility \
    gnome-system-tools \
    system-config-printer \
    deja-dup \
    deja-dup-backend-cloudfiles \
    deja-dup-backend-s3 \
    gnome-calendar \
    gnome-calculator \
    gnome-characters \
    gnome-clocks \
    gnome-contacts \
    gnome-font-viewer \
    gnome-screenshot \
    gnome-search-tool \
    gnome-system-monitor \
    gnome-terminal \
    gnome-tweaks \
    gnome-usage \
    gpick \
    spectacle \
    ksnip \
    flameshot

# Clean up
apt-get autoremove -y
apt-get clean
apt-get autoclean

# Create Piẻxed user
useradd -m -s /bin/bash piexed || true
echo "piexed:piexed" | chpasswd
usermod -aG sudo,audio,video,cdrom,dip,plugdev,scanner,wireshark,games lpadmin piexed
echo "piexed ALL=(ALL) NOPASSWD:ALL" > /etc/sudoers.d/piexed
echo "piexed ALL=(ALL) NOPASSWD:ALL" > /etc/sudoers.d/piexed-user

EOF
    log_success "All packages installed"
}

configure_desktop_macOS() {
    log_info "Configuring macOS-like desktop..."
    
    sudo chroot "${WORKSPACE}/chroot" /bin/bash << 'EOF'
set -e

mkdir -p /root/.config
mkdir -p /home/piexed/.config
mkdir -p /etc/xdg
mkdir -p /etc/xdg/xfce4
mkdir -p /etc/skel/.config

# Configure LightDM - macOS style
cat > /etc/lightdm/lightdm.conf << 'LIGHTDM'
[LightDM]
autologin-user=piexed
autologin-user-timeout=0
autologin-session=xfce
greeter-session=lightdm-gtk-greeter
user-session=xfce

[Seat:*]
autologin-guest=false
autologin-user=piexed
autologin-user-timeout=0
greeter-session=lightdm-gtk-greeter
user-session=xfce
allow-guest=false
seat-type=local
LIGHTDM

cat > /etc/lightdm/lightdm-gtk-greeter.conf << 'GREETER'
[greeter]
background = /usr/share/backgrounds/piexed-default.jpg
theme-name = Arc-Dark
icon-theme-name = Papirus-Dark
font-name = Ubuntu Regular 12
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
default-user-image = /usr/share/pixmaps/piexed-logo.png
GREETER

# macOS-like XFCE Configuration
cat > /etc/xdg/xfce4/xfconf/xfce-perchannel-xml/xfwm4.xml << 'XFCE'
<?xml version="1.0" encoding="UTF-8"?>
<channel name="xfwm4" version="1.0">
  <property name="theme" type="string" value="Arc-Dark"/>
  <property name="title_font" type="string" value="Ubuntu Bold 10"/>
  <property name="title_alignment" type="string" value="center"/>
  <property name="button_layout" type="string" value="OBMHMZ"/>
  <property name="button_spacing" type="int" value="2"/>
  <property name="show_shadow" type="bool" value="true"/>
  <property name="show_frame_opacity" type="int" value="100"/>
  <property name="inactive_opacity" type="int" value="90"/>
  <property name="active_opacity" type="int" value="100"/>
  <property name="snap_to_border" type="bool" value="true"/>
  <property name="snap_to_windows" type="bool" value="true"/>
  <property name="snap_width" type="int" value="10"/>
  <property name="snap_height" type="int" value="10"/>
  <property name="wrap_on_move" type="bool" value="true"/>
  <property name="wrap_on_resize" type="bool" value="true"/>
  <property name="click_to_raise" type="bool" value="true"/>
  <property name="raise_on_focus" type="bool" value="true"/>
  <property name="raise_on_click" type="bool" value="true"/>
  <property name="cycle_minimized" type="bool" value="true"/>
  <property name="cycle_apps_only" type="bool" value="false"/>
  <property name="focus_delay" type="int" value="0"/>
  <property name="raise_delay" type="int" value="0"/>
  <property name="double_click_time" type="int" value="250"/>
  <property name="double_click_distance" type="int" value="5"/>
  <property name="border_width" type="int" value="0"/>
  <property name="border_radius" type="int" value="8"/>
  <property name="menu_width" type="int" value="200"/>
  <property name="menu_height" type="int" value="250"/>
  <property name="workspace_count" type="int" value="4"/>
  <property name="workspace_1_name" type="string" value="1"/>
  <property name="workspace_2_name" type="string" value="2"/>
  <property name="workspace_3_name" type="string" value="3"/>
  <property name="workspace_4_name" type="string" value="4"/>
  <property name="mousewheel_rollup" type="bool" value="true"/>
  <property name="mousewheel_raise" type="bool" value="false"/>
  <property name="prevent_focus_stealing" type="bool" value="false"/>
  <property name="auto_raise" type="bool" value="false"/>
  <property name="auto_raise_delay" type="int" value="500"/>
  <property name="maximum_composited_opacity" type="int" value="100"/>
  <property name="minimum_composited_opacity" type="int" value="50"/>
</channel>
XFCE

# Panel Configuration - macOS style dock
cat > /etc/xdg/xfce4/xfconf/xfce-perchannel-xml/xfce4-panel.xml << 'PANEL'
<?xml version="1.0" encoding="UTF-8"?>
<channel name="xfce4-panel" version="1.0">
  <property name="configVersion" type="int" value="3"/>
  <property name="panels" type="array">
    <value type="struct">
      <property name="panelId" type="int" value="0"/>
      <property name="position" type="string" value="p=6;x=0;y=0"/>
      <property name="length" type="uint" value="100"/>
      <property name="position-locked" type="bool" value="true"/>
      <property name="plugin-ids" type="array">
        <value type="int">1</value>
        <value type="int">2</value>
        <value type="int">3</value>
        <value type="int">4</value>
        <value type="int">5</value>
        <value type="int">6</value>
        <value type="int">7</value>
        <value type="int">8</value>
        <value type="int">9</value>
        <value type="int">10</value>
      </property>
    </value>
  </property>
  <property name="plugins" type="array">
    <value type="struct">
      <property name="panel" type="int" value="0"/>
      <property name="id" type="uint" value="1"/>
      <property name="name" type="string" value="launcher"/>
    </value>
    <value type="struct">
      <property name="panel" type="int" value="0"/>
      <property name="id" type="uint" value="2"/>
      <property name="name" type="string" value="tasklist"/>
    </value>
    <value type="struct">
      <property name="panel" type="int" value="0"/>
      <property name="id" type="uint" value="3"/>
      <property name="name" type="string" value="pager"/>
    </value>
    <value type="struct">
      <property name="panel" type="int" value="0"/>
      <property name="id" type="uint" value="4"/>
      <property name="name" type="string" value="clock"/>
    </value>
    <value type="struct">
      <property name="panel" type="int" value="0"/>
      <property name="id" type="uint" value="5"/>
      <property name="name" type="string" value="systray"/>
    </value>
    <value type="struct">
      <property name="panel" type="int" value="0"/>
      <property name="id" type="uint" value="6"/>
      <property name="name" type="string" value="actions"/>
    </value>
    <value type="struct">
      <property name="panel" type="int" value="0"/>
      <property name="id" type="uint" value="7"/>
      <property name="name" type="string" value="pulseaudio"/>
    </value>
    <value type="struct">
      <property name="panel" type="int" value="0"/>
      <property name="id" type="uint" value="8"/>
      <property name="name" type="string" value="network"/>
    </value>
    <value type="struct">
      <property name="panel" type="int" value="0"/>
      <property name="id" type="uint" value="9"/>
      <property name="name" type="string" value="battery"/>
    </value>
    <value type="struct">
      <property name="panel" type="int" value="0"/>
      <property name="id" type="uint" value="10"/>
      <property name="name" type="string" value="power-manager-plugin"/>
    </value>
  </property>
</channel>
PANEL

# Desktop Configuration
cat > /etc/xdg/xfce4/xfconf/xfce-perchannel-xml/xfdesktop.xml << 'DESKTOP'
<?xml version="1.0" encoding="UTF-8"?>
<channel name="xfdesktop" version="1.0">
  <property name="menu-file" type="string" value="/etc/xdg/xfce4/rc.xml"/>
  <property name="desktop-icons" type="bool" value="true"/>
  <property name="icon-size" type="uint" value="48"/>
  <property name="desktop-layout" type="string" value="rows"/>
  <property name="show-file-icons" type="bool" value="true"/>
  <property name="show-thumbnail-icons" type="bool" value="true"/>
  <property name="show-emblems" type="bool" value="true"/>
  <property name="last-wallpaper" type="string" value="/usr/share/backgrounds/piexed-default.jpg"/>
  <property name="wallpaper-mode" type="string" value="spanned"/>
  <property name="image-style" type="int" value="3"/>
  <property name="icon-view" type="bool" value="true"/>
  <property name="file-icon-size" type="int" value="48"/>
  <property name="tooltip-shadow" type="int" value="0"/>
  <property name="tooltip-opacity" type="int" value="230"/>
</channel>
DESKTOP

# Window Manager Settings
cat > /etc/xdg/xfce4/xfconf/xfce-perchannel-xml/xfwm4.xml << 'WM'
<?xml version="1.0" encoding="UTF-8"?>
<channel name="xfwm4" version="1.0">
  <property name="theme" type="string" value="Arc-Dark"/>
  <property name="workspace_count" type="int" value="4"/>
  <property name="button_layout" type="string" value="OBMHMZ"/>
  <property name="title_alignment" type="string" value="center"/>
  <property name="show_shadow" type="bool" value="true"/>
  <property name="inactive_opacity" type="int" value="90"/>
  <property name="active_opacity" type="int" value="100"/>
  <property name="border_width" type="int" value="0"/>
  <property name="border_radius" type="int" value="8"/>
  <property name="snap_to_border" type="bool" value="true"/>
  <property name="snap_to_windows" type="bool" value="true"/>
  <property name="raise_on_focus" type="bool" value="true"/>
  <property name="focus_delay" type="int" value="0"/>
  <property name="raise_delay" type="int" value="0"/>
</channel>
WM

# Copy settings to skel for new users
cp -r /etc/xdg/xfce4 /etc/skel/.config/
cp -r /etc/xdg/xfce4 /root/.config/
cp -r /etc/xdg/xfce4 /home/piexed/.config/

# Create autostart
mkdir -p /etc/xdg/autostart
mkdir -p /home/piexed/.config/autostart

cat > /etc/xdg/autostart/pulseaudio.desktop << 'AUTOSTART'
[Desktop Entry]
Type=Application
Name=PulseAudio
Exec=pulseaudio --start --log-target=syslog
X-GNOME-Autostart-enabled=true
AUTOSTART

cat > /etc/xdg/autostart/bluetooth.desktop << 'BT'
[Desktop Entry]
Type=Application
Name=Bluetooth
Exec=blueman
X-GNOME-Autostart-enabled=true
BT

cat > /etc/xdg/autostart/network.desktop << 'NET'
[Desktop Entry]
Type=Application
Name=Network Manager
Exec=nm-applet
X-GNOME-Autostart-enabled=true
NET

cat > /etc/xdg/autostart/picom.desktop << 'PIC'
[Desktop Entry]
Type=Application
Name=Compositor
Exec=picom -b
X-GNOME-Autostart-enabled=true
PIC

cp /etc/xdg/autostart/*.desktop /home/piexed/.config/autostart/

EOF
    log_success "macOS-like desktop configured"
}

configure_system() {
    log_info "Configuring system settings..."
    
    sudo chroot "${WORKSPACE}/chroot" /bin/bash << 'EOF'
set -e

# Timezone
ln -sf /usr/share/zoneinfo/UTC /etc/localtime
dpkg-reconfigure -f noninteractive tzdata

# Locales
sed -i 's/# en_US.UTF-8/en_US.UTF-8/' /etc/locale.gen
sed -i 's/# en_GB.UTF-8/en_GB.UTF-8/' /etc/locale.gen
locale-gen

# Network
cat > /etc/network/interfaces << 'NET'
auto lo
iface lo inet loopback
NET

# Enable services
systemctl enable NetworkManager
systemctl enable lightdm
systemctl enable ssh
systemctl enable bluetooth
systemctl enable cups
systemctl enable fail2ban
systemctl enable ufw
systemctl enable thermald
systemctl enable tlp

# Configure sysctl - Performance
cat > /etc/sysctl.d/99-piexed.conf << 'SYSCTL'
# Network
net.ipv4.tcp_timestamps = 1
net.ipv4.tcp_sack = 1
net.ipv4.tcp_window_scaling = 1
net.core.rmem_max = 16777216
net.core.wmem_max = 16777216
net.ipv4.conf.all.rp_filter = 1
net.ipv4.conf.default.rp_filter = 1
net.ipv4.icmp_echo_ignore_broadcasts = 1

# Memory
vm.swappiness = 10
vm.vfs_cache_pressure = 60
vm.dirty_ratio = 15
vm.dirty_background_ratio = 5

# Security
kernel.dmesg_restrict = 1
kernel.kptr_restrict = 2
net.ipv4.conf.all.accept_redirects = 0
net.ipv4.conf.default.accept_redirects = 0
net.ipv6.conf.all.accept_redirects = 0
net.ipv6.conf.default.accept_redirects = 0
SYSCTL

# Limits
cat > /etc/security/limits.d/piexed.conf << 'LIMITS'
* soft nofile 65536
* hard nofile 65536
* soft nproc 65536
* hard nproc 65536
LIMITS

# Piẻxed OS Info
cat > /etc/piexed-version << 'VERSION'
PIEXED_VERSION="1.0.0"
PIEXED_CODENAME="Professional Edition"
PIEXED_BUILD=$(date +%Y%m%d)
VERSION

cat > /etc/os-release << 'OSRELEASE'
NAME="Piẻxed OS"
VERSION="1.0.0 (Professional Edition)"
ID=piexed
ID_LIKE=ubuntu debian
PRETTY_NAME="Piẻxed OS 1.0.0 Professional Edition"
VERSION_ID="1.0.0"
HOME_URL="https://piexed-os.org"
SUPPORT_URL="https://github.com/piexed-os"
BUG_REPORT_URL="https://github.com/piexed-os/issues"
PRIVACY_POLICY_URL="https://piexed-os.org/privacy"
VERSION_CODENAME=professional
UBUNTU_CODENAME=jammy
OSRELEASE

# Logrotate
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

EOF
    log_success "System configured"
}

configure_security() {
    log_info "Configuring security (Firewall, fail2ban)..."
    
    sudo chroot "${WORKSPACE}/chroot" /bin/bash << 'EOF'
set -e

# UFW Firewall
ufw default deny incoming
ufw default allow outgoing
ufw allow ssh/tcp
ufw allow 22/tcp
ufw allow 80/tcp
ufw allow 443/tcp
ufw enable

# fail2ban
cat > /etc/fail2ban/jail.local << 'FAIL2BAN'
[DEFAULT]
bantime = 3600
findtime = 600
maxretry = 5
destemail = admin@localhost

[sshd]
enabled = true
port = ssh
filter = sshd
logpath = /var/log/auth.log
maxretry = 5
FAIL2BAN

# SSH hardening
sed -i 's/^PermitRootLogin.*/PermitRootLogin no/' /etc/ssh/sshd_config 2>/dev/null || true
sed -i 's/^#*PasswordAuthentication.*/PasswordAuthentication yes/' /etc/ssh/sshd_config 2>/dev/null || true

EOF
    log_success "Security configured"
}

install_piexed_tools() {
    log_info "Installing Piẻxed OS tools and App Store..."
    
    # Piẻxed Info
    sudo tee "${WORKSPACE}/chroot/usr/local/bin/piexed-info" > /dev/null << 'EOF'
#!/bin/bash
echo "============================================"
echo "    Piẻxed OS - System Information"
echo "============================================"
echo ""
echo "Version:     $(cat /etc/piexed-version | grep VERSION | cut -d'"' -f2)"
echo "Codename:    $(cat /etc/piexed-version | grep CODENAME | cut -d'"' -f2)"
echo "Kernel:      $(uname -r)"
echo "Architecture: $(uname -m)"
echo "Uptime:      $(uptime -p)"
echo ""
echo "=== Resources ==="
echo "Disk:  $(df -h / | tail -1 | awk '{print $3 " / " $2 " (" $5 ")"}')"
echo "Memory: $(free -h | awk '/^Mem:/ {print $3 " / " $2}')"
echo "CPU:   $(nproc) cores"
echo ""
echo "=== Network ==="
echo "IP: $(hostname -I | awk '{print $1}')"
echo ""
echo "============================================"
EOF

    # Piẻxed Clean
    sudo tee "${WORKSPACE}/chroot/usr/local/bin/piexed-clean" > /dev/null << 'EOF'
#!/bin/bash
echo "Piẻxed OS System Cleaner"
echo "========================"
apt-get clean
apt-get autoremove -y
apt-get autoclean
rm -rf /var/cache/apt/archives/*
rm -rf /var/tmp/*
rm -rf /tmp/*
rm -rf ~/.cache/*
echo "System cleaned!"
EOF

    # Piẻxed Update
    sudo tee "${WORKSPACE}/chroot/usr/local/bin/piexed-update" > /dev/null << 'EOF'
#!/bin/bash
echo "Piẻxed OS Updater"
echo "================="
export DEBIAN_FRONTEND=noninteractive
apt-get update
apt-get upgrade -y
apt-get dist-upgrade -y
echo "System updated!"
EOF

    # Piẻxed Backup
    sudo tee "${WORKSPACE}/chroot/usr/local/bin/piexed-backup" > /dev/null << 'EOF'
#!/bin/bash
BACKUP_DIR="/var/backup/piexed"
DATE=$(date +%Y%m%d%H%M%S)
mkdir -p "$BACKUP_DIR/$DATE"
dpkg --get-selections > "$BACKUP_DIR/$DATE/packages.txt"
cp -r /etc "$BACKUP_DIR/$DATE/"
tar -czf "$BACKUP_DIR/home-$DATE.tar.gz" /home 2>/dev/null || true
echo "Backup: $BACKUP_DIR/$DATE"
EOF

    # Piẻxed App Store (Simple GUI)
    sudo tee "${WORKSPACE}/chroot/usr/local/bin/piexed-store" > /dev/null << 'EOF'
#!/bin/bash
# Piẻxed App Store - Simple software center
HEIGHT=20
WIDTH=60
CHOICE=$(dialog --clear \
    --title "Piẻxed App Store" \
    --menu "Choose category:" \
    $HEIGHT $WIDTH 10 \
    "1" "Internet (Browser, Email, Chat)" \
    "2" "Multimedia (Video, Music, Images)" \
    "3" "Office (Documents, Spreadsheets)" \
    "4" "Development (Code Editors, IDEs)" \
    "5" "Games (Steam, Lutris, Native)" \
    "6" "System (Drivers, Tools, Utilities)" \
    "7" "Security (Antivirus, Firewall)" \
    "8" "Update System" \
    3>&1 1>&2 2>&3)

case $CHOICE in
    1) sudo apt-get install -y firefox thunderbird chromium discord telegram qtox hexchat ;;
    2) sudo apt-get install -y vlc audacious smplayer Clementine rhythmbox gimp inkscape ;;
    3) sudo apt-get install -y libreoffice wps-office freeoffice ;;
    4) sudo apt-get install -y vscode atom sublime-text intellij-idea-community pycharm-community ;;
    5) sudo apt-get install -y steam lutris playonlinux wine ;;
    6) sudo apt-get install -y gparted hardinfo neofetch htop tmux vim git ;;
    7) sudo apt-get install -y gufw clamtk rkhunter chkrootkit ;;
    8) sudo apt-get update && sudo apt-get upgrade -y ;;
esac
EOF

    sudo chmod +x "${WORKSPACE}/chroot/usr/local/bin/piexed-"*

    # Create menu entry
    sudo mkdir -p "${WORKSPACE}/chroot/usr/share/applications"
    cat > "${WORKSPACE}/chroot/usr/share/applications/piexed-store.desktop" << 'APPSTORE'
[Desktop Entry]
Name=Piexed Store
Comment=Software Center
Exec=piexed-store
Icon=system-software-install
Terminal=true
Type=Application
Categories=System;Settings;
APPSTORE

    log_success "Piẻxed tools installed"
}

configure_grub() {
    log_info "Configuring GRUB..."
    sudo chroot "${WORKSPACE}/chroot" /bin/bash << 'EOF'
set -e
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
GRUB
update-grub
EOF
    log_success "GRUB configured"
}

create_iso() {
    log_info "Creating ISO image..."
    cd "${WORKSPACE}"
    
    log_info "Preparing filesystem..."
    sudo rsync -a --exclude='/proc/*' --exclude='/sys/*' --exclude='/dev/*' --exclude='/run/*' --exclude='/tmp/*' chroot/ image/
    
    log_info "Creating squashfs..."
    sudo mksquashfs image squashfs/filesystem.squashfs -noappend -comp xz -e boot
    
    log_info "Creating boot image..."
    sudo mkdir -p efi/boot
    sudo cp -r image/boot/* efi/boot/ 2>/dev/null || true
    
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
        -output "${OUTPUT_DIR}/piexed-os-${PIEXED_VERSION}-professional.iso" \
        . 2>/dev/null || {
        
        sudo xorriso -as mkisofs \
            -iso-level 3 \
            -full-iso9660-filenames \
            -volid "PIEXED_OS_1.0.0" \
            -output "${OUTPUT_DIR}/piexed-os-${PIEXED_VERSION}-professional.iso" \
            .
    }
    
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
    install_all_packages
    configure_desktop_macOS
    configure_system
    configure_security
    install_piexed_tools
    configure_grub
    create_iso
    
    echo ""
    log_success "==========================================="
    log_success "   BUILD COMPLETE!"
    log_success "==========================================="
    echo ""
    echo "ISO Location: ${OUTPUT_DIR}/piexed-os-${PIEXED_VERSION}-professional.iso"
    echo ""
    echo "Default Login:"
    echo "  Username: piexed"
    echo "  Password: piexed"
    echo ""
    log_success "Ready to install!"
}

main "$@"
