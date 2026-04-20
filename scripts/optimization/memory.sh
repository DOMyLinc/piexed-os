#!/bin/bash
#
# Piexed OS Memory Optimization Script
# Optimized for 1GB RAM systems
#

set -e

echo "=== Piexed OS Memory Optimization ==="
echo "Configuring system for low-memory usage..."

# Configure swappiness
echo 10 > /proc/sys/vm/swappiness
echo "vm.swappiness = 10" >> /etc/sysctl.conf

# Configure cache pressure
echo 60 > /proc/sys/vm/vfs_cache_pressure
echo "vm.vfs_cache_pressure = 60" >> /etc/sysctl.conf

# Configure overcommit memory (useful for memory-intensive applications)
echo 1 > /proc/sys/vm/overcommit_memory
echo "vm.overcommit_memory = 1" >> /etc/sysctl.conf

# Configure overcommit ratio
echo 50 > /proc/sys/vm/overcommit_ratio
echo "vm.overcommit_ratio = 50" >> /etc/sysctl.conf

# Disable crash dumps to save memory
mkdir -p /etc/systemd/coredump.conf.d
cat > /etc/systemd/coredump.conf.d/piexed.conf << 'EOF'
[Coredump]
Storage=none
SizeMax=0
EOF

# Configure journal for low-memory usage
mkdir -p /etc/systemd/journald.conf.d
cat > /etc/systemd/journald.conf.d/piexed.conf << 'EOF'
[Journal]
SystemMaxUse=100M
SystemMaxFileSize=10M
MaxLevelStore=warning
MaxLevelSyslog=warning
MaxLevelKMsg=warning
EOF

# Configure TMPFS for /tmp (uses RAM instead of disk)
cat >> /etc/fstab << 'EOF'

# Piexed OS - tmpfs for /tmp (memory-based)
tmpfs                                     /tmp              tmpfs   nosuid,nodev,size=256M              0  0
EOF

# Configure preload (preload frequently used applications)
if command -v preload &> /dev/null; then
    mkdir -p /var/lib/preload
    preload --once
fi

# Configure earlyoom (stop processes when memory is low)
if command -v earlyoom &> /dev/null; then
    cat > /etc/default/earlyoom << 'EOF'
# Piexed OS EarlyOOM Configuration
EARLYOOM_ARGS="-m 100 -r 60 -o"
EOF
    systemctl enable earlyoom
fi

# Optimize kernel for low-memory
cat >> /etc/sysctl.conf << 'EOF'

# Piexed OS Low-Memory Optimizations
# Reduce disk cache pressure to favor free memory
vm.dirty_ratio = 15
vm.dirty_background_ratio = 5
vm.dirty_expire_centisecs = 500

# Improve responsiveness under low memory conditions
vm.page-cluster = 3
EOF

# Configure zram (compressed memory)
mkdir -p /etc/systemd/system
cat > /etc/systemd/system/zram.service << 'EOF'
[Unit]
Description=Piexed OS zRAM-based compressed swap

[Service]
Type=oneshot
ExecStartPre=/sbin/modprobe zram
ExecStart=/sbin/mkswap /dev/zram0
ExecStart=/sbin/swapon -p 100 /dev/zram0

[Install]
WantedBy=multi-user.target
EOF

# Create zram config
cat > /etc/default/zram-config << 'EOF'
# Piexed OS zRAM Configuration
# Use 50% of RAM as compressed swap
FRACTION=0.5
ALGO=lzo
EOF

echo "Memory optimization completed!"
echo "Please reboot for changes to take effect."