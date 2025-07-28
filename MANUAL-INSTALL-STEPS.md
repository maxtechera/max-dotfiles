# Manual Arch Installation Steps

Quick reference for installing Arch manually or understanding what the installer does.

## Pre-Installation

### 1. Connect to Internet
```bash
# WiFi
iwctl
device list
station wlan0 connect "WiFi-Name"
exit

# Test
ping google.com
```

### 2. Update System Clock
```bash
timedatectl set-ntp true
```

## Disk Setup

### Option A: Use Existing Partitions
```bash
# List partitions
lsblk

# Example: Use existing
# /dev/sda1 - EFI (512MB)
# /dev/sda2 - Swap (8GB)  
# /dev/sda3 - Root (rest)
```

### Option B: Manual Partition
```bash
# For UEFI
cfdisk /dev/sda
# Create:
# 512MB EFI System
# 8GB Linux swap
# Rest Linux filesystem

# For BIOS
cfdisk /dev/sda
# Create:
# 8GB Linux swap
# Rest Linux filesystem (bootable)
```

### Format Partitions
```bash
# Root
mkfs.ext4 /dev/sda3

# EFI (UEFI only)
mkfs.fat -F32 /dev/sda1

# Swap
mkswap /dev/sda2
```

### Mount Partitions
```bash
# Root
mount /dev/sda3 /mnt

# EFI (UEFI only)
mkdir -p /mnt/boot/efi
mount /dev/sda1 /mnt/boot/efi

# Swap
swapon /dev/sda2
```

## Installation

### Install Base System
```bash
pacstrap /mnt base linux linux-firmware base-devel \
    networkmanager vim nano sudo git \
    intel-ucode amd-ucode
```

### Generate fstab
```bash
genfstab -U /mnt >> /mnt/etc/fstab
```

## Configure System

### Chroot
```bash
arch-chroot /mnt
```

### Timezone
```bash
ln -sf /usr/share/zoneinfo/America/New_York /etc/localtime
hwclock --systohc
```

### Localization
```bash
echo "en_US.UTF-8 UTF-8" >> /etc/locale.gen
locale-gen
echo "LANG=en_US.UTF-8" > /etc/locale.conf
```

### Network
```bash
echo "myhostname" > /etc/hostname

cat > /etc/hosts << EOF
127.0.0.1   localhost
::1         localhost
127.0.1.1   myhostname.localdomain myhostname
EOF

systemctl enable NetworkManager
```

### Root Password
```bash
passwd
```

### Bootloader

#### UEFI
```bash
pacman -S grub efibootmgr
grub-install --target=x86_64-efi --efi-directory=/boot/efi --bootloader-id=GRUB
grub-mkconfig -o /boot/grub/grub.cfg
```

#### BIOS
```bash
pacman -S grub
grub-install --target=i386-pc /dev/sda
grub-mkconfig -o /boot/grub/grub.cfg
```

### Create User
```bash
useradd -m -G wheel -s /bin/bash username
passwd username

# Enable sudo
EDITOR=nano visudo
# Uncomment: %wheel ALL=(ALL:ALL) ALL
```

### Essential Packages
```bash
pacman -S xorg-server pipewire pipewire-pulse \
    firefox openssh htop man-db man-pages
    
systemctl enable sshd
```

## Finish

### Exit and Reboot
```bash
exit
umount -R /mnt
reboot
```

## Post-Installation

### After reboot, login and:
```bash
# Connect to network
nmtui

# Clone dotfiles
git clone https://github.com/maxtechera/max-dotfiles.git
cd max-dotfiles
./install.sh
```

## Common Issues

### Wrong disk naming
- NVMe: `/dev/nvme0n1` with partitions `nvme0n1p1`, `nvme0n1p2`
- SATA: `/dev/sda` with partitions `sda1`, `sda2`

### GRUB not finding OS
```bash
# Regenerate config
grub-mkconfig -o /boot/grub/grub.cfg
```

### No internet after reboot
```bash
# Start NetworkManager manually
sudo systemctl start NetworkManager
nmtui
```