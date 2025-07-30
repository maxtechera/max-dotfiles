#!/bin/bash
# Comprehensive backup script for dotfiles and configurations
# Can be run independently before any installation

set -e

# Colors
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
PURPLE='\033[0;35m'
NC='\033[0m'

# Parse command line arguments
BACKUP_DIR=""
INCLUDE_PACKAGES=true
VERBOSE=false

usage() {
    echo "Usage: $0 [OPTIONS]"
    echo "Backup existing configurations before dotfiles installation"
    echo
    echo "Options:"
    echo "  -d, --dir DIR        Backup directory (default: ~/.dotfiles-backup-TIMESTAMP)"
    echo "  -n, --no-packages    Don't backup package lists"
    echo "  -v, --verbose        Verbose output"
    echo "  -h, --help           Show this help message"
}

while [[ $# -gt 0 ]]; do
    case $1 in
        -d|--dir)
            BACKUP_DIR="$2"
            shift 2
            ;;
        -n|--no-packages)
            INCLUDE_PACKAGES=false
            shift
            ;;
        -v|--verbose)
            VERBOSE=true
            shift
            ;;
        -h|--help)
            usage
            exit 0
            ;;
        *)
            echo "Unknown option: $1"
            usage
            exit 1
            ;;
    esac
done

# Set default backup directory if not provided
if [ -z "$BACKUP_DIR" ]; then
    BACKUP_DIR="$HOME/.dotfiles-backup-$(date +%Y%m%d-%H%M%S)"
fi

echo -e "${BLUE}╔════════════════════════════════════════╗${NC}"
echo -e "${BLUE}║     Dotfiles Configuration Backup      ║${NC}"
echo -e "${BLUE}╚════════════════════════════════════════╝${NC}"
echo

# Create backup directory
mkdir -p "$BACKUP_DIR"

# Create backup log
BACKUP_LOG="$BACKUP_DIR/backup.log"
echo "Dotfiles Configuration Backup" > "$BACKUP_LOG"
echo "Date: $(date)" >> "$BACKUP_LOG"
echo "Hostname: $(hostname)" >> "$BACKUP_LOG"
echo "User: $USER" >> "$BACKUP_LOG"
echo "=========================" >> "$BACKUP_LOG"
echo >> "$BACKUP_LOG"

# Extended list of configs to backup
CONFIGS_TO_BACKUP=(
    # Window Manager configs
    ".config/hypr"
    ".config/waybar"
    ".config/fuzzel"
    ".config/mako"
    ".config/swaylock"
    ".config/wlogout"
    ".config/rofi"
    ".config/i3"
    ".config/sway"
    
    # Terminal configs
    ".config/ghostty"
    ".config/alacritty"
    ".config/kitty"
    ".config/wezterm"
    ".tmux.conf"
    ".tmux"
    
    # Editor configs
    ".config/nvim"
    ".vimrc"
    ".vim"
    ".config/Code/User/settings.json"
    ".config/Code/User/keybindings.json"
    
    # Shell configs
    ".zshrc"
    ".zshenv"
    ".zprofile"
    ".p10k.zsh"
    ".bashrc"
    ".bash_profile"
    ".profile"
    ".oh-my-zsh"
    
    # Development configs
    ".gitconfig"
    ".gitignore_global"
    ".ssh/config"
    ".ssh/known_hosts"
    ".nvm"
    ".fnm"
    ".cargo"
    ".rustup"
    
    # Desktop environment
    ".config/gtk-3.0"
    ".config/gtk-4.0"
    ".config/qt5ct"
    ".config/qt6ct"
    ".config/Trolltech.conf"
    ".gtkrc-2.0"
    ".icons"
    ".themes"
    
    # Application configs
    ".config/claude"
    ".config/discord"
    ".config/slack"
    ".config/spotify"
    
    # System configs
    ".config/fontconfig"
    ".config/systemd/user"
    ".local/share/applications"
    
    # Existing dotfiles
    ".dotfiles"
)

echo -e "${YELLOW}Backing up configurations to:${NC}"
echo -e "${BLUE}$BACKUP_DIR${NC}"
echo

# Backup function with progress
backup_config() {
    local config="$1"
    local src="$HOME/$config"
    
    if [ -e "$src" ]; then
        # Create parent directory in backup
        local parent_dir=$(dirname "$config")
        if [ "$parent_dir" != "." ]; then
            mkdir -p "$BACKUP_DIR/$parent_dir"
        fi
        
        # Check if it's a symlink
        if [ -L "$src" ]; then
            # For symlinks, copy both the link and what it points to
            local link_target=$(readlink -f "$src")
            if [ "$VERBOSE" = true ]; then
                echo -e "  ${BLUE}↗${NC} $config -> $link_target"
            fi
            
            # Copy the actual content
            if cp -rL "$src" "$BACKUP_DIR/$config" 2>/dev/null; then
                echo "Backed up (symlink): $config -> $link_target" >> "$BACKUP_LOG"
                return 0
            else
                echo "Failed (symlink): $config" >> "$BACKUP_LOG"
                return 1
            fi
        else
            # Regular file or directory
            if [ "$VERBOSE" = true ]; then
                echo -e "  ${GREEN}→${NC} $config"
            fi
            
            if cp -r "$src" "$BACKUP_DIR/$config" 2>/dev/null; then
                echo "Backed up: $config" >> "$BACKUP_LOG"
                return 0
            else
                echo "Failed: $config" >> "$BACKUP_LOG"
                return 1
            fi
        fi
    else
        return 2  # Not found
    fi
}

