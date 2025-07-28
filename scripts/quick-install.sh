#!/bin/bash
# Quick install wrapper for the modular installer
# Provides different installation profiles

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
MODULAR_INSTALLER="$SCRIPT_DIR/../install-arch-modular.sh"

# Colors
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m'

# Check if modular installer exists
if [ ! -f "$MODULAR_INSTALLER" ]; then
    echo -e "${RED}Modular installer not found at: $MODULAR_INSTALLER${NC}"
    exit 1
fi

# Make it executable
chmod +x "$MODULAR_INSTALLER"

# Installation profiles
case "${1:-full}" in
    minimal)
        echo -e "${BLUE}Running minimal installation...${NC}"
        echo -e "${YELLOW}This will install: essentials, shell, terminal, CLI tools${NC}"
        # Source the installer to use its functions
        source "$MODULAR_INSTALLER"
        run_module "01-essentials"
        run_module "02-yay"
        run_module "03-shell"
        run_module "04-terminal"
        run_module "05-cli-tools"
        run_module "07-development"
        ;;
        
    desktop)
        echo -e "${BLUE}Running desktop installation...${NC}"
        echo -e "${YELLOW}This will install: minimal + Hyprland + fonts${NC}"
        source "$MODULAR_INSTALLER"
        # Run minimal first
        for module in "01-essentials" "02-yay" "03-shell" "04-terminal" "05-cli-tools" "07-development"; do
            run_module "$module"
        done
        # Add desktop components
        run_module "08-gpu"
        run_module "09-hyprland-core"
        run_module "10-hyprland-utils"
        run_module "11-fonts"
        run_module "12-audio"
        run_module "14-display-manager"
        run_module "15-dotfiles"
        ;;
        
    full)
        echo -e "${BLUE}Running full installation...${NC}"
        echo -e "${YELLOW}This will install everything${NC}"
        "$MODULAR_INSTALLER"
        ;;
        
    interactive)
        echo -e "${BLUE}Running interactive installation...${NC}"
        "$MODULAR_INSTALLER"
        ;;
        
    *)
        echo "Usage: $0 [minimal|desktop|full|interactive]"
        echo
        echo "Profiles:"
        echo "  minimal     - Essential CLI tools only"
        echo "  desktop     - Minimal + Hyprland desktop"
        echo "  full        - Everything including AUR packages"
        echo "  interactive - Choose modules interactively (default)"
        exit 1
        ;;
esac