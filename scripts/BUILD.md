# Piẻxed OS - Build Instructions

## Quick Start (Windows/WLinux)

### Option 1: WSL (Recommended)
```powershell
# Open PowerShell as Administrator, then:
wsl --install

# After restart, open Ubuntu:
wsl -d Ubuntu

# Run these commands:
sudo apt update
sudo apt install -y debootstrap squashfs-tools xorriso grub-pc-bin grub-efi-amd64-bin mtools git

# Navigate to project
cd /mnt/c/Users/user/Desktop/tiktokclone/piexed-os/piexed-os

# Build!
sudo make build-pro
```

### Option 2: VirtualBox
1. Download Ubuntu Server ISO: https://ubuntu.com/download/server
2. Create VM (4GB RAM, 40GB disk)
3. Install Ubuntu
4. Run build commands above

## Build Commands

```bash
# Build Professional Edition (Desktop)
sudo make build-pro

# Build Server Edition
sudo make build-server

# Build Android Edition  
make build-android

# Apply Security Hardening
sudo make security

# Install Auto-Update
sudo make update

# Test in QEMU
make test

# Test in Oracle VirtualBox
make test-oracle
```

## Output Files

After build, ISOs are in:
```
output/
├── piexed-os-1.0.0-professional.iso    # Desktop
├── piexed-os-1.0.0-server.iso       # Server
└── piexed-os-1.0.0-android.tar.gz  # Android
```

## Installation

### Create Bootable USB (Linux)
```bash
sudo dd if=output/piexed-os-1.0.0-professional.iso of=/dev/sdX bs=4M status=progress
sync
```

### Create Bootable USB (Windows)
Use Rufus: https://rufus.ie

### Oracle VM Installation
1. Create new VM (Ubuntu 64-bit)
2. Mount ISO
3. Install
4. Login: piexed / piexed