# Progress tracking
total=${#CONFIGS_TO_BACKUP[@]}
backed_up=0
failed=0
skipped=0

# Perform backups with progress bar
echo -e "${YELLOW}Backing up configurations...${NC}"
for i in "${!CONFIGS_TO_BACKUP[@]}"; do
    config="${CONFIGS_TO_BACKUP[$i]}"
    
    # Show progress
    if [ "$VERBOSE" = false ]; then
        printf "\r[%3d/%3d] %3d%% " $((i+1)) $total $(((i+1)*100/total))
    fi
    
    # Backup the config
    if backup_config "$config"; then
        ((backed_up++))
    else
        status=$?
        if [ $status -eq 1 ]; then
            ((failed++))
            if [ "$VERBOSE" = true ]; then
                echo -e "  ${RED}✗${NC} Failed: $config"
            fi
        else
            ((skipped++))
        fi
    fi
done

if [ "$VERBOSE" = false ]; then
    echo  # New line after progress bar
fi

# Backup package lists if requested
if [ "$INCLUDE_PACKAGES" = true ]; then
    echo -e "\n${YELLOW}Backing up package lists...${NC}"
    
    # Pacman packages
    if command -v pacman &> /dev/null; then
        pacman -Qqe > "$BACKUP_DIR/pacman-explicit.txt" 2>/dev/null && \
            echo -e "  ${GREEN}✓${NC} Pacman explicit packages"
        pacman -Qqm > "$BACKUP_DIR/pacman-foreign.txt" 2>/dev/null && \
            echo -e "  ${GREEN}✓${NC} Pacman foreign packages"
        pacman -Qqd > "$BACKUP_DIR/pacman-dependencies.txt" 2>/dev/null && \
            echo -e "  ${GREEN}✓${NC} Pacman dependencies"
    fi
    
    # AUR helper packages
    if command -v yay &> /dev/null; then
        yay -Qqe > "$BACKUP_DIR/yay-packages.txt" 2>/dev/null && \
            echo -e "  ${GREEN}✓${NC} Yay packages"
    elif command -v paru &> /dev/null; then
        paru -Qqe > "$BACKUP_DIR/paru-packages.txt" 2>/dev/null && \
            echo -e "  ${GREEN}✓${NC} Paru packages"
    fi
    
    # Flatpak packages
    if command -v flatpak &> /dev/null; then
        flatpak list --app --columns=application > "$BACKUP_DIR/flatpak-apps.txt" 2>/dev/null && \
            echo -e "  ${GREEN}✓${NC} Flatpak applications"
    fi
    
    # Snap packages
    if command -v snap &> /dev/null; then
        snap list > "$BACKUP_DIR/snap-packages.txt" 2>/dev/null && \
            echo -e "  ${GREEN}✓${NC} Snap packages"
    fi
    
    # Python packages
    if command -v pip &> /dev/null; then
        pip list --format=freeze > "$BACKUP_DIR/pip-packages.txt" 2>/dev/null && \
            echo -e "  ${GREEN}✓${NC} Python pip packages"
    fi
    
    # Node packages
    if command -v npm &> /dev/null; then
        npm list -g --depth=0 > "$BACKUP_DIR/npm-global-packages.txt" 2>/dev/null && \
            echo -e "  ${GREEN}✓${NC} NPM global packages"
    fi
fi

# Create system information file
echo -e "\n${YELLOW}Saving system information...${NC}"
cat > "$BACKUP_DIR/system-info.txt" << EOF
System Information
==================
Date: $(date)
Hostname: $(hostname)
User: $USER
OS: $(uname -o)
Kernel: $(uname -r)
Architecture: $(uname -m)

Distribution Info:
$(cat /etc/os-release 2>/dev/null || echo "Not available")

Shell: $SHELL
Terminal: $TERM

Display Server: ${XDG_SESSION_TYPE:-Unknown}
Desktop Environment: ${XDG_CURRENT_DESKTOP:-Unknown}
Session: ${XDG_SESSION_DESKTOP:-Unknown}
EOF

# Create restore script
cat > "$BACKUP_DIR/restore.sh" << 'RESTORE_SCRIPT'
#!/bin/bash
# Restore script for dotfiles backup

BACKUP_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
DRY_RUN=false
SELECTIVE=false

# Colors
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m'

usage() {
    echo "Usage: $0 [OPTIONS]"
    echo "Restore configurations from backup"
    echo
    echo "Options:"
    echo "  -s, --selective    Select individual items to restore"
    echo "  -d, --dry-run      Preview what would be restored"
    echo "  -h, --help         Show this help message"
}

while [[ $# -gt 0 ]]; do
    case $1 in
        -s|--selective)
            SELECTIVE=true
            shift
            ;;
        -d|--dry-run)
            DRY_RUN=true
            shift
            ;;
        -h|--help)
            usage
            exit 0
            ;;
        *)
            echo "Unknown option: $1"
            usage
            exit 1
            ;;
    esac
