#!/bin/bash
#
# Piẻxed OS System Utilities
# Optimized for low-end hardware
#

set -e

echo "=== Piẻxed OS System Utilities ==="

# System Monitor
cat > /usr/local/bin/piexed-system-monitor << 'EOF'
#!/bin/bash
# Piẻxed OS System Monitor - Low resource usage

while true; do
    clear
    echo "╔══════════════════════════════════════════════════════════╗"
    echo "║              PIEXED OS SYSTEM MONITOR                     ║"
    echo "╠══════════════════════════════════════════════════════════╣"

    # System info
    echo -n "║ "
    uname -srn | head -c 56
    echo " ║"

    echo "╠══════════════════════════════════════════════════════════╣"
    echo "║ CPU                                                          ║"

    # CPU usage
    cpu_usage=$(top -bn1 | grep "Cpu(s)" | awk '{print $2}' | sed 's/%us,//')
    cpu_usage=${cpu_usage:-0}
    cpu_bar=$(printf "%.0s█" $(seq 1 $((cpu_usage / 5))) 2>/dev/null)
    cpu_empty=$(printf "%.0s░" $(seq 1 $((20 - cpu_usage / 5))) 2>/dev/null)
    echo "║ Usage: [$cpu_bar$cpu_empty] ${cpu_usage}%              ║"

    # Temperature
    if [ -f /sys/class/thermal/thermal_zone0/temp ]; then
        temp=$(cat /sys/class/thermal/thermal_zone0/temp)
        temp=$((temp / 1000))
        echo "║ Temperature: ${temp}°C                                        ║"
    fi

    echo "╠══════════════════════════════════════════════════════════╣"
    echo "║ MEMORY                                                       ║"

    # Memory usage
    mem_total=$(free -m | awk 'NR==2{print $2}')
    mem_used=$(free -m | awk 'NR==2{print $3}')
    mem_percent=$((mem_used * 100 / mem_total))
    mem_bar=$(printf "%.0s█" $(seq 1 $((mem_percent / 5))) 2>/dev/null)
    mem_empty=$(printf "%.0s░" $(seq 1 $((20 - mem_percent / 5))) 2>/dev/null)
    echo "║ [$mem_bar$mem_empty]         ║"
    echo "║ Used: ${mem_used}MB / ${mem_total}MB                             ║"

    # Swap usage
    swap_total=$(free -m | awk 'NR==3{print $2}')
    if [ "$swap_total" -gt 0 ]; then
        swap_used=$(free -m | awk 'NR==3{print $3}')
        echo "║ Swap: ${swap_used}MB / ${swap_total}MB                            ║"
    fi

    echo "╠══════════════════════════════════════════════════════════╣"
    echo "║ DISK                                                          ║"

    # Disk usage
    disk_usage=$(df -h / | awk 'NR==2{print $5}' | tr -d '%')
    disk_bar=$(printf "%.0s█" $(seq 1 $((disk_usage / 5))) 2>/dev/null)
    disk_empty=$(printf "%.0s░" $(seq 1 $((20 - disk_usage / 5))) 2>/dev/null)
    echo "║ Root: [$disk_bar$disk_empty]                          ║"
    df -h / | awk 'NR==2{printf "║ %s used of %s                              ║\n", $3, $2}'

    echo "╠══════════════════════════════════════════════════════════╣"
    echo "║ NETWORK                                                      ║"

    # Network usage
    rx_bytes=$(cat /sys/class/net/*/statistics/rx_bytes 2>/dev/null | paste -sd+ | bc)
    tx_bytes=$(cat /sys/class/net/*/statistics/tx_bytes 2>/dev/null | paste -sd+ | bc)
    rx_mb=$((rx_bytes / 1024 / 1024))
    tx_mb=$((tx_bytes / 1024 / 1024))
    echo "║ RX: ${rx_mb}MB  TX: ${tx_mb}MB                                      ║"

    # Active connections
    connections=$(ss -t | wc -l)
    echo "║ Connections: ${connections}                                       ║"

    echo "╠══════════════════════════════════════════════════════════╣"
    echo "║ TOP PROCESSES                                               ║"
    echo "║ PID     CPU%   MEM%   COMMAND                               ║"

    ps aux --sort=-%cpu | head -6 | tail -5 | awk '{printf "║ %-7s %-5s %-5s %-31s ║\n", $2, $3, $4, $11}'

    echo "╚══════════════════════════════════════════════════════════╝"

    echo ""
    echo "Press 'q' to quit, 'r' to refresh"
    read -t 2 -n 1 key

    if [ "$key" = "q" ]; then
        exit 0
    fi
done
EOF

chmod +x /usr/local/bin/piexed-system-monitor

# System Cleaner
cat > /usr/local/bin/piexed-clean << 'EOF'
#!/bin/bash
# Piẻxed OS System Cleaner

echo "=== Piẻxed OS System Cleaner ==="
echo ""

