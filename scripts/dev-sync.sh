#!/bin/bash
# Native git-based project sync solution

# Create a .dev-repos file in your home directory that lists all your repos
# Format: repo_url|local_path|branch(optional)

DEV_DIR="$HOME/dev"
REPOS_FILE="$HOME/.dev-repos"

# Colors
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
RED='\033[0;31m'
NC='\033[0m'

# Initialize dev directory
mkdir -p "$DEV_DIR"

# Create example repos file if it doesn't exist
if [ ! -f "$REPOS_FILE" ]; then
    cat > "$REPOS_FILE" << 'EOF'
# Format: repo_url|local_path|branch(optional)
# Example:
# git@github.com:username/project.git|experiments/project|main
# git@github.com:username/another.git|work/another
EOF
    echo -e "${YELLOW}Created $REPOS_FILE - add your repositories there${NC}"
    exit 0
fi

# Function to sync a single repo
sync_repo() {
    local repo_url="$1"
    local local_path="$2"
    local branch="${3:-main}"
    local full_path="$DEV_DIR/$local_path"
    
    if [ -d "$full_path/.git" ]; then
        echo -e "${YELLOW}Updating $local_path...${NC}"
        cd "$full_path"
        git fetch --all
        git pull origin "$branch"
    else
        echo -e "${GREEN}Cloning $repo_url to $local_path...${NC}"
        mkdir -p "$(dirname "$full_path")"
        git clone -b "$branch" "$repo_url" "$full_path"
    fi
}

# Read repos file and sync each
while IFS='|' read -r repo_url local_path branch || [ -n "$repo_url" ]; do
    # Skip comments and empty lines
    [[ "$repo_url" =~ ^#.*$ ]] || [ -z "$repo_url" ] && continue
    
    # Trim whitespace
    repo_url=$(echo "$repo_url" | xargs)
    local_path=$(echo "$local_path" | xargs)
    branch=$(echo "$branch" | xargs)
    
    sync_repo "$repo_url" "$local_path" "$branch"
done < "$REPOS_FILE"

echo -e "${GREEN}All repositories synced!${NC}"

# Show current status
echo -e "\n${GREEN}Current repositories:${NC}"
find "$DEV_DIR" -name .git -type d -prune | while read gitdir; do
    dir=$(dirname "$gitdir")
    cd "$dir"
    branch=$(git branch --show-current)
    status=$(git status --porcelain)
    rel_path="${dir#$DEV_DIR/}"
    
    if [ -n "$status" ]; then
        echo -e "  ${YELLOW}●${NC} $rel_path [$branch] - has uncommitted changes"
    else
        echo -e "  ${GREEN}●${NC} $rel_path [$branch]"
    fi
done