#!/bin/bash

# Script to encrypt/decrypt production variables

set -e

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

PROD_FILE="group_vars/prod.yml"

if [ ! -f "$PROD_FILE" ]; then
    echo -e "${RED}Error: $PROD_FILE not found!${NC}"
    exit 1
fi

case "${1:-help}" in
    "encrypt")
        echo -e "${YELLOW}Encrypting $PROD_FILE...${NC}"
        ansible-vault encrypt "$PROD_FILE"
        echo -e "${GREEN}✅ $PROD_FILE encrypted successfully${NC}"
        ;;
    "decrypt")
        echo -e "${YELLOW}Decrypting $PROD_FILE...${NC}"
        ansible-vault decrypt "$PROD_FILE"
        echo -e "${GREEN}✅ $PROD_FILE decrypted successfully${NC}"
        ;;
    "edit")
        echo -e "${YELLOW}Editing encrypted $PROD_FILE...${NC}"
        ansible-vault edit "$PROD_FILE"
        ;;
    "view")
        echo -e "${YELLOW}Viewing encrypted $PROD_FILE...${NC}"
        ansible-vault view "$PROD_FILE"
        ;;
    "rekey")
        echo -e "${YELLOW}Changing vault password for $PROD_FILE...${NC}"
        ansible-vault rekey "$PROD_FILE"
        echo -e "${GREEN}✅ Vault password changed successfully${NC}"
        ;;
    *)
        echo "Usage: $0 {encrypt|decrypt|edit|view|rekey}"
        echo ""
        echo "Commands:"
        echo "  encrypt  - Encrypt the production variables file"
        echo "  decrypt  - Decrypt the production variables file"
        echo "  edit     - Edit the encrypted file (opens editor)"
        echo "  view     - View the encrypted file contents"
        echo "  rekey    - Change the vault password"
        echo ""
        echo "Example:"
        echo "  $0 encrypt"
        echo "  $0 edit"
        exit 1
        ;;
esac 