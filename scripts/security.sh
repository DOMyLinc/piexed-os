#!/bin/bash
#
# Piẻxed OS Security Suite
# Advanced security features for robust protection
#

set -e

echo "=== Piẻxed OS Security Suite ==="
echo ""

# Create security directories
mkdir -p /etc/piexed/security
mkdir -p /var/log/piexed/security

# 1. Firewall Configuration (UFW)
configure_firewall() {
    echo "[1/10] Configuring firewall..."

    # Install UFW if not present
    if ! command -v ufw &> /dev/null; then
        apt-get install -y ufw
    fi

    # Configure UFW defaults
    ufw --force enable
    ufw default deny incoming
    ufw default allow outgoing
    ufw default allow routed

    # Allow SSH
    ufw allow 22/tcp comment 'SSH'

    # Allow common services
    ufw allow 80/tcp comment 'HTTP'
    ufw allow 443/tcp comment 'HTTPS'
    ufw allow 3000/tcp comment 'Development servers'
    ufw allow 5000/tcp comment 'Development servers'

    # Enable UFW
    systemctl enable ufw
    ufw --force enable

    echo "Firewall configured successfully"
}

# 2. AppArmor Configuration
configure_apparmor() {
    echo "[2/10] Configuring AppArmor..."

    # Install AppArmor
    apt-get install -y apparmor apparmor-utils

    # Enable AppArmor
    aa-status --enabled || aa-complain /etc/apparmor.d/*

    # Configure profiles
    systemctl enable apparmor

    # Create custom profiles directory
    mkdir -p /etc/apparmor.d/local

    echo "AppArmor configured successfully"
}

# 3. Fail2Ban Configuration
configure_fail2ban() {
    echo "[3/10] Configuring Fail2Ban..."

    # Install Fail2Ban
    apt-get install -y fail2ban

    # Create Fail2Ban configuration
    cat > /etc/fail2ban/jail.local << 'EOF'
[DEFAULT]
bantime = 3600
findtime = 600
maxretry = 5
destemail = root@localhost
sender = fail2ban@piexed-os

[sshd]
enabled = true
port = ssh
filter = sshd
logpath = /var/log/auth.log
maxretry = 3

[apache-auth]
enabled = true
port = http,https
filter = apache-auth
logpath = /var/log/apache*/error.log
maxretry = 5

[apache-badbots]
enabled = true
port = http,https
filter = apache-badbots
logpath = /var/log/apache*/access.log
maxretry = 2

[nginx-http-auth]
enabled = false
port = http,https
filter = nginx-http-auth
logpath = /var/log/nginx/error.log
EOF

    # Enable and start Fail2Ban
    systemctl enable fail2ban
    systemctl start fail2ban

    echo "Fail2Ban configured successfully"
}

# 4. ClamAV Antivirus
configure_clamav() {
    echo "[4/10] Configuring ClamAV..."

    # Install ClamAV
    apt-get install -y clamav clamav-daemon

    # Update virus definitions
    systemctl stop clamav-freshclam
    freshclam
    systemctl start clamav-freshclam

    # Create scheduled scan script
    cat > /usr/local/bin/piexed-antivirus-scan << 'EOF'
#!/bin/bash
# Piẻxed OS Antivirus Scanner

SCAN_DIRS="/home /tmp /var"
LOG_FILE="/var/log/piexed/security/antivirus.log"

echo "Starting antivirus scan at $(date)" | tee -a $LOG_FILE
echo "=========================================" | tee -a $LOG_FILE

# Scan home directories
clamscan -r --remove $SCAN_DIRS 2>&1 | tee -a $LOG_FILE

# Update log
echo "Scan completed at $(date)" | tee -a $LOG_FILE
echo "" | tee -a $LOG_FILE
EOF

    chmod +x /usr/local/bin/piexed-antivirus-scan

    # Create cron job for daily scan
    echo "0 3 * * * root /usr/local/bin/piexed-antivirus-scan" > /etc/cron.d/piexed-antivirus

    # Enable and start ClamAV
    systemctl enable clamav-daemon
    systemctl start clamav-daemon

    echo "ClamAV configured successfully"
}

# 5. Encrypted Home Directory
configure_ecryptfs() {
    echo "[5/10] Configuring encrypted home directories..."

    # Install ecryptfs
    apt-get install -y ecryptfs-utils

    # Enable PAM module
    sed -i 's/#ecryptfs-wrap-file-systems/ecryptfs-wrap-file-systems/' /etc/default/ecryptfs-utils 2>/dev/null || true

    echo "Encrypted home directory support configured"
}

