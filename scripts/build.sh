#!/bin/bash
#
# Piexed OS Build Script
# Version: 1.0.0
# Description: Builds Piexed OS from Ubuntu base with all optimizations
#

set -e
set -o pipefail

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m'

# Configuration
PIEXED_VERSION="1.0.0"
PIEXED_CODENAME="Strawberry Fields"
KERNEL_VERSION="6.1.0-lts-piexed"
UBUNTU_BASE="jammy" # 22.04 LTS
ARCH="amd64"
BUILD_DIR="/workspace/piexed-os/build"
OUTPUT_DIR="/workspace/piexed-os/output"
WORKSPACE="/workspace/piexed-os/workspace"

# Package lists
CORE_PACKAGES=(
    "linux-image-${KERNEL_VERSION}"
    "linux-headers-${KERNEL_VERSION}"
    "linux-firmware"
    "ubuntu-base"
    "base-files"
    "base-passwd"
    "bash"
    "bzip2"
    "coreutils"
    "dash"
    "debconf"
    "debianutils"
    "diffutils"
    "dpkg"
    "e2fsprogs"
    "fdisk"
    "findutils"
    "gcc-12-base"
    "gawk"
    "gcc-12"
    "dpkg-dev"
    "tar"
    "gnupg"
    "gzip"
    "hostname"
    "init-system-helpers"
    "libc-bin"
    "libcrypt1"
    "libgcc-s1"
    "ncurses-base"
    "ncurses-bin"
    "passwd"
    "perl-base"
    "sed"
    "sensible-utils"
    "sysvinit-utils"
    "tzdata"
    "ubuntu-keyring"
    "util-linux"
    "zlib1g"
)

DESKTOP_PACKAGES=(
    "xorg"
    "xfce4"
    "xfce4-goodies"
    "lightdm"
    "lightdm-gtk-greeter"
    "picom"
    "network-manager"
    "network-manager-gnome"
    "pulseaudio"
    "pulseaudio-utils"
    "alsa-utils"
    "gvfs"
    "gvfs-backends"
    "gvfs-fuse"
    "thunar"
    "thunar-volman"
    "thunar-archive-plugin"
    "xfce4-terminal"
    "mousepad"
    "ristretto"
    "garcon"
    "exo-utils"
    "libxfce4ui-utils"
    "xfce4-panel"
    "xfce4-settings"
    "xfce4-appfinder"
    "xfwm4"
    "xfce4-notifyd"
    "xfce4-power-manager"
    "xfce4-pulseaudio-plugin"
    "xfce4-battery-plugin"
    "xfce4-clipman-plugin"
    "xfce4-dict"
    "xfce4-mail-watcher-plugin"
    "xfce4-mpc-plugin"
    "xfce4-screenshooter"
    "xfce4-session"
    "xfce4-systemload-plugin"
    "xfce4-taskmanager"
    "xfce4-verve-plugin"
    "xfce4-weather-plugin"
    "xfce4-xkb-plugin"
    "gtk2-engines-xfce"
    "arc-theme"
    "papirus-icon-theme"
    "fonts-noto"
    "fonts-noto-cjk"
)

PRODUCTIVITY_PACKAGES=(
    "libreoffice"
    "firefox"
    "vlc"
    "shotwell"
    "thunderbird"
    "file-roller"
    "evince"
    "eog"
    "gnome-calculator"
    "gnome-calendar"
    "gnome-clocks"
    "gnome-contacts"
    "gnome-font-viewer"
    "gnome-screenshot"
    "gnome-system-monitor"
    "gnome-text-editor"
)

DEV_PACKAGES=(
    "build-essential"
    "git"
    "vim"
    "nano"
    "curl"
    "wget"
    "openssh-client"
    "software-properties-common"
    "apt-transport-https"
    "ca-certificates"
    "clang"
    "cmake"
    "ninja-build"
    "autoconf"
    "automake"
    "libtool"
    "pkg-config"
    "python3"
    "python3-pip"
    "python3-dev"
)

PERFORMANCE_PACKAGES=(
    "preload"
    "zram-config"
    "earlyoom"
    "thermald"
    "linux-tools-generic"
)

APPSTORE_PACKAGES=(
    "gnome-software"
    "flatpak"
    "snapd"
)

ANDROID_PACKAGES=(
    "termux-api"
    "proot"
)

# Functions
log_info() {
    echo -e "${BLUE}[INFO]${NC} $1"
}

log_success() {
    echo -e "${GREEN}[SUCCESS]${NC} $1"
}

log_warning() {
    echo -e "${YELLOW}[WARNING]${NC} $1"
}

log_error() {
    echo -e "${RED}[ERROR]${NC} $1"
}

