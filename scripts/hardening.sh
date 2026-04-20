#!/bin/bash
#
# Piẻxed OS - Security Hardening Script
# Professional security for production use
#

set -e

RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m'

log_info() { echo -e "${GREEN}[+]${NC} $1"; }
log_warn() { echo -e "${YELLOW}[!]${NC} $1"; }

echo "=== Piẻxed OS Security Hardening ==="
echo ""

# Update system
log_info "Updating system packages..."
apt-get update && apt-get upgrade -y

# Install security tools
log_info "Installing security tools..."
apt-get install -y \
    ufw \
    fail2ban \
    rkhunter \
    chkrootkit \
    lynis \
    auditd \
    aide \
    libpam-pwquality \
    libpam-tmpdir \
    libpam-umask \
    prelink \
    sysstat

# Configure UFW Firewall
log_info "Configuring firewall (UFW)..."
ufw --force reset
ufw default deny incoming
ufw default allow outgoing
ufw allow ssh/tcp
ufw allow 22/tcp
ufw enable

# Configure fail2ban
log_info "Configuring fail2ban..."
cat > /etc/fail2ban/jail.local << 'EOF'
[DEFAULT]
bantime = 3600
findtime = 600
maxretry = 3
destemail = admin@localhost
sender = fail2ban@localhost
action = %(action_mwl)s

[sshd]
enabled = true
port = ssh
filter = sshd
logpath = /var/log/auth.log
maxretry = 3
bantime = 3600

[nginx-http-auth]
enabled = true
filter = nginx-http-auth
port = http,https
logpath = /var/log/nginx/error.log

[php-url-fopen]
enabled = true
port = http,https
filter = php-url-fopen
logpath = /var/log/apache2/access.log
maxretry = 1
EOF

systemctl enable fail2ban
systemctl start fail2ban

# Configure sysctl hardening
log_info "Configuring kernel hardening..."
cat > /etc/sysctl.d/99-security.conf << 'EOF'
# Kernel hardening
kernel.dmesg_restrict = 1
kernel.kptr_restrict = 2
kernel.yama.ptrace_scope = 2
kernel.panic = 10
kernel.panic_on_oops = 1

# Network hardening
net.ipv4.tcp_timestamps = 1
net.ipv4.tcp_sack = 1
net.ipv4.conf.all.rp_filter = 1
net.ipv4.conf.default.rp_filter = 1
net.ipv4.icmp_echo_ignore_broadcasts = 1
net.ipv4.icmp_ignore_bogus_error_responses = 1
net.ipv4.conf.all.accept_redirects = 0
net.ipv4.conf.default.accept_redirects = 0
net.ipv4.conf.all.send_redirects = 0
net.ipv4.conf.default.send_redirects = 0
net.ipv4.conf.all.accept_source_route = 0
net.ipv4.conf.default.accept_source_route = 0
net.ipv4.conf.all.log_martians = 1
net.ipv4.conf.default.log_martians = 1
net.ipv6.conf.all.accept_redirects = 0
net.ipv6.conf.default.accept_redirects = 0
net.ipv6.conf.all.accept_source_route = 0
net.ipv6.conf.default.accept_source_route = 0

# Memory protection
vm.mmap_min_addr = 65536
vm.swappiness = 10
vm.dirty_ratio = 15
vm.dirty_background_ratio = 5
EOF

sysctl -p /etc/sysctl.d/99-security.conf

# Configure password policy
log_info "Configuring password policy..."
cat > /etc/pam.d/common-password << 'EOF'
password    required    pam_pwquality.so retry=3 minlen=12 difok=3 ucredit=-1 lcredit=-1 dcredit=-1 ocredit=-1
password    required    pam_unix.so sha512 use_authtok
EOF

# Configure login permissions
log_info "Configuring login security..."
cat > /etc/pam.d/login << 'EOF'
auth        required      pam_faildelay.so delay=3000000
auth        requisite     pam_unix.so nullok
auth        optional      pam_permit.so
account     required      pam_unix.so
session     required      pam_loginuid.so
session     optional      pam_keyinit.so force revoke
session     required      pam_unix.so
session     optional      pam_permit.so
EOF

