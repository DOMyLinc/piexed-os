#!/bin/bash
#
# Piẻxed OS Backup and Recovery Suite
# Complete backup and disaster recovery system
#

set -e

BACKUP_VERSION="1.0.0"
BACKUP_DIR="${BACKUP_DIR:-/backup}"
LOG_DIR="/var/log/piexed/backup"
CONFIG_DIR="/etc/piexed/backup"

echo "╔══════════════════════════════════════════════════════════╗"
echo "║        Piẻxed OS Backup and Recovery Suite             ║"
echo "║                   Version ${BACKUP_VERSION}                            ║"
echo "╚══════════════════════════════════════════════════════════╝"
echo ""

# Create directories
mkdir -p "${BACKUP_DIR}"
mkdir -p "${LOG_DIR}"
mkdir -p "${CONFIG_DIR}"

# Configuration
cat > "${CONFIG_DIR}/backup.conf" << 'EOF'
# Piẻxed OS Backup Configuration

# Backup destination
BACKUP_DEST="/backup"

# Backup compression (gzip, bzip2, xz, none)
COMPRESSION="xz"

# Backup retention (days)
RETENTION_DAYS=30

# Exclude patterns
EXCLUDE_PATTERNS=(
    "/proc/*"
    "/sys/*"
    "/dev/*"
    "/run/*"
    "/tmp/*"
    "/lost+found/*"
    "/backup/*"
    "/mnt/*"
    "/media/*"
    "*.log"
    ".cache/*"
    "Cache/*"
    "Trash/*"
)

# Backup includes (system files)
INCLUDE_SYSTEM=(
    "/etc"
    "/var/www"
    "/var/spool/cron"
    "/root"
    "/home"
)

# Database backups
ENABLE_DB_BACKUP=true
DB_BACKUPS=(
    "mysql:*"
    "postgresql:*"
    "mongodb:*"
)

# Cloud backup (optional)
ENABLE_CLOUD_BACKUP=false
CLOUD_PROVIDER="none"  # borg, rclone, rsync
CLOUD_DEST=""

# Notification
ENABLE_EMAIL=false
EMAIL_TO="root@localhost"
EOF

# Backup Functions
backup_home() {
    local backup_name="home-$(date +%Y%m%d-%H%M%S)"
    local backup_path="${BACKUP_DIR}/${backup_name}.tar.xz"

    echo "[1/6] Backing up home directories..."

    # Create backup with progress
    tar -cpv --exclude='.cache' --exclude='.local/share/Trash' \
        --exclude='*.log' --exclude='Downloads/*' \
        -f - /home | xz > "${backup_path}" 2>/dev/null || \
    tar -cpv --exclude='.cache' --exclude='.local/share/Trash' \
        --exclude='*.log' --exclude='Downloads/*' \
        -f "${backup_path}" -C / home 2>/dev/null

    # Create verification file
    echo "$(date)" > "${backup_path}.info"
    echo "Type: Home Directory Backup" >> "${backup_path}.info"
    echo "Size: $(du -h ${backup_path} | cut -f1)" >> "${backup_path}.info"

    echo "  Home backup: ${backup_path}"
}

backup_system_config() {
    local backup_name="system-$(date +%Y%m%d-%H%M%S)"
    local backup_path="${BACKUP_DIR}/${backup_name}.tar.gz"

    echo "[2/6] Backing up system configuration..."

    tar -cpzf "${backup_path}" \
        /etc \
        /root \
        /var/backups \
        /usr/local \
        /opt 2>/dev/null || true

    echo "$(date)" > "${backup_path}.info"
    echo "Type: System Configuration Backup" >> "${backup_path}.info"
    echo "Size: $(du -h ${backup_path} | cut -f1)" >> "${backup_path}.info"

    echo "  System backup: ${backup_path}"
}

backup_packages() {
    local backup_file="${BACKUP_DIR}/packages-$(date +%Y%m%d).txt"

    echo "[3/6] Backing up installed packages..."

    # Create package list
    dpkg --get-selections > "${backup_file}" 2>/dev/null || true
    apt-mark showmanual > "${backup_file}.manual" 2>/dev/null || true

    # Create restore script
    cat > "${backup_file}.restore" << 'RESTORE'
#!/bin/bash
# Piẻxed OS Package Restore Script

PACKAGE_LIST="${1}"

echo "Restoring packages from ${PACKAGE_LIST}..."

# Restore package selections
sudo dpkg --clear-selections
sudo dpkg --set-selections < "${PACKAGE_LIST}"

# Install
sudo apt-get dselect-upgrade -y

echo "Package restore complete!"
RESTORE

    chmod +x "${backup_file}.restore"

    echo "  Package list: ${backup_file}"
}

