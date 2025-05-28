#!/bin/bash

# Comprehensive inventory management script

set -e

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

INVENTORY_DIR="inventory"
HOSTS_FILE="$INVENTORY_DIR/hosts.yml"
PROD_FILE="$INVENTORY_DIR/production.yml"

show_help() {
    echo "Usage: $0 {update|encrypt|decrypt|edit|view|backup|restore|test}"
    echo ""
    echo "Commands:"
    echo "  update   - Update inventory from DigitalOcean API"
    echo "  encrypt  - Encrypt production inventory"
    echo "  decrypt  - Decrypt production inventory"
    echo "  edit     - Edit encrypted production inventory"
    echo "  view     - View encrypted production inventory"
    echo "  backup   - Backup current inventory files"
    echo "  restore  - Restore from backup"
    echo "  test     - Test connectivity to all hosts"
    echo ""
    echo "Examples:"
    echo "  $0 update"
    echo "  $0 encrypt"
    echo "  $0 test"
}

update_inventory() {
    echo -e "${BLUE}🔄 Updating inventory from DigitalOcean...${NC}"
    
    if [ -z "$DO_API_TOKEN" ]; then
        echo -e "${RED}Error: DO_API_TOKEN not set${NC}"
        echo "Run: source scripts/setup-env.sh"
        exit 1
    fi
    
    ./scripts/update-inventory.sh
}

encrypt_production() {
    echo -e "${YELLOW}🔐 Encrypting production inventory...${NC}"
    if [ -f "$PROD_FILE" ]; then
        ansible-vault encrypt "$PROD_FILE"
        echo -e "${GREEN}✅ Production inventory encrypted${NC}"
    else
        echo -e "${RED}❌ Production inventory file not found: $PROD_FILE${NC}"
        exit 1
    fi
}

decrypt_production() {
    echo -e "${YELLOW}🔓 Decrypting production inventory...${NC}"
    ansible-vault decrypt "$PROD_FILE"
    echo -e "${GREEN}✅ Production inventory decrypted${NC}"
}

edit_production() {
    echo -e "${YELLOW}✏️  Editing production inventory...${NC}"
    ansible-vault edit "$PROD_FILE"
}

view_production() {
    echo -e "${BLUE}👀 Viewing production inventory...${NC}"
    ansible-vault view "$PROD_FILE"
}

backup_inventory() {
    BACKUP_DIR="inventory/backups"
    TIMESTAMP=$(date +%Y%m%d_%H%M%S)
    
    mkdir -p "$BACKUP_DIR"
    
    echo -e "${BLUE}💾 Creating inventory backup...${NC}"
    
    if [ -f "$HOSTS_FILE" ]; then
        cp "$HOSTS_FILE" "$BACKUP_DIR/hosts_$TIMESTAMP.yml"
        echo -e "${GREEN}✅ Backed up: $HOSTS_FILE${NC}"
    fi
    
    if [ -f "$PROD_FILE" ]; then
        cp "$PROD_FILE" "$BACKUP_DIR/production_$TIMESTAMP.yml"
        echo -e "${GREEN}✅ Backed up: $PROD_FILE${NC}"
    fi
    
    echo -e "${GREEN}📁 Backups saved to: $BACKUP_DIR${NC}"
    ls -la "$BACKUP_DIR/"
}

restore_inventory() {
    BACKUP_DIR="inventory/backups"
    
    echo -e "${BLUE}📂 Available backups:${NC}"
    ls -la "$BACKUP_DIR/" 2>/dev/null || {
        echo -e "${RED}❌ No backups found${NC}"
        exit 1
    }
    
    echo ""
    echo "To restore, manually copy the desired backup file:"
    echo "cp $BACKUP_DIR/hosts_TIMESTAMP.yml $HOSTS_FILE"
    echo "cp $BACKUP_DIR/production_TIMESTAMP.yml $PROD_FILE"
}

test_connectivity() {
    echo -e "${BLUE}🔌 Testing connectivity to all hosts...${NC}"
    
    echo -e "${YELLOW}Testing DigitalOcean hosts:${NC}"
    ansible digitalocean -m ping -o || echo -e "${RED}❌ Some DigitalOcean hosts unreachable${NC}"
    
    echo -e "${YELLOW}Testing production hosts:${NC}"
    ansible production -m ping -o --ask-vault-pass || echo -e "${RED}❌ Some production hosts unreachable${NC}"
    
    echo -e "${YELLOW}Testing staging hosts:${NC}"
    ansible staging -m ping -o --ask-vault-pass || echo -e "${RED}❌ Some staging hosts unreachable${NC}"
}

# Make scripts executable
chmod +x scripts/update-inventory.sh 2>/dev/null || true

case "${1:-help}" in
    "update")
        update_inventory
        ;;
    "encrypt")
        encrypt_production
        ;;
    "decrypt")
        decrypt_production
        ;;
    "edit")
        edit_production
        ;;
    "view")
        view_production
        ;;
    "backup")
        backup_inventory
        ;;
    "restore")
        restore_inventory
        ;;
    "test")
        test_connectivity
        ;;
    *)
        show_help
        exit 1
        ;;
esac 