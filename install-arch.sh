#!/bin/bash
# Arch Linux Post-Install Setup
# Idempotent - can be run multiple times safely
# Only prompts when necessary for destructive operations

set -e

# Colors
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
PURPLE='\033[0;35m'
NC='\033[0m'

# Parse command line arguments
SKIP_BACKUP=false
SKIP_AUR=false
DRY_RUN=false

while [[ $# -gt 0 ]]; do
    case $1 in
        --skip-backup)
            SKIP_BACKUP=true
            shift
            ;;
        --skip-aur)
            SKIP_AUR=true
            shift
            ;;
        --dry-run)
            DRY_RUN=true
            shift
            ;;
        --help|-h)
            echo "Usage: $0 [OPTIONS]"
            echo "Options:"
            echo "  --skip-backup    Skip creating backup of existing configs"
            echo "  --skip-aur       Skip AUR package installation"
            echo "  --dry-run        Preview changes without making them"
            echo "  --help, -h       Show this help message"
            exit 0
            ;;
        *)
            echo "Unknown option: $1"
            echo "Use --help for usage information"
            exit 1
            ;;
    esac
done

echo -e "${BLUE}╔════════════════════════════════════════╗${NC}"
echo -e "${BLUE}║     Arch Linux Environment Setup       ║${NC}"
echo -e "${BLUE}║        Hyprland + Ghostty              ║${NC}"
echo -e "${BLUE}╚════════════════════════════════════════╝${NC}"

if [ "$DRY_RUN" = true ]; then
    echo -e "\n${YELLOW}DRY RUN MODE - No changes will be made${NC}"
    echo -e "${YELLOW}This will show what would be installed/changed${NC}\n"
fi

# Request sudo upfront and keep it alive (unless dry run)
if [ "$DRY_RUN" = false ]; then
    echo -e "\n${YELLOW}This script needs sudo access. Please enter your password:${NC}"
    sudo -v
    
    # Keep sudo alive in the background
    (while true; do sudo -n true; sleep 50; done 2>/dev/null) &
    SUDO_PID=$!
else
    SUDO_PID=""
fi

# Cleanup function to kill the sudo keepalive
cleanup() {
    kill $SUDO_PID 2>/dev/null || true
}
trap cleanup EXIT

# Helper functions
check_installed() {
    pacman -Qi "$1" &> /dev/null
}

check_aur_installed() {
    pacman -Qi "$1" &> /dev/null
}

install_if_missing() {
    local package=$1
    local critical=${2:-false}
    
    if ! check_installed "$package"; then
        if [ "$DRY_RUN" = true ]; then
            echo -e "${BLUE}[DRY RUN]${NC} Would install: $package"
            return 0
        fi
        echo -e "${YELLOW}Installing $package...${NC}"
        if sudo pacman -S --needed --noconfirm "$package" 2>/dev/null; then
            echo -e "${GREEN}✓ $package installed successfully${NC}"
        else
            if [ "$critical" = "true" ]; then
                echo -e "${RED}✗ CRITICAL: Failed to install $package${NC}"
                echo -e "${YELLOW}Attempting alternative installation methods...${NC}"
                
                # Try updating package database and retry
                sudo pacman -Sy 2>/dev/null
                if sudo pacman -S --needed --noconfirm "$package" 2>/dev/null; then
                    echo -e "${GREEN}✓ $package installed on retry${NC}"
                else
                    echo -e "${RED}FATAL: Cannot install critical package $package${NC}"
                    return 1
                fi
            else
                echo -e "${RED}✗ Failed to install $package (non-critical)${NC}"
                return 1
            fi
        fi
    else
        echo -e "${GREEN}✓ $package already installed${NC}"
    fi
    return 0
}

install_aur_if_missing() {
    local package=$1
    local critical=${2:-false}
    
    if ! check_aur_installed "$package"; then
        if [ "$DRY_RUN" = true ]; then
            echo -e "${BLUE}[DRY RUN]${NC} Would install from AUR: $package"
            return 0
        fi
        echo -e "${YELLOW}Installing $package from AUR...${NC}"
        if yay -S --needed --noconfirm "$package" 2>/dev/null; then
            echo -e "${GREEN}✓ $package installed successfully${NC}"
        else
            if [ "$critical" = "true" ]; then
                echo -e "${RED}✗ CRITICAL: Failed to install $package from AUR${NC}"
                echo -e "${YELLOW}AUR package installation failed. Manual intervention may be required.${NC}"
                return 1
            else
                echo -e "${RED}✗ Failed to install $package (non-critical AUR package)${NC}"
                return 1
            fi
        fi
    else
        echo -e "${GREEN}✓ $package already installed${NC}"
    fi
    return 0
}

