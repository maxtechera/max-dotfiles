#!/bin/bash
# Modular Arch Linux Post-Install Setup
# Split into smaller, incremental steps for better control
# Each module can be run independently

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

# State file to track completed modules
STATE_FILE="$HOME/.arch-install-state"

# Initialize state file
[ ! -f "$STATE_FILE" ] && touch "$STATE_FILE"

# Helper functions
mark_complete() {
    echo "$1" >> "$STATE_FILE"
}

is_complete() {
    grep -q "^$1$" "$STATE_FILE" 2>/dev/null
}

check_installed() {
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

# Module definitions
declare -A MODULES=(
    ["01-essentials"]="Essential build tools (git, base-devel)"
    ["02-yay"]="AUR helper (yay)"
    ["03-shell"]="Zsh and Oh My Zsh setup"
    ["04-terminal"]="Ghostty terminal"
    ["05-cli-tools"]="CLI tools (neovim, tmux, ripgrep, etc)"
    ["06-modern-cli"]="Modern CLI replacements (eza, bat, zoxide)"
    ["07-development"]="Development tools (nvm, node, python)"
    ["08-gpu"]="GPU drivers detection and setup"
    ["09-hyprland-core"]="Hyprland compositor core"
    ["10-hyprland-utils"]="Hyprland utilities (waybar, rofi, etc)"
    ["11-fonts"]="System fonts"
    ["12-audio"]="Audio system (pipewire)"
    ["13-bluetooth"]="Bluetooth support"
    ["14-display-manager"]="SDDM login manager"
    ["15-dotfiles"]="Dotfiles installation"
    ["16-aur-essential"]="Essential AUR apps (VS Code, Spotify, Claude)"
    ["17-aur-optional"]="Optional AUR apps (Slack, Zoom, etc)"
    ["18-git-config"]="Git configuration"
    ["19-ssh-keys"]="SSH key generation"
    ["20-final-config"]="Final system configuration"
)

# Module order
MODULE_ORDER=(
    "01-essentials"
    "02-yay"
    "03-shell"
    "04-terminal"
    "05-cli-tools"
    "06-modern-cli"
    "07-development"
    "08-gpu"
    "09-hyprland-core"
    "10-hyprland-utils"
    "11-fonts"
    "12-audio"
    "13-bluetooth"
    "14-display-manager"
    "15-dotfiles"
    "16-aur-essential"
    "17-aur-optional"
    "18-git-config"
    "19-ssh-keys"
    "20-final-config"
)

# Show menu
show_menu() {
    echo -e "${BLUE}╔════════════════════════════════════════╗${NC}"
    echo -e "${BLUE}║     Modular Arch Linux Setup           ║${NC}"
    echo -e "${BLUE}╚════════════════════════════════════════╝${NC}"
    echo
    echo -e "${YELLOW}Select modules to install:${NC}"
    echo
    
    local i=1
    for module in "${MODULE_ORDER[@]}"; do
        if is_complete "$module"; then
            echo -e "  ${GREEN}✓${NC} $i. ${MODULES[$module]}"
        else
            echo -e "  ${RED}○${NC} $i. ${MODULES[$module]}"
        fi
        ((i++))
    done
    
    echo
    echo -e "${YELLOW}Options:${NC}"
    echo "  a. Install all remaining modules"
    echo "  n. Install next incomplete module"
    echo "  r. Reset progress and start over"
    echo "  q. Quit"
    echo
    echo -n "Enter choice (1-${#MODULE_ORDER[@]}/a/n/r/q): "
}

# Module implementations
run_01_essentials() {
    echo -e "${BLUE}Installing essential build tools...${NC}"
    
    # Request sudo upfront
    sudo -v
    
    ESSENTIALS=(base-devel git wget curl)
    for pkg in "${ESSENTIALS[@]}"; do
        install_if_missing "$pkg"
    done
    
    # System update
    echo -e "${YELLOW}Checking for system updates...${NC}"
    if [[ $(checkupdates 2>/dev/null | wc -l) -gt 0 ]]; then
        read -p "System updates available. Update now? (y/n) [y]: " -n 1 -r REPLY
        REPLY=${REPLY:-y}
        echo
        if [[ $REPLY =~ ^[Yy]$ ]]; then
            sudo pacman -Syu --noconfirm
        fi
    else
        echo -e "${GREEN}✓ System is up to date${NC}"
    fi
}

run_02_yay() {
    echo -e "${BLUE}Installing AUR helper (yay)...${NC}"
    
    if ! command -v yay &> /dev/null; then
        TEMP_DIR=$(mktemp -d)
        git clone https://aur.archlinux.org/yay-bin.git "$TEMP_DIR/yay-bin"
        cd "$TEMP_DIR/yay-bin"
        makepkg -si --noconfirm
        cd -
        rm -rf "$TEMP_DIR"
    else
        echo -e "${GREEN}✓ yay already installed${NC}"
    fi
}

run_03_shell() {
    echo -e "${BLUE}Setting up Zsh and Oh My Zsh...${NC}"
    
    install_if_missing "zsh"
    
    # Install Oh My Zsh
    if [ ! -d "$HOME/.oh-my-zsh" ]; then
        echo -e "${YELLOW}Installing Oh My Zsh...${NC}"
        sh -c "$(curl -fsSL https://raw.githubusercontent.com/ohmyzsh/ohmyzsh/master/tools/install.sh)" "" --unattended
    else
        echo -e "${GREEN}✓ Oh My Zsh already installed${NC}"
    fi
    
    # Install zsh plugins
    ZSH_CUSTOM=${ZSH_CUSTOM:-~/.oh-my-zsh/custom}
    
    if [ ! -d "$ZSH_CUSTOM/plugins/zsh-autosuggestions" ]; then
        git clone https://github.com/zsh-users/zsh-autosuggestions "$ZSH_CUSTOM/plugins/zsh-autosuggestions"
    fi
    
    if [ ! -d "$ZSH_CUSTOM/plugins/zsh-syntax-highlighting" ]; then
        git clone https://github.com/zsh-users/zsh-syntax-highlighting "$ZSH_CUSTOM/plugins/zsh-syntax-highlighting"
    fi
    
    # Install starship prompt
    install_if_missing "starship"
    
    # Change shell
    if [ "$SHELL" != "$(which zsh)" ]; then
        read -p "Change default shell to zsh? (y/n) [y]: " -n 1 -r REPLY
        REPLY=${REPLY:-y}
        echo
        if [[ $REPLY =~ ^[Yy]$ ]]; then
            chsh -s $(which zsh)
        fi
    fi
}

run_04_terminal() {
    echo -e "${BLUE}Installing Ghostty terminal...${NC}"
    install_if_missing "ghostty"
}

run_05_cli_tools() {
    echo -e "${BLUE}Installing CLI tools...${NC}"
    
    CLI_TOOLS=(
        neovim neovim-remote tmux stow
        wget curl unzip ripgrep fd fzf bat
        htop btop neofetch ranger lazygit
        github-cli jq man-db man-pages
        openssh tree ncdu duf tldr httpie glow
    )
    
    for tool in "${CLI_TOOLS[@]}"; do
        install_if_missing "$tool"
    done
    
    # Install tmux plugin manager
    if [ ! -d "$HOME/.tmux/plugins/tpm" ]; then
        echo -e "${YELLOW}Installing tmux plugin manager...${NC}"
        git clone https://github.com/tmux-plugins/tpm ~/.tmux/plugins/tpm
    fi
}

run_06_modern_cli() {
    echo -e "${BLUE}Installing modern CLI replacements...${NC}"
    
    MODERN_CLI=(eza zoxide direnv thefuck)
    for tool in "${MODERN_CLI[@]}"; do
        install_if_missing "$tool"
    done
}

run_07_development() {
    echo -e "${BLUE}Setting up development tools...${NC}"
    
    # Python
    install_if_missing "python"
    install_if_missing "python-pip"
    install_if_missing "python-pipx"
    
    # NVM and Node.js with immediate sourcing
    if [ ! -d "$HOME/.nvm" ]; then
        echo -e "${YELLOW}Installing NVM...${NC}"
        curl -o- https://raw.githubusercontent.com/nvm-sh/nvm/v0.39.0/install.sh | bash
        
        # Source NVM immediately in current shell
        export NVM_DIR="$HOME/.nvm"
        [ -s "$NVM_DIR/nvm.sh" ] && \. "$NVM_DIR/nvm.sh"
        [ -s "$NVM_DIR/bash_completion" ] && \. "$NVM_DIR/bash_completion"
        
        # Install Node LTS
        echo -e "${YELLOW}Installing Node.js LTS...${NC}"
        nvm install --lts
        nvm use --lts
        nvm alias default node
        
        # Install global packages
        npm install -g pnpm yarn typescript prettier eslint
        
        echo -e "${GREEN}✓ Node.js $(node --version) installed${NC}"
    else
        echo -e "${GREEN}✓ NVM already installed${NC}"
        
        # Ensure NVM is sourced and Node is installed
        export NVM_DIR="$HOME/.nvm"
        [ -s "$NVM_DIR/nvm.sh" ] && \. "$NVM_DIR/nvm.sh"
        
        if ! command -v node &> /dev/null; then
            echo -e "${YELLOW}Installing Node.js LTS...${NC}"
            nvm install --lts
            nvm use --lts
            nvm alias default node
            npm install -g pnpm yarn typescript prettier eslint
        fi
    fi
    
    # Python tools
    echo -e "${YELLOW}Installing Python tools...${NC}"
    pipx ensurepath 2>/dev/null || true
    
    PYTHON_TOOLS=(poetry black ruff ipython)
    for tool in "${PYTHON_TOOLS[@]}"; do
        if ! command -v "$tool" &> /dev/null; then
            pipx install "$tool" 2>/dev/null || echo "  ! Failed to install $tool"
        fi
    done
    
    echo -e "${YELLOW}Note: Run 'source ~/.zshrc' in new terminals to use NVM/Node${NC}"
}

run_08_gpu() {
    echo -e "${BLUE}Detecting and installing GPU drivers...${NC}"
    
    if lspci | grep -i nvidia > /dev/null; then
        echo -e "${GREEN}NVIDIA GPU detected${NC}"
        if ! check_installed nvidia; then
            read -p "Install NVIDIA drivers? (y/n) [y]: " -n 1 -r REPLY
            REPLY=${REPLY:-y}
            echo
            if [[ $REPLY =~ ^[Yy]$ ]]; then
                sudo pacman -S --needed --noconfirm nvidia nvidia-utils nvidia-settings
                echo "options nvidia-drm modeset=1" | sudo tee /etc/modprobe.d/nvidia.conf
            fi
        fi
    elif lspci | grep -i amd | grep -i vga > /dev/null; then
        echo -e "${GREEN}AMD GPU detected${NC}"
        AMD_PACKAGES=(mesa vulkan-radeon libva-mesa-driver)
        for pkg in "${AMD_PACKAGES[@]}"; do
            install_if_missing "$pkg"
        done
    elif lspci | grep -i intel | grep -i vga > /dev/null; then
        echo -e "${GREEN}Intel GPU detected${NC}"
        INTEL_PACKAGES=(mesa vulkan-intel intel-media-driver)
        for pkg in "${INTEL_PACKAGES[@]}"; do
            install_if_missing "$pkg"
        done
    fi
}

run_09_hyprland_core() {
    echo -e "${BLUE}Installing Hyprland core...${NC}"
    
    CORE_PACKAGES=(
        hyprland xdg-desktop-portal-hyprland
        qt5-wayland qt6-wayland xorg-xwayland
        polkit-kde-agent xdg-utils
    )
    
    for pkg in "${CORE_PACKAGES[@]}"; do
        install_if_missing "$pkg"
    done
}

run_10_hyprland_utils() {
    echo -e "${BLUE}Installing Hyprland utilities...${NC}"
    
    UTIL_PACKAGES=(
        waybar rofi-wayland swww mako
        grim slurp wl-clipboard swappy
        swaylock-effects wlogout hyprpicker
        pavucontrol brightnessctl playerctl pamixer
        thunar thunar-archive-plugin file-roller tumbler
        gvfs gvfs-mtp thunar-volman
        network-manager-applet
    )
    
    for pkg in "${UTIL_PACKAGES[@]}"; do
        install_if_missing "$pkg"
    done
}

run_11_fonts() {
    echo -e "${BLUE}Installing fonts...${NC}"
    
    FONT_PACKAGES=(
        ttf-jetbrains-mono-nerd ttf-font-awesome ttf-nerd-fonts-symbols
        noto-fonts noto-fonts-cjk noto-fonts-emoji ttf-firacode-nerd
        inter-font ttf-roboto ttf-ubuntu-font-family
    )
    
    for pkg in "${FONT_PACKAGES[@]}"; do
        install_if_missing "$pkg"
    done
}

run_12_audio() {
    echo -e "${BLUE}Installing audio system...${NC}"
    
    AUDIO_PACKAGES=(
        pipewire wireplumber pipewire-pulse
        pipewire-alsa pipewire-jack
    )
    
    for pkg in "${AUDIO_PACKAGES[@]}"; do
        install_if_missing "$pkg"
    done
    
    systemctl --user enable pipewire 2>/dev/null || true
    systemctl --user enable wireplumber 2>/dev/null || true
}

run_13_bluetooth() {
    echo -e "${BLUE}Installing Bluetooth support...${NC}"
    
    install_if_missing "bluez"
    install_if_missing "bluez-utils"
    install_if_missing "blueman"
    
    sudo systemctl enable bluetooth 2>/dev/null || true
}

run_14_display_manager() {
    echo -e "${BLUE}Installing SDDM display manager...${NC}"
    
    if ! check_installed sddm; then
        sudo pacman -S --needed --noconfirm sddm qt5-graphicaleffects qt5-quickcontrols2 qt5-svg
        
        # Install theme from AUR
        if command -v yay &> /dev/null; then
            yay -S --needed --noconfirm sddm-sugar-candy-git
        fi
        
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
}

run_15_dotfiles() {
    echo -e "${BLUE}Setting up dotfiles...${NC}"
    
    DOTFILES_DIR="$HOME/.dotfiles"
    
    # Setup dotfiles directory
    if [ -d "$DOTFILES_DIR" ]; then
        if [ "$(realpath "$DOTFILES_DIR")" != "$(realpath "$SCRIPT_DIR")" ]; then
            read -p "Replace existing dotfiles directory? (y/n) [n]: " -n 1 -r REPLY
            REPLY=${REPLY:-n}
            echo
            if [[ $REPLY =~ ^[Yy]$ ]]; then
                mv "$DOTFILES_DIR" "$DOTFILES_DIR.backup.$(date +%Y%m%d%H%M%S)"
                cp -r "$SCRIPT_DIR" "$DOTFILES_DIR"
            fi
        fi
    else
        cp -r "$SCRIPT_DIR" "$DOTFILES_DIR"
    fi
    
    cd "$DOTFILES_DIR"
    
    # Use GNU Stow
    for dir in hypr waybar rofi ghostty nvim tmux zsh git; do
        if [ -d "$dir" ]; then
            stow -v "$dir" 2>/dev/null || echo "  ! $dir stow failed"
        fi
    done
    
    # Install custom scripts
    for script in scripts/nvim-tab scripts/github-dev-sync.sh scripts/fix-arch-audio.sh scripts/fix-nvm.sh; do
        if [ -f "$script" ]; then
            SCRIPT_NAME=$(basename "$script" .sh)
            DEST="/usr/local/bin/${SCRIPT_NAME/github-dev-sync/dev-sync}"
            DEST="${DEST/fix-arch-audio/fix-audio}"
            
            sudo install -m 755 "$script" "$DEST"
        fi
    done
    
    cd -
}

run_16_aur_essential() {
    echo -e "${BLUE}Installing essential AUR packages...${NC}"
    
    if ! command -v yay &> /dev/null; then
        echo -e "${YELLOW}Yay not installed, skipping AUR packages${NC}"
        return
    fi
    
    ESSENTIAL_AUR=(
        visual-studio-code-bin
        spotify
        claude-code
    )
    
    echo -e "${YELLOW}This will install: ${ESSENTIAL_AUR[*]}${NC}"
    read -p "Continue? (y/n) [y]: " -n 1 -r REPLY
    REPLY=${REPLY:-y}
    echo
    
    if [[ $REPLY =~ ^[Yy]$ ]]; then
        for pkg in "${ESSENTIAL_AUR[@]}"; do
            if ! pacman -Qi "$pkg" &> /dev/null; then
                yay -S --needed --noconfirm "$pkg"
            else
                echo -e "${GREEN}✓ $pkg already installed${NC}"
            fi
        done
    fi
}

run_17_aur_optional() {
    echo -e "${BLUE}Installing optional AUR packages...${NC}"
    
    if ! command -v yay &> /dev/null; then
        echo -e "${YELLOW}Yay not installed, skipping AUR packages${NC}"
        return
    fi
    
    OPTIONAL_AUR=(
        slack-desktop
        zoom
        postman-bin
        figma-linux-bin
        1password
        1password-cli
        grimblast-git
    )
    
    echo -e "${YELLOW}Available optional AUR packages:${NC}"
    for pkg in "${OPTIONAL_AUR[@]}"; do
        if ! pacman -Qi "$pkg" &> /dev/null; then
            read -p "Install $pkg? (y/n) [n]: " -n 1 -r REPLY
            REPLY=${REPLY:-n}
            echo
            if [[ $REPLY =~ ^[Yy]$ ]]; then
                yay -S --needed --noconfirm "$pkg"
            fi
        else
            echo -e "${GREEN}✓ $pkg already installed${NC}"
        fi
    done
}

run_18_git_config() {
    echo -e "${BLUE}Configuring Git...${NC}"
    
    if [ ! -f "$HOME/.gitconfig" ] || ! grep -q "user.name" "$HOME/.gitconfig" 2>/dev/null; then
        read -p "Configure Git? (y/n) [y]: " -n 1 -r REPLY
        REPLY=${REPLY:-y}
        echo
        if [[ $REPLY =~ ^[Yy]$ ]]; then
            "$SCRIPT_DIR/scripts/setup-git-config.sh"
        fi
    else
        echo -e "${GREEN}✓ Git already configured${NC}"
    fi
}

run_19_ssh_keys() {
    echo -e "${BLUE}Setting up SSH keys...${NC}"
    
    if [ ! -f "$HOME/.ssh/id_ed25519" ] && [ ! -f "$HOME/.ssh/id_rsa" ]; then
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
}

run_20_final_config() {
    echo -e "${BLUE}Finalizing configuration...${NC}"
    
    # Enable remaining services
    sudo systemctl enable NetworkManager 2>/dev/null || true
    
    # Create Hyprland desktop entry
    if [ ! -f /usr/share/wayland-sessions/hyprland.desktop ]; then
        sudo tee /usr/share/wayland-sessions/hyprland.desktop > /dev/null << 'EOF'
[Desktop Entry]
Name=Hyprland
Comment=An intelligent dynamic tiling Wayland compositor
Exec=Hyprland
Type=Application
EOF
    fi
    
    echo -e "${GREEN}✓ All configurations complete${NC}"
}

# Execute module
run_module() {
    local module=$1
    local func="run_${module//-/_}"
    
    if declare -f "$func" > /dev/null; then
        echo
        echo -e "${PURPLE}Running: ${MODULES[$module]}${NC}"
        echo "════════════════════════════════════════"
        
        # Keep sudo alive for this module
        sudo -v
        (while true; do sudo -n true; sleep 50; done 2>/dev/null) &
        local SUDO_PID=$!
        
        # Run the module
        $func
        
        # Kill sudo keepalive
        kill $SUDO_PID 2>/dev/null || true
        
        # Mark as complete
        mark_complete "$module"
        
        echo -e "${GREEN}✓ Module complete${NC}"
        echo
    else
        echo -e "${RED}Module function not found: $func${NC}"
    fi
}

# Main loop
main() {
    while true; do
        clear
        show_menu
        read choice
        
        case $choice in
            [1-9]|1[0-9]|20)
                # Run specific module
                local index=$((choice - 1))
                if [ $index -lt ${#MODULE_ORDER[@]} ]; then
                    run_module "${MODULE_ORDER[$index]}"
                else
                    echo -e "${RED}Invalid choice${NC}"
                fi
                ;;
            a|A)
                # Run all remaining
                for module in "${MODULE_ORDER[@]}"; do
                    if ! is_complete "$module"; then
                        run_module "$module"
                    fi
                done
                break
                ;;
            n|N)
                # Run next incomplete
                for module in "${MODULE_ORDER[@]}"; do
                    if ! is_complete "$module"; then
                        run_module "$module"
                        break
                    fi
                done
                ;;
            r|R)
                # Reset progress
                read -p "Are you sure you want to reset all progress? (y/n) [n]: " -n 1 -r REPLY
                REPLY=${REPLY:-n}
                echo
                if [[ $REPLY =~ ^[Yy]$ ]]; then
                    > "$STATE_FILE"
                    echo -e "${YELLOW}Progress reset${NC}"
                fi
                ;;
            q|Q)
                # Quit
                break
                ;;
            *)
                echo -e "${RED}Invalid choice${NC}"
                ;;
        esac
        
        echo
        read -p "Press Enter to continue..."
    done
    
    # Final summary
    echo
    echo -e "${GREEN}╔════════════════════════════════════════╗${NC}"
    echo -e "${GREEN}║        Installation Summary            ║${NC}"
    echo -e "${GREEN}╚════════════════════════════════════════╝${NC}"
    echo
    
    local completed=0
    for module in "${MODULE_ORDER[@]}"; do
        if is_complete "$module"; then
            ((completed++))
        fi
    done
    
    echo -e "Completed: ${GREEN}$completed${NC} / ${#MODULE_ORDER[@]} modules"
    
    if [ $completed -eq ${#MODULE_ORDER[@]} ]; then
        echo
        echo -e "${GREEN}All modules completed!${NC}"
        echo
        echo -e "${YELLOW}Next steps:${NC}"
        echo "1. Reboot your system"
        echo "2. Login via SDDM"
        echo "3. For Node.js/NVM: source ~/.zshrc"
        echo
        echo -e "${BLUE}Key bindings:${NC}"
        echo -e "  ${GREEN}Alt + Enter${NC} - Open Ghostty"
        echo -e "  ${GREEN}Alt + Space${NC} - App launcher"
        echo -e "  ${GREEN}Alt + H/J/K/L${NC} - Focus windows"
    fi
}

# Run main if not sourced
if [ "${BASH_SOURCE[0]}" == "${0}" ]; then
    main
fi