done

echo -e "${BLUE}Restore from: $BACKUP_DIR${NC}"
echo -e "${YELLOW}Backup date: $(head -2 "$BACKUP_DIR/backup.log" | tail -1)${NC}"
echo

if [ "$DRY_RUN" = true ]; then
    echo -e "${YELLOW}DRY RUN MODE - No changes will be made${NC}"
    echo
fi

# Build list of backed up configs
configs=()
while IFS= read -r line; do
    if [[ $line =~ ^"Backed up"( \(symlink\))?: (.+)( -> .+)?$ ]]; then
        config="${BASH_REMATCH[2]}"
        configs+=("$config")
    fi
done < "$BACKUP_DIR/backup.log"

# Selective restore
if [ "$SELECTIVE" = true ]; then
    echo "Select items to restore (y/n for each):"
    selected_configs=()
    for config in "${configs[@]}"; do
        read -p "  Restore $config? (y/n) [n]: " -n 1 -r REPLY
        REPLY=${REPLY:-n}
        echo
        if [[ $REPLY =~ ^[Yy]$ ]]; then
            selected_configs+=("$config")
        fi
    done
    configs=("${selected_configs[@]}")
fi

# Confirm restore
if [ "$DRY_RUN" = false ]; then
    echo -e "\n${YELLOW}Will restore ${#configs[@]} items${NC}"
    read -p "Continue? (y/n) [n]: " -n 1 -r REPLY
    echo
    if [[ ! $REPLY =~ ^[Yy]$ ]]; then
        echo "Restore cancelled"
        exit 1
    fi
fi

# Perform restore
restored=0
failed=0

for config in "${configs[@]}"; do
    src="$BACKUP_DIR/$config"
    dest="$HOME/$config"
    
    if [ -e "$src" ]; then
        if [ "$DRY_RUN" = true ]; then
            echo -e "[DRY RUN] Would restore: $config"
        else
            # Create parent directory
            parent_dir=$(dirname "$dest")
            mkdir -p "$parent_dir"
            
            # Backup current if exists
            if [ -e "$dest" ]; then
                mv "$dest" "$dest.pre-restore.$(date +%Y%m%d%H%M%S)"
            fi
            
            # Restore
            if cp -r "$src" "$dest" 2>/dev/null; then
                echo -e "${GREEN}✓${NC} Restored: $config"
                ((restored++))
            else
                echo -e "${RED}✗${NC} Failed: $config"
                ((failed++))
            fi
        fi
    fi
done

echo
if [ "$DRY_RUN" = false ]; then
    echo -e "${GREEN}Restored: $restored${NC}"
    if [ $failed -gt 0 ]; then
        echo -e "${RED}Failed: $failed${NC}"
    fi
else
    echo -e "${YELLOW}Dry run complete - no changes made${NC}"
fi
RESTORE_SCRIPT

chmod +x "$BACKUP_DIR/restore.sh"

# Summary in log
echo >> "$BACKUP_LOG"
echo "Summary:" >> "$BACKUP_LOG"
echo "  Total configs checked: $total" >> "$BACKUP_LOG"
echo "  Successfully backed up: $backed_up" >> "$BACKUP_LOG"
echo "  Failed: $failed" >> "$BACKUP_LOG"
echo "  Not found: $skipped" >> "$BACKUP_LOG"

# Display summary
echo
echo -e "${BLUE}╔════════════════════════════════════════╗${NC}"
echo -e "${BLUE}║           Backup Complete              ║${NC}"
echo -e "${BLUE}╚════════════════════════════════════════╝${NC}"
echo
echo -e "${GREEN}✓ Location:${NC} $BACKUP_DIR"
echo -e "${GREEN}✓ Configs backed up:${NC} $backed_up"
if [ $failed -gt 0 ]; then
    echo -e "${YELLOW}⚠ Failed:${NC} $failed"
fi
echo -e "${YELLOW}○ Not found:${NC} $skipped"
echo
echo -e "${YELLOW}To restore this backup:${NC}"
echo -e "  ${BLUE}$BACKUP_DIR/restore.sh${NC}"
echo -e "${YELLOW}To selectively restore:${NC}"
echo -e "  ${BLUE}$BACKUP_DIR/restore.sh --selective${NC}"
echo -e "${YELLOW}To preview restore:${NC}"
echo -e "  ${BLUE}$BACKUP_DIR/restore.sh --dry-run${NC}"

# Save backup location to a known file for easy reference
mkdir -p "$HOME/.config/dotfiles-backups"
echo "$BACKUP_DIR" >> "$HOME/.config/dotfiles-backups/backup-history.txt"

exit 0