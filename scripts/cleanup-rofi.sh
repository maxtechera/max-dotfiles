#!/bin/bash
# Clean up rofi and ensure consistent launcher setup

# Colors
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m'

echo -e "${BLUE}Launcher Cleanup & Consistency Script${NC}"
echo "===================================="

# 1. Remove rofi configs
echo -e "\n${YELLOW}Removing rofi configurations...${NC}"

# Remove rofi from home config
if [ -d "$HOME/.config/rofi" ]; then
    echo "Backing up and removing ~/.config/rofi"
    mv "$HOME/.config/rofi" "$HOME/.config/rofi.backup.$(date +%Y%m%d%H%M%S)"
fi

# Remove rofi symlink if it exists
if [ -L "$HOME/.config/rofi" ]; then
    echo "Removing rofi symlink"
    rm "$HOME/.config/rofi"
fi

# 2. Uninstall rofi if installed
if pacman -Qi rofi-wayland &> /dev/null; then
    echo -e "${YELLOW}Uninstalling rofi-wayland...${NC}"
    sudo pacman -R --noconfirm rofi-wayland
elif pacman -Qi rofi &> /dev/null; then
    echo -e "${YELLOW}Uninstalling rofi...${NC}"
    sudo pacman -R --noconfirm rofi
else
    echo -e "${GREEN}✓ Rofi not installed${NC}"
fi

# 3. Ensure fuzzel is installed
echo -e "\n${YELLOW}Ensuring fuzzel is installed...${NC}"
if ! command -v fuzzel &> /dev/null; then
    sudo pacman -S --needed --noconfirm fuzzel
else
    echo -e "${GREEN}✓ Fuzzel already installed${NC}"
fi

# 4. Create/update fuzzel config
echo -e "${YELLOW}Setting up fuzzel configuration...${NC}"
mkdir -p ~/.config/fuzzel

# Check if fuzzel config already exists
if [ -f ~/.config/fuzzel/fuzzel.ini ]; then
    echo -e "${YELLOW}Found existing fuzzel configuration${NC}"
    read -p "Backup and replace with optimized config? (y/n) [y]: " -n 1 -r REPLY
    REPLY=${REPLY:-y}
    echo
    if [[ $REPLY =~ ^[Yy]$ ]]; then
        # Backup existing config
        BACKUP_FILE="$HOME/.config/fuzzel/fuzzel.ini.backup.$(date +%Y%m%d%H%M%S)"
        cp ~/.config/fuzzel/fuzzel.ini "$BACKUP_FILE"
        echo -e "${GREEN}Backed up to: $BACKUP_FILE${NC}"
        
        # Create new config
        cat > ~/.config/fuzzel/fuzzel.ini << 'EOF'
[main]
font=JetBrainsMono Nerd Font:size=14
dpi-aware=yes
width=25
horizontal-pad=40
vertical-pad=20
inner-pad=15
lines=10
letter-spacing=0
prompt=" "

[colors]
background=1e1e2eee
text=cdd6f4ff
match=f38ba8ff
selection=45475aff
selection-text=cdd6f4ff
border=89b4faff

[border]
width=2
radius=10

[dmenu]
exit-immediately-if-empty=yes
EOF
        echo -e "${GREEN}✓ Fuzzel configured${NC}"
    else
        echo -e "${YELLOW}Keeping existing fuzzel configuration${NC}"
    fi
else
    # No existing config, create new one
    cat > ~/.config/fuzzel/fuzzel.ini << 'EOF'
[main]
font=JetBrainsMono Nerd Font:size=14
dpi-aware=yes
width=25
horizontal-pad=40
vertical-pad=20
inner-pad=15
lines=10
letter-spacing=0
prompt=" "

[colors]
background=1e1e2eee
text=cdd6f4ff
match=f38ba8ff
selection=45475aff
selection-text=cdd6f4ff
border=89b4faff

[border]
width=2
radius=10

[dmenu]
exit-immediately-if-empty=yes
EOF
    echo -e "${GREEN}✓ Fuzzel configured${NC}"
fi

# 5. Fix Hyprland config to ensure it uses fuzzel
echo -e "\n${YELLOW}Checking Hyprland configuration...${NC}"
HYPR_CONFIG="$HOME/.config/hypr/hyprland.conf"

if [ -f "$HYPR_CONFIG" ]; then
    # Check if rofi is still referenced
    if grep -q "rofi" "$HYPR_CONFIG"; then
        echo "Found rofi references in Hyprland config, updating..."
        sed -i 's/rofi[^,]*/fuzzel/g' "$HYPR_CONFIG"
        echo -e "${GREEN}✓ Updated Hyprland config${NC}"
    else
        echo -e "${GREEN}✓ Hyprland config already using fuzzel${NC}"
    fi
fi

# 6. Update desktop files cache
echo -e "\n${YELLOW}Updating desktop database...${NC}"
update-desktop-database ~/.local/share/applications 2>/dev/null || true
sudo update-desktop-database 2>/dev/null || true

# 7. Summary
echo -e "\n${GREEN}=== Cleanup Complete ===${NC}"
echo -e "${BLUE}Consistent launcher setup:${NC}"
echo "• Launcher: fuzzel (minimal & fast)"
echo "• Keybind: Alt+Space or Super+Space"
echo "• Config: ~/.config/fuzzel/fuzzel.ini"
echo
echo -e "${YELLOW}To reload Hyprland:${NC}"
echo "hyprctl reload"
echo
echo -e "${YELLOW}Test fuzzel:${NC}"
echo "fuzzel"