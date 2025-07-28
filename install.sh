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
    echo -e "\n${YELLOW}Running Arch Linux setup...${NC}"
    ./install-arch.sh
fi

echo -e "\n${GREEN}Installation complete!${NC}"
echo -e "${YELLOW}Please restart your terminal or run: source ~/.zshrc${NC}"