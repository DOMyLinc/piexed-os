#!/bin/bash
#
# Piẻxed OS - Server Edition Build Script
# Version: 1.0.0 Professional Server Edition
#

set -euo pipefail

PIEXED_VERSION="1.0.0"
PIEXED_CODENAME="Server Edition"
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
    ║     Server Edition Build System v1.0.0                   ║
    ║     Professional Server Edition                           ║
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
        sudo debootstrap --arch="${ARCH}" --variant=minbase "${UBUNTU_BASE}" chroot "http://archive.ubuntu.com/ubuntu/" || {
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
piexed-server
EOF

    sudo tee "${WORKSPACE}/chroot/etc/hosts" > /dev/null << 'EOF'
127.0.0.1   localhost
127.0.1.1   piexed-server
::1     ip6-localhost ip6-loopback
fe00::0 ip6-localnet
ff00::0 ip6-mcastprefix
ff02::1 ip6-allnodes
ff02::2 ip6-allrouters
EOF
    log_success "Base system configured"
}

install_server_packages() {
    log_info "Installing server packages..."
    sudo chroot "${WORKSPACE}/chroot" /bin/bash << 'EOF'
set -e
export DEBIAN_FRONTEND=noninteractive

apt-get update

apt-get install -y \
    ubuntu-standard \
    linux-image-generic \
    linux-headers-generic \
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
    htop \
    tmux \
    screen \
    fail2ban \
    ufw \
    net-tools \
    iproute2 \
    ethtool \
    traceroute \
    mtr \
    nmap \
    telnet \
    ftp \
    lftp \
    wget \
    curl \
    aria2 \
    git \
    build-essential \
    gcc \
    g++ \
    make \
    cmake \
    python3 \
    python3-pip \
    apache2 \
    nginx \
    mariadb-server \
    mariadb-client \
    postgresql \
    postgresql-client \
    php \
    php-fpm \
    php-mysql \
    php-pgsql \
    php-cli \
    php-curl \
    php-gd \
    php-mbstring \
    php-xml \
    php-xmlrpc \
    php-zip \
    php-json \
    nodejs \
    npm \
    redis-server \
    memcached \
    supervisor \
    logwatch \
    monit \
    apt-listchanges \
    needrestart

apt-get autoremove -y
apt-get clean

useradd -m -s /bin/bash piexed || true
echo "piexed:piexed" | chpasswd
usermod -aG sudo piexed
echo "piexed ALL=(ALL) NOPASSWD:ALL" > /etc/sudoers.d/piexed

EOF
    log_success "Server packages installed"
}

configure_server_security() {
    log_info "Configuring server security..."
    sudo chroot "${WORKSPACE}/chroot" /bin/bash << 'EOF'
set -e

# Configure UFW
ufw default deny incoming
ufw default allow outgoing
ufw allow ssh/tcp
ufw allow 22/tcp
ufw allow 80/tcp
ufw allow 443/tcp
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

[nginx-http-auth]
enabled = true
port = http,https
FAIL2BAN

systemctl enable fail2ban

# SSH hardening
sed -i 's/^PermitRootLogin.*/PermitRootLogin no/' /etc/ssh/sshd_config
sed -i 's/^#*PasswordAuthentication.*/PasswordAuthentication yes/' /etc/ssh/sshd_config

# Configure sysctl
cat > /etc/sysctl.d/99-server-security.conf << 'SYSCTL'
net.ipv4.tcp_timestamps = 1
net.ipv4.tcp_sack = 1
net.ipv4.conf.all.rp_filter = 1
net.ipv4.conf.default.rp_filter = 1
net.ipv4.icmp_echo_ignore_broadcasts = 1
net.ipv4.conf.all.accept_redirects = 0
net.ipv4.conf.default.accept_redirects = 0
net.ipv4.conf.all.send_redirects = 0
net.ipv4.conf.default.send_redirects = 0
vm.swappiness = 10
SYSCTL

EOF
    log_success "Server security configured"
}

