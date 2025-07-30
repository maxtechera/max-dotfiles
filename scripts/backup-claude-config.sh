#!/bin/bash

# Backup existing Claude configuration before stowing

BACKUP_DIR="$HOME/.claude-backup-$(date +%Y%m%d-%H%M%S)"

if [ -d "$HOME/.claude" ] && [ ! -L "$HOME/.claude" ]; then
    echo "Backing up existing Claude configuration to $BACKUP_DIR"
    mv "$HOME/.claude" "$BACKUP_DIR"
    echo "Backup created at: $BACKUP_DIR"
    echo "You can restore it later with: mv $BACKUP_DIR $HOME/.claude"
fi