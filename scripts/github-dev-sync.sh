#!/bin/bash
# GitHub-native project sync using gh CLI

DEV_DIR="$HOME/dev"
CACHE_FILE="$HOME/.github-repos-cache"

# Colors
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
PURPLE='\033[0;35m'
CYAN='\033[0;36m'
NC='\033[0m'

# Command mode
MODE="${1:-sync}"

# Show usage
usage() {
    echo -e "${BLUE}GitHub Dev Sync - Manage your local development repositories${NC}"
    echo
    echo -e "${YELLOW}Usage:${NC}"
    echo -e "  ${GREEN}dev-sync${NC}              - Sync all GitHub repos (clone missing, update existing)"
    echo -e "  ${GREEN}dev-sync discover${NC}     - Discover and organize existing local repos"
    echo -e "  ${GREEN}dev-sync update${NC}       - Only update existing local repos"
    echo -e "  ${GREEN}dev-sync status${NC}       - Show status of all local repos"
    echo -e "  ${GREEN}dev-sync help${NC}         - Show this help message"
    echo
    exit 0
}

# Ensure gh is installed
if ! command -v gh &> /dev/null; then
    echo -e "${RED}GitHub CLI (gh) not found. Install it first.${NC}"
    exit 1
fi

# Ensure authenticated
if ! gh auth status &> /dev/null; then
    echo -e "${YELLOW}Not authenticated with GitHub. Running 'gh auth login'...${NC}"
    gh auth login
fi

# Handle help
if [[ "$MODE" == "help" ]] || [[ "$MODE" == "--help" ]] || [[ "$MODE" == "-h" ]]; then
    usage
fi

# Function to determine local path from repo name
get_local_path() {
    local repo_name="$1"
    local owner=$(echo "$repo_name" | cut -d'/' -f1)
    local name=$(echo "$repo_name" | cut -d'/' -f2)
    
    # Custom path logic - adjust as needed
    case "$name" in
        *-experiments|*-exp|experiments-*)
            echo "experiments/$name"
            ;;
        *-work|work-*|*-client)
            echo "work/$name"
            ;;
        *-dotfiles|dotfiles*)
            echo "config/$name"
            ;;
        *)
            # Default: if it's your own repo, put in root, otherwise in forks/
            if [ "$owner" = "$(gh api user --jq .login)" ]; then
                echo "$name"
            else
                echo "forks/$owner/$name"
            fi
            ;;
    esac
}

# Discover mode - find local repos and organize them
if [[ "$MODE" == "discover" ]]; then
    echo -e "${BLUE}Discovering local repositories in $DEV_DIR...${NC}"
    
    # Find all git repos
    local_repos=()
    while IFS= read -r gitdir; do
        repo_dir=$(dirname "$gitdir")
        local_repos+=("$repo_dir")
    done < <(find "$DEV_DIR" -name .git -type d -prune 2>/dev/null | sort)
    
    echo -e "${GREEN}Found ${#local_repos[@]} local repositories${NC}"
    
    # Get GitHub repos for matching
    echo -e "${BLUE}Fetching your GitHub repositories...${NC}"
    gh repo list --limit 1000 --json nameWithOwner,sshUrl,isArchived,isFork,defaultBranchRef | \
        jq -r '.[] | select(.isArchived == false) | "\(.nameWithOwner)|\(.sshUrl)|\(.defaultBranchRef.name)"' > "$CACHE_FILE"
    
    # Process each local repo
    echo -e "\n${YELLOW}Local Repository Status:${NC}"
    for repo_path in "${local_repos[@]}"; do
        cd "$repo_path"
        rel_path="${repo_path#$DEV_DIR/}"
        
        # Get remote URL
        remote_url=$(git config --get remote.origin.url 2>/dev/null || echo "no-remote")
        
        # Check if it's a GitHub repo
        if [[ "$remote_url" == *"github.com"* ]]; then
            # Extract owner/repo from URL
            if [[ "$remote_url" =~ github\.com[:/]([^/]+/[^/]+)(\.git)?$ ]]; then
                github_repo="${BASH_REMATCH[1]}"
                github_repo="${github_repo%.git}"
                
                # Check if in our GitHub repos
                if grep -q "^$github_repo|" "$CACHE_FILE"; then
                    echo -e "  ${GREEN}✓${NC} $rel_path ${CYAN}→ $github_repo${NC}"
                    
                    # Get suggested path
                    suggested_path=$(get_local_path "$github_repo")
                    if [[ "$rel_path" != "$suggested_path" ]]; then
                        echo -e "    ${YELLOW}! Consider moving to: $suggested_path${NC}"
                    fi
                else
                    echo -e "  ${YELLOW}?${NC} $rel_path ${CYAN}→ $github_repo${NC} ${YELLOW}(not in your GitHub account)${NC}"
                fi
            else
                echo -e "  ${PURPLE}●${NC} $rel_path ${CYAN}→ GitHub (couldn't parse URL)${NC}"
            fi
        else
            echo -e "  ${PURPLE}○${NC} $rel_path ${CYAN}→ ${remote_url:-no remote}${NC}"
        fi
        
        # Check for uncommitted changes
        if [ -n "$(git status --porcelain 2>/dev/null)" ]; then
            echo -e "    ${YELLOW}⚠ Has uncommitted changes${NC}"
        fi
    done
    
    # Find GitHub repos not cloned locally
    echo -e "\n${YELLOW}GitHub repos not found locally:${NC}"
    missing_count=0
    while IFS='|' read -r repo_name ssh_url branch; do
        local_path=$(get_local_path "$repo_name")
        full_path="$DEV_DIR/$local_path"
        
        if [ ! -d "$full_path/.git" ]; then
            echo -e "  ${RED}✗${NC} $repo_name ${CYAN}→ would be at: $local_path${NC}"
            ((missing_count++))
        fi
    done < "$CACHE_FILE"
    
    if [ $missing_count -eq 0 ]; then
        echo -e "  ${GREEN}All GitHub repos are cloned locally!${NC}"
    else
        echo -e "\n${YELLOW}Run '${GREEN}dev-sync${YELLOW}' to clone missing repos${NC}"
    fi
    
    exit 0
