#!/bin/bash
# Safe installation wrapper for dotfiles
# Provides additional safety checks and options

set -e

# Colors
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
PURPLE='\033[0;35m'
NC='\033[0m'

# Script directory
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

# Options
FORCE_BACKUP=true
CHECK_ONLY=false
MODULAR=false
SKIP_AUR=false
VERBOSE=false

usage() {
    echo "Usage: $0 [OPTIONS]"
    echo "Safe wrapper for dotfiles installation with enhanced safety features"
    echo
    echo "Options:"
    echo "  -c, --check         Check system compatibility without installing"
    echo "  -m, --modular       Use modular installer for step-by-step control"
    echo "  -n, --no-backup     Skip backup (not recommended)"
    echo "  -s, --skip-aur      Skip AUR package installation"
    echo "  -v, --verbose       Verbose output"
    echo "  -h, --help          Show this help message"
    echo
    echo "Safety features:"
    echo "  • Automatic backup before installation"
    echo "  • System compatibility checks"
    echo "  • Conflict detection"
    echo "  • Rollback capability"
}

# Parse arguments
while [[ $# -gt 0 ]]; do
    case $1 in
        -c|--check)
            CHECK_ONLY=true
            shift
            ;;
        -m|--modular)
            MODULAR=true
            shift
            ;;
        -n|--no-backup)
            FORCE_BACKUP=false
            shift
            ;;
        -s|--skip-aur)
            SKIP_AUR=true
            shift
            ;;
        -v|--verbose)
            VERBOSE=true
            shift
            ;;
        -h|--help)
            usage
            exit 0
            ;;
        *)
            echo "Unknown option: $1"
            usage
            exit 1
            ;;
    esac
done

echo -e "${BLUE}╔════════════════════════════════════════╗${NC}"
echo -e "${BLUE}║      Safe Dotfiles Installation        ║${NC}"
echo -e "${BLUE}╚════════════════════════════════════════╝${NC}"
echo

# Function to check system compatibility
check_system() {
    echo -e "${YELLOW}Checking system compatibility...${NC}"
    
    local issues=0
    
    # Check OS
    if [ -f /etc/arch-release ]; then
        echo -e "  ${GREEN}✓${NC} Arch Linux detected"
    else
        echo -e "  ${RED}✗${NC} Not running Arch Linux"
        ((issues++))
    fi
    
    # Check required commands
    local required_cmds=(git stow pacman sudo)
    for cmd in "${required_cmds[@]}"; do
        if command -v "$cmd" &> /dev/null; then
            echo -e "  ${GREEN}✓${NC} $cmd available"
        else
            echo -e "  ${RED}✗${NC} $cmd not found"
            ((issues++))
        fi
    done
    
    # Check if running as root
    if [ "$EUID" -eq 0 ]; then
        echo -e "  ${YELLOW}!${NC} Running as root (not recommended)"
    else
        echo -e "  ${GREEN}✓${NC} Running as normal user"
    fi
    
    # Check available disk space
    local available_space=$(df -BG "$HOME" | awk 'NR==2 {print $4}' | sed 's/G//')
    if [ "$available_space" -lt 5 ]; then
        echo -e "  ${YELLOW}!${NC} Low disk space: ${available_space}GB available"
    else
        echo -e "  ${GREEN}✓${NC} Sufficient disk space: ${available_space}GB available"
    fi
    
    return $issues
}

# Function to detect existing configs
detect_configs() {
    echo -e "\n${YELLOW}Detecting existing configurations...${NC}"
    
    local configs=(
        "$HOME/.config/hypr"
        "$HOME/.config/waybar"
        "$HOME/.config/nvim"
        "$HOME/.zshrc"
        "$HOME/.tmux.conf"
        "$HOME/.gitconfig"
    )
    
    local found=0
    for config in "${configs[@]}"; do
        if [ -e "$config" ]; then
            echo -e "  ${YELLOW}!${NC} Found: $config"
            ((found++))
        fi
    done
    
    if [ $found -gt 0 ]; then
        echo -e "\n  ${YELLOW}Found $found existing configurations${NC}"
        return 0
    else
        echo -e "  ${GREEN}✓${NC} No existing configurations found"
        return 1
    fi
}

