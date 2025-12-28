#!/bin/bash
set -e

echo "🔥 Gentoo OpenRC Hyprland Full Setup (Masking & Category Fix) 🔥"

if [ "$EUID" -ne 0 ]; then
  echo "Error: Please run as root."
  exit 1
fi

USER_NAME=${SUDO_USER:-$(logname)}
USER_HOME=$(getent passwd "$USER_NAME" | cut -d: -f6)

# 1. Sync and Tooling
emerge --noreplace app-eselect/eselect-repository dev-vcs/git

# 2. Enable GURU overlay
if ! eselect repository list -i | grep -q "guru"; then
    eselect repository enable guru
    emaint sync -r guru
fi

# 3. Handle Masked Packages & Keywords (Fixes your "All ebuilds... have been masked" error)
echo "🔓 Unmasking required packages..."
mkdir -p /etc/portage/package.accept_keywords
mkdir -p /etc/portage/package.license

# Accept testing keyword for brightnessctl from GURU
echo "app-misc/brightnessctl ~amd64" > /etc/portage/package.accept_keywords/brightnessctl
# Accept Brave Browser license
echo "www-client/brave-bin Brave" > /etc/portage/package.license/brave-bin

# 4. Apply Global USE flags to make.conf
if ! grep -q "wayland" /etc/portage/make.conf; then
    echo 'USE="${USE} wayland pipewire elogind dbus -nvidia"' >> /etc/portage/make.conf
fi

# 5. Core Package Installation (Corrected Categories)
echo "📦 Installing packages..."
# Using --autounmask-write to help handle any other unexpected keyword issues
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

# 6. OpenRC Service Setup
echo "⚙️ Setting up services..."
rc-update add dbus default
rc-service dbus start || true
rc-update add elogind default
rc-service elogind start || true

# 7. Permissions
usermod -aG video,input,seat "$USER_NAME"

# 8. User-side setup
sudo -u "$USER_NAME" bash <<EOF
set -e
cd "$USER_HOME"

if [ ! -d "hyprland-material-you" ]; then
  git clone https://github.com/koeqaife/hyprland-material-you.git
fi

cd hyprland-material-you
chmod +x install.sh
# Note: if install.sh asks for a password, you will need to enter it
./install.sh

mkdir -p ~/.config/hypr ~/.config/waybar ~/.config/wofi

if ! grep -q "neofetch" ~/.bashrc; then
  echo -e "\n# terminal drip\nneofetch" >> ~/.bashrc
fi
EOF

echo "---"
echo "✅ ALL DONE"
echo "➡️  Reboot and run: Hyprland"
