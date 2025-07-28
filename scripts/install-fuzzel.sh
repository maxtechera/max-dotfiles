#!/bin/bash
# Install fuzzel - the fastest, most minimal launcher

# Colors
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m'

echo -e "${BLUE}Installing Fuzzel - Minimal & Fast Launcher${NC}"
echo "=========================================="

# Install fuzzel
if ! command -v fuzzel &> /dev/null; then
    echo -e "${YELLOW}Installing fuzzel...${NC}"
    sudo pacman -S --needed --noconfirm fuzzel
else
    echo -e "${GREEN}✓ Fuzzel already installed${NC}"
fi

# Create minimal config
echo -e "${YELLOW}Creating fuzzel config...${NC}"
mkdir -p ~/.config/fuzzel

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

echo -e "${GREEN}✓ Fuzzel installed and configured!${NC}"
echo
echo -e "${BLUE}Usage:${NC}"
echo -e "  Press ${GREEN}Alt + Space${NC} to launch"
echo -e "  Just start typing to search"
echo -e "  ${GREEN}Enter${NC} to launch"
echo -e "  ${GREEN}Esc${NC} to cancel"
echo
echo -e "${YELLOW}Why Fuzzel?${NC}"
echo "• Starts instantly (no delay)"
echo "• Minimal RAM usage"
echo "• No dependencies"
echo "• Just works™"
echo
echo -e "${YELLOW}Pro tip:${NC} It's so fast you can spam Alt+Space"