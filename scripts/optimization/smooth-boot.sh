#!/bin/bash
# Piẻxed OS - Smooth Boot Optimization
# Optimizes system for smooth, fast boot like macOS

set -e

echo "=== Piẻxed OS Smooth Boot Optimization ==="

# Disable plymouth if not needed
sudo systemctl mask plymouth-quit.service 2>/dev/null || true
sudo systemctl mask plymouth-quit-wait.service 2>/dev/null || true
sudo systemctl mask plymouth-start.service 2>/dev/null || true

# Optimize GRUB for fast boot
sudo tee /etc/default/grub.d/99-piexed-fastboot.cfg > /dev/null << 'EOF'
GRUB_TIMEOUT=2
GRUB_TIMEOUT_STYLE=hidden
GRUB_HIDDEN_TIMEOUT=2
GRUB_HIDDEN_TIMEOUT_QUIET=true
GRUB_CMDLINE_LINUX_DEFAULT="quiet splash loglevel=3 mitigations=off elevator=noop"
EOF

# Optimize kernel boot parameters
sudo tee /etc/default/grub.d/98-piexed-kernel.cfg > /dev/null << 'EOF'
GRUB_CMDLINE_LINUX_DEFAULT="quiet splash loglevel=3 mitigations=off elevator=noop nvme.noacpi=1"
EOF

sudo update-grub

# Disable unnecessary services
sudo systemctl disable cups.service 2>/dev/null || true
sudo systemctl disable cups.socket 2>/dev/null || true
sudo systemctl disable cups.path 2>/dev/null || true
sudo systemctl disable bluetooth.service 2>/dev/null || true

# Enable parallel boot
sudo systemctl set-default multi-user.target

# Optimize filesystem
echo "noop" | sudo tee /sys/block/sda/queue/scheduler 2>/dev/null || true
echo "0" | sudo tee /sys/block/sda/queue/add_random 2>/dev/null || true

# Optimize network
echo "1" | sudo tee /proc/sys/net/ipv4/tcp_timestamps 2>/dev/null || true
echo "1" | sudo tee /proc/sys/net/ipv4/tcp_sack 2>/dev/null || true
echo "2" | sudo tee /proc/sys/net/ipv4/tcp_fack_timeout 2>/dev/null || true

# Optimize memory
echo "10" | sudo tee /proc/sys/vm/swappiness 2>/dev/null || true

echo "Smooth boot optimization applied!"
echo "Reboot to apply changes."