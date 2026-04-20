# Piexed OS - Specification Document

## 1. Project Overview

### Project Name
**Piexed OS** - A lightweight, professional Linux-based operating system designed for low-end hardware.

### Project Vision
Piexed OS delivers a macOS-like experience on resource-constrained hardware, featuring a strawberry-themed identity and full Ubuntu compatibility. The OS provides a premium, polished computing environment while maintaining exceptional performance on systems with as little as 1GB RAM and 1GB storage.

### Target Users
- Users with older or low-spec hardware seeking modern OS experience
- Educational institutions deploying affordable computing solutions
- Users transitioning from Windows/macOS to Linux
- Android devices supporting Linux chroots (Termux, UserLAnd)
- Organizations requiring lightweight, customizable desktop environments

### Technical Foundation
- **Base Distribution**: Ubuntu (LTS releases)
- **Package Format**: DEB (Ubuntu/Debian compatible)
- **Init System**: OpenRC (lightweight) or systemd (compatibility)
- **Desktop Environment**: Custom lightweight environment based on XFCE/LXQt components
- **Kernel**: Linux LTS with hardware enablement stack

---

## 2. UI/UX Specification

### 2.1 Window Management

#### Window Chrome
- **Title Bar Height**: 32px
- **Border Radius**: 8px (top corners only)
- **Shadow**: 0 4px 16px rgba(0,0,0,0.15)
- **Control Buttons**: 12px circles (close, minimize, maximize)
  - Close: #FF5F57
  - Minimize: #FFBD2E
  - Maximize: #28CA41
- **Title Text**: SF Pro Text fallback to Noto Sans, 13px, #333333

#### Window Behavior
- Snap to screen edges (left, right, corners)
- Multi-monitor aware positioning
- Smooth animated transitions (200ms ease-out)
- Tab switching within windows (like macOS Spaces concept)

### 2.2 Color Palette

#### Primary Colors
- **Primary Accent**: #E63946 (Strawberry Red)
- **Primary Dark**: #9D0208 (Deep Red)
- **Primary Light**: #FF758F (Light Pink)

#### Secondary Colors
- **Secondary Accent**: #2A9D8F (Teal)
- **Background Dark**: #1A1A2E
- **Background Light**: #FAFAFA

#### Semantic Colors
- **Success**: #4CAF50
- **Warning**: #FF9800
- **Error**: #F44336
- **Info**: #2196F3

#### Desktop Environment Colors
- **Desktop Background**: #16213E (gradient to #0F3460)
- **Panel/Dock**: rgba(30,30,40,0.85) with blur
- **Window Background**: #FFFFFF
- **Window Background Dark Mode**: #2D2D2D

### 2.3 Typography

#### Font Stack
```
font-family: 'Piexed Sans', 'SF Pro Display', 'Noto Sans', -apple-system, sans-serif;
font-family: 'Piexed Mono', 'SF Mono', 'Noto Sans Mono', monospace;
```

#### Type Scale
| Element | Size | Weight | Line Height |
|---------|------|--------|-------------|
| H1 | 28px | 600 | 1.3 |
| H2 | 24px | 600 | 1.3 |
| H3 | 20px | 500 | 1.4 |
| Body | 14px | 400 | 1.5 |
| Caption | 12px | 400 | 1.4 |
| Code | 13px | 400 | 1.6 |

### 2.4 Spacing System

#### Grid System
- Base unit: 4px
- Spacing scale: 4, 8, 12, 16, 24, 32, 48, 64, 96px

#### Component Spacing
- Button padding: 8px 16px
- Card padding: 16px
- Section margins: 24px
- List item padding: 12px 16px

### 2.5 Visual Effects

#### Shadows
- Elevation 1: 0 2px 4px rgba(0,0,0,0.1)
- Elevation 2: 0 4px 8px rgba(0,0,0,0.15)
- Elevation 3: 0 8px 16px rgba(0,0,0,0.2)
- Elevation 4: 0 16px 32px rgba(0,0,0,0.25)

