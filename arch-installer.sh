#!/bin/bash
# Flexible Arch Linux Installer - Wizard Mode
# Automatically progresses through installation steps
# Supports existing partitions, multi-disk, and resuming from any step

set -e

# Colors
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
PURPLE='\033[0;35m'
NC='\033[0m'

# State file to track progress
STATE_FILE="/tmp/arch-install-state"

echo -e "${BLUE}╔════════════════════════════════════════╗${NC}"
echo -e "${BLUE}║  Arch Linux Installation Wizard        ║${NC}"
echo -e "${BLUE}╚════════════════════════════════════════╝${NC}"
echo

# Load previous state if exists
if [ -f "$STATE_FILE" ]; then
    source "$STATE_FILE"
    echo -e "${GREEN}✓ Found previous installation state${NC}"
    echo -e "${YELLOW}  Resuming from where you left off...${NC}"
    echo
fi

# Helper function to save state
save_state() {
    {
        echo "export CURRENT_STEP=$1"
        [ ! -z "$ROOT_PART" ] && echo "export ROOT_PART=$ROOT_PART"
        [ ! -z "$EFI_PART" ] && echo "export EFI_PART=$EFI_PART"
        [ ! -z "$SWAP_PART" ] && echo "export SWAP_PART=$SWAP_PART"
        [ ! -z "$BOOT_MODE" ] && echo "export BOOT_MODE=$BOOT_MODE"
        [ ! -z "$USERNAME" ] && echo "export USERNAME=$USERNAME"
        [ ! -z "$HOSTNAME" ] && echo "export HOSTNAME=$HOSTNAME"
    } > "$STATE_FILE"
}

# Progress bar
show_progress() {
    local current=$1
    local total=9
    local width=50
    local progress=$((current * width / total))
    
    echo -ne "\r${PURPLE}Progress: [${NC}"
    for ((i=0; i<width; i++)); do
        if [ $i -lt $progress ]; then
            echo -ne "${GREEN}#${NC}"
        else
            echo -ne "-"
        fi
    done
    echo -ne "${PURPLE}] $current/$total${NC}"
}

# Step 1: Prerequisites
step_prerequisites() {
    echo -e "\n${BLUE}[Step 1/9] Checking prerequisites...${NC}"
    
    # Check UEFI/BIOS
    if [ -d /sys/firmware/efi/efivars ]; then
        BOOT_MODE="UEFI"
        echo -e "${GREEN}✓ UEFI mode detected${NC}"
    else
        BOOT_MODE="BIOS"
        echo -e "${YELLOW}✓ BIOS mode detected${NC}"
    fi
    
    # Check internet
    echo -n "Checking internet connection... "
    if ping -c 1 google.com &> /dev/null; then
        echo -e "${GREEN}Connected${NC}"
    else
        echo -e "${RED}Failed${NC}"
        echo -e "\n${YELLOW}Please connect to internet first:${NC}"
        echo "1. For WiFi: iwctl"
        echo "2. For Ethernet: should work automatically"
        exit 1
    fi
    
    # Update clock
    echo -n "Updating system clock... "
    timedatectl set-ntp true
    echo -e "${GREEN}Done${NC}"
    
    save_state 1
    sleep 1
}

# Step 2: Disk detection and partitioning
step_partition() {
    echo -e "\n${BLUE}[Step 2/9] Disk partitioning${NC}"
    
    # Auto-detect if partitions exist
    echo "Analyzing disk layout..."
    echo
    lsblk -o NAME,SIZE,TYPE,FSTYPE,MOUNTPOINT
    echo
    
    # Check for existing Linux partitions
    if lsblk -o FSTYPE | grep -q "ext4"; then
        echo -e "${YELLOW}Found existing Linux partitions${NC}"
        read -p "Use existing partitions? (y/n) [y]: " USE_EXISTING
        USE_EXISTING=${USE_EXISTING:-y}
        
        if [ "$USE_EXISTING" = "y" ]; then
            save_state 2
            return
        fi
    fi
    
    # No existing partitions or user wants new ones
    echo -e "\n${YELLOW}Available disks:${NC}"
    lsblk -d -o NAME,SIZE,TYPE | grep disk
    echo
    
    read -p "Select disk to install (e.g., sda, nvme0n1): " DISK_NAME
    DISK="/dev/$DISK_NAME"
    
    # Confirm
    echo -e "\n${RED}WARNING: This will ERASE all data on ${DISK}${NC}"
    lsblk "$DISK"
    read -p "Continue? (type 'yes' to confirm): " CONFIRM
    
    if [ "$CONFIRM" != "yes" ]; then
        echo "Installation cancelled"
        exit 1
    fi
    
    echo "Partitioning disk..."
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
    save_state 2
    sleep 2
}

