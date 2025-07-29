# Dev Sync Setup Guide

## Initial Setup (First Time)

### 1. Create the max-dev private repository on GitHub
```bash
# On GitHub, create a new PRIVATE repository called "max-dev"
# Don't initialize with README (we'll push our structure)
```

### 2. Initialize max-dev as a git repository
```bash
cd ~/.dotfiles/dev
git init
git add .
git commit -m "Initial max-dev structure"
git branch -M main
git remote add origin git@github.com:YOUR_USERNAME/max-dev.git
git push -u origin main
```

### 3. Add max-dev as a submodule to dotfiles
```bash
cd ~/.dotfiles
# Remove the dev directory we just created
rm -rf dev
# Add it as a submodule instead
git submodule add git@github.com:YOUR_USERNAME/max-dev.git dev
git add .gitmodules dev
git commit -m "Added max-dev as submodule"
git push
```

### 4. Set up ~/dev symlink
```bash
cd ~/.dotfiles
stow dev  # This creates ~/dev -> ~/.dotfiles/dev
```

## Workflow

### On Mac (with existing repos)
```bash
# 1. Discover existing repositories
cd ~/.dotfiles
./scripts/dev-sync.sh discover

# 2. Commit and push to max-dev
cd ~/.dotfiles/dev
git add .dev-manifest.json
git commit -m "Discovered repos from MacBook"
git push

# 3. Update dotfiles to point to new submodule commit
cd ~/.dotfiles
git add dev
git commit -m "Updated max-dev reference"
git push
```

### On WSL (merge with Mac repos)
```bash
# 1. Pull latest from both repos
cd ~/.dotfiles
git pull --recurse-submodules

# 2. Discover local repositories (merges with existing)
./scripts/dev-sync.sh discover

# 3. Commit merged manifest
cd ~/.dotfiles/dev
git add .dev-manifest.json
git commit -m "Merged repos from WSL"
git push

# 4. Update dotfiles
cd ~/.dotfiles
git add dev
git commit -m "Updated max-dev reference"
git push
```

### On Fresh Arch Install (restore everything)
```bash
# 1. Clone dotfiles with submodules
git clone --recursive git@github.com:YOUR_USERNAME/dotfiles.git ~/.dotfiles

# 2. Run install script (includes dev setup)
cd ~/.dotfiles
./install-arch.sh

# 3. Restore all repositories
./scripts/dev-sync.sh restore
```

## Daily Usage

### Adding a new repository
```bash
# Work normally
cd ~/dev/experiments
git clone git@github.com:you/new-project.git

# Update manifest when you want to sync
cd ~/.dotfiles
./scripts/dev-sync.sh discover
cd dev && git add . && git commit -m "Added new-project" && git push
```

### Checking status
```bash
cd ~/.dotfiles
./scripts/dev-sync.sh status
```

## Troubleshooting

### If ~/dev already exists
```bash
# Back up existing dev folder
mv ~/dev ~/dev.backup

# Set up the symlink
cd ~/.dotfiles && stow dev

# Move projects to the new structure
mv ~/dev.backup/* ~/dev/
rmdir ~/dev.backup

# Discover the moved repositories
./scripts/dev-sync.sh discover
```

### If submodule gets out of sync
```bash
cd ~/.dotfiles
git submodule update --remote dev
git add dev
git commit -m "Updated max-dev to latest"
git push
```

### Starting over
```bash
# Remove submodule
cd ~/.dotfiles
git submodule deinit dev
git rm dev
rm -rf .git/modules/dev

# Re-add it
git submodule add git@github.com:YOUR_USERNAME/max-dev.git dev
```

## Important Notes

- The max-dev repository MUST be private (contains your private repo URLs)
- Your dotfiles repository can remain public (only contains reference to submodule)
- Always commit both the max-dev changes AND the dotfiles submodule reference
- Use `git pull --recurse-submodules` to get both updates