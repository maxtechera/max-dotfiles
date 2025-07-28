#!/bin/bash
# Verification script to check if everything was installed correctly

# Colors
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
PURPLE='\033[0;35m'
NC='\033[0m'

echo -e "${BLUE}╔════════════════════════════════════════╗${NC}"
echo -e "${BLUE}║    Installation Verification Tool      ║${NC}"
echo -e "${BLUE}╚════════════════════════════════════════╝${NC}"

# Counters
TOTAL=0
INSTALLED=0
MISSING=0
WARNINGS=0

# Function to check if package is installed
check_package() {
    local pkg=$1
    local type=${2:-"pacman"}
    TOTAL=$((TOTAL + 1))
    
    if [ "$type" == "pacman" ]; then
        if pacman -Qi "$pkg" &> /dev/null; then
            echo -e "${GREEN}✓${NC} $pkg"
            INSTALLED=$((INSTALLED + 1))
            return 0
        else
            echo -e "${RED}✗${NC} $pkg"
            MISSING=$((MISSING + 1))
            return 1
        fi
    elif [ "$type" == "command" ]; then
        if command -v "$pkg" &> /dev/null; then
            echo -e "${GREEN}✓${NC} $pkg ($(which $pkg))"
            INSTALLED=$((INSTALLED + 1))
            return 0
        else
            echo -e "${RED}✗${NC} $pkg command not found"
            MISSING=$((MISSING + 1))
            return 1
        fi
    fi
}

# Function to check service status
check_service() {
    local service=$1
    TOTAL=$((TOTAL + 1))
    
    if systemctl is-enabled --quiet "$service" 2>/dev/null; then
        if systemctl is-active --quiet "$service" 2>/dev/null; then
            echo -e "${GREEN}✓${NC} $service (enabled and active)"
            INSTALLED=$((INSTALLED + 1))
        else
            echo -e "${YELLOW}!${NC} $service (enabled but not active)"
            WARNINGS=$((WARNINGS + 1))
        fi
    else
        echo -e "${RED}✗${NC} $service (not enabled)"
        MISSING=$((MISSING + 1))
    fi
}

# Function to check config files
check_config() {
    local config=$1
    TOTAL=$((TOTAL + 1))
    
    if [ -e "$HOME/$config" ]; then
        if [ -L "$HOME/$config" ]; then
            echo -e "${GREEN}✓${NC} $config (symlinked)"
        else
            echo -e "${GREEN}✓${NC} $config (exists)"
        fi
        INSTALLED=$((INSTALLED + 1))
    else
        echo -e "${RED}✗${NC} $config (missing)"
        MISSING=$((MISSING + 1))
    fi
}

echo -e "\n${PURPLE}[1/7] Core System Packages${NC}"
echo "================================"
check_package base-devel
check_package git
check_package wget
check_package curl
check_package zsh
check_package neovim
check_package tmux
check_package stow

echo -e "\n${PURPLE}[2/7] Window Manager & Desktop${NC}"
echo "================================"
check_package hyprland
check_package waybar
check_package rofi-wayland
check_package mako
check_package sddm
check_package ghostty
check_package pipewire
check_package wireplumber

echo -e "\n${PURPLE}[3/7] Development Tools${NC}"
echo "================================"
check_command claude command
check_command nvm command
check_command node command
check_command npm command
check_command pnpm command
check_command yarn command
check_command python command
check_command pipx command
check_command poetry command
check_command gh command

echo -e "\n${PURPLE}[4/7] CLI Tools${NC}"
echo "================================"
check_command eza command
check_command bat command
check_command ripgrep command
check_command fzf command
check_command zoxide command
check_command lazygit command

echo -e "\n${PURPLE}[5/7] GUI Applications${NC}"
echo "================================"
check_package chromium
check_package visual-studio-code-bin
check_package slack-desktop
check_package spotify
check_package figma-linux-bin
check_package postman-bin

echo -e "\n${PURPLE}[6/7] System Services${NC}"
echo "================================"
check_service NetworkManager
check_service bluetooth
check_service sddm
check_service sshd

echo -e "\n${PURPLE}[7/7] Configuration Files${NC}"
echo "================================"
check_config .config/hypr
check_config .config/waybar
check_config .config/ghostty
check_config .config/nvim
check_config .zshrc
check_config .tmux.conf
check_config .gitconfig

# Summary
echo -e "\n${BLUE}╔════════════════════════════════════════╗${NC}"
echo -e "${BLUE}║            Summary Report              ║${NC}"
echo -e "${BLUE}╚════════════════════════════════════════╝${NC}"
echo
echo -e "Total checks:     ${TOTAL}"
echo -e "${GREEN}Installed:        ${INSTALLED}${NC}"
echo -e "${YELLOW}Warnings:         ${WARNINGS}${NC}"
echo -e "${RED}Missing:          ${MISSING}${NC}"
echo

# Calculate percentage
if [ $TOTAL -gt 0 ]; then
    PERCENTAGE=$((INSTALLED * 100 / TOTAL))
    echo -e "Installation:     ${PERCENTAGE}% complete"
    echo

    if [ $PERCENTAGE -eq 100 ]; then
        echo -e "${GREEN}✓ Perfect! Everything is installed correctly.${NC}"
    elif [ $PERCENTAGE -ge 90 ]; then
        echo -e "${GREEN}✓ Excellent! Most things are working.${NC}"
    elif [ $PERCENTAGE -ge 75 ]; then
        echo -e "${YELLOW}! Good, but some components are missing.${NC}"
    else
        echo -e "${RED}✗ Installation incomplete. Run ./install.sh again.${NC}"
    fi
fi

# Detailed report for missing items
if [ $MISSING -gt 0 ]; then
    echo -e "\n${YELLOW}Missing items might be:${NC}"
    echo "• Optional packages (can be skipped)"
    echo "• AUR packages (need manual confirmation)"
    echo "• Services not yet started"
    echo
    echo -e "${YELLOW}To fix, run:${NC} ./install.sh"
fi

# Quick fixes
if [ $WARNINGS -gt 0 ]; then
    echo -e "\n${YELLOW}Quick fixes for warnings:${NC}"
    if ! systemctl is-active --quiet sddm; then
        echo "• Start SDDM: sudo systemctl start sddm"
    fi
    if ! systemctl is-active --quiet bluetooth; then
        echo "• Start Bluetooth: sudo systemctl start bluetooth"
    fi
fi

# Test critical functionality
echo -e "\n${PURPLE}Testing Key Components${NC}"
echo "================================"

# Test Hyprland
if command -v Hyprland &> /dev/null; then
    echo -e "${GREEN}✓${NC} Hyprland binary found"
else
    echo -e "${RED}✗${NC} Hyprland binary not found"
fi

# Test Ghostty
if command -v ghostty &> /dev/null; then
    echo -e "${GREEN}✓${NC} Ghostty binary found"
else
    echo -e "${RED}✗${NC} Ghostty binary not found"
fi

# Test shell
if [ "$SHELL" == "$(which zsh)" ]; then
    echo -e "${GREEN}✓${NC} Zsh is default shell"
else
    echo -e "${YELLOW}!${NC} Default shell is $SHELL (not zsh)"
fi

# Test display manager
if [ -f /usr/share/wayland-sessions/hyprland.desktop ]; then
    echo -e "${GREEN}✓${NC} Hyprland session available in SDDM"
else
    echo -e "${RED}✗${NC} Hyprland session not available in SDDM"
fi

echo -e "\n${BLUE}Run this script anytime to verify your installation!${NC}"