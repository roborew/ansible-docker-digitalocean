#!/bin/bash

# 1Password SSH Helper Script
# Helps manage SSH keys with 1Password and DigitalOcean

set -e

echo "🔑 1Password SSH Helper"
echo "======================="

# Check if 1Password CLI is installed
if ! command -v op &> /dev/null; then
    echo "❌ 1Password CLI is not installed."
    echo "   Install it first:"
    echo "   macOS: brew install --cask 1password-cli"
    echo "   Ubuntu: See README.md for installation instructions"
    exit 1
fi

# Check if user is signed in to 1Password
if ! op account list &> /dev/null; then
    echo "🔐 Please sign in to 1Password CLI first:"
    echo "   op signin"
    exit 1
fi

echo "✅ 1Password CLI is ready"
echo ""

# Function to list SSH keys in 1Password
list_ssh_keys() {
    echo "🔍 SSH keys in 1Password:"
    echo "========================"
    
    # List SSH keys
    op item list --categories "SSH Key" --format json | jq -r '.[] | "\(.id) - \(.title)"' 2>/dev/null || {
        echo "No SSH keys found in 1Password or jq not installed"
        echo "You can list them manually with: op item list --categories 'SSH Key'"
    }
    echo ""
}

# Function to get public key from 1Password
get_public_key() {
    local key_id="$1"
    echo "📋 Getting public key for: $key_id"
    
    # Get the public key
    public_key=$(op item get "$key_id" --fields "public key" 2>/dev/null || {
        echo "❌ Could not retrieve public key. Check the key ID."
        return 1
    })
    
    echo "✅ Public key retrieved:"
    echo "========================"
    echo "$public_key"
    echo "========================"
    echo ""
    
    # Offer to copy to clipboard
    if command -v pbcopy &> /dev/null; then
        read -p "Copy to clipboard? (y/n): " -n 1 -r
        echo
        if [[ $REPLY =~ ^[Yy]$ ]]; then
            echo "$public_key" | pbcopy
            echo "✅ Copied to clipboard!"
        fi
    elif command -v xclip &> /dev/null; then
        read -p "Copy to clipboard? (y/n): " -n 1 -r
        echo
        if [[ $REPLY =~ ^[Yy]$ ]]; then
            echo "$public_key" | xclip -selection clipboard
            echo "✅ Copied to clipboard!"
        fi
    fi
    
    return 0
}

# Function to check SSH agent configuration
check_ssh_agent() {
    echo "🔧 Checking SSH agent configuration:"
    echo "===================================="
    
    # Check if SSH config exists and has 1Password configuration
    if [ -f ~/.ssh/config ]; then
        if grep -q "IdentityAgent.*1Password" ~/.ssh/config; then
            echo "✅ 1Password SSH agent is configured in ~/.ssh/config"
        else
            echo "⚠️  1Password SSH agent not found in ~/.ssh/config"
            echo "   Add this to ~/.ssh/config:"
            echo "   Host *"
            echo "     IdentityAgent \"~/Library/Group Containers/2BUA8C4S2C.com.1password/t/agent.sock\""
        fi
    else
        echo "⚠️  ~/.ssh/config does not exist"
        echo "   Create it with 1Password SSH agent configuration"
    fi
    
    # Check if 1Password SSH agent socket exists
    if [ -S ~/Library/Group\ Containers/2BUA8C4S2C.com.1password/t/agent.sock ]; then
        echo "✅ 1Password SSH agent socket is available"
    else
        echo "❌ 1Password SSH agent socket not found"
        echo "   Make sure SSH agent is enabled in 1Password settings"
    fi
    
    echo ""
}

# Function to test SSH connection
test_ssh_connection() {
    local host="$1"
    if [ -z "$host" ]; then
        read -p "Enter hostname or IP to test: " host
    fi
    
    echo "🧪 Testing SSH connection to: $host"
    echo "=================================="
    
    ssh -o ConnectTimeout=10 -o BatchMode=yes "$host" "echo 'SSH connection successful!'" 2>/dev/null && {
        echo "✅ SSH connection successful!"
    } || {
        echo "❌ SSH connection failed"
        echo "   Check that:"
        echo "   - The host is reachable"
        echo "   - Your SSH key is added to the server"
        echo "   - 1Password SSH agent is working"
    }
    echo ""
}

# Main menu
show_menu() {
    echo "Choose an option:"
    echo "1. List SSH keys in 1Password"
    echo "2. Get public key from 1Password"
    echo "3. Check SSH agent configuration"
    echo "4. Test SSH connection"
    echo "5. Exit"
    echo ""
}

# Main loop
while true; do
    show_menu
    read -p "Enter your choice (1-5): " choice
    echo ""
    
    case $choice in
        1)
            list_ssh_keys
            ;;
        2)
            read -p "Enter SSH key ID or name: " key_id
            get_public_key "$key_id"
            ;;
        3)
            check_ssh_agent
            ;;
        4)
            test_ssh_connection
            ;;
        5)
            echo "👋 Goodbye!"
            exit 0
            ;;
        *)
            echo "❌ Invalid choice. Please try again."
            echo ""
            ;;
    esac
done 