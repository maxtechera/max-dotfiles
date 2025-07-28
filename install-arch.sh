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
echo -e "\n${YELLOW}[1/8] Updating system...${NC}"
sudo pacman -Syu --noconfirm

# Install yay (AUR helper)
echo -e "\n${YELLOW}[2/8] Installing yay...${NC}"
if ! command -v yay &> /dev/null; then
    git clone https://aur.archlinux.org/yay-bin.git /tmp/yay-bin
    cd /tmp/yay-bin
    makepkg -si --noconfirm
    cd -
    rm -rf /tmp/yay-bin
fi

# Install base packages
echo -e "\n${YELLOW}[3/8] Installing base packages...${NC}"
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

# Install Hyprland and dependencies
echo -e "\n${YELLOW}[4/8] Installing Hyprland...${NC}"
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
echo -e "\n${YELLOW}[5/8] Installing fonts...${NC}"
sudo pacman -S --needed --noconfirm \
    ttf-jetbrains-mono-nerd \
    ttf-font-awesome \
    ttf-nerd-fonts-symbols \
    noto-fonts \
    noto-fonts-cjk \
    noto-fonts-emoji \
    ttf-firacode-nerd

# Install Ghostty from AUR
echo -e "\n${YELLOW}[6/8] Installing Ghostty...${NC}"
yay -S --needed --noconfirm ghostty-bin

# Install grimblast from AUR
yay -S --needed --noconfirm grimblast-git

# Clone and setup dotfiles
echo -e "\n${YELLOW}[7/8] Setting up dotfiles...${NC}"
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

# Install nvim-tab and dev-sync scripts
echo -e "\n${GREEN}Installing custom scripts...${NC}"
sudo install -m 755 scripts/nvim-tab /usr/local/bin/nvim-tab
sudo install -m 755 scripts/github-dev-sync.sh /usr/local/bin/dev-sync

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
echo -e "\n${YELLOW}[8/8] Setting up shell...${NC}"
if [ "$SHELL" != "$(which zsh)" ]; then
    chsh -s $(which zsh)
fi

# Enable services
echo -e "\n${GREEN}Enabling services...${NC}"
systemctl --user enable pipewire
systemctl --user enable wireplumber
sudo systemctl enable bluetooth

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
pipx install poetry
pipx install black
pipx install ruff
pipx install ipython

echo -e "\n${GREEN}╔════════════════════════════════════════╗${NC}"
echo -e "${GREEN}║        Installation Complete!          ║${NC}"
echo -e "${GREEN}╚════════════════════════════════════════╝${NC}"
echo -e "\n${YELLOW}Please reboot and login to start Hyprland${NC}"
echo -e "${YELLOW}After reboot, press Ctrl+Alt+F2 to switch to TTY2${NC}"
echo -e "${YELLOW}Login and type: Hyprland${NC}"
echo -e "\n${BLUE}Key bindings:${NC}"
echo -e "  ${GREEN}Super + Enter${NC} - Open Ghostty"
echo -e "  ${GREEN}Super + D${NC} - Open Rofi"
echo -e "  ${GREEN}Super + Q${NC} - Close window"
echo -e "  ${GREEN}Super + M${NC} - Exit Hyprland"
echo -e "  ${GREEN}Super + [1-9]${NC} - Switch workspace"
echo -e "  ${GREEN}Super + Shift + [1-9]${NC} - Move window to workspace"