#!/bin/bash
# One-command setup for fresh Arch installations
# Run this immediately after connecting to WiFi

set -e

# Colors
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m'

echo -e "${BLUE}╔═══════════════════════════════════════════╗${NC}"
echo -e "${BLUE}║    Fresh Arch Linux Complete Setup        ║${NC}"
echo -e "${BLUE}║         Zero to Desktop                   ║${NC}"
echo -e "${BLUE}╚═══════════════════════════════════════════╝${NC}"

# Step 1: Install git if not present
if ! command -v git &> /dev/null; then
    echo -e "\n${YELLOW}[1/3] Installing Git...${NC}"
    sudo pacman -Sy --noconfirm
    sudo pacman -S --needed --noconfirm git
else
    echo -e "\n${GREEN}✓ Git already installed${NC}"
fi

# Step 2: Clone the repository
echo -e "\n${YELLOW}[2/3] Cloning dotfiles repository...${NC}"
if [ -d "max-dotfiles" ]; then
    echo -e "${YELLOW}Repository already exists, updating...${NC}"
    cd max-dotfiles
    git pull
else
    git clone https://github.com/maxtechera/max-dotfiles.git
    cd max-dotfiles
fi

# Step 3: Run the installer
echo -e "\n${YELLOW}[3/3] Running complete setup...${NC}"
echo -e "${GREEN}This will install everything: Hyprland, Ghostty, dev tools, and more!${NC}\n"
chmod +x install.sh
./install.sh

echo -e "\n${GREEN}╔═══════════════════════════════════════════╗${NC}"
echo -e "${GREEN}║           Setup Complete! 🎉              ║${NC}"
echo -e "${GREEN}╚═══════════════════════════════════════════╝${NC}"
echo -e "\n${YELLOW}Please reboot your system to start using Hyprland!${NC}"
echo -e "${GREEN}sudo reboot${NC}"