backup_bootloader() {
    local backup_dir="${BACKUP_DIR}/boot-$(date +%Y%m%d)"
    mkdir -p "${backup_dir}"

    echo "[4/6] Backing up bootloader..."

    # Backup GRUB configuration
    cp -r /boot/grub "${backup_dir}/" 2>/dev/null || true
    cp /etc/default/grub "${backup_dir}/" 2>/dev/null || true

    # Backup EFI (if exists)
    if [ -d "/boot/efi" ]; then
        mkdir -p "${backup_dir}/efi"
        cp -r /boot/efi/EFI "${backup_dir}/efi/" 2>/dev/null || true
    fi

    # Backup partition table
    sfdisk -d /dev/sda > "${backup_dir}/partition-table.txt" 2>/dev/null || true

    # Create restore script
    cat > "${backup_dir}/restore-bootloader.sh" << 'RESTORE'
#!/bin/bash
# Restore bootloader from backup

BACKUP_DIR="$(dirname "$0")"

echo "Restoring bootloader..."

# Restore GRUB
grub-install /dev/sda
grub-mkconfig -o /boot/grub/grub.cfg

echo "Bootloader restore complete!"
RESTORE

    chmod +x "${backup_dir}/restore-bootloader.sh"

    echo "  Bootloader backup: ${backup_dir}/"
}

backup_mbr() {
    local backup_file="${BACKUP_DIR}/mbr-$(date +%Y%m%d).img"

    echo "[5/6] Backing up MBR..."

    # Backup MBR (first 512 bytes)
    dd if=/dev/sda of="${backup_file}" bs=512 count=1 2>/dev/null || true

    # Backup disk UUIDs
    blkid > "${backup_file}.uuids" 2>/dev/null || true

    echo "  MBR backup: ${backup_file}"
}

backup_encryption_keys() {
    local backup_dir="${BACKUP_DIR}/keys-$(date +%Y%m%d)"

    echo "[6/6] Backing up encryption keys (encrypted)..."

    mkdir -p "${backup_dir}"

    # Prompt for encryption password
    echo "Enter encryption password for backup:"
    read -s ENCRYPT_PASS

    # Backup LUKS headers (encrypted)
    if command -v cryptsetup &> /dev/null; then
        for dev in /dev/sd*; do
            if cryptsetup isLuks "${dev}" 2>/dev/null; then
                cryptsetup luksHeaderBackup "${dev}" \
                    --header-backup-file "${backup_dir}/$(basename ${dev}).luks" 2>/dev/null || true
            fi
        done
    fi

    # Encrypt backup directory
    tar -czf - "${backup_dir}" 2>/dev/null | \
        openssl enc -aes-256-cbc -salt -pass pass:"${ENCRYPT_PASS}" -out "${BACKUP_DIR}/keys-$(date +%Y%m%d).tar.enc" 2>/dev/null || true

    rm -rf "${backup_dir}"

    echo "  Encrypted keys backup: ${BACKUP_DIR}/keys-$(date +%Y%m%d).tar.enc"
}

