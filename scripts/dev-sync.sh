#!/bin/bash
# Dev Sync - Discover, merge, and restore development repositories across machines
# Usage: dev-sync.sh [discover|restore|status|help]

# set -euo pipefail  # Temporarily disabled for debugging

# Colors
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m'

# Paths
DOTFILES_DIR="$HOME/.dotfiles"
DEV_DIR="$HOME/dev"
MAX_DEV_DIR="$DOTFILES_DIR/dev"
MANIFEST_FILE="$MAX_DEV_DIR/.dev-manifest.json"

# Get machine identifier
get_machine_id() {
    # Try different methods to get hostname
    local host_name=""
    
    if command -v hostname &> /dev/null; then
        host_name=$(hostname -s 2>/dev/null || hostname)
    elif [ -f /etc/hostname ]; then
        host_name=$(cat /etc/hostname)
    else
        host_name=$(uname -n)
    fi
    
    # Clean up hostname
    host_name=$(echo "$host_name" | tr -d '\n' | tr -cd '[:alnum:]-_')
    
    if [[ "$OSTYPE" == "darwin"* ]]; then
        echo "${host_name}-mac"
    elif [[ -n "${WSL_DISTRO_NAME:-}" ]]; then
        echo "${host_name}-wsl"
    else
        echo "${host_name}-$(uname -s | tr '[:upper:]' '[:lower:]')"
    fi
}

MACHINE_ID=$(get_machine_id)

# Logging functions
log_info() { echo -e "${BLUE}ℹ${NC} $1"; }
log_success() { echo -e "${GREEN}✓${NC} $1"; }
log_warning() { echo -e "${YELLOW}⚠${NC} $1"; }
log_error() { echo -e "${RED}✗${NC} $1"; }

# Check if we're in a git repository
is_git_repo() {
    local dir="$1"
    [[ -d "$dir/.git" ]] || git -C "$dir" rev-parse --git-dir &>/dev/null
}

# Get git remote URL
get_git_remote() {
    local dir="$1"
    git -C "$dir" remote get-url origin 2>/dev/null || echo ""
}

# Get current branch
get_git_branch() {
    local dir="$1"
    git -C "$dir" branch --show-current 2>/dev/null || echo "main"
}

# Get last commit hash
get_git_commit() {
    local dir="$1"
    git -C "$dir" rev-parse HEAD 2>/dev/null || echo ""
}

# Initialize manifest if it doesn't exist
init_manifest() {
    if [[ ! -f "$MANIFEST_FILE" ]]; then
        log_info "Creating new dev manifest"
        cat > "$MANIFEST_FILE" << EOF
{
  "version": "1.0",
  "last_sync": "$(date -u +%Y-%m-%dT%H:%M:%SZ)",
  "machine": "$MACHINE_ID",
  "repos": {}
}
EOF
    fi
}

# Discover repositories in ~/dev
discover_repos() {
    log_info "Discovering repositories in $DEV_DIR"
    
    if [[ ! -d "$DEV_DIR" ]]; then
        log_warning "~/dev directory doesn't exist, creating it"
        mkdir -p "$DEV_DIR"
        return 0
    fi
    
    init_manifest
    
    # Create temporary file for new manifest
    local temp_manifest=$(mktemp)
    local discovered_count=0
    
    # Load existing manifest
    local existing_repos=$(jq -r '.repos // {}' "$MANIFEST_FILE")
    
    # Start building new manifest
    jq -n \
        --arg version "1.0" \
        --arg last_sync "$(date -u +%Y-%m-%dT%H:%M:%SZ)" \
        --arg machine "$MACHINE_ID" \
        --argjson existing_repos "$existing_repos" \
        '{version: $version, last_sync: $last_sync, machine: $machine, repos: $existing_repos}' \
        > "$temp_manifest"
    
    # Find all git repositories
    while IFS= read -r -d '' git_dir; do
        # Get the repository directory (parent of .git)
        local repo_path=$(dirname "$git_dir")
        
        # Get relative path from ~/dev
        local rel_path="${repo_path#$DEV_DIR/}"
        
        # Skip if path is empty or just a dot
        [[ -z "$rel_path" || "$rel_path" == "." ]] && continue
        
        local remote_url=$(get_git_remote "$repo_path")
        local branch=$(get_git_branch "$repo_path")
        local last_commit=$(get_git_commit "$repo_path")
        
        if [[ -n "$remote_url" ]]; then
            log_info "Found: $rel_path ($remote_url)"
            
            # Add to manifest
            jq --arg path "$rel_path" \
               --arg url "$remote_url" \
               --arg branch "$branch" \
               --arg machine "$MACHINE_ID" \
               --arg commit "$last_commit" \
               '.repos[$path] = {url: $url, branch: $branch, added_by: $machine, last_commit: $commit, last_seen: (now | strftime("%Y-%m-%dT%H:%M:%SZ"))}' \
               "$temp_manifest" > "${temp_manifest}.tmp" && mv "${temp_manifest}.tmp" "$temp_manifest"
            
            ((discovered_count++))
        fi
    done < <(find "$DEV_DIR" -name ".git" -type d -print0)
    
    # Move temp manifest to final location
    mv "$temp_manifest" "$MANIFEST_FILE"
    
    log_success "Discovered $discovered_count repositories"
    log_info "Manifest updated: $MANIFEST_FILE"
}