# Function to check for conflicts
check_conflicts() {
    echo -e "\n${YELLOW}Checking for potential conflicts...${NC}"
    
    # Check if dotfiles directory already exists
    if [ -d "$HOME/.dotfiles" ] && [ "$(realpath "$HOME/.dotfiles")" != "$(realpath "$SCRIPT_DIR")" ]; then
        echo -e "  ${YELLOW}!${NC} Different dotfiles directory exists at $HOME/.dotfiles"
        echo -e "    Current: $(realpath "$HOME/.dotfiles")"
        echo -e "    New: $(realpath "$SCRIPT_DIR")"
    fi
    
    # Check for running Hyprland
    if pgrep -x "Hyprland" > /dev/null; then
        echo -e "  ${YELLOW}!${NC} Hyprland is currently running"
        echo -e "    Some changes may require restart"
    fi
    
    # Check for custom scripts that might be overwritten
    local scripts=("/usr/local/bin/nvim-tab" "/usr/local/bin/dev-sync" "/usr/local/bin/fix-audio")
    for script in "${scripts[@]}"; do
        if [ -f "$script" ]; then
            echo -e "  ${YELLOW}!${NC} Script exists: $script"
        fi
    done
}

# Main execution
main() {
    # System checks
    if ! check_system; then
        echo -e "\n${RED}System compatibility issues detected${NC}"
        if [ "$CHECK_ONLY" = false ]; then
            read -p "Continue anyway? (y/n) [n]: " -n 1 -r REPLY
            REPLY=${REPLY:-n}
            echo
            if [[ ! $REPLY =~ ^[Yy]$ ]]; then
                exit 1
            fi
        fi
    fi
    
    # Detect existing configs
    local has_configs=false
    if detect_configs; then
        has_configs=true
    fi
    
    # Check for conflicts
    check_conflicts
    
    # If check only mode, exit here
    if [ "$CHECK_ONLY" = true ]; then
        echo -e "\n${GREEN}Check complete${NC}"
        exit 0
    fi
    
    # Backup if needed
    if [ "$has_configs" = true ] && [ "$FORCE_BACKUP" = true ]; then
        echo -e "\n${YELLOW}Creating backup...${NC}"
        if [ -f "$SCRIPT_DIR/scripts/backup-configs.sh" ]; then
            "$SCRIPT_DIR/scripts/backup-configs.sh"
        else
            echo -e "${YELLOW}Backup script not found, using built-in backup${NC}"
            # Use the install script's backup function
        fi
    fi
    
    # Prepare installation options
    local install_opts=()
    if [ "$SKIP_AUR" = true ]; then
        install_opts+=("--skip-aur")
    fi
    if [ "$FORCE_BACKUP" = false ]; then
        install_opts+=("--skip-backup")
    fi
    
    # Run installation
    echo -e "\n${BLUE}Starting installation...${NC}"
    echo -e "${YELLOW}═══════════════════════════════════════${NC}"
    
    if [ "$MODULAR" = true ]; then
        echo -e "${YELLOW}Using modular installer${NC}"
        if [ -f "$SCRIPT_DIR/install-arch-modular.sh" ]; then
            "$SCRIPT_DIR/install-arch-modular.sh"
        else
            echo -e "${RED}Modular installer not found${NC}"
            exit 1
        fi
    else
        echo -e "${YELLOW}Using standard installer${NC}"
        if [ -f "$SCRIPT_DIR/install-arch.sh" ]; then
            "$SCRIPT_DIR/install-arch.sh" "${install_opts[@]}"
        else
            echo -e "${RED}Standard installer not found${NC}"
            exit 1
        fi
    fi
    
    # Post-installation summary
    echo -e "\n${BLUE}╔════════════════════════════════════════╗${NC}"
    echo -e "${BLUE}║        Installation Complete           ║${NC}"
    echo -e "${BLUE}╚════════════════════════════════════════╝${NC}"
    
    # Show backup location if created
    if [ -n "$DOTFILES_BACKUP_DIR" ]; then
        echo -e "\n${GREEN}Backup location:${NC}"
        echo -e "  $DOTFILES_BACKUP_DIR"
        echo -e "\n${YELLOW}To restore if needed:${NC}"
        echo -e "  $DOTFILES_BACKUP_DIR/restore.sh"
    fi
    
    echo -e "\n${GREEN}Next steps:${NC}"
    echo -e "  1. Review any warnings above"
    echo -e "  2. Restart your terminal or run: source ~/.zshrc"
    echo -e "  3. Reboot for full changes to take effect"
}

# Trap to ensure cleanup on exit
trap 'echo -e "\n${YELLOW}Installation interrupted${NC}"' INT TERM

# Run main
main

exit 0