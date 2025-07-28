#!/bin/bash
# Fix Hyprland config deprecated options

# Colors
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m'

echo -e "${BLUE}Hyprland Config Fixer${NC}"
echo "====================="

HYPR_CONFIG="$HOME/.config/hypr/hyprland.conf"
BACKUP_CONFIG="$HOME/.config/hypr/hyprland.conf.backup-$(date +%Y%m%d%H%M%S)"

if [ ! -f "$HYPR_CONFIG" ]; then
    echo -e "${RED}Hyprland config not found at $HYPR_CONFIG${NC}"
    exit 1
fi

echo -e "${YELLOW}Backing up current config...${NC}"
cp "$HYPR_CONFIG" "$BACKUP_CONFIG"

echo -e "${YELLOW}Checking for deprecated options...${NC}"

# List of deprecated options to remove
DEPRECATED_OPTIONS=(
    "shadow_range"
    "shadow_render_power"
    "col.shadow"
    "active_opacity"
    "inactive_opacity"
    "new_optimizations"
    "damage_tracking"
    "use_nearest_neighbor"
    "no_vfr"
    "damage_entire_on_snapshot"
    "kb_variant"
    "kb_model"
    "kb_options"
    "kb_rules"
)

# Also check for deprecated syntax
DEPRECATED_PATTERNS=(
    "workspace.*silent"
    "blur:new_optimizations"
)

# Count fixes
FIXES=0

# Remove deprecated options
for option in "${DEPRECATED_OPTIONS[@]}"; do
    if grep -q "^[[:space:]]*$option" "$HYPR_CONFIG"; then
        echo -e "${YELLOW}Removing deprecated: $option${NC}"
        sed -i "/^[[:space:]]*$option/d" "$HYPR_CONFIG"
        ((FIXES++))
    fi
done

# Fix deprecated patterns
if grep -q "workspace.*silent" "$HYPR_CONFIG"; then
    echo -e "${YELLOW}Removing 'silent' from workspace rules${NC}"
    sed -i 's/workspace \([0-9]*\) silent/workspace \1/g' "$HYPR_CONFIG"
    ((FIXES++))
fi

# Fix blur syntax if needed
if grep -q "blur:new_optimizations" "$HYPR_CONFIG"; then
    echo -e "${YELLOW}Removing deprecated blur:new_optimizations${NC}"
    sed -i '/blur:new_optimizations/d' "$HYPR_CONFIG"
    ((FIXES++))
fi

# Show what we found in decoration block
echo -e "\n${BLUE}Current decoration block:${NC}"
sed -n '/^decoration {/,/^}/p' "$HYPR_CONFIG" | head -20

if [ $FIXES -gt 0 ]; then
    echo -e "\n${GREEN}Fixed $FIXES deprecated options!${NC}"
    echo -e "${YELLOW}Backup saved to: $BACKUP_CONFIG${NC}"
    
    # Reload Hyprland
    if command -v hyprctl &> /dev/null; then
        echo -e "${YELLOW}Reloading Hyprland...${NC}"
        hyprctl reload
    fi
else
    echo -e "\n${GREEN}No deprecated options found!${NC}"
    # Check if the config has the expected structure
    if ! grep -q "mainMod =" "$HYPR_CONFIG"; then
        echo -e "${RED}Warning: Config might be corrupted or incomplete${NC}"
    fi
fi

echo -e "\n${BLUE}If you still see errors:${NC}"
echo "1. Check the Hyprland wiki for current syntax"
echo "2. Run: journalctl --user -u hyprland -n 50"
echo "3. Try the default config: cp /usr/share/hyprland/hyprland.conf ~/.config/hypr/"