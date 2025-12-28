#!/bin/bash
set -e

echo "🔥 Gentoo OpenRC Hyprland Full Setup (Fixed & Optimized) 🔥"

if [ "$EUID" -ne 0 ]; then
  echo "Error: Please run as root (or via sudo)."
  exit 1
fi

# Fallback for USER_NAME if script is run directly as root
USER_NAME=${SUDO_USER:-$(logname)}
USER_HOME=$(getent passwd "$USER_NAME" | cut -d: -f6)

echo "👤 User: $USER_NAME"
echo "🏠 Home: $USER_HOME"

# 1. Ensure world is up to date and eselect-repository is present
emerge --noreplace app-eselect/eselect-repository dev-vcs/git

# 2. Enable GURU if not already enabled
if ! eselect repository list -i | grep -q "guru"; then
    eselect repository enable guru
    emaint sync -r guru
fi

# 3. Global USE flag check (Crucial for Hyprland/Wayland)
# We ensure the system knows we want Wayland support globally
if ! grep -q "wayland" /etc/portage/make.conf; then
    echo 'USE="${USE} wayland pipewire elogind dbus -nvidia"' >> /etc/portage/make.conf
    echo "⚠️ Added Wayland/Pipewire USE flags to make.conf. You may need to run 'emerge --update --newuse @world' later."
fi

# 4. Core packages
# Note: --ask is removed to allow automation, replaced with --verbose
# Added elogind as it's the standard seat manager for OpenRC Wayland
emerge --getbinpkg --verbose \
  gui-wm/hyprland \
  gui-apps/waybar \
  gui-apps/wofi \
  media-video/pipewire \
  media-video/wireplumber \
  media-fonts/jetbrains-mono \
  x11-misc/brightnessctl \
  sys-auth/polkit \
  sys-auth/elogind \
  app-misc/neofetch \
  app-editors/neovim \
  www-client/brave-bin

# 5. OpenRC Services
rc-update add dbus default
rc-service dbus start || true
rc-update add elogind default
rc-service elogind start || true

# 6. User-side setup
sudo -u "$USER_NAME" bash <<EOF
set -e
cd "$USER_HOME"

# Clone and install Material You theme
if [ ! -d "hyprland-material-you" ]; then
  git clone https://github.com/koeqaife/hyprland-material-you.git
  cd hyprland-material-you
  chmod +x install.sh
  # Note: The install script might ask for sudo inside; 
  # ensure your user has NOPASSWD or be ready to type it.
  ./install.sh
fi

# Ensure config dirs exist
mkdir -p ~/.config/hypr ~/.config/waybar ~/.config/wofi

# Bashrc Drip
if ! grep -q "neofetch" ~/.bashrc; then
  echo -e "\n# terminal drip\nneofetch" >> ~/.bashrc
fi

echo "✨ User config done"
EOF

echo "✅ ALL DONE"
echo "➡️  IMPORTANT: Ensure your user is in the 'video', 'input', and 'seat' groups:"
echo "   usermod -aG video,input,seat $USER_NAME"
echo "➡️  Reboot, log into TTY, and run: Hyprland"#!/bin/bash
set -e

echo "🔥 Gentoo OpenRC Hyprland Full Setup (Fixed & Optimized) 🔥"

if [ "$EUID" -ne 0 ]; then
  echo "Error: Please run as root (or via sudo)."
  exit 1
fi

# Fallback for USER_NAME if script is run directly as root
USER_NAME=${SUDO_USER:-$(logname)}
USER_HOME=$(getent passwd "$USER_NAME" | cut -d: -f6)

echo "👤 User: $USER_NAME"
echo "🏠 Home: $USER_HOME"

# 1. Ensure world is up to date and eselect-repository is present
emerge --noreplace app-eselect/eselect-repository dev-vcs/git

# 2. Enable GURU if not already enabled
if ! eselect repository list -i | grep -q "guru"; then
    eselect repository enable guru
    emaint sync -r guru
fi

# 3. Global USE flag check (Crucial for Hyprland/Wayland)
# We ensure the system knows we want Wayland support globally
if ! grep -q "wayland" /etc/portage/make.conf; then
    echo 'USE="${USE} wayland pipewire elogind dbus -nvidia"' >> /etc/portage/make.conf
    echo "⚠️ Added Wayland/Pipewire USE flags to make.conf. You may need to run 'emerge --update --newuse @world' later."
fi

# 4. Core packages
# Note: --ask is removed to allow automation, replaced with --verbose
# Added elogind as it's the standard seat manager for OpenRC Wayland
emerge --getbinpkg --verbose \
  gui-wm/hyprland \
  gui-apps/waybar \
  gui-apps/wofi \
  media-video/pipewire \
  media-video/wireplumber \
  media-fonts/jetbrains-mono \
  x11-misc/brightnessctl \
  sys-auth/polkit \
  sys-auth/elogind \
  app-misc/neofetch \
  app-editors/neovim \
  www-client/brave-bin

# 5. OpenRC Services
rc-update add dbus default
rc-service dbus start || true
rc-update add elogind default
rc-service elogind start || true

# 6. User-side setup
sudo -u "$USER_NAME" bash <<EOF
set -e
cd "$USER_HOME"

# Clone and install Material You theme
if [ ! -d "hyprland-material-you" ]; then
  git clone https://github.com/koeqaife/hyprland-material-you.git
  cd hyprland-material-you
  chmod +x install.sh
  # Note: The install script might ask for sudo inside; 
  # ensure your user has NOPASSWD or be ready to type it.
  ./install.sh
fi

# Ensure config dirs exist
mkdir -p ~/.config/hypr ~/.config/waybar ~/.config/wofi

# Bashrc Drip
if ! grep -q "neofetch" ~/.bashrc; then
  echo -e "\n# terminal drip\nneofetch" >> ~/.bashrc
fi

echo "✨ User config done"
EOF

echo "✅ ALL DONE"
echo "➡️  IMPORTANT: Ensure your user is in the 'video', 'input', and 'seat' groups:"
echo "   usermod -aG video,input,seat $USER_NAME"
echo "➡️  Reboot, log into TTY, and run: Hyprland"
