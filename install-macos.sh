#!/bin/bash
# macOS Dotfiles Setup
# Configures macOS to match Arch Linux environment

set -e

# Colors
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m'

echo -e "${BLUE}╔════════════════════════════════════════╗${NC}"
echo -e "${BLUE}║        macOS Environment Setup         ║${NC}"
echo -e "${BLUE}║     Matching Arch Linux Experience     ║${NC}"
echo -e "${BLUE}╚════════════════════════════════════════╝${NC}"

# Check if Homebrew is installed
if ! command -v brew &> /dev/null; then
    echo -e "${YELLOW}Installing Homebrew...${NC}"
    /bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)"
fi

# Update Homebrew
echo -e "\n${YELLOW}[1/8] Updating Homebrew...${NC}"
brew update

# Install base packages (matching Arch setup)
echo -e "\n${YELLOW}[2/8] Installing CLI tools...${NC}"
brew install --quiet \
    neovim \
    neovim-remote \
    tmux \
    zsh \
    stow \
    wget \
    curl \
    ripgrep \
    fd \
    fzf \
    bat \
    htop \
    btop \
    lazygit \
    gh \
    jq \
    python@3.11 \
    pipx

# Install casks
echo -e "\n${YELLOW}[3/8] Installing applications...${NC}"

# Install Ghostty if not already installed
if ! ls /Applications/Ghostty.app &> /dev/null; then
    echo "Installing Ghostty..."
    brew install --cask ghostty || {
        echo -e "${YELLOW}Ghostty not in Homebrew yet. Download from: https://ghostty.org${NC}"
        echo -e "${YELLOW}After installing, run this script again.${NC}"
    }
fi

# Install Aerospace if not already installed
if ! command -v aerospace &> /dev/null; then
    echo "Installing Aerospace..."
    brew install --cask nikitabobko/tap/aerospace
fi

# Install fonts
echo -e "\n${YELLOW}[4/8] Installing fonts...${NC}"
brew tap homebrew/cask-fonts
brew install --cask \
    font-jetbrains-mono-nerd-font \
    font-fira-code-nerd-font

# Setup Python tools with pipx
echo -e "\n${YELLOW}[5/8] Setting up Python tools...${NC}"
pipx ensurepath
pipx install poetry
pipx install black
pipx install ruff
pipx install ipython

# Clone and setup dotfiles
echo -e "\n${YELLOW}[6/8] Setting up dotfiles...${NC}"
DOTFILES_DIR="$HOME/.dotfiles"

# Backup existing configs
for config in ghostty nvim tmux aerospace; do
    if [ -e "$HOME/.config/$config" ]; then
        echo "Backing up existing $config config..."
        mv "$HOME/.config/$config" "$HOME/.config/$config.backup.$(date +%Y%m%d%H%M%S)"
    fi
done

# Backup aerospace config specifically
if [ -f "$HOME/.aerospace.toml" ]; then
    echo "Backing up existing .aerospace.toml..."
    mv "$HOME/.aerospace.toml" "$HOME/.aerospace.toml.backup.$(date +%Y%m%d%H%M%S)"
fi

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

# Install custom scripts
echo -e "\n${GREEN}Installing custom scripts...${NC}"
sudo mkdir -p /usr/local/bin
sudo install -m 755 scripts/nvim-tab /usr/local/bin/nvim-tab
sudo install -m 755 scripts/github-dev-sync.sh /usr/local/bin/dev-sync

# Use GNU Stow to symlink configs
echo -e "\n${GREEN}Creating symlinks...${NC}"
stow -v ghostty
stow -v nvim
stow -v tmux
stow -v zsh
stow -v git

# Copy aerospace config to home (it doesn't use .config/)
cp aerospace/.aerospace.toml ~/

# Change default shell to zsh if needed
echo -e "\n${YELLOW}[7/8] Setting up shell...${NC}"
if [ "$SHELL" != "$(which zsh)" ]; then
    echo "Changing default shell to zsh..."
    chsh -s $(which zsh)
fi

# Install Oh My Zsh
echo -e "\n${GREEN}Installing Oh My Zsh...${NC}"
if [ ! -d "$HOME/.oh-my-zsh" ]; then
    sh -c "$(curl -fsSL https://raw.githubusercontent.com/ohmyzsh/ohmyzsh/master/tools/install.sh)" "" --unattended
fi

# Set up zsh plugins
echo -e "\n${GREEN}Installing zsh plugins...${NC}"
git clone https://github.com/zsh-users/zsh-autosuggestions ${ZSH_CUSTOM:-~/.oh-my-zsh/custom}/plugins/zsh-autosuggestions 2>/dev/null || true

# Install tmux plugin manager
echo -e "\n${GREEN}Installing tmux plugin manager...${NC}"
git clone https://github.com/tmux-plugins/tpm ~/.tmux/plugins/tpm 2>/dev/null || true

# Install NVM
echo -e "\n${YELLOW}[8/8] Installing NVM...${NC}"
if [ ! -d "$HOME/.nvm" ]; then
    curl -o- https://raw.githubusercontent.com/nvm-sh/nvm/v0.39.0/install.sh | bash
    
    # Source NVM and install latest LTS Node
    export NVM_DIR="$HOME/.nvm"
    [ -s "$NVM_DIR/nvm.sh" ] && \. "$NVM_DIR/nvm.sh"
    nvm install --lts
    nvm use --lts
    nvm alias default node
    
    # Install global npm packages
    npm install -g pnpm yarn typescript prettier eslint
fi

echo -e "\n${GREEN}╔════════════════════════════════════════╗${NC}"
echo -e "${GREEN}║    macOS Setup Complete!               ║${NC}"
echo -e "${GREEN}╚════════════════════════════════════════╝${NC}"
echo -e "\n${YELLOW}Please restart your terminal or run: source ~/.zshrc${NC}"
echo -e "\n${BLUE}Your environment now matches your Arch Linux setup:${NC}"
echo -e "  ${GREEN}Alt + Enter${NC} - Open Ghostty"
echo -e "  ${GREEN}Alt + [hjkl]${NC} - Navigate windows"
echo -e "  ${GREEN}Alt + [1-9,a-z]${NC} - Switch workspaces"
echo -e "  ${GREEN}Alt + Shift + [hjkl]${NC} - Move windows"
echo -e "\n${YELLOW}To start Aerospace, run: aerospace${NC}"