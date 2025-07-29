# Fast Node Manager (fnm) Usage Guide

## Overview
fnm is installed and configured for ultra-fast Node.js version management. It's **50x faster** than nvm and fully compatible with `.nvmrc` files!

## Installation Status
✅ fnm is installed at: `~/.local/share/fnm/fnm`
✅ Automatically switches Node versions based on `.nvmrc` files
✅ Terminal startup is now ~10x faster (~55ms vs ~550ms)

## Basic Commands

### List installed Node versions
```bash
fnm list
```

### Install Node.js versions
```bash
# Install latest LTS
fnm install --lts

# Install specific version
fnm install 20
fnm install 18.19.0

# Install version from .nvmrc
fnm install
```

### Switch Node versions
```bash
# Use specific version
fnm use 20
fnm use 18.19.0

# Use LTS
fnm use lts-latest

# Set default version
fnm default 20
```

### .nvmrc Compatibility
fnm automatically respects `.nvmrc` files! When you `cd` into a directory with a `.nvmrc` file:
- If the version is installed: automatically switches to it
- If not installed: shows an error (run `fnm install` to install it)

Example `.nvmrc`:
```
20
```
or
```
18.19.0
```

## Migration from nvm

Your existing `.nvmrc` files work perfectly with fnm! No changes needed.

### Install global packages for new Node version
```bash
fnm use 20
npm install -g pnpm yarn typescript prettier eslint
```

### Aliases (compatible with nvm)
```bash
fnm alias lts-latest default
fnm alias 20 latest-20
```

## Troubleshooting

### If fnm is not found
```bash
source ~/.zshrc
```

### Check current Node version
```bash
fnm current
node --version
```

### Uninstall a Node version
```bash
fnm uninstall 16.20.0
```

## Performance Benefits
- **Before**: ~550-580ms terminal startup
- **After**: ~54-55ms terminal startup
- **10x faster** terminal startup
- **Instant** Node version switching
- **Zero** impact when not using Node

## Configuration
fnm is configured in `~/.zshrc` with:
- Auto-switching on directory change (`--use-on-cd`)
- Fallback to lazy-loaded nvm if fnm not available
- Full `.nvmrc` compatibility