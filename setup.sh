#!/bin/bash

# Exit immediately if a command exits with a non-zero status
set -e

# Check for root privileges
if [[ $EUID -ne 0 ]]; then
    echo "This script must be run as root!"
    exit 1
fi

echo "Enabling ParallelDownloads in pacman.conf..."
sed -i 's/^#ParallelDownloads/ParallelDownloads/' /etc/pacman.conf

echo "Updating system packages..."
pacman -Syu --noconfirm

echo "Installing required packages..."
pacman -S --noconfirm qtile lxappearance nitrogen thunar firefox vim neofetch fastfetch \
    alacritty picom ufw archlinux-wallpaper lightdm lightdm-gtk-greeter alsa-utils \
    keepassxc intel-ucode flatpak git pacman-contrib xbindkeys flameshot ttf-jetbrains-mono-nerd

echo "Enabling UFW (Uncomplicated Firewall)..."
systemctl enable ufw

echo "Modifying GRUB timeout settings..."
sed -i 's/^GRUB_TIMEOUT_STYLE=menu/GRUB_TIMEOUT_STYLE=hidden/' /etc/default/grub
grub-mkconfig -o /boot/grub/grub.cfg

echo "Installing YAY AUR helper..."
if ! command -v yay &>/dev/null; then
    git clone https://aur.archlinux.org/yay.git /tmp/yay
    cd /tmp/yay
    makepkg -si --noconfirm
    cd ..
    rm -rf /tmp/yay
else
    echo "YAY is already installed. Skipping..."
fi

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
mv /tmp/dotfiles/xbindkeysrc "/home/$SUDO_USER/.xbindkeysrc"
rm -rf /etc/xdg/picom.conf
mv /tmp/dotfiles/picom.conf /etc/xdg/picom.conf

echo "Setting up Neovim (NvChad)..."
git clone https://github.com/NvChad/starter "$CONFIG_DIR/nvim"

echo "Cleaning up..."
rm -rf /tmp/dotfiles
rm -rf /tmp/dotfiles/README.md

echo "Installation complete. Rebooting now..."
reboot
