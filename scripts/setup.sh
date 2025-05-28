#!/bin/bash

# Enhanced Ansible Setup Script
# Handles dependency installation and environment setup

set -e

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

echo -e "${BLUE}🚀 Ansible DigitalOcean Setup${NC}"
echo "=================================="

# Function to detect OS
detect_os() {
    if [[ "$OSTYPE" == "darwin"* ]]; then
        echo "macOS"
    elif [[ "$OSTYPE" == "linux-gnu"* ]]; then
        if command -v apt-get >/dev/null 2>&1; then
            echo "ubuntu"
        else
            echo "linux"
        fi
    else
        echo "unknown"
    fi
}

# Function to load environment variables
load_env() {
    if [[ -f ".env" ]]; then
        echo -e "${GREEN}📄 Loading environment variables from .env file...${NC}"
        set -a  # Automatically export all variables
        source .env
        set +a  # Turn off automatic export
        echo -e "${GREEN}✅ Environment variables loaded${NC}"
        return 0
    else
        echo -e "${YELLOW}⚠️  No .env file found. You'll need to set environment variables manually.${NC}"
        return 1
    fi
}

# Function to run ansible with environment loaded
run_ansible() {
    load_env
    echo -e "${BLUE}🎭 Running Ansible playbook...${NC}"
    "$@"
}

# Export the function so it can be used
export -f run_ansible

# Setup script for Ansible DigitalOcean deployment

echo "🚀 Setting up Ansible DigitalOcean deployment environment..."

# Load .env file if it exists
if [ -f .env ]; then
    echo "📄 Loading environment variables from .env file..."
    export $(grep -v '^#' .env | xargs)
    echo "✅ Environment variables loaded"
else
    echo "💡 No .env file found. You can create one from env.example for easier configuration."
fi

# Detect operating system
OS="unknown"
if [[ "$OSTYPE" == "darwin"* ]]; then
    OS="macos"
elif [[ "$OSTYPE" == "linux-gnu"* ]]; then
    if command -v apt &> /dev/null; then
        OS="ubuntu"
    else
        OS="linux"
    fi
fi

echo "🖥️  Detected OS: $OS"

# Check if Ansible is installed
if command -v ansible &> /dev/null; then
    ANSIBLE_VERSION=$(ansible --version | head -n1 | cut -d' ' -f3)
    echo "✅ Ansible is already installed (version $ANSIBLE_VERSION)"
else
    echo "📦 Installing Ansible..."
    case $OS in
        "macos")
            if ! command -v brew &> /dev/null; then
                echo "❌ Homebrew is required but not installed. Please install Homebrew first:"
                echo "   /bin/bash -c \"\$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)\""
                exit 1
            fi
            brew install ansible
            ;;
        "ubuntu")
            if ! command -v python3 &> /dev/null; then
                echo "❌ Python 3 is required but not installed. Please install Python 3 first."
                exit 1
            fi
            if ! command -v pip3 &> /dev/null; then
                echo "❌ pip3 is required but not installed. Please install pip3 first."
                exit 1
            fi
            pip3 install ansible
            ;;
        *)
            echo "❌ Unsupported OS. Please install Ansible manually."
            exit 1
            ;;
    esac
    echo "✅ Ansible installed successfully"
fi

# Install Python requirements (only if not on macOS with brew-installed ansible)
if [[ "$OS" != "macos" ]] || ! brew list ansible &> /dev/null; then
    if command -v pip3 &> /dev/null; then
        echo "📦 Installing Python requirements..."
        pip3 install -r requirements.txt
    else
        echo "⚠️  pip3 not found, skipping Python requirements installation"
    fi
fi

# Install Ansible collections
echo "📦 Installing Ansible collections..."
ansible-galaxy collection install community.digitalocean

# SSH Key handling
echo ""
echo "🔑 SSH Key Configuration:"