# 6. Secure Boot Configuration
configure_secure_boot() {
    echo "[6/10] Configuring Secure Boot..."

    # Install shim-signed for Secure Boot
    apt-get install -y shim-signed grub-efi-amd64-signed

    # Create Secure Boot recovery script
    cat > /usr/local/bin/piexed-secureboot-recovery << 'EOF'
#!/bin/bash
# Secure Boot Recovery Tool

echo "=== Piẻxed OS Secure Boot Recovery ==="
echo ""

echo "Checking Secure Boot status..."
mokutil --sb-state

echo ""
echo "Enrolling MOK (Machine Owner Key)..."
mokutil --import /var/lib/shim-signed/mok/MOK.der

echo ""
echo "Please restart and complete MOK enrollment in MOK Manager"
EOF

    chmod +x /usr/local/bin/piexed-secureboot-recovery

    echo "Secure Boot configuration ready"
}

# 7. Rootkit Detection
configure_rkhunter() {
    echo "[7/10] Configuring Rootkit Hunter..."

    # Install rkhunter
    apt-get install -y rkhunter

    # Configure rkhunter
    cat > /etc/rkhunter.conf.local << 'EOF'
UPDATE_COMMANDS=1
CRON_DAILY_RUN=1
CRON_WEEKLY_RUN=1
ENABLE_TCP=1
ALLOW_SSH_ROOT_USER=0
ALLOW_SSH_PROT_V1=0
PORT_WHITELIST=22
EOF

    # Update rkhunter database
    rkhunter --update
    rkhunter --propupd

    # Create scan script
    cat > /usr/local/bin/piexed-rootkit-scan << 'EOF'
#!/bin/bash
# Piẻxed OS Rootkit Scanner

LOG_FILE="/var/log/piexed/security/rkhunter.log"

echo "Starting rootkit scan at $(date)" | tee -a $LOG_FILE
echo "=========================================" | tee -a $LOG_FILE

rkhunter --check --skip-keypress 2>&1 | tee -a $LOG_FILE

echo "Scan completed at $(date)" | tee -a $LOG_FILE
EOF

    chmod +x /usr/local/bin/piexed-rootkit-scan

    # Schedule weekly scan
    echo "0 4 * * 0 root /usr/local/bin/piexed-rootkit-scan" > /etc/cron.d/piexed-rootkit

    echo "Rootkit Hunter configured successfully"
}

# 8. Audit System
configure_audit() {
    echo "[8/10] Configuring Audit System..."

    # Install auditd
    apt-get install -y auditd

    # Configure audit rules
    cat > /etc/audit/rules.d/piexed.rules << 'EOF'
# Watch system calls
-a always,exit -F arch=b64 -S mount -S umount2 -S mount -S umount -k mount
-a always,exit -F arch=b64 -S ptrace -k trace
-a always,exit -F arch=b64 -S adjtimex -S settimeofday -k time-change
-a always,exit -F arch=b64 -S clock_settime -k time-change
-a always,exit -F arch=b64 -S sethostname -S setdomainname -k hostname
-a always,exit -F arch=b64 -S unlink -S unlinkat -S rename -S renameat -k delete
-a always,exit -F arch=b64 -S chmod -S fchmod -S fchmodat -k perms_chmod
-a always,exit -F arch=b64 -S creat -S open -S openat -S openat2 -F exit=EPERM -k access
-w /etc/passwd -p wa -k passwd_modify
-w /etc/shadow -p wa -k shadow_modify
-w /etc/group -p wa -k group_modify
-w /etc/gshadow -p wa -k gshadow_modify
-w /etc/sudoers -p wa -k sudoers_modify
EOF

    # Enable and start auditd
    systemctl enable auditd
    systemctl start auditd

    echo "Audit system configured successfully"
}

# 9. Privacy Configuration
configure_privacy() {
    echo "[9/10] Configuring Privacy Settings..."

    # Create privacy configuration
    cat > /etc/profile.d/piexed-privacy.sh << 'EOF'
# Piẻxed OS Privacy Configuration

# Disable hostname revelation
echo 0 > /proc/sys/kernel/yama/ptrace_scope 2>/dev/null || true

# Disable ICMP redirects
echo 0 > /proc/sys/net/ipv4/conf/all/accept_redirects 2>/dev/null || true
echo 0 > /proc/sys/net/ipv6/conf/all/accept_redirects 2>/dev/null || true

# Disable source routing
echo 0 > /proc/sys/net/ipv4/conf/all/accept_source_route 2>/dev/null || true
echo 0 > /proc/sys/net/ipv6/conf/all/accept_source_route 2>/dev/null || true

# Enable TCP SYN cookies
echo 1 > /proc/sys/net/ipv4/tcp_syncookies 2>/dev/null || true

# Disable IP forwarding
echo 0 > /proc/sys/net/ipv4/ip_forward 2>/dev/null || true
echo 0 > /proc/sys/net/ipv6/ip_forward 2>/dev/null || true
EOF

    # Configure Zeitgeist (activity tracker) privacy
    if command -v zeitgeist-daemon &> /dev/null; then
        zeitgeist-daemon --quit 2>/dev/null || true
    fi

    echo "Privacy settings configured"
}

