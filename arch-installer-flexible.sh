#!/bin/bash
# Flexible Arch Linux Installer
# Supports existing partitions, multi-disk, and resuming from any step

set -e

# Colors
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m'

# State file to track progress
STATE_FILE="/tmp/arch-install-state"

echo -e "${BLUE}╔════════════════════════════════════════╗${NC}"
echo -e "${BLUE}║  Arch Linux Flexible Installer         ║${NC}"
echo -e "${BLUE}╚════════════════════════════════════════╝${NC}"

# Load previous state if exists
if [ -f "$STATE_FILE" ]; then
    source "$STATE_FILE"
    echo -e "${GREEN}Found previous installation state${NC}"
fi

# Helper function to save state
save_state() {
    echo "export INSTALL_STEP=$1" > "$STATE_FILE"
    [ ! -z "$ROOT_PART" ] && echo "export ROOT_PART=$ROOT_PART" >> "$STATE_FILE"
    [ ! -z "$EFI_PART" ] && echo "export EFI_PART=$EFI_PART" >> "$STATE_FILE"
    [ ! -z "$SWAP_PART" ] && echo "export SWAP_PART=$SWAP_PART" >> "$STATE_FILE"
    [ ! -z "$BOOT_MODE" ] && echo "export BOOT_MODE=$BOOT_MODE" >> "$STATE_FILE"
    [ ! -z "$USERNAME" ] && echo "export USERNAME=$USERNAME" >> "$STATE_FILE"
    [ ! -z "$HOSTNAME" ] && echo "export HOSTNAME=$HOSTNAME" >> "$STATE_FILE"
}

# Check what's already done
check_status() {
    echo -e "\n${YELLOW}Checking system status...${NC}"
    
    # Check if we're in chroot
    if [ -f /etc/arch-release ] && [ ! -d /mnt/etc ]; then
        echo -e "${GREEN}✓ Running inside installed system${NC}"
        IN_CHROOT=true
    fi
    
    # Check if partitions are mounted
    if mountpoint -q /mnt; then
        echo -e "${GREEN}✓ Root partition mounted${NC}"
        ROOT_MOUNTED=true
    fi
    
    # Check if base system is installed
    if [ -f /mnt/etc/fstab ] || [ -f /etc/fstab ]; then
        echo -e "${GREEN}✓ Base system installed${NC}"
        BASE_INSTALLED=true
    fi
}

# Menu to select step
show_menu() {
    echo -e "\n${BLUE}Select step to start from:${NC}"
    echo "1) Check prerequisites"
    echo "2) Partition disk (skip if already done)"
    echo "3) Format partitions (skip if already done)"
    echo "4) Mount partitions"
    echo "5) Install base system"
    echo "6) Configure system (fstab, timezone, etc)"
    echo "7) Install bootloader"
    echo "8) Create user account"
    echo "9) Install essential packages"
    echo "0) Start from beginning"
    echo
    read -p "Choice [0-9]: " STEP_CHOICE
}

# Step 1: Prerequisites
step_prerequisites() {
    echo -e "\n${YELLOW}[Step 1] Checking prerequisites...${NC}"
    
    # Check UEFI/BIOS
    if [ -d /sys/firmware/efi/efivars ]; then
        BOOT_MODE="UEFI"
        echo -e "${GREEN}✓ UEFI mode detected${NC}"
    else
        BOOT_MODE="BIOS"
        echo -e "${YELLOW}⚠ BIOS mode detected${NC}"
    fi
    
    # Check internet
    if ping -c 1 google.com &> /dev/null; then
        echo -e "${GREEN}✓ Internet connected${NC}"
    else
        echo -e "${RED}✗ No internet connection${NC}"
        echo "Connect with: iwctl"
        exit 1
    fi
    
    # Update clock
    timedatectl set-ntp true
    echo -e "${GREEN}✓ System clock updated${NC}"
    
    save_state "prerequisites_done"
}

