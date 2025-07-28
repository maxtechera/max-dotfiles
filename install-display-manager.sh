#!/bin/bash
# Install SDDM display manager for a nice GUI login

set -e

# Colors
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m'

echo -e "${YELLOW}Installing SDDM Display Manager...${NC}"

# Install SDDM and theme
sudo pacman -S --needed --noconfirm sddm qt5-graphicaleffects qt5-quickcontrols2 qt5-svg

# Install a modern SDDM theme from AUR
yay -S --needed --noconfirm sddm-sugar-candy-git

# Enable SDDM
sudo systemctl enable sddm

# Configure SDDM to use the theme
sudo mkdir -p /etc/sddm.conf.d
sudo tee /etc/sddm.conf.d/theme.conf > /dev/null << EOF
[Theme]
Current=sugar-candy
EOF

# Create Hyprland desktop entry for SDDM
sudo tee /usr/share/wayland-sessions/hyprland.desktop > /dev/null << 'EOF'
[Desktop Entry]
Name=Hyprland
Comment=An intelligent dynamic tiling Wayland compositor
Exec=Hyprland
Type=Application
EOF

echo -e "${GREEN}SDDM installed! You'll now have a graphical login screen.${NC}"
echo -e "${YELLOW}After reboot, you can login and select Hyprland from the session menu.${NC}"