echo "1. Clean package cache"
sudo apt clean

echo "2. Remove old kernels (keep current)"
sudo apt autoremove --purge -y

echo "3. Clean thumbnail cache"
rm -rf ~/.cache/thumbnails/*

echo "4. Clean trash"
rm -rf ~/.local/share/Trash/*

echo "5. Clean logs"
sudo journalctl --vacuum-time=7d

echo "6. Clean temp files"
rm -rf /tmp/* 2>/dev/null || true

echo ""
echo "Cleaning completed!"
EOF

chmod +x /usr/local/bin/piexed-clean

# System Information
cat > /usr/local/bin/piexed-info << 'EOF'
#!/bin/bash
# Piẻxed OS System Information

echo "╔══════════════════════════════════════════════════════════╗"
echo "║              PIEXED OS SYSTEM INFORMATION                 ║"
echo "╚══════════════════════════════════════════════════════════╝"
echo ""

echo "Operating System:"
cat /etc/os-release | grep -E "^(NAME|VERSION)=" | sed 's/^/  /'
echo ""

echo "Kernel:"
uname -a
echo ""

echo "Architecture:"
uname -m
echo ""

echo "Hostname:"
hostname
echo ""

echo "Uptime:"
uptime -p
echo ""

echo "CPU:"
lscpu | grep -E "^Model name:|^CPU(s):|^Thread|^Core" | sed 's/^/  /'
echo ""

echo "Memory:"
free -h
echo ""

echo "Disk:"
df -h /
echo ""

echo "Network Interfaces:"
ip -br link show | sed 's/^/  /'
echo ""

echo "Graphics:"
lspci | grep -i vga | sed 's/^/  /'
echo ""
EOF

chmod +x /usr/local/bin/piexed-info

# Hardware Detection
cat > /usr/local/bin/piexed-hwinfo << 'EOF'
#!/bin/bash
# Piẻxed OS Hardware Information

echo "=== Piẻxed OS Hardware Detection ==="
echo ""

echo "=== CPU ==="
lscpu
echo ""

echo "=== Memory ==="
dmidecode -t memory | grep -E "Size|Speed|Type:"
echo ""

echo "=== Storage ==="
lsblk -o NAME,SIZE,TYPE,FSTYPE,MOUNTPOINT
echo ""

echo "=== Network ==="
lspci | grep -i network
echo ""

echo "=== Graphics ==="
lspci | grep -i vga
echo ""

echo "=== USB ==="
lsusb
echo ""

echo "=== PCI ==="
lspci
EOF

chmod +x /usr/local/bin/piexed-hwinfo

# Performance Test
cat > /usr/local/bin/piexed-benchmark << 'EOF'
#!/bin/bash
# Piẻxed OS Performance Benchmark

echo "=== Piẻxed OS Performance Benchmark ==="
echo ""

# CPU benchmark
echo "CPU Benchmark..."
echo "Computing Pi (10000 iterations)..."
start_time=$(date +%s%N)
python3 -c "
import math
def calc(n):
    pi = 0
    for i in range(n):
        pi += (4.0 * (-1)**i / (2*i + 1))
    return pi
calc(10000)
" 2>/dev/null || echo "1+1" | bc > /dev/null
end_time=$(date +%s%N)
cpu_time=$(( (end_time - start_time) / 1000000 ))
echo "CPU Score: $cpu_time ms"

# Memory benchmark
echo ""
echo "Memory Benchmark..."
mem_total=$(free -m | awk 'NR==2{print $2}')
echo "Total Memory: ${mem_total}MB"

# Disk benchmark
echo ""
echo "Disk Benchmark..."
start_time=$(date +%s%N)
dd if=/dev/zero of=/tmp/test bs=1M count=100 2>/dev/null
end_time=$(date +%s%N)
disk_time=$(( (end_time - start_time) / 1000000 ))
rm -f /tmp/test
echo "Disk Write Speed: $((100000 / disk_time)) MB/s"

echo ""
echo "Benchmark completed!"
EOF

chmod +x /usr/local/bin/piexed-benchmark

# Backup Tool
cat > /usr/local/bin/piexed-backup << 'EOF'
#!/bin/bash
# Piẻxed OS Backup Tool

BACKUP_DIR="/backup"
DATE=$(date +%Y%m%d_%H%M%S)

mkdir -p $BACKUP_DIR

echo "=== Piẻxed OS Backup Tool ==="
echo ""

echo "1. Home Directory Backup"
tar -czf $BACKUP_DIR/home_$DATE.tar.gz -C ~ . 2>/dev/null
echo "   Home backup: $BACKUP_DIR/home_$DATE.tar.gz"

echo "2. Configuration Backup"
tar -czf $BACKUP_DIR/config_$DATE.tar.gz /etc 2>/dev/null
echo "   Config backup: $BACKUP_DIR/config_$DATE.tar.gz"

echo "3. Installed Packages List"
dpkg --get-selections > $BACKUP_DIR/packages_$DATE.txt
echo "   Packages list: $BACKUP_DIR/packages_$DATE.txt"

echo ""
echo "Backup completed!"
echo "Location: $BACKUP_DIR"
EOF

chmod +x /usr/local/bin/piexed-backup

# Restore Tool
cat > /usr/local/bin/piexed-restore << 'EOF'
#!/bin/bash
# Piẻxed OS Restore Tool

echo "=== Piẻxed OS Restore Tool ==="
echo ""

read -p "Enter backup file path: " backup_file

if [ -f "$backup_file" ]; then
    echo "Restoring from $backup_file..."
    tar -xzf "$backup_file" -C ~
    echo "Restore completed!"
else
    echo "Error: Backup file not found"
fi
EOF

chmod +x /usr/local/bin/piexed-restore

# Battery Optimization (for laptops)
cat > /usr/local/bin/piexed-battery-optimize << 'EOF'
#!/bin/bash
# Piẻxed OS Battery Optimization

echo "=== Piẻxed OS Battery Optimization ==="
echo ""

# Check if running on battery
on_battery=$(upower -i /org/freedesktop/UPower/devices/battery_BAT0 2>/dev/null | grep "state" | grep -c "discharging")

if [ "$on_battery" -eq 1 ]; then
    echo "Running on battery - optimizing..."

    # Reduce screen brightness
    # echo 50 > /sys/class/backlight/*/brightness

    # Disable unnecessary services
    systemctl stop apache2 2>/dev/null || true
    systemctl stop nginx 2>/dev/null || true

    # Enable power saving
    # wifi power save
    iw dev wlan0 set power_save on 2>/dev/null || true

    echo "Battery optimization applied!"