fi

# Status mode - show quick status of all repos
if [[ "$MODE" == "status" ]]; then
    echo -e "${BLUE}Repository Status Summary${NC}"
    echo
    
    # Count repos
    total_repos=$(find "$DEV_DIR" -name .git -type d -prune 2>/dev/null | wc -l)
    echo -e "${GREEN}Local repositories:${NC} $total_repos"
    
    # Check for uncommitted changes
    echo -e "\n${YELLOW}Repos with uncommitted changes:${NC}"
    uncommitted=0
    find "$DEV_DIR" -name .git -type d -prune | while read gitdir; do
        dir=$(dirname "$gitdir")
        cd "$dir"
        if [ -n "$(git status --porcelain 2>/dev/null)" ]; then
            rel_path="${dir#$DEV_DIR/}"
            echo -e "  ${YELLOW}●${NC} $rel_path"
            ((uncommitted++))
        fi
    done
    
    # Check for unpushed commits
    echo -e "\n${CYAN}Repos with unpushed commits:${NC}"
    find "$DEV_DIR" -name .git -type d -prune | while read gitdir; do
        dir=$(dirname "$gitdir")
        cd "$dir"
        if git status 2>/dev/null | grep -q "Your branch is ahead"; then
            rel_path="${dir#$DEV_DIR/}"
            ahead=$(git status | grep -oP "by \K\d+")
            echo -e "  ${CYAN}↑${NC} $rel_path (${ahead} commits)"
        fi
    done
    
    exit 0
fi

# Update mode - only update existing repos
if [[ "$MODE" == "update" ]]; then
    echo -e "${BLUE}Updating existing repositories only...${NC}"
    MODE="update-only"
fi

# Get all repos for sync/update
if [[ "$MODE" != "update-only" ]]; then
    echo -e "${BLUE}Fetching your GitHub repositories...${NC}"
fi

gh repo list --limit 1000 --json nameWithOwner,sshUrl,isArchived,isFork,defaultBranchRef | \
    jq -r '.[] | select(.isArchived == false) | "\(.nameWithOwner)|\(.sshUrl)|\(.defaultBranchRef.name)"' > "$CACHE_FILE"

# Sync each repository
while IFS='|' read -r repo_name ssh_url branch; do
    local_path=$(get_local_path "$repo_name")
    full_path="$DEV_DIR/$local_path"
    
    if [ -d "$full_path/.git" ]; then
        echo -e "${YELLOW}Updating $repo_name...${NC}"
        cd "$full_path"
        
        # Check for uncommitted changes
        if [ -n "$(git status --porcelain)" ]; then
            echo -e "  ${YELLOW}⚠ Has uncommitted changes, skipping pull${NC}"
        else
            git fetch --all --quiet
            git pull origin "$branch" --quiet
            echo -e "  ${GREEN}✓ Updated${NC}"
        fi
    else
        # Skip cloning in update-only mode
        if [[ "$MODE" == "update-only" ]]; then
            continue
        fi
        
        echo -e "${GREEN}Cloning $repo_name to $local_path...${NC}"
        mkdir -p "$(dirname "$full_path")"
        git clone -q "$ssh_url" "$full_path"
        echo -e "  ${GREEN}✓ Cloned${NC}"
    fi
done < "$CACHE_FILE"

# Summary
echo -e "\n${BLUE}Repository Summary:${NC}"
echo -e "Total repos on GitHub: $(wc -l < "$CACHE_FILE" | xargs)"
echo -e "Local repos synced: $(find "$DEV_DIR" -name .git -type d | wc -l | xargs)"

# Optional: Show repos with uncommitted changes
echo -e "\n${YELLOW}Repos with uncommitted changes:${NC}"
find "$DEV_DIR" -name .git -type d -prune | while read gitdir; do
    dir=$(dirname "$gitdir")
    cd "$dir"
    if [ -n "$(git status --porcelain)" ]; then
        rel_path="${dir#$DEV_DIR/}"
        echo -e "  ${YELLOW}●${NC} $rel_path"
    fi
done

# Create quick alias
echo -e "\n${GREEN}Add this to your .zshrc for quick access:${NC}"
echo "alias dev-sync='$0'"