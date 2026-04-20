#!/bin/bash
#
# Piẻxed OS - Development & Music Production Suite
# For Software Engineers, Hackers & Music Producers
#

set -e

GREEN='\033[0;32m'
NC='\033[0m'

log() { echo -e "${GREEN}[✓]${NC} $1"; }

echo "=========================================="
echo "  Piẻxed OS - Dev & Music Tools"
echo "=========================================="

# ============================================
# PART 1: DEVELOPMENT IDEs & EDITORS
# ============================================
log "Installing Development Tools..."

apt-get update -qq
apt-get install -y \
    # Code Editors & IDEs
    vim \
    vim-gtk3 \
    neovim \
    vscode \
    atom \
    sublime-text \
    emacs \
    emacs-nox \
    geany \
    chKt \
    
    # AI/ML Development
    python3 \
    python3-pip \
    python3-venv \
    python3-dev \
    python3-numpy \
    python3-scipy \
    python3-matplotlib \
    python3-pandas \
    python3-sklearn \
    python3-tensorflow \
    python3-keras \
    python3-pytorch \
    jupyter \
    jupyter-notebook \
    ipython3 \
    ipython3-notebook \
    
    # Node.js Development  
    nodejs \
    npm \
    yarn \
    npx \
    nodejs-dev \
    nodejs-doc \
    
    # Java Development
    openjdk-17-jdk \
    openjdk-17-jre \
    maven \
    gradle \
    eclipse \
    
    # Rust Development
    rustc \
    cargo \
    rustfmt \
    rls \
    
    # Go Development
    golang-go \
    
    # C/C++ Development
    build-essential \
    gcc \
    g++ \
    gdb \
    cmake \
    ninja-build \
    clang \
    lldb \
    
    # Database Development
    mysql-client \
    postgresql-client \
    redis-tools \
    sqlite3 \
    mongosh \
    mariadb-client \
    
    # Web Development
    apache2 \
    nginx \
    php \
    php-fpm \
    php-mysql \
    php-cli \
    php-curl \
    php-gd \
    php-mbstring \
    php-xml \
    php-zip \
    php-json \
    composer \
    ruby \
    ruby-dev \
    perl \
    
    # Version Control
    git \
    git-lfs \
    gitk \
    git-gui \
    subversion \
    
    # Container Development
    docker.io \
    docker-compose \
    kubectl \
    minikube \
    
    # Cloud Tools
    awscli \
    google-cloud-sdk \
    azure-cli \
    
    # API Testing
    postman \
    insomnia \
    curl \
    httpie \
    wget \
    
    # DevOps Tools
    terraform \
    ansible \
    puppet \
    vagrant \
    packer \
    
    # Testing Tools
    pytest \
    phpunit \
    mocha \
    jasmine \
    
    # Documentation
    sphinx \
    doxygen \
    markdown \
    
    # Scripting
    bash \
    zsh \
    fish \
    powerline \
    shellcheck \
    hadolint

# ============================================
# PART 2: LOCAL DEVELOPMENT SERVER
# ============================================
log "Installing Local Development Server..."

# LAMP Stack
apt-get install -y \
    apache2 \
    libapache2-mod-php \
    php \
    php-fpm \
    php-mysql \
    mysql-server \
    postgresql \
    redis-server \
    
# Node.js Server
npm install -g \
    express \
    nodemon \
    http-server \
    pm2

# Python Server  
pip3 install \
    flask \
    django \
    fastapi \
    uvicorn \
    gunicorn \
    jupyter

# Create dev server launcher
cat > /usr/local/bin/piexed-devserver << 'DEV'
#!/bin/bash
echo "=== Piẻxed OS Development Server ==="
echo ""
echo "1. Start Apache (PHP/MySQL)"
echo "2. Start Nginx (PHP)"
echo "3. Start Python Flask"
echo "4. Start Node.js"
echo "5. Start All"
read -p "Choose: " choice

case $choice in
    1) sudo systemctl start apache2 mysql ;;
    2) sudo systemctl start nginx php8.1-fpm ;;
    3) cd ~/projects && python3 -m flask run --host=0.0.0.0 ;;
    4) cd ~/projects && npm start ;;
    5) sudo systemctl start apache2 nginx mysql postgresql redis-server ;;
esac
DEV
chmod +x /usr/local/bin/piexed-devserver

# ============================================
# PART 3: MUSIC PRODUCTION
# ============================================
log "Installing Music Production Tools..."

apt-get install -y \
    # Digital Audio Workstations
    ardour \
    qtractor \
    rosgarden \
    muse \
    audacity \
    hydrogen \
    
    # Plugins & Synthesis
    synth \
    phasex \
    amsynth \
    swh-lv2 \
    invada-lv2-plugins \
    mcp-plugins \
    lsp-plugins \
    \
    # Instruments
    piano \
    fluidsynth \
    qsynth \
    sf2fonts-rom-places \
    sf2fonts-s generaluser \
    \
    # Effects
    jamin \
    jconv \
    ecasound \
    \
    # DJ Tools
    mixxx \
    qlandkarte \
    \
    # Audio Editors
    audacity \
    sox \
    audio-recorder \
    \
    # Streaming
    obs-studio \
    \
    # Tools
    alsa-utils \
    jackd2 \
    qjackctl \
    jackd \
    pulseaudio \
    pavucontrol \
    simple-scan \
    easytag \
    kid3 \
    mp3gain \
    id3tool

