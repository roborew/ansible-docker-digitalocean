# Auto-Deployment System

## 🏗️ **Architecture Overview**

The auto-deployment system uses a **control node architecture** that separates concerns between orchestration and application hosting:

```
┌─────────────────┐    ┌─────────────────────┐    ┌─────────────────────┐
│   GitHub/GitLab │    │   Control Node      │    │   Target Server     │
│                 │    │   (Mac Mini)        │    │   (DigitalOcean)    │
│  Repository ────┼────┤  ┌─────────────────┐│    │                     │
│  (webhook)      │    │  │ Webhook Service ││    │  ┌─────────────────┐│
│                 │    │  │ + Ansible       ││────┼─▶│  Applications   ││
│                 │    │  └─────────────────┘│    │  │  (Docker)       ││
│                 │    │                     │    │  └─────────────────┘│
└─────────────────┘    └─────────────────────┘    └─────────────────────┘
```

### **Benefits**

- ✅ **Clean separation** - Control node orchestrates, target servers run apps
- ✅ **Secure** - Target servers have minimal attack surface
- ✅ **Scalable** - One control node can manage multiple target servers
- ✅ **Proper DevOps** - Follows infrastructure-as-code principles
- ✅ **Flexible** - Control node can be Mac Mini, separate droplet, or CI/CD server

## 🎛️ **Control Node Setup**

### **Prerequisites**

- **Control Node** (Mac Mini, separate droplet, or dedicated server)
- **Python 3.7+** installed on control node
- **Ansible** installed on control node
- **SSH access** from control node to target servers
- **Network connectivity** from GitHub/GitLab to control node

### **Quick Setup**

1. **Clone this repository on your control node:**

   ```bash
   git clone <your-repo> robo-ansible
   cd robo-ansible
   ```

2. **Configure auto-deployment in `group_vars/prod.yml`:**

   ```yaml
   auto_deploy:
     enabled: true
     webhook_port: 9000
     webhook_secret: "your-secure-secret-here"
     deploy_delay: 30
     max_concurrent_deploys: 2

   apps:
     - name: "myapp"
       repo: "https://github.com/user/myapp.git"
       auto_deploy:
         enabled: true
         branches:
           - name: "main"
             hostname: "myapp.example.com"
             environment: "production"
           - name: "staging"
             hostname: "staging-myapp.example.com"
             environment: "staging"
   ```

3. **Run setup on your control node:**

   ```bash
   ./scripts/auto-deploy-control.sh setup
   ```

4. **Start the webhook service:**

   ```bash
   ./scripts/auto-deploy-control.sh start
   ```

5. **Configure repository webhooks:**
   ```bash
   ./scripts/auto-deploy-control.sh webhook
   ```

## 🔧 **Control Node Management**

### **Service Commands**

```bash
# Setup control node
./scripts/auto-deploy-control.sh setup

# Start webhook service
./scripts/auto-deploy-control.sh start

# Stop webhook service
./scripts/auto-deploy-control.sh stop

# Restart webhook service
./scripts/auto-deploy-control.sh restart

# Check service status
./scripts/auto-deploy-control.sh status

# View logs
./scripts/auto-deploy-control.sh logs

# Show webhook configuration
./scripts/auto-deploy-control.sh webhook

# Test configuration
./scripts/auto-deploy-control.sh test
```

### **Service Management**

The webhook service runs as a Python application on your control node:

- **Service Directory:** `~/auto-deploy/`
- **Logs:** `~/auto-deploy/logs/`
- **Configuration:** `~/auto-deploy/deploy_config.yml`
- **Python Environment:** `~/auto-deploy/venv/`

## 📡 **Webhook Configuration**

### **GitHub Setup**

For each repository that should trigger auto-deployment:

1. Go to **Repository → Settings → Webhooks**
2. Click **Add webhook**
3. Configure:
   - **Payload URL:** `http://your-control-node-ip:9000/webhook`
   - **Content type:** `application/json`
   - **Secret:** Your webhook secret from configuration
   - **Events:** Select "Just the push event"
   - **Active:** ✅ Checked