#### Animations
- Transitions: 200ms ease-out (default)
- Hover effects: 150ms ease-in-out
- Loading animations: 1s infinite ease-in-out
- Page transitions: 300ms fade-in

#### Glass Effect
- backdrop-filter: blur(20px)
- Background: rgba(255,255,255,0.8) or rgba(30,30,40,0.7)
- Border: 1px solid rgba(255,255,255,0.2)

---

## 3. Functional Specification

### 3.1 Core Features

#### Boot System
- **Boot Manager**: GRUB2 with custom Piexed OS theme
- **Dual Boot Support**: Automatic detection and offering of existing OS installations
  - Windows (UEFI/Legacy)
  - macOS (Hackintosh detection)
  - Other Linux distributions
- **Boot Options**:
  - Normal boot
  - Recovery mode
  - Safe graphics mode
  - Memory test (memtest86+)
  - OEM installation mode

#### File System
- **Default Filesystem**: ext4 (recommended)
- **Supported Filesystems**:
  - ext4, ext3, ext2
  - Btrfs (with compression)
  - XFS
  - NTFS (read/write)
  - FAT32 (EFI boot)
  - exFAT
  - APFS (read-only)
  - HFS+ (read/write)
- **Partitioning Tool**: GParted + custom Piexed Installer
- **Swap**: Swap file support (zswap enabled by default)

#### Desktop Environment Components

##### Piexed Desktop Shell
- Custom compositor (based on Compton)
- Desktop icons with drag-drop support
- Wallpaper with slideshow support
- Widget support (weather, clock, system monitor)

##### Piexed Dock (Similar to macOS Dock)
- App launching dock with magnification effect
- Running app indicators (dot below icon)
- Drag to rearrange, drag to new apps
- Trash/Recycle bin integration
- Right-click context menus
- Auto-hide option
- Position: Bottom (default), Left, Right configurable

##### Piexed Panel (Top Bar)
- Apple-style top bar
- Left: Application menu (piexed menu)
- Center: Active window title
- Right: Status indicators
  - Wi-Fi, Bluetooth, Battery, Volume, Clock
  - Notification center access

##### Mission Control (Spaces)
- Multiple virtual desktops
- Exposé-style window overview
- Hot corner activation
- Keyboard shortcut navigation
- Desktop indicators

#### Application Ecosystem

##### Piexed App Store
- Flatpak-based application distribution
- Categories: Productivity, Development, Games, Multimedia, Utilities
- One-click install with automatic updates
- Snap support for Ubuntu packages
- Rating and review system
- Software center with screenshots and descriptions

##### Pre-installed Applications
- **Office Suite**: LibreOffice (full installation)
- **Web Browser**: Firefox ESR with custom theming
- **Media Player**: VLC Media Player
- **Image Viewer**: Shotwell
- **Mail Client**: Thunderbird
- **Terminal**: Custom Piexed Terminal (based on Terminator)
- **File Manager**: Thunar with custom theming
- **Text Editor**: Pluma (Gedit fork)
- **Archive Manager**: File Roller
- **System Tools**:  Settings, Software Updates, Disk Utility

#### System Utilities

##### System Preferences (Settings)
- **Personalization**:
  - Desktop backgrounds
  - Dock configuration
  - Theme selection (Light/Dark/Auto)
  - Accent color picker
  - Font size adjustment

- **Displays**:
  - Resolution settings
  - Multiple monitor configuration
  - Brightness control
  - Night shift (blue light filter)

- **Sound**:
  - Output device selection
  - Input device selection
  - Volume shortcuts
  - Sound themes

- **Network**:
  - Wi-Fi connections
  - Ethernet configuration
  - VPN support
  - Hotspot creation

- **Bluetooth**:
  - Device pairing
  - File transfer (OBEX)
  - Audio device connection

- **Users & Accounts**:
  - User creation/modification
  - Avatar selection
  - Login options
  - Fingerprint setup (if supported)

