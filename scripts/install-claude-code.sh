#!/bin/bash
# Claude Code installation helper
# Provides multiple installation methods

# Colors
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
RED='\033[0;31m'
NC='\033[0m'

echo -e "${BLUE}Claude Code Installation${NC}"
echo "========================"

# Check if already installed
if command -v claude &> /dev/null; then
    echo -e "${GREEN}✓ Claude Code is already installed${NC}"
    claude --version
    exit 0
fi

echo -e "${YELLOW}Choose installation method:${NC}"
echo "1) AUR package (recommended)"
echo "2) npm global install"
echo "3) npx (run without installing)"

read -p "Select option (1-3) [1]: " OPTION
OPTION=${OPTION:-1}

case $OPTION in
    1)
        echo -e "\n${YELLOW}Installing from AUR...${NC}"
        if command -v yay &> /dev/null; then
            yay -S claude-code
        elif command -v paru &> /dev/null; then
            paru -S claude-code
        else
            echo -e "${YELLOW}No AUR helper found. Installing manually...${NC}"
            git clone https://aur.archlinux.org/claude-code.git /tmp/claude-code
            cd /tmp/claude-code
            makepkg -si
            cd -
            rm -rf /tmp/claude-code
        fi
        ;;
    2)
        echo -e "\n${YELLOW}Installing via npm...${NC}"
        if ! command -v npm &> /dev/null; then
            echo -e "${RED}npm not found. Install Node.js first.${NC}"
            exit 1
        fi
        sudo npm install -g @anthropic-ai/claude-code
        ;;
    3)
        echo -e "\n${YELLOW}You can run Claude Code with:${NC}"
        echo "npx @anthropic-ai/claude-code"
        echo
        echo "This will download and run it without installing globally."
        exit 0
        ;;
    *)
        echo -e "${RED}Invalid option${NC}"
        exit 1
        ;;
esac

# Verify installation
if command -v claude &> /dev/null; then
    echo -e "\n${GREEN}✓ Claude Code installed successfully!${NC}"
    claude --version
    echo
    echo -e "${YELLOW}Quick start:${NC}"
    echo "• Run 'claude help' to see available commands"
    echo "• Run 'claude chat' to start an interactive session"
    echo "• Run 'claude code' to analyze your codebase"
else
    echo -e "\n${RED}Installation may have failed.${NC}"
    echo "Try alternative method or check error messages above."
fi