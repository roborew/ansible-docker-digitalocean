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

# Function to check for conflicting Ansible installations
check_ansible_conflicts() {
    echo -e "\n${BLUE}🔍 Checking for conflicting Ansible installations...${NC}"
    
    # Check for brew Ansible
    if command -v brew &> /dev/null && brew list ansible 2>/dev/null; then
        echo -e "${YELLOW}⚠️  Ansible installed via Homebrew detected${NC}"
        echo -e "${YELLOW}This can conflict with virtual environment installations.${NC}"
        echo ""
        read -p "Uninstall Homebrew Ansible and use virtual environment instead? (y/n): " -n 1 -r
        echo
        if [[ $REPLY =~ ^[Yy]$ ]]; then
            echo -e "${BLUE}🗑️  Uninstalling Homebrew Ansible...${NC}"
            brew uninstall ansible
            echo -e "${GREEN}✅ Homebrew Ansible uninstalled${NC}"
        else
            echo -e "${YELLOW}⚠️  Keeping Homebrew Ansible - you may encounter conflicts${NC}"
            echo -e "${YELLOW}If you have issues, run: brew uninstall ansible${NC}"
        fi
    fi
    
    # Check for system Ansible
    if command -v ansible &> /dev/null && [[ $(which ansible) != *"venv"* ]]; then
        ANSIBLE_PATH=$(which ansible)
        echo -e "${YELLOW}⚠️  System Ansible found at: $ANSIBLE_PATH${NC}"
        echo -e "${YELLOW}This may conflict with virtual environment installation${NC}"
    fi
}

# Function to setup Python virtual environment and install dependencies
setup_python_environment() {
    echo -e "\n${BLUE}🐍 Setting up Python virtual environment...${NC}"
    
    # Check Python version
    if ! command -v python3 &> /dev/null; then
        echo -e "${RED}❌ Python 3 not found${NC}"
        case "$OS" in
            "macos")
                echo "Install with: brew install python@3.11"
                ;;
            "linux")
                echo "Install with: sudo apt install python3 python3-venv python3-pip"
                ;;
        esac
        exit 1
    fi
    
    PYTHON_VERSION=$(python3 --version | cut -d' ' -f2)
    echo -e "${GREEN}✅ Python found: $PYTHON_VERSION${NC}"
    
    # Install venv if needed (Linux)
    if [[ "$OS" == "linux" ]]; then
        if ! python3 -m venv --help &> /dev/null; then
            echo -e "${BLUE}📦 Installing python3-venv...${NC}"
            case "$DISTRO" in
                "debian")
                    sudo apt update
                    sudo apt install -y python3-venv python3-pip
                    ;;
                "redhat")
                    sudo yum install -y python3-pip || sudo dnf install -y python3-pip
                    ;;
            esac
        fi
    fi
    
    # Remove existing venv if present
    if [[ -d "venv" ]]; then
        echo -e "${YELLOW}⚠️  Existing virtual environment found${NC}"
        read -p "Remove and recreate? (y/n): " -n 1 -r
        echo
        if [[ $REPLY =~ ^[Yy]$ ]]; then
            rm -rf venv/
            echo -e "${GREEN}✅ Removed existing virtual environment${NC}"
        else
            echo -e "${YELLOW}Keeping existing virtual environment${NC}"
            return 0
        fi
    fi
    
    # Create virtual environment
    echo -e "${BLUE}🏗️  Creating virtual environment...${NC}"
    python3 -m venv venv
    
    # Activate virtual environment
    source venv/bin/activate
    
    # Upgrade pip
    echo -e "${BLUE}⬆️  Upgrading pip...${NC}"
    pip install --upgrade pip setuptools wheel
    
    # Install requirements
    if [[ -f "requirements.txt" ]]; then
        echo -e "${BLUE}📦 Installing Python dependencies...${NC}"
        pip install -r requirements.txt
        echo -e "${GREEN}✅ Python dependencies installed${NC}"
    else
        echo -e "${RED}❌ requirements.txt not found${NC}"
        exit 1
    fi
    
    # Verify Ansible installation
    if command -v ansible &> /dev/null; then
        ANSIBLE_VERSION=$(ansible --version | head -n1)
        echo -e "${GREEN}✅ Ansible installed in virtual environment: $ANSIBLE_VERSION${NC}"
    else
        echo -e "${RED}❌ Ansible not found after installation${NC}"
        exit 1
    fi
}

