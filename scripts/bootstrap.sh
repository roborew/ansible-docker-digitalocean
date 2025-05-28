#!/bin/bash

# Bootstrap script for Ansible DigitalOcean Deployment
# This script handles both Ansible setup and project initialization
# Run this ONCE when you first clone the repository

set -e

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
BOLD='\033[1m'
NC='\033[0m' # No Color

echo -e "${BOLD}${BLUE}🚀 Ansible DigitalOcean Deployment - Bootstrap${NC}"
echo "=============================================="
echo ""

# Function to check if we're in the right directory
check_project_structure() {
    if [[ ! -f "ansible.cfg" || ! -d "playbooks" || ! -d "roles" ]]; then
        echo -e "${RED}❌ Error: This doesn't appear to be the robo-ansible project root${NC}"
        echo "Please run this script from the project root directory"
        exit 1
    fi
}

# Function to detect OS and set package manager
detect_os() {
    if [[ "$OSTYPE" == "darwin"* ]]; then
        OS="macos"
        if ! command -v brew &> /dev/null; then
            echo -e "${RED}❌ Homebrew not found. Please install Homebrew first:${NC}"
            echo "https://brew.sh/"
            exit 1
        fi
    elif [[ "$OSTYPE" == "linux-gnu"* ]]; then
        OS="linux"
        if [[ -f /etc/debian_version ]]; then
            DISTRO="debian"
        elif [[ -f /etc/redhat-release ]]; then
            DISTRO="redhat"
        else
            echo -e "${YELLOW}⚠️  Unknown Linux distribution, assuming Debian-based${NC}"
            DISTRO="debian"
        fi
    else
        echo -e "${RED}❌ Unsupported operating system: $OSTYPE${NC}"
        exit 1
    fi
    
    echo -e "${GREEN}✅ Detected OS: $OS${NC}"
}

# Function to install Ansible
install_ansible() {
    echo -e "\n${BLUE}📦 Installing Ansible and dependencies...${NC}"
    
    case "$OS" in
        "macos")
            echo "Installing via Homebrew..."
            brew update
            brew install ansible
            ;;
        "linux")
            case "$DISTRO" in
                "debian")
                    echo "Installing via apt..."
                    sudo apt update
                    sudo apt install -y python3 python3-pip python3-venv
                    python3 -m pip install --user ansible
                    # Add to PATH if not already there
                    if [[ ":$PATH:" != *":$HOME/.local/bin:"* ]]; then
                        echo 'export PATH="$HOME/.local/bin:$PATH"' >> ~/.bashrc
                        export PATH="$HOME/.local/bin:$PATH"
                    fi
                    ;;
                "redhat")
                    echo "Installing via yum/dnf..."
                    sudo yum install -y python3 python3-pip || sudo dnf install -y python3 python3-pip
                    python3 -m pip install --user ansible
                    ;;
            esac
            ;;
    esac
    
    # Verify installation
    if command -v ansible &> /dev/null; then
        ANSIBLE_VERSION=$(ansible --version | head -n1)
        echo -e "${GREEN}✅ Ansible installed: $ANSIBLE_VERSION${NC}"
    else
        echo -e "${RED}❌ Ansible installation failed${NC}"
        exit 1
    fi
}

# Function to install Python dependencies
install_python_deps() {
    echo -e "\n${BLUE}🐍 Installing Python dependencies...${NC}"
    
    if [[ -f "requirements.txt" ]]; then
        if command -v pip3 &> /dev/null; then
            pip3 install --user -r requirements.txt
        elif command -v pip &> /dev/null; then
            pip install --user -r requirements.txt
        else
            echo -e "${YELLOW}⚠️  pip not found, skipping Python dependencies${NC}"
        fi
        echo -e "${GREEN}✅ Python dependencies installed${NC}"
    else
        echo -e "${YELLOW}⚠️  requirements.txt not found, skipping${NC}"
    fi
}

# Function to install Ansible collections
install_ansible_collections() {
    echo -e "\n${BLUE}📦 Installing Ansible collections...${NC}"
    
    ansible-galaxy collection install community.digitalocean
    ansible-galaxy collection install community.docker
    
    echo -e "${GREEN}✅ Ansible collections installed${NC}"
}

