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

echo -e "${BLUE}╔════════════════════════════════════════╗${NC}"
echo -e "${BLUE}║     Arch Linux Environment Setup       ║${NC}"
echo -e "${BLUE}║        Hyprland + Ghostty              ║${NC}"
echo -e "${BLUE}╚════════════════════════════════════════╝${NC}"

# Request sudo upfront and keep it alive
echo -e "\n${YELLOW}This script needs sudo access. Please enter your password:${NC}"
sudo -v

# Keep sudo alive in the background
(while true; do sudo -n true; sleep 50; done 2>/dev/null) &
SUDO_PID=$!

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
    if ! check_installed "$package"; then
        echo -e "${YELLOW}Installing $package...${NC}"
        if sudo pacman -S --needed --noconfirm "$package"; then
            echo -e "${GREEN}✓ $package installed successfully${NC}"
        else
            echo -e "${RED}✗ Failed to install $package${NC}"
            return 1
        fi
    else
        echo -e "${GREEN}✓ $package already installed${NC}"
    fi
}

install_aur_if_missing() {
    local package=$1
    if ! check_aur_installed "$package"; then
        echo -e "${YELLOW}Installing $package from AUR...${NC}"
        if yay -S --needed --noconfirm "$package"; then
            echo -e "${GREEN}✓ $package installed successfully${NC}"
        else
            echo -e "${RED}✗ Failed to install $package${NC}"
            return 1
        fi
    else
        echo -e "${GREEN}✓ $package already installed${NC}"
    fi
}