### **GitLab Setup**

For each project:

1. Go to **Project → Settings → Webhooks**
2. Configure:
   - **URL:** `http://your-control-node-ip:9000/webhook`
   - **Secret Token:** Your webhook secret
   - **Push events:** ✅ Checked
3. Click **Add webhook**

### **Webhook Security**

- All webhook requests are **signature-verified** using HMAC-SHA256
- Invalid signatures are rejected with 401 status
- Only configured branches trigger deployments
- Repository URLs are matched against configuration

## ⚙️ **Configuration**

### **Global Settings**

```yaml
auto_deploy:
  enabled: true # Enable/disable auto-deployment
  webhook_port: 9000 # Port for webhook service
  webhook_secret: "secure-secret" # HMAC secret for webhook verification
  webhook_path: "/webhook" # Webhook endpoint path
  deploy_delay: 30 # Seconds to wait before deploying (batching)
  max_concurrent_deploys: 2 # Maximum concurrent deployments
  notification_email: "" # Email for deployment notifications (optional)
```

### **Per-App Configuration**

```yaml
apps:
  - name: "myapp"
    repo: "https://github.com/user/myapp.git"
    auto_deploy:
      enabled: true
      branches:
        - name: "main"
          hostname: "myapp.example.com"
          environment: "production"
          deploy_user: "deploy" # Optional: specific deploy user
          deploy_path: "/var/www" # Optional: specific deploy path

        - name: "staging"
          hostname: "staging.example.com"
          environment: "staging"

        - name: "develop"
          hostname: "dev.example.com"
          environment: "development"
```

### **Branch Matching**

- **Exact match:** Branch name must exactly match configured name
- **Repository match:** Repository URL is normalized and compared
- **Multiple environments:** Same repository can deploy different branches to different environments

## 🚀 **Deployment Process**

### **Trigger Flow**

1. **Developer pushes** to configured branch (e.g., `main`, `staging`)
2. **GitHub/GitLab sends webhook** to control node
3. **Webhook service verifies** signature and matches configuration
4. **Deployment is scheduled** with delay (for batching multiple commits)
5. **Ansible runs** from control node to deploy to target server
6. **Deployment logs** are captured and stored

### **Batching Logic**

- **Deploy delay** prevents rapid-fire deployments from multiple quick commits
- **Last commit wins** - if multiple commits happen during delay, only latest is deployed
- **Concurrent limits** prevent overwhelming target servers
- **Queue management** handles multiple apps deploying simultaneously

### **Ansible Execution**

The webhook service executes Ansible from the control node:

```bash
ansible-playbook playbooks/deploy.yml \
  -i inventory/hosts.yml \
  -e mode=branch \
  -e branch=main \
  -e app=myapp \
  -e deploy_environment=production \
  -e auto_deploy=true
```

## 📊 **Monitoring & Logging**

### **Real-Time Status**

```bash
# Check webhook service health
curl http://localhost:9000/health

# View active deployments
curl http://localhost:9000/deployments

# View configuration (secrets redacted)
curl http://localhost:9000/config
```

### **Log Files**

- **Webhook logs:** `~/auto-deploy/logs/webhook.log`
- **Service output:** `~/auto-deploy/logs/webhook.out`
- **Deployment logs:** `~/auto-deploy/logs/deploy_<id>.log`

### **Log Rotation**

- Webhook logs rotate at 10MB, keeping 5 backups
- Deployment logs are preserved for last 20 deployments
- All logs include timestamps and deployment IDs

## 🔐 **Security**

### **Webhook Security**

- **HMAC-SHA256** signature verification on all requests
- **Secret rotation** supported via configuration update
- **IP filtering** can be implemented at network level
- **Rate limiting** prevents webhook spam

### **SSH Security**

- **Key-based authentication** from control node to target servers
- **Ansible user** with limited sudo permissions
- **SSH agent forwarding** not required
- **Firewall rules** protect target servers

