#!/bin/bash
set -e

echo "🔥 Gentoo OpenRC Hyprland Full Setup (Fixed Categories) 🔥"

if [ "$EUID" -ne 0 ]; then
  echo "Error: Please run as root."
  exit 1
fi

# Fallback for USER_NAME if script is run directly as root
USER_NAME=${SUDO_USER:-$(logname)}
USER_HOME=$(getent passwd "$USER_NAME" | cut -d: -f6)

echo "👤 User: $USER_NAME"
echo "🏠 Home: $USER_HOME"

# 1. Sync and Tooling
emerge --noreplace app-eselect/eselect-repository dev-vcs/git

# 2. Enable GURU overlay
if ! eselect repository list -i | grep -q "guru"; then
    eselect repository enable guru
    emaint sync -r guru
fi

# 3. Apply Global USE flags to make.conf
# This ensures packages build with the features Hyprland needs
if ! grep -q "wayland" /etc/portage/make.conf; then
    echo 'USE="${USE} wayland pipewire elogind dbus -nvidia"' >> /etc/portage/make.conf
    echo "⚠️ Updated /etc/portage/make.conf with Wayland/Pipewire flags."
fi

# 4. Core Package Installation (Corrected Categories)
echo "📦 Installing packages..."
emerge --getbinpkg --verbose \
  gui-wm/hyprland \
  gui-apps/waybar \
  gui-apps/wofi \
  gui-apps/wl-clipboard \
  media-video/pipewire \
  media-video/wireplumber \
  media-fonts/jetbrains-mono \
  app-misc/brightnessctl \
  sys-auth/polkit \
  sys-auth/elogind \
  app-misc/neofetch \
  app-editors/neovim \
  www-client/brave-bin

# 5. OpenRC Service Setup
echo "⚙️ Setting up services..."
rc-update add dbus default
rc-service dbus start || true

# elogind handles seat/session management for Wayland on OpenRC
rc-update add elogind default
rc-service elogind start || true

# 6. Permissions
# Critical for accessing graphics and input devices
usermod -aG video,input,seat "$USER_NAME"

# 7. User-side setup
sudo -u "$USER_NAME" bash <<EOF
set -e
cd "$USER_HOME"

# Hyprland Material You Theme
if [ ! -d "hyprland-material-you" ]; then
  git clone https://github.com/koeqaife/hyprland-material-you.git
fi

cd hyprland-material-you
chmod +x install.sh
./install.sh

# Ensure local config structure
mkdir -p ~/.config/hypr ~/.config/waybar ~/.config/wofi

# Terminal Drip
if ! grep -q "neofetch" ~/.bashrc; then
  echo -e "\n# terminal drip\nneofetch" >> ~/.bashrc
fi
EOF

echo "---"
echo "✅ SETUP COMPLETE"
echo "➡️  1. Reboot your system."
echo "➡️  2. Log into the TTY as $USER_NAME."
echo "➡️  3. Type 'Hyprland' to start the session."
