#!/bin/bash

# Local .env file editing utility
# For management tasks, use: ansible-playbook playbooks/manage-env.yml

set -e

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_ROOT="$(dirname "$SCRIPT_DIR")"

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

log_info() {
    echo -e "${BLUE}[INFO]${NC} $1"
}

log_success() {
    echo -e "${GREEN}[SUCCESS]${NC} $1"
}

log_warning() {
    echo -e "${YELLOW}[WARNING]${NC} $1"
}

log_error() {
    echo -e "${RED}[ERROR]${NC} $1"
}

show_usage() {
    echo "🔐 Local .env File Editor"
    echo "========================="
    echo
    echo "This script only handles local editing tasks."
    echo "For full .env management, use the Ansible playbook:"
    echo
    echo "📚 Full Management Commands:"
    echo "  ansible-playbook playbooks/manage-env.yml -e action=create -e app_name=APP"
    echo "  ansible-playbook playbooks/manage-env.yml -e action=encrypt -e app_name=APP"
    echo "  ansible-playbook playbooks/manage-env.yml -e action=deploy -e app_name=APP"
    echo "  ansible-playbook playbooks/manage-env.yml -e action=list"
    echo
    echo "✏️  Local Editing Commands:"
    echo "  $0 edit <app_name>        Edit .env file locally"
    echo "  $0 create <app_name>      Quick create and edit"
    echo
    echo "Examples:"
    echo "  $0 edit rekalled"
    echo "  $0 create rekalled"
    echo
}

edit_env_file() {
    local app_name="$1"
    
    if [ -z "$app_name" ]; then
        log_error "App name required"
        show_usage
        exit 1
    fi
    
    local env_dir="$PROJECT_ROOT/env_files"
    local env_file="$env_dir/$app_name.env"
    local vault_file="$env_dir/$app_name.env.vault"
    
    # Check if encrypted version exists and decrypt temporarily
    if [ -f "$vault_file" ] && [ ! -f "$env_file" ]; then
        log_info "Decrypting .env.vault file for editing..."
        ansible-vault decrypt "$vault_file" --output="$env_file"
        local decrypted=true
    fi
    
    if [ ! -f "$env_file" ]; then
        log_error ".env file not found for $app_name"
        echo "Create it first with:"
        echo "  ansible-playbook playbooks/manage-env.yml -e action=create -e app_name=$app_name"
        exit 1
    fi
    
    log_info "Opening .env file for editing..."
    ${EDITOR:-nano} "$env_file"
    
    if [ "$decrypted" = true ]; then
        log_warning "File was decrypted for editing. Encrypt it again:"
        echo "  ansible-playbook playbooks/manage-env.yml -e action=encrypt -e app_name=$app_name"
    else
        log_warning "Remember to encrypt the file:"
        echo "  ansible-playbook playbooks/manage-env.yml -e action=encrypt -e app_name=$app_name"
    fi
}

quick_create() {
    local app_name="$1"
    
    if [ -z "$app_name" ]; then
        log_error "App name required"
        show_usage
        exit 1
    fi
    
    log_info "Creating .env file for $app_name..."
    
    # Use Ansible to create the template
    ansible-playbook "$PROJECT_ROOT/playbooks/manage-env.yml" -e action=create -e app_name="$app_name"
    
    # Then edit it
    edit_env_file "$app_name"
}

main() {
    local command="$1"
    local app_name="$2"
    
    case "$command" in
        "edit")
            edit_env_file "$app_name"
            ;;
        "create")
            quick_create "$app_name"
            ;;
        *)
            show_usage
            exit 1
            ;;
    esac
}

main "$@" 