#!/bin/bash

# Standalone fnm installation script for testing
set -e

# Colors
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

echo -e "${YELLOW}Fast Node Manager (fnm) Installation Script${NC}"
echo -e "${YELLOW}===========================================${NC}"

# Function to add fnm to shell config
add_to_shell_config() {
    local shell_config="$1"
    local fnm_init_code='
# Fast Node Manager (fnm)
if command -v fnm &> /dev/null; then
    eval "$(fnm env --use-on-cd)"
fi'

    if [ -f "$shell_config" ] && ! grep -q "fnm env" "$shell_config"; then
        echo -e "${YELLOW}Adding fnm to $shell_config...${NC}"
        echo "$fnm_init_code" >> "$shell_config"
        echo -e "${GREEN}✓ Added fnm to $shell_config${NC}"
    fi
}

# Method 1: Try AUR first (if yay is available)
if command -v yay &> /dev/null; then
    echo -e "${YELLOW}Method 1: Installing fnm via AUR...${NC}"
    if yay -S --needed --noconfirm fnm-bin 2>/dev/null || yay -S --needed --noconfirm fnm 2>/dev/null; then
        echo -e "${GREEN}✓ fnm installed via AUR${NC}"
    else
        echo -e "${RED}✗ AUR installation failed${NC}"
    fi
fi

# Method 2: Install via official script
if ! command -v fnm &> /dev/null; then
    echo -e "${YELLOW}Method 2: Installing fnm via official install script...${NC}"
    
    # Create installation directory
    FNM_DIR="${XDG_DATA_HOME:-$HOME/.local/share}/fnm"
    mkdir -p "$FNM_DIR"
    
    # Download and install
    if curl -fsSL https://fnm.vercel.app/install | bash -s -- --install-dir "$FNM_DIR" --skip-shell; then
        echo -e "${GREEN}✓ fnm installed to $FNM_DIR${NC}"
        export PATH="$FNM_DIR:$PATH"
    else
        echo -e "${RED}✗ Install script failed${NC}"
    fi
fi

# Method 3: Install via cargo
if ! command -v fnm &> /dev/null && command -v cargo &> /dev/null; then
    echo -e "${YELLOW}Method 3: Installing fnm via cargo...${NC}"
    if cargo install fnm; then
        echo -e "${GREEN}✓ fnm installed via cargo${NC}"
        export PATH="$HOME/.cargo/bin:$PATH"
    else
        echo -e "${RED}✗ Cargo installation failed${NC}"
    fi
fi

# Method 4: Install via npm (if available)
if ! command -v fnm &> /dev/null && command -v npm &> /dev/null; then
    echo -e "${YELLOW}Method 4: Installing fnm via npm...${NC}"
    if npm install -g @fnm/fnm; then
        echo -e "${GREEN}✓ fnm installed via npm${NC}"
    else
        echo -e "${RED}✗ npm installation failed${NC}"
    fi
fi

# Add to PATH for current session
POSSIBLE_PATHS=(
    "${XDG_DATA_HOME:-$HOME/.local/share}/fnm"
    "$HOME/.fnm"
    "$HOME/.cargo/bin"
    "$(npm root -g 2>/dev/null)/bin"
)

for path in "${POSSIBLE_PATHS[@]}"; do
    if [ -f "$path/fnm" ]; then
        export PATH="$path:$PATH"
        echo -e "${GREEN}✓ Added $path to PATH${NC}"
        break
    fi
done

# Verify installation
if command -v fnm &> /dev/null; then
    echo -e "${GREEN}✓ fnm installed successfully!${NC}"
    echo -e "${GREEN}  Location: $(which fnm)${NC}"
    echo -e "${GREEN}  Version: $(fnm --version)${NC}"
    
    # Add to shell configurations
    add_to_shell_config "$HOME/.bashrc"
    add_to_shell_config "$HOME/.zshrc"
    
    # Initialize fnm
    eval "$(fnm env --use-on-cd)"
    
    # Install Node.js LTS
    echo -e "${YELLOW}Installing Node.js LTS...${NC}"
    if fnm install --lts && fnm use lts-latest && fnm default lts-latest; then
        echo -e "${GREEN}✓ Node.js $(node --version) installed${NC}"
        echo -e "${GREEN}✓ npm $(npm --version) available${NC}"
    else
        echo -e "${RED}✗ Failed to install Node.js${NC}"
    fi
    
    echo -e "\n${GREEN}Installation complete!${NC}"
    echo -e "${YELLOW}Please restart your shell or run:${NC}"
    echo -e "  source ~/.bashrc   # for bash"
    echo -e "  source ~/.zshrc    # for zsh"
else
    echo -e "${RED}✗ Failed to install fnm${NC}"
    echo -e "${YELLOW}Please install fnm manually from: https://github.com/Schniz/fnm${NC}"
    exit 1
fi