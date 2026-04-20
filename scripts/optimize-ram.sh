#!/bin/bash
#
# Piẻxed OS - RAM Optimization
# Maximum performance, minimum RAM usage
#

set -e

echo "=========================================="
echo "  Piẻxed OS - RAM Optimizer"
echo "=========================================="

# 1. Optimize Swappiness (low RAM usage)
echo "[1] Optimizing swappiness..."
echo 10 | sudo tee /proc/sys/vm/swappiness
echo "vm.swappiness=10" | sudo tee /etc/sysctl.d/99-ram-optimization.conf

# 2. Cache pressure
echo "[2] Optimizing cache pressure..."
echo 60 | sudo tee /proc/sys/vm/vfs_cache_pressure
echo "vm.vfs_cache_pressure=60" | sudo tee -a /etc/sysctl.d/99-ram-optimization.conf

# 3. Disable unnecessary services
echo "[3] Disabling unnecessary services..."
services_to_disable=(
    bluetooth
    cups
    apport
    whoopsie
    spamassassin
    apache2
    mysql
    postgresql
    redis-server
)

for service in "${services_to_disable[@]}"; do
    sudo systemctl stop $service 2>/dev/null || true
    sudo systemctl disable $service 2>/dev/null || true
done

# 4. Clear cache
echo "[4] Clearing system cache..."
sudo sync
echo 3 | sudo tee /proc/sys/vm/drop_caches
sudo rm -rf /var/cache/* /tmp/* ~/.cache/* 2>/dev/null || true

# 5. Optimize .bashrc for fast loading
cat >> ~/.bashrc << 'BASHRC'
# Fast prompt - no git stuff
PS1='\u@\h:\w\$ '
# Fast completion
complete -cf sudo
BASHRC

# 6. Use zRAM instead of swap (if available)
echo "[5] Checking zRAM..."
if ! grep -q /dev/zram0 /proc/swaps; then
    echo "zRAM not active - activating..."
    sudo modprobe zram
    echo lz4 | sudo tee /sys/block/zram0/comp_algorithm
    echo 512M | sudo tee /sys/block/zram0/disksize
    sudo mkswap /dev/zram0
    sudo swapon /dev/zram0 -p 100
fi

# 7. Preload essential apps
cat > /etc/preload.conf << 'PRELOAD'
# Critical apps to preload
firefox
xfce4-terminal
thunar
libreoffice
vlc
PRELOAD

# 8. Auto-clear cache script
cat > /usr/local/bin/piexed-optimize << 'OPT'
#!/bin/bash
echo "Optimizing RAM..."

# Clear cache
sudo sync
echo 3 | sudo tee /proc/sys/vm/drop_caches

# Clear temp files
rm -rf /tmp/* /var/tmp/* ~/.cache/* 2>/dev/null

# Show memory
free -h
echo "Optimization complete!"
OPT
chmod +x /usr/local/bin/piexed-optimize

# 9. Create fast startup script
cat > /usr/local/bin/piexed-faststart << 'FAST'
#!/bin/bash
echo "Enabling fast boot..."

# Disable plymouth boot delay
sudo sed -i 's/GRUB_TIMEOUT=.*/GRUB_TIMEOUT=1/' /etc/default/grub
sudo update-grub

# Disable graphical boot
sudo systemctl set-default multi-user.target

# Enable services
sudo systemctl enable NetworkManager
sudo systemctl enable ssh

echo "Fast boot enabled!"
FAST
chmod +x /usr/local/bin/piexed-faststart

echo ""
echo "=========================================="
echo "  RAM OPTIMIZATION COMPLETE!"
echo "=========================================="
echo ""
echo "Expected RAM usage now: ~300MB idle"
echo ""
echo "Tools:"
echo "  piexed-optimize      - Clear cache"
echo "  piexed-faststart    - Enable fast boot"