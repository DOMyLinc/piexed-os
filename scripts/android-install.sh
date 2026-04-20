#!/bin/bash
#
# Piẻxed OS Android Compatibility Scripts
# Version: 1.0.0
# Description: Scripts for running Piẻxed OS on Android devices via Termux/UserLAnd
#

set -e

PIEXED_ANDROID_VERSION="1.0.0"

echo "╔══════════════════════════════════════════════════════════╗"
echo "║        PIEXED OS ANDROID COMPATIBILITY SUITE             ║"
echo "║                 Version ${PIEXED_ANDROID_VERSION}                             ║"
echo "╚══════════════════════════════════════════════════════════╝"
echo ""

# Check if running on Android
check_android() {
    if [ -d "/data/data/com.termux" ] || [ -d "/data/data/com.termux.x11" ]; then
        return 0
    elif grep -q "android" /proc/version 2>/dev/null; then
        return 0
    else
        return 1
    fi
}

# Check if proot-distro is available
check_proot() {
    if command -v proot-distro &> /dev/null; then
        echo "proot-distro found"
        return 0
    else
        echo "proot-distro not found"
        return 1
    fi
}

# Main menu
main_menu() {
    clear
    echo "=============================================="
    echo "  Piẻxed OS Android Installer"
    echo "=============================================="
    echo ""
    echo "1. Install Piẻxed OS (Ubuntu-based)"
    echo "2. Update Piẻxed OS"
    echo "3. Launch Piẻxed OS"
    echo "4. Remove Piẻxed OS"
    echo "5. System Info"
    echo "6. Exit"
    echo ""
    read -p "Select option [1-6]: " choice

    case $choice in
        1) install_piexed ;;
        2) update_piexed ;;
        3) launch_piexed ;;
        4) remove_piexed ;;
        5) system_info ;;
        6) exit 0 ;;
        *) echo "Invalid option"; sleep 2; main_menu ;;
    esac
}

# Install Piẻxed OS
install_piexed() {
    clear
    echo "=============================================="
    echo "  Installing Piẻxed OS"
    echo "=============================================="
    echo ""

    # Check Android
    if ! check_android; then
        echo "Warning: This script is designed for Android devices"
        read -p "Continue anyway? (y/n): " confirm
        if [ "$confirm" != "y" ]; then
            main_menu
        fi
    fi

    # Check dependencies
    echo "Checking dependencies..."

    if ! command -v wget &> /dev/null; then
        echo "Installing wget..."
        pkg update && pkg install wget -y
    fi

    if ! command -v curl &> /dev/null; then
        echo "Installing curl..."
        pkg update && pkg install curl -y
    fi

    # Install proot-distro if not present
    if ! check_proot; then
        echo "Installing proot-distro..."
        pkg update && pkg install proot-distro -y
    fi

    # Create Piẻxed OS directory
    mkdir -p ~/piexed-os
    cd ~/piexed-os

    # Download Piẻxed OS configuration
    echo "Downloading Piẻxed OS..."

    # Create Ubuntu distribution configuration
    cat > ~/.config/proot-distro/ubuntu-piexed.json << 'EOF'
{
    "name": "ubuntu-piexed",
    "distribution": "Ubuntu",
    "release": "jammy",
    "maintenance": "Piẻxed OS Team",
    "description": "Piẻxed OS based on Ubuntu 22.04 LTS - Lightweight Linux for Android",
    "aliases": [
        "piexed",
        "piexed-os"
    ],
    "pre_script": "echo 'Piẻxed OS Ubuntu Environment' > /etc/piexed-release",
    "env": {
        "PIEXED_OS": "1",
        "TERM": "xterm-256color"
    },
    "hooks": {
        "bootstrap": [
            "echo 'nameserver 8.8.8.8' > /etc/resolv.conf"
        ]
    }
}
EOF

    # Install Ubuntu with proot-distro
    echo "Installing Ubuntu base system..."
    proot-distro install ubuntu-piexed

    # Configure Piẻxed OS inside Ubuntu
    configure_piexed_installation

    echo ""
    echo "Installation completed!"
    echo "Run 'piexed-launch' to start Piẻxed OS"
    echo ""
    read -p "Press Enter to continue"
    main_menu
}