### **Network Security**

- **Webhook endpoint** only accepts POST requests
- **Health endpoints** provide no sensitive information
- **Configuration endpoint** redacts secrets
- **Target servers** don't expose Ansible or webhook services

## 🛠️ **Troubleshooting**

### **Common Issues**

**Webhook service won't start:**

```bash
# Check configuration
./scripts/auto-deploy-control.sh test

# Check Python dependencies
~/auto-deploy/venv/bin/python -c "import flask, yaml, requests"

# Check port availability
netstat -an | grep :9000
```

**Deployments not triggering:**

```bash
# Check webhook logs
tail -f ~/auto-deploy/logs/webhook.log

# Test webhook manually
curl -X POST http://localhost:9000/webhook \
  -H "Content-Type: application/json" \
  -H "X-Hub-Signature-256: sha256=$(echo -n '{}' | openssl dgst -sha256 -hmac 'your-secret')" \
  -d '{}'
```

**Cannot reach target servers:**

```bash
# Test Ansible connectivity
ansible digitalocean -m ping

# Check SSH connectivity
ssh -i ~/.ssh/your-key user@target-server

# Verify inventory configuration
ansible-inventory --list
```

**Deployment failures:**

```bash
# Check deployment logs
ls -la ~/auto-deploy/logs/deploy_*.log

# Run manual deployment
ansible-playbook playbooks/deploy.yml -e mode=branch -e branch=main -e app=myapp
```

### **Configuration Validation**

The webhook service includes built-in configuration validation:

```bash
# Test all configuration
./scripts/auto-deploy-control.sh test

# Test specific components
python3 ~/auto-deploy/webhook_control.py --test-config
ansible digitalocean -m ping
curl http://localhost:9000/health
```

## 📈 **Advanced Configuration**

### **Multiple Control Nodes**

For high availability, run multiple control nodes:

- Use **load balancer** to distribute webhook requests
- **Shared configuration** via Git or configuration management
- **Deployment coordination** to prevent conflicts
- **Health checks** for automatic failover

### **Custom Deployment Logic**

Extend the deployment process:

- **Pre-deployment hooks** for testing or validation
- **Post-deployment hooks** for monitoring or notifications
- **Environment-specific playbooks** for different deployment strategies
- **Blue-green deployments** for zero-downtime updates

### **Integration with CI/CD**

Combine with existing pipelines:

- **Webhook as final step** after CI/CD tests pass
- **Deployment gates** based on external conditions
- **Rollback triggers** from monitoring systems
- **Multi-stage approvals** for production deployments

## 🎯 **Best Practices**

### **Control Node**

- **Dedicated hardware** for reliability (Mac Mini ideal for home labs)
- **Regular backups** of configuration and SSH keys
- **Monitoring** of webhook service health
- **Network redundancy** for high availability

### **Target Servers**

- **Minimal services** - only run your applications
- **Regular security updates** automated via Ansible
- **Resource monitoring** to prevent overload
- **Backup strategies** independent of deployment

### **Configuration Management**

- **Version control** for all configuration files
- **Environment separation** for staging vs production
- **Secret management** using Ansible Vault or external systems
- **Change tracking** for deployment configurations

### **Deployment Strategy**

- **Staged rollouts** using branch-based environments
- **Health checks** before marking deployments successful
- **Rollback procedures** for quick recovery
- **Communication** to team about deployment status

## 🎉 **Getting Started Checklist**

- [ ] **Set up control node** (Mac Mini or dedicated server)
- [ ] **Install Ansible** and Python dependencies
- [ ] **Configure SSH access** to target servers
- [ ] **Update configuration** in `group_vars/prod.yml`
- [ ] **Run setup** on control node
- [ ] **Start webhook service**
- [ ] **Configure repository webhooks**
- [ ] **Test with sample push**
- [ ] **Monitor deployment logs**
- [ ] **Document process** for your team

**Control node architecture provides clean separation, better security, and easier management compared to running deployment services on target servers!**
