#!/usr/bin/env zsh
# Timestamp wrapper for profiling

# Enable timestamp logging
PS4='+[%D{%s.%6.}] '
set -x

# Source the actual zshrc
source ~/.zshrc

# Exit immediately
exit 0
