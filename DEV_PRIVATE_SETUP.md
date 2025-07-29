# Private Dev Setup

## Why Private?

The `dev/` directory contains a `.dev-manifest.json` file that lists ALL your repositories, including:
- Private repository URLs
- Work/client projects
- Personal projects

This information should NOT be in a public dotfiles repository!

## Setup Instructions

### 1. Create Private Repository

Go to https://github.com/new and create a new repository:
- Name: `max-dev`
- Visibility: **PRIVATE** (Important!)
- Don't initialize with README

### 2. Run Setup Script

```bash
cd ~/.dotfiles
./setup-private-dev.sh
```

This script will:
- Convert the `dev/` directory to a git submodule
- Link it to your private `max-dev` repository
- Preserve your existing manifest and structure

### 3. Current Status

Right now, your dev directory is tracked in your PUBLIC dotfiles. We need to fix this by:
1. Removing it from the public repo
2. Creating it as a private submodule
3. Moving the manifest there

## After Setup

Your structure will be:
```
~/.dotfiles/
  ├── .gitmodules          (references the private max-dev repo)
  ├── dev/                 (private submodule)
  │   ├── .dev-manifest.json   (your private repo list)
  │   ├── README.md
  │   └── ... (structure folders)
  └── ... (other dotfiles)
```

## Daily Workflow

1. Discover repos: `dev-sync discover`
2. Commit in dev/: `cd ~/.dotfiles/dev && git add . && git commit && git push`
3. Update dotfiles: `cd ~/.dotfiles && git add dev && git commit && git push`

## Security Note

- The `max-dev` repository MUST remain private
- Never make it public as it contains all your repository URLs
- Your main dotfiles can stay public (they only reference the submodule)