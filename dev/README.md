# Max Development Workspace

This repository tracks the organization and structure of my `~/dev` directory across multiple machines.

## Directory Structure

- `experiments/` - Proof of concepts, learning projects, quick tests
- `customer-work/` - Client projects and deliverables
- `personal/` - Personal projects and side projects

## Usage

### On an existing machine (Mac/WSL)
```bash
cd ~/.dotfiles
./scripts/dev-sync.sh discover
cd dev && git add . && git commit -m "Updated dev from $(hostname)" && git push
```

### On a new machine
```bash
cd ~/.dotfiles
git pull --recurse-submodules
stow dev
./scripts/dev-sync.sh restore
```

### Daily workflow
1. Work normally in `~/dev` - clone repos, create projects, organize as needed
2. When you add new repositories, run `./scripts/dev-sync.sh discover` to track them
3. Commit and push changes to sync across machines

## What's Tracked

- Directory structure (via .gitkeep files)
- Repository locations and URLs (via .dev-manifest.json)
- Organization documentation (README files, notes)

## What's NOT Tracked

- Repository contents (each project remains independent)
- IDE settings, build artifacts, etc.
- Sensitive files (.env, secrets, etc.)

The goal is to sync the *organization* of your development workspace while keeping individual projects independent.