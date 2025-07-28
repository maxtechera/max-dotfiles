#!/bin/bash
# Arch Linux Complete Installer
# Run this from the Arch ISO live environment
# This will install Arch and configure everything automatically

set -e

# Colors
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m'

echo -e "${BLUE}╔════════════════════════════════════════╗${NC}"
echo -e "${BLUE}║    Arch Linux Automated Installer      ║${NC}"
echo -e "${BLUE}╚════════════════════════════════════════╝${NC}"

# Check if running in UEFI mode
if [ -d /sys/firmware/efi/efivars ]; then
    BOOT_MODE="UEFI"
    echo -e "${GREEN}✓ UEFI mode detected${NC}"
else
    BOOT_MODE="BIOS"
    echo -e "${YELLOW}⚠ BIOS mode detected${NC}"
fi

# Check internet connection
echo -e "\n${YELLOW}Checking internet connection...${NC}"
if ping -c 1 google.com &> /dev/null; then
    echo -e "${GREEN}✓ Internet connected${NC}"
else
    echo -e "${RED}✗ No internet connection${NC}"
    echo "Please connect to internet first:"
    echo "  For WiFi: iwctl"
    echo "  For Ethernet: should work automatically"
    exit 1
fi

# Update system clock
echo -e "\n${YELLOW}Updating system clock...${NC}"
timedatectl set-ntp true

# Disk selection
echo -e "\n${YELLOW}Available disks:${NC}"
lsblk -d -o NAME,SIZE,TYPE | grep disk

echo -e "\n${YELLOW}Select disk to install Arch (e.g., sda, nvme0n1):${NC}"
read -p "Disk: /dev/" DISK
DISK="/dev/${DISK}"

# Confirm disk selection
echo -e "\n${RED}WARNING: This will ERASE all data on ${DISK}${NC}"
lsblk "${DISK}"
read -p "Continue? (yes/no): " CONFIRM
if [ "$CONFIRM" != "yes" ]; then
    echo "Installation cancelled"
    exit 1
fi

# Partition the disk
echo -e "\n${YELLOW}Partitioning disk...${NC}"
if [ "$BOOT_MODE" = "UEFI" ]; then
    # UEFI partition scheme
    parted "${DISK}" --script mklabel gpt \
        mkpart ESP fat32 1MiB 512MiB \
        set 1 esp on \
        mkpart primary linux-swap 512MiB 8.5GiB \
        mkpart primary ext4 8.5GiB 100%
    
    # Format partitions
    if [[ "${DISK}" == *"nvme"* ]]; then
        mkfs.fat -F32 "${DISK}p1"
        mkswap "${DISK}p2"
        mkfs.ext4 "${DISK}p3"
        ROOT_PART="${DISK}p3"
        SWAP_PART="${DISK}p2"
        EFI_PART="${DISK}p1"
    else
        mkfs.fat -F32 "${DISK}1"
        mkswap "${DISK}2"
        mkfs.ext4 "${DISK}3"
        ROOT_PART="${DISK}3"
        SWAP_PART="${DISK}2"
        EFI_PART="${DISK}1"
    fi
else
    # BIOS partition scheme
    parted "${DISK}" --script mklabel msdos \
        mkpart primary linux-swap 1MiB 8GiB \
        mkpart primary ext4 8GiB 100% \
        set 2 boot on
    
    # Format partitions
    if [[ "${DISK}" == *"nvme"* ]]; then
        mkswap "${DISK}p1"
        mkfs.ext4 "${DISK}p2"
        ROOT_PART="${DISK}p2"
        SWAP_PART="${DISK}p1"
    else
        mkswap "${DISK}1"
        mkfs.ext4 "${DISK}2"
        ROOT_PART="${DISK}2"
        SWAP_PART="${DISK}1"
    fi
fi

# Mount partitions
echo -e "\n${YELLOW}Mounting partitions...${NC}"
mount "${ROOT_PART}" /mnt
swapon "${SWAP_PART}"

if [ "$BOOT_MODE" = "UEFI" ]; then
    mkdir -p /mnt/boot/efi
    mount "${EFI_PART}" /mnt/boot/efi
fi

# Install base system
echo -e "\n${YELLOW}Installing base system...${NC}"
pacstrap /mnt base linux linux-firmware base-devel \
    networkmanager vim nano sudo git \
    intel-ucode amd-ucode

