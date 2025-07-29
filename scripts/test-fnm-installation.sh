#!/bin/bash

# Test script for fnm installation
set -e

# Colors
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

echo -e "${YELLOW}Testing fnm installation...${NC}"

# Test 1: Check if fnm is in PATH
echo -e "\n${YELLOW}Test 1: Checking if fnm is in PATH${NC}"
if command -v fnm &> /dev/null; then
    echo -e "${GREEN}✓ fnm found at: $(which fnm)${NC}"
else
    echo -e "${RED}✗ fnm not found in PATH${NC}"
    echo -e "${YELLOW}Current PATH: $PATH${NC}"
    exit 1
fi

# Test 2: Check fnm version
echo -e "\n${YELLOW}Test 2: Checking fnm version${NC}"
if fnm_version=$(fnm --version 2>&1); then
    echo -e "${GREEN}✓ fnm version: $fnm_version${NC}"
else
    echo -e "${RED}✗ Failed to get fnm version: $fnm_version${NC}"
    exit 1
fi

# Test 3: Check fnm environment
echo -e "\n${YELLOW}Test 3: Checking fnm environment${NC}"
if fnm_env=$(fnm env 2>&1); then
    echo -e "${GREEN}✓ fnm env output:${NC}"
    echo "$fnm_env" | head -5
else
    echo -e "${RED}✗ Failed to get fnm env${NC}"
    exit 1
fi

# Test 4: Initialize fnm in current shell
echo -e "\n${YELLOW}Test 4: Initializing fnm environment${NC}"
if eval "$(fnm env --use-on-cd)"; then
    echo -e "${GREEN}✓ fnm environment initialized${NC}"
else
    echo -e "${RED}✗ Failed to initialize fnm environment${NC}"
    exit 1
fi

# Test 5: Check if Node.js is installed
echo -e "\n${YELLOW}Test 5: Checking Node.js installation${NC}"
if fnm list | grep -q "lts"; then
    echo -e "${GREEN}✓ Node.js LTS is installed${NC}"
    fnm list
else
    echo -e "${YELLOW}! Node.js LTS not installed, installing now...${NC}"
    if fnm install --lts && fnm use lts-latest && fnm default lts-latest; then
        echo -e "${GREEN}✓ Node.js LTS installed successfully${NC}"
    else
        echo -e "${RED}✗ Failed to install Node.js LTS${NC}"
        exit 1
    fi
fi

# Test 6: Verify node and npm commands
echo -e "\n${YELLOW}Test 6: Verifying node and npm commands${NC}"
if command -v node &> /dev/null && command -v npm &> /dev/null; then
    echo -e "${GREEN}✓ node version: $(node --version)${NC}"
    echo -e "${GREEN}✓ npm version: $(npm --version)${NC}"
else
    echo -e "${RED}✗ node or npm commands not available${NC}"
    exit 1
fi

# Test 7: Test fnm use command
echo -e "\n${YELLOW}Test 7: Testing fnm use command${NC}"
if fnm use lts-latest 2>&1; then
    echo -e "${GREEN}✓ fnm use command works${NC}"
else
    echo -e "${RED}✗ fnm use command failed${NC}"
    exit 1
fi

echo -e "\n${GREEN}✓ All fnm tests passed!${NC}"