# macOS Migration Guide: Achieving Platform Parity

## Overview
This guide helps you migrate your macOS dotfiles setup to achieve full parity with the Arch Linux installation, including performance optimizations.

## Quick Migration Steps

### 1. Back up your current configuration
```bash
# Create a backup directory
mkdir -p ~/dotfiles-backup-$(date +%Y%m%d)

# Backup important files
cp -r ~/.zshrc ~/.oh-my-zsh ~/.config ~/dotfiles-backup-$(date +%Y%m%d)/
```

### 2. Install fnm (Fast Node Manager)
If you're currently using NVM:
```bash
# Install fnm via Homebrew
brew install fnm

# Add to your shell (will be done by installer)
echo 'eval "$(fnm env --use-on-cd)"' >> ~/.zshrc

# Migrate from nvm
fnm install $(nvm current)
fnm default $(nvm current)
```

### 3. Install missing CLI tools
```bash
# Install tools that were missing from macOS installer
brew install bc unzip openssh ncdu duf tldr eza zoxide direnv thefuck httpie glow ranger neofetch
```

### 4. Run the fixed installer
```bash
cd ~/.dotfiles
./install-macos-fixed.sh
```

## Key Changes in Fixed Installer

### 1. Node.js Management
- **Old**: NVM (slow startup, ~500ms overhead)
- **New**: fnm (fast startup, ~10ms overhead)
- **Benefit**: 50x faster shell startup

### 2. Additional Packages
Added to match Arch Linux:
- `bc` - Command line calculator
- `unzip` - Archive extraction
- `ncdu` - NCurses disk usage analyzer
- `duf` - Modern df replacement
- `tldr` - Simplified man pages
- `eza` - Modern ls replacement
- `zoxide` - Smart cd replacement
- `direnv` - Directory-based environments
- `thefuck` - Command correction
- `httpie` - Modern curl replacement
- `glow` - Markdown renderer
- `ranger` - Terminal file manager
- `neofetch` - System info display

### 3. Shell Performance
- Added zsh compilation step
- Uses fast-syntax-highlighting instead of standard
- Compiles .zshrc, .p10k.zsh, and oh-my-zsh.sh
- Result: <100ms terminal startup time

### 4. Consistent Git Delta
- Ensured git-delta is installed in base packages
- No longer relies on conditional installation

## Performance Verification

After migration, test your shell startup time:
```bash
# Test shell startup time
time zsh -i -c exit

# Should see something like:
# real    0m0.095s  (Good!)
# Instead of:
# real    0m0.520s  (Slow with NVM)
```

## Troubleshooting

### If fnm doesn't work after installation:
```bash
# Manually add to PATH
export PATH="/Users/$USER/Library/Application Support/fnm:$PATH"
eval "$(fnm env --use-on-cd)"

# Reinstall Node
fnm install --lts
fnm use lts-latest
fnm default lts-latest
```

### If zsh compilation fails:
```bash
# Manually compile
zsh -c 'zcompile ~/.zshrc'
zsh -c 'zcompile ~/.p10k.zsh'
zsh -c 'zcompile ~/.oh-my-zsh/oh-my-zsh.sh'
```

### If packages fail to install:
```bash
# Update Homebrew and retry
brew update
brew upgrade
brew install [package-name]
```

## Validation Checklist

After migration, verify:

- [ ] fnm is installed and working: `fnm --version`
- [ ] Node.js is available: `node --version`
- [ ] All CLI tools installed: `which eza zoxide direnv`
- [ ] Shell starts quickly: `time zsh -i -c exit` < 100ms
- [ ] Git delta works: `git diff` shows colored output
- [ ] Ghostty terminal works with all keybindings
- [ ] Aerospace window manager configured correctly

## Rolling Back

If you need to revert:
```bash
# Restore from backup
cp -r ~/dotfiles-backup-*/. ~/

# Reinstall NVM if needed
curl -o- https://raw.githubusercontent.com/nvm-sh/nvm/v0.39.0/install.sh | bash
```

## Platform Parity Achieved

With these changes, your macOS environment will have:
- Same CLI tools as Arch Linux
- Same performance optimizations
- Same development workflow
- Same configuration files
- Different window manager (Aerospace vs Hyprland) - expected

The only remaining differences are platform-specific (window manager, system settings) which is expected and desired.