# Generate fstab
echo -e "\n${YELLOW}Generating fstab...${NC}"
genfstab -U /mnt >> /mnt/etc/fstab

# Create chroot script
cat > /mnt/install-chroot.sh << 'CHROOT_SCRIPT'
#!/bin/bash

# Colors
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m'

# Set timezone
echo -e "${YELLOW}Setting timezone...${NC}"
ln -sf /usr/share/zoneinfo/America/New_York /etc/localtime
hwclock --systohc

# Localization
echo -e "${YELLOW}Setting locale...${NC}"
echo "en_US.UTF-8 UTF-8" >> /etc/locale.gen
locale-gen
echo "LANG=en_US.UTF-8" > /etc/locale.conf

# Network configuration
echo -e "${YELLOW}Configuring network...${NC}"
read -p "Enter hostname: " HOSTNAME
echo "$HOSTNAME" > /etc/hostname
cat > /etc/hosts << EOF
127.0.0.1   localhost
::1         localhost
127.0.1.1   $HOSTNAME.localdomain $HOSTNAME
EOF

# Enable NetworkManager
systemctl enable NetworkManager

# Set root password
echo -e "${YELLOW}Set root password:${NC}"
passwd

# Create user
echo -e "${YELLOW}Creating user account...${NC}"
read -p "Enter username: " USERNAME
useradd -m -G wheel -s /bin/bash "$USERNAME"
echo -e "${YELLOW}Set password for $USERNAME:${NC}"
passwd "$USERNAME"

# Enable sudo for wheel group
echo "%wheel ALL=(ALL:ALL) ALL" | tee -a /etc/sudoers

# Install bootloader
echo -e "${YELLOW}Installing bootloader...${NC}"
if [ -d /sys/firmware/efi/efivars ]; then
    # UEFI
    pacman -S --noconfirm grub efibootmgr
    grub-install --target=x86_64-efi --efi-directory=/boot/efi --bootloader-id=GRUB
else
    # BIOS
    pacman -S --noconfirm grub
    grub-install --target=i386-pc PLACEHOLDER_DISK
fi

# Configure GRUB
grub-mkconfig -o /boot/grub/grub.cfg

# Install essential packages
echo -e "${YELLOW}Installing essential packages...${NC}"
pacman -S --noconfirm \
    xorg-server xorg-xinit \
    pipewire pipewire-pulse pipewire-alsa pipewire-jack wireplumber \
    mesa vulkan-intel vulkan-radeon \
    ttf-liberation noto-fonts \
    firefox \
    openssh \
    man-db man-pages \
    htop neofetch \
    bash-completion

# Enable essential services
systemctl enable sshd

echo -e "${GREEN}Base installation complete!${NC}"
echo -e "${YELLOW}After reboot:${NC}"
echo "1. Login as $USERNAME"
echo "2. Connect to internet: nmtui or nmcli"
echo "3. Clone dotfiles: git clone https://github.com/maxtechera/max-dotfiles.git"
echo "4. Run: cd max-dotfiles && ./install.sh"
CHROOT_SCRIPT

# Replace disk placeholder
sed -i "s|PLACEHOLDER_DISK|${DISK}|g" /mnt/install-chroot.sh
chmod +x /mnt/install-chroot.sh

# Chroot and run script
echo -e "\n${YELLOW}Entering chroot environment...${NC}"
arch-chroot /mnt /install-chroot.sh

# Cleanup
rm /mnt/install-chroot.sh

# Unmount
echo -e "\n${YELLOW}Unmounting...${NC}"
umount -R /mnt
swapoff "${SWAP_PART}"

echo -e "\n${GREEN}╔════════════════════════════════════════╗${NC}"
echo -e "${GREEN}║     Installation Complete!             ║${NC}"
echo -e "${GREEN}╚════════════════════════════════════════╝${NC}"
echo -e "\n${YELLOW}Remove USB and type: ${NC}reboot"
echo -e "\n${BLUE}After reboot:${NC}"
echo "1. Login with your username"
echo "2. Connect to internet: nmtui"
echo "3. git clone https://github.com/maxtechera/max-dotfiles.git"
echo "4. cd max-dotfiles && ./install.sh"