#!/bin/bash

# Maintenance Mode Management Script
# Easy interface for enabling/disabling maintenance mode

set -e

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# Function to display help
show_help() {
    echo -e "${BLUE}🚧 Maintenance Mode Management${NC}"
    echo "=================================="
    echo ""
    echo "Usage: $0 <action> [options]"
    echo ""
    echo "Actions:"
    echo "  enable    Enable maintenance mode"
    echo "  disable   Disable maintenance mode"
    echo "  status    Check maintenance mode status"
    echo ""
    echo "Options:"
    echo "  -a, --app <name>        Target specific app (default: all apps)"
    echo "  -t, --title <title>     Custom page title"
    echo "  -r, --reason <reason>   Custom maintenance reason"
    echo "  -c, --completion <time> Estimated completion time"
    echo "  -e, --email <email>     Contact email for urgent issues"
    echo "  -h, --help              Show this help"
    echo ""
    echo "Examples:"
    echo "  $0 enable                                    # Enable for all apps"
    echo "  $0 enable -a myapp                          # Enable for specific app"
    echo "  $0 enable -r \"Database migration\"          # Custom reason"
    echo "  $0 enable -c \"2024-01-01 15:00 UTC\"        # With completion time"
    echo "  $0 disable                                   # Disable maintenance"
    echo "  $0 status                                    # Check current status"
    echo ""
    echo "  # Enable with full customization:"
    echo "  $0 enable -a myapp -t \"MyApp Upgrade\" \\"
    echo "    -r \"Upgrading to v2.0\" \\"
    echo "    -c \"$(date -d '+2 hours' '+%Y-%m-%d %H:%M UTC')\" \\"
    echo "    -e \"support@myapp.com\""
}

# Function to check ansible availability
check_ansible() {
    if ! command -v ansible-playbook &> /dev/null; then
        echo -e "${RED}❌ Error: ansible-playbook not found${NC}"
        echo "Please ensure Ansible is installed and in your PATH"
        exit 1
    fi
}

# Function to build ansible command
build_ansible_cmd() {
    local action="$1"
    local cmd="ansible-playbook playbooks/maintenance-mode.yml -e action=$action"
    
    [ -n "$APP_NAME" ] && cmd="$cmd -e app_name=\"$APP_NAME\""
    [ -n "$SITE_TITLE" ] && cmd="$cmd -e site_title=\"$SITE_TITLE\""
    [ -n "$MAINTENANCE_REASON" ] && cmd="$cmd -e maintenance_reason=\"$MAINTENANCE_REASON\""
    [ -n "$ESTIMATED_COMPLETION" ] && cmd="$cmd -e estimated_completion=\"$ESTIMATED_COMPLETION\""
    [ -n "$CONTACT_EMAIL" ] && cmd="$cmd -e contact_email=\"$CONTACT_EMAIL\""
    
    echo "$cmd"
}

# Function to confirm action
confirm_action() {
    local action="$1"
    local target="${APP_NAME:-"all apps"}"
    
    echo -e "\n${YELLOW}⚠️  Confirmation Required${NC}"
    echo "=================================="
    echo "Action: ${action^^}"
    echo "Target: $target"
    
    if [ "$action" = "enable" ]; then
        echo "This will:"
        echo "- Stop the current app container(s)"
        echo "- Start a maintenance page container"
        echo "- Redirect all traffic to the maintenance page"
        [ -n "$MAINTENANCE_REASON" ] && echo "- Reason: $MAINTENANCE_REASON"
        [ -n "$ESTIMATED_COMPLETION" ] && echo "- Completion: $ESTIMATED_COMPLETION"
    elif [ "$action" = "disable" ]; then
        echo "This will:"
        echo "- Stop the maintenance page container"
        echo "- Restart the app container(s)"
        echo "- Restore normal traffic flow"
    fi
    
    echo ""
    read -p "Continue? (y/N): " -n 1 -r
    echo
    
    if [[ ! $REPLY =~ ^[Yy]$ ]]; then
        echo -e "${YELLOW}Operation cancelled${NC}"
        exit 0
    fi
}

# Parse command line arguments
ACTION=""
APP_NAME=""
SITE_TITLE=""
MAINTENANCE_REASON=""
ESTIMATED_COMPLETION=""
CONTACT_EMAIL=""
SKIP_CONFIRM=false

while [[ $# -gt 0 ]]; do
    case $1 in
        enable|disable|status)
            ACTION="$1"
            shift
            ;;
        -a|--app)
            APP_NAME="$2"
            shift 2
            ;;
        -t|--title)
            SITE_TITLE="$2"
            shift 2
            ;;
        -r|--reason)
            MAINTENANCE_REASON="$2"
            shift 2
            ;;
        -c|--completion)
            ESTIMATED_COMPLETION="$2"
            shift 2
            ;;
        -e|--email)
            CONTACT_EMAIL="$2"
            shift 2
            ;;
        -y|--yes)
            SKIP_CONFIRM=true
            shift
            ;;
        -h|--help)
            show_help
            exit 0
            ;;
        *)
            echo -e "${RED}❌ Unknown option: $1${NC}"
            echo "Use $0 --help for usage information"
            exit 1
            ;;
    esac
done

# Validate action
if [ -z "$ACTION" ]; then
    echo -e "${RED}❌ Error: No action specified${NC}"
    echo "Use $0 --help for usage information"
    exit 1
fi

# Check prerequisites
check_ansible

# Build the ansible command
ANSIBLE_CMD=$(build_ansible_cmd "$ACTION")

# Show what will be executed
echo -e "${BLUE}🚧 Maintenance Mode: ${ACTION^^}${NC}"
echo "Command: $ANSIBLE_CMD"

# Confirm action (except for status)
if [ "$ACTION" != "status" ] && [ "$SKIP_CONFIRM" != true ]; then
    confirm_action "$ACTION"
fi

# Execute the command
echo -e "\n${GREEN}🚀 Executing maintenance mode operation...${NC}"
echo "=============================================="

if eval "$ANSIBLE_CMD"; then
    echo -e "\n${GREEN}✅ Maintenance mode operation completed successfully!${NC}"
else
    echo -e "\n${RED}❌ Maintenance mode operation failed!${NC}"
    exit 1
fi 