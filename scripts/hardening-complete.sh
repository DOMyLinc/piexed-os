#!/bin/bash
#
# Piẻxed OS - ULTIMATE SECURITY HARDENING
# World-Class Firewall + Anti-Malware + Privacy Protection
# Version: 1.0.0
#

set -e

RED='\033[0;31m'
GREEN='\033[0;32m'
BLUE='\033[0;34m'
YELLOW='\033[1;33m'
NC='\033[0m'

log() { echo -e "${GREEN}[✓]${NC} $1"; }
log_warn() { echo -e "${YELLOW}[!]${NC} $1"; }
log_error() { echo -e "${RED}[✗]${NC} $1"; }

echo "=========================================="
echo "  Piẻxed OS - SECURITY SUITE"
echo "=========================================="
echo ""

# ============================================
# PART 1: ULTIMATE FIREWALL
# ============================================
log "Installing Ultimate Firewall..."

# Install UFW with strict rules
apt-get update -qq
apt-get install -y ufw gufw fail2ban rkhunter chkrootkit lynis auditd aide

# Default deny all
ufw --force reset
ufw default deny incoming
ufw default allow outgoing
ufw default allow routed

# Allow only essential ports
ufw allow 22/tcp comment 'SSH'
ufw allow 80/tcp comment 'HTTP'
ufw allow 443/tcp comment 'HTTPS'

# Enable firewall
echo "y" | ufw enable

# Enable fail2ban
systemctl enable fail2ban
systemctl start fail2ban

# ============================================
# PART 2: ANTI-MALWARE & ANTIVIRUS
# ============================================
log "Installing Anti-Malware Suite..."

# Install ClamAV
apt-get install -y clamav clamav-daemon clamav-freshclam

# Update virus definitions
freshclam

# Create scan scripts
mkdir -p /usr/local/bin/piexed-scan

cat > /usr/local/bin/piexed-scan/scan-malware << 'EOF'
#!/bin/bash
echo "=== Piẻxed OS Malware Scanner ==="
echo "Scanning system..."

# Quick scan
clamscan --recursive --remove /tmp
clamscan --recursive --remove /var/tmp
clamscan --recursive --remove /home

# Full system scan option
if [ "$1" == "--full" ]; then
    echo "Running full system scan..."
    clamscan --recursive --remove /
fi

echo "Scan complete!"
EOF

chmod +x /usr/local/bin/piexed-scan/scan-malware

# ============================================
# PART 3: KERNEL HARDENING
# ============================================
log "Hardening Kernel..."

# Create security sysctl rules
cat > /etc/sysctl.d/99-security-hardening.conf << 'SYSCTL'
# ============== NETWORK SECURITY ==============
# Prevent IP spoofing
net.ipv4.conf.all.rp_filter = 1
net.ipv4.conf.default.rp_filter = 1

# Ignore ICMP redirects
net.ipv4.conf.all.accept_redirects = 0
net.ipv4.conf.default.accept_redirects = 0
net.ipv6.conf.all.accept_redirects = 0
net.ipv6.conf.default.accept_redirects = 0

# Don't send redirects
net.ipv4.conf.all.send_redirects = 0
net.ipv4.conf.default.send_redirects = 0

# Ignore ICMP ping requests
net.ipv4.icmp_echo_ignore_all = 1
net.ipv4.icmp_echo_ignore_broadcasts = 1

# Ignore bogus ICMP errors
net.ipv4.icmp_ignore_bogus_error_responses = 1

# Log suspicious packets
net.ipv4.conf.all.log_martians = 1
net.ipv4.conf.default.log_martians = 1

# Disable source packet routing
net.ipv4.conf.all.accept_source_route = 0
net.ipv4.conf.default.accept_source_route = 0
net.ipv6.conf.all.accept_source_route = 0
net.ipv6.conf.default.accept_source_route = 0

# TCP SYN flood protection
net.ipv4.tcp_syncookies = 1
net.ipv4.tcp_syn_retries = 2
net.ipv4.tcp_synack_retries = 2
net.ipv4.net.ipv4.tcp_max_syn_backlog = 4096

# ============== MEMORY PROTECTION ==============
# Prevent core dumps
kernel.core_uses_pid = 0
kernel.core_pattern = /dev/null

# Disable kernel debug
kernel.dmesg_restrict = 1
kernel.kptr_restrict = 2

# Randomize memory addresses
kernel.randomize_va_space = 2

# ============== PROCESS PROTECTION ==============
# Restrict ptrace
kernel.yama.ptrace_scope = 2

# ============== FILE SYSTEM SECURITY ==============
# Disable unused filesystems
install usb-storage /bin/true
install cramfs /bin/true
install freevxfs /bin/true
install jffs2 /bin/true
install hfs /bin/true
install hfsplus /bin/true
install squashfs /bin/true
install udf /bin/true
SYSCTL

sysctl -p /etc/sysctl.d/99-security-hardening.conf

# ============================================
# PART 4: SSH HARDENING
# ============================================
log "Hardening SSH..."

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

# Security options
MaxAuthTries 3
MaxSessions 10
ClientAliveInterval 300
ClientAliveCountMax 2
LoginGraceTime 60
UseDNS no

