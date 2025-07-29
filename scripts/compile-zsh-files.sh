#!/usr/bin/env zsh
# Compile Zsh files for faster loading
# This creates .zwc (Zsh Word Code) files that load faster

set -euo pipefail

echo "Compiling Zsh configuration files..."

# Compile main config files
FILES_TO_COMPILE=(
    "$HOME/.zshrc"
    "$HOME/.p10k.zsh"
    "$HOME/.zshenv"
    "$HOME/.oh-my-zsh/oh-my-zsh.sh"
)

# Compile each file if it exists and is newer than its compiled version
for file in "${FILES_TO_COMPILE[@]}"; do
    if [[ -f "$file" ]]; then
        if [[ ! -f "${file}.zwc" ]] || [[ "$file" -nt "${file}.zwc" ]]; then
            echo "Compiling: $file"
            zcompile "$file"
        else
            echo "Already compiled: $file"
        fi
    fi
done

# Compile oh-my-zsh plugins
echo ""
echo "Compiling Oh-My-Zsh plugins..."
for plugin_dir in $HOME/.oh-my-zsh/plugins/* $HOME/.oh-my-zsh/custom/plugins/*; do
    if [[ -d "$plugin_dir" ]]; then
        plugin_name=$(basename "$plugin_dir")
        plugin_file="$plugin_dir/$plugin_name.plugin.zsh"
        
        if [[ -f "$plugin_file" ]]; then
            if [[ ! -f "${plugin_file}.zwc" ]] || [[ "$plugin_file" -nt "${plugin_file}.zwc" ]]; then
                echo "Compiling plugin: $plugin_name"
                zcompile "$plugin_file" 2>/dev/null || true
            fi
        fi
    fi
done

# Recompile completion dump
if [[ -f "$HOME/.zcompdump" ]]; then
    echo ""
    echo "Recompiling completion dump..."
    rm -f "$HOME/.zcompdump.zwc"
    zcompile "$HOME/.zcompdump"
fi

# Find and compile any .zcompdump-* files
for dump in $HOME/.zcompdump-*; do
    if [[ -f "$dump" ]] && [[ ! "$dump" =~ \.zwc$ ]]; then
        echo "Compiling: $dump"
        zcompile "$dump" 2>/dev/null || true
    fi
done

echo ""
echo "✓ Zsh compilation complete!"
echo "Your shell should now start faster."