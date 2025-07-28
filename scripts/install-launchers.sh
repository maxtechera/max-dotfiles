#!/bin/bash
# Install and configure app launchers for Hyprland

# Colors
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m'

echo -e "${BLUE}App Launcher Setup${NC}"
echo "=================="

# Install launchers
echo -e "${YELLOW}Installing launcher options...${NC}"

# Wofi - Most popular Wayland launcher
if ! command -v wofi &> /dev/null; then
    echo "Installing wofi..."
    sudo pacman -S --needed --noconfirm wofi
fi

# Fuzzel - Minimal and fast
if ! command -v fuzzel &> /dev/null; then
    echo "Installing fuzzel..."
    sudo pacman -S --needed --noconfirm fuzzel
fi

# Tofi - Modern dmenu replacement
if ! command -v tofi &> /dev/null; then
    echo "Installing tofi..."
    sudo pacman -S --needed --noconfirm tofi 2>/dev/null || echo "Tofi not in repos"
fi

# Create wofi config
echo -e "${YELLOW}Creating wofi config...${NC}"
mkdir -p ~/.config/wofi
cat > ~/.config/wofi/config << 'EOF'
# Wofi Configuration
width=600
height=400
location=center
show=drun
prompt=Search
filter_rate=100
allow_markup=true
no_actions=true
halign=fill
orientation=vertical
content_halign=fill
insensitive=true
allow_images=true
image_size=24
hide_scroll=true
EOF

# Create wofi style (dark theme)
cat > ~/.config/wofi/style.css << 'EOF'
window {
    margin: 0px;
    border: 2px solid #88c0d0;
    background-color: #2e3440;
    border-radius: 10px;
}

#input {
    margin: 5px;
    border: none;
    color: #eceff4;
    background-color: #3b4252;
    border-radius: 5px;
    padding: 10px;
}

#inner-box {
    margin: 5px;
    border: none;
    background-color: #2e3440;
}

#outer-box {
    margin: 5px;
    border: none;
    background-color: #2e3440;
}

#scroll {
    margin: 0px;
    border: none;
}

#text {
    margin: 5px;
    border: none;
    color: #eceff4;
} 

#entry:selected {
    background-color: #4c566a;
    border-radius: 5px;
}

#text:selected {
    color: #88c0d0;
}
EOF

# Create fuzzel config
echo -e "${YELLOW}Creating fuzzel config...${NC}"
mkdir -p ~/.config/fuzzel
cat > ~/.config/fuzzel/fuzzel.ini << 'EOF'
[main]
font=JetBrainsMono Nerd Font:size=12
dpi-aware=yes
width=30
horizontal-pad=20
vertical-pad=10
inner-pad=10

[colors]
background=2e3440dd
text=eceff4ff
selection=4c566aff
selection-text=88c0d0ff
border=88c0d0ff

[border]
width=2
radius=10
EOF

echo -e "\n${GREEN}Launchers installed!${NC}"
echo -e "\n${BLUE}Usage:${NC}"
echo -e "  ${GREEN}wofi${NC} - Feature-rich launcher (like rofi)"
echo -e "  ${GREEN}fuzzel${NC} - Minimal and fast"
echo -e "  ${GREEN}tofi${NC} - dmenu-style (if installed)"
echo
echo -e "${YELLOW}To test them:${NC}"
echo "  wofi --show drun"
echo "  fuzzel"
echo "  tofi-drun | xargs swaymsg exec --"