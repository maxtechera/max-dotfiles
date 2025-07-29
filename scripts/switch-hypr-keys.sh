#!/bin/bash
# Switch between Alt and Super keybindings for Hyprland

# Colors
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m'

HYPR_DIR="$HOME/.config/hypr"
CANONICAL_CONFIG="$HYPR_DIR/hyprland.conf"
ALT_CONFIG="$HYPR_DIR/backups/hyprland.conf.alt-backup"

echo -e "${BLUE}Hyprland Keybinding Switcher${NC}"
echo "============================="
echo

# Check current configuration
CURRENT="unknown"
if [ -L "$ALT_CONFIG" ]; then
    if [ "$(readlink "$ALT_CONFIG")" = "hyprland-current.conf" ]; then
        # We're using the symlink system
        if grep -q "mainMod = ALT" "$CURRENT_CONFIG" 2>/dev/null; then
            CURRENT="alt"
        elif grep -q "mainMod = SUPER" "$CURRENT_CONFIG" 2>/dev/null; then
            CURRENT="super"
        fi
    fi
elif grep -q "mainMod = ALT" "$ALT_CONFIG" 2>/dev/null; then
    CURRENT="alt"
elif grep -q "mainMod = SUPER" "$ALT_CONFIG" 2>/dev/null; then
    CURRENT="super"
fi

echo -e "Current configuration: ${GREEN}$CURRENT${NC}"
echo
echo "Choose keybinding style:"
echo -e "  ${YELLOW}1${NC}. Alt (macOS-like) - May conflict with apps"
echo -e "  ${YELLOW}2${NC}. Super (Linux standard) - Recommended"
echo -e "  ${YELLOW}3${NC}. Show key differences"
echo -e "  ${YELLOW}q${NC}. Quit"
echo
read -p "Choice [1/2/3/q]: " choice

case $choice in
    1)
        echo -e "\n${YELLOW}Switching to Alt configuration...${NC}"
        
        # Backup current config
        if [ -f "$ALT_CONFIG" ] && [ ! -L "$ALT_CONFIG" ]; then
            cp "$ALT_CONFIG" "$ALT_CONFIG.backup.$(date +%Y%m%d%H%M%S)"
        fi
        
        # If original Alt config exists in dotfiles, use it
        if [ -f "$HOME/.dotfiles/hypr/.config/hypr/hyprland.conf" ]; then
            cp "$HOME/.dotfiles/hypr/.config/hypr/hyprland.conf" "$CURRENT_CONFIG"
        else
            echo -e "${RED}Original Alt config not found!${NC}"
            exit 1
        fi
        
        # Create symlink
        rm -f "$ALT_CONFIG"
        ln -s "hyprland-current.conf" "$ALT_CONFIG"
        
        echo -e "${GREEN}✓ Switched to Alt keybindings${NC}"
        echo -e "\n${YELLOW}Warning: Alt may conflict with:${NC}"
        echo "• Browser shortcuts (Alt+D, Alt+Left/Right)"
        echo "• Terminal tabs (Alt+1-9)"
        echo "• Application menus (Alt+F, Alt+E)"
        ;;
        
    2)
        echo -e "\n${YELLOW}Switching to Super configuration...${NC}"
        
        # Backup current config
        if [ -f "$ALT_CONFIG" ] && [ ! -L "$ALT_CONFIG" ]; then
            cp "$ALT_CONFIG" "$ALT_CONFIG.backup.$(date +%Y%m%d%H%M%S)"
        fi
        
        # Copy Super config
        cp "$SUPER_CONFIG" "$CURRENT_CONFIG"
        
        # Create symlink
        rm -f "$ALT_CONFIG"
        ln -s "hyprland-current.conf" "$ALT_CONFIG"
        
        echo -e "${GREEN}✓ Switched to Super keybindings${NC}"
        echo -e "\n${GREEN}Linux standard keybindings active!${NC}"
        ;;
        
    3)
        echo -e "\n${BLUE}Key Differences:${NC}"
        echo
        echo -e "${YELLOW}Alt Configuration (macOS-like):${NC}"
        echo "• Alt + Enter = Terminal"
        echo "• Alt + Space = App launcher"
        echo "• Alt + Q = Close window"
        echo "• Alt + 1-9 = Workspaces"
        echo
        echo -e "${YELLOW}Super Configuration (Linux standard):${NC}"
        echo "• Super + Enter = Terminal"
        echo "• Super + D = App launcher (dmenu-style)"
        echo "• Super + Space = App launcher (alternate)"
        echo "• Super + Q = Close window"
        echo "• Super + 1-9 = Workspaces"
        echo "• Super + E = File manager"
        echo "• Super + L = Lock screen"
        echo
        echo -e "${GREEN}Advantages of Super:${NC}"
        echo "• No conflicts with application shortcuts"
        echo "• Standard across Linux tiling WMs"
        echo "• Alt+Tab still works normally"
        echo "• Browser/terminal shortcuts preserved"
        exit 0
        ;;
        
    q|Q)
        echo "No changes made."
        exit 0
        ;;
        
    *)
        echo -e "${RED}Invalid choice${NC}"
        exit 1
        ;;
esac

# Reload Hyprland
echo -e "\n${YELLOW}Reloading Hyprland...${NC}"
hyprctl reload

echo -e "\n${GREEN}Done! New keybindings are active.${NC}"
echo "Run this script again to switch back."