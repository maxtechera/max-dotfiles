#!/bin/bash
# Setup git configuration interactively

echo "Setting up Git configuration..."

# Get current values if they exist
CURRENT_NAME=$(git config --global user.name 2>/dev/null)
CURRENT_EMAIL=$(git config --global user.email 2>/dev/null)

# Prompt for name
if [ -n "$CURRENT_NAME" ] && [ "$CURRENT_NAME" != "Your Name" ]; then
    echo "Current Git name: $CURRENT_NAME"
    read -p "Press Enter to keep, or type new name: " NEW_NAME
    if [ -z "$NEW_NAME" ]; then
        NEW_NAME="$CURRENT_NAME"
    fi
else
    read -p "Enter your Git name: " NEW_NAME
fi

# Prompt for email
if [ -n "$CURRENT_EMAIL" ] && [ "$CURRENT_EMAIL" != "your.email@example.com" ]; then
    echo "Current Git email: $CURRENT_EMAIL"
    read -p "Press Enter to keep, or type new email: " NEW_EMAIL
    if [ -z "$NEW_EMAIL" ]; then
        NEW_EMAIL="$CURRENT_EMAIL"
    fi
else
    read -p "Enter your Git email: " NEW_EMAIL
fi

# Update the gitconfig file
if [ -f "$HOME/.gitconfig" ]; then
    # Update existing file
    sed -i.bak "s/name = .*/name = $NEW_NAME/" "$HOME/.gitconfig"
    sed -i.bak "s/email = .*/email = $NEW_EMAIL/" "$HOME/.gitconfig"
else
    # Create new file from template
    cp "$(dirname "$0")/../git/.gitconfig" "$HOME/.gitconfig"
    sed -i "s/Your Name/$NEW_NAME/" "$HOME/.gitconfig"
    sed -i "s/your.email@example.com/$NEW_EMAIL/" "$HOME/.gitconfig"
fi

echo "Git configuration updated!"

# Install delta if not already installed
if ! command -v delta &> /dev/null; then
    echo "Installing delta for better git diffs..."
    if [[ "$OSTYPE" == "darwin"* ]]; then
        brew install git-delta
    else
        sudo pacman -S git-delta || yay -S git-delta-bin
    fi
fi