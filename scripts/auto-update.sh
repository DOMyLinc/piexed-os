#!/bin/bash
#
# Piẻxed OS - GitHub Auto-Update System
# Automatically updates from GitHub repository
#

set -euo pipefail

REPO_URL="https://github.com/piexed-os/piexed-os"
UPDATE_BRANCH="${UPDATE_BRANCH:-main}"
LOG_FILE="/var/log/piexed-update.log"
LOCK_FILE="/var/run/piexed-update.lock"
CHECK_INTERVAL="${CHECK_INTERVAL:-3600}"  # 1 hour default

RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m'

log() {
    echo "[$(date '+%Y-%m-%d %H:%M:%S')] $1" | tee -a "$LOG_FILE"
}

log_info() { log "${GREEN}[INFO]${NC} $1"; }
log_warn() { log "${YELLOW}[WARNING]${NC} $1"; }
log_error() { log "${RED}[ERROR]${NC} $1"; }

check_lock() {
    if [ -f "$LOCK_FILE" ]; then
        LOCK_AGE=$(($(date +%s) - $(stat -c %Y "$LOCK_FILE" 2>/dev/null || echo 0)))
        if [ "$LOCK_AGE" -lt 3600 ]; then
            log_warn "Update already running (lock file exists)"
            exit 0
        fi
        rm -f "$LOCK_FILE"
    fi
    touch "$LOCK_FILE"
}

remove_lock() {
    rm -f "$LOCK_FILE"
}

trap remove_lock EXIT

get_versions() {
    CURRENT_VERSION="1.0.0"
    if [ -f /etc/piexed-version ]; then
        CURRENT_VERSION=$(grep VERSION /etc/piexed-version 2>/dev/null | cut -d'"' -f2 || echo "1.0.0")
    fi
    
    NEW_VERSION="1.0.0"
}

check_for_updates() {
    log_info "Checking for updates..."
    
    if ! command -v git &> /dev/null; then
        log_error "Git not installed"
        return 1
    fi
    
    cd /tmp
    
    if [ -d "/tmp/piexed-os-repo" ]; then
        rm -rf /tmp/piexed-os-repo
    fi
    
    if ! git clone --depth 1 -b "$UPDATE_BRANCH" "$REPO_URL" /tmp/piexed-os-repo 2>/dev/null; then
        log_error "Failed to clone repository"
        return 1
    fi
    
    if [ -f /tmp/piexed-os-repo/etc/piexed-version ]; then
        NEW_VERSION=$(grep VERSION /tmp/piexed-os-repo/etc/piexed-version | cut -d'"' -f2 || echo "1.0.0")
    else
        NEW_VERSION="1.0.0"
    fi
    
    get_versions
    
    if [ "$NEW_VERSION" != "$CURRENT_VERSION" ]; then
        log_info "New version available: $NEW_VERSION (current: $CURRENT_VERSION)"
        return 0
    else
        log_info "System is up to date ($CURRENT_VERSION)"
        rm -rf /tmp/piexed-os-repo
        return 1
    fi
}

backup_system() {
    log_info "Creating system backup..."
    
    local BACKUP_DIR="/var/backup/piexed/$(date +%Y%m%d%H%M%S)"
    mkdir -p "$BACKUP_DIR"
    
    dpkg --get-selections > "$BACKUP_DIR/package-list.txt"
    cp -r /etc "$BACKUP_DIR/"
    
    log_info "Backup saved to $BACKUP_DIR"
}