# Restore repositories from manifest
restore_repos() {
    log_info "Restoring repositories from manifest"
    
    if [[ ! -f "$MANIFEST_FILE" ]]; then
        log_error "No manifest file found. Run 'dev-sync discover' first."
        exit 1
    fi
    
    # Ensure ~/dev exists
    mkdir -p "$DEV_DIR"
    
    local restored_count=0
    local failed_count=0
    
    # Read repos from manifest and clone them
    while IFS=$'\t' read -r repo_path repo_url repo_branch; do
        local target_dir="$DEV_DIR/$repo_path"
        local target_parent=$(dirname "$target_dir")
        
        # Create parent directory if needed
        mkdir -p "$target_parent"
        
        if [[ -d "$target_dir" ]]; then
            if is_git_repo "$target_dir"; then
                local existing_url=$(get_git_remote "$target_dir")
                if [[ "$existing_url" == "$repo_url" ]]; then
                    log_info "Already exists: $repo_path"
                    continue
                else
                    log_warning "URL mismatch for $repo_path:"
                    log_warning "  Expected: $repo_url"
                    log_warning "  Found: $existing_url"
                    continue
                fi
            else
                log_warning "Directory exists but is not a git repo: $repo_path"
                continue
            fi
        fi
        
        log_info "Cloning: $repo_path"
        if git clone "$repo_url" "$target_dir" &>/dev/null; then
            # Checkout the specified branch if it's not main/master
            if [[ "$repo_branch" != "main" && "$repo_branch" != "master" ]]; then
                if git -C "$target_dir" checkout "$repo_branch" &>/dev/null; then
                    log_success "Cloned $repo_path (branch: $repo_branch)"
                else
                    log_warning "Cloned $repo_path but couldn't checkout branch: $repo_branch"
                fi
            else
                log_success "Cloned: $repo_path"
            fi
            ((restored_count++))
        else
            log_error "Failed to clone: $repo_path"
            ((failed_count++))
        fi
        
    done < <(jq -r '.repos | to_entries[] | [.key, .value.url, .value.branch] | @tsv' "$MANIFEST_FILE")
    
    log_success "Restored $restored_count repositories"
    if [[ $failed_count -gt 0 ]]; then
        log_warning "$failed_count repositories failed to clone"
    fi
}

# Show status of tracked repositories
show_status() {
    log_info "Dev workspace status"
    
    if [[ ! -f "$MANIFEST_FILE" ]]; then
        log_warning "No manifest file found"
        return 0
    fi
    
    local tracked_count=$(jq '.repos | length' "$MANIFEST_FILE")
    local machine=$(jq -r '.machine' "$MANIFEST_FILE")
    local last_sync=$(jq -r '.last_sync' "$MANIFEST_FILE")
    
    echo
    echo "Manifest info:"
    echo "  Last sync: $last_sync"
    echo "  Last machine: $machine"
    echo "  Tracked repos: $tracked_count"
    echo
    
    if [[ $tracked_count -gt 0 ]]; then
        echo "Tracked repositories:"
        jq -r '.repos | to_entries[] | "  \(.key) - \(.value.url) (\(.value.branch))"' "$MANIFEST_FILE"
    fi
    
    echo
    if [[ -d "$DEV_DIR" ]]; then
        local local_repos=0
        while IFS= read -r -d '' repo_path; do
            ((local_repos++))
        done < <(find "$DEV_DIR" -name ".git" -type d -print0 2>/dev/null)
        echo "Local repositories: $local_repos"
    else
        echo "Local ~/dev directory: not found"
    fi
}

# Main function
main() {
    case "${1:-help}" in
        "discover")
            discover_repos
            log_info "Don't forget to commit and push the changes:"
            log_info "  cd ~/.dotfiles/dev && git add .dev-manifest.json && git commit -m 'Updated dev manifest from $MACHINE_ID' && git push"
            ;;
        "restore")
            restore_repos
            ;;
        "status")
            show_status
            ;;
        "help"|*)
            echo "Dev Sync - Manage development repositories across machines"
            echo
            echo "Usage: $0 [command]"
            echo
            echo "Commands:"
            echo "  discover  Scan ~/dev and update manifest with found repositories"
            echo "  restore   Clone all repositories from manifest to ~/dev"
            echo "  status    Show current status of tracked repositories"
            echo "  help      Show this help message"
            echo
            echo "Typical workflow:"
            echo "  1. On existing machine: ./dev-sync.sh discover"
            echo "  2. Commit and push changes"
            echo "  3. On new machine: ./dev-sync.sh restore"
            ;;
    esac
}

# Check dependencies
if ! command -v jq &> /dev/null; then
    log_error "jq is required but not installed. Please install jq first."
    exit 1
fi

main "$@"