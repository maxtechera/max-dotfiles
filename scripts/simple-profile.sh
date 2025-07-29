#!/bin/bash
# Simple profiling script

echo "Terminal Startup Profiling"
echo "========================="
echo ""

# Function to measure time in milliseconds
measure_ms() {
    local start=$(date +%s%N)
    "$@" >/dev/null 2>&1
    local end=$(date +%s%N)
    echo $(( (end - start) / 1000000 ))
}

echo "Testing zsh startup (5 runs):"
total=0
for i in {1..5}; do
    ms=$(measure_ms zsh -i -c 'exit')
    echo "  Run $i: ${ms}ms"
    total=$((total + ms))
done
avg=$((total / 5))
echo "Average: ${avg}ms"

echo ""
echo "Testing with fnm status:"
zsh -i -c 'fnm --version && fnm current' 2>&1

echo ""
echo "Checking optimizations:"
echo -n "- fnm installed: "
[[ -x "$HOME/.local/share/fnm/fnm" ]] && echo "✓" || echo "✗"

echo -n "- .zshrc compiled: "
[[ -f "$HOME/.zshrc.zwc" ]] && echo "✓" || echo "✗"

echo -n "- .p10k.zsh compiled: "
[[ -f "$HOME/.p10k.zsh.zwc" ]] && echo "✓" || echo "✗"

echo -n "- Instant prompt cache: "
[[ -f "$HOME/.cache/p10k-instant-prompt-${USER}.zsh" ]] && echo "✓" || echo "✗"