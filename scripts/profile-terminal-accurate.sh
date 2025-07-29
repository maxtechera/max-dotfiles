#!/bin/bash
# Accurate Terminal Profiling Script
# Using more reliable timing methods

set -euo pipefail

# Colors
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[0;33m'
BLUE='\033[0;34m'
NC='\033[0m'

PROFILE_DIR="$HOME/.dotfiles/terminal-profiles"
TIMESTAMP=$(date +%Y%m%d_%H%M%S)
mkdir -p "$PROFILE_DIR"

echo -e "${BLUE}Terminal Startup Profiler v2${NC}"
echo "================================"
echo ""

# Method 1: Use hyperfine if available (most accurate)
if command -v hyperfine >/dev/null 2>&1; then
    echo -e "${GREEN}Using hyperfine for accurate benchmarking...${NC}"
    
    # Benchmark zsh startup
    hyperfine --warmup 3 --runs 10 --export-json "$PROFILE_DIR/hyperfine-zsh-$TIMESTAMP.json" \
        'zsh -i -c "exit"' \
        --show-output
    
    # Benchmark ghostty startup
    hyperfine --warmup 3 --runs 10 --export-json "$PROFILE_DIR/hyperfine-ghostty-$TIMESTAMP.json" \
        'ghostty --command "exit"' \
        --show-output
else
    echo -e "${YELLOW}hyperfine not found. Install it for most accurate results:${NC}"
    echo "  sudo pacman -S hyperfine"
    echo ""
fi

# Method 2: Manual timing with proper measurement
echo -e "${YELLOW}Running manual timing tests...${NC}"

# Function to get current time in milliseconds
get_time_ms() {
    python3 -c 'import time; print(int(time.time() * 1000))'
}

# Test zsh startup times
echo "Testing zsh startup (5 runs)..."
for i in {1..5}; do
    start=$(get_time_ms)
    zsh -i -c 'exit' 2>/dev/null
    end=$(get_time_ms)
    duration=$((end - start))
    echo "  Run $i: ${duration}ms"
done

echo ""
echo "Testing ghostty startup (5 runs)..."
for i in {1..5}; do
    start=$(get_time_ms)
    ghostty --command 'exit' 2>/dev/null
    end=$(get_time_ms)
    duration=$((end - start))
    echo "  Run $i: ${duration}ms"
done

# Method 3: Detailed zsh profiling with zprof
echo ""
echo -e "${YELLOW}Running detailed zsh profiling...${NC}"

# Create a profiling script
cat > "$PROFILE_DIR/zsh-profile-wrapper.zsh" << 'EOF'
#!/usr/bin/env zsh

# Enable profiling
zmodload zsh/zprof
zmodload zsh/datetime

# Track start time
typeset -F SECONDS
start=$SECONDS

# Source the regular config
source ~/.zshrc

# Calculate total time
end=$SECONDS
total_ms=$(( (end - start) * 1000 ))

echo "Total startup time: ${total_ms}ms"
echo ""
echo "=== Component Breakdown ==="

# Show zprof results
zprof | head -30
EOF

chmod +x "$PROFILE_DIR/zsh-profile-wrapper.zsh"
zsh "$PROFILE_DIR/zsh-profile-wrapper.zsh" > "$PROFILE_DIR/zprof-detailed-$TIMESTAMP.log" 2>&1

# Method 4: Trace individual components
echo ""
echo -e "${YELLOW}Profiling individual components...${NC}"

# Test individual components
components=(
    "oh-my-zsh:source \$ZSH/oh-my-zsh.sh"
    "nvm:source \$NVM_DIR/nvm.sh"
    "p10k:source ~/.p10k.zsh"
    "zoxide:eval \"\$(zoxide init zsh)\""
)

for component in "${components[@]}"; do
    name="${component%%:*}"
    cmd="${component#*:}"
    
    # Create test script
    cat > "$PROFILE_DIR/test-$name.zsh" << EOF
#!/usr/bin/env zsh
export ZSH="$HOME/.oh-my-zsh"
export NVM_DIR="$HOME/.nvm"
start=\$(python3 -c 'import time; print(int(time.time() * 1000))')
$cmd 2>/dev/null
end=\$(python3 -c 'import time; print(int(time.time() * 1000))')
echo \$((end - start))
EOF
    
    chmod +x "$PROFILE_DIR/test-$name.zsh"
    duration=$(zsh "$PROFILE_DIR/test-$name.zsh" 2>/dev/null || echo "error")
    echo "  $name: ${duration}ms"
done

# Generate summary report
echo ""
echo -e "${GREEN}Generating report...${NC}"

cat > "$PROFILE_DIR/REPORT-$TIMESTAMP.md" << EOF
# Terminal Startup Performance Report

Generated: $(date)

## Key Findings

### Component Load Times (from zprof)
$(grep -E "nvm|oh-my-zsh|p10k|compinit|compdump" "$PROFILE_DIR/zprof-detailed-$TIMESTAMP.log" 2>/dev/null | head -10 || echo "No data available")

### Recommendations

1. **NVM is the biggest bottleneck** - Consider:
   - Switching to fnm or volta (50x faster)
   - Lazy-loading NVM only when needed
   - Removing auto-switching functionality

2. **Oh-My-Zsh overhead** - Consider:
   - Using a minimal framework like zinit
   - Loading only essential plugins
   - Compiling zsh files for faster startup

3. **Compilation cache** - Run:
   \`\`\`bash
   # Compile zsh files for faster loading
   zcompile ~/.zshrc
   zcompile ~/.p10k.zsh
   \`\`\`

## Quick Wins

1. Install fnm instead of nvm:
   \`\`\`bash
   sudo pacman -S fnm
   # Then update .zshrc to use fnm instead of nvm
   \`\`\`

2. Reduce ghostty visual effects in config:
   - Set \`background-opacity = 1.0\`
   - Set \`background-blur-radius = 0\`

3. Remove duplicate syntax highlighting plugin:
   - Keep only \`fast-syntax-highlighting\`
   - Remove \`zsh-syntax-highlighting\`

## Files Generated
- zprof-detailed-$TIMESTAMP.log - Detailed profiling data
- hyperfine-*.json - Accurate benchmark results (if hyperfine installed)
EOF

echo -e "${GREEN}Report saved to: $PROFILE_DIR/REPORT-$TIMESTAMP.md${NC}"
echo ""
echo "View detailed profiling: less $PROFILE_DIR/zprof-detailed-$TIMESTAMP.log"