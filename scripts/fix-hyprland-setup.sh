#!/bin/bash
# Fix Hyprland setup issues - waybar, system settings, etc.

# Colors
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m'

echo -e "${BLUE}Hyprland Setup Troubleshooter${NC}"
echo "=============================="

# Check if we're in Hyprland
if [ "$XDG_SESSION_TYPE" != "wayland" ] || [ -z "$HYPRLAND_INSTANCE_SIGNATURE" ]; then
    echo -e "${YELLOW}Warning: Not running in Hyprland session${NC}"
fi

# 1. Check Waybar
echo -e "\n${BLUE}1. Checking Waybar (status bar)...${NC}"
if ! pgrep -x waybar > /dev/null; then
    echo -e "${RED}✗ Waybar is not running${NC}"
    
    # Check if waybar is installed
    if command -v waybar &> /dev/null; then
        echo -e "${YELLOW}Starting waybar...${NC}"
        waybar &
        sleep 2
        if pgrep -x waybar > /dev/null; then
            echo -e "${GREEN}✓ Waybar started successfully${NC}"
        else
            echo -e "${RED}Failed to start waybar. Check logs with: journalctl --user -u waybar${NC}"
        fi
    else
        echo -e "${RED}Waybar is not installed!${NC}"
        echo "Install with: sudo pacman -S waybar"
    fi
else
    echo -e "${GREEN}✓ Waybar is running${NC}"
fi

# 2. Check essential services
echo -e "\n${BLUE}2. Checking essential services...${NC}"

# NetworkManager
if systemctl is-active --quiet NetworkManager; then
    echo -e "${GREEN}✓ NetworkManager is running${NC}"
else
    echo -e "${RED}✗ NetworkManager is not running${NC}"
    echo "  Start with: sudo systemctl start NetworkManager"
    echo "  Enable with: sudo systemctl enable NetworkManager"
fi

# Bluetooth
if systemctl is-active --quiet bluetooth; then
    echo -e "${GREEN}✓ Bluetooth is running${NC}"
else
    echo -e "${YELLOW}! Bluetooth is not running (optional)${NC}"
fi

# PipeWire
if systemctl --user is-active --quiet pipewire; then
    echo -e "${GREEN}✓ PipeWire audio is running${NC}"
else
    echo -e "${RED}✗ PipeWire is not running${NC}"
    echo "  Start with: systemctl --user start pipewire wireplumber"
fi

# 3. Check Hyprland autostart
echo -e "\n${BLUE}3. Checking Hyprland autostart...${NC}"
HYPR_CONFIG="$HOME/.config/hypr/hyprland.conf"

