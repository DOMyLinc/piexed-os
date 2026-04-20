#!/bin/bash
#
# Piexed OS Desktop Environment Setup
# Configures XFCE with macOS-like experience
#

set -e

echo "=== Piexed OS Desktop Setup ==="

# Install desktop packages
apt-get update
apt-get install -y \
    xfce4 \
    xfce4-goodies \
    xfce4-terminal \
    thunar \
    mousepad \
    ristretto \
    lightdm \
    lightdm-gtk-greeter \
    xfce4-panel \
    xfce4-settings \
    xfce4-appfinder \
    xfwm4 \
    xfce4-notifyd \
    xfce4-power-manager \
    xfce4-session \
    xfce4-screenshooter \
    xfce4-taskmanager \
    xfce4-systemload-plugin \
    xfce4-cpufreq-plugin \
    xfce4-battery-plugin \
    xfce4-pulseaudio-plugin \
    xfce4-clipman-plugin \
    xfwm4-themes \
    xfce4-icon-theme \
    arc-theme \
    papirus-icon-theme \
    picom \
    feh

echo "Desktop packages installed"

# Create Piexed Desktop directories
mkdir -p ~/.config/xfce4
mkdir -p ~/.config/xfce4/panel
mkdir -p ~/.config/xfce4/xfconf/xfce-perchannel-xml
mkdir -p ~/.local/share/xfce4
mkdir -p ~/.local/share/themes
mkdir -p ~/.local/share/icons
mkdir -p ~/Pictures
mkdir -p ~/Documents
mkdir -p ~/Downloads

# Configure XFCE Panel
cat > ~/.config/xfce4/xfconf/xfce-perchannel-xml/xfce4-panel.xml << 'EOF'
<?xml version="1.0" encoding="UTF-8"?>
<channel name="xfce4-panel" version="1.0">
  <property name="configVersion" type="int" value="3"/>
  <property name="panels" type="array">
    <value type="struct">
      <property name="panelId" type="int" value="0"/>
      <property name="length" type="uint" value="100"/>
      <property name="position" type="string" value="p=6;x=0;y=0"/>
      <property name="length" type="uint" value="100"/>
      <property name="monitor" type="int" value="0"/>
      <property name="autohide" type="bool" value="false"/>
      <property name="autoHideDelay" type="int" value="500"/>
      <property name="autoHideLength" type="int" value="0"/>
      <property name="dock-position" type="string" value="BOTTOM"/>
      <property name="background-alpha" type="int" value="90"/>
    </value>
  </property>
  <property name="plugins" type="array">
    <value type="struct">
      <property name="panel" type="int" value="0"/>
      <property name="name" type="string" value="menu"/>
      <property name="enabled" type="bool" value="true"/>
      <property name="id" type="uint" value="0"/>
    </value>
    <value type="struct">
      <property name="panel" type="int" value="0"/>
      <property name="name" type="string" value="launcher"/>
      <property name="enabled" type="bool" value="true"/>
      <property name="id" type="uint" value="1"/>
      <property name="property" type="string" value="IIds"/>
    </value>
    <value type="struct">
      <property name="panel" type="int" value="0"/>
      <property name="name" type="string" value="actions"/>
      <property name="enabled" type="bool" value="true"/>
      <property name="id" type="uint" value="2"/>
    </value>
    <value type="struct">
      <property name="panel" type="int" value="0"/>
      <property name="name" type="string" value="pager"/>
      <property name="enabled" type="bool" value="true"/>
      <property name="id" type="uint" value="3"/>
    </value>
    <value type="struct">
      <property name="panel" type="int" value="0"/>
      <property name="name" type="string" value="tasklist"/>
      <property name="enabled" type="bool" value="true"/>
      <property name="id" type="uint" value="4"/>
    </value>
    <value type="struct">
      <property name="panel" type="int" value="0"/>
      <property name="name" type="string" value="systray"/>
      <property name="enabled" type="bool" value="true"/>
      <property name="id" type="uint" value="5"/>
    </value>
    <value type="struct">
      <property name="panel" type="int" value="0"/>
      <property name="name" type="string" value="clock"/>
      <property name="enabled" type="bool" value="true"/>
      <property name="id" type="uint" value="6"/>
    </value>
  </property>
</channel>
EOF

