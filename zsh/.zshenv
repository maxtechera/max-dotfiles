# Environment variables that should be available to all shells
# This file is sourced before .zshrc

# Set PATH for local binaries
export PATH="$HOME/.local/bin:$PATH"

# Puppeteer configuration (for headless Chrome)
export PUPPETEER_SKIP_CHROMIUM_DOWNLOAD=true
if [[ "$OSTYPE" == "darwin"* ]]; then
    # macOS - check common Chrome locations
    if [ -f "/Applications/Google Chrome.app/Contents/MacOS/Google Chrome" ]; then
        export PUPPETEER_EXECUTABLE_PATH="/Applications/Google Chrome.app/Contents/MacOS/Google Chrome"
    elif [ -f "/Applications/Chromium.app/Contents/MacOS/Chromium" ]; then
        export PUPPETEER_EXECUTABLE_PATH="/Applications/Chromium.app/Contents/MacOS/Chromium"
    fi
else
    # Linux
    export PUPPETEER_EXECUTABLE_PATH=/usr/bin/chromium
fi

# Default editor
export EDITOR="/usr/local/bin/nvim-tab"
export VISUAL="nvim"

# Language settings
export LANG='en_US.UTF-8'
export LC_ALL='en_US.UTF-8'

# XDG Base Directory Specification
export XDG_CONFIG_HOME="$HOME/.config"
export XDG_DATA_HOME="$HOME/.local/share"
export XDG_CACHE_HOME="$HOME/.cache"
export XDG_STATE_HOME="$HOME/.local/state"

# Development paths
export PNPM_HOME="$HOME/.local/share/pnpm"
export NVM_DIR="$HOME/.nvm"

# FZF defaults
export FZF_DEFAULT_COMMAND='fd --type f --hidden --follow --exclude .git'
export FZF_DEFAULT_OPTS='--height 40% --layout=reverse --border'
export FZF_CTRL_T_COMMAND="$FZF_DEFAULT_COMMAND"