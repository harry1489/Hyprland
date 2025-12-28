#!/bin/bash
set -euo pipefail

echo "🔥 Gentoo OpenRC Hyprland Full Setup (Masking & Category Fix) 🔥"

# Ensure the script is run as root
if [ "$EUID" -ne 0 ]; then
  echo "Error: Please run this script as root."
  exit 1
fi

USER_NAME=${SUDO_USER:-$(logname 2>/dev/null || echo "root")}
USER_HOME=$(getent passwd "$USER_NAME" | cut -d: -f6)

# 1. Sync and enable necessary repositories
echo "🔄 Syncing repositories and enabling GURU overlay..."
emerge --noreplace --quiet app-eselect/eselect-repository dev-vcs/git
if ! eselect repository list -i | grep -q "guru"; then
    eselect repository enable guru
    emaint sync -r guru
fi

# 2. Unmask required packages and accept licenses
echo "🔓 Unmasking required packages and accepting licenses..."
mkdir -p /etc/portage/package.accept_keywords
mkdir -p /etc/portage/package.license

# Unmask testing packages
cat > /etc/portage/package.accept_keywords/wayland <<EOF
gui-wm/hyprland ~amd64
app-misc/brightnessctl ~amd64
EOF

# Accept Brave Browser license
echo "www-client/brave-bin Brave" > /etc/portage/package.license/brave-bin

# 3. Apply global USE flags
echo "📝 Applying global USE flags..."
if ! grep -q "wayland" /etc/portage/make.conf; then
    echo 'USE="${USE} wayland pipewire elogind dbus -nvidia"' >> /etc/portage/make.conf
fi

# 4. Update the package database
echo "🗃️  Updating package database..."
emerge --sync

# 5. Install core packages with autounmask
echo "📦 Installing core packages..."
emerge --autounmask-write --getbinpkg --verbose --ask \
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

# Handle autounmask prompts
echo "🔧 Running dispatch-conf to handle unmasking..."
dispatch-conf

# 6. Set up OpenRC services
echo "⚙️ Setting up OpenRC services..."
rc-update add dbus default
rc-service dbus start || echo "dbus already running or failed to start"
rc-update add elogind default
rc-service elogind start || echo "elogind already running or failed to start"

# 7. Add user to necessary groups
echo "👤 Adding user to video, input, and seat groups..."
usermod -aG video,input,seat "$USER_NAME"

# 8. User-side setup (Hyprland config and neofetch)
echo "🏠 Setting up user configuration..."
sudo -u "$USER_NAME" bash <<USER_SCRIPT
set -euo pipefail
cd "$HOME" || exit 1

# Clone Hyprland Material You theme
if [ ! -d "hyprland-material-you" ]; then
    git clone https://github.com/koeqaife/hyprland-material-you.git
    cd hyprland-material-you || exit 1
    chmod +x install.sh
    ./install.sh
fi

# Create config directories
mkdir -p ~/.config/hypr ~/.config/waybar ~/.config/wofi

# Add neofetch to bashrc
if ! grep -q "neofetch" ~/.bashrc; then
    echo -e "\n# terminal drip\nneofetch" >> ~/.bashrc
fi
USER_SCRIPT

echo "---"
echo "✅ Setup complete!"
echo "➡️ Reboot your system and run 'Hyprland' to start your new environment."
