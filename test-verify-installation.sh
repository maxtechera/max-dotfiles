#!/bin/bash
# Test the verify_installation function

# Source colors and the function
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
PURPLE='\033[0;35m'
NC='\033[0m'

# Extract and source just the verify_installation function
sed -n '/^verify_installation() {/,/^}$/p' install-arch.sh > /tmp/verify_func.sh
source /tmp/verify_func.sh

# Run the verification
echo "Testing verify_installation function..."
verify_installation
STATUS=$?

echo -e "\nVerification returned status: $STATUS"
rm -f /tmp/verify_func.sh