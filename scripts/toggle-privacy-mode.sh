#!/bin/bash

# Toggle between public and private repository modes
# Public mode: Ignores sensitive files for safe sharing/contributing
# Private mode: Tracks sensitive files for development

set -e

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# Script directory
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_ROOT="$(dirname "$SCRIPT_DIR")"
GITIGNORE_FILE="$PROJECT_ROOT/.gitignore"

# Sensitive file patterns to ignore in public mode
PRIVATE_PATTERNS=(
    "# === PRIVATE MODE EXCLUSIONS ==="
    "# Environment and secrets"
    ".env"
    ".vault_pass"
    ".vault_pass.txt"
    ""
    "# Server inventory and configurations"
    "inventory/hosts.yml"
    "inventory/hosts.yml.backup.*"
    "group_vars/prod.yml"
    ""
    "# SSH keys and encrypted files"
    "files/ssh_keys/*"
    "!files/ssh_keys/.gitkeep"
    "env_files/*"
    "!env_files/.gitkeep"
    ""
    "# Runtime files"
    "logs/"
    "backups/"
    "*.log"
    "*.backup"
    "*_backup_*"
    ""
    "# Temporary files"
    "tmp/"
    ".tmp/"
    "*.tmp"
    "SANITIZED.md"
)

show_help() {
    echo -e "${BLUE}🔄 Privacy Mode Toggle Script${NC}"
    echo ""
    echo "Usage: $0 [public|private|status]"
    echo ""
    echo "Modes:"
    echo "  ${GREEN}private${NC}  - Development mode (tracks sensitive files)"
    echo "  ${YELLOW}public${NC}   - Contribution mode (ignores sensitive files)"
    echo "  ${BLUE}status${NC}   - Show current mode"
    echo ""
    echo "Examples:"
    echo "  $0 private    # Switch to private development mode"
    echo "  $0 public     # Switch to public contribution mode"
    echo "  $0 status     # Check current mode"
}

get_current_mode() {
    if [ ! -f "$GITIGNORE_FILE" ]; then
        echo "unknown"
        return
    fi
    
    if grep -q "# === PRIVATE MODE EXCLUSIONS ===" "$GITIGNORE_FILE" 2>/dev/null; then
        echo "public"
    else
        echo "private"
    fi
}

show_status() {
    local current_mode=$(get_current_mode)
    
    echo -e "${BLUE}📊 Current Repository Mode${NC}"
    echo ""
    
    case $current_mode in
        "private")
            echo -e "Mode: ${GREEN}PRIVATE${NC} (Development)"
            echo "• Sensitive files are tracked by Git"
            echo "• Safe for local development"
            echo "• ⚠️  DO NOT push to public repositories"
            ;;
        "public")
            echo -e "Mode: ${YELLOW}PUBLIC${NC} (Contribution)"
            echo "• Sensitive files are ignored by Git"
            echo "• Safe for public sharing"
            echo "• ✅ Ready for contributions"
            ;;
        "unknown")
            echo -e "Mode: ${RED}UNKNOWN${NC}"
            echo "• .gitignore file not found or unrecognized"
            echo "• Run with 'private' or 'public' to set mode"
            ;;
    esac
    
    echo ""
    
    # Show which sensitive files exist
    echo -e "${BLUE}📁 Sensitive Files Status:${NC}"
    local has_sensitive=false
    
    if [ -f "$PROJECT_ROOT/.env" ]; then
        echo "• .env file exists"
        has_sensitive=true
    fi
    
    if [ -f "$PROJECT_ROOT/group_vars/prod.yml" ]; then
        echo "• group_vars/prod.yml exists"
        has_sensitive=true
    fi
    
    if [ -f "$PROJECT_ROOT/inventory/hosts.yml" ]; then
        echo "• inventory/hosts.yml exists"
        has_sensitive=true
    fi
    
    if [ -d "$PROJECT_ROOT/files/ssh_keys" ] && [ "$(ls -A "$PROJECT_ROOT/files/ssh_keys" 2>/dev/null | grep -v .gitkeep)" ]; then
        echo "• SSH keys exist in files/ssh_keys/"
        has_sensitive=true
    fi
    
    if [ -d "$PROJECT_ROOT/env_files" ] && [ "$(ls -A "$PROJECT_ROOT/env_files" 2>/dev/null | grep -v .gitkeep)" ]; then
        echo "• Encrypted env files exist in env_files/"
        has_sensitive=true
    fi
    
    if [ "$has_sensitive" = false ]; then
        echo "• No sensitive files detected"
    fi
}

switch_to_private() {
    echo -e "${GREEN}🔓 Switching to PRIVATE mode (development)...${NC}"
    
    # Remove private patterns from .gitignore
    if [ -f "$GITIGNORE_FILE" ]; then
        # Create temp file without private patterns
        grep -v "# === PRIVATE MODE EXCLUSIONS ===" "$GITIGNORE_FILE" | \
        sed '/^# Environment and secrets$/,/^SANITIZED\.md$/d' > "${GITIGNORE_FILE}.tmp"
        mv "${GITIGNORE_FILE}.tmp" "$GITIGNORE_FILE"
    fi
    
    echo -e "${GREEN}✅ Switched to PRIVATE mode${NC}"
    echo "• Sensitive files will now be tracked by Git"
    echo "• Safe for local development"
    echo "• ⚠️  Remember to switch to PUBLIC mode before contributing"
}

switch_to_public() {
    echo -e "${YELLOW}🔒 Switching to PUBLIC mode (contribution)...${NC}"
    
    # Ensure .gitignore exists
    if [ ! -f "$GITIGNORE_FILE" ]; then
        touch "$GITIGNORE_FILE"
    fi
    
    # Remove existing private patterns first (in case they exist)
    grep -v "# === PRIVATE MODE EXCLUSIONS ===" "$GITIGNORE_FILE" | \
    sed '/^# Environment and secrets$/,/^SANITIZED\.md$/d' > "${GITIGNORE_FILE}.tmp" 2>/dev/null || cp "$GITIGNORE_FILE" "${GITIGNORE_FILE}.tmp"
    
    # Add private patterns
    echo "" >> "${GITIGNORE_FILE}.tmp"
    printf '%s\n' "${PRIVATE_PATTERNS[@]}" >> "${GITIGNORE_FILE}.tmp"
    
    mv "${GITIGNORE_FILE}.tmp" "$GITIGNORE_FILE"
    
    echo -e "${YELLOW}✅ Switched to PUBLIC mode${NC}"
    echo "• Sensitive files are now ignored by Git"
    echo "• Safe for public sharing and contributions"
    echo "• Your private files remain on disk but won't be committed"
}

main() {
    cd "$PROJECT_ROOT"
    
    case "${1:-status}" in
        "private")
            switch_to_private
            ;;
        "public")
            switch_to_public
            ;;
        "status")
            show_status
            ;;
        "help"|"-h"|"--help")
            show_help
            ;;
        *)
            echo -e "${RED}❌ Unknown option: $1${NC}"
            echo ""
            show_help
            exit 1
            ;;
    esac
}

main "$@" 