# Configure XFCE Window Manager
cat > ~/.config/xfce4/xfconf/xfce-perchannel-xml/xfwm4.xml << 'EOF'
<?xml version="1.0" encoding="UTF-8"?>
<channel name="xfwm4" version="1.0">
  <property name="activeFont" type="string" value="Sans 10"/>
  <property name="inactiveFont" type="string" value="Sans 10"/>
  <property name="titleFont" type="string" value="Sans Bold 10"/>
  <property name="titleAlignment" type="string" value="center"/>
  <property name="buttonLayout" type="string" value="|OMHE"/>
  <property name="buttonSpacing" type="int" value="0"/>
  <property name="minimizeOpacity" type="int" value="90"/>
  <property name="maximizeOpacity" type="int" value="100"/>
  <property name="shadowDeltaY" type="int" value="0"/>
  <property name="shadowDeltaX" type="int" value="0"/>
  <property name="shadowOpacity" type="int" value="30"/>
  <property name="shadowRadius" type="int" value="12"/>
  <property name="snapWidth" type="int" value="10"/>
  <property name="snapHeight" type="int" value="10"/>
  <property name="snapToBorder" type="bool" value="true"/>
  <property name="snapToWindows" type="bool" value="true"/>
  <property name="cycleMinimized" type="bool" value="false"/>
  <property name="cycleMinimize" type="bool" value="false"/>
  <property name="raiseWithClick" type="bool" value="true"/>
  <property name="clickToFocus" type="bool" value="false"/>
  <property name="raiseOnClick" type="bool" value="true"/>
  <property name="focusNew" type="bool" value="true"/>
  <property name="focusDelay" type="int" value="250"/>
  <property name="raiseDelay" type="int" value="250"/>
  <property name="theme" type="string" value="Piexed"/>
  <property name="workspace_count" type="int" value="4"/>
  <property name="wrapWorkspaces" type="bool" value="true"/>
  <property name="wrapWorkspacesOnDelete" type="bool" value="true"/>
  <property name="wrapCycle" type="bool" value="false"/>
  <property name="showTopBar" type="bool" value="true"/>
  <property name="showBottomBar" type="bool" value="false"/>
  <property name="showLeftBar" type="bool" value="false"/>
  <property name="showRightBar" type="bool" value="false"/>
</channel>
EOF

# Configure XFCE Appearance
cat > ~/.config/xfce4/xfconf/xfce-perchannel-xml/xsettings.xml << 'EOF'
<?xml version="1.0" encoding="UTF-8"?>
<channel name="xfce4-xsettings" version="1.0">
  <property name="Net/ThemeName" type="string" value="Arc-Dark"/>
  <property name="Net/IconThemeName" type="string" value="Papirus-Dark"/>
  <property name="Xft/Antialias" type="int" value="1"/>
  <property name="Xft/Hinting" type="int" value="1"/>
  <property name="Xft/HintStyle" type="string" value="hintfull"/>
  <property name="Xft/RGBA" type="string" value="rgb"/>
  <property name="Xft/DPI" type="int" value="-1"/>
  <property name="Gtk/ToolbarStyle" type="string" value="both-horiz"/>
  <property name="Gtk/ButtonImages" type="bool" value="true"/>
  <property name="Gtk/MenuImages" type="bool" value="true"/>
  <property name="Gtk/CursorThemeName" type="string" value="default"/>
  <property name="Gtk/CursorThemeSize" type="int" value="24"/>
  <property name="Net/SoundThemeName" type="string" value="freedesktop"/>
  <property name="Net/EnableEventSounds" type="bool" value="true"/>
  <property name="Net/EnableInputFeedbackSounds" type="bool" value="true"/>
</channel>
EOF

# Configure Thunar (File Manager)
mkdir -p ~/.config/Thunar

cat > ~/.config/Thunar/uca.xml << 'EOF'
<?xml version="1.0" encoding="UTF-8"?>
<actions>
  <action>
    <icon>utilities-terminal</icon>
    <name>Open Terminal Here</name>
    <command>xfce4-terminal --working-directory=%f</command>
    <description>Open terminal in this directory</description>
    <patterns>*</patterns>
    <directories/>
  </action>
  <action>
    <icon>document-new</icon>
    <name>Create File</name>
    <command>touch %n/%f</command>
    <description>Create new file</description>
    <patterns>*</patterns>
    <directories/>
  </action>
</actions>
EOF

# Configure LightDM
mkdir -p /etc/lightdm/lightdm.conf.d

cat > /etc/lightdm/lightdm.conf.d/99-piexed.conf << 'EOF'
[Seat:*]
autologin-user=piexed
user-session=xfce
greeter-session=lightdm-gtk-greeter
allow-user-switching=true
allow-guest=false

[SeatDefaults]
greeter-session=lightdm-gtk-greeter
user-session=xfce
xserver-command=X -core -nocursor
EOF

# Configure GTK
cat > ~/.config/gtk-3.0/settings.ini << 'EOF'
[Settings]
gtk-theme-name=Arc-Dark
gtk-icon-theme-name=Papirus-Dark
gtk-font-name=Sans 11
gtk-cursor-theme-name=default
gtk-cursor-theme-size=24
gtk-toolbar-style=GTK_TOOLBAR_BOTH_HORIZ
gtk-toolbar-icon-size=GTK_ICON_SIZE_LARGE_TOOLBAR
gtk-button-images=true
gtk-menu-images=true
gtk-show-tooltips=true
EOF

