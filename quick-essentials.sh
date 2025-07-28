#!/bin/bash
# Quick essentials installer - Gets you to a working desktop FAST
# Skips all optional packages for speed

set -e

# Colors
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m'

echo -e "${BLUE}╔════════════════════════════════════════╗${NC}"
echo -e "${BLUE}║    Quick Essentials Installer          ║${NC}"
echo -e "${BLUE}║    ~10 minutes to working desktop      ║${NC}"
echo -e "${BLUE}╚════════════════════════════════════════╝${NC}"

echo -e "\n${YELLOW}This installs only the essentials:${NC}"
echo "✓ Hyprland (window manager)"
echo "✓ Ghostty (terminal)"
echo "✓ Basic dev tools (git, neovim, tmux)"
echo "✓ Network & audio"
echo "✗ Skips: Slack, Spotify, VS Code, etc."
echo

read -p "Continue? (y/n) [y]: " -n 1 -r REPLY
REPLY=${REPLY:-y}
echo
if [[ ! $REPLY =~ ^[Yy]$ ]]; then
    exit 0
fi

# Run main installer with skip flags
echo -e "\n${GREEN}Starting quick installation...${NC}"
./install-arch.sh --skip-aur

echo -e "\n${GREEN}╔════════════════════════════════════════╗${NC}"
echo -e "${GREEN}║    Quick Install Complete! 🚀         ║${NC}"
echo -e "${GREEN}╚════════════════════════════════════════╝${NC}"

echo -e "\n${YELLOW}You now have a working Hyprland desktop!${NC}"
echo -e "${YELLOW}To install additional apps later:${NC}"
echo "• Claude Code: yay -S claude-code"
echo "• VS Code: yay -S visual-studio-code-bin"
echo "• Spotify: yay -S spotify"
echo "• Slack: yay -S slack-desktop"
echo
echo -e "${GREEN}Reboot now to start using Hyprland!${NC}"