else
    echo "Running on AC power - no optimization needed"
fi
EOF

chmod +x /usr/local/bin/piexed-battery-optimize

# Network Diagnostics
cat > /usr/local/bin/piexed-netcheck << 'EOF'
#!/bin/bash
# Piẻxed OS Network Diagnostics

echo "=== Piẻxed OS Network Diagnostics ==="
echo ""

echo "1. Interface Status:"
ip link show
echo ""

echo "2. IP Addresses:"
ip addr show
echo ""

echo "3. DNS Resolution:"
cat /etc/resolv.conf | grep nameserver
echo ""

echo "4. Ping Tests:"
echo "   Google DNS: $(ping -c 1 8.8.8.8 -W 2 >/dev/null && echo 'OK' || echo 'FAILED')"
echo "   Cloudflare: $(ping -c 1 1.1.1.1 -W 2 >/dev/null && echo 'OK' || echo 'FAILED')"
echo ""

echo "5. Gateway Test:"
gateway=$(ip route | grep default | awk '{print $3}')
echo "   Gateway: $gateway"
ping -c 1 $gateway -W 2 >/dev/null && echo "   Gateway: OK" || echo "   Gateway: FAILED"
echo ""

echo "6. DNS Test:"
nslookup google.com >/dev/null 2>&1 && echo "   DNS: OK" || echo "   DNS: FAILED"
EOF

chmod +x /usr/local/bin/piexed-netcheck

# Quick Fix Tool
cat > /usr/local/bin/piexed-fix << 'EOF'
#!/bin/bash
# Piẻxed OS Quick Fix Tool

echo "=== Piẻxed OS Quick Fix ==="
echo ""

echo "1. Repair broken packages"
sudo apt install -f -y

echo "2. Clean apt cache"
sudo apt clean

echo "3. Update package lists"
sudo apt update

echo "4. Upgrade packages"
sudo apt upgrade -y

echo "5. Remove unnecessary packages"
sudo apt autoremove -y

echo ""
echo "Quick fix completed!"
EOF

chmod +x /usr/local/bin/piexed-fix

# Create menu entries
mkdir -p /usr/share/applications

cat > /usr/share/applications/piexed-system-monitor.desktop << 'EOF'
[Desktop Entry]
Name=Piexed System Monitor
Comment=Monitor system resources
Exec=xfce4-terminal -e piexed-system-monitor
Icon=utilities-system-monitor
Terminal=false
Type=Application
Categories=System;Monitor;
EOF

cat > /usr/share/applications/piexed-system-info.desktop << 'EOF'
[Desktop Entry]
Name=Piexed System Info
Comment=View system information
Exec=xfce4-terminal -e piexed-info
Icon=dialog-information
Terminal=false
Type=Application
Categories=System;Utility;
EOF

cat > /usr/share/applications/piexed-cleaner.desktop << 'EOF'
[Desktop Entry]
Name=Piexed System Cleaner
Comment=Clean system junk files
Exec=sudo piexed-clean
Icon=user-trash-full
Terminal=true
Type=Application
Categories=System;Utility;
EOF

echo "System utilities installed successfully!"