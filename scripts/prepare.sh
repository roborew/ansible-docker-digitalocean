#!/bin/bash

# Environment preparation script
# Loads environment variables and validates everything is ready for deployment

set -e

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
BOLD='\033[1m'
NC='\033[0m' # No Color

echo -e "${BOLD}${BLUE}🔧 Preparing Environment${NC}"
echo "========================"
echo ""

# Check if required files exist
check_files() {
    local files_ok=true
    
    echo -e "${BLUE}📁 Checking required files...${NC}"
    
    if [[ ! -f ".env" ]]; then
        echo -e "${RED}❌ .env file not found${NC}"
        echo "   Run: ./scripts/bootstrap.sh (if first time)"
        echo "   Or: cp .env.example .env && nano .env"
        files_ok=false
    else
        echo -e "${GREEN}✅ .env file exists${NC}"
    fi
    
    if [[ ! -f "group_vars/prod.yml" ]]; then
        echo -e "${RED}❌ group_vars/prod.yml not found${NC}"
        echo "   Run: ./scripts/bootstrap.sh (if first time)"
        echo "   Or: cp group_vars/prod.yml.example group_vars/prod.yml && nano group_vars/prod.yml"
        files_ok=false
    else
        echo -e "${GREEN}✅ group_vars/prod.yml exists${NC}"
    fi
    
    if [[ "$files_ok" = false ]]; then
        echo -e "\n${RED}❌ Missing required files${NC}"
        exit 1
    fi
}

# Load and validate environment variables
load_and_check_env() {
    echo -e "\n${BLUE}🔧 Loading environment variables...${NC}"
    
    # Function to export variables from .env
    while IFS='=' read -r key value || [ -n "$key" ]; do
        # Skip comments and empty lines
        [[ $key =~ ^#.*$ ]] || [ -z "$key" ] && continue
        
        # Trim whitespace
        key=$(echo "$key" | xargs)
        value=$(echo "$value" | xargs)
        
        # Export the variable
        export "$key=$value"
    done < .env
    
    echo -e "${GREEN}✅ Environment variables loaded${NC}"
    
    # Validate required variables
    echo -e "\n${BLUE}🔍 Validating environment variables...${NC}"
    
    local vars_ok=true
    local required_vars=("DO_API_TOKEN" "DO_SSH_KEYS" "SERVER_USERNAME" "ROOT_PASSWORD")
    
    for var in "${required_vars[@]}"; do
        if [[ -z "$(eval echo \$$var)" ]]; then
            echo -e "${RED}❌ $var is not set or empty${NC}"
            vars_ok=false
        else
            echo -e "${GREEN}✅ $var is set${NC}"
        fi
    done
    
    if [[ "$vars_ok" = false ]]; then
        echo -e "\n${RED}❌ Missing environment variables. Please edit .env:${NC}"
        echo "   nano .env"
        exit 1
    fi
}

# Check Ansible installation
check_ansible() {
    echo -e "\n${BLUE}🤖 Checking Ansible...${NC}"
    
    if ! command -v ansible &> /dev/null; then
        echo -e "${RED}❌ Ansible not found${NC}"
        echo "   Run: ./scripts/bootstrap.sh"
        exit 1
    else
        local version=$(ansible --version | head -n1)
        echo -e "${GREEN}✅ Ansible installed: $version${NC}"
    fi
}

# Check SSH keys
check_ssh() {
    echo -e "\n${BLUE}🔑 Checking SSH configuration...${NC}"
    
    # Check if SSH agent has keys
    if ssh-add -l &>/dev/null; then
        echo -e "${GREEN}✅ SSH agent has keys loaded${NC}"
    else
        echo -e "${YELLOW}⚠️  No SSH keys in agent, attempting to load...${NC}"
        # Try to load common keys
        for key_type in ed25519 rsa ecdsa; do
            if [[ -f ~/.ssh/id_$key_type ]]; then
                ssh-add ~/.ssh/id_$key_type 2>/dev/null && echo -e "${GREEN}✅ Loaded ~/.ssh/id_$key_type${NC}" || true
            fi
        done
    fi
    
    # Check for SSH keys
    local key_found=false
    for key_type in ed25519 rsa ecdsa; do
        if [[ -f ~/.ssh/id_$key_type ]]; then
            echo -e "${GREEN}✅ SSH key found: ~/.ssh/id_$key_type${NC}"
            key_found=true
            break
        fi
    done
    
    if [[ "$key_found" = false ]]; then
        echo -e "${YELLOW}⚠️  No SSH keys found in ~/.ssh/${NC}"
        echo "   Generate one with: ssh-keygen -t ed25519"
    fi
}

# Test DigitalOcean API connection
test_do_api() {
    echo -e "\n${BLUE}🌐 Testing DigitalOcean API connection...${NC}"
    
    if command -v curl &> /dev/null; then
        local response=$(curl -s -o /dev/null -w "%{http_code}" \
            -H "Authorization: Bearer $DO_API_TOKEN" \
            "https://api.digitalocean.com/v2/account" 2>/dev/null || echo "000")
        
        if [[ "$response" == "200" ]]; then
            echo -e "${GREEN}✅ DigitalOcean API connection successful${NC}"
        elif [[ "$response" == "401" ]]; then
            echo -e "${RED}❌ DigitalOcean API authentication failed${NC}"
            echo "   Check your DO_API_TOKEN in .env"
            exit 1
        else
            echo -e "${YELLOW}⚠️  Could not test DigitalOcean API (HTTP $response)${NC}"
        fi
    else
        echo -e "${YELLOW}⚠️  curl not found, skipping API test${NC}"
    fi
}

# Main function
main() {
    check_files
    load_and_check_env
    check_ansible
    check_ssh
    test_do_api
    
    echo ""
    echo -e "${BOLD}${GREEN}🎉 Environment Ready!${NC}"
    echo ""
    echo -e "${YELLOW}You can now run:${NC}"
    echo "  ansible-playbook playbooks/site.yml              # Provision & configure"
    echo "  ansible-playbook playbooks/deploy-stack.yml      # Deploy applications"
    echo ""
    echo -e "${BLUE}💡 Environment variables are loaded in this shell session${NC}"
}

# Check if script is being sourced or executed
if [[ "${BASH_SOURCE[0]}" == "${0}" ]]; then
    # Script is being executed, not sourced
    echo -e "${YELLOW}💡 Tip: Source this script to keep environment variables:${NC}"
    echo "   source scripts/prepare.sh"
    echo ""
    main "$@"
else
    # Script is being sourced
    main "$@"
fi 