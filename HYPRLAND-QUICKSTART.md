# Hyprland Quick Start Guide

## ⚠️ Important: Keybinding Conflicts

The current config uses **Alt** as the modifier (to match macOS), but this conflicts with many Linux apps!

### To Switch to Linux Standard Keys (Recommended):
```bash
~/max-dotfiles/scripts/switch-hypr-keys.sh
```
Choose option 2 for Super (Windows key) - the Linux standard.

## 🚨 Essential Key Bindings

### Window Management
- **Alt + Enter** - Open terminal (Ghostty)
- **Alt + Space** - Open app launcher (search for apps)
- **Alt + Shift + Q** - Close current window
- **Alt + F** - Toggle fullscreen

### Window Navigation
- **Alt + H/J/K/L** - Move focus between windows (vim-style)
- **Alt + Shift + H/J/K/L** - Move windows around

### Workspaces
- **Alt + [1-9]** - Switch to workspace 1-9
- **Alt + Tab** - Switch to previous workspace
- **Alt + Shift + [number]** - Move window to workspace

### Special Workspace Assignments
- **Alt + C** - Chrome workspace
- **Alt + S** - Slack workspace
- **Alt + M** - Messages (WhatsApp)
- **Alt + O** - Spotify

## 🔧 Opening System Settings

Since there's no traditional "Settings" app, use these:

### From Terminal (Alt + Enter):
```bash
# Network Settings
nm-connection-editor

# Audio Settings
pavucontrol

# Bluetooth Settings
blueman-manager

# Display Settings
wdisplays

# File Manager
thunar
```

### From App Launcher (Alt + Space):
Just type the app name:
- "pavucontrol" for audio
- "network" for network settings
- "bluetooth" for bluetooth
- "thunar" for files

## 🚨 If Waybar (Status Bar) is Missing

1. Open terminal: **Alt + Enter**
2. Run: `waybar &`
3. If that doesn't work, run the fix script:
   ```bash
   ~/max-dotfiles/scripts/fix-hyprland-setup.sh
   ```

## 📱 Quick Actions

### Volume Control
- Use media keys on your keyboard, OR
- Click volume in waybar, OR
- Run `pavucontrol`

### Screen Brightness
- Brightness keys on laptop, OR
- `brightnessctl s +10%` (increase)
- `brightnessctl s 10%-` (decrease)

### Screenshots
- **Print Screen** - Select area to screenshot
- **Shift + Print Screen** - Full screen screenshot
- **Ctrl + Print Screen** - Active window screenshot

### Lock Screen
- **Alt + L** (if configured), OR
- Run `swaylock`

### Logout/Shutdown
- **Alt + Shift + Ctrl + Q** - Exit Hyprland
- From terminal: `systemctl poweroff` or `reboot`

## 🔄 Reload Configuration

If you make changes to config files:
- **Hyprland**: No reload needed (auto-reloads)
- **Waybar**: `pkill waybar && waybar &`

## 🆘 Emergency Commands

If things go wrong:

```bash
# Restart waybar
pkill waybar && waybar &

# Check what's running
ps aux | grep -E "(waybar|mako|swww|polkit)"

# See Hyprland keybindings
cat ~/.config/hypr/hyprland.conf | grep bind

# Open this guide
cat ~/max-dotfiles/HYPRLAND-QUICKSTART.md
```

## 💡 Pro Tips

1. **Floating Windows**: Alt + Shift + F to toggle
2. **Resize Windows**: Alt + Right mouse drag
3. **Move Windows**: Alt + Left mouse drag
4. **Multiple Monitors**: Windows remember their workspace

## 🎯 First Things to Do

1. **Set Wallpaper**:
   ```bash
   swww img ~/Pictures/your-wallpaper.jpg
   ```

2. **Connect WiFi** (if needed):
   - Alt + Space → type "network" → Enter
   - OR: `nmtui` in terminal

3. **Adjust Audio**:
   - Alt + Space → type "pavucontrol" → Enter

4. **Install More Apps**:
   ```bash
   # Firefox
   sudo pacman -S firefox
   
   # Discord
   yay -S discord
   
   # VS Code (if not installed)
   yay -S visual-studio-code-bin
   ```

Remember: This is a tiling window manager - windows automatically arrange themselves. Embrace the keyboard-driven workflow!