# Step 3: Format partitions
step_format() {
    echo -e "\n${BLUE}[Step 3/9] Formatting partitions${NC}"
    
    # Auto-detect partitions if not set
    if [ -z "$ROOT_PART" ]; then
        echo "Detecting partitions..."
        echo
        lsblk -o NAME,SIZE,FSTYPE,LABEL
        echo
        
        # Try to auto-detect root partition
        if [ "$BOOT_MODE" = "UEFI" ]; then
            # For UEFI, root is usually the largest ext4 or unformatted partition
            read -p "Root partition (e.g., sda3, nvme0n1p3): " ROOT_NAME
            ROOT_PART="/dev/$ROOT_NAME"
            
            read -p "EFI partition (e.g., sda1, nvme0n1p1): " EFI_NAME
            EFI_PART="/dev/$EFI_NAME"
            
            read -p "Swap partition (optional, press Enter to skip): " SWAP_NAME
            [ ! -z "$SWAP_NAME" ] && SWAP_PART="/dev/$SWAP_NAME"
        else
            # For BIOS
            read -p "Root partition (e.g., sda1): " ROOT_NAME
            ROOT_PART="/dev/$ROOT_NAME"
            
            read -p "Swap partition (optional): " SWAP_NAME
            [ ! -z "$SWAP_NAME" ] && SWAP_PART="/dev/$SWAP_NAME"
        fi
    fi
    
    # Format with progress
    echo -n "Formatting root partition... "
    if ! blkid "$ROOT_PART" | grep -q 'TYPE="ext4"'; then
        mkfs.ext4 -q "$ROOT_PART"
        echo -e "${GREEN}Done${NC}"
    else
        echo -e "${YELLOW}Already formatted${NC}"
    fi
    
    if [ "$BOOT_MODE" = "UEFI" ] && [ ! -z "$EFI_PART" ]; then
        echo -n "Formatting EFI partition... "
        if ! blkid "$EFI_PART" | grep -q 'TYPE="vfat"'; then
            mkfs.fat -F32 "$EFI_PART" 2>/dev/null
            echo -e "${GREEN}Done${NC}"
        else
            echo -e "${YELLOW}Already formatted${NC}"
        fi
    fi
    
    if [ ! -z "$SWAP_PART" ]; then
        echo -n "Setting up swap... "
        if ! blkid "$SWAP_PART" | grep -q 'TYPE="swap"'; then
            mkswap "$SWAP_PART" >/dev/null
            echo -e "${GREEN}Done${NC}"
        else
            echo -e "${YELLOW}Already formatted${NC}"
        fi
    fi
    
    save_state 3
    sleep 1
}

# Step 4: Mount partitions
step_mount() {
    echo -e "\n${BLUE}[Step 4/9] Mounting partitions${NC}"
    
    # Mount root
    echo -n "Mounting root partition... "
    if ! mountpoint -q /mnt; then
        mount "$ROOT_PART" /mnt
        echo -e "${GREEN}Done${NC}"
    else
        echo -e "${YELLOW}Already mounted${NC}"
    fi
    
    # Mount EFI
    if [ "$BOOT_MODE" = "UEFI" ] && [ ! -z "$EFI_PART" ]; then
        echo -n "Mounting EFI partition... "
        mkdir -p /mnt/boot/efi
        if ! mountpoint -q /mnt/boot/efi; then
            mount "$EFI_PART" /mnt/boot/efi
            echo -e "${GREEN}Done${NC}"
        else
            echo -e "${YELLOW}Already mounted${NC}"
        fi
    fi
    
    # Enable swap
    if [ ! -z "$SWAP_PART" ]; then
        echo -n "Enabling swap... "
        if ! swapon -s | grep -q "$SWAP_PART"; then
            swapon "$SWAP_PART"
            echo -e "${GREEN}Done${NC}"
        else
            echo -e "${YELLOW}Already enabled${NC}"
        fi
    fi
    
    save_state 4
    sleep 1
}

# Step 5: Install base system
step_install_base() {
    echo -e "\n${BLUE}[Step 5/9] Installing base system${NC}"
    echo "This will take a few minutes..."
    
    # Check if already installed
    if [ -f /mnt/bin/bash ]; then
        echo -e "${YELLOW}Base system already installed${NC}"
        save_state 5
        return
    fi
    
    # Install with progress indication
    echo "Installing essential packages..."
    pacstrap /mnt base linux linux-firmware base-devel \
        networkmanager vim nano sudo git \
        intel-ucode amd-ucode
    
    echo -e "${GREEN}✓ Base system installed${NC}"
    save_state 5
}

