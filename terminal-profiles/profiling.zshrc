# Load zsh profiling module
zmodload zsh/zprof
zmodload zsh/datetime

# Function to log timing
typeset -gA PROFILE_TIMES
profile_start() {
    PROFILE_TIMES[$1]=$EPOCHREALTIME
}

profile_end() {
    local end=$EPOCHREALTIME
    local start=${PROFILE_TIMES[$1]}
    local duration=$(( (end - start) * 1000 ))
    echo "PROFILE: $1: ${duration}ms"
}

# Profile oh-my-zsh
profile_start "oh-my-zsh"
export ZSH="$HOME/.oh-my-zsh"
ZSH_THEME="powerlevel10k/powerlevel10k"
profile_end "oh-my-zsh"

# Profile plugins individually
profile_start "plugin:git"
source $ZSH/plugins/git/git.plugin.zsh 2>/dev/null || true
profile_end "plugin:git"

profile_start "plugin:zsh-autosuggestions"
source $ZSH/plugins/zsh-autosuggestions/zsh-autosuggestions.zsh 2>/dev/null || true
profile_end "plugin:zsh-autosuggestions"

profile_start "plugin:zsh-syntax-highlighting"
source $ZSH/plugins/zsh-syntax-highlighting/zsh-syntax-highlighting.zsh 2>/dev/null || true
profile_end "plugin:zsh-syntax-highlighting"

profile_start "plugin:fast-syntax-highlighting"
source $ZSH/plugins/fast-syntax-highlighting/fast-syntax-highlighting.plugin.zsh 2>/dev/null || true
profile_end "plugin:fast-syntax-highlighting"

profile_start "plugin:zsh-autocomplete"
source $ZSH/plugins/zsh-autocomplete/zsh-autocomplete.plugin.zsh 2>/dev/null || true
profile_end "plugin:zsh-autocomplete"

# Profile oh-my-zsh main script
profile_start "oh-my-zsh-main"
source $ZSH/oh-my-zsh.sh
profile_end "oh-my-zsh-main"

# Profile NVM
profile_start "nvm"
export NVM_DIR="$HOME/.nvm"
[ -s "$NVM_DIR/nvm.sh" ] && \. "$NVM_DIR/nvm.sh"
profile_end "nvm"

# Profile NVM auto-switching
profile_start "nvm-auto-switch"
autoload -U add-zsh-hook
load-nvmrc() {
  local node_version="$(nvm version 2>/dev/null)"
  local nvmrc_path="$(nvm_find_nvmrc 2>/dev/null)"
  if [ -n "$nvmrc_path" ]; then
    local nvmrc_node_version=$(nvm version "$(cat "${nvmrc_path}")" 2>/dev/null)
    if [ "$nvmrc_node_version" = "N/A" ]; then
      nvm install >/dev/null 2>&1
    elif [ "$nvmrc_node_version" != "$node_version" ]; then
      nvm use >/dev/null 2>&1
    fi
  fi
}
add-zsh-hook chpwd load-nvmrc
load-nvmrc
profile_end "nvm-auto-switch"

# Profile p10k
profile_start "p10k"
[[ ! -f ~/.p10k.zsh ]] || source ~/.p10k.zsh
profile_end "p10k"

# Profile zoxide
profile_start "zoxide"
eval "$(zoxide init zsh)"
profile_end "zoxide"

# Show zprof results
echo "=== ZPROF RESULTS ==="
zprof
