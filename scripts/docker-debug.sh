#!/bin/bash

# Local Docker Debugging Script using Ansible
# Run this from your local machine to debug remote Docker deployments

set -e

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
BOLD='\033[1m'
NC='\033[0m' # No Color

APP_NAME=""
ACTION=""
TARGET_HOST="digitalocean"

show_help() {
    echo -e "${BOLD}${BLUE}🐳 Remote Docker Debug Helper${NC}"
    echo "================================="
    echo ""
    echo "Usage: $0 [APP_NAME] [ACTION] [HOST_GROUP]"
    echo ""
    echo "Actions:"
    echo "  logs     - Show recent logs"
    echo "  status   - Show container status"
    echo "  build    - Show last build log"
    echo "  restart  - Restart containers"
    echo "  shell    - Get shell in running container"
    echo "  cleanup  - Clean up Docker resources"
    echo "  health   - Complete health check"
    echo ""
    echo "Examples:"
    echo "  $0 rekalled status           # Show rekalled status"
    echo "  $0 rekalled logs            # Show rekalled logs"
    echo "  $0 rekalled health          # Complete health check"
    echo "  $0 cleanup                  # System-wide cleanup"
    echo ""
    echo "Host Group (optional, defaults to 'digitalocean'):"
    echo "  digitalocean, production, staging, etc."
}

check_ansible() {
    if ! command -v ansible &> /dev/null; then
        echo -e "${RED}❌ Ansible not found. Please install ansible first.${NC}"
        exit 1
    fi
}

show_logs() {
    echo -e "${BLUE}📋 Fetching logs for $APP_NAME from remote servers...${NC}"
    ansible $TARGET_HOST -m shell -a "cd /opt/$APP_NAME && docker compose logs --tail=50 --timestamps" || {
        echo -e "${RED}❌ Failed to get logs. Check if app exists on servers.${NC}"
        exit 1
    }
}

show_status() {
    echo -e "${BLUE}📊 Checking status for $APP_NAME...${NC}"
    echo ""
    
    echo -e "${YELLOW}Container Status:${NC}"
    ansible $TARGET_HOST -m shell -a "cd /opt/$APP_NAME && docker compose ps" || {
        echo -e "${RED}❌ App directory not found or accessible${NC}"
        return 1
    }
    
    echo ""
    echo -e "${YELLOW}Images:${NC}"
    ansible $TARGET_HOST -m shell -a "cd /opt/$APP_NAME && docker compose images" 2>/dev/null || true
    
    echo ""
    echo -e "${YELLOW}Resource Usage:${NC}"
    ansible $TARGET_HOST -m shell -a "cd /opt/$APP_NAME && docker compose top" 2>/dev/null || true
}

show_build_log() {
    echo -e "${BLUE}🏗️  Fetching build log for $APP_NAME...${NC}"
    ansible $TARGET_HOST -m shell -a "cat /tmp/${APP_NAME}_build.log" || {
        echo -e "${YELLOW}⚠️  No build log found. Try rebuilding first.${NC}"
    }
}

restart_app() {
    echo -e "${BLUE}🔄 Restarting $APP_NAME...${NC}"
    ansible $TARGET_HOST -m shell -a "cd /opt/$APP_NAME && docker compose restart"
    
    echo ""
    echo -e "${GREEN}✅ Restart command sent. Checking status...${NC}"
    sleep 3
    show_status
}

get_shell() {
    echo -e "${BLUE}🐚 Getting shell access to $APP_NAME...${NC}"
    echo ""
    echo "Available services:"
    ansible $TARGET_HOST -m shell -a "cd /opt/$APP_NAME && docker compose ps --services"
    echo ""
    read -p "Enter service name for shell access: " service_name
    
    if [ -n "$service_name" ]; then
        echo -e "${GREEN}Connecting to $service_name...${NC}"
        echo "Note: You'll need to SSH manually for interactive shell:"
        echo "ssh your-user@server-ip"
        echo "cd /opt/$APP_NAME && docker compose exec $service_name /bin/bash"
    fi
}

cleanup_docker() {
    echo -e "${YELLOW}🗑️  Docker System Cleanup${NC}"
    echo "=========================="
    
    echo "Current disk usage:"
    ansible $TARGET_HOST -m shell -a "docker system df"
    
    echo ""
    read -p "Continue with cleanup on all servers? (y/N): " -n 1 -r
    echo
    
    if [[ $REPLY =~ ^[Yy]$ ]]; then
        echo "Cleaning up Docker resources..."
        ansible $TARGET_HOST -m shell -a "docker container prune -f && docker image prune -f && docker network prune -f && docker builder prune -f"
        
        echo ""
        echo "New disk usage:"
        ansible $TARGET_HOST -m shell -a "docker system df"
        
        echo -e "${GREEN}✅ Cleanup complete!${NC}"
    else
        echo "Cleanup cancelled"
    fi
}

health_check() {
    echo -e "${BLUE}🏥 Complete Health Check${NC}"
    echo "========================="
    
    echo -e "${YELLOW}1. Caddy Proxy Status:${NC}"
    ansible $TARGET_HOST -m shell -a "docker ps | grep caddy" || echo "❌ Caddy not running"
    
    echo ""
    echo -e "${YELLOW}2. $APP_NAME Application:${NC}"
    show_status
    
    echo ""
    echo -e "${YELLOW}3. Network Status:${NC}"
    ansible $TARGET_HOST -m shell -a "docker network ls | grep proxy"
    
    echo ""
    echo -e "${YELLOW}4. Recent Logs (last 10 lines):${NC}"
    ansible $TARGET_HOST -m shell -a "cd /opt/$APP_NAME && docker compose logs --tail=10" 2>/dev/null || true
    
    echo ""
    echo -e "${YELLOW}5. Build/Deploy Logs:${NC}"
    ansible $TARGET_HOST -m shell -a "ls -la /tmp/${APP_NAME}_*.log /var/log/ansible-deployments/${APP_NAME}_*.log 2>/dev/null | tail -3" || echo "No logs found"
}

# Parse arguments
if [ $# -eq 0 ]; then
    show_help
    exit 0
fi

if [ "$1" = "cleanup" ]; then
    check_ansible
    cleanup_docker
    exit 0
fi

if [ "$1" = "help" ] || [ "$1" = "-h" ] || [ "$1" = "--help" ]; then
    show_help
    exit 0
fi

if [ $# -lt 2 ]; then
    echo -e "${RED}❌ Missing arguments${NC}"
    echo "Usage: $0 [APP_NAME] [ACTION] [HOST_GROUP]"
    echo "Run '$0 help' for more information"
    exit 1
fi

APP_NAME="$1"
ACTION="$2"
TARGET_HOST="${3:-digitalocean}"

check_ansible

# Execute action
case "$ACTION" in
    "logs")
        show_logs
        ;;
    "status")
        show_status
        ;;
    "build")
        show_build_log
        ;;
    "restart")
        restart_app
        ;;
    "shell")
        get_shell
        ;;
    "health")
        health_check
        ;;
    *)
        echo -e "${RED}❌ Unknown action: $ACTION${NC}"
        echo "Run '$0 help' for available actions"
        exit 1
        ;;
esac 