cat > ~/.config/gtk-2.0/gtkrc << 'EOF'
gtk-theme-name="Arc-Dark"
gtk-icon-theme-name="Papirus-Dark"
gtk-font-name="Sans 11"
gtk-cursor-theme-name="default"
gtk-cursor-theme-size=24
gtk-toolbar-style=GTK_TOOLBAR_BOTH_HORIZ
gtk-button-images=true
gtk-menu-images=true
EOF

# Configure Picom (Compositor)
mkdir -p ~/.config/picom.conf

cat > ~/.config/picom.conf << 'EOF'
# Piexed OS Picom Configuration
# Optimized for low-end hardware

backend = "glx";
glx-no-stencil = true;
glx-swap-method = "buffer-age";
use-damage = true;
xrender-sync-fence = true;

# Shadow
shadow = true;
shadow-radius = 12;
shadow-offset-x = -5;
shadow-offset-y = -5;
shadow-opacity = 0.3;
shadow-exclude = [
    "n:e:Notification",
    "n:e:Docky",
    "n:e:Plank",
    "n:e:Dockbarx",
    "g:e:Synapse",
    "g:e:Conky",
    "n:e:Steam",
    "n:e:mpv",
    "n:e:Firefox",
    "n:e:Chromium",
    "class_g = 'Terminator'",
    "class_g = 'Xfce4-terminal'"
];

# Transparency
opacity-rule = [
    "85:class_g = 'Xfce4-terminal'",
    "95:class_g = 'Ristretto'",
    "95:class_g = 'Thunar'",
    "90:class_g = 'Mousepad'"
];

# Fading
fading = true;
fade-in-step = 0.03;
fade-out-step = 0.03;
fade-time-step = 20;

# Performance
vsync = true;
dbe = false;
unredir-if-possible = false;
unredir-if-possible-exclude = [
    "class_g = 'Firefox'",
    "class_g = 'Chromium'"
];
detect-transient = true;
detect-client-leader = true;
EOF

# Configure autostart applications
mkdir -p ~/.config/autostart

cat > ~/.config/autostart/piexed-desktop.desktop << 'EOF'
[Desktop Entry]
Type=Application
Name=Piexed Desktop
Comment=Initialize Piexed OS desktop
Exec=/usr/local/bin/piexed-desktop-init.sh
Icon=piexed-logo
Terminal=false
Categories=System;
EOF

cat > ~/.config/autostart/picom.desktop << 'EOF'
[Desktop Entry]
Type=Application
Name=Picom
Comment=Window compositor
Exec=picom -b
Icon=picom
Terminal=false
Categories=System;
EOF

cat > ~/.config/autostart/nm-applet.desktop << 'EOF'
[Desktop Entry]
Type=Application
Name=Network Manager
Comment=Network connection manager
Exec=nm-applet
Icon=network-idle
Terminal=false
Categories=Network;
EOF

cat > ~/.config/autostart/clipman.desktop << 'EOF'
[Desktop Entry]
Type=Application
Name=Clipboard Manager
Comment=Clipboard manager
Exec=xfce4-clipman restart
Icon=edit-copy
Terminal=false
Categories=Utility;
EOF

# Create desktop icon directory
mkdir -p ~/.config/xfce4/desktop

cat > ~/.config/xfce4/desktop/icons.screen0-1223.rc << 'EOF'
[Desktop Entry]
Type=Directory
Icon=user-home
Name=Home
EOF

# Create Piexed menu
mkdir -p ~/.local/share/applications

cat > ~/.local/share/applications/piexed-menu.desktop << 'EOF'
[Desktop Entry]
Version=1.0
Type=Application
Name=Piexed Menu
Comment=Open Piexed application menu
Icon=strawberry
Exec=xfce4-appfinder --iconic
Terminal=false
Categories=System;
EOF

# Install Piexed themes
mkdir -p ~/.local/share/themes/Piexed

cat > ~/.local/share/themes/Piexed/gtk-3.0/gtk.css << 'EOF'
/* Piexed OS GTK Theme */
@import url("resource:///org/gtk/libgtk/theme/Arc-Dark/gtk.css");

/* Custom modifications for Piexed */
@define-color theme_primary #E63946;
@define-color theme_primary_dark #9D0208;
@define-color theme_primary_light #FF758F;

* {
    -gtk-primary-color: @theme_primary;
    -gtk-secondary-color: @theme_primary_light;
}

.button:hover {
    background-color: @theme_primary;
}

.titlebar {
    background-color: @theme_primary_dark;
}
EOF

echo "Desktop environment configured successfully!"