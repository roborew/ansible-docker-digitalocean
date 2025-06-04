#!/bin/bash

# Ansible DigitalOcean Deployment - Environment Activation Script
# This script activates both the Python virtual environment and loads environment variables

set -e

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

echo -e "${BLUE}🚀 Activating Ansible environment...${NC}"

# Check if we're in the right directory
if [ ! -f "scripts/bootstrap.sh" ]; then
    echo -e "${RED}❌ Error: Not in robo-ansible directory${NC}"
    echo -e "${YELLOW}Please run this script from the robo-ansible root directory${NC}"
    exit 1
fi

# Check if virtual environment exists
if [ ! -d "venv" ]; then
    echo -e "${RED}❌ Error: Virtual environment not found${NC}"
    echo -e "${YELLOW}Please run ./scripts/bootstrap.sh first${NC}"
    exit 1
fi

# Activate virtual environment
echo -e "${GREEN}✅ Activating Python virtual environment...${NC}"
source venv/bin/activate

# Check if .env file exists
if [ ! -f ".env" ]; then
    echo -e "${YELLOW}⚠️  Warning: .env file not found${NC}"
    echo -e "${YELLOW}   Creating from example template...${NC}"
    cp env.example .env
    echo -e "${YELLOW}   Please edit .env with your DigitalOcean API token:${NC}"
    echo -e "${YELLOW}   nano .env${NC}"
    echo ""
fi

# Load environment variables
echo -e "${GREEN}✅ Loading environment variables...${NC}"
source .env

# Verify API token is set
if [ -z "$DO_API_TOKEN" ]; then
    echo -e "${YELLOW}⚠️  Warning: DO_API_TOKEN not set in .env file${NC}"
    echo -e "${YELLOW}   Please add your DigitalOcean API token to .env${NC}"
else
    echo -e "${GREEN}✅ DigitalOcean API token loaded: ${DO_API_TOKEN:0:8}...${NC}"
fi

echo ""
echo -e "${GREEN}🎉 Environment ready! You can now run Ansible commands.${NC}"
echo -e "${BLUE}💡 Tip: You can also source this script with: source scripts/activate.sh${NC}"
echo "" 