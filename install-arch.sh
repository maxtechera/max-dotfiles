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
        sudo pacman -S --needed --noconfirm "$package"
    else
        echo -e "${GREEN}✓ $package already installed${NC}"
    fi
}

install_aur_if_missing() {
    local package=$1
    if ! check_aur_installed "$package"; then
        echo -e "${YELLOW}Installing $package from AUR...${NC}"
        yay -S --needed --noconfirm "$package"
    else
        echo -e "${GREEN}✓ $package already installed${NC}"
    fi
}

# Progress counter
STEP=0
TOTAL_STEPS=12

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
    wget curl unzip ripgrep fd fzf bat
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
    sudo pacman -S --needed --noconfirm "${PACKAGES_TO_INSTALL[@]}" 2>/dev/null || {
        echo -e "${YELLOW}Some packages failed, installing individually...${NC}"
        for pkg in "${PACKAGES_TO_INSTALL[@]}"; do
            sudo pacman -S --needed --noconfirm "$pkg" 2>/dev/null || echo "  ! $pkg not available"
        done
    }
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
    sudo pacman -S --needed --noconfirm "${PACKAGES_TO_INSTALL[@]}" 2>/dev/null || {
        echo -e "${YELLOW}Some packages failed, installing individually...${NC}"
        for pkg in "${PACKAGES_TO_INSTALL[@]}"; do
            sudo pacman -S --needed --noconfirm "$pkg" 2>/dev/null || echo "  ! $pkg not available"
        done
    }
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
    sudo pacman -S --needed --noconfirm "${PACKAGES_TO_INSTALL[@]}" 2>/dev/null || {
        echo -e "${YELLOW}Some packages failed, installing individually...${NC}"
        for pkg in "${PACKAGES_TO_INSTALL[@]}"; do
            sudo pacman -S --needed --noconfirm "$pkg" 2>/dev/null || echo "  ! $pkg not available"
        done
    }
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

# Handle existing configs
CONFIGS=(hypr waybar rofi ghostty nvim tmux zsh git)
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
for dir in hypr waybar rofi ghostty nvim tmux zsh git; do
    if [ -d "$dir" ]; then
        # Check if already stowed
        if [ -L "$HOME/.config/$dir" ] || [ -L "$HOME/.$(basename $dir)rc" ]; then
            echo -e "  ${GREEN}✓ $dir already linked${NC}"
        else
            stow -v "$dir" 2>/dev/null || echo -e "  ${YELLOW}! $dir stow failed (may already be linked)${NC}"
        fi
    fi
done

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

# Set up zsh plugins
echo -e "${YELLOW}Installing zsh plugins...${NC}"
ZSH_CUSTOM=${ZSH_CUSTOM:-~/.oh-my-zsh/custom}

if [ ! -d "$ZSH_CUSTOM/plugins/zsh-autosuggestions" ]; then
    git clone https://github.com/zsh-users/zsh-autosuggestions "$ZSH_CUSTOM/plugins/zsh-autosuggestions"
else
    echo -e "${GREEN}✓ zsh-autosuggestions already installed${NC}"
fi

if [ ! -d "$ZSH_CUSTOM/plugins/zsh-syntax-highlighting" ]; then
    git clone https://github.com/zsh-users/zsh-syntax-highlighting "$ZSH_CUSTOM/plugins/zsh-syntax-highlighting"
else
    echo -e "${GREEN}✓ zsh-syntax-highlighting already installed${NC}"
fi

# Install tmux plugin manager
if [ ! -d "$HOME/.tmux/plugins/tpm" ]; then
    echo -e "${YELLOW}Installing tmux plugin manager...${NC}"
    git clone https://github.com/tmux-plugins/tpm ~/.tmux/plugins/tpm
else
    echo -e "${GREEN}✓ Tmux plugin manager already installed${NC}"
fi

# Install NVM
if [ ! -d "$HOME/.nvm" ]; then
    echo -e "${YELLOW}Installing NVM...${NC}"
    curl -o- https://raw.githubusercontent.com/nvm-sh/nvm/v0.39.0/install.sh | bash
    
    # Source NVM immediately
    export NVM_DIR="$HOME/.nvm"
    [ -s "$NVM_DIR/nvm.sh" ] && \. "$NVM_DIR/nvm.sh"
    [ -s "$NVM_DIR/bash_completion" ] && \. "$NVM_DIR/bash_completion"
    
    echo -e "${YELLOW}Installing Node.js LTS...${NC}"
    nvm install --lts
    nvm use --lts
    nvm alias default node
    
    # Verify installation
    echo -e "${GREEN}✓ Node.js $(node --version) installed${NC}"
    
    # Install global npm packages
    echo -e "${YELLOW}Installing global npm packages...${NC}"
    npm install -g pnpm yarn typescript prettier eslint
else
    echo -e "${GREEN}✓ NVM already installed${NC}"
    # Source it anyway to ensure it's available
    export NVM_DIR="$HOME/.nvm"
    [ -s "$NVM_DIR/nvm.sh" ] && \. "$NVM_DIR/nvm.sh"
    
    # Check if node is installed
    if ! command -v node &> /dev/null; then
        echo -e "${YELLOW}Node not found, installing LTS...${NC}"
        nvm install --lts
        nvm use --lts
        nvm alias default node
    fi
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

# Final system configuration
step "Final configuration..."
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

# Important note about shell configuration
echo -e "\n${YELLOW}IMPORTANT: To use Node.js/NVM:${NC}"
echo -e "1. Open a new terminal, OR"
echo -e "2. Run: ${GREEN}source ~/.zshrc${NC}"
echo
echo -e "${YELLOW}If NVM/Node still not working:${NC}"
echo -e "Run: ${GREEN}./scripts/fix-nvm.sh${NC}"