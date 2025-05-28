#!/bin/bash

# SSH Key ID Lookup Script
# Converts SSH key names to IDs using DigitalOcean API

set -e

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# Check if DO_API_TOKEN is set
if [ -z "$DO_API_TOKEN" ]; then
    echo -e "${RED}❌ DO_API_TOKEN environment variable is not set${NC}"
    echo -e "${YELLOW}💡 Please set it with: export DO_API_TOKEN=your_token_here${NC}"
    exit 1
fi

# Function to get all SSH keys and save to temp file
get_all_keys() {
    echo -e "${BLUE}🔍 Fetching SSH keys from DigitalOcean...${NC}" >&2
    
    local temp_file=$(mktemp)
    
    if curl -s -X GET \
        -H "Content-Type: application/json" \
        -H "Authorization: Bearer $DO_API_TOKEN" \
        "https://api.digitalocean.com/v2/account/keys" > "$temp_file"; then
        
        if jq -e '.ssh_keys' "$temp_file" >/dev/null 2>&1; then
            echo "$temp_file"
        else
            echo -e "${RED}❌ Failed to fetch SSH keys. Check your API token.${NC}" >&2
            cat "$temp_file" >&2
            rm "$temp_file"
            exit 1
        fi
    else
        echo -e "${RED}❌ Failed to connect to DigitalOcean API${NC}" >&2
        rm "$temp_file"
        exit 1
    fi
}

# Function to display all keys in a nice format
display_all_keys() {
    local temp_file="$1"
    
    echo -e "${GREEN}✅ Available SSH Keys:${NC}"
    echo "=================================================="
    printf "%-12s %-30s %s\n" "ID" "NAME" "FINGERPRINT"
    echo "=================================================="
    
    jq -r '.ssh_keys[] | [.id, .name, .fingerprint] | @tsv' "$temp_file" | \
    while IFS=$'\t' read -r id name fingerprint; do
        printf "%-12s %-30s %s\n" "$id" "$name" "$fingerprint"
    done
    echo "=================================================="
}

# Function to lookup key IDs by names
lookup_key_ids() {
    local key_names="$1"
    local temp_file="$2"
    local found_ids=()
    
    echo -e "${BLUE}🔍 Looking up key IDs for names: $key_names${NC}"
    
    IFS=',' read -ra NAMES <<< "$key_names"
    for name in "${NAMES[@]}"; do
        # Trim whitespace
        name=$(echo "$name" | xargs)
        
        # Look for exact match first
        local key_id=$(jq -r --arg name "$name" '.ssh_keys[] | select(.name == $name) | .id' "$temp_file")
        
        if [ -z "$key_id" ] || [ "$key_id" = "null" ]; then
            # Try partial match (case insensitive)
            key_id=$(jq -r --arg name "$name" '.ssh_keys[] | select(.name | ascii_downcase | contains($name | ascii_downcase)) | .id' "$temp_file")
        fi
        
        if [ -n "$key_id" ] && [ "$key_id" != "null" ]; then
            found_ids+=("$key_id")
            local actual_name=$(jq -r --arg id "$key_id" '.ssh_keys[] | select(.id == ($id | tonumber)) | .name' "$temp_file")
            echo -e "${GREEN}✅ Found: '$name' → ID: $key_id (actual name: '$actual_name')${NC}"
        else
            echo -e "${RED}❌ Key not found: '$name'${NC}"
        fi
    done
    
    if [ ${#found_ids[@]} -gt 0 ]; then
        echo ""
        echo -e "${GREEN}🎉 SSH Key IDs for your .env file:${NC}"
        echo "DO_SSH_KEYS=$(IFS=,; echo "${found_ids[*]}")"
    else
        echo -e "${RED}❌ No matching keys found${NC}"
        exit 1
    fi
}

# Main function
main() {
    local temp_file=$(get_all_keys)
    
    if [ $# -eq 0 ]; then
        # No arguments - show all keys
        display_all_keys "$temp_file"
        echo ""
        echo -e "${YELLOW}💡 Usage examples:${NC}"
        echo "  $0 'mac-mini-pub-key,mac-book-pro-pub'"
        echo "  $0 'mac-mini,mac-book'"
        echo "  $0 'Mini Pub Key'"
    else
        # Arguments provided - lookup specific keys
        lookup_key_ids "$1" "$temp_file"
    fi
    
    # Clean up
    rm "$temp_file"
}

main "$@" 