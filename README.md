# Arch Linux Dotfiles

Modern, reproducible Arch Linux setup with Hyprland, Ghostty, and developer tools.

## Features

- **Window Manager**: Hyprland with smooth animations
- **Terminal**: Ghostty with Nord theme
- **Shell**: Zsh with Oh-My-Zsh
- **Editor**: Neovim with LazyVim
- **Multiplexer**: Tmux with sensible defaults
- **Tools**: Modern CLI replacements (eza, bat, ripgrep, fd, etc.)

## Installation

### 1. Install Base Arch Linux

Boot from Arch ISO and install the base system. Make sure you have:
- Base system installed
- User account created
- Network connectivity
- sudo configured

### 2. Clone This Repository

```bash
git clone https://github.com/yourusername/arch-dotfiles.git
cd arch-dotfiles
```

### 3. Run Installation Script

```bash
chmod +x install.sh
./install.sh
```

This will:
- Install all required packages
- Set up configuration files using GNU Stow
- Configure services
- Install AUR helper (yay)

### 4. Reboot and Start Hyprland

After installation:
1. Reboot your system
2. Login to TTY (Ctrl+Alt+F2)
3. Run: `Hyprland`

## Key Bindings

### Hyprland
- `Super + Enter` - Open Ghostty terminal
- `Super + D` - Open Rofi application launcher
- `Super + Q` - Close window
- `Super + M` - Exit Hyprland
- `Super + [1-9]` - Switch workspace
- `Super + Shift + [1-9]` - Move window to workspace
- `Super + S` - Screenshot selection
- `Super + [h,j,k,l]` - Move focus (vim-style)
- `Super + Shift + [h,j,k,l]` - Move window
- `Super + Ctrl + [h,j,k,l]` - Resize window

### Tmux
- `Ctrl + a` - Prefix key
- `Prefix + |` - Split vertical
- `Prefix + -` - Split horizontal
- `Prefix + [h,j,k,l]` - Navigate panes
- `Prefix + r` - Reload config

## Customization

### Wallpaper
Place your wallpaper at `~/Pictures/wallpaper.jpg`

### Git Configuration
Edit `git/.gitconfig` and update:
```bash
[user]
    name = Your Name
    email = your.email@example.com
```

### Additional Packages
Add more packages to `install.sh` as needed.

## Directory Structure

```
.
├── hypr/          # Hyprland configuration
├── waybar/        # Status bar configuration
├── rofi/          # Application launcher
├── ghostty/       # Terminal configuration
├── nvim/          # Neovim configuration
├── tmux/          # Tmux configuration
├── zsh/           # Zsh configuration
├── git/           # Git configuration
└── install.sh     # Installation script
```

## Troubleshooting

### Hyprland Won't Start
- Check logs: `journalctl -b -u seatd`
- Ensure your user is in the `video` group: `sudo usermod -aG video $USER`

### Audio Issues
- Check PipeWire status: `systemctl --user status pipewire`
- Use `pavucontrol` for audio management

### Ghostty Not Found
- Make sure AUR helper installed correctly
- Try manual installation: `yay -S ghostty-bin`

## Credits

Inspired by ThePrimagen's setup and the Arch Linux community.