# Full System Backup
full_backup() {
    echo ""
    echo "=== Full System Backup ==="
    echo ""

    local backup_date=$(date +%Y%m%d-%H%M%S)
    local backup_path="${BACKUP_DIR}/full-system-${backup_date}"

    mkdir -p "${backup_path}"

    echo "Starting full system backup to ${backup_path}..."

    # Create backup manifest
    cat > "${backup_path}/MANIFEST" << 'EOF'
PIEXED OS FULL SYSTEM BACKUP
============================

This backup contains:
- Complete root filesystem (/)
- Boot configuration
- Installed packages
- User data

To restore:
1. Boot from Piẻxed OS Live USB
2. Mount target disk
3. Extract this backup
4. Reinstall bootloader
5. Reboot

WARNING: This backup may be large. Ensure sufficient disk space.
EOF

    echo "$(date)" >> "${backup_path}/MANIFEST"

    # Create backup using rsync (more reliable)
    if command -v rsync &> /dev/null; then
        rsync -aAXHv \
            --exclude={"/proc/*","/sys/*","/dev/*","/run/*","/tmp/*","/lost+found/*","/backup/*","/mnt/*","/media/*","/home/*/.cache/*"} \
            / "${backup_path}/root/" 2>/dev/null || true
    else
        tar -cpzf "${backup_path}/root.tar.gz" --exclude='/home/*' --exclude='/proc/*' --exclude='/sys/*' --exclude='/dev/*' --exclude='/run/*' --exclude='/tmp/*' / 2>/dev/null || true
    fi

    # Backup boot
    cp -r /boot "${backup_path}/" 2>/dev/null || true

    # Backup packages
    dpkg --get-selections > "${backup_path}/packages.txt" 2>/dev/null || true

    # Create restore script
    cat > "${backup_path}/restore.sh" << 'RESTORE'
#!/bin/bash
# Piẻxed OS Full System Restore

set -e

TARGET_DISK="${1:-/dev/sda}"
BACKUP_DIR="$(dirname "$0")"

echo "=== Piẻxed OS Full System Restore ==="
echo ""
echo "Target Disk: ${TARGET_DISK}"
echo "Backup Location: ${BACKUP_DIR}"
echo ""
read -p "This will ERASE all data on ${TARGET_DISK}. Continue? (yes/no): " confirm

if [ "$confirm" != "yes" ]; then
    echo "Restore cancelled."
    exit 1
fi

# Unmount partitions
umount -R /mnt 2>/dev/null || true

# Partition disk
parted -s ${TARGET_DISK} mklabel gpt
parted -s ${TARGET_DISK} mkpart primary fat32 1MiB 513MiB
parted -s ${TARGET_DISK} set 1 esp on
parted -s ${TARGET_DISK} mkpart primary ext4 513MiB 100%

# Format partitions
mkfs.fat -F32 ${TARGET_DISK}1
mkfs.ext4 -F ${TARGET_DISK}2

# Mount
mount ${TARGET_DISK}2 /mnt
mkdir -p /mnt/boot/efi
mount ${TARGET_DISK}1 /mnt/boot/efi

# Restore root filesystem
tar -xpzf ${BACKUP_DIR}/root.tar.gz -C /mnt

# Install bootloader
grub-install --target=x86_64-efi --efi-directory=/mnt/boot/efi --boot-directory=/mnt/boot ${TARGET_DISK}
grub-mkconfig -o /mnt/boot/grub/grub.cfg

# Restore packages
dpkg --set-selections < ${BACKUP_DIR}/packages.txt
apt-get dselect-upgrade -y

echo ""
echo "Restore complete! Please reboot."
RESTORE

    chmod +x "${backup_path}/restore.sh"

    # Compress backup directory
    echo "Compressing backup..."
    tar -I pxz -cvf "${BACKUP_DIR}/full-system-${backup_date}.tar.xz" -C "${BACKUP_DIR}" "full-system-${backup_date}"

    # Remove uncompressed directory
    rm -rf "${backup_path}"

    echo ""
    echo "Full system backup complete!"
    echo "Backup: ${BACKUP_DIR}/full-system-${backup_date}.tar.xz"
}

# Incremental Backup (using rsync)
incremental_backup() {
    local backup_path="${BACKUP_DIR}/incremental-$(date +%Y%m%d)"

    echo "=== Incremental Backup ==="
    echo ""

    mkdir -p "${backup_path}"

    echo "Running incremental backup..."

    rsync -aAXHv \
        --delete \
        --delete-excluded \
        --exclude={"/proc/*","/sys/*","/dev/*","/run/*","/tmp/*","/lost+found/*","/backup/*"} \
        / "${backup_path}/" 2>/dev/null || true

    echo ""
    echo "Incremental backup complete: ${backup_path}/"
}

# Cloud Backup
cloud_backup() {
    echo "=== Cloud Backup ==="
    echo ""

    # Check for cloud provider
    if [ ! -f "${CONFIG_DIR}/backup.conf" ]; then
        echo "Cloud backup not configured. Edit ${CONFIG_DIR}/backup.conf"
        return 1
    fi

    source "${CONFIG_DIR}/backup.conf"

    case "${CLOUD_PROVIDER}" in
        "borg")
            echo "Backing up to Borg repository..."
            borg create "${CLOUD_DEST}"::'{hostname}-{now:%Y-%m-%d}' /home /etc --compression lz4
            ;;
        "rclone")
            echo "Backing up to rclone destination..."
            rclone sync /home "${CLOUD_DEST}" --progress
            ;;
        *)
            echo "Cloud provider not configured. Available: borg, rclone"
            ;;
    esac
}