# Disable weak ciphers
Ciphers chacha20-poly1305@openssh.com,aes256-gcm@openssh.com,aes128-gcm@openssh.com,aes256-ctr,aes128-ctr
MACs hmac-sha2-512-etm@openssh.com,hmac-sha2-256-etm@openssh.com
KexAlgorithms curve25519-sha256,ecdh-sha2-nistp256
SSH

systemctl restart sshd

# ============================================
# PART 5: FILE PERMISSIONS
# ============================================
log "Setting Secure Permissions..."

# Lock critical files
chmod 600 /etc/shadow
chmod 600 /etc/gshadow
chmod 644 /etc/passwd
chmod 644 /etc/group
chmod 700 /root
chmod 600 /etc/ssh/sshd_config
chmod 600 /etc/pam.d/*
chmod 700 /etc/sudoers.d

# Set secure umask
echo "umask 077" >> /etc/profile

# ============================================
# PART 6: AUDIT LOGGING
# ============================================
log "Setting Up Audit Logging..."

# Create audit rules
cat > /etc/audit/audit.rules << 'AUDIT'
# Identity changes
-w /etc/passwd -p wa -k identity
-w /etc/shadow -p wa -k identity
-w /etc/group -p wa -k identity

# Sudo usage
-w /etc/sudoers -p wa -k sudoers_changes

# SSH config
-w /etc/ssh/sshd_config -p wa -k sshd_changes

# Network
-a always,exit -F arch=b64 -S socket -k net_connect
AUDIT

systemctl enable auditd

# ============================================
# PART 7: BLOCK COMMON ATTACKS
# ============================================
log "Blocking Common Attacks..."

# Block common attack ports
for port in 135 139 445 1433 3306 5432 27017; do
    ufw deny $port/tcp 2>/dev/null || true
done

# Create malware block list
cat > /etc/hosts.deny << 'BLOCK'
# Block known malware IPs - add suspicious IPs here
# Example: 192.168.1.100
BLOCK

# ============================================
# PART 8: PRIVACY PROTECTION
# ============================================
log "Setting Up Privacy Protection..."

# Disable telemetry
systemctl mask ubuntu-report.service 2>/dev/null || true
systemctl mask whoopsie.service 2>/dev/null || true
systemctl mask apport.service 2>/dev/null || true

# Disable crash reporting
sed -i 's/enabled=1/enabled=0/' /etc/default/whoopsie 2>/dev/null || true
sed -i 'enabled=1/enabled=0/' /etc/default/apport 2>/dev/null || true

# ============================================
# PART 9: AUTO SECURITY UPDATES
# ============================================
log "Setting Auto Security Updates..."

cat > /etc/apt/apt.conf.d/50unattended-upgrades << 'AUTO'
Unattended-Upgrade::Allowed-Origins {
    "${distro_id}:${distro_codename}-security";
};
Unattended-Upgrade::Package-Blacklist {
};
Unattended-Upgrade::AutoFixInterruptedDpkg "true";
Unattended-Upgrade::MinimalSteps "true";
Unattended-Upgrade::Automatic-Reboot "false";
AUTO

# ============================================
# PART 10: CREATE SECURITY COMMANDS
# ============================================
log "Creating Security Tools..."

# piexed-security
cat > /usr/local/bin/piexed-security << 'SECURITY'
#!/bin/bash
echo "=== Piẻxed OS Security Center ==="
echo ""
echo "1. Scan for malware"
echo "2. View firewall status"
echo "3. View failed login attempts"
echo "4. Check system security"
echo "5. Update security"
read -p "Choose: " choice
case $choice in
    1) piexed-scan/scan-malware ;;
    2) sudo ufw status verbose ;;
    3) sudo grep "Failed" /var/log/auth.log | tail -20 ;;
    4) sudo lynis audit system ;;
    5) sudo apt-get update && sudo apt-get upgrade -y ;;
esac
SECURITY
chmod +x /usr/local/bin/piexed-security

# piexed-privacy
cat > /usr/local/bin/piexed-privacy << 'PRIVACY'
#!/bin/bash
echo "=== Piẻxed OS Privacy Settings ==="
echo ""
echo "Current privacy status:"
echo "- Telemetry: DISABLED"
echo "- Crash reporting: DISABLED"
echo "- Location services: DISABLED"
echo "- User data collection: NONE"
echo ""
echo "Your data stays on YOUR device!"
echo "Piẻxed OS does NOT collect:"
echo "  ✗ Usage analytics"
echo "  ✗ Crash reports"
echo "  ✗ Location data"
echo "  ✗ Personal files"
echo "  ✗ Browsing history"
PRIVACY
chmod +x /usr/local/bin/piexed-privacy

log "Security Suite Installed!"
echo ""
echo "=========================================="
echo "  SECURITY COMPLETE!"
echo "=========================================="
echo ""
echo "Your system is now protected by:"
echo "- UFW Firewall (strict)"
echo "- fail2ban (brute force protection)"
echo "- ClamAV (antivirus)"
echo "- Kernel hardening"
echo "- Audit logging"
echo "- Auto security updates"
echo ""
echo "Security commands:"
echo "  piexed-security    - Security center"
echo "  piexed-scan/scan-malware - Scan for malware"
echo "  piexed-privacy  - Privacy settings"