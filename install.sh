#!/bin/bash

# Exit on error
set -e

# Check for root privileges
if [ "$EUID" -ne 0 ]; then
    echo "Please run as root (e.g., sudo ./install.sh)"
    exit 1
fi

# Update system
echo "Updating system..."
pacman -Syu --noconfirm

# Install main packages
echo "Installing main packages..."
pacman -S --needed --noconfirm - < packages.txt

# Install yay for AUR packages
if ! command -v yay &> /dev/null; then
    echo "Installing yay..."
    pacman -S --needed --noconfirm git base-devel
    git clone https://aur.archlinux.org/yay.git
    cd yay
    makepkg -si --noconfirm
    cd ..
    rm -rf yay
fi

# Install AUR packages
if [ -s aur_packages.txt ]; then
    echo "Installing AUR packages..."
    yay -S --needed --noconfirm - < aur_packages.txt
fi

# Copy user configurations
echo "Applying user configurations..."
USER_HOME=$(getent passwd "$SUDO_USER" | cut -d: -f6)
cp -r {kdeglobals,kwinrc,plasmashellrc,plasma-org.kde.plasma.desktop-appletsrc,kcminputrc,baloofilerc,dolphinrc,konsolerc,plasma-localerc,kactivitymanagerdrc,powermanagementprofilesrc} "$USER_HOME/.config/" 2>/dev/null || true
mkdir -p "$USER_HOME/.config/fish"
cp -r fish/config.fish "$USER_HOME/.config/fish/" 2>/dev/null || true
cp -r alacritty "$USER_HOME/.config/" 2>/dev/null || true
chown -R "$SUDO_USER:$SUDO_USER" "$USER_HOME/.config"

# Copy system-wide configurations
echo "Applying system configurations..."
mkdir -p /etc/sddm.conf.d
cp -r sddm.conf.d/* /etc/sddm.conf.d/ 2>/dev/null || true

# Enable services
echo "Enabling services..."
systemctl enable sddm
systemctl enable NetworkManager
systemctl enable ufw 2>/dev/null || true
systemctl enable tailscale 2>/dev/null || true

# Note kernel parameters
if [ -f kernel_params.txt ]; then
    echo "Kernel parameters found. Please manually update /etc/default/grub with contents of kernel_params.txt"
fi

echo "Installation complete! Reboot to start KDE Plasma."