# Critical package verification function
verify_critical_packages() {
    local failed_packages=()
    local critical_packages=("$@")
    
    echo -e "${YELLOW}Verifying critical packages...${NC}"
    for package in "${critical_packages[@]}"; do
        if ! check_installed "$package"; then
            failed_packages+=("$package")
            echo -e "${RED}✗ Critical package $package not installed${NC}"
        else
            echo -e "${GREEN}✓ $package verified${NC}"
        fi
    done
    
    if [ ${#failed_packages[@]} -gt 0 ]; then
        echo -e "${RED}CRITICAL ERROR: The following packages failed to install:${NC}"
        printf '  %s\n' "${failed_packages[@]}"
        echo -e "${YELLOW}Installation cannot continue without these packages.${NC}"
        return 1
    fi
    return 0
}

# PATH verification function
verify_command_available() {
    local command=$1
    local package=${2:-$1}
    
    if command -v "$command" &> /dev/null; then
        echo -e "${GREEN}✓ $command available in PATH${NC}"
        return 0
    else
        echo -e "${RED}✗ $command not found in PATH (package: $package)${NC}"
        return 1
    fi
}

# Progress counter
STEP=0
TOTAL_STEPS=13

step() {
    STEP=$((STEP + 1))
    echo -e "\n${PURPLE}[$STEP/$TOTAL_STEPS]${NC} $1"
}

# Install essential build tools
step "Checking essential build tools..."
ESSENTIALS=(base-devel git wget curl)
for pkg in "${ESSENTIALS[@]}"; do
    install_if_missing "$pkg"
done

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

# Install yay (AUR helper)
step "Installing AUR helper..."
if ! command -v yay &> /dev/null; then
    echo -e "${YELLOW}Installing yay...${NC}"
    TEMP_DIR=$(mktemp -d)
    git clone https://aur.archlinux.org/yay-bin.git "$TEMP_DIR/yay-bin"
    cd "$TEMP_DIR/yay-bin"
    makepkg -si --noconfirm
    cd -
    rm -rf "$TEMP_DIR"
else
    echo -e "${GREEN}✓ yay already installed${NC}"
fi

# Install base packages
step "Installing base packages..."
BASE_PACKAGES=(
    neovim neovim-remote tmux zsh stow
    wget curl unzip ripgrep fd fzf bat jq
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
            echo -e "${YELLOW}Failed packages: ${failed_packages[*]}${NC}"
        fi
    fi
fi

# Verify critical Hyprland packages are installed
CRITICAL_HYPRLAND=("hyprland" "fuzzel" "mako" "swww" "waybar" "pipewire" "wireplumber")
if ! verify_critical_packages "${CRITICAL_HYPRLAND[@]}"; then
    echo -e "${RED}CRITICAL ERROR: Essential Hyprland packages missing. Installation cannot continue.${NC}"
    exit 1
fi
echo -e "${GREEN}✓ Hyprland packages ready${NC}"

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
if [ "$1" == "--skip-aur" ]; then
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

# Use GNU Stow to symlink configs
echo -e "${YELLOW}Creating symlinks...${NC}"
for dir in hypr waybar ghostty nvim tmux zsh git dev; do
    if [ -d "$dir" ]; then
        # Special handling for dev directory (links to ~/dev)
        if [ "$dir" = "dev" ]; then
            if [ -L "$HOME/dev" ]; then
                echo -e "  ${GREEN}✓ $dir already linked${NC}"
            else
                stow -v "$dir" 2>/dev/null || echo -e "  ${YELLOW}! $dir stow failed (may already be linked)${NC}"
            fi
        else
            # Check if already stowed
            if [ -L "$HOME/.config/$dir" ] || [ -L "$HOME/.$(basename $dir)rc" ]; then
                echo -e "  ${GREEN}✓ $dir already linked${NC}"
            else
                stow -v "$dir" 2>/dev/null || echo -e "  ${YELLOW}! $dir stow failed (may already be linked)${NC}"
            fi
        fi
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

# Configure Hyprland to use Super key (Linux standard)
echo -e "${YELLOW}Configuring Hyprland keybindings...${NC}"
HYPR_CONFIG="$HOME/.config/hypr/hyprland.conf"
HYPR_SUPER="$HOME/.config/hypr/hyprland-super.conf"
HYPR_CURRENT="$HOME/.config/hypr/hyprland-current.conf"

if [ -f "$HYPR_CONFIG" ] && ! grep -q "mainMod = SUPER" "$HYPR_CONFIG" 2>/dev/null; then
    echo -e "${YELLOW}Current Hyprland config uses Alt (macOS-style) which conflicts with Linux apps${NC}"
    read -p "Switch to Super key (Linux standard)? (y/n) [y]: " -n 1 -r REPLY
    REPLY=${REPLY:-y}
    echo
    if [[ $REPLY =~ ^[Yy]$ ]]; then
        # Backup original Alt config
        if [ ! -L "$HYPR_CONFIG" ]; then
            cp "$HYPR_CONFIG" "$HYPR_CONFIG.alt-backup"
        fi
        
        # Use Super config
        if [ -f "$HYPR_SUPER" ]; then
            cp "$HYPR_SUPER" "$HYPR_CURRENT"
            rm -f "$HYPR_CONFIG"
            ln -s "hyprland-current.conf" "$HYPR_CONFIG"
            echo -e "${GREEN}✓ Switched to Super key (recommended)${NC}"
        else
            echo -e "${YELLOW}! Super config not found, keeping Alt${NC}"
        fi
    fi
elif [ -f "$HYPR_CONFIG" ]; then
    echo -e "${GREEN}✓ Hyprland already using Super key${NC}"
fi

# Change default shell to zsh
step "Setting up shell..."
if [ "$SHELL" != "$(which zsh)" ]; then
    echo -e "${YELLOW}Current shell: $SHELL${NC}"
    read -p "Change default shell to zsh? (y/n) [y]: " -n 1 -r REPLY
    REPLY=${REPLY:-y}
    echo
    if [[ $REPLY =~ ^[Yy]$ ]]; then
        chsh -s $(which zsh)
        echo -e "${GREEN}✓ Default shell changed to zsh${NC}"
    fi
else
    echo -e "${GREEN}✓ Already using zsh${NC}"
fi

# Enable services
echo -e "${YELLOW}Enabling services...${NC}"
systemctl --user enable pipewire 2>/dev/null || true
systemctl --user enable wireplumber 2>/dev/null || true
sudo systemctl enable bluetooth 2>/dev/null || true
sudo systemctl enable NetworkManager 2>/dev/null || true
echo -e "${GREEN}✓ Services enabled${NC}"

# Install Oh My Zsh
if [ ! -d "$HOME/.oh-my-zsh" ]; then
    echo -e "${YELLOW}Installing Oh My Zsh...${NC}"
    sh -c "$(curl -fsSL https://raw.githubusercontent.com/ohmyzsh/ohmyzsh/master/tools/install.sh)" "" --unattended
else
    echo -e "${GREEN}✓ Oh My Zsh already installed${NC}"
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

# Install performance-optimized plugins
if [ ! -d "$ZSH_CUSTOM/plugins/zsh-autosuggestions" ]; then
    echo -e "${YELLOW}Installing zsh-autosuggestions...${NC}"
    git clone https://github.com/zsh-users/zsh-autosuggestions "$ZSH_CUSTOM/plugins/zsh-autosuggestions"
else
    echo -e "${GREEN}✓ zsh-autosuggestions already installed${NC}"
fi

# Use fast-syntax-highlighting instead of zsh-syntax-highlighting for better performance
if [ ! -d "$ZSH_CUSTOM/plugins/fast-syntax-highlighting" ]; then
    echo -e "${YELLOW}Installing fast-syntax-highlighting (performance optimized)...${NC}"
    git clone https://github.com/zdharma-continuum/fast-syntax-highlighting.git "$ZSH_CUSTOM/plugins/fast-syntax-highlighting"
else
    echo -e "${GREEN}✓ fast-syntax-highlighting already installed${NC}"
fi

# Install zsh-autocomplete for better completion performance
if [ ! -d "$ZSH_CUSTOM/plugins/zsh-autocomplete" ]; then
    echo -e "${YELLOW}Installing zsh-autocomplete (performance optimized)...${NC}"
    git clone --depth 1 -- https://github.com/marlonrichert/zsh-autocomplete.git "$ZSH_CUSTOM/plugins/zsh-autocomplete"
else
    echo -e "${GREEN}✓ zsh-autocomplete already installed${NC}"
fi

# Remove old zsh-syntax-highlighting if it exists (replaced by fast-syntax-highlighting)
if [ -d "$ZSH_CUSTOM/plugins/zsh-syntax-highlighting" ]; then
    echo -e "${YELLOW}Removing old zsh-syntax-highlighting (replaced by fast version)...${NC}"
    rm -rf "$ZSH_CUSTOM/plugins/zsh-syntax-highlighting"
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
                yay -S --needed --noconfirm fnm-bin
            else
                return 1
            fi
            ;;
        "script")
            curl -fsSL https://fnm.vercel.app/install | bash -s -- --skip-shell
            ;;
        "cargo")
            if command -v cargo &> /dev/null; then
                cargo install fnm
            else
                return 1
            fi
            ;;
        *)
            return 1
            ;;
    esac
}

