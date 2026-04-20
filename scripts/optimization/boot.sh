#!/bin/bash
#
# Piexed OS Boot Optimization Script
# Optimizes boot time for low-end hardware
#

set -e

echo "=== Piexed OS Boot Optimization ==="

# Configure systemd for faster boot
mkdir -p /etc/systemd/system.conf.d

cat > /etc/systemd/system.conf.d/piexed-boot.conf << 'EOF'
[Manager]
# Faster boot
DefaultTimeoutStartSec=30s
DefaultTimeoutStopSec=30s
DefaultRestartUSec=100ms

# Optimize CPU scheduler
CPUAffinity=0 1

# Network
[Network]
# Faster network online
OnlineTimeout=10s
EOF

# Configure services to start in parallel
cat >> /etc/systemd/system.conf.d/piexed-boot.conf << 'EOF'

# Services
[Unit]
After=network-online.target
Wants=network-online.target
EOF

# Disable unnecessary services for low-end hardware
SERVICES_TO_DISABLE=(
    "thermald"
    "bluetooth"
    "cups"
    "apache2"
    "nginx"
    "snapd.apparmor"
)

for service in "${SERVICES_TO_DISABLE[@]}"; do
    systemctl mask ${service} 2>/dev/null || true
done

# Enable only necessary services
SERVICES_TO_ENABLE=(
    "NetworkManager"
    "lightdm"
    "cron"
    "rsyslog"
)

for service in "${SERVICES_TO_ENABLE[@]}"; do
    systemctl enable ${service} 2>/dev/null || true
done

# Configure Plymouth for faster boot
mkdir -p /etc/systemd/system
cat > /etc/systemd/system/plymouth-start.service << 'EOF'
[Unit]
Description=Plymouth Boot Splash
DefaultDependencies=no
After=local-fs.target
Before=basic.target

[Service]
ExecStart=/usr/sbin/plymouthd --mode=boot --theme=piexed
ExecStartPost=-/usr/bin/plymouth show-splash
Type=oneshot
RemainAfterExit=yes

[Install]
WantedBy=basic.target
EOF

# Configure GRUB for faster boot
cat > /etc/default/grub.piexed << 'EOF'
GRUB_DEFAULT=0
GRUB_TIMEOUT=5
GRUB_TIMEOUT_STYLE=hidden
GRUB_DISTRIBUTOR='Piexed OS'
GRUB_GFXMODE=1280x720
GRUB_GFXPAYLOAD=keep
GRUB_CMDLINE_LINUX_DEFAULT="quiet splash loglevel=3 zram.enabled=1"
GRUB_CMDLINE_LINUX="zram.enabled=1 zram.fraction=0.5"
EOF

# Update GRUB
update-grub 2>/dev/null || grub-mkconfig -o /boot/grub/grub.cfg

# Configure initramfs
cat >> /etc/initramfs-tools/conf.d/compression.conf << 'EOF'
COMPRESS=xz
COMPRESSORITY=6
EOF

# Update initramfs
update-initramfs -u

echo "Boot optimization completed!"
echo "GRUB timeout reduced to 5 seconds."
echo "Services optimized for faster startup."