# Installing from Private Repo on Arch USB

Since your repo is private, you can't directly curl from it without authentication. Here are your options:

## Option 1: USB Transfer (Easiest)
1. Copy `arch-installer.sh` to a second USB drive
2. Mount it on the Arch system:
   ```bash
   mkdir /mnt/usb
   mount /dev/sdb1 /mnt/usb  # Replace sdb1 with your USB
   cp /mnt/usb/arch-installer.sh .
   chmod +x arch-installer.sh
   ./arch-installer.sh
   ```

## Option 2: Make Installer Public (Temporary)
1. Create a GitHub Gist with just the installer
2. Download from the gist URL
3. Delete gist after use

## Option 3: Manual Install First
Since the installer is just automating steps, you can:
1. Follow the [Arch Wiki Installation Guide](https://wiki.archlinux.org/title/Installation_guide)
2. After reboot, set up SSH and clone your private dotfiles

## Option 4: Type the Installer
The key parts you need:

```bash
# Quick partition (replace sdX with your disk)
parted /dev/sdX mklabel gpt
parted /dev/sdX mkpart ESP fat32 1MiB 512MiB
parted /dev/sdX set 1 esp on
parted /dev/sdX mkpart primary linux-swap 512MiB 8.5GiB
parted /dev/sdX mkpart primary ext4 8.5GiB 100%

# Format
mkfs.fat -F32 /dev/sdX1
mkswap /dev/sdX2
mkfs.ext4 /dev/sdX3

# Mount
mount /dev/sdX3 /mnt
mkdir -p /mnt/boot/efi
mount /dev/sdX1 /mnt/boot/efi
swapon /dev/sdX2

# Install base
pacstrap /mnt base linux linux-firmware base-devel networkmanager vim nano sudo git intel-ucode

# Continue with standard Arch install...
```

## After First Boot
Once you have Arch installed with git:
```bash
# Generate SSH key
ssh-keygen -t ed25519 -C "your_email"
cat ~/.ssh/id_ed25519.pub
# Add this key to GitHub

# Clone private repo
git clone git@github.com:maxtechera/max-dotfiles.git
cd max-dotfiles
./install.sh
```