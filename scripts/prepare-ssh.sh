#!/bin/bash

# SSH Preparation Script
# Ensures SSH agent and 1Password are properly configured before Ansible runs

set -e

echo "🔑 Preparing SSH authentication..."

# Function to check if 1Password SSH agent is available
check_1password_ssh() {
    if command -v op >/dev/null 2>&1; then
        echo "✓ 1Password CLI found"
        
        # Check if 1Password SSH agent is running
        if pgrep -f "1Password.*ssh-agent" >/dev/null 2>&1; then
            echo "✓ 1Password SSH agent is running"
            
            # Try to list SSH keys with a longer timeout
            if timeout 15 ssh-add -L 2>/dev/null | grep -q "ssh-"; then
                echo "✓ 1Password SSH keys are available:"
                timeout 15 ssh-add -L 2>/dev/null | head -3 | while read -r line; do
                    key_type=$(echo "$line" | awk '{print $1}')
                    key_comment=$(echo "$line" | awk '{print $NF}')
                    echo "  - $key_type key: $key_comment"
                done
                return 0
            else
                echo "❌ 1Password SSH keys not accessible. You may need to:"
                echo "   1. Unlock 1Password"
                echo "   2. Authenticate when prompted"
                echo "   3. Make sure 'SSH Agent' is enabled in 1Password settings"
                return 1
            fi
        else
            echo "❌ 1Password SSH agent not running"
            echo "   Please enable SSH Agent in 1Password -> Settings -> Developer"
            return 1
        fi
    else
        echo "❌ 1Password CLI not found"
        return 1
    fi
}

# Function to check local SSH keys
check_local_ssh() {
    local ssh_dir="$HOME/.ssh"
    echo "🔍 Checking for local SSH keys in $ssh_dir"
    
    for key_type in ed25519 rsa ecdsa; do
        local key_file="$ssh_dir/id_${key_type}"
        local pub_file="$ssh_dir/id_${key_type}.pub"
        
        if [[ -f "$key_file" && -f "$pub_file" ]]; then
            echo "✓ Found $key_type key pair"
            
            # Add to SSH agent if not already loaded
            if ! ssh-add -l 2>/dev/null | grep -q "$key_file"; then
                echo "  Adding to SSH agent..."
                ssh-add "$key_file" 2>/dev/null || echo "  ⚠️  Failed to add to SSH agent"
            else
                echo "  Already loaded in SSH agent"
            fi
            return 0
        fi
    done
    
    echo "❌ No local SSH key pairs found"
    return 1
}

# Test SSH connection to a host (optional, for debugging)
test_ssh_connection() {
    local host="$1"
    if [[ -n "$host" ]]; then
        echo "🔗 Testing SSH connection to $host..."
        if ssh -o ConnectTimeout=10 -o StrictHostKeyChecking=no -o UserKnownHostsFile=/dev/null root@"$host" "echo 'SSH connection successful'" 2>/dev/null; then
            echo "✓ SSH connection test successful"
        else
            echo "❌ SSH connection test failed"
            echo "   This is expected if the server isn't set up yet"
        fi
    fi
}

# Main execution
echo "Starting SSH preparation..."

# Check SSH agent
if ! pgrep -x ssh-agent >/dev/null; then
    echo "🚀 Starting SSH agent..."
    eval "$(ssh-agent -s)"
fi

# On macOS, prioritize 1Password
if [[ "$OSTYPE" == "darwin"* ]]; then
    if check_1password_ssh; then
        echo "✅ 1Password SSH ready"
    elif check_local_ssh; then
        echo "✅ Local SSH keys ready"
    else
        echo "❌ No SSH authentication available"
        exit 1
    fi
else
    # On other systems, try local first, then 1Password
    if check_local_ssh; then
        echo "✅ Local SSH keys ready"
    elif check_1password_ssh; then
        echo "✅ 1Password SSH ready"
    else
        echo "❌ No SSH authentication available"
        exit 1
    fi
fi

# Test connection if host provided
if [[ -n "$1" ]]; then
    test_ssh_connection "$1"
fi

echo "🎉 SSH preparation complete!" 