setup_fnm_environment() {
    # Add fnm to PATH for this session
    if [ -d "$HOME/.local/share/fnm" ]; then
        export PATH="$HOME/.local/share/fnm:$PATH"
    elif [ -d "$HOME/.fnm" ]; then
        export PATH="$HOME/.fnm:$PATH"
    elif [ -d "$HOME/.cargo/bin" ] && [ -f "$HOME/.cargo/bin/fnm" ]; then
        export PATH="$HOME/.cargo/bin:$PATH"
    fi
    
    # Initialize fnm if available
    if command -v fnm &> /dev/null; then
        eval "$(fnm env --use-on-cd)"
        return 0
    fi
    return 1
}

install_nodejs_with_fnm() {
    echo -e "${YELLOW}Installing Node.js LTS...${NC}"
    
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
    
    # Try multiple installation methods
    FNM_INSTALLED=false
    
    for method in "aur" "script" "cargo"; do
        if install_fnm "$method"; then
            if setup_fnm_environment; then
                FNM_INSTALLED=true
                echo -e "${GREEN}✓ fnm installed successfully via $method${NC}"
                break
            fi
        fi
        echo -e "${YELLOW}$method installation failed, trying next method...${NC}"
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

# Verify fnm and node are working
if ! verify_command_available "fnm" "fnm-bin"; then
    echo -e "${RED}✗ CRITICAL: fnm verification failed${NC}"
    exit 1
fi

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

# Configure Powerlevel10k
echo -e "${YELLOW}Setting up Powerlevel10k configuration...${NC}"
if [ ! -f "$HOME/.p10k.zsh" ]; then
    echo -e "${YELLOW}Powerlevel10k not configured yet${NC}"
    read -p "Configure Powerlevel10k with optimized defaults? (y/n) [y]: " -n 1 -r REPLY
    REPLY=${REPLY:-y}
    echo
    if [[ $REPLY =~ ^[Yy]$ ]]; then
        # Use the existing p10k config from dotfiles if available
        if [ -f "$DOTFILES_DIR/zsh/.p10k.zsh" ]; then
            echo -e "${GREEN}Using optimized p10k configuration from dotfiles${NC}"
            cp "$DOTFILES_DIR/zsh/.p10k.zsh" "$HOME/.p10k.zsh"
        else
            echo -e "${YELLOW}Running p10k configure with sensible defaults...${NC}"
            # Set up basic p10k config non-interactively
            zsh -c 'source ~/.oh-my-zsh/custom/themes/powerlevel10k/powerlevel10k.zsh-theme; p10k configure' || true
        fi
    fi
else
    echo -e "${GREEN}✓ Powerlevel10k already configured${NC}"
fi

# Compile zsh files for performance
echo -e "${YELLOW}Compiling zsh files for faster startup...${NC}"
if [ -f "$DOTFILES_DIR/scripts/compile-zsh-files.sh" ]; then
    # Make the script executable and run it
    chmod +x "$DOTFILES_DIR/scripts/compile-zsh-files.sh"
    zsh "$DOTFILES_DIR/scripts/compile-zsh-files.sh" || echo -e "${YELLOW}! Zsh compilation had some issues (non-critical)${NC}"
    echo -e "${GREEN}✓ Zsh files compiled for performance${NC}"
else
    echo -e "${YELLOW}! Zsh compilation script not found, compiling manually...${NC}"
    # Fallback compilation
    [[ -f ~/.zshrc ]] && zcompile ~/.zshrc || true
    [[ -f ~/.p10k.zsh ]] && zcompile ~/.p10k.zsh || true
    [[ -f ~/.oh-my-zsh/oh-my-zsh.sh ]] && zcompile ~/.oh-my-zsh/oh-my-zsh.sh || true
fi

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
    sudo systemctl enable sddm
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

# Final system configuration and verification
step "Final configuration and verification..."
echo -e "${GREEN}✓ All configurations complete${NC}"

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

# Important note about shell configuration
echo -e "\n${YELLOW}IMPORTANT: To use Node.js/fnm in new terminals:${NC}"
echo -e "1. Open a new terminal, OR"
echo -e "2. Run: ${GREEN}source ~/.zshrc${NC}"
echo
echo -e "${YELLOW}fnm is 50x faster than nvm!${NC}"
echo -e "Your terminal startup is now optimized."