# 10. Security Updates
configure_security_updates() {
    echo "[10/10] Configuring automatic security updates..."

    # Install unattended-upgrades
    apt-get install -y unattended-upgrades

    # Configure automatic updates
    cat > /etc/apt/apt.conf.d/50unattended-upgrades << 'EOF'
Unattended-Upgrade::Allowed-Origins {
    "${distro_id}:${distro_codename}";
    "${distro_id}:${distro_codename}-security";
    "${distro_id}:${distro_codename}-updates";
};

Unattended-Upgrade::DevRelease "auto";
Unattended-Upgrade::Remove-Unused-Dependencies "true";
Unattended-Upgrade::Automatic-Reboot "true";
Unattended-Upgrade::Automatic-Reboot-Time "02:00";
Unattended-Upgrade::Mail "root";
Unattended-Upgrade::MailReport "on-change";
EOF

    # Enable automatic updates
    cat > /etc/apt/apt.conf.d/20auto-upgrades << 'EOF'
APT::Periodic::Update-Package-Lists "1";
APT::Periodic::Download-Upgradeable-Packages "1";
APT::Periodic::Unattended-Upgrade "1";
APT::Periodic::AutocleanInterval "7";
EOF

    # Enable unattended-upgrades
    systemctl enable unattended-upgrades

    echo "Automatic security updates configured"
}

# Create security center application
create_security_center() {
    echo "Creating security center application..."

    mkdir -p /usr/share/applications
    mkdir -p /usr/local/bin/piexed-security-center

    # Create security center launcher
    cat > /usr/local/bin/piexed-security-center << 'EOF'
#!/bin/bash
# Piẻxed OS Security Center

yad --title="Piẻxed OS Security Center" \
    --window-icon="security" \
    --width=600 --height=400 \
    --center \
    --text="<b><span size='xx-large'>Piẻxed OS Security Center</span></b>\n\n" \
    --form \
    --field="Firewall Status:FBTN" "bash:ufw status | head -5" \
    --field="AppArmor Status:FBTN" "bash:aa-status --enabled && echo 'Enabled' || echo 'Disabled'" \
    --field="Fail2Ban Status:FBTN" "bash:systemctl status fail2ban | grep Active" \
    --field="ClamAV Status:FBTN" "bash:systemctl status clamav-daemon | grep Active" \
    --field="Run Antivirus Scan:FBTN" "bash:/usr/local/bin/piexed-antivirus-scan" \
    --field="Run Rootkit Scan:FBTN" "bash:/usr/local/bin/piexed-rootkit-scan" \
    --field="View Security Logs:FBTN" "bash:xdg-open /var/log/piexed/security" \
    --field="Configure Firewall:FBTN" "bash:sudo ufw status verbose" \
    --field="Security Updates:FBTN" "bash:sudo apt list --upgradable | grep -i security"
EOF

    chmod +x /usr/local/bin/piexed-security-center

    # Create desktop entry
    cat > /usr/share/applications/piexed-security-center.desktop << 'EOF'
[Desktop Entry]
Name=Piexed Security Center
Comment=Manage security settings and tools
Exec=pkexec /usr/local/bin/piexed-security-center
Icon=security
Terminal=false
Type=Application
Categories=System;Security;
EOF

    echo "Security center created"
}

# Main execution
main() {
    configure_firewall
    configure_apparmor
    configure_fail2ban
    configure_clamav
    configure_ecryptfs
    configure_secure_boot
    configure_rkhunter
    configure_audit
    configure_privacy
    configure_security_updates
    create_security_center

    echo ""
    echo "=== Security Suite Installation Complete ==="
    echo ""
    echo "Security features installed:"
    echo "  - UFW Firewall"
    echo "  - AppArmor"
    echo "  - Fail2Ban"
    echo "  - ClamAV Antivirus"
    echo "  - Encrypted Home Support"
    echo "  - Secure Boot Support"
    echo "  - Rootkit Hunter"
    echo "  - Audit System"
    echo "  - Privacy Settings"
    echo "  - Automatic Security Updates"
    echo ""
    echo "Run 'piexed-security-center' to access security tools"
}

main "$@"