#!/usr/bin/env bash
# Ansible Lint Helper Script
# Runs ansible-lint on the ansible directory

set -euo pipefail

# Colors
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

echo -e "${YELLOW}Running ansible-lint...${NC}"

# Check if ansible-lint is installed
if ! command -v ansible-lint &> /dev/null; then
    echo -e "${RED}Error: ansible-lint is not installed${NC}"
    echo -e "${YELLOW}Install with: pip install ansible-lint ansible-core${NC}"
    echo -e "${YELLOW}Or: brew install ansible-lint${NC}"
    exit 1
fi

# Change to ansible directory
cd "$(dirname "$0")/../ansible"

# Run ansible-lint
if ansible-lint --version &> /dev/null; then
    echo -e "${GREEN}Ansible-lint version:${NC}"
    ansible-lint --version
    echo ""

    echo -e "${YELLOW}Linting ansible/ directory...${NC}"
    if ansible-lint .; then
        echo -e "${GREEN}✓ Ansible-lint passed!${NC}"
        exit 0
    else
        echo -e "${RED}✗ Ansible-lint found issues${NC}"
        exit 1
    fi
else
    echo -e "${RED}Error running ansible-lint${NC}"
    exit 1
fi