# Function to check SSH configuration
check_ssh_config() {
    echo -e "\n${BLUE}🔑 Checking SSH configuration...${NC}"
    
    # Check for 1Password CLI
    if command -v op &> /dev/null; then
        echo -e "${GREEN}✅ 1Password CLI detected${NC}"
        
        # Check if SSH agent is configured for 1Password
        if grep -q "IdentityAgent.*1Password" ~/.ssh/config 2>/dev/null; then
            echo -e "${GREEN}✅ 1Password SSH agent appears to be configured${NC}"
        else
            echo -e "${YELLOW}💡 To use 1Password SSH agent, add to ~/.ssh/config:${NC}"
            echo "   Host *.digitalocean.com"
            echo "     IdentityAgent \"~/Library/Group Containers/2BUA8C4S2C.com.1password/t/agent.sock\""
        fi
    else
        echo -e "${YELLOW}⚠️  1Password CLI not detected${NC}"
    fi
    
    # Check for existing SSH keys
    SSH_KEY_FOUND=false
    for key_type in ed25519 rsa ecdsa; do
        if [[ -f ~/.ssh/id_$key_type ]]; then
            echo -e "${GREEN}✅ SSH key found: ~/.ssh/id_$key_type${NC}"
            SSH_KEY_FOUND=true
            break
        fi
    done
    
    if [[ "$SSH_KEY_FOUND" = false ]]; then
        echo -e "${YELLOW}⚠️  No SSH key found${NC}"
        read -p "Generate a new SSH key? (y/n): " -n 1 -r
        echo
        if [[ $REPLY =~ ^[Yy]$ ]]; then
            ssh-keygen -t ed25519 -f ~/.ssh/id_ed25519 -N ""
            echo -e "${GREEN}✅ SSH key generated at ~/.ssh/id_ed25519${NC}"
        fi
    fi
    
    # Ensure SSH agent has keys
    if [[ -z "$(ssh-add -l 2>/dev/null)" ]]; then
        echo -e "${YELLOW}💡 Adding SSH keys to agent...${NC}"
        for key_type in ed25519 rsa ecdsa; do
            if [[ -f ~/.ssh/id_$key_type ]]; then
                ssh-add ~/.ssh/id_$key_type 2>/dev/null || true
            fi
        done
    fi
}

# Function to initialize project files
initialize_project() {
    echo -e "\n${BLUE}📋 Initializing project files...${NC}"
    
    # Check if already initialized
    if [[ -f ".env" && -f "group_vars/prod.yml" ]]; then
        echo -e "${YELLOW}⚠️  Project appears to be already initialized${NC}"
        read -p "Reinitialize anyway? (y/n): " -n 1 -r
        echo
        if [[ ! $REPLY =~ ^[Yy]$ ]]; then
            echo "Skipping project initialization"
            return 0
        fi
    fi
    
    # Copy environment template
    if [[ ! -f ".env" ]]; then
        if [[ -f ".env.example" ]]; then
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
    if [[ ! -f "group_vars/prod.yml" ]]; then
        if [[ -f "group_vars/prod.yml.example" ]]; then
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
    if [[ ! -f "inventory/hosts.yml" ]]; then
        if [[ -f "inventory/hosts.yml.example" ]]; then
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
}

# Function to make scripts executable
make_scripts_executable() {
    echo -e "\n${BLUE}🔧 Making scripts executable...${NC}"
    
    chmod +x scripts/*.sh 2>/dev/null || true
    echo -e "${GREEN}✅ Scripts are now executable${NC}"
}

# Function to display next steps
show_next_steps() {
    echo ""
    echo -e "${BOLD}${GREEN}🎉 Bootstrap Complete!${NC}"
    echo "======================="
    echo ""
    echo -e "${BOLD}📝 Next Steps:${NC}"
    echo ""
    echo -e "${YELLOW}1. Configure your environment:${NC}"
    echo "   nano .env"
    echo "   # Add your DigitalOcean API token and SSH key names"
    echo ""
    echo -e "${YELLOW}2. Configure your applications:${NC}"
    echo "   nano group_vars/prod.yml"
    echo "   # Add your apps to deploy"
    echo ""
    echo -e "${YELLOW}3. Encrypt production configuration:${NC}"
    echo "   ./scripts/encrypt-prod.sh encrypt"
    echo ""
    echo -e "${YELLOW}4. Load environment and deploy:${NC}"
    echo "   source scripts/setup-env.sh"
    echo "   ansible-playbook playbooks/site.yml"
    echo ""
    echo -e "${BOLD}💡 Important Notes:${NC}"
    echo "• Always run 'source scripts/setup-env.sh' before using ansible"
    echo "• Keep your vault password secure"
    echo "• Never commit .env or unencrypted prod.yml to version control"
    echo ""
    
    if [[ "$SSH_KEY_FOUND" = true ]]; then
        echo -e "${YELLOW}🔑 Don't forget to add your SSH public key to DigitalOcean:${NC}"
        echo "https://cloud.digitalocean.com/account/security"
        echo ""
        echo "Your public key:"
        for key_type in ed25519 rsa ecdsa; do
            if [[ -f ~/.ssh/id_$key_type.pub ]]; then
                echo "=================================================="
                cat ~/.ssh/id_$key_type.pub
                echo "=================================================="
                break
            fi
        done
    fi
}

# Main execution
main() {
    echo -e "${BLUE}🔍 Checking project structure...${NC}"
    check_project_structure
    
    echo -e "${BLUE}🔍 Detecting operating system...${NC}"
    detect_os
    
    # Check if Ansible is already installed
    if ! command -v ansible &> /dev/null; then
        install_ansible
    else
        ANSIBLE_VERSION=$(ansible --version | head -n1)
        echo -e "${GREEN}✅ Ansible already installed: $ANSIBLE_VERSION${NC}"
    fi
    
    install_python_deps
    install_ansible_collections
    check_ssh_config
    initialize_project
    make_scripts_executable
    show_next_steps
}

# Run main function
main "$@" 