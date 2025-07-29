#!/bin/bash
# Terminal Profiling Script - Comprehensive performance analysis for ghostty + zsh
# This script profiles terminal startup without making any permanent changes

set -euo pipefail

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[0;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# Configuration
ITERATIONS=5
PROFILE_DIR="$HOME/.dotfiles/terminal-profiles"
TIMESTAMP=$(date +%Y%m%d_%H%M%S)

# Create profile directory
mkdir -p "$PROFILE_DIR"

echo -e "${BLUE}Terminal Startup Profiler${NC}"
echo "================================"
echo "Profile directory: $PROFILE_DIR"
echo "Timestamp: $TIMESTAMP"
echo ""

# Function to measure command execution time in milliseconds
measure_time() {
    local start=$(date +%s%N)
    "$@" >/dev/null 2>&1
    local end=$(date +%s%N)
    echo $(( (end - start) / 1000000 ))
}

# Function to profile zsh startup with zprof
profile_zsh_detailed() {
    echo -e "${YELLOW}Profiling zsh startup (detailed)...${NC}"
    
    # Create temporary profiling zshrc
    cat > "$PROFILE_DIR/profiling.zshrc" << 'EOF'
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
EOF

    # Run profiling
    zsh -c "source $PROFILE_DIR/profiling.zshrc" > "$PROFILE_DIR/zsh-detailed-$TIMESTAMP.log" 2>&1
}

# Function to profile basic startup times
profile_basic_times() {
    echo -e "${YELLOW}Measuring basic startup times ($ITERATIONS iterations)...${NC}"
    
    # Array to store results
    declare -a ghostty_times=()
    declare -a zsh_times=()
    declare -a combined_times=()
    
    for i in $(seq 1 $ITERATIONS); do
        echo -n "Iteration $i/$ITERATIONS: "
        
        # Measure pure zsh startup
        local zsh_time=$(measure_time zsh -i -c 'exit')
        zsh_times+=($zsh_time)
        
        # Measure ghostty + zsh startup
        local combined_time=$(measure_time ghostty --command 'exit')
        combined_times+=($combined_time)
        
        # Calculate ghostty overhead
        local ghostty_time=$((combined_time - zsh_time))
        ghostty_times+=($ghostty_time)
        
        echo "zsh: ${zsh_time}ms, ghostty overhead: ${ghostty_time}ms, total: ${combined_time}ms"
        
        # Small delay between iterations
        sleep 0.5
    done
    
    # Calculate averages
    local zsh_avg=$(IFS=+; echo "scale=2; (${zsh_times[*]}) / $ITERATIONS" | bc)
    local ghostty_avg=$(IFS=+; echo "scale=2; (${ghostty_times[*]}) / $ITERATIONS" | bc)
    local combined_avg=$(IFS=+; echo "scale=2; (${combined_times[*]}) / $ITERATIONS" | bc)
    
    echo ""
    echo -e "${GREEN}Average Results:${NC}"
    echo "- Zsh startup: ${zsh_avg}ms"
    echo "- Ghostty overhead: ${ghostty_avg}ms"
    echo "- Total startup: ${combined_avg}ms"
    
    # Save results
    cat > "$PROFILE_DIR/summary-$TIMESTAMP.txt" << EOF
Terminal Startup Profile Summary
================================
Date: $(date)
Iterations: $ITERATIONS

Average Times:
- Zsh startup: ${zsh_avg}ms
- Ghostty overhead: ${ghostty_avg}ms
- Total startup: ${combined_avg}ms

Raw Data:
Zsh times: ${zsh_times[@]}
Ghostty times: ${ghostty_times[@]}
Combined times: ${combined_times[@]}
EOF
}

# Function to trace system calls
profile_syscalls() {
    echo -e "${YELLOW}Tracing system calls (optional - requires strace)...${NC}"
    
    if command -v strace >/dev/null 2>&1; then
        echo "Running strace analysis..."
        strace -c -f ghostty --command 'exit' 2> "$PROFILE_DIR/strace-summary-$TIMESTAMP.txt" >/dev/null
        echo "Strace summary saved to: $PROFILE_DIR/strace-summary-$TIMESTAMP.txt"
    else
        echo "strace not found, skipping system call analysis"
    fi
}

# Function to profile with timestamps
profile_with_timestamps() {
    echo -e "${YELLOW}Profiling with timestamps...${NC}"
    
    # Create wrapper script that adds timestamps
    cat > "$PROFILE_DIR/timestamp-wrapper.zsh" << 'EOF'
#!/usr/bin/env zsh
# Timestamp wrapper for profiling

# Enable timestamp logging
PS4='+[%D{%s.%6.}] '
set -x

# Source the actual zshrc
source ~/.zshrc

# Exit immediately
exit 0
EOF
    
    chmod +x "$PROFILE_DIR/timestamp-wrapper.zsh"
    
    # Run with timestamps
    zsh "$PROFILE_DIR/timestamp-wrapper.zsh" 2> "$PROFILE_DIR/timestamp-trace-$TIMESTAMP.log" >/dev/null
    
    echo "Timestamp trace saved to: $PROFILE_DIR/timestamp-trace-$TIMESTAMP.log"
}

# Function to generate report
generate_report() {
    echo -e "${YELLOW}Generating final report...${NC}"
    
    cat > "$PROFILE_DIR/REPORT-$TIMESTAMP.md" << EOF
# Terminal Startup Performance Report

Generated: $(date)

## Summary

Average startup times from $ITERATIONS iterations:
$(cat "$PROFILE_DIR/summary-$TIMESTAMP.txt" | grep -E "^- " || echo "No summary data")

## Detailed Analysis

### Component Load Times
$(grep "^PROFILE:" "$PROFILE_DIR/zsh-detailed-$TIMESTAMP.log" 2>/dev/null | sort -t: -k3 -nr | head -20 || echo "No detailed profiling data")

### Potential Optimizations

Based on the profiling data, here are the slowest components:
$(grep "^PROFILE:" "$PROFILE_DIR/zsh-detailed-$TIMESTAMP.log" 2>/dev/null | sort -t: -k3 -nr | head -5 | while read line; do
    component=$(echo "$line" | cut -d: -f2)
    time=$(echo "$line" | cut -d: -f3)
    echo "- $component:$time"
done || echo "No optimization data")

## Files Generated

- summary-$TIMESTAMP.txt: Basic timing averages
- zsh-detailed-$TIMESTAMP.log: Detailed component profiling
- timestamp-trace-$TIMESTAMP.log: Full execution trace with timestamps
- strace-summary-$TIMESTAMP.txt: System call analysis (if available)

## Next Steps

1. Review the slowest components above
2. Consider lazy-loading or removing unnecessary plugins
3. Look into faster alternatives for slow components
4. Run profiling again after making changes to measure improvements
EOF

    echo -e "${GREEN}Report generated: $PROFILE_DIR/REPORT-$TIMESTAMP.md${NC}"
}

# Main execution
main() {
    echo "Starting comprehensive terminal profiling..."
    echo ""
    
    # Run all profiling methods
    profile_basic_times
    echo ""
    
    profile_zsh_detailed
    echo ""
    
    profile_with_timestamps
    echo ""
    
    profile_syscalls
    echo ""
    
    generate_report
    
    echo ""
    echo -e "${GREEN}Profiling complete!${NC}"
    echo "All results saved to: $PROFILE_DIR"
    echo ""
    echo "View the report: cat $PROFILE_DIR/REPORT-$TIMESTAMP.md"
}

# Run main function
main