configure_server_services() {
    log_info "Configuring server services..."
    sudo chroot "${WORKSPACE}/chroot" /bin/bash << 'EOF'
set -e

# Configure SSH
cat > /etc/ssh/sshd_config << 'SSH'
Port 22
AddressFamily any
ListenAddress 0.0.0.0
Protocol 2
HostKey /etc/ssh/ssh_host_rsa_key
HostKey /etc/ssh/ssh_host_ecdsa_key
HostKey /etc/ssh/ssh_host_ed25519_key
PermitRootLogin no
PubkeyAuthentication yes
PasswordAuthentication yes
PermitEmptyPasswords no
ChallengeResponseAuthentication no
UsePAM yes
X11Forwarding no
PrintMotd no
AcceptEnv LANG LC_*
Subsystem sftp /usr/lib/openssh/sftp-server
AllowUsers piexed
SSH

# Configure Apache
a2enmod rewrite
a2enmod ssl
a2enmod headers
a2enmod proxy
a2enmod proxy_http

# Configure PHP
sed -i 's/;max_execution_time = 30/max_execution_time = 300/' /etc/php/*/fpm/php.ini
sed -i 's/;memory_limit = 128M/memory_limit = 512M/' /etc/php/*/fpm/php.ini
sed -i 's/;upload_max_filesize = 2M/upload_max_filesize = 100M/' /etc/php/*/fpm/php.ini
sed -i 's/;post_max_size = 8M/post_max_size = 100M/' /etc/php/*/fpm/php.ini

# Configure MySQL
mysql_secure_installation || true

# Configure Nginx
cat > /etc/nginx/nginx.conf << 'NGINX'
user www-data;
worker_processes auto;
pid /run/nginx.pid;
include /etc/nginx/modules-enabled/*.conf;

events {
    worker_connections 1024;
    use epoll;
}

http {
    sendfile on;
    tcp_nopush on;
    types_hash_max_size 2048;
    include /etc/nginx/mime.types;
    default_type application/octet-stream;
    access_log /var/log/nginx/access.log;
    error_log /var/log/nginx/error.log;
    gzip on;
    include /etc/nginx/conf.d/*.conf;
}
NGINX

# Configure system
ln -sf /usr/share/zoneinfo/UTC /etc/localtime
dpkg-reconfigure -f noninteractive tzdata

# Enable services
systemctl enable ssh
systemctl enable nginx
systemctl enable php*-fpm
systemctl enable mariadb
systemctl enable postgresql
systemctl enable redis-server

# Create Piẻxed server info
cat > /etc/piexed-version << 'VERSION'
PIEXED_VERSION="1.0.0"
PIEXED_CODENAME="Server Edition"
PIEXED_BUILD=$(date +%Y%m%d)
VERSION

cat > /etc/os-release << 'OSRELEASE'
NAME="Piẻxed OS Server"
VERSION="1.0.0 (Server Edition)"
ID=piexed-server
ID_LIKE=ubuntu
PRETTY_NAME="Piẻxed OS 1.0.0 Server Edition"
VERSION_ID="1.0.0"
HOME_URL="https://piexed-os.org"
SUPPORT_URL="https://github.com/piexed-os"
BUG_REPORT_URL="https://github.com/piexed-os/issues"
VERSION_CODENAME=server
UBUNTU_CODENAME=jammy
OSRELEASE

EOF
    log_success "Server services configured"
}

configure_monitoring() {
    log_info "Configuring monitoring..."
    sudo chroot "${WORKSPACE}/chroot" /bin/bash << 'EOF'
set -e

# Configure htop
mkdir -p /root/.config/htop
cat > /root/.config/htop/htoprc << 'HTOP'
htop_version=2.2
config_version=2
show_cpu_usage=1
show_cpu_freq=1
show_cpu_temperature=1
delay=3
tree_view=0
shadow_range=5
HTOP

# Configure monit
cat > /etc/monit/monitrc << 'MONIT'
set daemon 60
set log /var/log/monit.log
set pidfile /var/run/monit.pid
set statefile /var/lib/monit/state
set httpd port 2812 and
    use address localhost
    allow localhost
    allow admin:monit

include /etc/monit/conf.d/*
MONIT

# Configure logwatch
cat > /etc/logwatch/conf/logwatch.conf << 'LOGWATCH'
LogDir = /var/log
TempDir = /tmp
Output = email
Format = text
MailTo = root
Print = No
Range = yesterday
Detail = Medium
Service = -Except
LOGWATCH

EOF
    log_success "Monitoring configured"
}

install_server_tools() {
    log_info "Installing server tools..."
    
    sudo tee "${WORKSPACE}/chroot/usr/local/bin/piexed-server-info" > /dev/null << 'EOF'
#!/bin/bash
echo "============================================="
echo "   Pi��xed OS Server Information"
echo "============================================="
echo ""
echo "Version:     $(cat /etc/piexed-version | grep VERSION | cut -d'"' -f2)"
echo "Codename:    $(cat /etc/piexed-version | grep CODENAME | cut -d'"' -f2)"
echo "Build:       $(cat /etc/piexed-version | grep BUILD | cut -d'=' -f2)"
echo "Kernel:      $(uname -r)"
echo "Uptime:      $(uptime -p)"
echo ""
echo "=== Services Status ==="
for svc in ssh nginx apache2 mariadb postgresql php-fpm redis-server; do
    if systemctl is-active $svc &>/dev/null; then
        echo "$svc: Active"
    else
        echo "$svc: Inactive"
    fi
done
echo ""
echo "============================================="
EOF

    sudo tee "${WORKSPACE}/chroot/usr/local/bin/piexed-server-backup" > /dev/null << 'EOF'
#!/bin/bash
BACKUP_DIR="/var/backups/piexed"
DATE=$(date +%Y%m%d%H%M%S)
mkdir -p "$BACKUP_DIR/$DATE"

echo "Creating server backup..."

dpkg --get-selections > "$BACKUP_DIR/$DATE/packages.txt"
cp -r /etc "$BACKUP_DIR/$DATE/"
mysqldump -A > "$BACKUP_DIR/$DATE/mysql.sql" 2>/dev/null || true

echo "Backup created: $BACKUP_DIR/$DATE"
echo "Backup size: $(du -sh $BACKUP_DIR/$DATE)"
EOF

    sudo chmod +x "${WORKSPACE}/chroot/usr/local/bin/piexed-server-"*
    log_success "Server tools installed"
}

configure_grub() {
    log_info "Configuring GRUB..."
    sudo chroot "${WORKSPACE}/chroot" /bin/bash << 'EOF'
set -e
cat > /etc/default/grub << 'GRUB'
GRUB_DEFAULT=0
GRUB_TIMEOUT=2
GRUB_TIMEOUT_STYLE=hidden
GRUB_DISTRIBUTOR="Piẻxed OS Server"
GRUB_CMDLINE_LINUX_DEFAULT="quiet splash loglevel=3"
GRUB_CMDLINE_LINUX=""
GRUB_DISABLE_RECOVERY="true"
GRUB
update-grub
EOF
    log_success "GRUB configured"
}

create_iso() {
    log_info "Creating server ISO image..."
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
        -volid "PIEXED_SERVER_1.0.0" \
        -appid "Piẻxed OS Server Edition" \
        -publisher "Piẻxed OS Team" \
        -preparer "Piẻxed OS Build System" \
        -output "${OUTPUT_DIR}/piexed-os-${PIEXED_VERSION}-server.iso" \
        . || {
            log_error "ISO creation failed..."
            exit 1
        }
    
    if [ -f "${OUTPUT_DIR}/piexed-os-${PIEXED_VERSION}-server.iso" ]; then
        log_success "Server ISO created successfully!"
        ls -lh "${OUTPUT_DIR}/piexed-os-${PIEXED_VERSION}-server.iso"
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
    install_server_packages
    configure_server_security
    configure_server_services
    configure_monitoring
    install_server_tools
    configure_grub
    create_iso
    
    log_success "Server build completed!"
    log_success "ISO: ${OUTPUT_DIR}/piexed-os-${PIEXED_VERSION}-server.iso"
}

main "$@"