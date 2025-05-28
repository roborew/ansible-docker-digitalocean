#!/bin/bash

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
NC='\033[0m' # No Color

# Check if .env file exists
if [ ! -f .env ]; then
    echo -e "${RED}Error: .env file not found!${NC}"
    echo "Please copy .env.example to .env and fill in your values"
    exit 1
fi

# Function to export variables from .env
export_env_vars() {
    while IFS='=' read -r key value || [ -n "$key" ]; do
        # Skip comments and empty lines
        [[ $key =~ ^#.*$ ]] || [ -z "$key" ] && continue
        
        # Trim whitespace
        key=$(echo "$key" | xargs)
        value=$(echo "$value" | xargs)
        
        # Export the variable
        export "$key=$value"
        echo -e "${GREEN}Exported:${NC} $key"
    done < .env
}

echo "Setting up environment variables..."
export_env_vars

# Verify required variables
required_vars=("DO_API_TOKEN" "DO_SSH_KEYS" "SERVER_USERNAME" "ROOT_PASSWORD")
missing_vars=0

for var in "${required_vars[@]}"; do
    if [ -z "$(eval echo \$$var)" ]; then
        echo -e "${RED}Error: $var is not set or empty${NC}"
        missing_vars=1
    fi
done

if [ $missing_vars -eq 1 ]; then
    echo -e "${RED}Some required variables are missing. Please check your .env file.${NC}"
    exit 1
fi

echo -e "${GREEN}Environment setup complete! All required variables are exported.${NC}"
echo "You can now run your Ansible playbooks." 