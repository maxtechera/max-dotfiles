# Cross-Platform Dotfiles (macOS + Arch Linux)

A unified configuration that provides an identical command-line and window management experience across macOS and Arch Linux.

## 🚨 Quick Start - Fresh Arch Install

**From Arch USB → Working Desktop in ~30 minutes!**

### Option A: One-Command Setup (Recommended)
```bash
# After installing base Arch and connecting to WiFi, just run:
curl -sSL https://raw.githubusercontent.com/maxtechera/max-dotfiles/main/fresh-arch-setup.sh | bash
```

**💡 Speed Tips:**
- Add `--skip-aur` to skip AUR packages (saves 10-30 minutes)
- AUR packages compile from source, which is why they're slow
- You can install them later individually

### Option B: Modular Installation (NEW!)
```bash
# Clone the repo first
git clone https://github.com/maxtechera/max-dotfiles.git
cd max-dotfiles

# Choose your installation type:
./scripts/quick-install.sh minimal    # Just essentials (~5 min)
./scripts/quick-install.sh desktop    # Desktop environment (~15 min)
./scripts/quick-install.sh full       # Everything (~30 min)
./install-arch-modular.sh            # Interactive module selection
```

### Option C: Traditional Step-by-Step
```bash
# 1. Boot Arch USB and connect WiFi
iwctl  # or use ethernet

# 2. Run installation wizard
curl -O https://raw.githubusercontent.com/maxtechera/max-dotfiles/main/arch-installer.sh
chmod +x arch-installer.sh
./arch-installer.sh

# 3. Reboot, login, and install dotfiles
git clone https://github.com/maxtechera/max-dotfiles.git
cd max-dotfiles
./install.sh
```

The installer wizard handles everything: existing partitions, resuming from interruptions, and guides you step-by-step!

## 🎯 Goal

Create a seamless experience between macOS and Arch Linux with:
- Same terminal (Ghostty with FiraCode ligatures)
- Same window management keybindings (Aerospace/Hyprland)
- Same development tools (Node via NVM, Python via pipx)
- Same shell experience (Zsh + Oh My Zsh)
- Same editor (Neovim with ThePrimeagen config)

## 🚀 Quick Start - macOS

```bash
git clone https://github.com/maxtechera/max-dotfiles.git
cd max-dotfiles
./install.sh  # Auto-detects macOS and runs appropriate setup
```

## 📦 What Gets Installed

### CLI Tools (Both Platforms)
- **Terminal**: Ghostty with FiraCode font + ligatures
- **Shell**: Zsh with Oh My Zsh, autosuggestions, syntax highlighting
- **Editor**: Neovim with ThePrimeagen's config
- **AI Assistant**: Claude Code CLI for coding assistance + global Claude configuration
- **Dev Tools**: Git, tmux, lazygit, GitHub CLI
- **Modern Utils**: eza (ls), zoxide (cd), bat (cat), ripgrep, fzf
- **Languages**: Node.js (via NVM), Python (with pipx)
- **Package Managers**: pnpm, yarn, poetry

### GUI Applications
- **Browsers**: Google Chrome
- **Development**: VS Code, Postman
- **Design**: Figma
- **Communication**: Slack, Zoom
- **Media**: Spotify
- **Security**: 1Password + CLI

### Platform-Specific
- **macOS**: Aerospace (tiling window manager)
- **Arch**: Hyprland (Wayland compositor) + SDDM (login manager)

## ⌨️ Unified Keybindings

Both Aerospace (macOS) and Hyprland (Arch) use identical keybindings:

### Window Management
- `Alt + Enter` - Open Ghostty terminal
- `Alt + F` - Toggle fullscreen
- `Alt + H/J/K/L` - Focus windows (vim-style)
- `Alt + Shift + H/J/K/L` - Move windows
- `Alt + -/=` - Resize windows
- `Alt + Tab` - Previous workspace

### Workspace Navigation
- `Alt + [1-9]` - Switch to numbered workspace
- `Alt + [A-Z]` - Switch to lettered workspace
- `Alt + Shift + [1-9,A-Z]` - Move window to workspace

### Pre-assigned Workspaces
- `C` - Chrome
- `S` - Slack
- `M` - Messages/WhatsApp
- `F` - Figma
- `P` - Postman
- `O` - Spotify

