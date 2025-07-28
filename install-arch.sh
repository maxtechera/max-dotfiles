#!/bin/bash
# Arch Linux Post-Install Setup
# Run this on a fresh Arch installation to set up everything

set -e

# Colors
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m'

echo -e "${BLUE}╔════════════════════════════════════════╗${NC}"
echo -e "${BLUE}║     Arch Linux Environment Setup       ║${NC}"
echo -e "${BLUE}║        Hyprland + Ghostty              ║${NC}"
echo -e "${BLUE}╚════════════════════════════════════════╝${NC}"

# Update system
echo -e "\n${YELLOW}[1/11] Updating system...${NC}"
sudo pacman -Syu --noconfirm

# Detect and install GPU drivers
echo -e "\n${YELLOW}[2/11] Detecting GPU...${NC}"
GPU_TYPE="unknown"
if lspci | grep -i nvidia > /dev/null; then
    GPU_TYPE="nvidia"
    echo -e "${GREEN}NVIDIA GPU detected${NC}"
    read -p "Install NVIDIA drivers? (y/n) " -n 1 -r
    echo
    if [[ $REPLY =~ ^[Yy]$ ]]; then
        sudo pacman -S --needed --noconfirm nvidia nvidia-utils nvidia-settings
        echo "options nvidia-drm modeset=1" | sudo tee /etc/modprobe.d/nvidia.conf
        echo -e "${YELLOW}Note: You may need to rebuild initramfs and reboot${NC}"
    fi
elif lspci | grep -i amd | grep -i vga > /dev/null; then
    GPU_TYPE="amd"
    echo -e "${GREEN}AMD GPU detected${NC}"
    sudo pacman -S --needed --noconfirm mesa vulkan-radeon libva-mesa-driver
elif lspci | grep -i intel | grep -i vga > /dev/null; then
    GPU_TYPE="intel"
    echo -e "${GREEN}Intel GPU detected${NC}"
    sudo pacman -S --needed --noconfirm mesa vulkan-intel intel-media-driver
fi

# Install yay (AUR helper)
echo -e "\n${YELLOW}[3/11] Installing yay...${NC}"
if ! command -v yay &> /dev/null; then
    git clone https://aur.archlinux.org/yay-bin.git /tmp/yay-bin
    cd /tmp/yay-bin
    makepkg -si --noconfirm
    cd -
    rm -rf /tmp/yay-bin
fi

# Install base packages
echo -e "\n${YELLOW}[4/11] Installing base packages...${NC}"
sudo pacman -S --needed --noconfirm \
    base-devel \
    git \
    neovim \
    neovim-remote \
    tmux \
    zsh \
    stow \
    wget \
    curl \
    unzip \
    ripgrep \
    fd \
    fzf \
    bat \
    htop \
    btop \
    neofetch \
    ranger \
    lazygit \
    github-cli \
    jq \
    man-db \
    man-pages \
    openssh \
    python \
    python-pip \
    python-pipx \
    chromium

# Install optional packages (may not be in all repos)
echo -e "\n${GREEN}Installing optional packages...${NC}"
for pkg in git-delta imagemagick; do
    sudo pacman -S --needed --noconfirm $pkg 2>/dev/null || echo "Optional package $pkg not found, skipping..."
done \
    tree \
    ncdu \
    duf \
    tldr \
    eza \
    zoxide \
    direnv \
    thefuck \
    httpie \
    glow

# Install Hyprland and dependencies
echo -e "\n${YELLOW}[5/11] Installing Hyprland...${NC}"
sudo pacman -S --needed --noconfirm \
    hyprland \
    xdg-desktop-portal-hyprland \
    qt5-wayland \
    qt6-wayland \
    polkit-kde-agent \
    pipewire \
    wireplumber \
    pipewire-pulse \
    pipewire-alsa \
    pipewire-jack \
    grim \
    slurp \
    wl-clipboard \
    swappy \
    mako \
    waybar \
    rofi-wayland \
    swww \
    swaylock-effects \
    wlogout \
    hyprpicker \
    xdg-utils \
    xorg-xwayland \
    pavucontrol \
    brightnessctl \
    playerctl \
    pamixer \
    thunar \
    thunar-archive-plugin \
    file-roller \
    tumbler \
    gvfs \
    gvfs-mtp \
    thunar-volman \
    bluez \
    bluez-utils \
    blueman \
    network-manager-applet

