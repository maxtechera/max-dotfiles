#!/bin/bash
# GitHub-native project sync using gh CLI

DEV_DIR="$HOME/dev"
CACHE_FILE="$HOME/.github-repos-cache"

# Colors
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m'

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

echo -e "${BLUE}Fetching your GitHub repositories...${NC}"

# Get all repos (including private ones)
gh repo list --limit 1000 --json nameWithOwner,sshUrl,isArchived,isFork,defaultBranchRef | \
    jq -r '.[] | select(.isArchived == false) | "\(.nameWithOwner)|\(.sshUrl)|\(.defaultBranchRef.name)"' > "$CACHE_FILE"

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