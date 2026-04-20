# Piẻxed OS Documentation

## Overview

Piẻxed OS is a lightweight, professional Linux-based operating system optimized for low-end hardware. Based on Ubuntu 22.04 LTS, it provides a macOS-inspired interface with strawberry branding.

## System Requirements

| Component | Minimum | Recommended |
|-----------|---------|-------------|
| RAM | 1 GB | 2 GB |
| Storage | 10 GB | 20 GB |
| CPU | 1 GHz | 2 GHz |
| Display | 800×600 | 1024×768 |

## Features

### Core Features
- **Lightweight**: Optimized for 1GB RAM systems
- **Fast Boot**: Under 30 seconds on modern hardware
- **Ubuntu Compatible**: Full DEB package support
- **Modern Desktop**: macOS-inspired XFCE interface
- **App Store**: One-click software installation
- **Security**: Firewall, AppArmor, and automatic updates
- **Gaming Ready**: Steam, Lutris, and native Linux games

### Pre-installed Software
- Firefox Web Browser
- LibreOffice Suite
- VLC Media Player
- GIMP Image Editor
- Shotwell Photo Manager
- Thunderbird Email Client
- VS Code (via App Store)
- And more...

## Installation

### Creating Bootable USB

**Linux:**
```bash
sudo dd if=piexed-os-1.0.0.iso of=/dev/sdX bs=4M status=progress
```

**macOS:**
```bash
sudo dd if=piexed-os-1.0.0.iso of=/dev/rdiskN bs=4m
```

**Windows:**
Use Rufus or Etcher to flash the ISO.

### Installation Steps

1. Boot from USB drive
2. Select "Install Piexed OS"
3. Choose installation type:
   - **Guided**: Automatic partitioning
   - **Custom**: Manual partitioning
   - **Encrypted**: LUKS encryption
   - **LVM**: Logical Volume Management
4. Follow the wizard
5. Reboot when complete

### Dual Boot

Piexed OS automatically detects Windows and other Linux installations. During installation, choose "Something else" to manually select partitions.

## Post-Installation

### First Steps

1. **Connect to Network**: Click the network icon in the panel
2. **Update System**: Run `sudo apt update && sudo apt upgrade`
3. **Install Software**: Use the Piexed App Store

### Default Login

- **Username**: `piexed`
- **Password**: `piexed` (change this!)
- **Root**: `piexed` (change this!)

## Desktop Environment

### Top Panel
- Left: Piẻxed Menu (click strawberry icon)
- Center: Active window title
- Right: System indicators (WiFi, Volume, Battery, Clock)

### Dock
- Application launcher at bottom
- Running app indicators (dots below icons)
- Magnification effect on hover
- Right-click for options

### Keyboard Shortcuts

| Shortcut | Action |
|----------|--------|
| Super | Open Piẻxed Menu |
| Alt+F2 | Quick launcher |
| Ctrl+Alt+T | Terminal |
| Ctrl+Alt+L | Lock screen |
| PrtSc | Screenshot |

## System Tools

Access via Menu → System Tools:

1. **System Information**: View hardware and software info
2. **System Monitor**: Real-time CPU/memory monitoring
3. **Disk Cleaner**: Clean caches and temporary files
4. **System Update**: Update packages
5. **Firewall**: Configure UFW firewall
6. **User Management**: Add/remove users
7. **Service Manager**: Start/stop system services
8. **Hardware Info**: Detailed hardware information
9. **Backup Tool**: Backup home and system

## App Store

The Piexed App Store provides easy software installation:

1. Open Piexed Store from the dock
2. Browse categories or search
3. Click "Install" on any application
4. Enter password when prompted
5. Application installs automatically

### Package Sources
- **Ubuntu (APT)**: Main package repository
- **Flatpak**: Sandboxed applications
- **Snap**: Canonical packages

## Performance Optimization

### Memory Optimization
- zram: Compressed RAM swap
- earlyoom: Prevent out-of-memory crashes
- preload: Preload frequently used apps

### Boot Optimization
- Plymouth splash screen
- Parallel service startup
- Optimized initramfs

### Power Management
- Battery indicator in panel
- Power profiles for laptops
- Screen brightness control

## Security

### Built-in Security
- **UFW Firewall**: Easy firewall management
- **AppArmor**: Application sandboxing
- **Automatic Updates**: Security patches
- **ClamAV**: Optional antivirus

### Enabling Firewall
```bash
sudo ufw enable
sudo ufw allow ssh
sudo ufw allow http
sudo ufw allow https
```

## Troubleshooting

### System Slow
```bash
# Check memory
free -h

# Check CPU
top

# Clean caches
sudo apt clean
rm -rf ~/.cache/*
```

### Network Issues
```bash
# Restart NetworkManager
sudo systemctl restart NetworkManager

# Check WiFi
nmcli device wifi list
```

### Can't Boot
1. Press ESC during boot for GRUB menu
2. Select "Recovery mode"
3. Choose "root - Drop to root shell"
4. Run: `update-grub && reboot`

## Getting Help

- **Documentation**: This document
- **Community Forum**: community.piexed-os.org
- **GitHub Issues**: github.com/piexed-os/issues
- **IRC**: #piexed on Libera.Chat

## Contributing

We welcome contributions! Please see our GitHub repository for:
- Bug reports
- Feature requests
- Pull requests
- Documentation improvements

## License

Piẻxed OS is released under GPL-3.0 license. Individual components maintain their respective licenses.

## Credits

- **Base**: Ubuntu Linux
- **Desktop**: XFCE
- **Kernel**: Linux
- **Logo**: Custom strawberry design

---

**Piẻxed OS - Lightweight, Powerful, Professional**

*Version 1.0.0 - Strawberry Fields*
