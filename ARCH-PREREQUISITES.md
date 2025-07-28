# Arch Linux Prerequisites

**IMPORTANT**: Complete these steps BEFORE running the install script!

## 1. Base Arch Installation

```bash
# During arch installation, ensure you have:
- Connected to internet (wifi-menu or ethernet)
- Created partitions (/, /boot/efi, swap)
- Installed base system: pacstrap /mnt base linux linux-firmware
- Generated fstab
- Set timezone: ln -sf /usr/share/zoneinfo/America/New_York /etc/localtime
- Set locale: echo "en_US.UTF-8 UTF-8" >> /etc/locale.gen && locale-gen
- Set hostname
- Set root password
- Installed bootloader (GRUB/systemd-boot)
```

## 2. First Boot Setup

```bash
# Enable network
systemctl enable --now NetworkManager

# Create your user
useradd -m -G wheel -s /bin/bash yourusername
passwd yourusername

# Enable sudo for wheel group
EDITOR=nano visudo
# Uncomment: %wheel ALL=(ALL:ALL) ALL

# Install essential packages
pacman -S base-devel git networkmanager sudo

# Logout and login as your user
```

## 3. GPU Drivers

### Intel
```bash
sudo pacman -S mesa vulkan-intel intel-media-driver
```

### AMD
```bash
sudo pacman -S mesa vulkan-radeon libva-mesa-driver
```

### NVIDIA
```bash
sudo pacman -S nvidia nvidia-utils nvidia-settings
# For Wayland support:
echo "options nvidia-drm modeset=1" | sudo tee /etc/modprobe.d/nvidia.conf
```

## 4. Enable Multilib (for 32-bit support)

```bash
sudo nano /etc/pacman.conf
# Uncomment:
# [multilib]
# Include = /etc/pacman.d/mirrorlist

sudo pacman -Sy
```

## 5. SSH Setup

```bash
# Generate SSH key for GitHub
ssh-keygen -t ed25519 -C "your_email@example.com"
eval "$(ssh-agent -s)"
ssh-add ~/.ssh/id_ed25519

# Copy this to GitHub:
cat ~/.ssh/id_ed25519.pub
```

Now you can run the install script!