check_dependencies() {
    log_info "Checking build dependencies..."

    MISSING_DEPS=()

    for dep in debootstrap squashfs-tools xorriso grub-pc-bin grub-efi-amd64-bin; do
        if ! command -v "$dep" &> /dev/null; then
            MISSING_DEPS+=("$dep")
        fi
    done

    if [ ${#MISSING_DEPS[@]} -gt 0 ]; then
        log_warning "Missing dependencies: ${MISSING_DEPS[*]}"
        log_info "Installing dependencies..."
        sudo apt-get update
        sudo apt-get install -y debootstrap squashfs-tools xorriso grub-pc-bin grub-efi-amd64-bin mtools
    fi

    log_success "All dependencies satisfied"
}

create_directories() {
    log_info "Creating build directories..."

    mkdir -p "${BUILD_DIR}"
    mkdir -p "${OUTPUT_DIR}"
    mkdir -p "${WORKSPACE}/chroot"
    mkdir -p "${WORKSPACE}/image"
    mkdir -p "${WORKSPACE}/squashfs"
    mkdir -p "${WORKSPACE}/efi"

    log_success "Directories created"
}

download_base_system() {
    log_info "Downloading Ubuntu base system (${UBUNTU_BASE})..."

    cd "${WORKSPACE}"

    if [ ! -d "chroot" ] || [ -z "$(ls -A chroot)" ]; then
        sudo debootstrap --arch="${ARCH}" --variant=minbase "${UBUNTU_BASE}" chroot "http://archive.ubuntu.com/ubuntu/"
    else
        log_warning "Base system already exists, skipping download"
    fi

    log_success "Base system ready"
}

configure_chroot() {
    log_info "Configuring chroot environment..."

    # Mount filesystems
    sudo mount --bind /dev chroot/dev
    sudo mount --bind /dev/pts chroot/dev/pts
    sudo mount --bind /proc chroot/proc
    sudo mount --bind /sys chroot/sys

    # Copy configuration files
    sudo cp config/sources.list chroot/etc/apt/sources.list
    sudo cp -r config/piexed/* chroot/etc/piexed/

    # Update package index
    sudo chroot chroot /bin/bash -c "apt-get update"

    log_success "Chroot configured"
}

install_kernel() {
    log_info "Building and installing custom Piexed kernel..."

    cd "${WORKSPACE}"

    # Download kernel source
    if [ ! -d "linux-${KERNEL_VERSION}" ]; then
        wget -q https://cdn.kernel.org/pub/linux/kernel/v6.x/linux-${KERNEL_VERSION}.tar.xz || \
        wget -q https://github.com/torvalds/linux/archive/refs/tags/v6.1.tar.gz -O linux-${KERNEL_VERSION}.tar.gz
        tar xf linux-*.tar.* || true
    fi

    cd linux-*/

    # Configure kernel for low-end hardware
    cat > .config << 'EOF'
CONFIG_CC_IS_GCC=y
CONFIG_GCC_PLUGINS=y
CONFIG_FUNCTION_TRACER=y
CONFIG_HAVE_FUNCTION_TRACER=y
CONFIG_HAVE_FUNCTION_GRAPH_TRACER=y
CONFIG_TRACING_SUPPORT=y
CONFIG_FROZEN=y
CONFIG_RD_XZ=y
CONFIG_RD_LZMA=y
CONFIG_RD_LZO=y
CONFIG_RD_ZSTD=y
CONFIG_CC_OPTIMIZE_FOR_SIZE=y
CONFIG_LTO=y
CONFIG_LTO_CLANG=y
CONFIG_CGROUP_SCHED=y
CONFIG_CFS_BANDWIDTH=y
CONFIG_NET_NS=y
CONFIG_USER_NS=y
CONFIG_PID_NS=y
CONFIG_IPC_NS=y
CONFIG_UTS_NS=y
CONFIG_LDISC_OBSOLETE_DEFINED=y
CONFIG_DEVTMPFS=y
CONFIG_DEVTMPFS_MOUNT=y
CONFIG_TMPFS=y
CONFIG_TMPFS_POSIX_ACL=y
CONFIG_TMPFS_XATTR=y
CONFIG_FHANDLE=y
CONFIG_SYSFS=y
CONFIG_PROC_FS=y
CONFIG_PROC_SYSCTL=y
CONFIG_PROC_PAGE_MONITOR=y
CONFIG_TREE_RCU=y
CONFIG_TREE_PREEMPT_RCU=y
CONFIG_RCU_STALL_COMMON=y
CONFIG_RCU_NEED_GCPU=y
CONFIG_BLK_DEV_INITRD=y
CONFIG_INITRAMFS_SOURCE=""
CONFIG_RD_GZIP=y
CONFIG_ARCH_SUPPORTS_UPROBES=y
CONFIG_HAVE_64BIT_ALIGNED_ACCESS=y
CONFIG_KEXEC=y
CONFIG_KEXEC_CORE=y
CONFIG_HOTPLUG=y
CONFIG_PRINTK=y
CONFIG_BUG=y
CONFIG_ELF_CORE=y
CONFIG_BASE_FULL=y
CONFIG_FUTEX=y
CONFIG_EPOLL=y
CONFIG_SIGNALFD=y
CONFIG_TIMERFD=y
CONFIG_EVENTFD=y
CONFIG_SHMEM=y
CONFIG_AIO=y
CONFIG_ADVISE_SYSCALLS=y
CONFIG_MEMBARRIER=y
CONFIG_KALLSYMS=y
CONFIG_KALLSYMS_ALL=y
CONFIG_MEMCG=y
CONFIG_MEMCG_SWAP=y
CONFIG_MEMCG_KMEM=y
CONFIG_CGROUP_PIDS=y
CONFIG_CGROUP_HUGETLB=y
CONFIG_CGROUP_DEVICE=y
CONFIG_CGROUP_FREEZER=y
CONFIG_CGROUP_CPUACCT=y
CONFIG_CGROUP_PERF=y
CONFIG_CGROUP_DEBUG=y
CONFIG_SOCK_CGROUP_DATA=y
CONFIG_NETPRIO_CGROUP=y
CONFIG_BLK_CGROUP=y
CONFIG_BLK_DEV_THROTTLING=y
CONFIG_CFQ_GROUP_IOSCHED=y
CONFIG_CFQ_GROUP_IOSCHED_BENCHMARK=y
CONFIG_DEFAULT_CFQ=y
CONFIG_CFQ_GROUP_IOSCHED_DEFAULT=y
CONFIG_DEFAULT_BFQ=y
CONFIG_BFQ_GROUP_IOSCHED=y
CONFIG_PID_LINKED=y
CONFIG_ZSWAP=y
CONFIG_ZSMALLOC=y
CONFIG_ZSMALLOC_STAT=y
CONFIG_ZSMALLOC_CHUNK_SHIFT=11
CONFIG_ZSMALLOC_DEBUG=y
CONFIG_ZSWAP_DEFAULT_ON=y
CONFIG_ZSWAP_COMPRESSOR_DEFAULT="lzo"
CONFIG_ZSWAP_COMPRESSOR_DEFAULT_LZO=y
CONFIG_ZBUD=y
CONFIG_Z3FOLD=y
CONFIG_GENERIC_EARLY_IOPORT_MAP=y
CONFIG_FB=y
CONFIG_FB_LOGO_EXTRA=y
CONFIG_SND=y
CONFIG_SND_PCM_OSS=y
CONFIG_SND_HWDEP=y
CONFIG_SND_SEQUENCER=y
CONFIG_SND_OSSEMUL=y
CONFIG_SND_MIXER_OSS=y
CONFIG_SND_PCM_OSS_PLUGINS=y
CONFIG_SND_DYNAMIC_MINORS=y
CONFIG_SND_MAX_CARDS=32
CONFIG_SND_VIA82XX=y
CONFIG_SND_VIA82XX_MODEM=y
CONFIG_SND_SB_COMMON=y
CONFIG_SND_SB16DSP=y
CONFIG_SND_SB16_CSP=y
CONFIG_SND_PCM=y
CONFIG_SND_TIMER=y
CONFIG_SND_HWDEP=y
CONFIG_SND_RAWMIDI=y
CONFIG_SND_SEQ_DEVICE=y
CONFIG_SND_JACK=y
CONFIG_SND_JACK_INPUT_DEVICES=y
CONFIG_SND_JACK_ZC121石家庄=y
CONFIG_SND_HDA_CORE=y
CONFIG_SND_HDA=y
CONFIG_SND_HDA_CODEC_REALTEK=y
CONFIG_SND_HDA_CODEC_ANALOG=y
CONFIG_SND_HDA_CODEC_SIGMATEL=y
CONFIG_SND_HDA_CODEC_VIA=y
CONFIG_SND_HDA_CODEC_HDMI=y
CONFIG_SND_HDA_CODEC_CIRRUS=y
CONFIG_SND_HDA_CODEC_CONEXANT=y
CONFIG_SND_HDA_CODEC_CA0132=y
CONFIG_SND_HDA_CODEC_QCOM=y
CONFIG_SND_HDA_CODEC_ALL=y
CONFIG_SND_HDA_HWDEP=y
CONFIG_SND_HDA_RECONFIG=y
CONFIG_SND_HDA_INPUT_BEEP=y
CONFIG_SND_HDA_INPUT_BEEP_MODE=1
CONFIG_SND_HDA_PATCH_LOADER=y
CONFIG_SND_HDA_CODEC_FIXUP_RATE_TABLE=y
CONFIG_SND_HDA_INTEL=y
CONFIG_SND_HDA_INTEL_DWDEBUG=0
CONFIG_SND_HDA_GENERIC=y
CONFIG_SND_HDA_MIXER_OSS=y
CONFIG_SND_HDA_POWER_SAVE_DEFAULT=1
CONFIG_SND_HDA_VGA=y
CONFIG_SND_SOC=y
CONFIG_SOUND_OSS_CORE=y
CONFIG_SOUND_OSS_CORE_PRECLAIM=y
CONFIG_SND_PCM_TIMER=y
CONFIG_SND_SOC_INTEL_SST=y
CONFIG_SND_SOC_INTEL_SST_FIRMWARE=y
CONFIG_SND_SOC_INTEL_HASWELL=y
CONFIG_SND_SOC_INTEL_BYT=y
CONFIG_SND_SOC_INTEL_BDWRT5667=y
CONFIG_SND_SOC_INTEL_BYTCR_RT5640=y
CONFIG_SND_SOC_INTEL_BYTCR_RT5651=y
CONFIG_SND_SOC_INTEL_CHT_CX2072X=y
CONFIG_SND_SOC_INTEL_CHT_TI_RT5640=y
CONFIG_SND_SOC_INTEL_CHT_TI_RT5651=y
CONFIG_SND_SOC_INTEL_SKL=y
CONFIG_SND_SOC_INTEL_KBL=y
CONFIG_SND_SOC_INTEL_GLK=y
CONFIG_SND_SOC_INTEL_CNL=y
CONFIG_SND_SOC_INTEL_CFL=y
CONFIG_SND_SOC_INTEL_CML_H=y
CONFIG_SND_SOC_INTEL_CML_L=y
CONFIG_SND_SOC_INTEL_EHL=y
CONFIG_SND_SOC_ACPI=y
CONFIG_SND_SOC_ACPI_INTEL_MATCH=y
CONFIG_SND_SOC_INTEL_SOUNDWIRE_SIMPLE_MATCH=y
CONFIG_SND_SOC_INTEL_SOUNDWIRE=y
CONFIG_SND_SOC_INTEL_SOUNDWIRE_INTEL=y
CONFIG_SND_SOC_ACPI_INTEL_SOUNDWIRE_MATCH=y
CONFIG_SND_SOC_SOF=y
CONFIG_SND_SOC_SOF_DEBUG_PROBES=y
CONFIG_SND_SOC_SOF_INTEL_SOUNDWIRE=y
CONFIG_SND_SOC_SOF_XEON_SPILLED_REGS=y
CONFIG_SND_SOC_SOF_DEBUG_PROBES_TRACES=y
CONFIG_SND_SOC_SOF_INTEL_PCI=y
CONFIG_SND_SOC_SOF_INTEL_APL=y
CONFIG_SND_SOC_SOF_INTEL_CNL=y
CONFIG_SND_SOC_SOF_INTEL_CFL=y
CONFIG_SND_SOC_SOF_INTEL_TGL=y
CONFIG_SND_SOC_SOF_INTEL_TGL_H=y
CONFIG_SND_SOC_SOF_INTEL_EHL=y
CONFIG_SND_SOC_SOF_INTEL_CML_H=y
CONFIG_SND_SOC_SOF_INTEL_CML_L=y
CONFIG_SND_SOC_SOF_ACPI=y
CONFIG_SND_SOC_SOF_DEBUG_PROBES_TRACES=y
CONFIG_SND_SOC_SOF_DEBUG_PROBES_TRACES_SOUNDWIRE=y
CONFIG_SND_SOC_SOUNDWIRE=y
CONFIG_SND_SOC_SOUNDWIRE_INTEL=y
CONFIG_SND_SOC_SOF_DEBUG_PROBES_TRACES_SOUNDWIRE=y
CONFIG_SND_SOC_CX2072X=y
CONFIG_SND_SOC_SOF_DEBUG_PROBES_TRACES_SOUNDWIRE=y
CONFIG_SND_SOC_SOF_DEBUG_PROBES_TRACES_HDA=y
CONFIG_SND_SOC_SOF_DEBUG_PROBES_TRACES_HDA_CODEC=y
CONFIG_SND_SOC_SOF_DEBUG_PROBES_TRACES_HDA_DAI_LINK=y
CONFIG_SND_SOC_SOF_DEBUG_PROBES_TRACES_HDA_DMA=y
CONFIG_SND_SOC_SOF_DEBUG_PROBES_TRACES_HDA_STREAM=y
CONFIG_SND_SOC_SOF_DEBUG_PROBES_TRACES_HDA_VENDOR=y
CONFIG_SND_SOC_SOF_DEBUG_PROBES_TRACES_SOUNDWIRE=y
CONFIG_SND_SOC_SOF_DEBUG_PROBES_TRACES_SOUNDWIRE_CODEC=y
CONFIG_SND_SOC_SOF_DEBUG_PROBES_TRACES_SOUNDWIRE_DAI_LINK=y
CONFIG_SND_SOC_SOF_DEBUG_PROBES_TRACES_SOUNDWIRE_STREAM=y
CONFIG_SND_SOC_SOF_DEBUG_PROBES_TRACES_SOUNDWIRE_VENDOR=y
CONFIG_SND_SOC_SOF_DEBUG_PROBES_TRACES_SOUNDWIRE_DMIC=y
CONFIG_SND_SOC_SOF_DEBUG_PROBES_TRACES_SOUNDWIRE_SOUNDWIRE=y
CONFIG_SND_SOC_SOF_DEBUG_PROBES_TRACES_SOUNDWIRE_SOUNDWIRE_CODEC=y
CONFIG_SND_SOC_SOF_DEBUG_PROBES_TRACES_SOUNDWIRE_SOUNDWIRE_DAI_LINK=y
CONFIG_SND_SOC_SOF_DEBUG_PROBES_TRACES_SOUNDWIRE_SOUNDWIRE_STREAM=y
CONFIG_SND_SOC_SOF_DEBUG_PROBES_TRACES_SOUNDWIRE_SOUNDWIRE_VENDOR=y
CONFIG_SND_SOC_SOF_DEBUG_PROBES_TRACES_SOUNDWIRE_SOUNDWIRE_DMIC=y
CONFIG_SND_SOC_SOF_DEBUG_PROBES_TRACES_SOUNDWIRE_SOUNDWIRE_SOUNDWIRE=y
CONFIG_SND_SOC_SOF_DEBUG_PROBES_TRACES_SOUNDWIRE_SOUNDWIRE_SOUNDWIRE_CODEC=y
CONFIG_SND_SOC_SOF_DEBUG_PROBES_TRACES_SOUNDWIRE_SOUNDWIRE_SOUNDWIRE_DAI_LINK=y
CONFIG_SND_SOC_SOF_DEBUG_PROBES_TRACES_SOUNDWIRE_SOUNDWIRE_SOUNDWIRE_STREAM=y
CONFIG_SND_SOC_SOF_DEBUG_PROBES_TRACES_SOUNDWIRE_SOUNDWIRE_SOUNDWIRE_VENDOR=y
CONFIG_SND_SOC_SOF_DEBUG_PROBES_TRACES_SOUNDWIRE_SOUNDWIRE_SOUNDWIRE_DMIC=y
CONFIG_SND_SOC_SOF_DEBUG_PROBES_TRACES_SOUNDWIRE_SOUNDWIRE_SOUNDWIRE_SOUNDWIRE=y
CONFIG_SND_SOC_SOF_DEBUG_PROBES_TRACES_SOUNDWIRE_SOUNDWIRE_SOUNDWIRE_SOUNDWIRE_CODEC=y
CONFIG_SND_SOC_SOF_DEBUG_PROBES_TRACES_SOUNDWIRE_SOUNDWIRE_SOUNDWIRE_SOUNDWIRE_DAI_LINK=y
CONFIG_SND_SOC_SOF_DEBUG_PROBES_TRACES_SOUNDWIRE_SOUNDWIRE_SOUNDWIRE_SOUNDWIRE_STREAM=y
CONFIG_SND_SOC_SOF_DEBUG_PROBES_TRACES_SOUNDWIRE_SOUNDWIRE_SOUNDWIRE_SOUNDWIRE_VENDOR=y
CONFIG_SND_SOC_SOF_DEBUG_PROBES_TRACES_SOUNDWIRE_SOUNDWIRE_SOUNDWIRE_SOUNDWIRE_DMIC=y
CONFIG_SND_SOC_SOF_DEBUG_PROBES_TRACES_SOUNDWIRE_SOUNDWIRE_SOUNDWIRE_SOUNDWIRE_SOUNDWIRE=y
CONFIG_SND_SOC_SOF_DEBUG_PROBES_TRACES_SOUNDWIRE_SOUNDWIRE_SOUNDWIRE_SOUNDWIRE_SOUNDWIRE_CODEC=y
CONFIG_SND_SOC_SOF_DEBUG_PROBES_TRACES_SOUNDWIRE_SOUNDWIRE_SOUNDWIRE_SOUNDWIRE_SOUNDWIRE_DAI_LINK=y
CONFIG_SND_SOC_SOF_DEBUG_PROBES_TRACES_SOUNDWIRE_SOUNDWIRE_SOUNDWIRE_SOUNDWIRE_SOUNDWIRE_STREAM=y
CONFIG_SND_SOC_SOF_DEBUG_PROBES_TRACES_SOUNDWIRE_SOUNDWIRE_SOUNDWIRE_SOUNDWIRE_SOUNDWIRE_VENDOR=y
CONFIG_SND_SOC_SOF_DEBUG_PROBES_TRACES_SOUNDWIRE_SOUNDWIRE_SOUNDWIRE_SOUNDWIRE_SOUNDWIRE_SOUNDWIRE_DMIC=y
CONFIG_SND_SOC_SOF_DEBUG_PROBES_TRACES_SOUNDWIRE_SOUNDWIRE_SOUNDWIRE_SOUNDWIRE_SOUNDWIRE_SOUNDWIRE_SOUNDWIRE=y
CONFIG_SND_SOC_SOF_DEBUG_PROBES_TRACES_SOUNDWIRE_SOUNDWIRE_SOUNDWIRE_SOUNDWIRE_SOUNDWIRE_SOUNDWIRE_SOUNDWIRE_CODEC=y
CONFIG_SND_SOC_SOF_DEBUG_PROBES_TRACES_SOUNDWIRE_SOUNDWIRE_SOUNDWIRE_SOUNDWIRE_SOUNDWIRE_SOUNDWIRE_SOUNDWIRE_DAI_LINK=y
CONFIG_SND_SOC_SOF_DEBUG_PROBES_TRACES_SOUNDWIRE_SOUNDWIRE_SOUNDWIRE_SOUNDWIRE_SOUNDWIRE_SOUNDWIRE_SOUNDWIRE_STREAM=y
CONFIG_SND_SOC_SOF_DEBUG_PROBES_TRACES_SOUNDWIRE_SOUNDWIRE_SOUNDWIRE_SOUNDWIRE_SOUNDWIRE_SOUNDWIRE_SOUNDWIRE_VENDOR=y
CONFIG_SND_SOC_SOF_DEBUG_PROBES_TRACES_SOUNDWIRE_SOUNDWIRE_SOUNDWIRE_SOUNDWIRE_SOUNDWIRE_SOUNDWIRE_SOUNDWIRE_DMIC=y
CONFIG_SND_SOC_SOF_DEBUG_PROBES_TRACES_SOUNDWIRE_SOUNDWIRE_SOUNDWIRE_SOUNDWIRE_SOUNDWIRE_SOUNDWIRE_SOUNDWIRE_SOUNDWIRE=y
CONFIG_SND_SOC_SOF_DEBUG_PROBES_TRACES_SOUNDWIRE_SOUNDWIRE_SOUNDWIRE_SOUNDWIRE_SOUNDWIRE_SOUNDWIRE_SOUNDWIRE_SOUNDWIRE_CODEC=y
CONFIG_SND_SOC_SOF_DEBUG_PROBES_TRACES_SOUNDWIRE_SOUNDWIRE_SOUNDWIRE_SOUNDWIRE_SOUNDWIRE_SOUNDWIRE_SOUNDWIRE_SOUNDWIRE_DAI_LINK=y
CONFIG_SND_SOC_SOF_DEBUG_PROBES_TRACES_SOUNDWIRE_SOUNDWIRE_SOUNDWIRE_SOUNDWIRE_SOUNDWIRE_SOUNDWIRE_SOUNDWIRE_SOUNDWIRE_STREAM=y
CONFIG_SND_SOC_SOF_DEBUG_PROBES_TRACES_SOUNDWIRE_SOUNDWIRE_SOUNDWIRE_SOUNDWIRE_SOUNDWIRE_SOUNDWIRE_SOUNDWIRE_SOUNDWIRE_VENDOR=y
CONFIG_SND_SOC_SOF_DEBUG_PROBES_TRACES_SOUNDWIRE_SOUNDWIRE_SOUNDWIRE_SOUNDWIRE_SOUNDWIRE_SOUNDWIRE_SOUNDWIRE_SOUNDWIRE_DMIC=y
CONFIG_SND_SOC_SOF_DEBUG_PROBES_TRACES_SOUNDWIRE_SOUNDWIRE_SOUNDWIRE_SOUNDWIRE_SOUNDWIRE_SOUNDWIRE_SOUNDWIRE_SOUNDWIRE_SOUNDWIRE=y
CONFIG_SND_SOC_SOF_DEBUG_PROBES_TRACES_SOUNDWIRE_SOUNDWIRE_SOUNDWIRE_SOUNDWIRE_SOUNDWIRE_SOUNDWIRE_SOUNDWIRE_SOUNDWIRE_SOUNDWIRE_CODEC=y
CONFIG_SND_SOC_SOF_DEBUG_PROBES_TRACES_SOUNDWIRE_SOUNDWIRE_SOUNDWIRE_SOUNDWIRE_SOUNDWIRE_SOUNDWIRE_SOUNDWIRE_SOUNDWIRE_SOUNDWIRE_DAI_LINK=y
CONFIG_SND_SOC_SOF_DEBUG_PROBES_TRACES_SOUNDWIRE_SOUNDWIRE_SOUNDWIRE_SOUNDWIRE_SOUNDWIRE_SOUNDWIRE_SOUNDWIRE_SOUNDWIRE_SOUNDWIRE_STREAM=y
CONFIG_SND_SOC_SOF_DEBUG_PROBES_TRACES_SOUNDWIRE_SOUNDWIRE_SOUNDWIRE_SOUNDWIRE_SOUNDWIRE_SOUNDWIRE_SOUNDWIRE_SOUNDWIRE_SOUNDWIRE_VENDOR=y
CONFIG_SND_SOC_SOF_DEBUG_PROBES_TRACES_SOUNDWIRE_SOUNDWIRE_SOUNDWIRE_SOUNDWIRE_SOUNDWIRE_SOUNDWIRE_SOUNDWIRE_SOUNDWIRE_SOUNDWIRE_DMIC=y
CONFIG_SND_SOC_SOF_DEBUG_PROBES_TRACES_SOUNDWIRE_SOUNDWIRE_SOUNDWIRE_SOUNDWIRE_SOUNDWIRE_SOUNDWIRE_SOUNDWIRE_SOUNDWIRE_SOUNDWIRE_SOUNDWIRE=y
CONFIG_SND_SOC_SOF_DEBUG_PROBES_TRACES_SOUNDWIRE_SOUNDWIRE_SOUNDWIRE_SOUNDWIRE_SOUNDWIRE_SOUNDWIRE_SOUNDWIRE_SOUNDWIRE_SOUNDWIRE_SOUNDWIRE_CODEC=y
CONFIG_SND_SOC_SOF_DEBUG_PROBES_TRACES_SOUNDWIRE_SOUNDWIRE_SOUNDWIRE_SOUNDWIRE_SOUNDWIRE_SOUNDWIRE_SOUNDWIRE_SOUNDWIRE_SOUNDWIRE_SOUNDWIRE_DAI_LINK=y
CONFIG_SND_SOC_SOF_DEBUG_PROBES_TRACES_SOUNDWIRE_SOUNDWIRE_SOUNDWIRE_SOUNDWIRE_SOUNDWIRE_SOUNDWIRE_SOUNDWIRE_SOUNDWIRE_SOUNDWIRE_SOUNDWIRE_STREAM=y
CONFIG_SND_SOC_SOF_DEBUG_PROBES_TRACES_SOUNDWIRE_SOUNDWIRE_SOUNDWIRE_SOUNDWIRE_SOUNDWIRE_SOUNDWIRE_SOUNDWIRE_SOUNDWIRE_SOUNDWIRE_SOUNDWIRE_VENDOR=y
CONFIG_SND_SOC_SOF_DEBUG_PROBES_TRACES_SOUNDWIRE_SOUNDWIRE_SOUNDWIRE_SOUNDWIRE_SOUNDWIRE_SOUNDWIRE_SOUNDWIRE_SOUNDWIRE_SOUNDWIRE_SOUNDWIRE_DMIC=y
CONFIG_SND_SOC_SOF_DEBUG_PROBES_TRACES_SOUNDWIRE_SOUNDWIRE_SOUNDWIRE_SOUNDWIRE_SOUNDWIRE_SOUNDWIRE_SOUNDWIRE_SOUNDWIRE_SOUNDWIRE_SOUNDWIRE_SOUNDWIRE=y
CONFIG_SND_SOC_SOF_DEBUG_PROBES_TRACES_SOUNDWIRE_SOUNDWIRE_SOUNDWIRE_SOUNDWIRE_SOUNDWIRE_SOUNDWIRE_SOUNDWIRE_SOUNDWIRE_SOUNDWIRE_SOUNDWIRE_SOUNDWIRE_CODEC=y
CONFIG_SND_SOC_SOF_DEBUG_PROBES_TRACES_SOUNDWIRE_SOUNDWIRE_SOUNDWIRE_SOUNDWIRE_SOUNDWIRE_SOUNDWIRE_SOUNDWIRE_SOUNDWIRE_SOUNDWIRE_SOUNDWIRE_SOUNDWIRE_DAI_LINK=y
CONFIG_SND_SOC_SOF_DEBUG_PROBES_TRACES_SOUNDWIRE_SOUNDWIRE_SOUNDWIRE_SOUNDWIRE_SOUNDWIRE_SOUNDWIRE_SOUNDWIRE_SOUNDWIRE_SOUNDWIRE_SOUNDWIRE_SOUNDWIRE_STREAM=y
CONFIG_SND_SOC_SOF_DEBUG_PROBES_TRACES_SOUNDWIRE_SOUNDWIRE_SOUNDWIRE_SOUNDWIRE_SOUNDWIRE_SOUNDWIRE_SOUNDWIRE_SOUNDWIRE_SOUNDWIRE_SOUNDWIRE_SOUNDWIRE_VENDOR=y
CONFIG_SND_SOC_SOF_DEBUG_PROBES_TRACES_SOUNDWIRE_SOUNDWIRE_SOUNDWIRE_SOUNDWIRE_SOUNDWIRE_SOUNDWIRE_SOUNDWIRE_SOUNDWIRE_SOUNDWIRE_SOUNDWIRE_SOUNDWIRE_DMIC=y
CONFIG_SND_SOC_SOF_DEBUG_PROBES_TRACES_SOUNDWIRE_SOUNDWIRE_SOUNDWIRE_SOUNDWIRE_SOUNDWIRE_SOUNDWIRE_SOUNDWIRE_SOUNDWIRE_SOUNDWIRE_SOUNDWIRE_SOUNDWIRE_SOUNDWIRE=y
CONFIG_SND_SOC_SOF_DEBUG_PROBES_TRACES_SOUNDWIRE_SOUNDWIRE_SOUNDWIRE_SOUNDWIRE_SOUNDWIRE_SOUNDWIRE_SOUNDWIRE_SOUNDWIRE_SOUNDWIRE_SOUNDWIRE_SOUNDWIRE_SOUNDWIRE_CODEC=y
CONFIG_SND_SOC_SOF_DEBUG_PROBES_TRACES_SOUNDWIRE_SOUNDWIRE_SOUNDWIRE_SOUNDWIRE_SOUNDWIRE_SOUNDWIRE_SOUNDWIRE_SOUNDWIRE_SOUNDWIRE_SOUNDWIRE_SOUNDWIRE_SOUNDWIRE_DAI_LINK=y
CONFIG_SND_SOC_SOF_DEBUG_PROBES_TRACES_SOUNDWIRE_SOUNDWIRE_SOUNDWIRE_SOUNDWIRE_SOUNDWIRE_SOUNDWIRE_SOUNDWIRE_SOUNDWIRE_SOUNDWIRE_SOUNDWIRE_SOUNDWIRE_STREAM=y
CONFIG_SND_SOC_SOF_DEBUG_PROBES_TRACES_SOUNDWIRE_SOUNDWIRE_SOUNDWIRE_SOUNDWIRE_SOUNDWIRE_SOUNDWIRE_SOUNDWIRE_SOUNDWIRE_SOUNDWIRE_SOUNDWIRE_SOUNDWIRE_SOUNDWIRE_VENDOR=y
CONFIG_SND_SOC_SOF_DEBUG_PROBES_TRACES_SOUNDWIRE_SOUNDWIRE_SOUNDWIRE_SOUNDWIRE_SOUNDWIRE_SOUNDWIRE_SOUNDWIRE_SOUNDWIRE_SOUNDWIRE_SOUNDWIRE_SOUNDWIRE_SOUNDWIRE_DMIC=y
EOF

    # Build kernel
    make -j$(nproc) headers
    make -j$(nproc) olddefconfig
    make -j$(nproc) -DCONFIG_CC_OPTIMIZE_FOR_SIZE=y bzImage
    make -j$(nproc) modules
    make modules_install
    make install

    log_success "Kernel built and installed"
}

install_packages() {
    log_info "Installing packages..."

    # Core packages
    sudo chroot chroot /bin/bash -c "
        export DEBIAN_FRONTEND=noninteractive
        apt-get update
        apt-get install -y ${CORE_PACKAGES[*]}
    "

    # Desktop packages
    sudo chroot chroot /bin/bash -c "
        export DEBIAN_FRONTEND=noninteractive
        apt-get install -y ${DESKTOP_PACKAGES[*]}
    "

    # Productivity packages
    sudo chroot chroot /bin/bash -c "
        export DEBIAN_FRONTEND=noninteractive
        apt-get install -y ${PRODUCTIVITY_PACKAGES[*]}
    "

    # Development packages
    sudo chroot chroot /bin/bash -c "
        export DEBIAN_FRONTEND=noninteractive
        apt-get install -y ${DEV_PACKAGES[*]}
    "

    # Performance packages
    sudo chroot chroot /bin/bash -c "
        export DEBIAN_FRONTEND=noninteractive
        apt-get install -y ${PERFORMANCE_PACKAGES[*]}
    "

    # App store packages
    sudo chroot chroot /bin/bash -c "
        export DEBIAN_FRONTEND=noninteractive
        apt-get install -y ${APPSTORE_PACKAGES[*]}
    "

    log_success "Packages installed"
}

configure_system() {
    log_info "Configuring Piexed OS system..."

    # Set hostname
    echo "piexed-os" | sudo tee chroot/etc/hostname
    echo "127.0.1.1    piexed-os" | sudo tee -a chroot/etc/hosts

    # Configure locale
    sudo chroot chroot /bin/bash -c "
        echo 'LANG=en_US.UTF-8' > /etc/default/locale
        echo 'LC_ALL=en_US.UTF-8' >> /etc/default/locale
        sed -i '/en_US.UTF-8/s/^#//' /etc/locale.gen
        locale-gen
    "

    # Configure network
    sudo cp config/interfaces chroot/etc/network/interfaces
    sudo cp config/resolv.conf chroot/etc/resolv.conf 2>/dev/null || true

    # Configure APT
    sudo cp config/sources.list chroot/etc/apt/sources.list
    sudo chroot /bin/bash -c "
        echo 'APT::Install-Recommends \"false\";' > /etc/apt/apt.conf.d/99piexed
        echo 'APT::Get::AutomaticRemove \"true\";' >> /etc/apt/apt.conf.d/99piexed
    "

    log_success "System configured"
}

configure_desktop() {
    log_info "Configuring desktop environment..."

    # Copy desktop configuration
    sudo cp -r config/desktop/* chroot/etc/piexed/desktop/

    # Configure display manager
    sudo chroot /bin/bash -c "
        echo '[Seat:*]' > /etc/lightdm/lightdm.conf.d/99-piexed.conf
        echo 'greeter-session=lightdm-gtk-greeter' >> /etc/lightdm/lightdm.conf.d/99-piexed.conf
        echo 'user-session=xfce' >> /etc/lightdm/lightdm.conf.d/99-piexed.conf
        echo 'allow-user-switching=true' >> /etc/lightdm/lightdm.conf.d/99-piexed.conf
        echo 'autologin-user=piexed' >> /etc/lightdm/lightdm.conf.d/99-piexed.conf
    "

    # Configure XFCE
    mkdir -p chroot/etc/skel/.config/xfce4
    sudo cp config/xfce4/xfconf/xfce-perchannel-xml/xfce4-panel.xml chroot/etc/skel/.config/xfce4/xfconf/xfce-perchannel-xml/
    sudo cp config/xfce4/xfconf/xfce-perchannel-xml/xfwm4.xml chroot/etc/skel/.config/xfce4/xfconf/xfce-perchannel-xml/

    log_success "Desktop configured"
}

create_users() {
    log_info "Creating user accounts..."

    # Create default user
    sudo chroot /bin/bash -c "
        useradd -m -s /bin/bash -G sudo,adm,cdrom,floppy,audio,dip,video,plugdev,netdev,lxd piexed
        echo 'piexed:piexed' | chpasswd
        echo 'root:piexed' | chpasswd
    "

    log_success "Users created"
}

install_branding() {
    log_info "Installing Piexed OS branding..."

    # Install splash screen
    sudo mkdir -p chroot/etc/alternatives
    sudo cp branding/splash.png chroot/usr/share/plymouth/plymouth_default_theme.png

    # Install theme
    sudo cp -r branding/theme/* chroot/usr/share/themes/Piexed/

    # Install icons
    sudo cp -r branding/icons/* chroot/usr/share/icons/Piexed/

    # Update desktop database
    sudo chroot /bin/bash -c "update-desktop-database /usr/share/applications"
    sudo chroot /bin/bash -c "gtk-update-icon-cache /usr/share/icons/Piexed"

    log_success "Branding installed"
}

configure_boot() {
    log_info "Configuring boot system..."

    # Configure GRUB
    sudo chroot /bin/bash -c "
        cat > /etc/default/grub << 'EOF'
GRUB_DEFAULT=0
GRUB_TIMEOUT=10
GRUB_DISTRIBUTOR='Piexed OS'
GRUB_GFXMODE=1280x720
GRUB_GFXPAYLOAD=keep
GRUB_TERMINAL=console
GRUB_CMDLINE_LINUX_DEFAULT='quiet splash loglevel=3'
GRUB_CMDLINE_LINUX='zram.enabled=1 zram.fraction=0.5'
EOF
        update-grub
    "

    # Install Plymouth
    sudo cp branding/plymouth/theme.distributed chroot/usr/share/plymouth/themes/piexed/

    log_success "Boot configured"
}

install_piexed_store() {
    log_info "Installing Piexed App Store..."

    # Create App Store package
    mkdir -p packages/piexed-store
    cat > packages/piexed-store/DEBIAN/control << 'EOF'
Package: piexed-store
Version: 1.0.0
Section: utils
Priority: optional
Architecture: all
Depends: gnome-software, flatpak, snapd, python3-gi
Maintainer: Piexed OS Team <contact@piexed-os.org>
Description: Piexed OS App Store
 A modern, user-friendly application store for Piexed OS
EOF

    # Copy application files
    cp -r app-store/* packages/piexed-store/
    sudo dpkg-deb --build packages/piexed-store
    sudo chroot /bin/bash -c "dpkg -i /tmp/piexed-store.deb"

    log_success "App Store installed"
}

create_iso() {
    log_info "Creating ISO image..."

    cd "${WORKSPACE}"

    # Build SquashFS
    sudo mksquashfs chroot squashfs/filesystem.squashfs -comp xz -b 1M -no-exports

    # Create boot structure
    mkdir -p image/boot/grub/x86_64-efi
    mkdir -p image/boot/grub/i386-pc
    mkdir -p image/live

    # Copy kernel and initrd
    cp chroot/boot/vmlinuz-* image/live/vmlinuz
    cp chroot/boot/initrd.img-* image/live/initrd

    # Create GRUB config
    cat > image/boot/grub/grub.cfg << 'EOF'
set default="0"
set timeout="10"

menuentry "Piexed OS" {
    set gfxpayload=keep
    linux /live/vmlinuz boot=live config quiet splash
    initrd /live/initrd
}

menuentry "Piexed OS (safe graphics)" {
    set gfxpayload=keep
    linux /live/vmlinuz boot=live nomodeset
    initrd /live/initrd
}

menuentry "Piexed OS (recovery)" {
    set gfxpayload=keep
    linux /live/vmlinuz boot=live single
    initrd /live/initrd
}
EOF

    # Create EFI boot
    grub-mkimage -O x86_64-efi -o image/boot/grub/x86_64-efi/grub.efi boot part part_gpt part_msdos normal search search_fs_file efi_gop efi_uga gfxterm gfxterm_background test all_video png
    grub-mkimage -O i386-pc -o image/boot/grub/i386-pc/core.img boot part part_gpt part_msdos normal search search_fs_file bios_disk search_fs_uuid
    cat > image/boot/grub/i386-pc/grub.cfg << 'EOF'
set default=0
set timeout=10

menuentry "Piexed OS" {
    linux16 /boot/grub/i386-pc/normal.mod
}
EOF

    # Copy SquashFS
    cp squashfs/filesystem.squashfs image/live/

    # Create ISO
    xorriso -as mkisofs \
        -iso-level 3 \
        -full-iso9660-filenames \
        -volid "PIEXED_OS_${PIEXED_VERSION}" \
        -appid "Piexed OS ${PIEXED_VERSION}" \
        -publisher "Piexed OS Team" \
        -preparer "Piexed OS Build System" \
        -eltorito-boot boot/grub/bios.img \
        -no-emul-boot \
        -boot-load-size 4 \
        -boot-info-table \
        -eltorito-catalog boot.cat \
        -eltorito-alt-boot \
        -e EFI/efiboot.img \
        -no-emul-boot \
        -isohybrid-gpt-basdat \
        -output "${OUTPUT_DIR}/piexed-os-${PIEXED_VERSION}.iso" \
        image/

    log_success "ISO created: ${OUTPUT_DIR}/piexed-os-${PIEXED_VERSION}.iso"
}

cleanup_chroot() {
    log_info "Cleaning up..."

    sudo umount chroot/proc chroot/sys chroot/dev/pts chroot/dev 2>/dev/null || true

    log_success "Cleanup complete"
}

# Main execution
main() {
    echo -e "${BLUE}"
    echo "=========================================="
    echo "   Piexed OS Build System v${PIEXED_VERSION}"
    echo "   Codename: ${PIEXED_CODENAME}"
    echo "=========================================="
    echo -e "${NC}"

    log_info "Starting build process..."

    check_dependencies
    create_directories
    download_base_system
    configure_chroot
    install_kernel
    install_packages
    configure_system
    configure_desktop
    create_users
    install_branding
    configure_boot
    install_piexed_store
    create_iso
    cleanup_chroot

    log_success "Build completed successfully!"
    log_info "ISO available at: ${OUTPUT_DIR}/piexed-os-${PIEXED_VERSION}.iso"

    echo -e "${GREEN}"
    echo "=========================================="
    echo "   Build Complete!"
    echo "=========================================="
    echo -e "${NC}"
}

main "$@"