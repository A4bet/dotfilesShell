#!/bin/bash

# Exit on errors
set -e

# Check for root privileges
if [[ $EUID -ne 0 ]]; then
    echo "This script must be run as root!"
    exit 1
fi

echo "Detecting CPU vendor..."
if grep -q "GenuineIntel" /proc/cpuinfo; then
    CPU_UCODE="intel-ucode"
    echo "Intel CPU detected. Installing intel-ucode..."
elif grep -q "AuthenticAMD" /proc/cpuinfo; then
    CPU_UCODE="amd-ucode"
    echo "AMD CPU detected. Installing amd-ucode..."
else
    echo "Unknown CPU vendor! Skipping microcode installation..."
    CPU_UCODE=""
fi

echo "Enabling ParallelDownloads in pacman.conf..."
sed -i 's/^#ParallelDownloads/ParallelDownloads/' /etc/pacman.conf

echo "Updating system packages..."
pacman -Syu --noconfirm

echo "Installing required packages..."
pacman -S --noconfirm qtile lxappearance nitrogen thunar firefox vim neofetch fastfetch \
    alacritty picom ufw archlinux-wallpaper lightdm lightdm-gtk-greeter alsa-utils \
    keepassxc flatpak git pacman-contrib xbindkeys flameshot ttf-jetbrains-mono-nerd \
    rofi polybar imagemagick xorg-xdpyinfo

# Install CPU microcode if detected
if [[ -n "$CPU_UCODE" ]]; then
    pacman -S --noconfirm "$CPU_UCODE"
fi

echo "Enabling UFW (Uncomplicated Firewall)..."
systemctl enable ufw

echo "Modifying GRUB timeout settings..."
sed -i 's/^GRUB_TIMEOUT_STYLE=menu/GRUB_TIMEOUT_STYLE=hidden/' /etc/default/grub
grub-mkconfig -o /boot/grub/grub.cfg

echo "Enabling system services..."
systemctl enable paccache.timer
systemctl enable lightdm.service

echo "Setting up Qtile configuration..."
CONFIG_DIR="/home/$SUDO_USER/.config"
mkdir -p "$CONFIG_DIR"
cd "$CONFIG_DIR"

echo "Cloning dotfiles..."
git clone https://github.com/A4bet/dotfiles.git /tmp/dotfiles

echo "Moving configuration files..."
mv /tmp/dotfiles/* "$CONFIG_DIR/"
mv $CONFIG_DIR/xbindkeysrc "/home/$SUDO_USER/.xbindkeysrc"
rm -rf /etc/xdg/picom.conf
mv $CONFIG_DIR/picom.conf /etc/xdg/picom.conf

echo "Setting up Neovim (NvChad)..."
git clone https://github.com/NvChad/starter "$CONFIG_DIR/nvim"

echo "Cleaning up..."
rm -rf /tmp/dotfiles
rm -rf $CONFIG_DIR/dotfiles/README.md

echo "Installation complete."
