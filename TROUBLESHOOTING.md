# Troubleshooting Guide

## Common Issues and Solutions

### Arch Linux

#### No Display After Install
```bash
# Check if SDDM is running
sudo systemctl status sddm

# If not, enable and start it
sudo systemctl enable --now sddm

# For NVIDIA users, check driver
nvidia-smi
```

#### No Audio
```bash
# Run the audio fix script
fix-audio

# Check PipeWire status
systemctl --user status pipewire pipewire-pulse

# List audio devices
wpctl status
```

#### Hyprland Won't Start
```bash
# Check logs
journalctl --user -u hyprland

# For NVIDIA, ensure modeset is enabled
cat /etc/modprobe.d/nvidia.conf
# Should contain: options nvidia-drm modeset=1
```

#### Ghostty Not Found
```bash
# Reinstall from AUR
yay -S ghostty-bin

# Or try the git version
yay -S ghostty-git
```

### macOS

#### Aerospace Not Working
1. Check System Preferences > Security & Privacy > Accessibility
2. Add Aerospace to allowed apps
3. Restart Aerospace: `killall AeroSpace && aerospace`

#### Homebrew Commands Not Found
```bash
# Add Homebrew to PATH (Apple Silicon)
echo 'eval "$(/opt/homebrew/bin/brew shellenv)"' >> ~/.zprofile
eval "$(/opt/homebrew/bin/brew shellenv)"

# Intel Macs
echo 'eval "$(/usr/local/bin/brew shellenv)"' >> ~/.zprofile
eval "$(/usr/local/bin/brew shellenv)"
```

#### NVM Not Loading
```bash
# Check if NVM is installed
ls -la ~/.nvm

# Reinstall if needed
curl -o- https://raw.githubusercontent.com/nvm-sh/nvm/v0.39.0/install.sh | bash
```

### Both Platforms

#### Git Push Fails (SSH)
```bash
# Test GitHub connection
ssh -T git@github.com

# If fails, check key is added
ssh-add -l

# Add key if needed
ssh-add ~/.ssh/id_ed25519
```

#### Tmux Plugins Not Installing
1. Open tmux
2. Press `Ctrl+Space` then `I` (capital i)
3. Wait for installation
4. Press `Ctrl+Space` then `r` to reload

#### Neovim Plugins Not Loading
```bash
# Clear and reinstall
rm -rf ~/.local/share/nvim
rm -rf ~/.cache/nvim
nvim # Let it reinstall
```

#### Scripts Not Found
```bash
# Check if /usr/local/bin is in PATH
echo $PATH

# Add to PATH if needed
export PATH="/usr/local/bin:$PATH"
```

## Quick Fixes

### Reset Configuration
```bash
# Backup current config
mv ~/.config ~/.config.backup

# Reinstall dotfiles
cd ~/arch-dotfiles
./install.sh
```

### Update Everything
```bash
# macOS
brew update && brew upgrade && brew cleanup

# Arch
yay -Syu --noconfirm
```

### Check Service Status
```bash
# Arch
systemctl --user status
sudo systemctl status

# Both
tmux list-sessions
aerospace list-workspaces # macOS only
```

## Getting Help

1. Check logs: `journalctl -xe`
2. Run commands with debug: `RUST_LOG=debug ghostty`
3. Check GitHub issues for the specific tool
4. Review the ARCH-PREREQUISITES.md for missing steps