## 🔧 Configuration Files

```
├── aerospace/     # macOS window manager
├── ghostty/        # Terminal emulator
├── hypr/           # Arch Linux compositor
├── nvim/           # Neovim config
├── tmux/           # Tmux config
├── zsh/            # Shell config
├── git/            # Git config
├── claude/         # Claude AI configuration
└── scripts/        # Helper scripts
    ├── nvim-tab              # Smart nvim/tmux integration
    └── github-dev-sync.sh    # Sync GitHub projects
```

## 🔄 Project Sync

Keep your ~/dev folder synchronized across devices:

```bash
# First time setup
dev-sync

# This will:
# 1. Clone all your GitHub repos
# 2. Organize by type (experiments/, work/, forks/)
# 3. Update existing repos
```

## 🎨 Visual Experience

### Arch Linux
- **Display Manager**: SDDM with Sugar Candy theme (beautiful login screen)
- **Compositor**: Hyprland with smooth animations
- **Bar**: Waybar with system info
- **Launcher**: Rofi for app launching
- **Notifications**: Mako

### macOS
- **Window Manager**: Aerospace (no gaps, clean tiling)
- **Terminal**: Ghostty (GPU-accelerated)
- **Font Rendering**: Matches Linux with ligatures enabled

## 🛠️ Post-Install

### Both Platforms
1. Restart terminal or run `source ~/.zshrc`
2. Install tmux plugins: Press `Ctrl+Space` then `I` in tmux
3. Install Neovim plugins: Open nvim and let it auto-install

### Arch Linux Specific
1. Reboot after installation
2. Login via SDDM (graphical login)
3. Hyprland starts automatically

### macOS Specific
1. Start Aerospace: `aerospace`
2. Grant accessibility permissions when prompted

## 📝 Customization

### Adding New Apps to Workspaces

Edit workspace assignments:
- **macOS**: `~/.aerospace.toml`
- **Arch**: `~/.config/hypr/hyprland.conf`

### Changing Keybindings

Both configs use the same keybinding structure, just update both files to keep them in sync.

## ✅ Verify Installation

After installation, verify everything is working:

```bash
# Run comprehensive verification
./verify-installation.sh

# Or test just Hyprland
./test-hyprland.sh
```

The verification script checks:
- All packages installed correctly
- Services are enabled
- Configuration files are in place
- Key binaries are available

## 🎯 Installation Methods

### 1. **Modular Installation** (Recommended for Control)
The new modular installer splits the setup into 20 small, independent modules:
- Each module can be run separately
- Skip modules you don't need
- Resume from where you left off
- No more big Y/N prompts for unrelated packages

```bash
./install-arch-modular.sh  # Interactive menu
```

### 2. **Quick Profiles**
Pre-configured installation profiles:
- `minimal` - CLI tools only (5 min)
- `desktop` - Hyprland desktop (15 min)
- `full` - Everything including AUR (30 min)

### 3. **Traditional All-in-One**
The original installer that does everything at once:
```bash
./install-arch.sh
```

## 🚨 Troubleshooting

See [TROUBLESHOOTING.md](TROUBLESHOOTING.md) for common issues and solutions.

### Quick Fixes
- **NVM/Node not found**: Run `source ~/.zshrc` or `./scripts/fix-nvm.sh`
- **Arch audio issues**: Run `fix-audio`
- **Git not configured**: Run `./scripts/setup-git-config.sh`
- **Aerospace not working**: Check System Preferences > Security & Privacy
- **Missing packages**: Run `./verify-installation.sh` to see what's missing

## 📖 Documentation

- [QUICK-INSTALL.md](QUICK-INSTALL.md) - Speed run guide
- [ARCH-PREREQUISITES.md](ARCH-PREREQUISITES.md) - Pre-install requirements
- [MANUAL-INSTALL-STEPS.md](MANUAL-INSTALL-STEPS.md) - Step-by-step manual installation
- [TROUBLESHOOTING.md](TROUBLESHOOTING.md) - Common issues and fixes

## 🔗 Credits

- Window Management inspired by ThePrimeagen's workflow
- Neovim config based on ThePrimeagen's setup
- Hyprland config optimized for productivity