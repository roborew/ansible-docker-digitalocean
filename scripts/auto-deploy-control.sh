#!/bin/bash

# Auto-Deployment Control Node Management Script
# Manages webhook service running on control node (Mac Mini, etc.)
# that deploys to remote target servers via SSH

set -e

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# Configuration
SCRIPT_DIR="$HOME/auto-deploy"
WEBHOOK_PORT="9000"

# Function to display help
show_help() {
    echo -e "${BLUE}🎛️ Auto-Deployment Control Node Management${NC}"
    echo "============================================"
    echo ""
    echo "Usage: $0 <action> [options]"
    echo ""
    echo "Actions:"
    echo "  setup       Setup auto-deployment on this control node"
    echo "  start       Start webhook service"
    echo "  stop        Stop webhook service"
    echo "  restart     Restart webhook service"
    echo "  status      Check webhook service and deployment status"
    echo "  logs        Show webhook service logs"
    echo "  webhook     Show webhook configuration for GitHub/GitLab"
    echo "  test        Test webhook endpoint and configuration"
    echo ""
    echo "Examples:"
    echo "  $0 setup                    # Setup control node"
    echo "  $0 start                    # Start webhook service"
    echo "  $0 status                   # Check service status"
    echo "  $0 webhook                  # Show webhook config"
    echo "  $0 test                     # Test configuration"
    echo ""
    echo "Note: This script manages the control node that deploys to remote servers."
    echo "      Target servers do not need Ansible - this node handles all deployments."
}

# Function to check ansible availability
check_ansible() {
    if ! command -v ansible-playbook &> /dev/null; then
        echo -e "${RED}❌ Error: ansible-playbook not found${NC}"
        echo "Please ensure Ansible is installed and in your PATH"
        exit 1
    fi
}

# Function to get control node IP
get_control_ip() {
    # Try to get external IP
    curl -s ifconfig.me 2>/dev/null || \
    curl -s ipinfo.io/ip 2>/dev/null || \
    hostname -I 2>/dev/null | awk '{print $1}' || \
    echo "localhost"
}

# Function to setup auto-deployment control node
setup_control_node() {
    echo -e "${BLUE}🎛️ Setting up auto-deployment control node...${NC}"
    
    check_ansible
    
    if ansible-playbook playbooks/setup-auto-deploy-control.yml; then
        echo -e "\n${GREEN}✅ Control node setup completed successfully!${NC}"
        echo -e "\n${YELLOW}Next steps:${NC}"
        echo "1. Start the webhook service: $0 start"
        echo "2. Configure repository webhooks: $0 webhook"
        echo "3. Test with a push to configured branch"
    else
        echo -e "\n${RED}❌ Control node setup failed!${NC}"
        exit 1
    fi
}

# Function to start webhook service
start_service() {
    echo -e "${BLUE}🚀 Starting webhook service...${NC}"
    
    if [ -f "$SCRIPT_DIR/start-webhook.sh" ]; then
        if "$SCRIPT_DIR/start-webhook.sh"; then
            echo -e "\n${GREEN}✅ Webhook service started successfully!${NC}"
        else
            echo -e "\n${RED}❌ Failed to start webhook service${NC}"
            exit 1
        fi
    else
        echo -e "${RED}❌ Webhook service not found${NC}"
        echo "Run '$0 setup' first to set up the control node"
        exit 1
    fi
}

# Function to stop webhook service
stop_service() {
    echo -e "${BLUE}🛑 Stopping webhook service...${NC}"
    
    if [ -f "$SCRIPT_DIR/stop-webhook.sh" ]; then
        "$SCRIPT_DIR/stop-webhook.sh"
    else
        echo -e "${YELLOW}Webhook service not found or not installed${NC}"
    fi
}

# Function to restart webhook service
restart_service() {
    echo -e "${BLUE}🔄 Restarting webhook service...${NC}"
    
    if [ -f "$SCRIPT_DIR/restart-webhook.sh" ]; then
        "$SCRIPT_DIR/restart-webhook.sh"
    else
        echo -e "${RED}❌ Webhook service not found${NC}"
        echo "Run '$0 setup' first to set up the control node"
        exit 1
    fi
}