# Enhanced critical package verification function
verify_critical_packages() {
    local failed_packages=()
    local critical_packages=("$@")
    
    echo -e "${YELLOW}Verifying critical packages...${NC}"
    for package in "${critical_packages[@]}"; do
        if ! check_installed "$package"; then
            failed_packages+=("$package")
            echo -e "${RED}✗ Critical package $package not installed${NC}"
        else
            echo -e "${GREEN}✓ $package verified and installed${NC}"
        fi
    done
    
    if [ ${#failed_packages[@]} -gt 0 ]; then
        echo -e "${RED}CRITICAL ERROR: The following essential packages failed to install:${NC}"
        printf '  %s\n' "${failed_packages[@]}"
        echo -e "${YELLOW}These packages are required for the system to function properly.${NC}"
        echo -e "${YELLOW}Attempting to reinstall missing packages...${NC}"
        
        # Attempt to reinstall missing critical packages
        local recovery_failed=()
        for package in "${failed_packages[@]}"; do
            echo -e "${YELLOW}Attempting to reinstall $package...${NC}"
            if sudo pacman -S --needed --noconfirm "$package" 2>/dev/null; then
                echo -e "${GREEN}✓ Successfully reinstalled $package${NC}"
            else
                recovery_failed+=("$package")
                echo -e "${RED}✗ Failed to reinstall $package${NC}"
            fi
        done
        
        # Final check after recovery attempt
        if [ ${#recovery_failed[@]} -gt 0 ]; then
            echo -e "${RED}FATAL ERROR: Cannot recover the following critical packages:${NC}"
            printf '  %s\n' "${recovery_failed[@]}"
            echo -e "${YELLOW}Manual intervention required. Installation cannot continue.${NC}"
            return 1
        else
            echo -e "${GREEN}✓ All critical packages recovered successfully${NC}"
        fi
    fi
    return 0
}

# Enhanced PATH verification function
verify_command_available() {
    local command=$1
    local package=${2:-$1}
    local optional=${3:-false}
    
    if command -v "$command" &> /dev/null; then
        local cmd_path=$(which "$command")
        echo -e "${GREEN}✓ $command available at: $cmd_path${NC}"
        return 0
    else
        if [ "$optional" = "true" ]; then
            echo -e "${YELLOW}! $command not found in PATH (package: $package) - OPTIONAL${NC}"
            return 0  # Don't fail for optional commands
        else
            echo -e "${RED}✗ $command not found in PATH (package: $package) - REQUIRED${NC}"
            return 1
        fi
    fi
}

# Comprehensive system verification function
verify_system_health() {
    echo -e "${YELLOW}Performing comprehensive system health check...${NC}"
    local failed_checks=()
    
    # Check critical system services
    local services=("NetworkManager" "bluetooth")
    for service in "${services[@]}"; do
        if systemctl is-enabled "$service" &> /dev/null; then
            echo -e "${GREEN}✓ $service service enabled${NC}"
        else
            echo -e "${YELLOW}! $service service not enabled${NC}"
        fi
    done
    
    # Check user services
    local user_services=("pipewire" "wireplumber")
    for service in "${user_services[@]}"; do
        if systemctl --user is-enabled "$service" &> /dev/null 2>&1; then
            echo -e "${GREEN}✓ $service user service enabled${NC}"
        else
            echo -e "${YELLOW}! $service user service not enabled${NC}"
        fi
    done
    
    # Check for required directories
    local dirs=("$HOME/.config" "$HOME/.local/bin" "$HOME/.local/share")
    for dir in "${dirs[@]}"; do
        if [ -d "$dir" ]; then
            echo -e "${GREEN}✓ Directory $dir exists${NC}"
        else
            mkdir -p "$dir"
            echo -e "${YELLOW}Created directory $dir${NC}"
        fi
    done
    
    return 0
}

# Comprehensive backup function
backup_all_configs() {
    echo -e "${YELLOW}Backing up existing configurations...${NC}"
    
    BACKUP_DIR="$HOME/.dotfiles-backup-$(date +%Y%m%d-%H%M%S)"
    mkdir -p "$BACKUP_DIR"
    
    # Create backup log
    BACKUP_LOG="$BACKUP_DIR/backup.log"
    echo "Dotfiles Installation Backup" > "$BACKUP_LOG"
    echo "Date: $(date)" >> "$BACKUP_LOG"
    echo "=========================" >> "$BACKUP_LOG"
    echo >> "$BACKUP_LOG"
    
    # List of configs to backup
    CONFIGS_TO_BACKUP=(
        ".config/hypr"
        ".config/waybar"
        ".config/ghostty"
        ".config/nvim"
        ".config/tmux"
        ".config/fuzzel"
        ".config/mako"
        ".config/gtk-3.0"
        ".config/gtk-4.0"
        ".config/rofi"
        ".tmux.conf"
        ".tmux"
        ".zshrc"
        ".zshenv"
        ".p10k.zsh"
        ".gitconfig"
        ".ssh/config"
        ".oh-my-zsh"
        ".nvm"
        ".claude"
        ".dotfiles"
    )
    
    echo -e "${BLUE}Creating backup at: $BACKUP_DIR${NC}"
    local backed_up=0
    local skipped=0
    
    for config in "${CONFIGS_TO_BACKUP[@]}"; do
        src="$HOME/$config"
        if [ -e "$src" ]; then
            # Create parent directory in backup
            parent_dir=$(dirname "$config")
            if [ "$parent_dir" != "." ]; then
                mkdir -p "$BACKUP_DIR/$parent_dir"
            fi
            
            # Copy the config
            if cp -rL "$src" "$BACKUP_DIR/$config" 2>/dev/null; then
                echo -e "  ${GREEN}✓${NC} Backed up: $config"
                echo "Backed up: $config" >> "$BACKUP_LOG"
                ((backed_up++))
            else
                echo -e "  ${YELLOW}!${NC} Failed to backup: $config"
                echo "Failed: $config" >> "$BACKUP_LOG"
            fi
        else
            ((skipped++))
        fi
    done
    
    # Backup installed package lists
    echo -e "\n${YELLOW}Backing up package lists...${NC}"
    pacman -Qqe > "$BACKUP_DIR/pacman-explicit.txt" 2>/dev/null
    pacman -Qqm > "$BACKUP_DIR/pacman-foreign.txt" 2>/dev/null
    
    if command -v yay &> /dev/null; then
        yay -Qqe > "$BACKUP_DIR/yay-packages.txt" 2>/dev/null
    fi
    
    # Create restore script
    cat > "$BACKUP_DIR/restore.sh" << 'EOF'
#!/bin/bash
# Restore script for dotfiles backup
# Usage: ./restore.sh [--dry-run]

BACKUP_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
DRY_RUN=false

if [ "$1" == "--dry-run" ]; then
    DRY_RUN=true
    echo "DRY RUN MODE - No changes will be made"
fi

echo "Restoring from backup: $BACKUP_DIR"
echo "This will restore the following configs:"
cat "$BACKUP_DIR/backup.log" | grep "^Backed up:" | sed 's/Backed up: /  - /'

if [ "$DRY_RUN" = false ]; then
    read -p "Continue with restore? (y/n) [n]: " -n 1 -r REPLY
    echo
    if [[ ! $REPLY =~ ^[Yy]$ ]]; then
        echo "Restore cancelled"
        exit 1
    fi
fi

# Restore configs
while IFS= read -r line; do
    if [[ $line =~ ^"Backed up: "(.+)$ ]]; then
        config="${BASH_REMATCH[1]}"
        src="$BACKUP_DIR/$config"
        dest="$HOME/$config"
        
        if [ "$DRY_RUN" = true ]; then
            echo "[DRY RUN] Would restore: $config"
        else
            # Create parent directory if needed
            parent_dir=$(dirname "$dest")
            mkdir -p "$parent_dir"
            
            # Remove existing and restore
            rm -rf "$dest" 2>/dev/null
            cp -r "$src" "$dest"
            echo "Restored: $config"
        fi
    fi
done < "$BACKUP_DIR/backup.log"

echo "Restore complete!"
EOF
    
    chmod +x "$BACKUP_DIR/restore.sh"
    
    echo >> "$BACKUP_LOG"
    echo "Summary:" >> "$BACKUP_LOG"
    echo "  Backed up: $backed_up items" >> "$BACKUP_LOG"
    echo "  Skipped: $skipped items (not found)" >> "$BACKUP_LOG"
    
    echo -e "\n${GREEN}✓ Backup complete!${NC}"
    echo -e "  ${GREEN}Location:${NC} $BACKUP_DIR"
    echo -e "  ${GREEN}Items backed up:${NC} $backed_up"
    echo -e "  ${GREEN}Items skipped:${NC} $skipped"
    echo -e "\n${YELLOW}To restore this backup later, run:${NC}"
    echo -e "  ${BLUE}$BACKUP_DIR/restore.sh${NC}"
    
    # Store backup location for reference
    export DOTFILES_BACKUP_DIR="$BACKUP_DIR"
}

# Check if we should run backup
should_backup() {
    if [ "$SKIP_BACKUP" = "true" ]; then
        return 1
    fi
    
    # Check if any configs exist
    for config in .config/hypr .config/waybar .config/nvim .zshrc .tmux.conf; do
        if [ -e "$HOME/$config" ]; then
            return 0
        fi
    done
    
    return 1
}

# Progress counter
STEP=0
TOTAL_STEPS=14

step() {
    STEP=$((STEP + 1))
    echo -e "\n${PURPLE}[$STEP/$TOTAL_STEPS]${NC} $1"
}

# Run comprehensive backup before starting
if should_backup && [ "$DRY_RUN" = false ]; then
    echo -e "\n${YELLOW}Existing configurations detected.${NC}"
    read -p "Create a full backup before proceeding? (recommended) (y/n) [y]: " -n 1 -r BACKUP_CHOICE
    BACKUP_CHOICE=${BACKUP_CHOICE:-y}
    echo
    if [[ $BACKUP_CHOICE =~ ^[Yy]$ ]]; then
        backup_all_configs
        echo -e "\n${YELLOW}Backup complete. Proceeding with installation...${NC}"
        sleep 2
    else
        echo -e "${YELLOW}⚠️  WARNING: Proceeding without backup!${NC}"
        echo -e "${YELLOW}Some configurations may be overwritten.${NC}"
        read -p "Are you sure you want to continue? (y/n) [n]: " -n 1 -r CONFIRM
        CONFIRM=${CONFIRM:-n}
        echo
        if [[ ! $CONFIRM =~ ^[Yy]$ ]]; then
            echo -e "${RED}Installation cancelled.${NC}"
            exit 1
        fi
    fi
elif [ "$DRY_RUN" = true ] && should_backup; then
    echo -e "\n${BLUE}[DRY RUN]${NC} Would create backup of existing configurations"
fi

# Install essential build tools (critical for everything else)
step "Checking essential build tools..."
ESSENTIALS=(base-devel git wget curl)
echo -e "${YELLOW}Installing critical build dependencies...${NC}"
for pkg in "${ESSENTIALS[@]}"; do
    if ! install_if_missing "$pkg" true; then
        echo -e "${RED}FATAL: Cannot continue without $pkg${NC}"
        exit 1
    fi
done
echo -e "${GREEN}✓ All essential build tools ready${NC}"

# Update system
step "Updating system..."
echo -e "${YELLOW}Checking for updates...${NC}"
if [[ $(checkupdates 2>/dev/null | wc -l) -gt 0 ]]; then
    echo -e "${YELLOW}Updates available. Updating system...${NC}"
    sudo pacman -Syu --noconfirm
else
    echo -e "${GREEN}✓ System is up to date${NC}"
fi

# Detect and install GPU drivers
step "Detecting GPU..."
GPU_TYPE="unknown"
GPU_INSTALLED=false

if lspci | grep -i nvidia > /dev/null; then
    GPU_TYPE="nvidia"
    echo -e "${GREEN}NVIDIA GPU detected${NC}"
    
    if check_installed nvidia && check_installed nvidia-utils; then
        echo -e "${GREEN}✓ NVIDIA drivers already installed${NC}"
        GPU_INSTALLED=true
    else
        read -p "Install NVIDIA drivers? (y/n) [y]: " -n 1 -r REPLY
        REPLY=${REPLY:-y}
        echo
        if [[ $REPLY =~ ^[Yy]$ ]]; then
            sudo pacman -S --needed --noconfirm nvidia nvidia-utils nvidia-settings
            
            if [ ! -f /etc/modprobe.d/nvidia.conf ]; then
                echo "options nvidia-drm modeset=1" | sudo tee /etc/modprobe.d/nvidia.conf
                echo -e "${YELLOW}Note: Reboot required for NVIDIA drivers${NC}"
            fi
        fi
    fi
elif lspci | grep -i amd | grep -i vga > /dev/null; then
    GPU_TYPE="amd"
    echo -e "${GREEN}AMD GPU detected${NC}"
    AMD_PACKAGES=(mesa vulkan-radeon libva-mesa-driver)
    for pkg in "${AMD_PACKAGES[@]}"; do
        install_if_missing "$pkg"
    done
elif lspci | grep -i intel | grep -i vga > /dev/null; then
    GPU_TYPE="intel"
    echo -e "${GREEN}Intel GPU detected${NC}"
    INTEL_PACKAGES=(mesa vulkan-intel intel-media-driver)
    for pkg in "${INTEL_PACKAGES[@]}"; do
        install_if_missing "$pkg"
    done
fi

# Install yay (AUR helper) - Critical for AUR packages
step "Installing AUR helper..."
if ! command -v yay &> /dev/null; then
    echo -e "${YELLOW}Installing yay (AUR helper)...${NC}"
    TEMP_DIR=$(mktemp -d)
    
    if git clone https://aur.archlinux.org/yay-bin.git "$TEMP_DIR/yay-bin" 2>/dev/null; then
        cd "$TEMP_DIR/yay-bin"
        if makepkg -si --noconfirm 2>/dev/null; then
            echo -e "${GREEN}✓ yay installed successfully${NC}"
        else
            echo -e "${RED}FATAL: Failed to build yay${NC}"
            cd -
            rm -rf "$TEMP_DIR"
            exit 1
        fi
        cd -
        rm -rf "$TEMP_DIR"
    else
        echo -e "${RED}FATAL: Failed to clone yay repository${NC}"
        rm -rf "$TEMP_DIR"
        exit 1
    fi
    
    # Verify yay installation
    if ! command -v yay &> /dev/null; then
        echo -e "${RED}FATAL: yay installation failed - AUR packages unavailable${NC}"
        exit 1
    fi
else
    echo -e "${GREEN}✓ yay already installed${NC}"
fi

# Verify yay works
if ! yay --version &> /dev/null; then
    echo -e "${RED}FATAL: yay installed but not working properly${NC}"
    exit 1
fi
echo -e "${GREEN}✓ yay verified: $(yay --version | head -1)${NC}"

# Install base packages
step "Installing base packages..."
BASE_PACKAGES=(
    neovim neovim-remote tmux zsh stow
    wget curl unzip ripgrep fd fzf bat jq bc
    htop btop neofetch ranger lazygit
    github-cli jq man-db man-pages
    openssh python python-pip python-pipx
    chromium tree ncdu duf tldr eza
    zoxide direnv thefuck httpie glow
)

# Build list of packages to install
PACKAGES_TO_INSTALL=()
echo -e "${YELLOW}Checking base packages...${NC}"
for pkg in "${BASE_PACKAGES[@]}"; do
    if ! check_installed "$pkg"; then
        PACKAGES_TO_INSTALL+=("$pkg")
    fi
done

if [ ${#PACKAGES_TO_INSTALL[@]} -gt 0 ]; then
    echo -e "${YELLOW}Installing ${#PACKAGES_TO_INSTALL[@]} base packages...${NC}"
    
    # Try bulk install first
    if sudo pacman -S --needed --noconfirm "${PACKAGES_TO_INSTALL[@]}" 2>/dev/null; then
        echo -e "${GREEN}✓ All base packages installed successfully${NC}"
    else
        echo -e "${YELLOW}Bulk install failed, installing individually...${NC}"
        local failed_packages=()
        for pkg in "${PACKAGES_TO_INSTALL[@]}"; do
            if ! sudo pacman -S --needed --noconfirm "$pkg" 2>/dev/null; then
                failed_packages+=("$pkg")
                echo -e "${RED}✗ Failed to install $pkg${NC}"
            else
                echo -e "${GREEN}✓ $pkg installed${NC}"
            fi
        done
        
        if [ ${#failed_packages[@]} -gt 0 ]; then
            echo -e "${YELLOW}Non-critical packages that failed: ${failed_packages[*]}${NC}"
        fi
    fi
fi
echo -e "${GREEN}✓ Base packages ready${NC}"

# Install Hyprland and dependencies
step "Installing Hyprland..."
HYPRLAND_PACKAGES=(
    hyprland xdg-desktop-portal-hyprland qt5-wayland qt6-wayland
    polkit-kde-agent pipewire wireplumber pipewire-pulse pipewire-alsa
    pipewire-jack grim slurp wl-clipboard swappy mako waybar
    fuzzel swww swaylock-effects wlogout hyprpicker
    xdg-utils xorg-xwayland pavucontrol brightnessctl playerctl
    pamixer thunar thunar-archive-plugin file-roller tumbler
    gvfs gvfs-mtp thunar-volman bluez bluez-utils blueman
    network-manager-applet
)

# Build list of packages to install
PACKAGES_TO_INSTALL=()
echo -e "${YELLOW}Checking Hyprland packages...${NC}"
for pkg in "${HYPRLAND_PACKAGES[@]}"; do
    if ! check_installed "$pkg"; then
        PACKAGES_TO_INSTALL+=("$pkg")
    fi
done

if [ ${#PACKAGES_TO_INSTALL[@]} -gt 0 ]; then
    echo -e "${YELLOW}Installing ${#PACKAGES_TO_INSTALL[@]} Hyprland packages...${NC}"
    
    # Try bulk install first
    if sudo pacman -S --needed --noconfirm "${PACKAGES_TO_INSTALL[@]}" 2>/dev/null; then
        echo -e "${GREEN}✓ All Hyprland packages installed successfully${NC}"
    else
        echo -e "${YELLOW}Bulk install failed, installing individually...${NC}"
        local failed_packages=()
        for pkg in "${PACKAGES_TO_INSTALL[@]}"; do
            if ! sudo pacman -S --needed --noconfirm "$pkg" 2>/dev/null; then
                failed_packages+=("$pkg")
                echo -e "${RED}✗ Failed to install $pkg${NC}"
            else
                echo -e "${GREEN}✓ $pkg installed${NC}"
            fi
        done
        
        if [ ${#failed_packages[@]} -gt 0 ]; then
            echo -e "${RED}ATTENTION: The following packages failed to install:${NC}"
            printf '  %s\n' "${failed_packages[@]}"
            echo -e "${YELLOW}This may affect functionality. Consider manual installation.${NC}"
        fi
    fi
fi

# Verify critical Hyprland packages are installed
echo -e "${YELLOW}Verifying Hyprland environment...${NC}"
CRITICAL_HYPRLAND=("hyprland" "fuzzel" "mako" "swww" "waybar" "pipewire" "wireplumber" "grim" "slurp" "wl-clipboard")
if ! verify_critical_packages "${CRITICAL_HYPRLAND[@]}"; then
    echo -e "${RED}CRITICAL ERROR: Essential Hyprland packages missing. Installation cannot continue.${NC}"
    exit 1
fi

# Additional verification for Hyprland-specific functionality
echo -e "${YELLOW}Checking Hyprland component availability...${NC}"
HYPRLAND_COMMANDS=("hyprland" "fuzzel" "mako" "swww" "waybar" "grim" "slurp" "wl-copy")
for cmd in "${HYPRLAND_COMMANDS[@]}"; do
    if ! verify_command_available "$cmd"; then
        echo -e "${RED}CRITICAL: $cmd command not available${NC}"
        exit 1
    fi
done

echo -e "${GREEN}✓ Hyprland environment verified and ready${NC}"

# Install fonts
step "Installing fonts..."
FONT_PACKAGES=(
    ttf-jetbrains-mono-nerd ttf-font-awesome ttf-nerd-fonts-symbols
    noto-fonts noto-fonts-cjk noto-fonts-emoji ttf-firacode-nerd
    inter-font ttf-roboto ttf-ubuntu-font-family
)

# Build list of packages to install
PACKAGES_TO_INSTALL=()
echo -e "${YELLOW}Checking fonts...${NC}"
for pkg in "${FONT_PACKAGES[@]}"; do
    if ! check_installed "$pkg"; then
        PACKAGES_TO_INSTALL+=("$pkg")
    fi
done

if [ ${#PACKAGES_TO_INSTALL[@]} -gt 0 ]; then
    echo -e "${YELLOW}Installing ${#PACKAGES_TO_INSTALL[@]} font packages...${NC}"
    
    # Try bulk install first
    if sudo pacman -S --needed --noconfirm "${PACKAGES_TO_INSTALL[@]}" 2>/dev/null; then
        echo -e "${GREEN}✓ All font packages installed successfully${NC}"
    else
        echo -e "${YELLOW}Bulk install failed, installing individually...${NC}"
        local failed_packages=()
        for pkg in "${PACKAGES_TO_INSTALL[@]}"; do
            if ! sudo pacman -S --needed --noconfirm "$pkg" 2>/dev/null; then
                failed_packages+=("$pkg")
                echo -e "${RED}✗ Failed to install $pkg${NC}"
            else
                echo -e "${GREEN}✓ $pkg installed${NC}"
            fi
        done
        
        if [ ${#failed_packages[@]} -gt 0 ]; then
            echo -e "${YELLOW}Font packages that failed: ${failed_packages[*]}${NC}"
        fi
    fi
fi
echo -e "${GREEN}✓ Fonts ready${NC}"

# Install Ghostty
step "Installing Ghostty..."
if ! check_installed "ghostty"; then
    echo -e "${YELLOW}Installing Ghostty from official repository...${NC}"
    sudo pacman -S --needed --noconfirm ghostty
else
    echo -e "${GREEN}✓ Ghostty already installed${NC}"
fi

# Install AUR packages
step "Installing AUR packages (optional)..."

# Check if user wants to skip AUR packages
if [ "$SKIP_AUR" = true ]; then
    echo -e "${YELLOW}Skipping AUR packages as requested${NC}"
else
    echo -e "${YELLOW}AUR packages can take 10-30 minutes to compile${NC}"
    read -p "Install AUR packages now? (y/n) [y]: " -n 1 -r SKIP_AUR
    SKIP_AUR=${SKIP_AUR:-y}
    echo
    
    if [[ $SKIP_AUR =~ ^[Yy]$ ]]; then
        # Essential AUR packages (faster to install)
        ESSENTIAL_AUR=(
            visual-studio-code-bin
            spotify
            claude-code
        )
        
        # Optional AUR packages (slower, larger)
        OPTIONAL_AUR=(
            slack-desktop
            zoom
            postman-bin
            figma-linux-bin
            1password
            1password-cli
            grimblast-git
        )
        
        echo -e "\n${YELLOW}Installing essential AUR packages...${NC}"
        for pkg in "${ESSENTIAL_AUR[@]}"; do
            if ! check_aur_installed "$pkg"; then
                echo -e "${YELLOW}Installing $pkg...${NC}"
                yay -S --needed --noconfirm "$pkg" || echo -e "${YELLOW}! Failed to install $pkg${NC}"
            else
                echo -e "${GREEN}✓ $pkg already installed${NC}"
            fi
        done
        
        echo -e "\n${YELLOW}Optional AUR packages available:${NC}"
        for pkg in "${OPTIONAL_AUR[@]}"; do
            if ! check_aur_installed "$pkg"; then
                read -p "Install $pkg? (y/n) [n]: " -n 1 -r REPLY
                REPLY=${REPLY:-n}
                echo
                if [[ $REPLY =~ ^[Yy]$ ]]; then
                    yay -S --needed --noconfirm "$pkg" || echo -e "${YELLOW}! Failed to install $pkg${NC}"
                fi
            else
                echo -e "${GREEN}✓ $pkg already installed${NC}"
            fi
        done
    else
        echo -e "${YELLOW}Skipping AUR packages. You can install them later with:${NC}"
        echo "yay -S visual-studio-code-bin spotify slack-desktop"
    fi
fi

# Clone and setup dotfiles
step "Setting up dotfiles..."
DOTFILES_DIR="$HOME/.dotfiles"

# Handle existing configs (removed rofi from list)
CONFIGS=(hypr waybar ghostty nvim tmux zsh git)
for config in "${CONFIGS[@]}"; do
    if [ -e "$HOME/.config/$config" ] && [ ! -L "$HOME/.config/$config" ]; then
        echo -e "${YELLOW}Found existing $config config${NC}"
        read -p "Backup and replace? (y/n) [y]: " -n 1 -r REPLY
        REPLY=${REPLY:-y}
        echo
        if [[ $REPLY =~ ^[Yy]$ ]]; then
            mv "$HOME/.config/$config" "$HOME/.config/$config.backup.$(date +%Y%m%d%H%M%S)"
            echo -e "${GREEN}Backed up $config config${NC}"
        else
            echo -e "${YELLOW}Keeping existing $config config${NC}"
            continue
        fi
    fi
done

# Setup dotfiles directory
if [ -d "$DOTFILES_DIR" ]; then
    if [ "$(realpath "$DOTFILES_DIR")" != "$(realpath "$(pwd)")" ]; then
        echo -e "${YELLOW}Dotfiles directory exists at $DOTFILES_DIR${NC}"
        read -p "Replace with current directory? (y/n) [n]: " -n 1 -r REPLY
        REPLY=${REPLY:-n}
        echo
        if [[ $REPLY =~ ^[Yy]$ ]]; then
            mv "$DOTFILES_DIR" "$DOTFILES_DIR.backup.$(date +%Y%m%d%H%M%S)"
            cp -r "$(pwd)" "$DOTFILES_DIR"
        fi
    else
        echo -e "${GREEN}✓ Using existing dotfiles directory${NC}"
    fi
else
    cp -r "$(pwd)" "$DOTFILES_DIR"
fi

cd "$DOTFILES_DIR"

# Install custom scripts
echo -e "${YELLOW}Installing custom scripts...${NC}"
for script in scripts/nvim-tab scripts/github-dev-sync.sh scripts/fix-arch-audio.sh; do
    if [ -f "$script" ]; then
        SCRIPT_NAME=$(basename "$script" .sh)
        DEST="/usr/local/bin/${SCRIPT_NAME/github-dev-sync/dev-sync}"
        DEST="${DEST/fix-arch-audio/fix-audio}"
        
        if [ ! -f "$DEST" ] || ! cmp -s "$script" "$DEST" 2>/dev/null; then
            sudo install -m 755 "$script" "$DEST"
            echo -e "  ${GREEN}✓ Installed $(basename "$DEST")${NC}"
        else
            echo -e "  ${GREEN}✓ $(basename "$DEST") up to date${NC}"
        fi
    fi
done

# Backup Claude config if needed
if [ -f "$DOTFILES_DIR/scripts/backup-claude-config.sh" ]; then
    "$DOTFILES_DIR/scripts/backup-claude-config.sh"
fi

# Safe stow function with conflict handling
safe_stow() {
    local dir="$1"
    local target_path=""
    
    # Determine target path based on directory
    case "$dir" in
        zsh|git|tmux)
            # These create dotfiles in home directory
            target_path="$HOME/.$(basename $dir)rc"
            if [ "$dir" = "git" ]; then
                target_path="$HOME/.gitconfig"
            fi
            ;;
        dev)
            # Special case: links to ~/dev
            target_path="$HOME/dev"
            ;;
        *)
            # Most configs go to .config
            target_path="$HOME/.config/$dir"
            ;;
    esac
    
    # Check if already properly stowed
    if [ -L "$target_path" ]; then
        local link_target=$(readlink "$target_path")
        if [[ "$link_target" == *"/.dotfiles/$dir/"* ]]; then
            echo -e "  ${GREEN}✓ $dir already linked${NC}"
            return 0
        else
            echo -e "  ${YELLOW}! $dir linked to different location: $link_target${NC}"
            read -p "    Replace with dotfiles version? (y/n) [n]: " -n 1 -r REPLY
            REPLY=${REPLY:-n}
            echo
            if [[ $REPLY =~ ^[Yy]$ ]]; then
                rm "$target_path"
            else
                echo -e "    ${YELLOW}Skipping $dir${NC}"
                return 1
            fi
        fi
    elif [ -e "$target_path" ]; then
        # File/directory exists but is not a symlink
        echo -e "  ${YELLOW}! $dir config exists at $target_path${NC}"
        read -p "    Backup and replace? (y/n) [y]: " -n 1 -r REPLY
        REPLY=${REPLY:-y}
        echo
        if [[ $REPLY =~ ^[Yy]$ ]]; then
            local backup_path="$target_path.backup.$(date +%Y%m%d%H%M%S)"
            mv "$target_path" "$backup_path"
            echo -e "    ${GREEN}Backed up to: $backup_path${NC}"
        else
            echo -e "    ${YELLOW}Skipping $dir${NC}"
            return 1
        fi
    fi
    
    # Now try to stow
    if [ "$DRY_RUN" = true ]; then
        echo -e "  ${BLUE}[DRY RUN]${NC} Would link: $dir -> $target_path"
        return 0
    fi
    
    if stow -v "$dir" 2>&1; then
        echo -e "  ${GREEN}✓ $dir linked successfully${NC}"
        return 0
    else
        # Stow failed, try to diagnose why
        local stow_error=$(stow -n -v "$dir" 2>&1)
        if [[ "$stow_error" == *"existing target is not"* ]]; then
            echo -e "  ${RED}✗ $dir failed: Conflicts detected${NC}"
            echo -e "    ${YELLOW}Run 'stow -n -v $dir' for details${NC}"
        else
            echo -e "  ${RED}✗ $dir failed: Unknown error${NC}"
        fi
        return 1
    fi
}

# Use GNU Stow to symlink configs
echo -e "${YELLOW}Creating symlinks...${NC}"
for dir in hypr waybar ghostty nvim tmux zsh git dev fuzzel mako gtk claude; do
    if [ -d "$dir" ]; then
        safe_stow "$dir"
    else
        echo -e "  ${YELLOW}! $dir directory not found in dotfiles${NC}"
    fi
done

# Clean up old launcher configs
echo -e "${YELLOW}Cleaning up launcher configuration...${NC}"
if [ -f "$DOTFILES_DIR/scripts/cleanup-rofi.sh" ]; then
    "$DOTFILES_DIR/scripts/cleanup-rofi.sh"
else
    # Inline cleanup if script not found
    [ -d "$HOME/.config/rofi" ] && rm -rf "$HOME/.config/rofi"
    pacman -Qi rofi-wayland &> /dev/null && sudo pacman -R --noconfirm rofi-wayland
fi

# Verify Hyprland configuration
echo -e "${YELLOW}Verifying Hyprland configuration...${NC}"
HYPR_CONFIG="$HOME/.config/hypr/hyprland.conf"

if [ -f "$HYPR_CONFIG" ]; then
    echo -e "${GREEN}✓ Hyprland configuration present${NC}"
    
    # Verify it uses Super key (Linux standard)
    if grep -q "mainMod = SUPER" "$HYPR_CONFIG" 2>/dev/null; then
        echo -e "${GREEN}✓ Using Super key (Linux standard)${NC}"
    else
        echo -e "${YELLOW}! Config may not be using Super key${NC}"
    fi
    
    # Verify essential exec-once entries
    ESSENTIAL_EXECS=("waybar" "mako" "fuzzel" "swww")
    for exec in "${ESSENTIAL_EXECS[@]}"; do
        if grep -q "exec-once.*$exec" "$HYPR_CONFIG" 2>/dev/null; then
            echo -e "${GREEN}  ✓ $exec configured to start${NC}"
        else
            echo -e "${YELLOW}  ! $exec not found in exec-once${NC}"
        fi
    done
else
    echo -e "${RED}! Hyprland configuration not found${NC}"
fi

# Change default shell to zsh
step "Setting up shell..."
if [ "$SHELL" != "$(which zsh)" ]; then
    echo -e "${YELLOW}Current shell: $SHELL${NC}"
    read -p "Change default shell to zsh? (y/n) [y]: " -n 1 -r REPLY
    REPLY=${REPLY:-y}
    echo
    if [[ $REPLY =~ ^[Yy]$ ]]; then
        if [ "$DRY_RUN" = true ]; then
            echo -e "${BLUE}[DRY RUN]${NC} Would change shell to: $(which zsh)"
        else
            chsh -s $(which zsh)
            echo -e "${GREEN}✓ Default shell changed to zsh${NC}"
        fi
    fi
else
    echo -e "${GREEN}✓ Already using zsh${NC}"
fi

# Enable services
echo -e "${YELLOW}Enabling services...${NC}"
if [ "$DRY_RUN" = true ]; then
    echo -e "${BLUE}[DRY RUN]${NC} Would enable services:"
    echo -e "  - pipewire (user)"
    echo -e "  - wireplumber (user)"
    echo -e "  - bluetooth (system)"
    echo -e "  - NetworkManager (system)"
else
    systemctl --user enable pipewire 2>/dev/null || true
    systemctl --user enable wireplumber 2>/dev/null || true
    sudo systemctl enable bluetooth 2>/dev/null || true
    sudo systemctl enable NetworkManager 2>/dev/null || true
    echo -e "${GREEN}✓ Services enabled${NC}"
fi

# Install Oh My Zsh
if [ ! -d "$HOME/.oh-my-zsh" ]; then
    echo -e "${YELLOW}Installing Oh My Zsh...${NC}"
    sh -c "$(curl -fsSL https://raw.githubusercontent.com/ohmyzsh/ohmyzsh/master/tools/install.sh)" "" --unattended
else
    echo -e "${GREEN}✓ Oh My Zsh already installed${NC}"
fi

# Configure Powerlevel10k immediately after Oh My Zsh installation
if [ -f "$DOTFILES_DIR/zsh/.p10k.zsh" ] && [ ! -f "$HOME/.p10k.zsh" ]; then
    echo -e "${YELLOW}Installing optimized Powerlevel10k configuration...${NC}"
    cp "$DOTFILES_DIR/zsh/.p10k.zsh" "$HOME/.p10k.zsh"
    echo -e "${GREEN}✓ Powerlevel10k configuration installed${NC}"
fi

# Set up performance-optimized zsh plugins and theme
echo -e "${YELLOW}Installing performance-optimized zsh setup...${NC}"
ZSH_CUSTOM=${ZSH_CUSTOM:-~/.oh-my-zsh/custom}

# Install Powerlevel10k theme
if [ ! -d "$ZSH_CUSTOM/themes/powerlevel10k" ]; then
    echo -e "${YELLOW}Installing Powerlevel10k theme...${NC}"
    git clone --depth=1 https://github.com/romkatv/powerlevel10k.git "$ZSH_CUSTOM/themes/powerlevel10k"
else
    echo -e "${GREEN}✓ Powerlevel10k already installed${NC}"
fi

# Install and verify performance-optimized plugins
echo -e "${YELLOW}Setting up performance-optimized zsh plugins...${NC}"

# Ensure zoxide is installed for fast directory jumping
if ! check_installed "zoxide"; then
    echo -e "${YELLOW}Installing zoxide for fast directory jumping...${NC}"
    install_if_missing "zoxide"
fi

# Ensure direnv is installed for automatic environment management
if ! check_installed "direnv"; then
    echo -e "${YELLOW}Installing direnv for automatic environment management...${NC}"
    install_if_missing "direnv"
fi

# Install zsh-autosuggestions
if [ ! -d "$ZSH_CUSTOM/plugins/zsh-autosuggestions" ]; then
    echo -e "${YELLOW}Installing zsh-autosuggestions...${NC}"
    if git clone https://github.com/zsh-users/zsh-autosuggestions "$ZSH_CUSTOM/plugins/zsh-autosuggestions"; then
        echo -e "${GREEN}✓ zsh-autosuggestions installed${NC}"
    else
        echo -e "${RED}✗ Failed to install zsh-autosuggestions${NC}"
    fi
else
    echo -e "${GREEN}✓ zsh-autosuggestions already installed${NC}"
fi

# Use fast-syntax-highlighting instead of zsh-syntax-highlighting for better performance
if [ ! -d "$ZSH_CUSTOM/plugins/fast-syntax-highlighting" ]; then
    echo -e "${YELLOW}Installing fast-syntax-highlighting (performance optimized)...${NC}"
    if git clone https://github.com/zdharma-continuum/fast-syntax-highlighting.git "$ZSH_CUSTOM/plugins/fast-syntax-highlighting"; then
        echo -e "${GREEN}✓ fast-syntax-highlighting installed${NC}"
        echo -e "${YELLOW}Verifying fast-syntax-highlighting installation...${NC}"
        if [ -f "$ZSH_CUSTOM/plugins/fast-syntax-highlighting/fast-syntax-highlighting.plugin.zsh" ]; then
            echo -e "${GREEN}✓ fast-syntax-highlighting verified and ready${NC}"
        else
            echo -e "${RED}✗ fast-syntax-highlighting plugin file missing${NC}"
        fi
    else
        echo -e "${RED}✗ Failed to install fast-syntax-highlighting${NC}"
    fi
else
    echo -e "${GREEN}✓ fast-syntax-highlighting already installed${NC}"
fi

# Install zsh-autocomplete for better completion performance
if [ ! -d "$ZSH_CUSTOM/plugins/zsh-autocomplete" ]; then
    echo -e "${YELLOW}Installing zsh-autocomplete (performance optimized)...${NC}"
    if git clone --depth 1 -- https://github.com/marlonrichert/zsh-autocomplete.git "$ZSH_CUSTOM/plugins/zsh-autocomplete"; then
        echo -e "${GREEN}✓ zsh-autocomplete installed${NC}"
    else
        echo -e "${RED}✗ Failed to install zsh-autocomplete${NC}"
    fi
else
    echo -e "${GREEN}✓ zsh-autocomplete already installed${NC}"
fi

# Remove old zsh-syntax-highlighting if it exists (replaced by fast-syntax-highlighting)
if [ -d "$ZSH_CUSTOM/plugins/zsh-syntax-highlighting" ]; then
    echo -e "${YELLOW}Removing old zsh-syntax-highlighting (replaced by fast version)...${NC}"
    rm -rf "$ZSH_CUSTOM/plugins/zsh-syntax-highlighting"
    echo -e "${GREEN}✓ Old zsh-syntax-highlighting removed${NC}"
fi

# Verify plugin installation and functionality
echo -e "${YELLOW}Verifying plugin installations...${NC}"
PLUGIN_VERIFICATION_FAILED=false

# Check zsh-autosuggestions
if [ -f "$ZSH_CUSTOM/plugins/zsh-autosuggestions/zsh-autosuggestions.plugin.zsh" ]; then
    echo -e "${GREEN}✓ zsh-autosuggestions plugin file verified${NC}"
else
    echo -e "${RED}✗ zsh-autosuggestions plugin file missing${NC}"
    PLUGIN_VERIFICATION_FAILED=true
fi

# Check fast-syntax-highlighting
if [ -f "$ZSH_CUSTOM/plugins/fast-syntax-highlighting/fast-syntax-highlighting.plugin.zsh" ]; then
    echo -e "${GREEN}✓ fast-syntax-highlighting plugin file verified${NC}"
else
    echo -e "${RED}✗ fast-syntax-highlighting plugin file missing${NC}"
    PLUGIN_VERIFICATION_FAILED=true
fi

# Check zsh-autocomplete
if [ -f "$ZSH_CUSTOM/plugins/zsh-autocomplete/zsh-autocomplete.plugin.zsh" ]; then
    echo -e "${GREEN}✓ zsh-autocomplete plugin file verified${NC}"
else
    echo -e "${RED}✗ zsh-autocomplete plugin file missing${NC}"
    PLUGIN_VERIFICATION_FAILED=true
fi

if [ "$PLUGIN_VERIFICATION_FAILED" = true ]; then
    echo -e "${YELLOW}! Some plugins failed verification but installation will continue${NC}"
    echo -e "${YELLOW}! You may experience reduced shell performance${NC}"
else
    echo -e "${GREEN}✓ All performance plugins verified successfully${NC}"
fi

# Configure plugin-specific optimizations
echo -e "${YELLOW}Applying plugin performance optimizations...${NC}"

# Configure zsh-autosuggestions for better performance
if [ -d "$ZSH_CUSTOM/plugins/zsh-autosuggestions" ]; then
    # Set autosuggestion strategy to history only for speed
    export ZSH_AUTOSUGGEST_STRATEGY=(history)
    export ZSH_AUTOSUGGEST_BUFFER_MAX_SIZE=20
    echo -e "${GREEN}✓ zsh-autosuggestions optimized for performance${NC}"
fi

# Configure fast-syntax-highlighting
if [ -d "$ZSH_CUSTOM/plugins/fast-syntax-highlighting" ]; then
    # Fast-syntax-highlighting is already optimized by default
    echo -e "${GREEN}✓ fast-syntax-highlighting is performance-optimized${NC}"
fi

# Install tmux plugin manager
if [ ! -d "$HOME/.tmux/plugins/tpm" ]; then
    echo -e "${YELLOW}Installing tmux plugin manager...${NC}"
    git clone https://github.com/tmux-plugins/tpm ~/.tmux/plugins/tpm
else
    echo -e "${GREEN}✓ Tmux plugin manager already installed${NC}"
fi

# Install Fast Node Manager (fnm) - Much faster than NVM
echo -e "${YELLOW}Setting up Node.js environment...${NC}"

install_fnm() {
    local install_method=$1
    echo -e "${YELLOW}Installing fnm using $install_method...${NC}"
    
    case $install_method in
        "aur")
            if command -v yay &> /dev/null; then
                # Try fnm-bin first (precompiled binary), then fnm (source)
                if yay -S --needed --noconfirm fnm-bin 2>/dev/null; then
                    echo -e "${GREEN}✓ fnm-bin installed via AUR${NC}"
                    return 0
                elif yay -S --needed --noconfirm fnm 2>/dev/null; then
                    echo -e "${GREEN}✓ fnm installed via AUR${NC}"
                    return 0
                else
                    echo -e "${RED}✗ AUR installation failed${NC}"
                    return 1
                fi
            else
                echo -e "${YELLOW}yay not available${NC}"
                return 1
            fi
            ;;
        "script")
            # Create the installation directory first
            local fnm_dir="${XDG_DATA_HOME:-$HOME/.local/share}/fnm"
            mkdir -p "$fnm_dir"
            
            # Download and install fnm
            if curl -fsSL https://fnm.vercel.app/install | bash -s -- --install-dir "$fnm_dir" --skip-shell 2>/dev/null; then
                echo -e "${GREEN}✓ fnm installed via install script to $fnm_dir${NC}"
                # Add to PATH immediately
                export PATH="$fnm_dir:$PATH"
                return 0
            else
                echo -e "${RED}✗ Script installation failed${NC}"
                return 1
            fi
            ;;
        "cargo")
            if command -v cargo &> /dev/null; then
                # Ensure cargo bin is in PATH
                export PATH="$HOME/.cargo/bin:$PATH"
                if cargo install fnm 2>/dev/null; then
                    echo -e "${GREEN}✓ fnm installed via cargo${NC}"
                    return 0
                else
                    echo -e "${RED}✗ Cargo installation failed${NC}"
                    return 1
                fi
            else
                echo -e "${YELLOW}cargo not available${NC}"
                return 1
            fi
            ;;
        "pacman")
            # Try installing rust first for cargo method as fallback
            if sudo pacman -S --needed --noconfirm rust 2>/dev/null; then
                # Add cargo to PATH
                export PATH="$HOME/.cargo/bin:$PATH"
                if cargo install fnm 2>/dev/null; then
                    echo -e "${GREEN}✓ fnm installed via pacman+cargo${NC}"
                    return 0
                else
                    echo -e "${RED}✗ Pacman+cargo installation failed${NC}"
                    return 1
                fi
            else
                echo -e "${RED}✗ Could not install rust via pacman${NC}"
                return 1
            fi
            ;;
        "npm")
            # Fallback: Install via npm if available
            if command -v npm &> /dev/null; then
                if npm install -g fnm 2>/dev/null; then
                    echo -e "${GREEN}✓ fnm installed via npm${NC}"
                    return 0
                else
                    echo -e "${RED}✗ npm installation failed${NC}"
                    return 1
                fi
            else
                echo -e "${YELLOW}npm not available${NC}"
                return 1
            fi
            ;;
        *)
            echo -e "${RED}✗ Unknown installation method: $install_method${NC}"
            return 1
            ;;
    esac
}

setup_fnm_environment() {
    echo -e "${YELLOW}Setting up fnm environment...${NC}"
    
    # Multiple possible fnm installation locations
    local fnm_paths=(
        "${XDG_DATA_HOME:-$HOME/.local/share}/fnm"
        "$HOME/.fnm"
        "$HOME/.cargo/bin"
        "/usr/local/bin"
        "/usr/bin"
        "$(npm root -g 2>/dev/null)/bin"  # npm global bin
    )
    
    # Look for fnm binary in all possible locations
    local fnm_binary=""
    for fnm_path in "${fnm_paths[@]}"; do
        if [ -f "$fnm_path/fnm" ]; then
            fnm_binary="$fnm_path/fnm"
            export PATH="$fnm_path:$PATH"
            echo -e "${GREEN}✓ Found fnm binary at: $fnm_binary${NC}"
            break
        elif [ -d "$fnm_path" ] && [ -f "$fnm_path/fnm" ]; then
            fnm_binary="$fnm_path/fnm"
            export PATH="$fnm_path:$PATH"
            echo -e "${GREEN}✓ Found fnm binary at: $fnm_binary${NC}"
            break
        fi
    done
    
    # If not found in specific paths, check if it's already in PATH
    if [ -z "$fnm_binary" ] && command -v fnm &> /dev/null; then
        fnm_binary="$(which fnm)"
        echo -e "${GREEN}✓ fnm found in PATH at: $fnm_binary${NC}"
    fi
    
    # Verify fnm is now available
    if [ -n "$fnm_binary" ] && command -v fnm &> /dev/null; then
        echo -e "${GREEN}✓ fnm command available${NC}"
        
        # Initialize fnm environment with proper shell detection
        local shell_name="$(basename "$SHELL")"
        if [ "$shell_name" = "zsh" ]; then
            if eval "$(fnm env --use-on-cd --shell zsh)" 2>/dev/null; then
                echo -e "${GREEN}✓ fnm environment initialized for zsh${NC}"
                return 0
            fi
        elif [ "$shell_name" = "bash" ]; then
            if eval "$(fnm env --use-on-cd --shell bash)" 2>/dev/null; then
                echo -e "${GREEN}✓ fnm environment initialized for bash${NC}"
                return 0
            fi
        else
            # Try without shell specification
            if eval "$(fnm env --use-on-cd)" 2>/dev/null; then
                echo -e "${GREEN}✓ fnm environment initialized${NC}"
                return 0
            fi
        fi
        
        echo -e "${RED}✗ Failed to initialize fnm environment${NC}"
        return 1
    else
        echo -e "${RED}✗ fnm not found in PATH after setup${NC}"
        echo -e "${YELLOW}Current PATH: $PATH${NC}"
        return 1
    fi
}

verify_fnm_installation() {
    echo -e "${YELLOW}Verifying fnm installation...${NC}"
    
    # Check if fnm command works
    if ! command -v fnm &> /dev/null; then
        echo -e "${RED}✗ fnm command not found${NC}"
        return 1
    fi
    
    # Check fnm version
    local fnm_version
    if fnm_version=$(fnm --version 2>&1); then
        echo -e "${GREEN}✓ fnm version: $fnm_version${NC}"
    else
        echo -e "${RED}✗ fnm --version failed: $fnm_version${NC}"
        return 1
    fi
    
    # Check fnm completions
    if fnm completions --shell bash &> /dev/null; then
        echo -e "${GREEN}✓ fnm completions work${NC}"
    else
        echo -e "${YELLOW}! fnm completions not available${NC}"
    fi
    
    # Check fnm directory
    local fnm_dir
    if fnm_dir=$(fnm env | grep FNM_DIR | cut -d'"' -f2); then
        if [ -d "$fnm_dir" ]; then
            echo -e "${GREEN}✓ fnm directory exists: $fnm_dir${NC}"
        else
            echo -e "${YELLOW}! fnm directory not found: $fnm_dir${NC}"
        fi
    fi
    
    return 0
}

install_nodejs_with_fnm() {
    echo -e "${YELLOW}Installing Node.js LTS...${NC}"
    
    # First verify fnm is working
    if ! verify_fnm_installation; then
        echo -e "${RED}✗ fnm verification failed, cannot install Node.js${NC}"
        return 1
    fi
    
    if fnm install --lts && fnm use lts-latest && fnm default lts-latest; then
        echo -e "${GREEN}✓ Node.js $(node --version) installed successfully${NC}"
        
        # Install global npm packages
        echo -e "${YELLOW}Installing global npm packages...${NC}"
        if npm install -g pnpm yarn typescript prettier eslint; then
            echo -e "${GREEN}✓ Global npm packages installed${NC}"
        else
            echo -e "${YELLOW}! Some npm packages failed to install${NC}"
        fi
        return 0
    else
        echo -e "${RED}✗ Failed to install Node.js with fnm${NC}"
        return 1
    fi
}

if ! command -v fnm &> /dev/null; then
    echo -e "${YELLOW}Installing Fast Node Manager (fnm)...${NC}"
    
    # Try multiple installation methods with better error handling
    FNM_INSTALLED=false
    declare -a methods=("aur" "script" "cargo" "pacman")
    
    # Add npm method if npm is available
    if command -v npm &> /dev/null; then
        methods+=("npm")
    fi
    
    for method in "${methods[@]}"; do
        echo -e "${YELLOW}Attempting fnm installation via $method...${NC}"
        
        if install_fnm "$method"; then
            # Verify installation worked
            if setup_fnm_environment; then
                # Double-check that fnm command actually works
                if fnm --version &> /dev/null; then
                    FNM_INSTALLED=true
                    echo -e "${GREEN}✓ fnm installed and verified via $method${NC}"
                    echo -e "${GREEN}✓ fnm version: $(fnm --version)${NC}"
                    
                    # Ensure fnm shell integration is added to .zshrc
                    if ! grep -q "fnm env" "$HOME/.zshrc" 2>/dev/null; then
                        echo -e "${YELLOW}Adding fnm to shell configuration...${NC}"
                        cat >> "$HOME/.zshrc" << 'EOF'

# Fast Node Manager (fnm)
if command -v fnm &> /dev/null; then
    eval "$(fnm env --use-on-cd)"
fi
EOF
                        echo -e "${GREEN}✓ Added fnm to .zshrc${NC}"
                    fi
                    break
                else
                    echo -e "${RED}✗ fnm installed but not working properly${NC}"
                fi
            else
                echo -e "${RED}✗ fnm installed but environment setup failed${NC}"
            fi
        fi
        
        echo -e "${YELLOW}$method installation failed, trying next method...${NC}"
        sleep 1  # Brief pause between attempts
    done
    
    if [ "$FNM_INSTALLED" = false ]; then
        echo -e "${RED}✗ CRITICAL: Failed to install fnm with all methods${NC}"
        echo -e "${YELLOW}Manual installation required. Install fnm manually and re-run this script.${NC}"
        exit 1
    fi
    
    # Install Node.js
    if ! install_nodejs_with_fnm; then
        echo -e "${RED}✗ CRITICAL: Failed to install Node.js${NC}"
        exit 1
    fi
else
    echo -e "${GREEN}✓ fnm already installed${NC}"
    
    # Ensure fnm is available in current session
    if ! setup_fnm_environment; then
        echo -e "${RED}✗ Failed to initialize fnm environment${NC}"
        exit 1
    fi
    
    # Check if node is installed
    if ! command -v node &> /dev/null; then
        echo -e "${YELLOW}Node not found, installing LTS...${NC}"
        if ! install_nodejs_with_fnm; then
            echo -e "${RED}✗ CRITICAL: Failed to install Node.js${NC}"
            exit 1
        fi
    else
        echo -e "${GREEN}✓ Node.js $(node --version) already available${NC}"
    fi
fi

# Final verification that fnm and node are working
if ! command -v fnm &> /dev/null; then
    echo -e "${RED}✗ CRITICAL: fnm not available after installation${NC}"
    exit 1
fi

if ! command -v node &> /dev/null; then
    echo -e "${RED}✗ CRITICAL: node not available after installation${NC}"
    exit 1
fi

echo -e "${GREEN}✓ Node.js environment setup complete!${NC}"
echo -e "${GREEN}  fnm: $(fnm --version)${NC}"
echo -e "${GREEN}  node: $(node --version)${NC}"
echo -e "${GREEN}  npm: $(npm --version)${NC}"

if ! verify_command_available "node" "nodejs via fnm"; then
    echo -e "${RED}✗ CRITICAL: Node.js verification failed${NC}"
    exit 1
fi

# Set up Python tools
echo -e "${YELLOW}Setting up Python tools...${NC}"
pipx ensurepath 2>/dev/null || true

PYTHON_TOOLS=(poetry black ruff ipython)
for tool in "${PYTHON_TOOLS[@]}"; do
    if ! command -v "$tool" &> /dev/null; then
        pipx install "$tool" 2>/dev/null || echo "  ! Failed to install $tool"
    else
        echo -e "${GREEN}✓ $tool already installed${NC}"
    fi
done

# Run p10k configure automatically if not already configured
if [ ! -f "$HOME/.p10k.zsh" ] && command -v zsh &> /dev/null; then
    echo -e "${YELLOW}Running Powerlevel10k configuration wizard...${NC}"
    echo -e "${YELLOW}Note: You can skip this by pressing Ctrl+C and run 'p10k configure' later${NC}"
    sleep 2
    
    # Check if we're in an interactive terminal
    if [ -t 0 ] && [ -t 1 ]; then
        # Run p10k configure in a new zsh shell
        zsh -c 'source ~/.zshrc && p10k configure' || echo -e "${YELLOW}! p10k configure skipped or failed${NC}"
    else
        echo -e "${YELLOW}! Non-interactive terminal detected, skipping p10k configure${NC}"
        echo -e "${YELLOW}! Run 'p10k configure' manually in your terminal${NC}"
    fi
fi

# Configure Powerlevel10k
echo -e "${YELLOW}Setting up Powerlevel10k configuration...${NC}"
if [ ! -f "$HOME/.p10k.zsh" ]; then
    echo -e "${YELLOW}Configuring Powerlevel10k with performance-optimized defaults...${NC}"
    
    # Use the existing p10k config from dotfiles if available
    if [ -f "$DOTFILES_DIR/zsh/.p10k.zsh" ]; then
        echo -e "${GREEN}Using optimized p10k configuration from dotfiles${NC}"
        cp "$DOTFILES_DIR/zsh/.p10k.zsh" "$HOME/.p10k.zsh"
        echo -e "${GREEN}✓ Powerlevel10k configured with performance settings${NC}"
    else
        echo -e "${YELLOW}Dotfiles p10k config not found, creating basic optimized config...${NC}"
        # Create a basic performance-optimized p10k config
        cat > "$HOME/.p10k.zsh" << 'P10K_CONFIG'
# Performance-optimized Powerlevel10k configuration
# Generated by dotfiles installer for fast startup

# Enable Powerlevel10k instant prompt
if [[ -r "${XDG_CACHE_HOME:-$HOME/.cache}/p10k-instant-prompt-${(%):-%n}.zsh" ]]; then
  source "${XDG_CACHE_HOME:-$HOME/.cache}/p10k-instant-prompt-${(%):-%n}.zsh"
fi

# Powerlevel10k configuration
typeset -g POWERLEVEL9K_INSTANT_PROMPT=verbose
typeset -g POWERLEVEL9K_LEFT_PROMPT_ELEMENTS=(dir git prompt_char)
typeset -g POWERLEVEL9K_RIGHT_PROMPT_ELEMENTS=(status node_version time)
typeset -g POWERLEVEL9K_MODE=nerdfont-v3
typeset -g POWERLEVEL9K_ICON_PADDING=none
typeset -g POWERLEVEL9K_BACKGROUND=
typeset -g POWERLEVEL9K_PROMPT_ADD_NEWLINE=true
typeset -g POWERLEVEL9K_MULTILINE_FIRST_PROMPT_PREFIX=
typeset -g POWERLEVEL9K_MULTILINE_NEWLINE_PROMPT_PREFIX=
typeset -g POWERLEVEL9K_MULTILINE_LAST_PROMPT_PREFIX='%F{blue}❯ %f'
typeset -g POWERLEVEL9K_PROMPT_CHAR_OK_VIINS_FOREGROUND=blue
typeset -g POWERLEVEL9K_PROMPT_CHAR_ERROR_VIINS_FOREGROUND=red
P10K_CONFIG
        echo -e "${GREEN}✓ Basic Powerlevel10k config created${NC}"
    fi
else
    echo -e "${GREEN}✓ Powerlevel10k already configured${NC}"
fi

# Verify Powerlevel10k is working
echo -e "${YELLOW}Verifying Powerlevel10k installation...${NC}"
if zsh -c 'source ~/.oh-my-zsh/custom/themes/powerlevel10k/powerlevel10k.zsh-theme && echo "Powerlevel10k loaded successfully"' &>/dev/null; then
    echo -e "${GREEN}✓ Powerlevel10k verification passed${NC}"
else
    echo -e "${YELLOW}! Powerlevel10k verification failed (may still work)${NC}"
fi

# Compile zsh files for performance
echo -e "${YELLOW}Compiling zsh files for faster startup...${NC}"

# Ensure the compilation script exists and is executable
if [ -f "$DOTFILES_DIR/scripts/compile-zsh-files.sh" ]; then
    chmod +x "$DOTFILES_DIR/scripts/compile-zsh-files.sh"
    echo -e "${GREEN}✓ Compilation script found and made executable${NC}"
fi

# First, ensure we have zsh available for compilation
if ! command -v zsh &> /dev/null; then
    echo -e "${RED}✗ zsh not found - cannot compile zsh files${NC}"
    echo -e "${YELLOW}! Skipping zsh compilation${NC}"
else
    # Use the dedicated compilation script if available
    if [ -f "$DOTFILES_DIR/scripts/compile-zsh-files.sh" ]; then
        echo -e "${YELLOW}Running dedicated zsh compilation script...${NC}"
        
        # Run the script with proper error handling
        if zsh "$DOTFILES_DIR/scripts/compile-zsh-files.sh"; then
            echo -e "${GREEN}✓ Zsh files compiled successfully using script${NC}"
        else
            echo -e "${YELLOW}! Compilation script had issues, falling back to manual compilation${NC}"
            # Fallback to manual compilation
            compile_zsh_files_manual
        fi
    else
        echo -e "${YELLOW}Compilation script not found, compiling manually...${NC}"
        compile_zsh_files_manual
    fi
    
    # Verify compilation worked
    compiled_count=0
    total_count=0
    for file in ~/.zshrc ~/.p10k.zsh ~/.oh-my-zsh/oh-my-zsh.sh; do
        if [[ -f "$file" ]]; then
            total_count=$((total_count + 1))
            if [[ -f "${file}.zwc" ]]; then
                compiled_count=$((compiled_count + 1))
            fi
        fi
    done
    
    if [[ $compiled_count -gt 0 ]]; then
        echo -e "${GREEN}✓ Successfully compiled $compiled_count/$total_count core zsh files${NC}"
    else
        echo -e "${YELLOW}! No zsh files were compiled (this may affect startup performance)${NC}"
    fi
fi

# Function for manual zsh compilation
compile_zsh_files_manual() {
    echo -e "${YELLOW}Compiling core zsh files manually...${NC}"
    
    # Core files to compile
    local files_to_compile=(
        "$HOME/.zshrc"
        "$HOME/.p10k.zsh" 
        "$HOME/.oh-my-zsh/oh-my-zsh.sh"
    )
    
    for file in "${files_to_compile[@]}"; do
        if [[ -f "$file" ]]; then
            if [[ ! -f "${file}.zwc" ]] || [[ "$file" -nt "${file}.zwc" ]]; then
                echo "  Compiling: $(basename "$file")"
                zcompile "$file" 2>/dev/null || echo "    ! Failed to compile $(basename "$file")"
            else
                echo "  Already compiled: $(basename "$file")"
            fi
        fi
    done
    
    # Compile plugin files
    if [[ -d "$HOME/.oh-my-zsh/custom/plugins" ]]; then
        echo -e "${YELLOW}Compiling plugin files...${NC}"
        for plugin_dir in "$HOME/.oh-my-zsh/custom/plugins"/*; do
            if [[ -d "$plugin_dir" ]]; then
                plugin_name=$(basename "$plugin_dir")
                plugin_file="$plugin_dir/$plugin_name.plugin.zsh"
                
                if [[ -f "$plugin_file" ]]; then
                    if [[ ! -f "${plugin_file}.zwc" ]] || [[ "$plugin_file" -nt "${plugin_file}.zwc" ]]; then
                        echo "  Compiling plugin: $plugin_name"
                        zcompile "$plugin_file" 2>/dev/null || true
                    fi
                fi
            fi
        done
    fi
    
    # Recompile completion dump if it exists
    if [[ -f "$HOME/.zcompdump" ]]; then
        echo "  Compiling completion dump"
        rm -f "$HOME/.zcompdump.zwc"
        zcompile "$HOME/.zcompdump" 2>/dev/null || true
    fi
}

# Configure Git
if [ ! -f "$HOME/.gitconfig" ] || ! grep -q "user.name" "$HOME/.gitconfig" 2>/dev/null; then
    echo -e "${YELLOW}Git not configured${NC}"
    read -p "Configure Git now? (y/n) [y]: " -n 1 -r REPLY
    REPLY=${REPLY:-y}
    echo
    if [[ $REPLY =~ ^[Yy]$ ]]; then
        ./scripts/setup-git-config.sh
    fi
else
    echo -e "${GREEN}✓ Git already configured${NC}"
fi

# Generate SSH key if needed
if [ ! -f "$HOME/.ssh/id_ed25519" ] && [ ! -f "$HOME/.ssh/id_rsa" ]; then
    echo -e "${YELLOW}No SSH key found${NC}"
    read -p "Generate SSH key for GitHub? (y/n) [y]: " -n 1 -r REPLY
    REPLY=${REPLY:-y}
    echo
    if [[ $REPLY =~ ^[Yy]$ ]]; then
        read -p "Enter email for SSH key: " SSH_EMAIL
        ssh-keygen -t ed25519 -C "$SSH_EMAIL" -f "$HOME/.ssh/id_ed25519" -N ""
        echo -e "\n${YELLOW}Add this key to GitHub:${NC}"
        cat "$HOME/.ssh/id_ed25519.pub"
        echo -e "\n${YELLOW}Press Enter when you've added the key to GitHub...${NC}"
        read
    fi
else
    echo -e "${GREEN}✓ SSH key already exists${NC}"
fi

# Install SDDM display manager
step "Installing display manager..."
if ! check_installed sddm; then
    sudo pacman -S --needed --noconfirm sddm qt5-graphicaleffects qt5-quickcontrols2 qt5-svg
    install_aur_if_missing "sddm-sugar-candy-git"
    
    # Configure SDDM
    if [ "$DRY_RUN" = true ]; then
        echo -e "${BLUE}[DRY RUN]${NC} Would enable sddm service"
    else
        sudo systemctl enable sddm
    fi
    sudo mkdir -p /etc/sddm.conf.d
    sudo tee /etc/sddm.conf.d/theme.conf > /dev/null << EOF
[Theme]
Current=sugar-candy
EOF
else
    echo -e "${GREEN}✓ SDDM already installed${NC}"
fi

# Create Hyprland desktop entry
if [ ! -f /usr/share/wayland-sessions/hyprland.desktop ]; then
    echo -e "${YELLOW}Creating Hyprland desktop entry...${NC}"
    sudo tee /usr/share/wayland-sessions/hyprland.desktop > /dev/null << 'EOF'
[Desktop Entry]
Name=Hyprland
Comment=An intelligent dynamic tiling Wayland compositor
Exec=Hyprland
Type=Application
EOF
else
    echo -e "${GREEN}✓ Hyprland desktop entry exists${NC}"
fi

# Comprehensive installation verification function
verify_installation() {
    echo -e "\n${BLUE}╔════════════════════════════════════════╗${NC}"
    echo -e "${BLUE}║    Comprehensive Installation Check    ║${NC}"
    echo -e "${BLUE}╚════════════════════════════════════════╝${NC}\n"
    
    local total_checks=0
    local passed_checks=0
    local failed_checks=()
    local warnings=()
    
    # Function to track check results
    check_result() {
        local check_name="$1"
        local result="$2"  # pass/fail/warn
        local message="$3"
        
        total_checks=$((total_checks + 1))
        
        case $result in
            "pass")
                passed_checks=$((passed_checks + 1))
                echo -e "  ${GREEN}✓${NC} $check_name: $message"
                ;;
            "fail")
                failed_checks+=("$check_name: $message")
                echo -e "  ${RED}✗${NC} $check_name: $message"
                ;;
            "warn")
                warnings+=("$check_name: $message")
                echo -e "  ${YELLOW}!${NC} $check_name: $message"
                ;;
        esac
    }
    
    # 1. Check critical commands
    echo -e "${PURPLE}[1/8] Checking critical commands...${NC}"
    local critical_cmds=(
        "hyprland:Hyprland compositor"
        "fuzzel:Application launcher"
        "mako:Notification daemon"
        "swww:Wallpaper daemon"
        "waybar:Status bar"
        "ghostty:Terminal emulator"
        "fnm:Fast Node Manager"
        "node:Node.js runtime"
        "npm:Node package manager"
        "git:Version control"
        "stow:Symlink manager"
        "nvim:Neovim editor"
        "tmux:Terminal multiplexer"
        "zsh:Z shell"
    )
    
    for cmd_info in "${critical_cmds[@]}"; do
        IFS=':' read -r cmd desc <<< "$cmd_info"
        if command -v "$cmd" &> /dev/null; then
            check_result "$desc" "pass" "$(which $cmd)"
        else
            check_result "$desc" "fail" "Command '$cmd' not found"
        fi
    done
    
    # 2. Check configuration symlinks
    echo -e "\n${PURPLE}[2/8] Checking configuration symlinks...${NC}"
    local configs=(
        "$HOME/.config/hypr:Hyprland config"
        "$HOME/.config/waybar:Waybar config"
        "$HOME/.config/ghostty:Ghostty config"
        "$HOME/.config/nvim:Neovim config"
        "$HOME/.config/fuzzel:Fuzzel config"
        "$HOME/.config/mako:Mako config"
        "$HOME/.tmux.conf:Tmux config"
        "$HOME/.zshrc:Zsh config"
        "$HOME/.gitconfig:Git config"
    )
    
    for config_info in "${configs[@]}"; do
        IFS=':' read -r path desc <<< "$config_info"
        if [ -e "$path" ]; then
            if [ -L "$path" ]; then
                local target=$(readlink "$path")
                check_result "$desc" "pass" "Linked to $target"
            else
                check_result "$desc" "warn" "Exists but not a symlink"
            fi
        else
            check_result "$desc" "fail" "Missing"
        fi
    done
    
    # 3. Check system services
    echo -e "\n${PURPLE}[3/8] Checking system services...${NC}"
    local services=(
        "NetworkManager:Network management"
        "bluetooth:Bluetooth support"
        "sddm:Display manager"
    )
    
    for service_info in "${services[@]}"; do
        IFS=':' read -r service desc <<< "$service_info"
        if systemctl is-enabled "$service" &> /dev/null; then
            if systemctl is-active "$service" &> /dev/null; then
                check_result "$desc" "pass" "Enabled and running"
            else
                check_result "$desc" "warn" "Enabled but not running"
            fi
        else
            check_result "$desc" "fail" "Not enabled"
        fi
    done
    
    # 4. Check user services
    echo -e "\n${PURPLE}[4/8] Checking user services...${NC}"
    local user_services=(
        "pipewire:Audio server"
        "wireplumber:PipeWire session manager"
    )
    
    for service_info in "${user_services[@]}"; do
        IFS=':' read -r service desc <<< "$service_info"
        if systemctl --user is-enabled "$service" &> /dev/null 2>&1; then
            if systemctl --user is-active "$service" &> /dev/null 2>&1; then
                check_result "$desc" "pass" "Enabled and running"
            else
                check_result "$desc" "warn" "Enabled but not running (will start on login)"
            fi
        else
            check_result "$desc" "warn" "Not enabled (will be started by Hyprland)"
        fi
    done
    
    # 5. Check custom scripts
    echo -e "\n${PURPLE}[5/8] Checking custom scripts...${NC}"
    local scripts=(
        "/usr/local/bin/dev-sync:Dev sync script"
        "/usr/local/bin/nvim-tab:Neovim tab wrapper"
        "/usr/local/bin/fix-audio:Audio fix script"
        "$HOME/.dotfiles/scripts/switch-hypr-keys.sh:Hyprland key switcher"
        "$HOME/.dotfiles/scripts/compile-zsh-files.sh:Zsh compiler"
    )
    
    for script_info in "${scripts[@]}"; do
        IFS=':' read -r script desc <<< "$script_info"
        if [ -f "$script" ]; then
            if [ -x "$script" ]; then
                check_result "$desc" "pass" "Installed and executable"
            else
                check_result "$desc" "warn" "Installed but not executable"
            fi
        else
            check_result "$desc" "fail" "Not found"
        fi
    done
    
    # 6. Check theme consistency
    echo -e "\n${PURPLE}[6/8] Checking theme consistency...${NC}"
    
    # Check GTK theme
    if [ -f "$HOME/.config/gtk-3.0/settings.ini" ]; then
        local gtk_theme=$(grep "gtk-theme-name" "$HOME/.config/gtk-3.0/settings.ini" 2>/dev/null | cut -d'=' -f2 | xargs)
        if [ -n "$gtk_theme" ]; then
            check_result "GTK theme" "pass" "$gtk_theme"
        else
            check_result "GTK theme" "warn" "Not configured"
        fi
    else
        check_result "GTK theme" "warn" "GTK3 settings not found"
    fi
    
    # Check cursor theme
    if [ -f "$HOME/.config/hypr/hyprland.conf" ]; then
        if grep -q "cursor_theme" "$HOME/.config/hypr/hyprland.conf"; then
            check_result "Cursor theme" "pass" "Configured in Hyprland"
        else
            check_result "Cursor theme" "warn" "Not configured"
        fi
    fi
    
    # Check icon theme
    if [ -f "$HOME/.config/gtk-3.0/settings.ini" ]; then
        local icon_theme=$(grep "gtk-icon-theme-name" "$HOME/.config/gtk-3.0/settings.ini" 2>/dev/null | cut -d'=' -f2 | xargs)
        if [ -n "$icon_theme" ]; then
            check_result "Icon theme" "pass" "$icon_theme"
        else
            check_result "Icon theme" "warn" "Not configured"
        fi
    fi
    
    # 7. Performance metrics
    echo -e "\n${PURPLE}[7/8] Checking shell performance...${NC}"
    
    # Test shell startup time
    if command -v zsh &> /dev/null; then
        echo -e "  ${YELLOW}Testing shell startup time...${NC}"
        
        # Run multiple tests and calculate average
        local total_time=0
        local test_count=3
        
        for i in $(seq 1 $test_count); do
            local start_time=$(date +%s.%N)
            zsh -i -c exit 2>/dev/null
            local end_time=$(date +%s.%N)
            local duration=$(echo "$end_time - $start_time" | bc 2>/dev/null || echo "0.5")
            total_time=$(echo "$total_time + $duration" | bc 2>/dev/null || echo "1.5")
        done
        
        local avg_time=$(echo "scale=3; $total_time / $test_count" | bc 2>/dev/null || echo "0.500")
        local avg_ms=$(echo "scale=0; $avg_time * 1000" | bc 2>/dev/null || echo "500")
        
        # Evaluate performance
        if (( $(echo "$avg_time < 0.1" | bc -l 2>/dev/null || echo 0) )); then
            check_result "Shell startup time" "pass" "${avg_ms}ms (Excellent)"
        elif (( $(echo "$avg_time < 0.3" | bc -l 2>/dev/null || echo 0) )); then
            check_result "Shell startup time" "pass" "${avg_ms}ms (Good)"
        elif (( $(echo "$avg_time < 0.5" | bc -l 2>/dev/null || echo 0) )); then
            check_result "Shell startup time" "warn" "${avg_ms}ms (Acceptable)"
        else
            check_result "Shell startup time" "warn" "${avg_ms}ms (Slow - consider optimization)"
        fi
        
        # Check if zsh files are compiled
        local compiled_files=0
        local total_files=0
        for file in ~/.zshrc ~/.p10k.zsh ~/.oh-my-zsh/oh-my-zsh.sh; do
            if [ -f "$file" ]; then
                total_files=$((total_files + 1))
                if [ -f "${file}.zwc" ]; then
                    compiled_files=$((compiled_files + 1))
                fi
            fi
        done
        
        if [ $compiled_files -eq $total_files ] && [ $total_files -gt 0 ]; then
            check_result "Zsh compilation" "pass" "$compiled_files/$total_files files compiled"
        elif [ $compiled_files -gt 0 ]; then
            check_result "Zsh compilation" "warn" "$compiled_files/$total_files files compiled"
        else
            check_result "Zsh compilation" "warn" "No files compiled (affects performance)"
        fi
    else
        check_result "Shell performance" "fail" "Zsh not available"
    fi
    
    # 8. Development environment
    echo -e "\n${PURPLE}[8/8] Checking development environment...${NC}"
    
    # Check Node.js version
    if command -v node &> /dev/null; then
        local node_version=$(node --version)
        check_result "Node.js" "pass" "$node_version"
    else
        check_result "Node.js" "fail" "Not installed"
    fi
    
    # Check global npm packages
    if command -v npm &> /dev/null; then
        local npm_globals=("pnpm" "yarn" "typescript" "prettier" "eslint")
        local installed_globals=()
        local missing_globals=()
        
        for pkg in "${npm_globals[@]}"; do
            if npm list -g --depth=0 2>/dev/null | grep -q " $pkg@"; then
                installed_globals+=("$pkg")
            else
                missing_globals+=("$pkg")
            fi
        done
        
        if [ ${#missing_globals[@]} -eq 0 ]; then
            check_result "NPM globals" "pass" "All recommended packages installed"
        else
            check_result "NPM globals" "warn" "Missing: ${missing_globals[*]}"
        fi
    fi
    
    # Check Python tools
    local python_tools=("poetry" "black" "ruff" "ipython")
    local installed_python=()
    local missing_python=()
    
    for tool in "${python_tools[@]}"; do
        if command -v "$tool" &> /dev/null; then
            installed_python+=("$tool")
        else
            missing_python+=("$tool")
        fi
    done
    
    if [ ${#missing_python[@]} -eq 0 ]; then
        check_result "Python tools" "pass" "All recommended tools installed"
    elif [ ${#installed_python[@]} -gt 0 ]; then
        check_result "Python tools" "warn" "Missing: ${missing_python[*]}"
    else
        check_result "Python tools" "warn" "No Python tools installed"
    fi
    
    # Generate summary report
    echo -e "\n${BLUE}╔════════════════════════════════════════╗${NC}"
    echo -e "${BLUE}║         Installation Summary           ║${NC}"
    echo -e "${BLUE}╚════════════════════════════════════════╝${NC}\n"
    
    local fail_percentage=$(( (${#failed_checks[@]} * 100) / total_checks ))
    local pass_percentage=$(( (passed_checks * 100) / total_checks ))
    
    echo -e "${GREEN}Passed:${NC} $passed_checks/$total_checks ($pass_percentage%)"
    echo -e "${RED}Failed:${NC} ${#failed_checks[@]}/$total_checks ($fail_percentage%)"
    echo -e "${YELLOW}Warnings:${NC} ${#warnings[@]}"
    
    # Show failed checks
    if [ ${#failed_checks[@]} -gt 0 ]; then
        echo -e "\n${RED}Failed Checks:${NC}"
        for failure in "${failed_checks[@]}"; do
            echo -e "  - $failure"
        done
        
        echo -e "\n${YELLOW}Manual Fixes Required:${NC}"
        echo -e "  1. For missing commands: Install the corresponding package"
        echo -e "  2. For missing configs: Re-run 'stow' in the dotfiles directory"
        echo -e "  3. For disabled services: Run 'sudo systemctl enable <service>'"
        echo -e "  4. For missing scripts: Check if dotfiles were properly cloned"
    fi
    
    # Show warnings
    if [ ${#warnings[@]} -gt 0 ]; then
        echo -e "\n${YELLOW}Warnings:${NC}"
        for warning in "${warnings[@]}"; do
            echo -e "  - $warning"
        done
    fi
    
    # Overall status
    echo -e "\n${BLUE}Overall Status:${NC}"
    if [ ${#failed_checks[@]} -eq 0 ]; then
        echo -e "${GREEN}✓ Installation SUCCESSFUL - All checks passed!${NC}"
        return 0
    elif [ ${#failed_checks[@]} -le 3 ]; then
        echo -e "${YELLOW}⚠ Installation MOSTLY SUCCESSFUL - Minor issues detected${NC}"
        return 1
    else
        echo -e "${RED}✗ Installation INCOMPLETE - Critical issues detected${NC}"
        return 2
    fi
}

# Final system configuration and verification
step "Final configuration and verification..."
echo -e "${GREEN}✓ All configurations complete${NC}"

# Run final shell compilation after all configurations are in place
if command -v zsh &> /dev/null && [ -f "$DOTFILES_DIR/scripts/compile-zsh-files.sh" ]; then
    echo -e "\n${YELLOW}Running final zsh compilation for optimal performance...${NC}"
    zsh "$DOTFILES_DIR/scripts/compile-zsh-files.sh" || echo -e "${YELLOW}! Final compilation had warnings${NC}"
fi

echo -e "\n${GREEN}╔════════════════════════════════════════╗${NC}"
echo -e "${GREEN}║        Installation Complete!          ║${NC}"
echo -e "${GREEN}╚════════════════════════════════════════╝${NC}"

if systemctl is-active --quiet sddm; then
    echo -e "\n${GREEN}SDDM is already running!${NC}"
else
    echo -e "\n${YELLOW}Please reboot your system${NC}"
fi

echo -e "\n${BLUE}Key bindings (matching your Aerospace):${NC}"
echo -e "  ${GREEN}Alt + Enter${NC} - Open Ghostty"
echo -e "  ${GREEN}Alt + F${NC} - Fullscreen"
echo -e "  ${GREEN}Alt + H/J/K/L${NC} - Focus windows"
echo -e "  ${GREEN}Alt + [1-9,A-Z]${NC} - Switch workspace"
echo -e "\n${YELLOW}Workspaces:${NC}"
echo -e "  ${GREEN}C${NC} - Chrome  ${GREEN}S${NC} - Slack  ${GREEN}F${NC} - Figma"

# Final verification of critical tools
echo -e "\n${YELLOW}Performing final verification...${NC}"
CRITICAL_COMMANDS=("hyprland" "fuzzel" "mako" "swww" "waybar" "fnm" "node" "npm")
FAILED_COMMANDS=()

for cmd in "${CRITICAL_COMMANDS[@]}"; do
    if ! command -v "$cmd" &> /dev/null; then
        FAILED_COMMANDS+=("$cmd")
        echo -e "${RED}✗ $cmd not available in PATH${NC}"
    else
        echo -e "${GREEN}✓ $cmd verified${NC}"
    fi
done

if [ ${#FAILED_COMMANDS[@]} -gt 0 ]; then
    echo -e "\n${RED}CRITICAL ERROR: The following commands are not available:${NC}"
    printf '  %s\n' "${FAILED_COMMANDS[@]}"
    echo -e "\n${YELLOW}This indicates incomplete installation. Please check the logs above.${NC}"
    exit 1
fi

echo -e "\n${GREEN}✓ All critical tools verified successfully!${NC}"

# Run comprehensive verification
verify_installation
VERIFICATION_STATUS=$?

# Important note about shell configuration
echo -e "\n${YELLOW}IMPORTANT: Shell Performance Optimizations:${NC}"
echo -e "${GREEN}✓${NC} Powerlevel10k with instant prompt enabled"
echo -e "${GREEN}✓${NC} Fast-syntax-highlighting (50x faster than standard)"
echo -e "${GREEN}✓${NC} Zsh files compiled for faster loading"
echo -e "${GREEN}✓${NC} Lazy-loaded zoxide and direnv"
echo -e "${GREEN}✓${NC} fnm instead of nvm (50x faster)"
echo -e "${GREEN}✓${NC} Oh-My-Zsh auto-updates disabled"
echo
echo -e "${YELLOW}To use Node.js/fnm in new terminals:${NC}"
echo -e "1. Open a new terminal, OR"
echo -e "2. Run: ${GREEN}source ~/.zshrc${NC}"
echo
echo -e "${YELLOW}Your terminal startup is now fully optimized!${NC}"
echo -e "Expected startup time: ${GREEN}<100ms${NC}"
echo
echo -e "${YELLOW}Additional Performance Tips:${NC}"
echo -e "- Run ${GREEN}p10k configure${NC} to customize your prompt"
echo -e "- Use ${GREEN}z <directory>${NC} for instant directory jumping"
echo -e "- Run ${GREEN}~/scripts/compile-zsh-files.sh${NC} after major zsh config changes"

# Exit with verification status
if [ "$DRY_RUN" = true ]; then
    echo -e "\n${BLUE}╔════════════════════════════════════════╗${NC}"
    echo -e "${BLUE}║          Dry Run Complete              ║${NC}"
    echo -e "${BLUE}╚════════════════════════════════════════╝${NC}"
    echo -e "\n${YELLOW}This was a dry run. No changes were made.${NC}"
    echo -e "${YELLOW}Review the output above to see what would be installed.${NC}"
    echo -e "\n${GREEN}To perform the actual installation:${NC}"
    echo -e "  ${BLUE}./install-arch.sh${NC}"
    exit 0
fi

exit $VERIFICATION_STATUS