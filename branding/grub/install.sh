#!/bin/bash
# Piẻxed OS GRUB Theme Installer

set -e

THEME_DIR="/boot/grub/themes/piexed"

echo "Installing Piẻxed OS GRUB Theme..."

sudo mkdir -p "$THEME_DIR"

sudo cp -r grub-theme-piexed/* "$THEME_DIR/"

if [ -f "$THEME_DIR/theme.txt" ]; then
    if ! grep -q "piexed" /etc/default/grub 2>/dev/null; then
        echo 'GRUB_THEME="/boot/grub/themes/piexed/theme.txt"' | sudo tee -a /etc/default/grub > /dev/null
    fi
    sudo update-grub
fi

echo "GRUB theme installed successfully!"