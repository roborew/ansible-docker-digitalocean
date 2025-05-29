#!/bin/bash
set -e

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

echo -e "${BLUE}🔑 Setting up deploy keys for private repositories...${NC}"

# Create necessary directories
mkdir -p files/ssh_keys
chmod 700 files/ssh_keys

# Function to generate deploy key for an app
generate_deploy_key() {
    local app_name=$1
    local email=${2:-"deploy@${app_name}.com"}
    
    echo -e "\n${YELLOW}📝 Generating deploy key for: ${app_name}${NC}"
    
    # Generate SSH key
    ssh-keygen -t ed25519 -f "files/ssh_keys/${app_name}_deploy_key" -C "$email" -N ""
    
    # Set proper permissions
    chmod 600 "files/ssh_keys/${app_name}_deploy_key"
    chmod 644 "files/ssh_keys/${app_name}_deploy_key.pub"
    
    echo -e "${GREEN}✅ Deploy key generated for ${app_name}${NC}"
    
    # Display the public key
    echo -e "\n${BLUE}📋 Add this PUBLIC key to your GitHub repository:${NC}"
    echo -e "${YELLOW}Repository:${NC} github.com/yourusername/${app_name}"
    echo -e "${YELLOW}Path:${NC} Settings → Deploy keys → Add deploy key"
    echo -e "${YELLOW}Title:${NC} ${app_name}-server-deploy"
    echo -e "${YELLOW}Key:${NC}"
    echo ""
    cat "files/ssh_keys/${app_name}_deploy_key.pub"
    echo ""
    echo -e "${YELLOW}✅ Check 'Allow write access' if you need push capability${NC}"
    echo -e "${RED}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
}

# Check if app configuration exists
if [ -f "group_vars/prod.yml" ]; then
    echo -e "${BLUE}🔍 Checking configured apps...${NC}"
    
    # Extract app names from YAML properly
    # Look for '- name: "appname"' or '- name: appname' patterns
    apps=$(grep -A 1 "^  - name:" group_vars/prod.yml | grep "name:" | sed 's/.*name: *["\'"'"']*\([^"'"'"']*\)["\'"'"']*.*/\1/' | tr '\n' ' ')
    
    if [ -n "$apps" ]; then
        for app in $apps; do
            # Skip empty app names
            if [ -n "$app" ] && [ "$app" != "" ]; then
                if [ ! -f "files/ssh_keys/${app}_deploy_key" ]; then
                    generate_deploy_key "$app"
                else
                    echo -e "${GREEN}✅ Deploy key already exists for: ${app}${NC}"
                    echo -e "${BLUE}📋 Public key for ${app}:${NC}"
                    cat "files/ssh_keys/${app}_deploy_key.pub"
                    echo ""
                fi
            fi
        done
    else
        echo -e "${YELLOW}⚠️  No apps found in group_vars/prod.yml${NC}"
    fi
else
    echo -e "${YELLOW}⚠️  No group_vars/prod.yml found${NC}"
    echo -e "${BLUE}💡 Generating example deploy key for 'myapp'...${NC}"
    generate_deploy_key "myapp"
fi

echo -e "\n${GREEN}🎉 Deploy key setup complete!${NC}"
echo -e "\n${BLUE}📋 Next steps:${NC}"
echo -e "1. ${YELLOW}Add the public keys to your GitHub repositories${NC}"
echo -e "2. ${YELLOW}For private repos, deploy with:${NC}"
echo -e "   ${GREEN}ansible-playbook playbooks/deploy.yml -e deploy_key_path=files/ssh_keys/APPNAME_deploy_key${NC}"
echo -e "3. ${YELLOW}For public repos, deploy normally:${NC}"
echo -e "   ${GREEN}ansible-playbook playbooks/deploy.yml${NC}"

echo -e "\n${BLUE}💡 Tips:${NC}"
echo -e "- ${YELLOW}Deploy keys are app-specific and read-only by default${NC}"
echo -e "- ${YELLOW}Enable 'Allow write access' only if you need push capability${NC}"
echo -e "- ${YELLOW}Keys are stored in files/ssh_keys/ and deployed automatically${NC}" 