# Install fonts
echo -e "\n${YELLOW}[6/11] Installing fonts...${NC}"
sudo pacman -S --needed --noconfirm \
    ttf-jetbrains-mono-nerd \
    ttf-font-awesome \
    ttf-nerd-fonts-symbols \
    noto-fonts \
    noto-fonts-cjk \
    noto-fonts-emoji \
    ttf-firacode-nerd \
    inter-font \
    ttf-roboto \
    ttf-ubuntu-font-family

# Install Ghostty from AUR
echo -e "\n${YELLOW}[7/11] Installing Ghostty...${NC}"
yay -S --needed --noconfirm ghostty-bin

# Install AUR packages
echo -e "\n${YELLOW}Installing AUR packages...${NC}"
yay -S --needed --noconfirm \
    grimblast-git \
    spotify \
    slack-desktop \
    zoom \
    visual-studio-code-bin \
    postman-bin \
    figma-linux-bin \
    1password \
    1password-cli

# Clone and setup dotfiles
echo -e "\n${YELLOW}[8/11] Setting up dotfiles...${NC}"
DOTFILES_DIR="$HOME/.dotfiles"

# Backup existing configs
for config in hypr waybar rofi ghostty nvim tmux zsh git; do
    if [ -e "$HOME/.config/$config" ]; then
        echo "Backing up existing $config config..."
        mv "$HOME/.config/$config" "$HOME/.config/$config.backup.$(date +%Y%m%d%H%M%S)"
    fi
done

# Also backup existing dotfiles
for dotfile in .zshrc .zshenv .tmux.conf .gitconfig; do
    if [ -e "$HOME/$dotfile" ]; then
        echo "Backing up existing $dotfile..."
        mv "$HOME/$dotfile" "$HOME/$dotfile.backup.$(date +%Y%m%d%H%M%S)"
    fi
done

# Clone this repository to ~/.dotfiles
if [ -d "$DOTFILES_DIR" ]; then
    echo "Dotfiles already exist, backing up..."
    mv "$DOTFILES_DIR" "$DOTFILES_DIR.backup.$(date +%Y%m%d%H%M%S)"
fi

# Copy current directory to dotfiles location
cp -r "$(pwd)" "$DOTFILES_DIR"
cd "$DOTFILES_DIR"

# Install all custom scripts
echo -e "\n${GREEN}Installing custom scripts...${NC}"
sudo install -m 755 scripts/nvim-tab /usr/local/bin/nvim-tab
sudo install -m 755 scripts/github-dev-sync.sh /usr/local/bin/dev-sync
sudo install -m 755 scripts/fix-arch-audio.sh /usr/local/bin/fix-audio
chmod +x scripts/setup-git-config.sh

# Use GNU Stow to symlink configs
echo -e "\n${GREEN}Creating symlinks...${NC}"
stow -v hypr
stow -v waybar
stow -v rofi
stow -v ghostty
stow -v nvim
stow -v tmux
stow -v zsh
stow -v git

# Change default shell to zsh
echo -e "\n${YELLOW}[9/11] Setting up shell...${NC}"
if [ "$SHELL" != "$(which zsh)" ]; then
    chsh -s $(which zsh)
fi

# Enable services
echo -e "\n${GREEN}Enabling services...${NC}"
systemctl --user enable pipewire
systemctl --user enable wireplumber
sudo systemctl enable bluetooth
sudo systemctl enable NetworkManager

# Install Oh My Zsh
echo -e "\n${GREEN}Installing Oh My Zsh...${NC}"
if [ ! -d "$HOME/.oh-my-zsh" ]; then
    sh -c "$(curl -fsSL https://raw.githubusercontent.com/ohmyzsh/ohmyzsh/master/tools/install.sh)" "" --unattended
fi

# Set up zsh plugins
echo -e "\n${GREEN}Installing zsh plugins...${NC}"
git clone https://github.com/zsh-users/zsh-autosuggestions ${ZSH_CUSTOM:-~/.oh-my-zsh/custom}/plugins/zsh-autosuggestions 2>/dev/null || true
git clone https://github.com/zsh-users/zsh-syntax-highlighting ${ZSH_CUSTOM:-~/.oh-my-zsh/custom}/plugins/zsh-syntax-highlighting 2>/dev/null || true

# Install tmux plugin manager
echo -e "\n${GREEN}Installing tmux plugin manager...${NC}"
git clone https://github.com/tmux-plugins/tpm ~/.tmux/plugins/tpm 2>/dev/null || true

# Install LazyVim
echo -e "\n${GREEN}Setting up Neovim with LazyVim...${NC}"
if [ ! -d "$HOME/.config/nvim" ]; then
    git clone https://github.com/LazyVim/starter ~/.config/nvim
    rm -rf ~/.config/nvim/.git