# Check for 1Password CLI
if command -v op &> /dev/null; then
    echo "✅ 1Password CLI detected"
    echo "💡 You can use 1Password SSH keys with the following options:"
    echo "   1. Use 1Password SSH agent (recommended)"
    echo "   2. Export a key from 1Password to ~/.ssh/"
    echo ""
    echo "📖 To use 1Password SSH agent:"
    echo "   - Enable SSH agent in 1Password settings"
    echo "   - Add your SSH key to 1Password"
    echo "   - Configure SSH to use 1Password agent"
    echo ""
    
    # Check if SSH agent is configured for 1Password
    if grep -q "IdentityAgent.*1Password" ~/.ssh/config 2>/dev/null; then
        echo "✅ 1Password SSH agent appears to be configured"
    else
        echo "💡 To configure 1Password SSH agent, add to ~/.ssh/config:"
        echo "   Host *"
        echo "     IdentityAgent \"~/Library/Group Containers/2BUA8C4S2C.com.1password/t/agent.sock\""
    fi
else
    echo "⚠️  1Password CLI not detected"
fi

# Check for existing SSH keys
SSH_KEY_FOUND=false
for key_type in rsa ed25519 ecdsa; do
    if [ -f ~/.ssh/id_$key_type ]; then
        echo "✅ SSH key found: ~/.ssh/id_$key_type"
        SSH_KEY_FOUND=true
        
        # Display public key
        echo ""
        echo "🔑 Your SSH public key (add this to your DigitalOcean account):"
        echo "=================================================="
        cat ~/.ssh/id_$key_type.pub
        echo "=================================================="
        break
    fi
done

if [ "$SSH_KEY_FOUND" = false ]; then
    echo "🔑 No SSH key found. You have several options:"
    echo "   1. Use 1Password SSH keys (recommended if you have 1Password)"
    echo "   2. Generate a new SSH key"
    echo ""
    read -p "Generate a new SSH key? (y/n): " -n 1 -r
    echo
    if [[ $REPLY =~ ^[Yy]$ ]]; then
        ssh-keygen -t ed25519 -f ~/.ssh/id_ed25519 -N ""
        echo "✅ SSH key generated at ~/.ssh/id_ed25519"
        echo ""
        echo "🔑 Your new SSH public key:"
        echo "=================================================="
        cat ~/.ssh/id_ed25519.pub
        echo "=================================================="
    fi
fi

echo ""

# Run environment setup if .env exists
if [ -f .env ]; then
    echo "🔄 Running environment setup..."
    source scripts/setup-env.sh
fi 

# Define required environment variables
REQUIRED_ENV_VARS=(
    "DO_API_TOKEN:DigitalOcean API Token"
    "DO_SSH_KEYS:SSH Key Names"
    "SERVER_USERNAME:Server Username"
    "ROOT_PASSWORD:Root Password"
)

# Check for environment variables
echo "🔍 Checking environment variables..."
missing_vars=0

for var_info in "${REQUIRED_ENV_VARS[@]}"; do
    # Split the string into variable name and description
    var_name="${var_info%%:*}"
    var_desc="${var_info#*:}"
    
    if [ -z "${!var_name}" ]; then
        echo -e "${RED}❌ $var_desc ($var_name) is not set${NC}"
        missing_vars=1
    else
        echo -e "${GREEN}✅ $var_desc is set${NC}"
    fi
done

if [ $missing_vars -eq 1 ]; then
    echo -e "\n${YELLOW}⚠️  Some required variables are missing.${NC}"
    echo "Please ensure your .env file contains all required variables:"
    echo "1. Copy .env.example to .env if you haven't already:"
    echo "   cp .env.example .env"
    echo "2. Edit .env and fill in your values:"
    echo "   - DO_API_TOKEN (from https://cloud.digitalocean.com/account/api/tokens)"
    echo "   - DO_SSH_KEYS (comma-separated list of SSH key names)"
    echo "   - SERVER_USERNAME (the non-root user to create)"
    echo "   - ROOT_PASSWORD (secure password for root user)"
    echo ""
fi

echo ""
echo "🎉 Setup complete! Next steps:"
echo "1. Copy env.example to .env and configure your settings (if not done)"
echo "2. Add your SSH public key to DigitalOcean: https://cloud.digitalocean.com/account/security"
echo "3. Run: source scripts/setup-env.sh to load your environment"
echo "4. Run: ansible-playbook playbooks/site.yml"
echo ""

