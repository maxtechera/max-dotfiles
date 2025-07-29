#!/bin/bash
# Script to set up max-dev as a private submodule

set -e

# Colors
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
RED='\033[0;31m'
NC='\033[0m'

echo -e "${YELLOW}Setting up max-dev as a private submodule${NC}"
echo -e "${YELLOW}Make sure you've created a PRIVATE repository called 'max-dev' on GitHub first!${NC}"
echo
read -p "Have you created the private max-dev repository? (y/n): " -n 1 -r
echo
if [[ ! $REPLY =~ ^[Yy]$ ]]; then
    echo -e "${RED}Please create the repository first at: https://github.com/new${NC}"
    echo "Make sure to:"
    echo "  - Name it 'max-dev'"
    echo "  - Set it as PRIVATE"
    echo "  - Don't initialize with README"
    exit 1
fi

# Get GitHub username
read -p "Enter your GitHub username: " GITHUB_USER

cd ~/.dotfiles

# Remove the old dev directory from git (already done, but just in case)
echo -e "${YELLOW}Removing dev from main repo...${NC}"
git rm -rf --cached dev/ 2>/dev/null || true

# Move current dev to temp location
echo -e "${YELLOW}Moving current dev directory...${NC}"
if [ -d "dev" ]; then
    mv dev dev-temp
fi

# Add as submodule
echo -e "${YELLOW}Adding max-dev as submodule...${NC}"
git submodule add "git@github.com:${GITHUB_USER}/max-dev.git" dev

# Copy the backup content to the new submodule
echo -e "${YELLOW}Restoring dev content...${NC}"
if [ -d "dev-temp" ]; then
    cp -r dev-temp/* dev/ 2>/dev/null || true
    cp -r dev-temp/.* dev/ 2>/dev/null || true
    rm -rf dev-temp
fi

# Initialize the submodule as a git repo and push
cd dev
git add .
git commit -m "Initial commit: dev workspace structure and manifest"
git branch -M main
git push -u origin main

# Go back to dotfiles
cd ..

# Commit the submodule addition
echo -e "${YELLOW}Updating dotfiles...${NC}"
git add .gitmodules dev .gitignore
git commit -m "Convert dev to private submodule"

echo -e "${GREEN}✓ Setup complete!${NC}"
echo
echo -e "${YELLOW}Next steps:${NC}"
echo "1. Push your dotfiles: git push"
echo "2. On other machines: git pull --recurse-submodules"
echo "3. Use 'dev-sync discover' to update the manifest"
echo "4. Always commit changes in both dev/ and dotfiles/"