# Configure Piẻxed OS after installation
configure_piexed_installation() {
    echo "Configuring Piẻxed OS..."

    # Create launch script
    cat > ~/piexed-launch.sh << 'EOF'
#!/bin/bash
# Piẻxed OS Launcher Script

echo "Starting Piẻxed OS..."

# Set display for Termux:X11
if [ -n "$DISPLAY" ]; then
    export DISPLAY=$DISPLAY
elif [ -f /data/data/com.termux/files/usr/tmp/.Xwayland-0 ]; then
    export DISPLAY=:0
fi

# Launch proot-distro
proot-distro login ubuntu-piexed --shared-tmp --fix-low-ports --no-colon
EOF

    chmod +x ~/piexed-launch.sh

    # Create desktop shortcut
    mkdir -p ~/.shortcuts
    cat > ~/.shortcuts/Piexed-OS << 'EOF'
#!/bin/bash
~/piexed-launch.sh
EOF

    chmod +x ~/.shortcuts/Piexed-OS
}

# Update Piẻxed OS
update_piexed() {
    clear
    echo "=============================================="
    echo "  Updating Piẻxed OS"
    echo "=============================================="
    echo ""

    echo "Updating Piẻxed OS packages..."
    proot-distro login ubuntu-piexed --shared-tmp --fix-low-ports --no-colon -- bash -c "
        apt update && apt upgrade -y
    "

    echo ""
    echo "Update completed!"
    read -p "Press Enter to continue"
    main_menu
}

# Launch Piẻxed OS
launch_piexed() {
    clear
    echo "=============================================="
    echo "  Launching Piẻxed OS"
    echo "=============================================="
    echo ""

    echo "Starting Piẻxed OS environment..."
    echo ""

    # Check if installed
    if [ ! -f ~/.config/proot-distro/ubuntu-piexed.json ]; then
        echo "Piẻxed OS is not installed."
        read -p "Would you like to install it now? (y/n): " confirm
        if [ "$confirm" = "y" ]; then
            install_piexed
        else
            main_menu
        fi
    fi

    # Launch
    if [ -n "$DISPLAY" ]; then
        # GUI mode
        proot-distro login ubuntu-piexed --shared-tmp --fix-low-ports --no-colon
    else
        # CLI mode
        proot-distro login ubuntu-piexed --shared-tmp --fix-low-ports --no-colon
    fi
}

# Remove Piẻxed OS
remove_piexed() {
    clear
    echo "=============================================="
    echo "  Remove Piẻxed OS"
    echo "=============================================="
    echo ""

    read -p "Are you sure you want to remove Piẻxed OS? (y/n): " confirm

    if [ "$confirm" = "y" ]; then
        echo "Removing Piẻxed OS..."
        proot-distro remove ubuntu-piexed
        rm -rf ~/piexed-os
        rm -f ~/piexed-launch.sh
        rm -f ~/.shortcuts/Piexed-OS
        echo "Piẻxed OS removed successfully!"
    else
        echo "Removal cancelled."
    fi

    read -p "Press Enter to continue"
    main_menu
}

# System info
system_info() {
    clear
    echo "=============================================="
    echo "  System Information"
    echo "=============================================="
    echo ""

    echo "Android Version:"
    getprop ro.build.version.release
    echo ""

    echo "Device:"
    getprop ro.product.model
    echo ""

    echo "Architecture:"
    uname -m
    echo ""

    echo "Kernel:"
    uname -r
    echo ""

    echo "Available Storage:"
    df -h /data
    echo ""

    echo "Available Memory:"
    free -h
    echo ""

    read -p "Press Enter to continue"
    main_menu
}