# Function to install Ansible collections
install_ansible_collections() {
    echo -e "\n${BLUE}📦 Installing Ansible collections...${NC}"
    
    # Make sure we're in the venv
    if [[ "$VIRTUAL_ENV" == "" ]]; then
        source venv/bin/activate
    fi
    
    ansible-galaxy collection install community.digitalocean
    ansible-galaxy collection install community.docker
    
    echo -e "${GREEN}✅ Ansible collections installed${NC}"
}

# Function to check SSH configuration
check_ssh_config() {
    echo -e "\n${BLUE}🔑 Checking SSH configuration...${NC}"
    
    # Check for 1Password integration
    local onepassword_detected=false
    
    # Check for 1Password CLI
    if command -v op &> /dev/null; then
        echo -e "${GREEN}✅ 1Password CLI detected${NC}"
        onepassword_detected=true
    fi
    
    # Check for 1Password SSH agent configuration
    if grep -qi "1password" ~/.ssh/config 2>/dev/null; then
        echo -e "${GREEN}✅ 1Password SSH agent configured${NC}"
        onepassword_detected=true
    fi
    
    # Check if 1Password app is running (macOS)
    if [[ "$OSTYPE" == "darwin"* ]] && pgrep -f "1Password" >/dev/null 2>&1; then
        echo -e "${GREEN}✅ 1Password app running${NC}"
        onepassword_detected=true
    fi
    
    if [[ "$onepassword_detected" = false ]]; then
        echo -e "${YELLOW}⚠️  1Password not detected${NC}"
        echo -e "${YELLOW}💡 To use 1Password SSH agent, add to ~/.ssh/config:${NC}"
        echo "   Host *.digitalocean.com"
        echo "     IdentityAgent \"~/Library/Group Containers/2BUA8C4S2C.com.1password/t/agent.sock\""
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
    echo -e "${GREEN}4. Vault Password Setup:${NC}"
    echo ""
    echo -e "${YELLOW}This project uses encrypted files for security. You need to set up a vault password file.${NC}"
    echo ""
    read -p "Enter your vault password (will be saved to .vault_pass): " -s vault_password
    echo ""

    if [ -n "$vault_password" ]; then
        echo "$vault_password" > .vault_pass
        chmod 600 .vault_pass
        echo -e "${GREEN}✅ Vault password file created (.vault_pass)${NC}"
        echo -e "${BLUE}💡 This file is already in .gitignore for security${NC}"
    else
        echo -e "${YELLOW}⚠️  No password entered. You'll need to create .vault_pass manually${NC}"
        echo "   Run: echo 'your-password' > .vault_pass && chmod 600 .vault_pass"
    fi
    echo ""

    echo -e "${BOLD}${GREEN}🎉 Bootstrap Complete!${NC}"
    echo "======================="
    echo ""
    echo -e "${BLUE}📋 Next Steps:${NC}"
    echo ""
    echo "1. Edit your configuration:"
    echo "   nano .env                    # Add DigitalOcean API token & SSH keys"
    echo "   nano group_vars/prod.yml     # Add your applications"
    echo ""
    echo "2. Deploy your infrastructure:"
    echo "   ansible-playbook playbooks/provision-and-configure.yml"
    echo "   ansible-playbook playbooks/deploy-stack.yml"
    echo ""
    echo -e "${GREEN}🎉 Setup complete! All validation and encryption happens automatically in playbooks.${NC}"
    echo ""
    echo -e "${BOLD}💡 Environment Notes:${NC}"
    echo "• Your Python virtual environment is now activated"
    echo "• You'll see (venv) in your prompt when activated"
    echo "• For future sessions, run: source venv/bin/activate"
    echo "• Run 'deactivate' to exit the virtual environment"
    echo "• Keep your vault password secure (.vault_pass file)"
    echo "• Never commit .env or .vault_pass to version control"
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

    # Activate the environment automatically at the end
    echo -e "${BLUE}🎯 Activating Python environment...${NC}"
    source venv/bin/activate
    echo -e "${GREEN}✅ Environment activated! You can now run Ansible commands.${NC}"
}

# Main execution
main() {
    echo -e "${BLUE}🔍 Checking project structure...${NC}"
    check_project_structure
    
    echo -e "${BLUE}🔍 Detecting operating system...${NC}"
    detect_os
    
    # Check for conflicting Ansible installations
    check_ansible_conflicts
    
    # Setup Python virtual environment with all dependencies
    setup_python_environment
    
    # Install Ansible collections
    install_ansible_collections
    
    # Check SSH configuration
    check_ssh_config
    
    # Initialize project files
    initialize_project
    
    # Make scripts executable
    make_scripts_executable
    
    # Show next steps
    show_next_steps
}

# Run main function
main "$@" 