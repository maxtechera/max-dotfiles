#!/bin/bash
# Universal Cross-Platform Dotfiles Installer
# Works on macOS and Arch Linux

set -e

# Colors
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
PURPLE='\033[0;35m'
NC='\033[0m'

# Detect OS
detect_os() {
    if [[ "$OSTYPE" == "darwin"* ]]; then
        echo "macos"
    elif [[ -f /etc/arch-release ]]; then
        echo "arch"
    else
        echo "unsupported"
    fi
}

OS=$(detect_os)

echo -e "${BLUE}╔═══════════════════════════════════════════╗${NC}"
echo -e "${BLUE}║      Universal Dotfiles Installer         ║${NC}"
echo -e "${BLUE}║         Detected OS: ${PURPLE}$OS${BLUE}              ║${NC}"
echo -e "${BLUE}╚═══════════════════════════════════════════╝${NC}"

if [ "$OS" == "unsupported" ]; then
    echo -e "${RED}Unsupported OS. This installer works on macOS and Arch Linux only.${NC}"
    exit 1
fi

# Run OS-specific installer
if [ "$OS" == "macos" ]; then
    echo -e "\n${YELLOW}Running macOS setup...${NC}"
    ./install-macos.sh
elif [ "$OS" == "arch" ]; then
    # Check if this is a fresh Arch install
    if ! command -v git &> /dev/null; then
        echo -e "${RED}ERROR: Git is not installed!${NC}"
        echo -e "${YELLOW}This appears to be a fresh Arch installation.${NC}"
        echo -e "\nPlease run these commands first:"
        echo -e "${GREEN}sudo pacman -Sy${NC}"
        echo -e "${GREEN}sudo pacman -S git${NC}"
        echo -e "\nThen clone the repository and run this installer again."
        exit 1
    fi
    
    # Check for base-devel
    if ! pacman -Qi base-devel &> /dev/null; then
        echo -e "\n${YELLOW}Installing essential build tools...${NC}"
        echo -e "${GREEN}This is required for AUR packages and compilation${NC}"
        sudo pacman -S --needed --noconfirm base-devel git wget curl
    fi
    
    echo -e "\n${YELLOW}Running Arch Linux setup...${NC}"
    
    # Ensure we're in the right directory
    SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
    cd "$SCRIPT_DIR"
    
    # Use modular installer if user wants more control
    if [ "$1" == "--modular" ] || [ "$1" == "-m" ]; then
        echo -e "${BLUE}Using modular installer for granular control${NC}"
        ./install-arch-modular.sh
    else
        ./install-arch.sh
    fi
fi

echo -e "\n${GREEN}Installation complete!${NC}"
echo -e "${YELLOW}Please restart your terminal or run: source ~/.zshrc${NC}"