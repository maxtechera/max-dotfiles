# Unified Cross-Platform Dotfiles

This configuration provides an **identical experience** on both macOS and Arch Linux.

## 🎯 Key Features

### Identical on Both Platforms

1. **Window Management Keybindings**
   - `Alt + Enter` - Open Ghostty terminal
   - `Alt + h/j/k/l` - Navigate windows (vim-style)
   - `Alt + Shift + h/j/k/l` - Move windows
   - `Alt + [1-9,a-z]` - Switch workspaces
   - `Alt + f` - Fullscreen
   - `Alt + Tab` - Previous workspace
   - `Alt + -/=` - Resize windows

2. **Terminal Experience**
   - **Ghostty** with identical Nord theme
   - Same opacity and blur effects
   - Identical keybindings
   - `nvim-tab` script works the same way

3. **Development Environment**
   - Node.js via NVM (not system packages)
   - Python with pipx tools
   - Same Neovim config (ThePrimagen style)
   - Identical tmux setup
   - Same git aliases via Oh My Zsh

4. **Project Sync**
   - `dev-sync` command pulls all GitHub repos
   - Works identically on both platforms

## 🚀 Installation

### One Command Setup

```bash
# Clone the repo
git clone [your-repo-url] ~/dotfiles
cd ~/dotfiles

# Run universal installer
./install.sh
```

The installer automatically detects your OS and runs the appropriate setup.

### What Gets Installed

#### Both Platforms
- Ghostty terminal
- Neovim + LazyVim (ThePrimagen config)
- tmux with plugins
- Zsh + Oh My Zsh
- Git, GitHub CLI
- Modern CLI tools (ripgrep, fd, fzf, bat)
- NVM + Node.js LTS
- Python + pipx tools
- Custom scripts (nvim-tab, dev-sync)

#### macOS Specific
- Aerospace (tiling window manager)
- Homebrew packages
- macOS-specific font installation

#### Arch Linux Specific
- Hyprland (Wayland compositor)
- Audio stack (PipeWire)
- Waybar, Rofi, Mako
- Screenshot tools
- Full desktop environment

## 🎨 Window Management

### macOS: Aerospace
- Lightweight tiling window manager
- No gaps by default (matching your config)
- Automatic app → workspace assignment

### Arch Linux: Hyprland
- Wayland compositor with animations
- Matching keybindings to Aerospace
- Same workspace concepts (1-9, A-Z)

## 🔧 Configuration Files

```
.
├── aerospace/      # macOS window manager
├── hypr/           # Arch Linux compositor
├── ghostty/        # Terminal (both platforms)
├── nvim/           # Neovim config
├── tmux/           # Tmux config
├── zsh/            # Shell config
├── git/            # Git config
├── scripts/        # Custom scripts
└── config/         # Package mappings
```

## 📦 Key Differences Handled

1. **NVM Installation**
   - macOS: Uses Homebrew's NVM
   - Arch: Direct installation
   - Config detects and uses the right one

2. **Binary Locations**
   - Scripts use `/usr/local/bin` (works on both)
   - PATH configured appropriately

3. **Puppeteer/Chrome**
   - macOS: Uses Google Chrome.app
   - Arch: Uses chromium package

4. **Fonts**
   - macOS: Homebrew casks
   - Arch: pacman packages
   - Same fonts, different installation

## 🔄 Keeping in Sync

After initial setup on both machines:

```bash
# Pull latest dotfiles
cd ~/.dotfiles && git pull

# Re-run stow to update symlinks
stow -R ghostty nvim tmux zsh git

# Sync all development projects
dev-sync
```

## 💡 Tips

1. **Workspace Organization**
   - Use same workspace letters for same apps
   - B = Browser, S = Slack, etc.

2. **Terminal Multiplexing**
   - tmux config identical on both
   - Same prefix key (Ctrl+a)

3. **File Editing**
   - `nvt filename` opens in new Neovim tab
   - Works from Finder (macOS) or file managers (Linux)

## 🐛 Troubleshooting

### Ghostty not found
- macOS: Download from https://ghostty.org
- Arch: Install from AUR with `yay -S ghostty-bin`

### Aerospace not starting (macOS)
```bash
aerospace reload-config
```

### Hyprland not starting (Arch)
- Ensure you're in TTY (not X11)
- Check: `journalctl -xe | grep hypr`

### NVM not loading
- Restart terminal
- Check: `echo $NVM_DIR`
- Manually source: `source ~/.zshrc`