# Function to check service status
check_status() {
    echo -e "${BLUE}📊 Auto-Deployment Control Node Status${NC}"
    echo "======================================="
    
    # Check if webhook service is running
    echo -e "\n${YELLOW}1. Webhook Service Status:${NC}"
    if [ -f "$SCRIPT_DIR/webhook.pid" ]; then
        PID=$(cat "$SCRIPT_DIR/webhook.pid")
        if kill -0 "$PID" 2>/dev/null; then
            echo -e "${GREEN}✅ Webhook service is running (PID: $PID)${NC}"
            
            # Test health endpoint
            if curl -s -f "http://localhost:$WEBHOOK_PORT/health" >/dev/null 2>&1; then
                HEALTH=$(curl -s "http://localhost:$WEBHOOK_PORT/health" | python3 -m json.tool 2>/dev/null || echo "Service responding")
                echo "$HEALTH"
            else
                echo -e "${YELLOW}⚠️  Service running but health endpoint not responding${NC}"
            fi
        else
            echo -e "${RED}❌ Webhook service not running (stale PID file)${NC}"
        fi
    else
        echo -e "${RED}❌ Webhook service not running${NC}"
    fi
    
    # Check active deployments
    echo -e "\n${YELLOW}2. Active Deployments:${NC}"
    if curl -s -f "http://localhost:$WEBHOOK_PORT/deployments" >/dev/null 2>&1; then
        DEPLOYMENTS=$(curl -s "http://localhost:$WEBHOOK_PORT/deployments" | python3 -m json.tool 2>/dev/null || echo "Could not parse deployments")
        echo "$DEPLOYMENTS"
    else
        echo "Could not retrieve deployment status"
    fi
    
    # Check target server connectivity
    echo -e "\n${YELLOW}3. Target Server Connectivity:${NC}"
    if command -v ansible &> /dev/null; then
        if ansible digitalocean -m ping 2>/dev/null | grep -q "SUCCESS"; then
            echo -e "${GREEN}✅ Target server is reachable${NC}"
        else
            echo -e "${RED}❌ Target server is not reachable${NC}"
        fi
    else
        echo -e "${YELLOW}⚠️  Ansible not available to test target connectivity${NC}"
    fi
    
    # Check configuration
    echo -e "\n${YELLOW}4. Configuration:${NC}"
    if [ -f "$SCRIPT_DIR/deploy_config.yml" ]; then
        echo -e "${GREEN}✅ Configuration file exists${NC}"
        if [ -f "$SCRIPT_DIR/webhook_control.py" ]; then
            # Test configuration
            if python3 "$SCRIPT_DIR/webhook_control.py" --test-config 2>/dev/null; then
                echo -e "${GREEN}✅ Configuration is valid${NC}"
            else
                echo -e "${RED}❌ Configuration has issues${NC}"
            fi
        fi
    else
        echo -e "${RED}❌ Configuration file not found${NC}"
    fi
}

# Function to show logs
show_logs() {
    echo -e "${BLUE}📝 Webhook Service Logs${NC}"
    echo "======================="
    
    if [ -f "$SCRIPT_DIR/logs/webhook.log" ]; then
        echo -e "\n${YELLOW}Recent webhook logs:${NC}"
        tail -50 "$SCRIPT_DIR/logs/webhook.log"
    else
        echo -e "${RED}❌ Webhook log file not found${NC}"
    fi
    
    echo -e "\n${YELLOW}Recent deployment logs:${NC}"
    if [ -d "$SCRIPT_DIR/logs" ]; then
        ls -lat "$SCRIPT_DIR/logs"/deploy_*.log 2>/dev/null | head -5 || echo "No deployment logs found"
    else
        echo "Logs directory not found"
    fi
}

