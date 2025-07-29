# Enable Powerlevel10k instant prompt. Should stay close to the top of ~/.zshrc.
# Initialization code that may require console input (password prompts, [y/n]
# confirmations, etc.) must go above this block; everything else may go below.
if [[ -r "${XDG_CACHE_HOME:-$HOME/.cache}/p10k-instant-prompt-${(%):-%n}.zsh" ]]; then
  source "${XDG_CACHE_HOME:-$HOME/.cache}/p10k-instant-prompt-${(%):-%n}.zsh"
fi

# Zsh Configuration
# Matching macOS setup for Arch Linux

# Path to oh-my-zsh
export ZSH="$HOME/.oh-my-zsh"

# Disable oh-my-zsh auto-updates for faster startup
DISABLE_AUTO_UPDATE="true"
DISABLE_UPDATE_PROMPT="true"

# Theme - Powerlevel10k
ZSH_THEME="powerlevel10k/powerlevel10k"

# Plugins (optimized - removed duplicates)
plugins=(
    git
    zsh-autosuggestions
    fast-syntax-highlighting
    zsh-autocomplete
)

source $ZSH/oh-my-zsh.sh

# User configuration

# Aliases - matching macOS setup
# Use GNU ls on Arch (different from macOS)
alias ls='ls --color=auto'
alias ll='ls -lh'
alias la='ls -lAh'
alias l='ls -lah'
alias lsa='ls -lah'
alias md='mkdir -p'
alias rd='rmdir'

# Modern CLI tools
# Check if tools exist before aliasing
command -v eza &> /dev/null && alias ls='eza --icons'
command -v bat &> /dev/null && alias cat='bat'
alias vim='nvim'
alias vi='nvim'
alias g='git'
alias lg='lazygit'
alias ..='cd ..'
alias ...='cd ../..'
alias ....='cd ../../..'
alias .....='../../../../..'
alias ......='../../../../../..'
alias grep='grep --color=auto --exclude-dir={.bzr,CVS,.git,.hg,.svn,.idea,.tox}'
alias egrep='egrep --color=auto --exclude-dir={.bzr,CVS,.git,.hg,.svn,.idea,.tox}'
alias fgrep='fgrep --color=auto --exclude-dir={.bzr,CVS,.git,.hg,.svn,.idea,.tox}'

# oh-my-zsh git plugin provides all git aliases automatically
# Key ones: gs, ga, gc, gp, gpl, gco, gcb, glog, etc.

# Additional aliases
alias nvt='/usr/local/bin/nvim-tab'
alias dev-sync='~/.dotfiles/scripts/github-dev-sync.sh'

# Tmux aliases
alias ta='tmux attach -t'
alias ts='tmux new-session -s'
alias tl='tmux list-sessions'
alias tk='tmux kill-session -t'

# Functions
mkcd() {
    mkdir -p "$1" && cd "$1"
}

# Extract archives
extract() {
    if [ -f $1 ]; then
        case $1 in
            *.tar.bz2)   tar xjf $1     ;;
            *.tar.gz)    tar xzf $1     ;;
            *.bz2)       bunzip2 $1     ;;
            *.rar)       unrar e $1     ;;
            *.gz)        gunzip $1      ;;
            *.tar)       tar xf $1      ;;
            *.tbz2)      tar xjf $1     ;;
            *.tgz)       tar xzf $1     ;;
            *.zip)       unzip $1       ;;
            *.Z)         uncompress $1  ;;
            *.7z)        7z x $1        ;;
            *)     echo "'$1' cannot be extracted via extract()" ;;
        esac
    else
        echo "'$1' is not a valid file"
    fi
}

# FZF configuration
export FZF_DEFAULT_COMMAND='fd --type f --hidden --follow --exclude .git'
export FZF_DEFAULT_OPTS='--height 40% --layout=reverse --border'
export FZF_CTRL_T_COMMAND="$FZF_DEFAULT_COMMAND"

# Environment variables
export EDITOR='/usr/local/bin/nvim-tab'
export VISUAL='nvim'
export PAGER='less'
export LANG='en_US.UTF-8'
export LC_ALL='en_US.UTF-8'

# Fast Node Manager (fnm) - Much faster than NVM
# Check multiple possible fnm installation locations
FNM_PATHS=(
    "${XDG_DATA_HOME:-$HOME/.local/share}/fnm"
    "$HOME/.fnm"
    "$HOME/.cargo/bin"
)

# Find and use fnm from any of the possible locations
for fnm_path in "${FNM_PATHS[@]}"; do
    if [[ -x "$fnm_path/fnm" ]]; then
        export PATH="$fnm_path:$PATH"
        break
    fi
done

# Initialize fnm if available
if command -v fnm &> /dev/null; then
    eval "$(fnm env --use-on-cd --shell zsh)"
else
    # Fallback to NVM if fnm not installed
    export NVM_DIR="$HOME/.nvm"
    # Lazy load NVM to improve startup time
    nvm() {
        unset -f nvm node npm npx
        [ -s "$NVM_DIR/nvm.sh" ] && . "$NVM_DIR/nvm.sh"
        nvm "$@"
    }
    node() {
        unset -f nvm node npm npx
        [ -s "$NVM_DIR/nvm.sh" ] && . "$NVM_DIR/nvm.sh"
        node "$@"
    }
    npm() {
        unset -f nvm node npm npx
        [ -s "$NVM_DIR/nvm.sh" ] && . "$NVM_DIR/nvm.sh"
        npm "$@"
    }
    npx() {
        unset -f nvm node npm npx
        [ -s "$NVM_DIR/nvm.sh" ] && . "$NVM_DIR/nvm.sh"
        npx "$@"
    }
fi

# pnpm
export PNPM_HOME="$HOME/.local/share/pnpm"
case ":$PATH:" in
  *":$PNPM_HOME:"*) ;;
  *) export PATH="$PNPM_HOME:$PATH" ;;
esac

# Python (pipx)
export PATH="$PATH:$HOME/.local/bin"

# History
HISTFILE=~/.zsh_history
HISTSIZE=10000
SAVEHIST=10000
setopt SHARE_HISTORY
setopt HIST_IGNORE_DUPS
setopt HIST_IGNORE_ALL_DUPS
setopt HIST_FIND_NO_DUPS
setopt HIST_IGNORE_SPACE
setopt HIST_VERIFY

# Initialize starship prompt (disabled - using powerlevel10k)
# eval "$(starship init zsh)"

# Compile zsh files for faster loading
if [[ ! -f ~/.zshrc.zwc ]] || [[ ~/.zshrc -nt ~/.zshrc.zwc ]]; then
    zcompile ~/.zshrc
fi
if [[ ! -f ~/.p10k.zsh.zwc ]] || [[ ~/.p10k.zsh -nt ~/.p10k.zsh.zwc ]]; then
    zcompile ~/.p10k.zsh
fi

# Lazy-load zoxide for faster startup
z() {
    unset -f z zi
    eval "$(zoxide init zsh)"
    z "$@"
}
zi() {
    unset -f z zi
    eval "$(zoxide init zsh)"
    zi "$@"
}

# Initialize direnv for automatic environment management
if command -v direnv &> /dev/null; then
    eval "$(direnv hook zsh)"
fi

# Initialize thefuck for command correction
if command -v thefuck &> /dev/null; then
    eval "$(thefuck --alias)"
fi

# Load local zsh config if it exists
[[ -f ~/.zshrc.local ]] && source ~/.zshrc.local

# To customize prompt, run `p10k configure` or edit ~/.p10k.zsh.
[[ ! -f ~/.p10k.zsh ]] || source ~/.p10k.zsh
