#!/bin/bash
# Piẻxed OS Plymouth Theme Installer

set -e

THEME_DIR="/usr/share/plymouth/themes/piexed"

echo "Installing Piẻxed OS Plymouth Theme..."

# Create theme directory
sudo mkdir -p "$THEME_DIR"

# Copy theme files
sudo cp -r plymouth-theme-piexed/* "$THEME_DIR/"

# Convert SVG to PNG if needed
if [ -f "$THEME_DIR/images/logo.png" ]; then
    echo "Logo found, skipping conversion"
elif [ -f "$THEME_DIR/images/logo.svg" ]; then
    echo "Converting SVG to PNG..."
    rsvg-convert -w 256 -h 256 "$THEME_DIR/images/logo.svg" > "$THEME_DIR/logo.png" 2>/dev/null || \
    convert -resize 256x256 "$THEME_DIR/images/logo.svg" "$THEME_DIR/logo.png" 2>/dev/null || \
    echo "Warning: Could not convert SVG, using placeholder"
fi

# Set theme as default
sudo plymouth-set-default-theme piexed || true

# Rebuild initramfs
sudo update-initramfs -u || true

echo "Plymouth theme installed successfully!"
echo "Reboot to see the new boot splash."