# Step 6: Configure system
step_configure() {
    echo -e "\n${BLUE}[Step 6/9] Configuring system${NC}"
    
    # Generate fstab
    echo -n "Generating fstab... "
    if [ ! -f /mnt/etc/fstab ] || [ ! -s /mnt/etc/fstab ]; then
        genfstab -U /mnt >> /mnt/etc/fstab
        echo -e "${GREEN}Done${NC}"
    else
        echo -e "${YELLOW}Already exists${NC}"
    fi
    
    # Configure in chroot
    cat > /mnt/configure-system.sh << 'CONF_SCRIPT'
#!/bin/bash
set -e

# Timezone
if [ ! -f /etc/localtime ]; then
    echo -n "Setting timezone... "
    ln -sf /usr/share/zoneinfo/America/New_York /etc/localtime
    hwclock --systohc
    echo "Done"
fi

# Locale
if ! grep -q "en_US.UTF-8" /etc/locale.gen; then
    echo -n "Configuring locale... "
    sed -i 's/#en_US.UTF-8/en_US.UTF-8/g' /etc/locale.gen
    locale-gen >/dev/null 2>&1
    echo "LANG=en_US.UTF-8" > /etc/locale.conf
    echo "Done"
fi

# Hostname
if [ ! -f /etc/hostname ] || [ ! -s /etc/hostname ]; then
    echo
    read -p "Enter hostname (e.g., archlinux): " HOSTNAME
    HOSTNAME=${HOSTNAME:-archlinux}
    echo "$HOSTNAME" > /etc/hostname
    cat > /etc/hosts << EOF
127.0.0.1   localhost
::1         localhost
127.0.1.1   $HOSTNAME.localdomain $HOSTNAME
EOF
    echo "Hostname set to: $HOSTNAME"
fi

# Enable services
systemctl enable NetworkManager >/dev/null 2>&1
echo "✓ System configured"
CONF_SCRIPT
    
    chmod +x /mnt/configure-system.sh
    arch-chroot /mnt /configure-system.sh
    rm /mnt/configure-system.sh
    
    save_state 6
    sleep 1
}

# Step 7: Install bootloader
step_bootloader() {
    echo -e "\n${BLUE}[Step 7/9] Installing bootloader${NC}"
    
    cat > /mnt/install-bootloader.sh << BOOT_SCRIPT
#!/bin/bash
set -e

# Check if GRUB already installed
if command -v grub-install &> /dev/null; then
    echo "GRUB already installed"
else
    echo -n "Installing GRUB... "
    if [ -d /sys/firmware/efi/efivars ]; then
        pacman -S --noconfirm grub efibootmgr >/dev/null 2>&1
        echo "Done"
        echo -n "Installing bootloader... "
        grub-install --target=x86_64-efi --efi-directory=/boot/efi --bootloader-id=GRUB >/dev/null 2>&1
    else
        pacman -S --noconfirm grub >/dev/null 2>&1
        echo "Done"
        echo "Installing bootloader to ${DISK}..."
        grub-install --target=i386-pc "$DISK" >/dev/null 2>&1
    fi
    echo "Done"
fi

echo -n "Generating GRUB config... "
grub-mkconfig -o /boot/grub/grub.cfg >/dev/null 2>&1
echo "Done"
echo "✓ Bootloader installed"
BOOT_SCRIPT
    
    # Pass DISK variable if set
    if [ ! -z "$DISK" ]; then
        sed -i "s|\$DISK|$DISK|g" /mnt/install-bootloader.sh
    else
        # Try to detect disk from ROOT_PART
        DISK=$(echo "$ROOT_PART" | sed 's/[0-9]*$//' | sed 's/p[0-9]*$//')
        sed -i "s|\$DISK|$DISK|g" /mnt/install-bootloader.sh
    fi
    
    chmod +x /mnt/install-bootloader.sh
    arch-chroot /mnt /install-bootloader.sh
    rm /mnt/install-bootloader.sh
    
    save_state 7
}