# Function to show webhook configuration
show_webhook_config() {
    echo -e "${BLUE}🔗 Webhook Configuration${NC}"
    echo "========================"
    
    CONTROL_IP=$(get_control_ip)
    
    # Try to get webhook secret from config
    WEBHOOK_SECRET="your-webhook-secret"
    if [ -f "group_vars/prod.yml" ]; then
        WEBHOOK_SECRET=$(grep "webhook_secret:" group_vars/prod.yml | cut -d'"' -f2 2>/dev/null || echo "your-webhook-secret")
    fi
    
    echo -e "\n${YELLOW}📡 Webhook Endpoint:${NC}"
    echo "http://$CONTROL_IP:$WEBHOOK_PORT/webhook"
    
    echo -e "\n${YELLOW}🔐 Webhook Secret:${NC}"
    echo "$WEBHOOK_SECRET"
    
    echo -e "\n${YELLOW}📋 GitHub Configuration:${NC}"
    echo "For each repository, add a webhook with:"
    echo "1. Go to repository → Settings → Webhooks → Add webhook"
    echo "2. Set Payload URL: http://$CONTROL_IP:$WEBHOOK_PORT/webhook"
    echo "3. Set Content type: application/json"
    echo "4. Set Secret: $WEBHOOK_SECRET"
    echo "5. Select 'Just the push event'"
    echo "6. Ensure 'Active' is checked"
    echo "7. Click 'Add webhook'"
    
    echo -e "\n${YELLOW}📋 GitLab Configuration:${NC}"
    echo "For each project, add a webhook with:"
    echo "1. Go to project → Settings → Webhooks"
    echo "2. Set URL: http://$CONTROL_IP:$WEBHOOK_PORT/webhook"
    echo "3. Set Secret Token: $WEBHOOK_SECRET"
    echo "4. Check 'Push events'"
    echo "5. Click 'Add webhook'"
    
    echo -e "\n${YELLOW}🔧 Control Node Architecture:${NC}"
    echo "┌─────────────────┐    ┌─────────────────┐    ┌─────────────────┐"
    echo "│ GitHub/GitLab   │───▶│ Control Node    │───▶│ Target Server   │"
    echo "│ (webhook)       │    │ (webhook+ansible)│    │ (applications)  │"
    echo "└─────────────────┘    └─────────────────┘    └─────────────────┘"
    echo ""
    echo "• Webhooks point to this control node"
    echo "• Control node runs Ansible to deploy to target servers"
    echo "• Target servers only run your applications"
    
    echo -e "\n${YELLOW}🧪 Test Configuration:${NC}"
    echo "$0 test"
}

# Function to test configuration
test_configuration() {
    echo -e "${BLUE}🧪 Testing Auto-Deployment Configuration${NC}"
    echo "========================================"
    
    # Test webhook endpoint
    echo -e "\n${YELLOW}Testing webhook endpoint...${NC}"
    if curl -s -f "http://localhost:$WEBHOOK_PORT/health" >/dev/null 2>&1; then
        echo -e "${GREEN}✅ Webhook endpoint is accessible${NC}"
        curl -s "http://localhost:$WEBHOOK_PORT/health" | python3 -m json.tool 2>/dev/null || echo "Service responding"
    else
        echo -e "${RED}❌ Webhook endpoint not accessible${NC}"
        echo "Make sure the webhook service is running: $0 start"
        return 1
    fi
    
    # Test webhook security (should reject unsigned requests)
    echo -e "\n${YELLOW}Testing webhook security...${NC}"
    RESPONSE=$(curl -s -w "%{http_code}" -o /dev/null -X POST "http://localhost:$WEBHOOK_PORT/webhook" -H "Content-Type: application/json" -d '{"test": "data"}')
    if [ "$RESPONSE" = "401" ]; then
        echo -e "${GREEN}✅ Webhook security working (correctly rejecting unsigned requests)${NC}"
    else
        echo -e "${RED}❌ Webhook security issue (response: $RESPONSE)${NC}"
    fi
    
    # Test Ansible connectivity to target servers
    echo -e "\n${YELLOW}Testing target server connectivity...${NC}"
    if command -v ansible &> /dev/null; then
        if ansible digitalocean -m ping 2>/dev/null | grep -q "SUCCESS"; then
            echo -e "${GREEN}✅ Can reach target servers via Ansible${NC}"
        else
            echo -e "${RED}❌ Cannot reach target servers${NC}"
            echo "Check your inventory and SSH configuration"
        fi
    else
        echo -e "${RED}❌ Ansible not found${NC}"
    fi
    
    # Test configuration file
    echo -e "\n${YELLOW}Testing configuration...${NC}"
    if [ -f "$SCRIPT_DIR/webhook_control.py" ]; then
        if python3 "$SCRIPT_DIR/webhook_control.py" --test-config; then
            echo -e "\n${GREEN}🎉 All tests passed!${NC}"
        else
            echo -e "\n${RED}❌ Configuration test failed${NC}"
            return 1
        fi
    else
        echo -e "${RED}❌ Webhook application not found${NC}"
        echo "Run '$0 setup' to install the webhook service"
        return 1
    fi
}

# Parse command line arguments
ACTION="$1"

case "$ACTION" in
    setup)
        setup_control_node
        ;;
    start)
        start_service
        ;;
    stop)
        stop_service
        ;;
    restart)
        restart_service
        ;;
    status)
        check_status
        ;;
    logs)
        show_logs
        ;;
    webhook)
        show_webhook_config
        ;;
    test)
        test_configuration
        ;;
    -h|--help|help|"")
        show_help
        ;;
    *)
        echo -e "${RED}❌ Unknown action: $ACTION${NC}"
        echo "Use $0 --help for usage information"
        exit 1
        ;;
esac 