# Create music production launcher
cat > /usr/local/bin/piexis-music << 'MUSIC'
#!/bin/bash
echo "=== Piẻxed OS Music Studio ==="
echo ""
echo "1. Ardour (DAW)"
echo "2. Audacity (Editor)"
echo "3. Hydrogen (Drums)"
echo "4. Qtractor (Sequencer)"
echo "5. Mixxx (DJ)"
echo "6. OBS Studio (Streaming)"
read -p "Choose: " choice

case $choice in
    1) ardour & ;;
    2) audacity & ;;
    3) hydrogen & ;;
    4) qtractor & ;;
    5) mixxx & ;;
    6) obs & ;;
esac
MUSIC
chmod +x /usr/local/bin/pievix-music

# ============================================
# PART 4: HACKER TOOLS
# ============================================
log "Installing Hacker Tools..."

# Add Kali repo temporarily
echo "deb http://http.kali.org/kali kali-rolling main" | sudo tee /etc/apt/sources.list.d/kali.list
curl -fsSL https://archive.kali.org/archive-key.asc | sudo gpg -o /etc/apt/trusted.gpg.d/kali.gpg 2>/dev/null || true
apt-get update -qq 2>/dev/null || true

# Install key hacking tools
apt-get install -y \
    nmap \
    zenmap \
    nikto \
    sqlmap \
    msfpayload \
    msfvenom \
    searchsploit \
    hashcat \
    john \
    hydra \
    crowbar \
    aircrack-ng \
    reaver \
    beef-xss \
    zaproxy \
    burpsuite \
    netcat \
    netdiscover \
    enum4linux \
    ldapsearch \
    smbclient \
    redis-tools

# Remove Kali repo
sudo rm /etc/apt/sources.list.d/kali.list
apt-get update -qq 2>/dev/null || true

# ============================================
# PART 5: LOW-END PC OPTIMIZATION
# ============================================
log "Optimizing for Low-End PC..."

# Optimize apt
echo "APT::Acquire::http {Pipeline-Depth \"5\";};" | sudo tee /etc/apt/apt.conf.d/99optimize

# Disable unnecessary services
services_to_disable=(
    cups
    bluetooth
    apache2
    mysql
    postgresql
)

for svc in "${services_to_disable[@]}"; do
    sudo systemctl stop $svc 2>/dev/null || true
    sudo systemctl disable $svc 2>/dev/null || true
done

# Optimize desktop for low RAM
cat > /etc/xdg/autostart/lowmem.desktop << 'LOWMEM'
[Desktop Entry]
Type=Application
Name=Memory Optimizer
Exec=piexed-optimize
LOWMEM

# Create quick optimization commands
cat > /usr/local/bin/piexed-lowend << 'LOWEND'
#!/bin/bash
echo "Optimizing for low-end PC..."

# Reduce swappiness
echo 5 | sudo tee /proc/sys/vm/swappiness

# Clear cache
sudo sync
echo 3 | sudo tee /proc/sys/vm/drop_caches

# Kill unnecessary processes
sudo pkill -9 chrome 2>/dev/null || true
sudo pkill -9 electron 2>/dev/null || true

# Show optimized
free -h
echo "Optimized for low RAM!"
LOWEND
chmod +x /usr/local/bin/piexed-lowend

# Disable animations
gsettings set org.gnome.desktop.interface enable-animations false 2>/dev/null || true

# ============================================
# CREATE ALL LAUNCHERS
# ============================================

cat > /usr/local/bin/pixed-devtools << 'DEVOPS'
#!/bin/bash
echo "╔══════════════════════════════════════════════╗"
echo "║      Piẻxed OS Dev Tools v1.0.0             ║"
echo "╚══════════════════════════════════════════════╝"
echo ""
echo "Development:"
echo "  code                 - VS Code"
echo "  atom                 - Atom Editor"  
echo "  vim                  - Vim"
echo "  python3             - Python"
echo "  ipython3            - IPython"
echo "  jupyter-notebook    - Jupyter"
echo "  node                - Node.js"
echo "  npm                 - NPM"
echo ""
echo "Servers:"
echo "  piexed-devserver    - Start local server"
echo "  piexed-music        - Music Studio"
echo "  pivis               - AI Assistant"
echo ""
echo "Optimization:"
echo "  piexed-lowend       - Optimize for low RAM"
echo "  piexed-optimize     - Clear cache"
echo ""
echo "Info:"
echo "  piexed-info        - System info"
DEVOPS
chmod +x /usr/local/bin/pixed-devtools

log "All tools installed!"
echo ""
echo "=========================================="
echo "  COMPLETE INSTALLATION DONE!"
echo "=========================================="
echo ""
echo "Development: code, atom, vim, python3, node"
echo "Servers: piexed-devserver"
echo "Music: piexed-music"
echo "Optimization: pixed-lowend"
echo ""
echo "Target Users:"
echo "  ✅ Software Engineers"
echo "  ✅ Professional Hackers"
echo "  ✅ Music Producers"
echo "  ✅ Low-End PC Users"