# SSH hardening
log_info "Hardening SSH..."
sed -i 's/^#*PermitRootLogin.*/PermitRootLogin no/' /etc/ssh/sshd_config
sed -i 's/^#*PasswordAuthentication.*/PasswordAuthentication yes/' /etc/ssh/sshd_config
sed -i 's/^#*X11Forwarding.*/X11Forwarding no/' /etc/ssh/sshd_config
sed -i 's/^#*PermitEmptyPasswords.*/PermitEmptyPasswords no/' /etc/ssh/sshd_config
sed -i 's/^#*ClientAliveInterval.*/ClientAliveInterval 300/' /etc/ssh/sshd_config
sed -i 's/^#*ClientAliveCountMax.*/ClientAliveCountMax 2/' /etc/ssh/sshd_config

echo "AllowUsers piexed" >> /etc/ssh/sshd_config
systemctl restart sshd

# File permissions
log_info "Setting secure file permissions..."
chmod 600 /etc/shadow
chmod 600 /etc/gshadow
chmod 644 /etc/passwd
chmod 644 /etc/group
chmod 700 /root
chmod 600 /etc/ssh/sshd_config
chmod 600 /etc/pam.d/*
find /bin /sbin /usr/bin /usr/sbin -perm -4000 -exec chmod u+s {} \; 2>/dev/null || true

# Configure audit rules
log_info "Configuring audit rules..."
cat > /etc/audit/audit.rules << 'EOF'
-w /etc/passwd -p wa -k identity
-w /etc/shadow -p wa -k identity
-w /etc/group -p wa -k identity
-w /etc/sudoers -p wa -k sudoers_changes
-w /etc/ssh/sshd_config -p wa -k sshd_changes
-w /etc/ufw -p wa -k ufw_changes
-w /etc/fail2ban -p wa -k fail2ban_changes
-a always,exit -F arch=b64 -S adjtimex -S settimeofday -k time-change
-a always,exit -F arch=b64 -S clock_settime -k time-change
-w /etc/localtime -p wa -k time-change
EOF

systemctl enable auditd

# Configure AIDE
log_info "Initializing AIDE..."
aide --init
mv /var/lib/aide/aide.db.new /var/lib/aide/aide.db

# Configure rkhunter
log_info "Configuring rkhunter..."
cat > /etc/rkhunter.conf.local << 'EOF'
MAIL-ON-WARNING=root@localhost
ENABLE_TESTS=ALL
DISABLE_TESTS=usrsbininetd,systemd_functions
EOF

# Configure automatic security updates
log_info "Configuring automatic security updates..."
cat > /etc/apt/apt.conf.d/20auto-upgrades << 'EOF'
APT::Periodic::Update-Package-Lists "1";
APT::Periodic::Download-Upgradeable-Packages "1";
APT::Periodic::AutocleanInterval "7";
APT::Periodic::Unattended-Upgrade "1";
EOF

cat > /etc/apt/apt.conf.d/50unattended-upgrades << 'EOF'
Unattended-Upgrade::Allowed-Origins {
    "${distro_id}:${distro_codename}-security";
    "${distro_id}:${distro_codename}-updates";
};
Unattended-Upgrade::Package-Blacklist {
};
Unattended-Upgrade::AutoFixInterruptedDpkg "true";
Unattended-Upgrade::MinimalSteps "true";
Unattended-Upgrade::InstallOnShutdown "true";
Unattended-Upgrade::Mail "root@localhost";
Unattended-Upgrade::MailOnlyOnError "true";
Unattended-Upgrade::Remove-Unused-Kernel-Packages "true";
Unattended-Upgrade::Remove-New-Unused-Dependencies "true";
Unattended-Upgrade::Automatic-Reboot "false";
EOF

# Create security log directory
mkdir -p /var/log/security
chmod 700 /var/log/security

echo ""
log_info "Security hardening completed!"
echo ""
echo "Summary:"
echo "  - Firewall (UFW) enabled"
echo "  - fail2ban configured"
echo "  - Kernel hardened"
echo "  - SSH secured"
echo "  - Audit logging enabled"
echo "  - Automatic updates enabled"
echo ""
echo "Please reboot for all changes to take effect."
