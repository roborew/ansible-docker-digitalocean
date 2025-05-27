#!/bin/bash

# Setup script for Ansible DigitalOcean deployment

set -e

echo "🚀 Setting up Ansible DigitalOcean deployment environment..."

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

# Check for DigitalOcean API token
if [ -z "$DO_API_TOKEN" ]; then
    echo "⚠️  DO_API_TOKEN environment variable is not set."
    echo "   Please set it with: export DO_API_TOKEN=your_token_here"
    echo "   You can get your token from: https://cloud.digitalocean.com/account/api/tokens"
else
    echo "✅ DO_API_TOKEN is set"
fi

echo ""
echo "🎉 Setup complete! Next steps:"
echo "1. Add your SSH public key to DigitalOcean: https://cloud.digitalocean.com/account/security"
echo "2. Set your DO_API_TOKEN: export DO_API_TOKEN=your_token_here"
echo "3. Update group_vars/all.yml with your SSH key IDs and preferences"
echo "4. Run: ansible-playbook playbooks/site.yml"
echo "" 