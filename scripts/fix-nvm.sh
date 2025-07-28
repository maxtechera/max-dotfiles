#!/bin/bash
# Fix NVM and Node.js not being recognized

# Colors
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
RED='\033[0;31m'
NC='\033[0m'

echo -e "${BLUE}Fixing NVM and Node.js setup...${NC}"
echo "==============================="

# Check if NVM is installed
if [ ! -d "$HOME/.nvm" ]; then
    echo -e "${RED}NVM is not installed!${NC}"
    echo -e "${YELLOW}Installing NVM...${NC}"
    curl -o- https://raw.githubusercontent.com/nvm-sh/nvm/v0.39.0/install.sh | bash
fi

# Check if .zshrc has NVM configuration
if ! grep -q "NVM_DIR" "$HOME/.zshrc" 2>/dev/null; then
    echo -e "${YELLOW}Adding NVM to .zshrc...${NC}"
    cat >> "$HOME/.zshrc" << 'EOL'

# NVM Configuration
export NVM_DIR="$HOME/.nvm"
[ -s "$NVM_DIR/nvm.sh" ] && \. "$NVM_DIR/nvm.sh"
[ -s "$NVM_DIR/bash_completion" ] && \. "$NVM_DIR/bash_completion"
EOL
fi

# Source NVM for current session
export NVM_DIR="$HOME/.nvm"
[ -s "$NVM_DIR/nvm.sh" ] && \. "$NVM_DIR/nvm.sh"
[ -s "$NVM_DIR/bash_completion" ] && \. "$NVM_DIR/bash_completion"

# Check if NVM is now available
if command -v nvm &> /dev/null; then
    echo -e "${GREEN}✓ NVM is available${NC}"
    
    # Check if Node is installed
    if ! nvm list | grep -q "node" 2>/dev/null; then
        echo -e "${YELLOW}Installing Node.js LTS...${NC}"
        nvm install --lts
        nvm use --lts
        nvm alias default node
    fi
    
    # Verify Node installation
    if command -v node &> /dev/null; then
        echo -e "${GREEN}✓ Node.js $(node --version) is installed${NC}"
        echo -e "${GREEN}✓ npm $(npm --version) is installed${NC}"
        
        # Check for global packages
        if ! command -v pnpm &> /dev/null; then
            echo -e "${YELLOW}Installing global npm packages...${NC}"
            npm install -g pnpm yarn typescript prettier eslint
        fi
    else
        echo -e "${RED}Node installation failed${NC}"
    fi
else
    echo -e "${RED}NVM is still not available${NC}"
fi

echo -e "\n${YELLOW}Next steps:${NC}"
echo "1. Open a new terminal OR"
echo "2. Run: source ~/.zshrc"
echo
echo -e "${GREEN}Then verify with:${NC}"
echo "• nvm --version"
echo "• node --version"
echo "• npm --version"