- **Privacy**:
  - Location services
  - Screen capture permissions
  - Analytics opt-in/out
  - Crash reporting settings

- **Security**:
  - Firewall configuration
  - App permissions
  - Encryption settings
  - Secure boot configuration

##### System Monitor
- Real-time CPU, RAM, network, disk usage
- Process manager with kill/restart options
- Startup applications manager
- Resource history graphs

##### Software Center
- APT package management (Debian/Ubuntu compatibility)
- Flatpak integration
- Snap package support
- Update management
- Flatpak runtime optimization

#### Developer Tools

##### Development Environment
- **Compiler**: GCC, G++, Clang
- **Build Tools**: Make, CMake, Ninja
- **Version Control**: Git (pre-installed)
- **IDE Support**: VS Code installation available
- **Container Support**: Docker, Podman
- **Virtualization**: QEMU, VirtualBox compatible

##### Terminal Emulator
- Custom Piexed Terminal with features:
  - Split panes (tmux integration)
  - Multiple tabs
  - Customizable color schemes
  - SSH integration
  - Zsh with Oh-My-Zsh pre-configuration
  - Alias management
  - Command history search

#### Multimedia Capabilities

##### Audio
- PulseAudio with custom mixer
- PipeWire support (optional)
- Audio profile presets
- Bluetooth audio optimization

##### Video
- Hardware acceleration (VA-API, VDPAU)
- Codec support: H.264, H.265, VP9, AV1
- MP4, MKV, AVI, MOV playback
- DVD playback support

##### Graphics
- OpenGL support (Mesa)
- Vulkan support (if hardware allows)
- Hardware video decode
- Multiple monitor (Miracast alternative: SPICE)

#### Android Integration
- **DeX-style Mode**: Full desktop interface when connected to display
- **File Transfer**: MTP, ADB file transfer
- **Phone Companion**: Call/notification mirroring
- **Linux Subsystem**: Termux/UserLAnd compatibility scripts

### 3.2 Performance Optimization

#### Memory Management
- **Zram**: Compression-based RAM extension
- **Zswap**: Compressed swap in RAM
- **Preload**: Application preloading
- **Memory-efficient defaults**:
  - Swapiness: 60 (configurable)
  - Cache pressure: 60
  - Swappiness: 10 (for zram)

#### CPU Optimization
- **Thermald**: Thermal management
- **cpufreq**: Performance/governor selection
- **CPU isolation**: For real-time applications

#### Disk Optimization
- **fstrim**: SSD trim support
- **noatime**: Disable access time logging
- **relatime**: Smart access time updates
- **Compactor**: Memory compaction

#### Boot Optimization
- **Parallel boot**: Services parallel start
- ** Plymouth**: Custom boot splash
- **Fast boot**: Skip unnecessary hardware checks

### 3.3 Security Features

#### User Security
- Encrypted home directory (ecryptfs)
- Full disk encryption (LUKS)
- Secure boot support (shim-signed)
- UEFI password protection

#### Application Security
- AppArmor enabled by default
- Sandboxed applications
- Permission prompts for system access
- Secure update mechanism (signed packages)

#### Network Security
- UFW firewall (pre-configured)
- AppArmor network profiles
- DNSCrypt support
- VPN autoconnect options

### 3.4 Data Flow & Processing

#### Package Management Pipeline
```
User Request → Package Manager → Repository Index → Download → Verify Signature → Extract → Configure → Install
```

#### System Update Flow
```
Check Repos → Download Updates → Verify Packages → Pre-upgrade Scripts → Apply Updates → Post-upgrade Scripts → Restart Services
```

#### User Profile Data Flow
```
Local Storage → Encrypted (optional) → Backup to Cloud (optional) → Sync across devices (optional)
```

---

## 4. Technical Architecture

### 4.1 Kernel Configuration

