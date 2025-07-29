#!/bin/bash
# Install Fast Node Manager (fnm) for ultra-fast Node.js version management
# This replaces nvm and provides 50x faster startup times

set -euo pipefail

echo "Installing Fast Node Manager (fnm)..."

# Check if fnm is already installed
if command -v fnm &> /dev/null; then
    echo "fnm is already installed at: $(which fnm)"
    echo "Version: $(fnm --version)"
    exit 0
fi

# Install fnm based on the system
if command -v pacman &> /dev/null; then
    # Arch Linux - Install from AUR
    if command -v yay &> /dev/null; then
        echo "Installing fnm from AUR using yay..."
        yay -S fnm-bin --noconfirm
    elif command -v paru &> /dev/null; then
        echo "Installing fnm from AUR using paru..."
        paru -S fnm-bin --noconfirm
    else
        echo "Error: No AUR helper found. Please install yay or paru first."
        exit 1
    fi
elif [[ "$OSTYPE" == "darwin"* ]]; then
    # macOS
    if command -v brew &> /dev/null; then
        echo "Installing fnm using Homebrew..."
        brew install fnm
    else
        echo "Error: Homebrew not found. Please install Homebrew first."
        exit 1
    fi
else
    # Generic installation using curl
    echo "Installing fnm using the official script..."
    curl -fsSL https://fnm.vercel.app/install | bash
fi

echo ""
echo "fnm installed successfully!"
echo ""
echo "Next steps:"
echo "1. Restart your terminal or run: source ~/.zshrc"
echo "2. Install Node.js: fnm install --lts"
echo "3. Set default: fnm default <version>"
echo ""
echo "Your .zshrc is already configured to use fnm instead of nvm."