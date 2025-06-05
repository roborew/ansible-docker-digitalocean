#!/bin/bash

# Sync changes from private repository to public repository
# This script safely pushes non-sensitive changes to the public repo

set -e

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# Configuration
PRIVATE_BRANCH="${1:-main}"
PUBLIC_REMOTE="${2:-public}"
PUBLIC_BRANCH="${3:-main}"

show_help() {
    echo -e "${BLUE}🔄 Sync Private Repository to Public Repository${NC}"
    echo ""
    echo "Usage: $0 [private_branch] [public_remote] [public_branch]"
    echo ""
    echo "Arguments:"
    echo "  private_branch    Source branch in private repo (default: main)"
    echo "  public_remote     Name of public remote (default: public)"
    echo "  public_branch     Target branch in public repo (default: main)"
    echo ""
    echo "Examples:"
    echo "  $0                    # Sync main to public/main"
    echo "  $0 develop public dev # Sync develop to public/dev"
    echo ""
    echo "Prerequisites:"
    echo "  • Public repo added as remote: git remote add public <url>"
    echo "  • Public repo configured with proper .gitignore"
    echo "  • Current directory is private repository"
}

check_prerequisites() {
    echo -e "${BLUE}🔍 Checking prerequisites...${NC}"
    
    # Check if we're in a git repository
    if ! git rev-parse --git-dir > /dev/null 2>&1; then
        echo -e "${RED}❌ Not in a git repository${NC}"
        exit 1
    fi
    
    # Check if public remote exists
    if ! git remote | grep -q "^${PUBLIC_REMOTE}$"; then
        echo -e "${RED}❌ Public remote '${PUBLIC_REMOTE}' not found${NC}"
        echo "Add it with: git remote add ${PUBLIC_REMOTE} <public-repo-url>"
        exit 1
    fi
    
    # Check if we're on the right branch
    CURRENT_BRANCH=$(git branch --show-current)
    if [ "$CURRENT_BRANCH" != "$PRIVATE_BRANCH" ]; then
        echo -e "${YELLOW}⚠️  Currently on branch '$CURRENT_BRANCH', switching to '$PRIVATE_BRANCH'${NC}"
        git checkout "$PRIVATE_BRANCH"
    fi
    
    echo -e "${GREEN}✅ Prerequisites checked${NC}"
}

setup_public_gitignore() {
    echo -e "${BLUE}🔒 Setting up public repository .gitignore...${NC}"
    
    # Ensure we have the privacy toggle script
    if [ ! -f "scripts/toggle-privacy-mode.sh" ]; then
        echo -e "${RED}❌ Privacy toggle script not found${NC}"
        exit 1
    fi
    
    # Switch to public mode to ensure proper .gitignore
    ./scripts/toggle-privacy-mode.sh public
    
    echo -e "${GREEN}✅ Repository set to public mode${NC}"
}

sync_to_public() {
    echo -e "${BLUE}📤 Syncing to public repository...${NC}"
    
    # Fetch latest from public repo
    echo "Fetching from public remote..."
    git fetch "$PUBLIC_REMOTE"
    
    # Check for conflicts or uncommitted changes
    if ! git diff --quiet; then
        echo -e "${YELLOW}⚠️  You have uncommitted changes${NC}"
        read -p "Commit them now? (y/n): " -n 1 -r
        echo
        if [[ $REPLY =~ ^[Yy]$ ]]; then
            git add .
            read -p "Commit message: " commit_msg
            git commit -m "$commit_msg"
        else
            echo "Please commit or stash changes before syncing"
            exit 1
        fi
    fi
    
    # Push to public repository
    echo "Pushing to public repository..."
    if git push "$PUBLIC_REMOTE" "$PRIVATE_BRANCH:$PUBLIC_BRANCH"; then
        echo -e "${GREEN}✅ Successfully synced to public repository${NC}"
    else
        echo -e "${RED}❌ Failed to push to public repository${NC}"
        echo "You may need to resolve conflicts manually"
        exit 1
    fi
}

show_sync_status() {
    echo ""
    echo -e "${BLUE}📊 Sync Status:${NC}"
    echo "• Private branch: $PRIVATE_BRANCH"
    echo "• Public remote: $PUBLIC_REMOTE"
    echo "• Public branch: $PUBLIC_BRANCH"
    
    # Show what files are ignored
    echo ""
    echo -e "${BLUE}🔒 Files excluded from public repo:${NC}"
    if [ -f ".env" ]; then echo "• .env"; fi
    if [ -f ".vault_pass" ]; then echo "• .vault_pass"; fi
    if [ -f "group_vars/prod.yml" ]; then echo "• group_vars/prod.yml"; fi
    if [ -f "inventory/hosts.yml" ]; then echo "• inventory/hosts.yml"; fi
    if [ -d "files/ssh_keys" ] && [ "$(ls -A files/ssh_keys 2>/dev/null)" ]; then echo "• SSH keys"; fi
    
    echo ""
    echo -e "${GREEN}🎉 Sync completed successfully!${NC}"
    echo ""
    echo -e "${YELLOW}💡 Next steps:${NC}"
    echo "• Visit your public repository to verify the sync"
    echo "• Create pull requests from the public repository"
    echo "• Run './scripts/toggle-privacy-mode.sh private' to return to development mode"
}

main() {
    if [[ "$1" == "--help" || "$1" == "-h" ]]; then
        show_help
        exit 0
    fi
    
    echo -e "${GREEN}🔄 Starting sync from private to public repository...${NC}"
    
    check_prerequisites
    setup_public_gitignore
    sync_to_public
    show_sync_status
}

main "$@" 