# Step 2: Disk selection and partitioning
step_partition() {
    echo -e "\n${YELLOW}[Step 2] Disk partitioning${NC}"
    
    # Show current disk layout
    echo -e "\n${BLUE}Current disk layout:${NC}"
    lsblk
    
    echo -e "\n${YELLOW}Options:${NC}"
    echo "1) Use existing partitions"
    echo "2) Auto-partition a disk (WARNING: will erase!)"
    echo "3) Manual partition (opens cfdisk)"
    echo "4) Skip (already partitioned)"
    read -p "Choice [1-4]: " PART_CHOICE
    
    case $PART_CHOICE in
        1)
            echo "Existing partitions will be used in next step"
            ;;
        2)
            echo -e "\n${YELLOW}Available disks:${NC}"
            lsblk -d -o NAME,SIZE,TYPE | grep disk
            read -p "Disk to partition (e.g., sda): " DISK
            DISK="/dev/$DISK"
            
            echo -e "${RED}WARNING: This will ERASE $DISK${NC}"
            read -p "Continue? (yes/no): " CONFIRM
            [ "$CONFIRM" != "yes" ] && exit 1
            
            # Auto partition based on UEFI/BIOS
            if [ "$BOOT_MODE" = "UEFI" ]; then
                parted "$DISK" --script mklabel gpt \
                    mkpart ESP fat32 1MiB 512MiB \
                    set 1 esp on \
                    mkpart primary linux-swap 512MiB 8.5GiB \
                    mkpart primary ext4 8.5GiB 100%
            else
                parted "$DISK" --script mklabel msdos \
                    mkpart primary ext4 1MiB -8GiB \
                    set 1 boot on \
                    mkpart primary linux-swap -8GiB 100%
            fi
            echo -e "${GREEN}✓ Disk partitioned${NC}"
            ;;
        3)
            read -p "Disk to partition manually (e.g., sda): " DISK
            cfdisk "/dev/$DISK"
            ;;
        4)
            echo "Skipping partition step"
            ;;
    esac
    
    save_state "partition_done"
}

# Step 3: Format partitions
step_format() {
    echo -e "\n${YELLOW}[Step 3] Format partitions${NC}"
    
    echo -e "\n${BLUE}Current partitions:${NC}"
    lsblk
    
    echo -e "\n${YELLOW}Select partitions to use:${NC}"
    
    # Root partition
    read -p "Root partition (e.g., sda2 or nvme0n1p2): " ROOT
    ROOT_PART="/dev/$ROOT"
    
    # Check if already formatted
    if blkid "$ROOT_PART" | grep -q 'TYPE="ext4"'; then
        echo -e "${YELLOW}Root partition already formatted as ext4${NC}"
        read -p "Format anyway? (y/n): " FORMAT_ROOT
    else
        FORMAT_ROOT="y"
    fi
    
    [ "$FORMAT_ROOT" = "y" ] && mkfs.ext4 "$ROOT_PART"
    
    # EFI partition (UEFI only)
    if [ "$BOOT_MODE" = "UEFI" ]; then
        read -p "EFI partition (e.g., sda1): " EFI
        EFI_PART="/dev/$EFI"
        
        if blkid "$EFI_PART" | grep -q 'TYPE="vfat"'; then
            echo -e "${YELLOW}EFI partition already formatted${NC}"
        else
            mkfs.fat -F32 "$EFI_PART"
        fi
    fi
    
    # Swap partition (optional)
    read -p "Swap partition (leave empty to skip): " SWAP
    if [ ! -z "$SWAP" ]; then
        SWAP_PART="/dev/$SWAP"
        if blkid "$SWAP_PART" | grep -q 'TYPE="swap"'; then
            echo -e "${YELLOW}Swap already formatted${NC}"
        else
            mkswap "$SWAP_PART"
        fi
    fi
    
    save_state "format_done"
}