perform_update() {
    log_info "Starting update process..."
    
    if ! check_for_updates; then
        log_info "No updates available"
        return 0
    fi
    
    backup_system
    
    log_info "Updating package lists..."
    export DEBIAN_FRONTEND=noninteractive
    apt-get update -qq || {
        log_error "Failed to update package lists"
        return 1
    }
    
    log_info "Upgrading system packages..."
    apt-get upgrade -y -qq || {
        log_error "Failed to upgrade packages"
        return 1
    }
    
    log_info "Installing new packages..."
    apt-get dist-upgrade -y -qq || {
        log_warn "Dist-upgrade had warnings (continuing anyway)"
    }
    
    log_info "Updating Piẻxed OS system files..."
    if [ -d /tmp/piexed-os-repo/usr/local/bin ]; then
        cp -rf /tmp/piexed-os-repo/usr/local/bin/* /usr/local/bin/ 2>/dev/null || true
        chmod +x /usr/local/bin/piexed-* 2>/dev/null || true
    fi
    
    if [ -d /tmp/piexed-os-repo/etc ]; then
        cp -rf /tmp/piexed-os-repo/etc/* /etc/ 2>/dev/null || true
    fi
    
    log_info "Cleaning up..."
    apt-get autoremove -y -qq 2>/dev/null || true
    apt-get clean -qq 2>/dev/null || true
    
    rm -rf /tmp/piexed-os-repo
    
    log_info "Update completed successfully!"
    
    if [ "$1" == "--reboot" ]; then
        log_info "Rebooting in 10 seconds..."
        sleep 10
        reboot
    fi
}

install_cron() {
    log_info "Installing auto-update cron jobs..."
    
    cat > /etc/cron.d/piexed-update << 'EOF'
SHELL=/bin/bash
PATH=/usr/local/sbin:/usr/local/bin:/sbin:/bin

# Check for updates every hour
0 * * * * root /usr/local/bin/piexed-auto-update --check >/dev/null 2>&1

# Install updates daily at 3am
0 3 * * * root /usr/local/bin/piexed-auto-update --update >/dev/null 2>&1
EOF

    cat > /etc/systemd/system/piexed-update.service << 'EOF'
[Unit]
Description=Piexed OS Auto Update
After=network-online.target
Wants=network-online.target

[Service]
Type=oneshot
ExecStart=/usr/local/bin/piexed-auto-update --update
StandardOutput=journal
StandardError=journal
EOF

    cat > /etc/systemd/system/piexed-update.timer << 'EOF'
[Unit]
Description=Piexed OS Auto Update Timer

[Timer]
OnCalendar=hourly
Persistent=true

[Install]
WantedBy=timers.target
EOF

    cat > /usr/local/bin/piexed-auto-update << 'AUTO'
#!/bin/bash
exec /opt/piexed-updater/auto-update.sh "$@"
AUTO

    chmod +x /usr/local/bin/piexed-auto-update
    
    systemctl daemon-reload 2>/dev/null || true
    systemctl enable piexed-update.timer 2>/dev/null || true
    
    log_info "Auto-update system installed"
}

uninstall() {
    rm -f /etc/cron.d/piexed-update
    rm -f /etc/systemd/system/piexed-update.*
    rm -f /usr/local/bin/piexed-auto-update
    rm -f /var/run/piexed-update.lock
    systemctl daemon-reload 2>/dev/null || true
    log_info "Auto-update system uninstalled"
}

show_status() {
    get_versions
    echo ""
    echo "Piẻxed OS Auto-Update Status"
    echo "=============================="
    echo "Current Version: $CURRENT_VERSION"
    echo "Latest Version: $NEW_VERSION"
    echo "Repository: $REPO_URL"
    echo "Branch: $UPDATE_BRANCH"
    echo ""
    
    if systemctl is-enabled piexed-update.timer &>/dev/null; then
        echo "Timer: Enabled"
    else
        echo "Timer: Disabled"
    fi
    
    if [ -f "$LOG_FILE" ]; then
        echo ""
        echo "Last log entries:"
        tail -5 "$LOG_FILE"
    fi
    echo ""
}

case "${1:-}" in
    --check)
        check_lock
        check_for_updates
        remove_lock
        ;;
    --update)
        check_lock
        perform_update "${2:-}"
        remove_lock
        ;;
    --install)
        install_cron
        ;;
    --uninstall)
        uninstall
        ;;
    --status)
        show_status
        ;;
    *)
        echo "Usage: $0 {--check|--update|--install|--uninstall|--status}"
        echo ""
        echo "Options:"
        echo "  --check     Check for updates"
        echo "  --update    Check and perform update"
        echo "  --install   Install auto-update system"
        echo "  --uninstall Remove auto-update system"
        echo "  --status    Show update status"
        exit 1
        ;;
esac