# Step 8: Create user
step_user() {
    echo -e "\n${BLUE}[Step 8/9] Creating user account${NC}"
    
    cat > /mnt/create-user.sh << 'USER_SCRIPT'
#!/bin/bash
set -e

# Check if user was created in previous run
if [ ! -z "$USERNAME" ] && id "$USERNAME" &>/dev/null; then
    echo "User $USERNAME already exists"
else
    # Root password
    echo
    echo "First, set the root password:"
    passwd root
    
    # Create user
    echo
    read -p "Enter username: " USERNAME
    USERNAME=${USERNAME:-user}
    
    useradd -m -G wheel -s /bin/bash "$USERNAME"
    echo
    echo "Set password for $USERNAME:"
    passwd "$USERNAME"
    
    # Save username for next steps
    echo "export USERNAME=$USERNAME" >> /tmp/user-created
fi

# Enable sudo
if ! grep -q "^%wheel ALL=(ALL:ALL) ALL" /etc/sudoers; then
    echo "%wheel ALL=(ALL:ALL) ALL" >> /etc/sudoers
fi

echo "✓ User configuration complete"
USER_SCRIPT
    
    chmod +x /mnt/create-user.sh
    arch-chroot /mnt /create-user.sh
    
    # Get username from chroot
    if [ -f /mnt/tmp/user-created ]; then
        source /mnt/tmp/user-created
        rm /mnt/tmp/user-created
    fi
    
    rm /mnt/create-user.sh
    save_state 8
}

# Step 9: Essential packages
step_packages() {
    echo -e "\n${BLUE}[Step 9/9] Installing essential packages${NC}"
    echo "This will take a few minutes..."
    
    cat > /mnt/install-packages.sh << 'PKG_SCRIPT'
#!/bin/bash
set -e

echo "Installing graphics and audio..."
pacman -S --needed --noconfirm \
    xorg-server xorg-xinit \
    pipewire pipewire-pulse pipewire-alsa pipewire-jack wireplumber \
    mesa vulkan-intel vulkan-radeon >/dev/null 2>&1

echo "Installing fonts and utilities..."
pacman -S --needed --noconfirm \
    ttf-liberation noto-fonts \
    firefox \
    openssh \
    man-db man-pages \
    htop neofetch \
    bash-completion >/dev/null 2>&1

systemctl enable sshd >/dev/null 2>&1

echo "✓ Essential packages installed"
PKG_SCRIPT
    
    chmod +x /mnt/install-packages.sh
    arch-chroot /mnt /install-packages.sh
    rm /mnt/install-packages.sh
    
    save_state 9
}

# Main wizard flow
main() {
    # Determine starting step
    CURRENT_STEP=${CURRENT_STEP:-0}
    
    echo -e "${PURPLE}Starting installation wizard...${NC}"
    echo -e "${YELLOW}The wizard will guide you through each step automatically.${NC}"
    echo -e "${YELLOW}You can restart at any time and it will resume where you left off.${NC}"
    echo
    
    # Run steps based on current progress
    if [ $CURRENT_STEP -lt 1 ]; then step_prerequisites; fi
    show_progress 1
    
    if [ $CURRENT_STEP -lt 2 ]; then step_partition; fi
    show_progress 2
    
    if [ $CURRENT_STEP -lt 3 ]; then step_format; fi
    show_progress 3
    
    if [ $CURRENT_STEP -lt 4 ]; then step_mount; fi
    show_progress 4
    
    if [ $CURRENT_STEP -lt 5 ]; then step_install_base; fi
    show_progress 5
    
    if [ $CURRENT_STEP -lt 6 ]; then step_configure; fi
    show_progress 6
    
    if [ $CURRENT_STEP -lt 7 ]; then step_bootloader; fi
    show_progress 7
    
    if [ $CURRENT_STEP -lt 8 ]; then step_user; fi
    show_progress 8
    
    if [ $CURRENT_STEP -lt 9 ]; then step_packages; fi
    show_progress 9
    
    # Installation complete
    echo -e "\n\n${GREEN}╔════════════════════════════════════════╗${NC}"
    echo -e "${GREEN}║     Installation Complete! 🎉          ║${NC}"
    echo -e "${GREEN}╚════════════════════════════════════════╝${NC}"
    
    echo -e "\n${YELLOW}Next steps:${NC}"
    echo "1. Exit chroot (if in chroot): exit"
    echo "2. Unmount partitions: umount -R /mnt"
    echo "3. Reboot: reboot"
    echo
    echo -e "${BLUE}After reboot:${NC}"
    echo "1. Login as: ${USERNAME:-your-user}"
    echo "2. Connect to internet: nmtui"
    echo "3. Clone dotfiles:"
    echo "   git clone https://github.com/maxtechera/max-dotfiles.git"
    echo "   cd max-dotfiles && ./install.sh"
    echo
    echo -e "${GREEN}Enjoy your new Arch Linux system!${NC}"
    
    # Clean up state file
    rm -f "$STATE_FILE"
}

# Run the wizard
main