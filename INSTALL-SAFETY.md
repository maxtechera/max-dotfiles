# Dotfiles Installation Safety Features

This document describes the safety features added to prevent accidental configuration overwrites during installation.

## Overview

The installation scripts have been enhanced with multiple safety mechanisms to protect your existing configurations:

1. **Comprehensive Backup System**
2. **Safe Stow Operations**
3. **Dry-Run Mode**
4. **Configuration Conflict Detection**
5. **Easy Recovery Options**

## Usage

### Safe Installation (Recommended)

```bash
./install-safe.sh
```

This wrapper script provides:
- System compatibility checks
- Automatic backup prompts
- Conflict detection
- Step-by-step confirmation

### Standard Installation with Options

```bash
./install-arch.sh [OPTIONS]

Options:
  --skip-backup    Skip creating backup (not recommended)
  --skip-aur       Skip AUR package installation
  --dry-run        Preview changes without making them
  --help           Show help message
```

### Modular Installation

For more control over the installation process:

```bash
./install-arch-modular.sh
```

This allows you to:
- Install components individually
- Skip specific modules
- Resume interrupted installations

## Safety Features

### 1. Comprehensive Backup

Before any changes are made, the installer can backup:
- All configuration directories (`~/.config/*`)
- Shell configurations (`.zshrc`, `.bashrc`, etc.)
- Git configuration
- SSH configuration
- Package lists
- System information

Backups are stored in timestamped directories: `~/.dotfiles-backup-YYYYMMDD-HHMMSS/`

### 2. Safe Stow Operations

The improved stow function:
- Checks if configs already exist
- Prompts before overwriting
- Creates backups of existing configs
- Handles symlink conflicts gracefully

### 3. Dry-Run Mode

Run with `--dry-run` to:
- See what would be installed
- Preview configuration changes
- Check for conflicts
- No changes are made

### 4. Configuration Protection

Specific protections added for:
- **Fuzzel config**: Prompts before overwriting, creates backup
- **Existing symlinks**: Detects and asks before replacing
- **Non-symlink configs**: Backs up before replacing

### 5. Recovery Options

Every backup includes a restore script:

```bash
~/.dotfiles-backup-*/restore.sh           # Full restore
~/.dotfiles-backup-*/restore.sh --dry-run # Preview restore
~/.dotfiles-backup-*/restore.sh --selective # Choose what to restore
```

## Standalone Tools

### Backup Script

Create a backup anytime:

```bash
./scripts/backup-configs.sh [OPTIONS]

Options:
  -d, --dir DIR        Backup directory
  -n, --no-packages    Don't backup package lists
  -v, --verbose        Verbose output
```

### Check System

Check compatibility without installing:

```bash
./install-safe.sh --check
```

## What Gets Backed Up

- Window manager configs (Hyprland, Waybar, etc.)
- Terminal configs (Ghostty, tmux, etc.)
- Editor configs (Neovim, VS Code)
- Shell configs (zsh, bash)
- Development configs (git, SSH)
- Desktop environment settings
- Application configs
- Package lists (pacman, AUR, npm, pip)

## Best Practices

1. **Always backup first** - Use the default backup option
2. **Use dry-run** - Preview changes with `--dry-run`
3. **Check conflicts** - Run `./install-safe.sh --check` first
4. **Keep backup location** - Note the backup directory path
5. **Test incrementally** - Use modular installer for step-by-step control

## Troubleshooting

### Installation Failed

1. Check the backup location (displayed during installation)
2. Run the restore script: `~/.dotfiles-backup-*/restore.sh`
3. Fix any issues
4. Try again with modular installer

### Stow Conflicts

If stow fails:
1. Check what exists: `ls -la ~/.config/[package]`
2. Manually backup if needed
3. Remove the conflicting file/directory
4. Re-run the installer

### Partial Installation

Use the modular installer to complete specific components:
```bash
./install-arch-modular.sh
# Select only the failed components
```

## Emergency Recovery

If something goes wrong:

1. **Restore from backup**:
   ```bash
   ~/.dotfiles-backup-*/restore.sh
   ```

2. **Manual recovery**:
   - Backups are simple copies in the backup directory
   - Manually copy back what you need

3. **Package lists**:
   - Reinstall packages from backed up lists
   - `pacman-explicit.txt`, `yay-packages.txt`, etc.

## Changes Made

### Modified Files

1. **install-arch.sh**
   - Added comprehensive backup function
   - Improved stow operations with conflict handling
   - Added dry-run mode support
   - Command line argument parsing

2. **cleanup-rofi.sh**
   - Fixed fuzzel config overwrite
   - Added backup before replacing configs

3. **install-arch-modular.sh**
   - Improved stow operations

### New Files

1. **install-safe.sh** - Safe installation wrapper
2. **scripts/backup-configs.sh** - Standalone backup tool
3. **INSTALL-SAFETY.md** - This documentation

## Summary

The installation process is now much safer with:
- ✅ Automatic backups before changes
- ✅ Confirmation prompts for overwrites
- ✅ Dry-run mode for previewing
- ✅ Easy recovery options
- ✅ Granular control with modular installer

Your existing configurations are protected, and you can always restore from backup if needed.