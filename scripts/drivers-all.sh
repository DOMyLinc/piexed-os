#!/bin/bash
#
# Piẻxed OS - Complete Driver Installation
# All drivers including microphone
#

set -e

echo "=========================================="
echo "  Piẻxed OS - Driver Installer"
echo "=========================================="

# Install ALL drivers
echo "[1] Installing All Drivers..."

apt-get update

# NETWORK DRIVERS
echo "[2] Network drivers..."
apt-get install -y \
    network-manager \
    network-manager-gnome \
    iw \
    wpasupplicant \
    wireless-tools \
    crda \
    rfkill \
    firmware-iwlwifi \
    firmware-atheros \
    firmware-bnx2 \
    firmware-brcm80211 \
    firmware-intel-sound \
    firmware-ipw2x00 \
    firmware-libertas \
    firmware-netxen \
    firmware-realtek \
    firmware-ti-connectivity \
    firmware-zd1211 \
    linux-firmware \
   Broadcom-sta-dkms

# BLUETOOTH DRIVERS
echo "[3] Bluetooth drivers..."
apt-get install -y \
    bluetooth \
    bluez \
    bluez-cups \
    bluez-obexd \
    bluez-tools \
    blueman \
    pulseaudio-module-bluetooth

# GRAPHICS DRIVERS
echo "[4] Graphics drivers..."
apt-get install -y \
    xserver-xorg-video-all \
    xserver-xorg-video-amdgpu \
    xserver-xorg-video-ati \
    xserver-xorg-video-intel \
    xserver-xorg-video-nouveau \
    xserver-xorg-video-radeon \
    xserver-xorg-video-vesa \
    xserver-xorg-video-vmware \
    xserver-xorg-video-qxl \
    mesa-utils \
    mesa-vulkan-drivers \
    mesa-vdpau-drivers \
    vulkan-tools \
    vulkan-validationlayers \
    libva-intel-driver \
    libva-utils \
    vdpauinfo \
    clinfo \
    glxinfo

# AUDIO DRIVERS (INCLUDING MICROPHONE)
echo "[5] Audio and Microphone drivers..."
apt-get install -y \
    alsa-utils \
    alsa-base \
    pulseaudio \
    pulseaudio-utils \
    pulseaudio-module-bluetooth \
    pulseaudio-module-gsettings \
    pavucontrol \
    pasystray \
    libasound2 \
    libasound2-plugins \
    libasound2-dev \
    alsa-firmware \
    firmware-intel-sound \
    sof-firmware

# WEBCAM DRIVERS
echo "[6] Webcam drivers..."
apt-get install -y \
    cheese \
    guvcview \
    v4l-utils \
    v4l2ucp \
    libv4l-dev \
    libwebp-dev

# PRINTER DRIVERS
echo "[7] Printer drivers..."
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
    printer-driver-splix

# SCANNER DRIVERS
echo "[8] Scanner drivers..."
apt-get install -y \
    sane \
    sane-utils \
    xsane \
    xsane-common \
    libsane \
    libsane-common

# GAMING CONTROLLER DRIVERS
echo "[9] Gaming controller drivers..."
apt-get install -y \
    xpad \
    xboxdrv \
    ds4drv \
    qjoypad \
    xhost \
    joystick

# VIRTUALIZATION DRIVERS
echo "[10] Virtualization drivers..."
apt-get install -y \
    virtualbox-guest-utils \
    virtualbox-guest-x11 \
    open-vm-tools \
    open-vm-tools-desktop \
    xorg-vmware-video
    
# TOUCHPAD DRIVERS
echo "[11] Touchpad drivers..."
apt-get install -y \
    xserver-xorg-input-synaptics \
    xserver-xorg-input-libinput \
    xserver-xorg-input-elographics \
    xserver-xorg-input-evdev \
    xserver-xorg-input-wacom

# USB DRIVERS
echo "[12] USB drivers..."
apt-get install -y \
    usbutils \
    libusb-1.0-0 \
    libusb-1.0-dev \
    usb-modeswitch \
    usb-modeswitch-data

# FIRMWARE
echo "[13] Installing all firmware..."
apt-get install -y \
    linux-firmware \
    linux-firmware-extra

# Create driver diagnostic tool
cat > /usr/local/bin/piexed-drivers << 'DRIVERS'
#!/bin/bash
echo "=== Piẻxed OS Driver Status ==="
echo ""

echo "=== Graphics ==="
lspci | grep -i vga
glxinfo | grep "OpenGL version"
echo ""

echo "=== Audio ==="
aplay -l
echo "Microphones:"
pactl list short sources
echo ""

echo "=== Network ==="
ip link show
iw dev
echo ""

echo "=== Bluetooth ==="
rfkill list bluetooth
echo ""

echo "=== USB ==="
lsusb
echo ""

echo "=== Drivers Loaded ==="
lsmod | head -20
DRIVERS
chmod +x /usr/local/bin/piexed-drivers

# Create microphone test tool
cat > /usr/local/bin/piexed-mic << 'MIC'
#!/bin/bash
echo "=== Microphone Test ==="
echo "Available input devices:"
pactl list short sources

echo ""
echo "Testing microphone..."
arecord -d 5 /tmp/test-mic.wav 2>/dev/null
if [ -f /tmp/test-mic.wav ]; then
    echo "Recording saved! Playing back..."
    aplay /tmp/test-mic.wav
    rm /tmp/test-mic.wav
else
    echo "No microphone detected or permission denied"
    echo "Try: sudo usermod -aG audio $USER"
fi
MIC
chmod +x /usr/local/bin/piexed-mic

# Enable audio services
systemctl enable pulseaudio
systemctl enable bluetooth
systemctl enable NetworkManager

echo ""
echo "=========================================="
echo "  DRIVERS INSTALLED!"
echo "=========================================="
echo ""
echo "Diagnostics:"
echo "  piexed-drivers    - Check all drivers"
echo "  piexed-mic        - Test microphone"