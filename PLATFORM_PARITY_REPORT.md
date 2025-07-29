# Platform Parity Report: macOS vs Arch Linux

## Executive Summary
After analyzing the dotfiles repository, I've identified several key differences between the macOS and Arch Linux installations. While the core development environment is largely consistent, there are important gaps that need to be addressed for true platform parity.

## Critical Differences

### 1. Node.js Management
- **macOS**: Uses NVM (Node Version Manager) - slower startup
- **Arch Linux**: Uses fnm (Fast Node Manager) - 50x faster
- **Impact**: Shell startup times differ significantly between platforms
- **Fix**: Update macOS installer to use fnm instead of NVM

### 2. Window Management
- **macOS**: Uses Aerospace (tiling window manager)
- **Arch Linux**: Uses Hyprland (Wayland compositor)
- **Impact**: Different keybindings and configuration approaches
- **Fix**: Document keybinding differences, ensure muscle memory works across platforms

### 3. Package Installation
- **macOS**: Limited to Homebrew packages listed in script
- **Arch Linux**: More comprehensive package list including AUR packages
- **Impact**: Some tools may be missing on macOS
- **Fix**: Expand macOS package list to match Arch functionality

### 4. Terminal Performance
- **macOS**: No zsh compilation mentioned
- **Arch Linux**: Includes zsh file compilation for faster startup
- **Impact**: Terminal startup is slower on macOS
- **Fix**: Add zsh compilation to macOS installer

### 5. Git Delta Configuration
- **macOS**: Installs git-delta
- **Arch Linux**: Installs git-delta
- **Status**: ✓ Properly handled on both platforms

## Package Differences

### Missing from macOS installer:
```bash
# CLI tools
- bc (calculator)
- unzip
- openssh
- man-db/man-pages
- ncdu
- duf
- tldr
- eza
- zoxide
- direnv
- thefuck
- httpie
- glow
- ranger
- neofetch

# Development
- git-delta (partially handled in setup script)
```

### Missing from Arch installer:
```bash
# None - Arch installer is more comprehensive
```

## Configuration Differences

### 1. Shell Configuration
- **Issue**: macOS doesn't compile zsh files
- **Fix**: Add compilation step to macOS installer

### 2. fnm vs NVM
- **Issue**: Performance difference in Node.js management
- **Fix**: Standardize on fnm for both platforms

### 3. SSH Configuration
- **Issue**: Both platforms handle SSH key generation identically
- **Status**: ✓ No issues

### 4. Git Configuration
- **Issue**: Both use same setup script with OS detection
- **Status**: ✓ Properly cross-platform

## Recommendations

### Immediate Fixes

1. **Update macOS installer to use fnm**:
```bash
# Replace NVM installation with:
brew install fnm
echo 'eval "$(fnm env --use-on-cd)"' >> ~/.zshrc
```

2. **Add missing packages to macOS**:
```bash
brew install bc unzip openssh ncdu duf tldr eza zoxide direnv thefuck httpie glow ranger neofetch
```

3. **Add zsh compilation to macOS installer**:
```bash
# After Oh My Zsh installation
zsh -c 'zcompile ~/.zshrc'
zsh -c 'zcompile ~/.p10k.zsh'
```

4. **Ensure git-delta is in base packages**:
```bash
# Add to base brew install command
brew install git-delta
```

### Long-term Improvements

1. **Create unified package management**:
   - Expand `config/packages.yaml` to cover all packages
   - Create a unified installer that reads from this file
   - Ensure both platforms install identical tool sets

2. **Standardize keybindings documentation**:
   - Create a keybinding translation guide
   - Document Aerospace ↔ Hyprland equivalents
   - Ensure muscle memory works across platforms

3. **Performance optimization parity**:
   - Ensure both platforms use same shell optimizations
   - Standardize on fast tools (fnm, fast-syntax-highlighting, etc.)
   - Compile zsh files on both platforms

4. **Testing framework**:
   - Create automated tests for both platforms
   - Verify all tools are installed and accessible
   - Check shell startup performance

## Platform-Specific Code

### Handled Correctly:
- `scripts/setup-git-config.sh` - Uses OS detection
- `scripts/dev-sync.sh` - Detects platform for machine ID
- `ghostty/config` - Has platform-specific settings
- `.zshrc` - Handles both fnm and NVM fallback

### Needs Attention:
- Package installation lists
- Node.js manager choice
- Shell performance optimizations

## Conclusion

While the core development environment is largely consistent between platforms, there are important differences in:
1. Performance optimization (fnm vs NVM, zsh compilation)
2. Package completeness (macOS missing several CLI tools)
3. Window management approach (expected and acceptable)

With the recommended fixes, both platforms will provide an identical development experience with optimal performance.