#### Minimum Kernel Features
- Power management (ACPI, PM)
- Storage drivers (AHCI, NVMe, USB storage)
- Network drivers (Ethernet, Wi-Fi, Bluetooth)
- Graphics (Intel, AMD, NVIDIA)
- Audio (ALSA, PulseAudio)
- Input devices (USB, PS/2, touchpad)

#### Low-Memory Optimizations
- `CONFIG_HAVE_LEGACY_PTYS=y`
- `CONFIG_DEVTMPFS=y`
- `CONFIG_CGROUPS=y`
- `CONFIG_ZSMALLOC=y`
- `CONFIG_FRONTSWAP=y`

### 4.2 Package Repository Structure

```
piexed-os-repository/
├── pool/
│   ├── main/
│   │   ├── p/piexed-base/
│   │   ├── p/piexed-desktop/
│   │   └── p/piexed-apps/
│   ├── restricted/
│   ├── universe/
│   └── multiverse/
├── dists/
│   ├── stable/
│   └── testing/
└── indices/
```

### 4.3 Directory Structure
```
/
├── etc/                    # System configuration
├── var/lib/                # Variable state
├── usr/local/piexed/       # Piexed OS specific
├── home/                   # User directories
├── opt/                    # Third-party software
├── srv/                    # Service data
└── tmp/                    # Temporary files
```

---

## 5. Branding & Assets

### 5.1 Logo Design

#### Primary Logo
- Stylized strawberry with minimalist design
- Colors: Primary Red (#E63946) with gradient
- Uses: Desktop, installer, boot splash

#### Alternative Logos
- Outline version for dark themes
- Icon-only version for app icons
- Favicon set for web

### 5.2 Boot Splash
- Strawberry logo animation
- Progress bar in primary red
- Clean, minimal aesthetic

### 5.3 App Icons
- Consistent strawberry-leaf motif
- Rounded square base (similar to macOS)
- Gradient fills where appropriate

---

## 6. Build & Deployment

### 6.1 Build Requirements
- Ubuntu 22.04+ base system
- 30GB disk space minimum
- 8GB RAM recommended
- debootstrap
- squashfs-tools
- xorriso
- GRUB2

### 6.2 Build Output
- ISO image for Live DVD/USB
- tarball for chroot installations
- Package repository packages

### 6.3 Installation Targets
- Physical hardware (x86_64, ARM64)
- Virtual machines (QEMU, VirtualBox, VMware)
- Android Linux environments
- Cloud instances

---

## 7. Acceptance Criteria

### 7.1 Installation
- [ ] ISO boots successfully on legacy and UEFI systems
- [ ] Installation completes in under 30 minutes on target hardware
- [ ] All partition options work correctly
- [ ] Dual boot with Windows and other Linux works
- [ ] UEFI secure boot support functional

### 7.2 Desktop Environment
- [ ] Boot time under 30 seconds on 1GB RAM target
- [ ] UI responsive with under 100MB RAM usage at idle
- [ ] Window management all functions work
- [ ] Dock magnification and animation smooth
- [ ] Panel widgets update correctly

### 7.3 Applications
- [ ] App Store installs and updates packages
- [ ] All pre-installed apps launch correctly
- [ ] DEB packages install without dependency issues
- [ ] Flatpak applications run correctly

### 7.4 System Features
- [ ] All system settings functional
- [ ] Updates apply correctly
- [ ] Hardware detection works
- [ ] Sleep/wake works on supported hardware
- [ ] Power management functions

### 7.5 Performance
- [ ] Idle RAM usage under 400MB
- [ ] Startup applications complete under 10 seconds
- [ ] Application launch under 2 seconds
- [ ] File manager navigation smooth

### 7.6 Compatibility
- [ ] Ubuntu .deb packages install correctly
- [ ] Snap packages work
- [ ] Android termux compatibility scripts work
- [ ] Development tools compile code

---

## 8. Version Information

- **Version**: 1.0.0
- **Codename**: Strawberry Fields
- **Release Date**: TBD
- **Kernel**: 6.1 LTS (default)
- **Base**: Ubuntu 24.04 LTS