fi

# Install NVM (Node Version Manager)
echo -e "\n${GREEN}Installing NVM...${NC}"
curl -o- https://raw.githubusercontent.com/nvm-sh/nvm/v0.39.0/install.sh | bash

# Source NVM and install latest LTS Node
export NVM_DIR="$HOME/.nvm"
[ -s "$NVM_DIR/nvm.sh" ] && \. "$NVM_DIR/nvm.sh"
nvm install --lts
nvm use --lts
nvm alias default node

# Install global npm packages
echo -e "\n${GREEN}Installing global npm packages...${NC}"
npm install -g pnpm yarn typescript prettier eslint

# Set up Python with pipx for global tools
echo -e "\n${GREEN}Setting up Python tools...${NC}"
pipx ensurepath
pipx install poetry
pipx install black
pipx install ruff
pipx install ipython

# Configure Git
echo -e "\n${GREEN}Configuring Git...${NC}"
./scripts/setup-git-config.sh

# Generate SSH key if needed
if [ ! -f "$HOME/.ssh/id_ed25519" ] && [ ! -f "$HOME/.ssh/id_rsa" ]; then
    echo -e "\n${GREEN}Generating SSH key for GitHub...${NC}"
    read -p "Enter email for SSH key: " SSH_EMAIL
    ssh-keygen -t ed25519 -C "$SSH_EMAIL" -f "$HOME/.ssh/id_ed25519" -N ""
    echo -e "\n${YELLOW}Add this key to GitHub:${NC}"
    cat "$HOME/.ssh/id_ed25519.pub"
    echo -e "\n${YELLOW}Press Enter when you've added the key to GitHub...${NC}"
    read
fi

# Install SDDM display manager
echo -e "\n${YELLOW}[10/11] Installing display manager...${NC}"
sudo pacman -S --needed --noconfirm sddm qt5-graphicaleffects qt5-quickcontrols2 qt5-svg
yay -S --needed --noconfirm sddm-sugar-candy-git

# Configure SDDM
sudo systemctl enable sddm
sudo mkdir -p /etc/sddm.conf.d
sudo tee /etc/sddm.conf.d/theme.conf > /dev/null << EOF
[Theme]
Current=sugar-candy
EOF

# Create Hyprland desktop entry
sudo tee /usr/share/wayland-sessions/hyprland.desktop > /dev/null << 'EOF'
[Desktop Entry]
Name=Hyprland
Comment=An intelligent dynamic tiling Wayland compositor
Exec=Hyprland
Type=Application
EOF

# Configure system for better experience
echo -e "\n${YELLOW}[11/11] Final system configuration...${NC}"
# Enable autologin (optional - comment out if you want login screen)
# sudo mkdir -p /etc/sddm.conf.d
# sudo tee /etc/sddm.conf.d/autologin.conf > /dev/null << EOF
# [Autologin]
# User=$USER
# Session=hyprland
# EOF

echo -e "\n${GREEN}╔════════════════════════════════════════╗${NC}"
echo -e "${GREEN}║        Installation Complete!          ║${NC}"
echo -e "${GREEN}╚════════════════════════════════════════╝${NC}"
echo -e "\n${YELLOW}Please reboot your system${NC}"
echo -e "${GREEN}You'll see a beautiful login screen where you can select Hyprland!${NC}"
echo -e "\n${BLUE}Key bindings (matching your Aerospace):${NC}"
echo -e "  ${GREEN}Alt + Enter${NC} - Open Ghostty"
echo -e "  ${GREEN}Alt + F${NC} - Fullscreen"
echo -e "  ${GREEN}Alt + H/J/K/L${NC} - Focus windows"
echo -e "  ${GREEN}Alt + Shift + H/J/K/L${NC} - Move windows"
echo -e "  ${GREEN}Alt + [1-9,A-Z]${NC} - Switch workspace"
echo -e "  ${GREEN}Alt + Shift + [1-9,A-Z]${NC} - Move window to workspace"
echo -e "  ${GREEN}Alt + Tab${NC} - Previous workspace"
echo -e "  ${GREEN}Alt + -/=${NC} - Resize windows"
echo -e "\n${YELLOW}Apps are pre-assigned to workspaces:${NC}"
echo -e "  ${GREEN}C${NC} - Chrome Profile 1"
echo -e "  ${GREEN}S${NC} - Slack"
echo -e "  ${GREEN}M${NC} - WhatsApp"
echo -e "  ${GREEN}F${NC} - Figma"
echo -e "  ${GREEN}P${NC} - Postman"