# Step 4: Mount partitions
step_mount() {
    echo -e "\n${YELLOW}[Step 4] Mount partitions${NC}"
    
    # Check if already mounted
    if mountpoint -q /mnt; then
        echo -e "${YELLOW}Root already mounted${NC}"
        read -p "Unmount and remount? (y/n): " REMOUNT
        [ "$REMOUNT" = "y" ] && umount -R /mnt
    fi
    
    # Mount root
    if [ -z "$ROOT_PART" ]; then
        lsblk
        read -p "Root partition to mount (e.g., /dev/sda2): " ROOT_PART
    fi
    
    mount "$ROOT_PART" /mnt
    echo -e "${GREEN}✓ Root mounted${NC}"
    
    # Mount EFI
    if [ "$BOOT_MODE" = "UEFI" ]; then
        mkdir -p /mnt/boot/efi
        if [ -z "$EFI_PART" ]; then
            read -p "EFI partition to mount (e.g., /dev/sda1): " EFI_PART
        fi
        mount "$EFI_PART" /mnt/boot/efi
        echo -e "${GREEN}✓ EFI mounted${NC}"
    fi
    
    # Enable swap
    if [ ! -z "$SWAP_PART" ]; then
        swapon "$SWAP_PART" 2>/dev/null || echo "Swap already enabled"
        echo -e "${GREEN}✓ Swap enabled${NC}"
    fi
    
    save_state "mount_done"
}

# Step 5: Install base system
step_install_base() {
    echo -e "\n${YELLOW}[Step 5] Install base system${NC}"
    
    # Check if already installed
    if [ -f /mnt/bin/bash ]; then
        echo -e "${YELLOW}Base system already installed${NC}"
        read -p "Reinstall? (y/n): " REINSTALL
        [ "$REINSTALL" != "y" ] && return
    fi
    
    echo "Installing base packages..."
    pacstrap /mnt base linux linux-firmware base-devel \
        networkmanager vim nano sudo git \
        intel-ucode amd-ucode
    
    echo -e "${GREEN}✓ Base system installed${NC}"
    save_state "base_installed"
}

# Step 6: Configure system
step_configure() {
    echo -e "\n${YELLOW}[Step 6] Configure system${NC}"
    
    # Generate fstab
    if [ ! -f /mnt/etc/fstab ] || [ ! -s /mnt/etc/fstab ]; then
        genfstab -U /mnt >> /mnt/etc/fstab
        echo -e "${GREEN}✓ Generated fstab${NC}"
    else
        echo -e "${YELLOW}fstab already exists${NC}"
    fi
    
    # Create configuration script
    cat > /mnt/configure-system.sh << 'CONF_SCRIPT'
#!/bin/bash

# Colors
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m'

# Timezone
if [ ! -f /etc/localtime ]; then
    ln -sf /usr/share/zoneinfo/America/New_York /etc/localtime
    hwclock --systohc
    echo -e "${GREEN}✓ Timezone set${NC}"
fi

# Locale
if ! grep -q "en_US.UTF-8" /etc/locale.gen; then
    echo "en_US.UTF-8 UTF-8" >> /etc/locale.gen
    locale-gen
    echo "LANG=en_US.UTF-8" > /etc/locale.conf
    echo -e "${GREEN}✓ Locale configured${NC}"
fi

# Hostname
if [ ! -f /etc/hostname ] || [ ! -s /etc/hostname ]; then
    read -p "Enter hostname: " HOSTNAME
    echo "$HOSTNAME" > /etc/hostname
    cat > /etc/hosts << EOF
127.0.0.1   localhost
::1         localhost
127.0.1.1   $HOSTNAME.localdomain $HOSTNAME
EOF
    echo -e "${GREEN}✓ Hostname set${NC}"
fi

# Enable NetworkManager
systemctl enable NetworkManager 2>/dev/null
echo -e "${GREEN}✓ NetworkManager enabled${NC}"
CONF_SCRIPT
    
    chmod +x /mnt/configure-system.sh
    arch-chroot /mnt /configure-system.sh
    rm /mnt/configure-system.sh
    
    save_state "configure_done"
}

