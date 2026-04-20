#!/bin/bash
#
# Piexed OS Network Configuration Script
# Optimized for low-end hardware
#

set -e

# Network Manager Configuration for Piexed OS
# Optimized settings for 1GB RAM systems

# Create NetworkManager config directory
mkdir -p /etc/NetworkManager/conf.d

# Create Piexed OS optimization config
cat > /etc/NetworkManager/conf.d/99-piexed-optimization.conf << 'EOF'
[main]
# Optimize for low-memory systems
rc-manager=auto
# Use systemd-resolved if available
dns=default
# Don't manage loopback
no-auto-default=*,except:lo

[device]
# Scan interval (default 30s, optimized for low-end)
scanInterval=60
# WiFi power save
wifi.scan-rand-mac-address=no

[connection]
# Connection timeout
timeout=30
# Disable IPv6 privacy (saves resources)
ipv6.method=auto
EOF

# Create systemd networking override for low-end systems
mkdir -p /etc/systemd/network

cat > /etc/systemd/network/99-piexed-lowmem.network << 'EOF'
[Match]
Name=lo

[Network]
Address=127.0.0.1/8
Gateway=0.0.0.0
EOF

# Configure WiFi power management
mkdir -p /etc/pm/power.d

cat > /etc/pm/power.d/wifi-power << 'EOF'
#!/bin/sh
# Disable WiFi power management for better stability on low-end hardware
iwconfig wlan0 power off 2>/dev/null || true
EOF

chmod +x /etc/pm/power.d/wifi-power

# Optimize Ethernet for low-end systems
cat > /etc/pm/power.d/ethernet-power << 'EOF'
#!/bin/sh
# Optimize ethernet for low-power
ethtool -s eth0 wol d 2>/dev/null || true
ethtool -s eth0 advertising 0x01f 2>/dev/null || true
EOF

chmod +x /etc/pm/power.d/ethernet-power

echo "Network optimization completed"