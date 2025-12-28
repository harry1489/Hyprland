#!/bin/bash
set -e

echo "🔥 Gentoo OpenRC Hyprland Full Setup (No Network BS) 🔥"

if [ "$EUID" -ne 0 ]; then
  echo "Run as root. This is Gentoo, not a suggestion."
  exit 1
fi

USER_NAME=${SUDO_USER}
USER_HOME=$(eval echo "~$USER_NAME")

echo "👤 User: $USER_NAME"
echo "🏠 Home: $USER_HOME"

# sync repos
emerge --sync

# enable GURU overlay
emerge app-eselect/eselect-repository
eselect repository enable guru
emaint sync -r guru

# core packages
emerge --ask \
  dev-vcs/git \
  gui-wm/hyprland \
  gui-apps/waybar \
  gui-apps/wofi \
  media-sound/pipewire \
  media-video/wireplumber \
  media-fonts/jetbrains-mono \
  x11-misc/xclip \
  x11-misc/brightnessctl \
  sys-auth/polkit \
  app-misc/neofetch \
  app-editors/neovim \
  www-client/brave-bin

# dbus is still required (Wayland reality)
rc-update add dbus default
rc-service dbus start || true

# pipewire (OpenRC style)
rc-update add pipewire default
rc-update add wireplumber default
rc-service pipewire start || true
rc-service wireplumber start || true

# user-side setup
sudo -u "$USER_NAME" bash <<EOF
set -e

cd $USER_HOME

# clone Hyprland Material You
if [ ! -d hyprland-material-you ]; then
  git clone https://github.com/koeqaife/hyprland-material-you.git
fi

cd hyprland-material-you
chmod +x install.sh
./install.sh

# ensure config dirs exist
mkdir -p ~/.config/hypr ~/.config/waybar ~/.config/wofi

# neofetch terminal drip
if ! grep -q "neofetch" ~/.bashrc; then
  echo "" >> ~/.bashrc
  echo "# terminal drip" >> ~/.bashrc
  echo "neofetch" >> ~/.bashrc
fi

echo "✨ User config done"
EOF

echo "✅ ALL DONE"
echo "➡️ Reboot, log into TTY, run: Hyprland"
