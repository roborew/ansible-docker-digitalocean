#!/bin/bash

# Project initialization script for new users
# This script helps set up the project for your specific environment

set -e

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

echo -e "${BLUE}🚀 Initializing Ansible DigitalOcean Project${NC}"
echo "=============================================="

# Check if already initialized
if [ -f ".env" ] && [ -f "group_vars/prod.yml" ]; then
    echo -e "${YELLOW}⚠️  Project appears to be already initialized${NC}"
    read -p "Continue anyway? (y/N): " -n 1 -r
    echo
    if [[ ! $REPLY =~ ^[Yy]$ ]]; then
        echo "Aborted."
        exit 0
    fi
fi

echo -e "${BLUE}📋 Setting up configuration files...${NC}"

# Copy environment template
if [ ! -f ".env" ]; then
    if [ -f ".env.example" ]; then
        cp ".env.example" ".env"
        echo -e "${GREEN}✅ Created .env from template${NC}"
    else
        echo -e "${RED}❌ .env.example not found${NC}"
        exit 1
    fi
else
    echo -e "${YELLOW}⚠️  .env already exists, skipping${NC}"
fi

# Copy production config template
if [ ! -f "group_vars/prod.yml" ]; then
    if [ -f "group_vars/prod.yml.example" ]; then
        cp "group_vars/prod.yml.example" "group_vars/prod.yml"
        echo -e "${GREEN}✅ Created group_vars/prod.yml from template${NC}"
    else
        echo -e "${RED}❌ group_vars/prod.yml.example not found${NC}"
        exit 1
    fi
else
    echo -e "${YELLOW}⚠️  group_vars/prod.yml already exists, skipping${NC}"
fi

# Copy inventory template
if [ ! -f "inventory/hosts.yml" ]; then
    if [ -f "inventory/hosts.yml.example" ]; then
        cp "inventory/hosts.yml.example" "inventory/hosts.yml"
        echo -e "${GREEN}✅ Created inventory/hosts.yml from template${NC}"
    else
        echo -e "${YELLOW}⚠️  inventory/hosts.yml.example not found${NC}"
    fi
else
    echo -e "${YELLOW}⚠️  inventory/hosts.yml already exists, skipping${NC}"
fi

# Create inventory backups directory
mkdir -p "inventory/backups"
echo -e "${GREEN}✅ Created inventory/backups directory${NC}"

echo ""
echo -e "${BLUE}📝 Next steps:${NC}"
echo "1. Edit .env with your DigitalOcean API token and settings:"
echo "   nano .env"
echo ""
echo "2. Edit group_vars/prod.yml with your applications:"
echo "   nano group_vars/prod.yml"
echo ""
echo "3. Encrypt your production configuration:"
echo "   ./scripts/encrypt-prod.sh encrypt"
echo ""
echo "4. Run the setup script:"
echo "   ./scripts/setup.sh"
echo ""
echo "5. Provision your first droplet:"
echo "   source scripts/setup-env.sh"
echo "   ansible-playbook playbooks/provision-droplet.yml"
echo ""
echo -e "${GREEN}🎉 Project initialized successfully!${NC}"
echo ""
echo -e "${YELLOW}💡 Remember to:${NC}"
echo "- Never commit .env or unencrypted prod.yml to version control"
echo "- Use a private fork for your encrypted configurations"
echo "- Keep your vault password secure" 