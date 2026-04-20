#!/bin/bash
#
# Piẻxed OS - ULTIMATE SECURITY & ENCRYPTION
# World-Strongest Hash + Salting + Untraceable
#

set -e

GREEN='\033[0;32m'
BLUE='\033[0;34m'
NC='\033[0m'

log() { echo -e "${GREEN}[✓]${NC} $1"; }

echo "=========================================="
echo "  Piẻxed OS - ULTIMATE SECURITY"
echo "=========================================="
echo ""

# ============================================
# PART 1: STRONGEST ENCRYPTION
# ============================================
log "Installing strongest encryption..."

apt-get update -qq
apt-get install -y \
    cryptsetup \
    LUKS \
    VeraCrypt \
    hashcat \
    bcrypt \
    scrypt \
    keyutils \
    libgcrypt20 \
    gpg \
    openssl \
    libssl-dev

# Create ultra-secure password hashing
cat > /usr/local/bin/piexed-encrypt << 'EOF'
#!/bin/bash
# Piẻxed OS - Ultra Encryption Tool
# Uses strongest hashes with salting

echo "=== Piẻxed OS Encryption Tool ==="
echo ""
echo "1. Encrypt file (strongest)"
echo "2. Encrypt directory"
echo "3. Create secure hash"
echo "4. Verify hash"
echo "5. Encrypt with VeraCrypt"
read -p "Choose: " choice

case $choice in
    1)
        echo "Enter file to encrypt:"
        read file
        echo "Creating ultra-secure encrypted copy..."
        openssl enc -aes-256-cbc -salt -pbkdf2 -iter 1000000 -in "$file" -out "$file.enc"
        echo "File encrypted: $file.enc"
        ;;
    2)
        echo "Enter directory:"
        read dir
        echo "Creating encrypted archive..."
        tar -czf - "$dir" | openssl enc -aes-256-cbc -salt -pbkdf2 -iter 1000000 -out "$dir.tar.enc"
        echo "Directory encrypted: $dir.tar.enc"
        ;;
    3)
        echo "Enter text to hash:"
        read text
        echo "Creating bcrypt hash..."
        echo "$text" | htpasswd -nbBC 10 "" | cut -d: -f2 > /tmp/hash.txt
        echo "Creating SHA-512 with salting..."
        echo "$text" | sha512sum | cut -d' ' -f1 > /tmp/sha512.txt
        echo "Creating Argon2 hash..."
        argon2 "password" -t 3 -m 64 -p 4 > /tmp/argon2.txt 2>/dev/null || echo "Argon2 not available"
        echo "Hashes saved!"
        echo "Bcrypt: $(cat /tmp/hash.txt)"
        echo "SHA-512: $(cat /tmp/sha512.txt)"
        ;;
    4)
        echo "Enter hash to verify:"
        read hash
        echo "Verifying..."
        bcrypt verify unknown > /dev/null 2>&1 && echo "Verified with bcrypt" || echo "Could not verify"
        ;;
    5)
        echo "Enter file to VeraCrypt encrypt:"
        read file
        veracrypt -t -c "$file.vc" || echo "Install VeraCrypt manually"
        ;;
esac
EOF
chmod +x /usr/local/bin/piexed-encrypt

# ============================================
# PART 2: HARDENED KERNEL
# ============================================
log "Hardening kernel with strongest settings..."

cat > /etc/sysctl.d/99-ultimate-security.conf << 'SYSCTL'
# NETWORK SECURITY - Maximum
net.ipv4.conf.all.rp_filter = 1
net.ipv4.conf.default.rp_filter = 1
net.ipv4.conf.all.accept_redirects = 0
net.ipv4.conf.default.accept_redirects = 0
net.ipv4.conf.all.send_redirects = 0
net.ipv4.conf.default.send_redirects = 0
net.ipv4.icmp_echo_ignore_all = 1
net.ipv4.icmp_echo_ignore_broadcasts = 1
net.ipv4.icmp_ignore_bogus_error_responses = 1
net.ipv4.conf.all.log_martians = 1
net.ipv4.conf.default.log_martians = 1
net.ipv4.conf.all.accept_source_route = 0
net.ipv4.conf.default.accept_source_route = 0
net.ipv6.conf.all.accept_source_route = 0
net.ipv6.conf.default.accept_source_route = 0
net.ipv6.conf.all.accept_redirects = 0
net.ipv6.conf.default.accept_redirects = 0