# Quick Start (non-interactive)
quick_start() {
    if ! check_proot; then
        echo "Installing proot-distro..."
        pkg update && pkg install proot-distro -y
    fi

    # Create basic config
    mkdir -p ~/.config/proot-distro

    cat > ~/.config/proot-distro/ubuntu-piexed.json << 'EOF'
{
    "name": "ubuntu-piexed",
    "distribution": "Ubuntu",
    "release": "jammy",
    "maintenance": "Piẻxed OS Team",
    "description": "Piẻxed OS based on Ubuntu 22.04 LTS"
}
EOF

    proot-distro install ubuntu-piexed

    echo ""
    echo "Piẻxed OS installed!"
    echo "Launch with: proot-distro login ubuntu-piexed"
}

# Termux:X11 launcher
create_x11_launcher() {
    mkdir -p ~/.shortcuts

    cat > ~/.shortcuts/Piexed-OS-X11 << 'EOF'
#!/bin/bash
export DISPLAY=:0
export XDG_RUNTIME_DIR=/data/data/com.termux/files/usr/tmp
termux-x11 :0 &
sleep 2
proot-distro login ubuntu-piexed --shared-tmp --fix-low-ports --no-colon -- env DISPLAY=:0 XDG_RUNTIME_DIR=/data/data/com.termux/files/usr/tmp dbus-launch --exit-with-session startxfce4 &
EOF

    chmod +x ~/.shortcuts/Piexed-OS-X11
}

# Performance optimization for Android
optimize_for_android() {
    echo "Optimizing Piẻxed OS for Android..."

    proot-distro login ubuntu-piexed --shared-tmp --fix-low-ports --no-colon -- bash -c "
        # Disable unnecessary services
        systemctl disable postgresql 2>/dev/null || true
        systemctl disable redis 2>/dev/null || true

        # Install lighter alternatives
        apt-get install -y --no-install-recommends \
            lightdm \
            xfce4 \
            xfce4-terminal \
            thunar \
            mousepad

        # Configure for low memory
        echo 'vm.swappiness=10' >> /etc/sysctl.conf
        echo 'vm.min_free_kbytes=8192' >> /etc/sysctl.conf

        # Disable animations
        sed -i 's/Enabled=true/Enabled=false/' /etc/xdg/xfce4/xfconf/xfce-perchannel-xml/xfwm4.xml 2>/dev/null || true

        # Create Piẻxed theme
        mkdir -p /usr/share/themes/Piexed
    "

    echo "Android optimization completed!"
}

# Show help
show_help() {
    echo "Piẻxed OS Android Installer"
    echo ""
    echo "Usage: piexed-android [options]"
    echo ""
    echo "Options:"
    echo "  install     - Install Piẻxed OS"
    echo "  update      - Update Piẻxed OS"
    echo "  launch      - Launch Piẻxed OS"
    echo "  remove      - Remove Piẻxed OS"
    echo "  info        - Show system information"
    echo "  help        - Show this help"
    echo ""
    echo "Examples:"
    echo "  piexed-android install   - Install Piẻxed OS"
    echo "  piexed-android launch    - Start Piẻxed OS"
    echo ""
}

# Main execution
if [ "$1" = "install" ]; then
    install_piexed
elif [ "$1" = "update" ]; then
    update_piexed
elif [ "$1" = "launch" ]; then
    launch_piexed
elif [ "$1" = "remove" ]; then
    remove_piexed
elif [ "$1" = "info" ]; then
    system_info
elif [ "$1" = "quick" ]; then
    quick_start
elif [ "$1" = "optimize" ]; then
    optimize_for_android
elif [ "$1" = "x11" ]; then
    create_x11_launcher
elif [ "$1" = "--help" ] || [ "$1" = "-h" ]; then
    show_help
else
    main_menu
fi