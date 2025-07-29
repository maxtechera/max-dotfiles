#!/bin/bash
# Quick test to verify Hyprland can start

# Colors
GREEN='\033[0;32m'
RED='\033[0;31m'
YELLOW='\033[1;33m'
NC='\033[0m'

echo "Testing Hyprland setup..."
echo "========================"

# 1. Check if we're already in a graphical session
if [ ! -z "$DISPLAY" ] || [ ! -z "$WAYLAND_DISPLAY" ]; then
    echo -e "${YELLOW}! Already in a graphical session${NC}"
    echo "  To test Hyprland, log out first"
    exit 0
fi

# 2. Test Hyprland config
echo -n "Checking Hyprland config... "
if hyprctl version &> /dev/null; then
    echo -e "${GREEN}Valid${NC}"
else
    if Hyprland --config ~/.config/hypr/hyprland.conf --dry-run &> /dev/null; then
        echo -e "${GREEN}Valid${NC}"
    else
        echo -e "${RED}Invalid${NC}"
        echo "Run: Hyprland --config ~/.config/hypr/hyprland.conf --dry-run"
        echo "To see errors"
    fi
fi

# 3. Check critical binaries
echo -e "\nCritical binaries:"
for cmd in Hyprland waybar fuzzel ghostty; do
    if command -v $cmd &> /dev/null; then
        echo -e "${GREEN}✓${NC} $cmd"
    else
        echo -e "${RED}✗${NC} $cmd"
    fi
done

# 4. Check GPU drivers
echo -e "\nGPU drivers:"
if lsmod | grep -q nvidia; then
    echo -e "${GREEN}✓${NC} NVIDIA drivers loaded"
elif lsmod | grep -q amdgpu; then
    echo -e "${GREEN}✓${NC} AMD drivers loaded"
elif lsmod | grep -q i915; then
    echo -e "${GREEN}✓${NC} Intel drivers loaded"
else
    echo -e "${YELLOW}!${NC} No GPU drivers detected"
fi

# 5. Audio check
echo -e "\nAudio system:"
if systemctl --user is-active --quiet pipewire; then
    echo -e "${GREEN}✓${NC} Pipewire running"
else
    echo -e "${RED}✗${NC} Pipewire not running"
    echo "  Run: systemctl --user start pipewire"
fi

# 6. Quick launch test
echo -e "\n${YELLOW}Ready to test Hyprland?${NC}"
echo "You can:"
echo "1. Reboot and use SDDM login screen"
echo "2. Or test now with: Hyprland"
echo
echo "Press Alt+Enter to open Ghostty terminal once in Hyprland"
echo "Press Alt+Space to open app launcher (fuzzel)"
echo "Press Alt+Shift+Q to exit Hyprland"