#!/bin/bash
#===============================================================================
# Piexed OS System Tools
# Version: 1.0.0
# A collection of system utilities for Piexed OS
#===============================================================================

set -euo pipefail

VERSION="1.0.0"
TITLE="Piexed OS System Tools"

# Colors
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
CYAN='\033[0;36m'
NC='\033[0m'

#===============================================================================
# FUNCTIONS
#===============================================================================

log_info() { echo -e "${BLUE}[INFO]${NC} $1"; }
log_success() { echo -e "${GREEN}[SUCCESS]${NC} $1"; }
log_error() { echo -e "${RED}[ERROR]${NC} $1"; }

print_banner() {
    echo -e "${CYAN}"
    cat << 'EOF'
     _____ _____   _____         _____           _
    |_   _| ____| |  ___|_   __|_   _|__   __| | ___
      | | |  _|   | |_  | | |  | |/ _ \ / _` |/ _ \
      | | | |___  |  _|  | |_| | |  __/| (_| | (_) |
      |_| |_____| |_|     \__,_|_|\___| \__,_|\___/

    System Tools
    ================================================
    Version: 1.0.0 - Strawberry Fields
    ================================================
EOF
    echo -e "${NC}"
}

#===============================================================================
# SYSTEM INFO
#===============================================================================

show_system_info() {
    clear
    echo -e "${CYAN}"
    echo "╔══════════════════════════════════════════════════════════╗"
    echo "║              SYSTEM INFORMATION                         ║"
    echo "╚══════════════════════════════════════════════════════════╝"
    echo -e "${NC}"
    echo ""

    echo "Operating System:"
    if [ -f /etc/piexed-release ]; then
        cat /etc/piexed-release
    else
        cat /etc/os-release | grep -E "^(NAME|VERSION)="
    fi
    echo ""

    echo "Kernel:"
    uname -a
    echo ""

    echo "Architecture:"
    uname -m
    echo ""

    echo "Hostname:"
    hostname
    echo ""

    echo "Uptime:"
    uptime -p 2>/dev/null || uptime
    echo ""

    echo "CPU:"
    lscpu | grep -E "^Model name:|^CPU\(s\):|^Thread|^Core" | sed 's/^/  /'
    echo ""

    echo "Memory:"
    free -h
    echo ""

    echo "Disk:"
    df -h /
    echo ""

    echo "Network:"
    ip -br link show 2>/dev/null || ifconfig -a | grep -E "^[^ ]"
    echo ""

    read -p "Press Enter to continue"
}

#===============================================================================
# SYSTEM MONITOR
#===============================================================================

show_system_monitor() {
    clear
    while true; do
        echo -e "${CYAN}"
        echo "╔══════════════════════════════════════════════════════════╗"
        echo "║              SYSTEM MONITOR                            ║"
        echo "╚══════════════════════════════════════════════════════════╝"
        echo -e "${NC}"
        echo ""

        # CPU
        echo "CPU Usage:"
        top -bn1 | grep "Cpu(s)" | awk '{print "  Used: " $2 " | Idle: " $5}'
        echo ""

        # Memory
        echo "Memory Usage:"
        free -h | awk 'NR==2{printf "  Used: %s / %s (%.0f%%)\n", $3, $2, ($3/$2)*100}'
        echo ""

        # Disk
        echo "Disk Usage:"
        df -h / | awk 'NR==2{printf "  Used: %s / %s (%s)\n", $3, $2, $5}'
        echo ""

        # Network
        echo "Network:"
        echo "  RX: $(cat /sys/class/net/*/statistics/rx_bytes 2>/dev/null | paste -sd+ | bc | numfmt --to=iec-i 2>/dev/null || echo 'N/A')"
        echo "  TX: $(cat /sys/class/net/*/statistics/tx_bytes 2>/dev/null | paste -sd+ | bc | numfmt --to=iec-i 2>/dev/null || echo 'N/A')"
        echo ""

        # Top processes
        echo "Top Processes:"
        ps aux --sort=-%cpu | head -6 | tail -5 | awk '{printf "  %-8s CPU: %3s%% MEM: %3s%% %s\n", $2, $3, $4, $11}'
        echo ""

        echo "Press 'q' to quit, 'r' to refresh"
        read -t 2 -n 1 key
        if [ "$key" = "q" ]; then
            break
        elif [ "$key" = "r" ]; then
            clear
        else
            clear
        fi
    done
}

#===============================================================================
# DISK CLEANER
#===============================================================================

run_disk_cleaner() {
    clear
    echo -e "${CYAN}"
    echo "╔══════════════════════════════════════════════════════════╗"
    echo "║              DISK CLEANER                               ║"
    echo "╚══════════════════════════════════════════════════════════╝"
    echo -e "${NC}"
    echo ""

    echo "This will clean temporary files and caches."
    echo ""

    read -p "Continue? (yes/no): " confirm

    if [ "$confirm" != "yes" ]; then
        return
    fi

    echo ""
    log_info "Cleaning package cache..."
    apt-get clean
    apt-get autoremove -y

    echo ""
    log_info "Cleaning thumbnail cache..."
    rm -rf ~/.cache/thumbnails/*

    echo ""
    log_info "Cleaning trash..."
    rm -rf ~/.local/share/Trash/*

    echo ""
    log_info "Cleaning logs..."
    sudo journalctl --vacuum-time=7d 2>/dev/null || true

    echo ""
    log_info "Cleaning temp files..."
    rm -rf /tmp/* 2>/dev/null || true

    echo ""
    log_success "Disk cleaning completed!"
    read -p "Press Enter to continue"
}

#===============================================================================
# SYSTEM UPDATE
#===============================================================================

run_system_update() {
    clear
    echo -e "${CYAN}"
    echo "╔══════════════════════════════════════════════════════════╗"
    echo "║              SYSTEM UPDATE                              ║"
    echo "╚══════════════════════════════════════════════════════════╝"
    echo -e "${NC}"
    echo ""

    log_info "Updating package lists..."
    sudo apt-get update

    echo ""
    log_info "Upgrading packages..."
    sudo apt-get upgrade -y

    echo ""
    log_info "Cleaning up..."
    sudo apt-get autoremove -y
    sudo apt-get clean

    echo ""
    log_success "System update completed!"
    read -p "Press Enter to continue"
}

#===============================================================================
# FIREWALL
#===============================================================================

configure_firewall() {
    clear
    echo -e "${CYAN}"
    echo "╔══════════════════════════════════════════════════════════╗"
    echo "║              FIREWALL CONFIGURATION                     ║"
    echo "╚══════════════════════════════════════════════════════════╝"
    echo -e "${NC}"
    echo ""

    if ! command -v ufw &> /dev/null; then
        log_info "Installing UFW..."
        sudo apt-get install -y ufw
    fi

    echo "1) Enable Firewall"
    echo "2) Disable Firewall"
    echo "3) Show Status"
    echo "4) Allow SSH (port 22)"
    echo "5) Allow HTTP (port 80)"
    echo "6) Allow HTTPS (port 443)"
    echo "7) Back to main menu"
    echo ""
    read -p "Select option [1-7]: " choice

    case $choice in
        1)
            sudo ufw --force enable
            log_success "Firewall enabled"
            ;;
        2)
            sudo ufw disable
            log_success "Firewall disabled"
            ;;
        3)
            sudo ufw status verbose
            ;;
        4)
            sudo ufw allow 22/tcp comment 'SSH'
            log_success "SSH allowed"
            ;;
        5)
            sudo ufw allow 80/tcp comment 'HTTP'
            log_success "HTTP allowed"
            ;;
        6)
            sudo ufw allow 443/tcp comment 'HTTPS'
            log_success "HTTPS allowed"
            ;;
        7) return ;;
    esac

    read -p "Press Enter to continue"
}

#===============================================================================
# USER MANAGEMENT
#===============================================================================

manage_users() {
    clear
    echo -e "${CYAN}"
    echo "╔══════════════════════════════════════════════════════════╗"
    echo "║              USER MANAGEMENT                           ║"
    echo "╚══════════════════════════════════════════════════════════╝"
    echo -e "${NC}"
    echo ""

    echo "Current users:"
    echo ""
    who
    echo ""

    echo "1) Add new user"
    echo "2) Delete user"
    echo "3) Change user password"
    echo "4) List all users"
    echo "5) Back to main menu"
    echo ""
    read -p "Select option [1-5]: " choice

    case $choice in
        1)
            read -p "Enter username: " username
            sudo useradd -m -s /bin/bash -G sudo "$username"
            sudo passwd "$username"
            log_success "User $username created"
            ;;
        2)
            read -p "Enter username to delete: " username
            sudo userdel -r "$username"
            log_success "User $username deleted"
            ;;
        3)
            read -p "Enter username: " username
            sudo passwd "$username"
            log_success "Password changed for $username"
            ;;
        4)
            cut -d: -f1 /etc/passwd
            ;;
        5) return ;;
    esac

    read -p "Press Enter to continue"
}

#===============================================================================
# SERVICE MANAGER
#===============================================================================

manage_services() {
    clear
    echo -e "${CYAN}"
    echo "╔══════════════════════════════════════════════════════════╗"
    echo "║              SERVICE MANAGER                            ║"
    echo "╚══════════════════════════════════════════════════════════╝"
    echo -e "${NC}"
    echo ""

    echo "Running services:"
    echo ""
    systemctl list-units --type=service --state=running | grep -E "^\w" | head -20
    echo ""

    read -p "Enter service name to manage (or 'q' to quit): " service

    if [ "$service" = "q" ]; then
        return
    fi

    echo ""
    echo "1) Start"
    echo "2) Stop"
    echo "3) Restart"
    echo "4) Enable (start at boot)"
    echo "5) Disable (don't start at boot)"
    echo ""
    read -p "Select action [1-5]: " action

    case $action in
        1) sudo systemctl start "$service" ;;
        2) sudo systemctl stop "$service" ;;
        3) sudo systemctl restart "$service" ;;
        4) sudo systemctl enable "$service" ;;
        5) sudo systemctl disable "$service" ;;
    esac

    log_success "Service $service updated"
    read -p "Press Enter to continue"
}

#===============================================================================
# HARDWARE INFO
#===============================================================================

show_hardware_info() {
    clear
    echo -e "${CYAN}"
    echo "╔══════════════════════════════════════════════════════════╗"
    echo "║HARDWARE INFORMATION                       ║"
    echo "╚══════════════════════════════════════════════════════════╝"
    echo -e "${NC}"
    echo ""

    echo "=== CPU ==="
    lscpu
    echo ""

    echo "=== Memory ==="
    sudo dmidecode -t memory | grep -E "Size|Speed|Type:"
    echo ""

    echo "=== Storage ==="
    lsblk -o NAME,SIZE,TYPE,FSTYPE,MOUNTPOINT
    echo ""

    echo "=== Graphics ==="
    lspci | grep -i vga
    echo ""

    echo "=== Network ==="
    lspci | grep -i network
    echo ""

    echo "=== USB ==="
    lsusb
    echo ""

    read -p "Press Enter to continue"
}

#===============================================================================
# BACKUP TOOL
#===============================================================================

run_backup() {
    clear
    echo -e "${CYAN}"
    echo "╔══════════════════════════════════════════════════════════╗"
    echo "║              BACKUP TOOL                                 ║"
    echo "╚══════════════════════════════════════════════════════════╝"
    echo -e "${NC}"
    echo ""

    BACKUP_DIR="${HOME}/piexed-backups"
    mkdir -p "$BACKUP_DIR"

    echo "Backup destination: $BACKUP_DIR"
    echo ""

    echo "1) Backup home directory"
    echo "2) Backup system configuration"
    echo "3) Backup installed packages"
    echo "4) Full backup"
    echo "5) Back to main menu"
    echo ""
    read -p "Select option [1-5]: " choice

    case $choice in
        1)
            log_info "Backing up home directory..."
            DATE=$(date +%Y%m%d_%H%M%S)
            tar -czpf "$BACKUP_DIR/home_$DATE.tar.gz" "$HOME" --exclude='.cache' --exclude='.local/share/Trash' 2>/dev/null
            log_success "Home backup: $BACKUP_DIR/home_$DATE.tar.gz"
            ;;
        2)
            log_info "Backing up system configuration..."
            DATE=$(date +%Y%m%d_%H%M%S)
            sudo tar -czpf "$BACKUP_DIR/system_$DATE.tar.gz" /etc /root /usr/local 2>/dev/null
            log_success "System backup: $BACKUP_DIR/system_$DATE.tar.gz"
            ;;
        3)
            log_info "Backing up package list..."
            dpkg --get-selections > "$BACKUP_DIR/packages_$(date +%Y%m%d).txt"
            log_success "Package list saved: $BACKUP_DIR/packages_$(date +%Y%m%d).txt"
            ;;
        4)
            log_info "Creating full backup..."
            DATE=$(date +%Y%m%d_%H%M%S)
            mkdir -p "$BACKUP_DIR/full_$DATE"
            tar -czpf "$BACKUP_DIR/full_$DATE/home.tar.gz" "$HOME" --exclude='.cache' 2>/dev/null
            sudo tar -czpf "$BACKUP_DIR/full_$DATE/system.tar.gz" /etc /root /usr/local 2>/dev/null
            dpkg --get-selections > "$BACKUP_DIR/full_$DATE/packages.txt"
            log_success "Full backup: $BACKUP_DIR/full_$DATE/"
            ;;
        5) return ;;
    esac

    read -p "Press Enter to continue"
}

#===============================================================================
# ABOUT
#===============================================================================

show_about() {
    clear
    echo -e "${CYAN}"
    cat << 'EOF'

     _____ _____   _____         _____           _
    |_   _| ____| |  ___|_   __|_   _|__   __| | ___
      | | |  _|   | |_  | | |  | |/ _ \ / _` |/ _ \
      | | | |___  |  _|  | |_| | |  __/| (_| | (_) |
      |_| |_____| |_|     \__,_|_|\___| \__,_|\___/

    Operating System
    ================================================
    Version: 1.0.0
    Codename: Strawberry Fields
    Based on: Ubuntu 22.04 LTS
    Desktop: XFCE

    Piexed OS is a lightweight, fast, and
    beautiful operating system designed for
    low-end computers with minimum 1GB RAM.

    Features:
    - Optimized for low-end hardware
    - macOS-inspired interface
    - Strawberry branding
    - Ubuntu compatibility
    - Built-in security features
    - Easy software installation

    Website: https://piexed-os.org
    ================================================
EOF
    echo -e "${NC}"

    read -p "Press Enter to continue"
}

#===============================================================================
# MAIN MENU
#===============================================================================

main_menu() {
    while true; do
        print_banner
        echo ""
        echo "Please select an option:"
        echo ""
        echo "  1) System Information"
        echo "  2) System Monitor"
        echo "  3) Disk Cleaner"
        echo "  4) System Update"
        echo "  5) Firewall Configuration"
        echo "  6) User Management"
        echo "  7) Service Manager"
        echo "  8) Hardware Information"
        echo "  9) Backup Tool"
        echo "  10) About"
        echo "  11) Exit"
        echo ""
        read -p "Select option [1-11]: " choice

        case $choice in
            1) show_system_info ;;
            2) show_system_monitor ;;
            3) run_disk_cleaner ;;
            4) run_system_update ;;
            5) configure_firewall ;;
            6) manage_users ;;
            7) manage_services ;;
            8) show_hardware_info ;;
            9) run_backup ;;
            10) show_about ;;
            11) exit 0 ;;
            *) echo "Invalid option" ;;
        esac
    done
}

#===============================================================================
# START
#===============================================================================

main_menu
