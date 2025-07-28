#!/bin/bash
# One-command setup for fresh Arch installations
# Idempotent - can be run multiple times safely

# Don't exit on error - we handle errors gracefully
set +e

# Colors
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
PURPLE='\033[0;35m'
NC='\033[0m'

echo -e "${BLUE}╔═══════════════════════════════════════════╗${NC}"
echo -e "${BLUE}║    Fresh Arch Linux Complete Setup        ║${NC}"
echo -e "${BLUE}║         Zero to Desktop                   ║${NC}"
echo -e "${BLUE}╚═══════════════════════════════════════════╝${NC}"

# Step 1: Install git if not present
echo -e "\n${PURPLE}[1/3]${NC} Checking Git..."
if ! command -v git &> /dev/null; then
    echo -e "${YELLOW}Git not found. Installing...${NC}"
    sudo pacman -Sy --noconfirm
    sudo pacman -S --needed --noconfirm git
    if [ $? -eq 0 ]; then
        echo -e "${GREEN}✓ Git installed successfully${NC}"
    else
        echo -e "${RED}Failed to install Git. Please install manually:${NC}"
        echo -e "${YELLOW}sudo pacman -S git${NC}"
        exit 1
    fi
else
    echo -e "${GREEN}✓ Git already installed${NC}"
fi

# Step 2: Clone or update the repository
echo -e "\n${PURPLE}[2/3]${NC} Setting up dotfiles repository..."
REPO_DIR="max-dotfiles"

if [ -d "$REPO_DIR" ]; then
    echo -e "${YELLOW}Repository already exists${NC}"
    cd "$REPO_DIR"
    
    # Check if it's a git repository
    if [ -d ".git" ]; then
        echo -e "${YELLOW}Updating repository...${NC}"
        git fetch origin
        
        # Check for local changes
        if ! git diff --quiet || ! git diff --staged --quiet; then
            echo -e "${YELLOW}Local changes detected${NC}"
            read -p "Stash local changes and update? (y/n) [y]: " -n 1 -r REPLY
            REPLY=${REPLY:-y}
            echo
            if [[ $REPLY =~ ^[Yy]$ ]]; then
                git stash push -m "Auto-stash before update $(date +%Y%m%d-%H%M%S)"
                git pull --rebase
                echo -e "${GREEN}✓ Repository updated (changes stashed)${NC}"
            else
                echo -e "${YELLOW}Keeping local changes${NC}"
            fi
        else
            git pull --ff-only
            echo -e "${GREEN}✓ Repository updated${NC}"
        fi
    else
        echo -e "${RED}Directory exists but is not a git repository${NC}"
        read -p "Remove and re-clone? (y/n) [n]: " -n 1 -r REPLY
        REPLY=${REPLY:-n}
        echo
        if [[ $REPLY =~ ^[Yy]$ ]]; then
            cd ..
            rm -rf "$REPO_DIR"
            git clone https://github.com/maxtechera/max-dotfiles.git
            cd "$REPO_DIR"
        else
            echo -e "${RED}Cannot proceed without valid repository${NC}"
            exit 1
        fi
    fi
else
    echo -e "${YELLOW}Cloning repository...${NC}"
    git clone https://github.com/maxtechera/max-dotfiles.git
    cd "$REPO_DIR"
    echo -e "${GREEN}✓ Repository cloned${NC}"
fi

# Step 3: Run the installer
echo -e "\n${PURPLE}[3/3]${NC} Running setup..."
if [ -f "install.sh" ]; then
    chmod +x install.sh
    echo -e "${GREEN}Starting complete environment setup...${NC}"
    echo -e "${YELLOW}This will configure: Hyprland, Ghostty, dev tools, and more!${NC}\n"
    
    # Run installer
    ./install.sh
    INSTALL_RESULT=$?
    
    if [ $INSTALL_RESULT -eq 0 ]; then
        echo -e "\n${GREEN}╔═══════════════════════════════════════════╗${NC}"
        echo -e "${GREEN}║           Setup Complete! 🎉              ║${NC}"
        echo -e "${GREEN}╚═══════════════════════════════════════════╝${NC}"
        
        if systemctl is-active --quiet sddm; then
            echo -e "\n${GREEN}SDDM is already running! You can log out and log back in.${NC}"
        else
            echo -e "\n${YELLOW}Please reboot your system to start using Hyprland!${NC}"
            echo -e "${GREEN}sudo reboot${NC}"
        fi
    else
        echo -e "\n${YELLOW}Setup completed with some warnings.${NC}"
        echo -e "${YELLOW}You can re-run this script anytime to fix any issues.${NC}"
    fi
else
    echo -e "${RED}install.sh not found in repository${NC}"
    exit 1
fi