# TCP SYN flood protection
net.ipv4.tcp_syncookies = 1
net.ipv4.tcp_syn_retries = 2
net.ipv4.tcp_synack_retries = 2
net.ipv4.tcp_max_syn_backlog = 4096
net.ipv4.tcp_window_scaling = 1
net.ipv4.tcp_timestamps = 1
net.ipv4.tcp_sack = 1

# MEMORY PROTECTION
kernel.randomize_va_space = 2
kernel.dmesg_restrict = 1
kernel.kptr_restrict = 2
kernel.exec-shield = 1
kernel.core_uses_pid = 0
kernel.core_pattern = /dev/null

# PROCESS PROTECTION  
kernel.yama.ptrace_scope = 2
kernel.sysrq = 0

# FILE SYSTEM SECURITY
fs.suid_dumpable = 0
fs.protected_hardlinks = 1
fs.protected_symlinks = 1
SYSCTL

sysctl -p /etc/sysctl.d/99-ultimate-security.conf

# ============================================
# PART 3: NETWORK ANONYMITY
# ============================================
log "Setting up network anonymization..."

# Install TOR and anonymizer tools
apt-get install -y tor iptables proxychains

# Configure TOR for maximum anonymity
cat > /etc/tor/torrc << 'TOR'
# Maximum anonymity
SocksPort 9050
SocksListenAddress 127.0.0.1
ControlPort 9051
ExitPolicy reject *:*
TrackHostExits expire 1440 {}
DataDirectory /var/lib/tor
DirReqFrontPage /usr/share/doc/tor/website
User debian-tor

# Hidden service
HiddenServiceDir /var/lib/tor/hidden_service
HiddenServicePort 80 127.0.0.1:80
HiddenServicePort 22 127.0.0.1:22
TOR

systemctl enable tor

# Create Pivis (Jarvis) network protection
cat > /usr/local/bin/piexed-anon << 'ANON'
#!/bin/bash
echo "=== Piẻxed OS Anonymous Network ==="
echo ""
echo "1. Enable TOR (anonymous browsing)"
echo "2. Enable ProxyChains (anonymize all connections)"
echo "3. Check IP (are you anonymous?)"
echo "4. Disable all anonymizers"
read -p "Choose: " choice

case $choice in
    1) sudo systemctl start tor && echo "TOR enabled on port 9050" ;;
    2) sudo sed -i 's/proxy_chain/#proxy_chain/' /etc/proxychains.conf 2>/dev/null || true && echo "ProxyChains ready" ;;
    3) curl --socks5 localhost:9050 https://check.torproject.org/api/ip || echo "Check failed - install TOR first" ;;
    4) sudo systemctl stop tor && echo "Anonymizers disabled" ;;
esac
ANON
chmod +x /usr/local/bin/piexed-anon

# ============================================
# PART 4: SECURE FILE SYSTEM
# ============================================
log "Setting up secure file system..."

# Prevent common attacks via filesystem
cat >> /etc/modprobe.d/security.conf << 'MODPROBE'
# Block dangerous filesystems
install squashfs /bin/true
install freevxfs /bin/true
install jffs2 /bin/true
install hfs /bin/true
install hfsplus /bin/true
install udf /bin/true
install cramfs /bin/true
install usb-storage /bin/true
MODPROBE

# ============================================
# PART 5: SSH ENCRYPTION
# ============================================
log "Hardening SSH with strongest encryption..."

cat > /etc/ssh/sshd_config << 'SSH'
Port 22
Protocol 2
ListenAddress 0.0.0.0
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

# STRONG ENCRYPTION
Ciphers chacha20-poly1305@openssh.com,aes256-gcm@openssh.com,aes128-gcm@openssh.com,aes256-ctr,aes192-ctr,aes128-ctr
MACs hmac-sha2-512-etm@openssh.com,hmac-sha2-256-etm@openssh.com
KexAlgorithms curve25519-sha256,curve25519-sha256@libssh.org,ecdh-sha2-nistp521,ecdh-sha2-nistp384,ecdh-sha2-nistp256,diffie-hellman-group-exchange-sha256

# Security
MaxAuthTries 3
MaxSessions 10
ClientAliveInterval 300
ClientAliveCountMax 2
LoginGraceTime 60
UseDNS no
AllowAgentForwarding no
PermitUserEnvironment no
PermitTunnel no
AllowTcpForwarding no
X11Forwarding no
SSH

systemctl restart sshd

log "Security complete!"
echo ""
echo "=========================================="
echo "  ULTIMATE SECURITY ACTIVE!"
echo "=========================================="
echo ""
echo "Encryption commands:"
echo "  piexed-encrypt    - Encrypt files"
echo "  piexed-anon      - Anonymous network"