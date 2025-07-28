# App Launcher Guide for Hyprland

## Quick Fix for Rofi Errors

Run this to install better launchers:
```bash
~/max-dotfiles/scripts/install-launchers.sh
```

## Available Launchers

### 1. **Wofi** (Recommended)
- Feature-rich like Rofi but built for Wayland
- Pretty UI with icons
- Keybind: `Alt/Super + Space`

### 2. **Fuzzel** (Minimal & Fast)
- Super lightweight
- No dependencies
- Keybind: `Alt/Super + D` (or `R` with Super)

### 3. **Tofi** (dmenu-style)
- Horizontal bar at top
- Very minimal

## What ThePrimeagen Uses

ThePrimeagen actually uses:
- **dmenu** - Ultra minimal
- **fzf** in terminal for file finding
- **telescope.nvim** in Neovim

For a similar minimal experience:
```bash
# Install dmenu for Wayland
yay -S dmenu-wayland

# Or use fuzzel (already installed)
```

## File Finding (ThePrimeagen Style)

For fuzzy file finding like ThePrimeagen:

### In Terminal:
```bash
# Install fd and fzf if not already
sudo pacman -S fd fzf

# Find files (add to ~/.zshrc)
alias ff='fd --type f --hidden --follow --exclude .git | fzf'

# Find and open in nvim
alias fv='nvim $(fd --type f --hidden --follow --exclude .git | fzf)'
```

### In Neovim:
You already have telescope.nvim! Use:
- `<leader>pf` - Find files
- `<leader>ps` - Grep search
- `<leader>pg` - Git files

## Keybindings After Fix

With **Alt** modifier:
- `Alt + Space` - App launcher (wofi)
- `Alt + D` - Minimal launcher (fuzzel)
- `Alt + W` - Window switcher

With **Super** modifier (if you switched):
- `Super + Space` - App launcher
- `Super + D` - App launcher
- `Super + R` - Minimal launcher
- `Super + Tab` - Window switcher

## If Launchers Still Don't Work

1. Check if they're installed:
   ```bash
   which wofi fuzzel
   ```

2. Run from terminal to see errors:
   ```bash
   wofi --show drun
   fuzzel
   ```

3. Make sure XDG_CURRENT_DESKTOP is set:
   ```bash
   echo $XDG_CURRENT_DESKTOP
   # Should show "Hyprland"
   ```

4. Update desktop files cache:
   ```bash
   update-desktop-database ~/.local/share/applications
   sudo update-desktop-database
   ```