# Step 7: Install bootloader
step_bootloader() {
    echo -e "\n${YELLOW}[Step 7] Install bootloader${NC}"
    
    cat > /mnt/install-bootloader.sh << 'BOOT_SCRIPT'
#!/bin/bash

# Check if GRUB already installed
if command -v grub-install &> /dev/null; then
    echo "GRUB already installed"
    read -p "Reinstall? (y/n): " REINSTALL
    [ "$REINSTALL" != "y" ] && exit 0
fi

if [ -d /sys/firmware/efi/efivars ]; then
    pacman -S --noconfirm grub efibootmgr
    grub-install --target=x86_64-efi --efi-directory=/boot/efi --bootloader-id=GRUB
else
    pacman -S --noconfirm grub
    read -p "Disk for bootloader (e.g., /dev/sda): " DISK
    grub-install --target=i386-pc "$DISK"
fi

grub-mkconfig -o /boot/grub/grub.cfg
echo "✓ Bootloader installed"
BOOT_SCRIPT
    
    chmod +x /mnt/install-bootloader.sh
    arch-chroot /mnt /install-bootloader.sh
    rm /mnt/install-bootloader.sh
    
    save_state "bootloader_done"
}

# Step 8: Create user
step_user() {
    echo -e "\n${YELLOW}[Step 8] Create user account${NC}"
    
    cat > /mnt/create-user.sh << 'USER_SCRIPT'
#!/bin/bash

# Check if non-root user exists
if [ $(cat /etc/passwd | grep -v "root\|nobody\|systemd" | grep -c "/home") -gt 0 ]; then
    echo "User already exists:"
    cat /etc/passwd | grep "/home" | cut -d: -f1
    read -p "Create another user? (y/n): " CREATE
    [ "$CREATE" != "y" ] && exit 0
fi

# Set root password if not set
passwd -S root | grep -q "NP\|L" && passwd root

# Create user
read -p "Username: " USERNAME
useradd -m -G wheel -s /bin/bash "$USERNAME"
passwd "$USERNAME"

# Enable sudo
if ! grep -q "^%wheel ALL=(ALL:ALL) ALL" /etc/sudoers; then
    echo "%wheel ALL=(ALL:ALL) ALL" >> /etc/sudoers
fi

echo "✓ User $USERNAME created"
USER_SCRIPT
    
    chmod +x /mnt/create-user.sh
    arch-chroot /mnt /create-user.sh
    rm /mnt/create-user.sh
    
    save_state "user_done"
}

# Step 9: Essential packages
step_packages() {
    echo -e "\n${YELLOW}[Step 9] Install essential packages${NC}"
    
    cat > /mnt/install-packages.sh << 'PKG_SCRIPT'
#!/bin/bash

echo "Installing essential packages..."
pacman -S --needed --noconfirm \
    xorg-server xorg-xinit \
    pipewire pipewire-pulse pipewire-alsa pipewire-jack wireplumber \
    mesa vulkan-intel vulkan-radeon \
    ttf-liberation noto-fonts \
    firefox \
    openssh \
    man-db man-pages \
    htop neofetch \
    bash-completion

systemctl enable sshd

echo "✓ Essential packages installed"
echo
echo "Installation complete! Next steps:"
echo "1. Exit chroot: exit"
echo "2. Unmount: umount -R /mnt"
echo "3. Reboot: reboot"
echo "4. After reboot, clone dotfiles:"
echo "   git clone https://github.com/maxtechera/max-dotfiles.git"
echo "   cd max-dotfiles && ./install.sh"
PKG_SCRIPT
    
    chmod +x /mnt/install-packages.sh
    arch-chroot /mnt /install-packages.sh
    rm /mnt/install-packages.sh
    
    save_state "packages_done"
}

# Main execution
check_status

if [ -z "$STEP_CHOICE" ]; then
    show_menu
fi

case $STEP_CHOICE in
    0|1) step_prerequisites ;;&
    0|2) step_partition ;;&
    0|3) step_format ;;&
    0|4) step_mount ;;&
    0|5) step_install_base ;;&
    0|6) step_configure ;;&
    0|7) step_bootloader ;;&
    0|8) step_user ;;&
    0|9) step_packages ;;
    *) echo "Running from current step based on state..." ;;
esac

echo -e "\n${GREEN}╔════════════════════════════════════════╗${NC}"
echo -e "${GREEN}║        Process Complete!               ║${NC}"
echo -e "${GREEN}╚════════════════════════════════════════╝${NC}"