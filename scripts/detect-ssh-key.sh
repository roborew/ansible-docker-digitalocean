#!/bin/bash

# SSH Key Detection Script
# Supports both 1Password SSH Agent and local SSH keys
# Outputs only the file path for reliable parsing
# Prioritizes 1Password on macOS as it's more manageable

set -e

# Function to check 1Password SSH agent (priority on macOS)
check_1password_ssh() {
    if command -v op >/dev/null 2>&1; then
        # Check if 1Password SSH agent is running
        if pgrep -f "1Password.*ssh-agent" >/dev/null 2>&1; then
            # Try to list SSH keys from 1Password (with timeout)
            if timeout 10 ssh-add -L 2>/dev/null | grep -q "ssh-"; then
                # Get the first available key
                local first_key=$(timeout 10 ssh-add -L 2>/dev/null | head -n1)
                if [[ -n "$first_key" ]]; then
                    # Create a temporary file with the public key
                    local temp_key="/tmp/op_ssh_key_$$.pub"
                    echo "$first_key" > "$temp_key"
                    echo "$temp_key"
                    return 0
                fi
            fi
        fi
    fi
    return 1
}

# Function to find local SSH keys (fallback)
find_local_ssh_keys() {
    local ssh_dir="$HOME/.ssh"
    local key_types=("ed25519" "rsa" "ecdsa")
    
    for key_type in "${key_types[@]}"; do
        local pub_key="$ssh_dir/id_${key_type}.pub"
        if [[ -f "$pub_key" ]]; then
            echo "$pub_key"
            return 0
        fi
    done
    
    return 1
}

# Check if SSH_PUBLIC_KEY_PATH is set in environment (highest priority)
if [[ -n "${SSH_PUBLIC_KEY_PATH}" && -f "${SSH_PUBLIC_KEY_PATH}" ]]; then
    echo "${SSH_PUBLIC_KEY_PATH}"
    exit 0
fi

# On macOS, prioritize 1Password SSH agent
if [[ "$OSTYPE" == "darwin"* ]]; then
    if check_1password_ssh; then
        exit 0
    fi
fi

# Fall back to local SSH keys
if find_local_ssh_keys; then
    exit 0
fi

# Try 1Password on non-macOS systems as last resort
if check_1password_ssh; then
    exit 0
fi

# No keys found
exit 1 