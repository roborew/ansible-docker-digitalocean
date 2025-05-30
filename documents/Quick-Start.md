# Quick Start Guide

Get your Ansible DigitalOcean deployment system up and running in minutes!

## Prerequisites

### Required

- DigitalOcean account with API token
- SSH key (either in 1Password or traditional ~/.ssh/ keys)

### Platform-Specific

- **macOS**: Homebrew (for Ansible installation)
- **Ubuntu**: Python 3 and pip3 (for Ansible installation)

## 🚀 New User Setup

### 1. Bootstrap (one-time setup)

```bash
git clone https://github.com/roborew/robo-ansible.git
cd robo-ansible
./scripts/bootstrap.sh
```

The bootstrap script will:

- Install Ansible and required collections
- Create configuration template files
- Set up vault password for encryption
- Validate your environment

### 2. Configure (edit your settings)

```bash
# Add your DigitalOcean API token and SSH keys
nano .env

# Configure your applications and server settings
nano group_vars/prod.yml
```

**Essential .env variables:**

```bash
DO_API_TOKEN=your_digitalocean_api_token
DO_SSH_KEYS=your-ssh-key-name
SERVER_USERNAME=your_username
ROOT_PASSWORD=secure_password_123
```

**Essential app configuration in group_vars/prod.yml:**

```yaml
apps:
  - name: "myapp"
    repo: "https://github.com/yourusername/myapp.git"
    branch: "main"
    hostname: "myapp.yourdomain.com"
    port: "3000"
```

### 3. Setup Environment Files (for your applications)

```bash
# Generate deploy keys for private repositories (if needed)
./scripts/setup-deploy-keys.sh

# Manually add the displayed public keys to your GitHub repositories:
# Go to: github.com/username/repo → Settings → Deploy keys → Add deploy key
# Paste the public key and optionally enable "Allow write access"

# Create environment file templates for each app
ansible-playbook playbooks/manage-env.yml -e action=create -e app_name=myapp

# Edit the environment files
./scripts/manage-env.sh edit myapp

# Encrypt them for security
ansible-playbook playbooks/manage-env.yml -e action=encrypt -e app_name=myapp
```

### 4. Deploy (with automatic validation & encryption)

```bash
# Provision server and deploy everything
ansible-playbook playbooks/provision-and-configure.yml
ansible-playbook playbooks/deploy-stack.yml

# SSH keys for private repos are automatically deployed and detected
# No manual parameters needed!
```

## 🔄 Returning User Workflow

For subsequent deployments, it's just one command:

```bash
ansible-playbook playbooks/deploy.yml
```

## ✨ What Happens During Setup

**Bootstrap script handles:**

- Ansible installation (via Homebrew on macOS, pip on Ubuntu)
- Required Ansible collections (community.digitalocean, etc.)
- Configuration file creation from templates
- Vault password setup for encryption
- Environment validation

**Configuration validation includes:**

- Environment variables loaded from `.env` file
- Configuration files validated and encrypted automatically
- App environment files checked and validated
- SSH keys and DigitalOcean API tested before deployment
- System readiness verified before any deployment tasks run

## 🎯 Verification

After setup, verify everything is working:

```bash
# Test your DigitalOcean API connection
ansible-playbook playbooks/test-do-api.yml

# Test deployment system
ansible-playbook playbooks/test-deployment.yml

# Check your app status
ansible digitalocean -m shell -a "cd /opt/myapp/current && docker compose ps"
```

## 🔗 Next Steps

Once you have the basic setup working:

- **[Deploy a feature branch](Branch-Deployments.md)** - Test new features safely
- **[Add more applications](Configuration.md#adding-new-applications)** - Deploy multiple apps
- **[Set up monitoring](Monitoring.md)** - Track your deployments
- **[Configure rollbacks](Rollback-System.md)** - Prepare for emergency rollbacks

## 🆘 Need Help?

- **[Common Issues](Troubleshooting.md)** - Solutions to common problems
- **[Docker Issues](Docker-Troubleshooting.md)** - Build and runtime problems
- **[SSH Problems](SSH-Keys.md)** - SSH key setup and connectivity

## 🔧 Example App Requirements

Your application repository needs a `docker-compose.yml` file with:

```yaml
services:
  app:
    build: .
    networks:
      - proxy
    labels:
      caddy: "${CADDY_HOSTNAME:-myapp.example.com}"
      caddy.reverse_proxy: "{{upstreams ${CADDY_PORT:-3000}}}"

networks:
  proxy:
    external: true
    name: ${PROXY_NETWORK:-proxy}
```

See the complete [Application Requirements](Deployment-System.md#application-requirements) for details.
