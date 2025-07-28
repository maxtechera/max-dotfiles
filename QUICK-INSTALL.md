# Quick Install Guide - From USB to Desktop

## 🚀 Fastest Path to Working Arch + Dotfiles

### Step 1: Boot Arch USB
Boot from USB and select "Linux install medium 64"

### Step 2: Connect to Internet
```bash
# For Ethernet (usually automatic)
ping google.com

# For WiFi
iwctl
station wlan0 connect "YourWiFiName"
# Enter password
exit
```

### Step 3: Download and Run Installer
```bash
# Download the installer
curl -O https://raw.githubusercontent.com/[your-username]/arch-dotfiles/main/arch-installer.sh

# Make executable
chmod +x arch-installer.sh

# Run it!
./arch-installer.sh
```

**The installer will:**
- ✅ Detect UEFI/BIOS
- ✅ Partition your disk automatically
- ✅ Install base Arch system
- ✅ Configure bootloader
- ✅ Create your user account
- ✅ Set up networking

### Step 4: Reboot and Login
```bash
reboot
# Remove USB when prompted
# Login with your username
```

### Step 5: Connect to Internet Again
```bash
# Easy network UI
nmtui
# Select your network
```

### Step 6: Install Dotfiles
```bash
# Clone your dotfiles
git clone https://github.com/[your-username]/arch-dotfiles.git
cd arch-dotfiles

# Run the installer
./install.sh
```

### Step 7: Reboot to Glory
```bash
sudo reboot
```

**You'll see:**
- 🎨 Beautiful SDDM login screen
- 🪟 Select Hyprland
- 🚀 Enjoy your configured desktop!

## 📋 Total Commands Needed
From USB boot to working desktop:
```bash
# 1. Connect WiFi (if needed)
iwctl

# 2. Get installer
curl -O https://raw.githubusercontent.com/[your-username]/arch-dotfiles/main/arch-installer.sh
chmod +x arch-installer.sh
./arch-installer.sh

# 3. After reboot
nmtui
git clone https://github.com/[your-username]/arch-dotfiles.git
cd arch-dotfiles
./install.sh
sudo reboot
```

That's it! 7 commands total (excluding WiFi password).

## ⚡ Speed Run Times
- Base Arch install: ~10-15 minutes
- Dotfiles install: ~15-20 minutes
- **Total: ~30 minutes** from USB to configured desktop

## 🔧 What You Get
- Hyprland with your keybindings
- Ghostty terminal
- All your apps (VS Code, Slack, etc.)
- Same experience as your Mac!