# Restore Functions
restore_home() {
    local backup_file="${1}"

    if [ ! -f "${backup_file}" ]; then
        echo "Backup file not found: ${backup_file}"
        return 1
    fi

    echo "Restoring home directories from ${backup_file}..."
    tar -xpf "${backup_file}" -C /

    echo "Home directory restore complete!"
}

restore_system() {
    local backup_file="${1}"

    if [ ! -f "${backup_file}" ]; then
        echo "Backup file not found: ${backup_file}"
        return 1
    fi

    echo "Restoring system configuration from ${backup_file}..."
    tar -xpf "${backup_file}" -C /

    echo "System configuration restore complete!"
}

restore_mbr() {
    local backup_file="${1}"

    if [ ! -f "${backup_file}" ]; then
        echo "MBR backup not found: ${backup_file}"
        return 1
    fi

    echo "Restoring MBR from ${backup_file}..."
    echo "WARNING: This will overwrite the first 512 bytes of /dev/sda"
    read -p "Continue? (yes/no): " confirm

    if [ "$confirm" = "yes" ]; then
        dd if="${backup_file}" of=/dev/sda bs=512 count=1
        echo "MBR restore complete! Please reboot."
    fi
}

restore_packages() {
    local package_file="${1}"

    if [ ! -f "${package_file}" ]; then
        echo "Package list not found: ${package_file}"
        return 1
    fi

    echo "Restoring packages from ${package_file}..."

    dpkg --clear-selections
    dpkg --set-selections < "${package_file}"
    apt-get dselect-upgrade -y

    echo "Package restore complete!"
}

# Schedule Backup
schedule_backup() {
    echo "Setting up automatic backup schedule..."

    # Create cron job for daily backup
    cat > /etc/cron.daily/piexed-backup << 'EOF'
#!/bin/bash
# Piẻxed OS Daily Backup

BACKUP_DIR="/backup"
LOG_DIR="/var/log/piexed/backup"

# Run backup
/home/piexed/scripts/backup.sh incremental 2>&1 | tee -a "${LOG_DIR}/backup-$(date +%Y%m%d).log"

# Clean old backups (keep last 7 days)
find "${BACKUP_DIR}" -name "*.tar.*" -mtime +7 -delete
find "${BACKUP_DIR}" -name "*.xz" -mtime +7 -delete
EOF

    chmod +x /etc/cron.daily/piexed-backup

    echo "Automatic backup scheduled (daily at 3 AM)"
}

# Main Menu
main_menu() {
    clear
    echo "╔══════════════════════════════════════════════════════════╗"
    echo "║        Piẻxed OS Backup and Recovery Center           ║"
    echo "╚══════════════════════════════════════════════════════════╝"
    echo ""
    echo "1. Quick Backup (Home + System Config)"
    echo "2. Full System Backup"
    echo "3. Incremental Backup"
    echo "4. Cloud Backup"
    echo "5. Restore Home Directory"
    echo "6. Restore System Configuration"
    echo "7. Restore MBR"
    echo "8. Restore Packages"
    echo "9. View Backup History"
    echo "10. Schedule Automatic Backup"
    echo "11. Exit"
    echo ""
    read -p "Select option [1-11]: " choice

    case $choice in
        1) backup_home && backup_system_config && backup_packages && backup_bootloader ;;
        2) full_backup ;;
        3) incremental_backup ;;
        4) cloud_backup ;;
        5)
            echo "Enter backup file path:"
            read backup_file
            restore_home "${backup_file}"
            ;;
        6)
            echo "Enter backup file path:"
            read backup_file
            restore_system "${backup_file}"
            ;;
        7)
            echo "Enter MBR backup file path:"
            read backup_file
            restore_mbr "${backup_file}"
            ;;
        8)
            echo "Enter package list file path:"
            read package_file
            restore_packages "${package_file}"
            ;;
        9) ls -lh "${BACKUP_DIR}" ;;
        10) schedule_backup ;;
        11) exit 0 ;;
        *) echo "Invalid option" ;;
    esac

    read -p "Press Enter to continue"
    main_menu
}

# CLI mode
case "${1}" in
    "home")
        backup_home
        ;;
    "system")
        backup_system_config
        ;;
    "packages")
        backup_packages
        ;;
    "bootloader")
        backup_bootloader
        ;;
    "mbr")
        backup_mbr
        ;;
    "full")
        full_backup
        ;;
    "incremental")
        incremental_backup
        ;;
    "cloud")
        cloud_backup
        ;;
    "schedule")
        schedule_backup
        ;;
    *)
        main_menu
        ;;
esac