if [ -f "$HYPR_CONFIG" ]; then
    echo -e "${GREEN}✓ Hyprland config exists${NC}"
    
    # Check if exec-once commands are present
    if grep -q "exec-once = waybar" "$HYPR_CONFIG"; then
        echo -e "${GREEN}✓ Waybar autostart configured${NC}"
    else
        echo -e "${YELLOW}! Waybar autostart not found in config${NC}"
    fi
    
    # Check for other essentials
    MISSING_EXEC=()
    grep -q "exec-once = mako" "$HYPR_CONFIG" || MISSING_EXEC+=("mako (notifications)")
    grep -q "exec-once = swww" "$HYPR_CONFIG" || MISSING_EXEC+=("swww (wallpaper)")
    grep -q "polkit" "$HYPR_CONFIG" || MISSING_EXEC+=("polkit (authentication)")
    
    if [ ${#MISSING_EXEC[@]} -gt 0 ]; then
        echo -e "${YELLOW}! Missing autostart for: ${MISSING_EXEC[*]}${NC}"
    fi
else
    echo -e "${RED}✗ Hyprland config not found!${NC}"
    echo "  This is a serious issue - the config should be at ~/.config/hypr/hyprland.conf"
fi

# 4. Check keybindings
echo -e "\n${BLUE}4. Key bindings status:${NC}"
echo -e "  ${GREEN}Alt + Enter${NC} - Open terminal (ghostty)"
echo -e "  ${GREEN}Alt + Space${NC} - App launcher (rofi)"
echo -e "  ${GREEN}Alt + Q${NC} - Close window"
echo -e "  ${GREEN}Alt + F${NC} - Fullscreen"
echo -e "  ${GREEN}Alt + H/J/K/L${NC} - Navigate windows"

# 5. Check for system settings tools
echo -e "\n${BLUE}5. System settings tools:${NC}"

# Check for settings apps
SETTINGS_APPS=(
    "pavucontrol:Audio settings"
    "nm-connection-editor:Network settings"
    "blueman-manager:Bluetooth settings"
    "thunar:File manager"
)

for app_info in "${SETTINGS_APPS[@]}"; do
    IFS=':' read -r app desc <<< "$app_info"
    if command -v "$app" &> /dev/null; then
        echo -e "${GREEN}✓ $desc ($app)${NC}"
    else
        echo -e "${RED}✗ $desc not installed${NC}"
        echo "  Install with: sudo pacman -S ${app%-*}"
    fi
done

# 6. Quick fixes
echo -e "\n${BLUE}6. Applying quick fixes...${NC}"

# Ensure XDG dirs exist
mkdir -p ~/Pictures/Screenshots 2>/dev/null

# Start essential services if not running
if ! pgrep -x mako > /dev/null && command -v mako &> /dev/null; then
    echo "Starting mako (notifications)..."
    mako &
fi

if ! pgrep -x swww-daemon > /dev/null && command -v swww &> /dev/null; then
    echo "Starting swww (wallpaper)..."
    swww init &
    sleep 1
    # Set a default wallpaper if none exists
    if [ ! -f ~/Pictures/wallpaper.jpg ]; then
        echo "Creating default wallpaper..."
        convert -size 2560x1440 plasma: ~/Pictures/wallpaper.jpg 2>/dev/null || \
        convert -size 2560x1440 xc:navy ~/Pictures/wallpaper.jpg 2>/dev/null || \
        echo "  Could not create wallpaper (imagemagick not installed)"
    fi
    [ -f ~/Pictures/wallpaper.jpg ] && swww img ~/Pictures/wallpaper.jpg
fi

# 7. Manual reload option
echo -e "\n${BLUE}7. Manual controls:${NC}"
echo "• Reload Hyprland config: Alt+Shift+R (or hyprctl reload)"
echo "• Start waybar manually: waybar &"
echo "• Open app launcher: Alt+Space"
echo "• Open terminal: Alt+Enter"

# 8. Check if rofi theme exists
echo -e "\n${BLUE}8. Checking app launcher theme...${NC}"
ROFI_THEME="$HOME/.config/rofi/launcher.rasi"
if [ ! -f "$ROFI_THEME" ]; then
    echo -e "${YELLOW}! Rofi theme not found, creating default...${NC}"
    mkdir -p ~/.config/rofi
    cat > "$ROFI_THEME" << 'EOF'
configuration {
    modi: "drun,run,window";
    font: "JetBrainsMono Nerd Font 12";
    show-icons: true;
    icon-theme: "Papirus";
    display-drun: " Apps";
    display-run: " Run";
    display-window: " Window";
    drun-display-format: "{name}";
    window-format: "{w} · {c} · {t}";
}

* {
    bg: #1e1e2e;
    bg-alt: #313244;
    fg: #cdd6f4;
    fg-alt: #7f849c;
    
    background-color: @bg;
    text-color: @fg;
    
    margin: 0;
    padding: 0;
    spacing: 0;
}

window {
    width: 600px;
    border-radius: 8px;
}

mainbox {
    padding: 12px;
}

inputbar {
    background-color: @bg-alt;
    padding: 12px;
    border-radius: 8px;
}

prompt, entry {
    background-color: inherit;
}

prompt {
    margin-right: 12px;
}

listview {
    lines: 8;
    columns: 1;
    
    fixed-height: false;
    fixed-columns: true;
    
    cycle: true;
    scrollbar: false;
    
    border: 1px 0 0;
    border-color: @bg-alt;
}

element {
    padding: 8px 12px;
    spacing: 8px;
}

element-icon {
    size: 24px;
}

element selected {
    background-color: @bg-alt;
}
EOF
    echo -e "${GREEN}✓ Created default rofi theme${NC}"
fi

echo -e "\n${GREEN}Troubleshooting complete!${NC}"
echo -e "${YELLOW}If issues persist, check:${NC}"
echo "• Hyprland logs: ~/.local/share/hyprland/"
echo "• System logs: journalctl --user -b"
echo "• Run verification: ~/max-dotfiles/verify-installation.sh"