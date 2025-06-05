# Ansible DigitalOcean Deployment

🚀 **Automated DigitalOcean droplet provisioning and deployment with Capistrano-style releases, zero-downtime deployments, and automatic HTTPS certificates.**

## Features

- ⚡ **One-command setup** - Bootstrap everything with `./scripts/bootstrap.sh`
- 🚀 **Unified deployment system** - Single playbook handles infrastructure + selective app deployment
- 🎯 **Capistrano-style releases** - Zero-downtime deployments with instant rollbacks
- 📦 **Selective deployment** - Deploy specific apps, new-only, or all apps with granular control
- 🐳 **Docker-based deployments** - Automatic Docker and Docker Compose setup
- 🌿 **Branch deployments** - Deploy any branch as separate staging environment
- 🔐 **Private repository support** - Automatic SSH key management for private repos
- 🌐 **Automatic HTTPS** - Caddy proxy with Let's Encrypt certificates
- 🚧 **Maintenance mode** - Professional "Under Construction" pages for individual apps or entire system
- 🤖 **Auto-deployment** - Automatic deployments when pushing to configured branches (main, staging, test)
- 🔒 **Security by default** - UFW firewall, encrypted configurations, secure file permissions
- 🔑 **1Password integration** - Support for 1Password SSH keys

## Quick Start

### Prerequisites

- DigitalOcean account with API token
- SSH key (1Password or traditional)
- macOS (with Homebrew) or Ubuntu (with Python 3)

### 🚀 Get Started in 5 Steps

```bash
# 1. Clone and bootstrap
git clone https://github.com/roborew/robo-ansible.git
cd robo-ansible
./scripts/bootstrap.sh

# 2. Add configuration files
cp env.example .env
nano .env                        # Add DO_API_TOKEN and SSH keys
nano group_vars/prod.yml         # Add your applications
source venv/bin/activate         # Always do this before using Ansible


# 3. Activate Python environment and load environment variables
source venv/bin/activate  # Always do this before using Ansible
source .env                      # Load your DigitalOcean API token


# 4. Setup environment files for your apps (if needed)
ansible-playbook playbooks/manage-env.yml -e action=create -e app_name=myapp
./scripts/manage-env.sh edit myapp                                       # Edit environment variables
ansible-playbook playbooks/manage-env.yml -e action=encrypt -e app_name=myapp

# 5. Deploy everything (SSH keys generated automatically)
ansible-playbook playbooks/provision-and-configure.yml
ansible-playbook playbooks/deploy.yml -e infrastructure_setup=true      # Complete setup: infrastructure + apps
```

### 🔄 Daily Usage

```bash
# Activate environment first (every session)
source venv/bin/activate
source .env

# Deploy only new apps (recommended)
ansible-playbook playbooks/deploy.yml -e deploy_mode="new-only"

# Deploy specific apps
ansible-playbook playbooks/deploy.yml -e apps_to_deploy="app1,app2"

# Deploy feature branch for testing
ansible-playbook playbooks/deploy.yml -e apps_to_deploy="myapp" -e mode=branch -e branch=new-feature

# Emergency rollback
ansible-playbook playbooks/deploy.yml -e apps_to_deploy="myapp" -e mode=rollback
```

## 📚 Documentation

**Complete documentation is available in our [Documentation Wiki](documents/Home.md)**

### 🚀 Getting Started

- **[Quick Start Guide](documents/Quick-Start.md)** - Detailed setup instructions
- **[Configuration](documents/Configuration.md)** - Configure apps and servers
- **[Private Repositories](documents/Private-Repositories.md)** - Deploy from private GitHub repos

### 🎯 Core Features

- **[Capistrano-Style Deployments](documents/Deployment-System.md)** - Zero-downtime deployments
- **[Database Management](documents/Database-Management.md)** - Automatic backups and rollbacks
- **[Environment Management](documents/Environment-Management.md)** - Secure .env file handling
- **[Branch Deployments](documents/Branch-Deployments.md)** - Feature branch testing
- **[Rollback System](documents/Rollback-System.md)** - Instant rollbacks
- **[Maintenance Mode](documents/Maintenance-Mode.md)** - Professional "Under Construction" pages
- **[Auto-Deployment](documents/Auto-Deployment.md)** - Automatic deployments on push to configured branches

### 🛠️ Troubleshooting & Reference

- **[Troubleshooting Guide](documents/Troubleshooting.md)** - Common issues and solutions
- **[SSH Key Management](documents/SSH-Keys.md)** - 1Password and traditional SSH setup
- **[Security Guide](documents/Security.md)** - Security best practices
- **[Contributing](documents/Contributing.md)** - How to contribute to the project

## Architecture Overview

```
┌─────────────────────┐    ┌─────────────────────┐    ┌─────────────────────┐
│   Local Machine     │    │   DigitalOcean      │    │   GitHub Repos      │
│                     │    │                     │    │                     │
│  ┌─────────────┐    │    │  ┌─────────────┐    │    │  ┌─────────────┐    │
│  │   Ansible   │────┼────┼─▶│   Docker    │    │    │  │ Your Apps   │    │
│  │  Playbooks  │    │    │  │ Containers  │    │    │  │   (public   │    │
│  └─────────────┘    │    │  └─────────────┘    │    │  │  & private) │    │
│                     │    │         │           │    │  └─────────────┘    │
│  ┌─────────────┐    │    │  ┌─────────────┐    │    │           │         │
│  │ Environment │    │    │  │    Caddy    │────┼────┼───────────┘         │
│  │   Config    │    │    │  │   Proxy     │    │    │                     │
│  │ (encrypted) │    │    │  │  (HTTPS)    │    │    │                     │
│  └─────────────┘    │    │  └─────────────┘    │    │                     │
└─────────────────────┘    └─────────────────────┘    └─────────────────────┘
```

## Example Configuration

**Your app just needs a `docker-compose.yml`:**

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

**Result:** Your app automatically gets HTTPS at `https://myapp.example.com` 🎉

## Common Commands

> **Remember**: Always run `source venv/bin/activate` and `source .env` first in each terminal session!

```bash
# Activate environment (always run these first)
source venv/bin/activate
source .env

# Deploy production (all apps)
ansible-playbook playbooks/deploy.yml

# Deploy only NEW apps (skips existing)
ansible-playbook playbooks/deploy.yml -e deploy_mode="new-only"

# Deploy specific apps (comma-separated)
ansible-playbook playbooks/deploy.yml -e apps_to_deploy="app1,app2"

# Deploy all apps (redeploy existing + new)
ansible-playbook playbooks/deploy.yml -e deploy_mode="all"

# Deploy feature branch for specific app
ansible-playbook playbooks/deploy.yml -e apps_to_deploy="myapp" -e mode=branch -e branch=feature-name

# Custom retention settings (keep more releases/backups)
ansible-playbook playbooks/deploy.yml -e releases_to_keep=10 -e backups_to_keep=15

# Rollback specific apps (code only)
ansible-playbook playbooks/deploy.yml -e mode=rollback -e apps_to_deploy="myapp"

# Rollback with database restore
ansible-playbook playbooks/deploy.yml -e mode=rollback -e apps_to_deploy="myapp" -e restore_database=true

# Rollback all apps
ansible-playbook playbooks/deploy.yml -e mode=rollback -e deploy_mode="all"

# Maintenance mode
./scripts/maintenance-mode.sh enable                    # Enable for all apps
./scripts/maintenance-mode.sh enable -a myapp          # Enable for specific app only
./scripts/maintenance-mode.sh disable                  # Disable maintenance
./scripts/maintenance-mode.sh status                   # Check status

# Auto-deployment
./scripts/auto-deploy.sh setup                         # Setup auto-deployment service
./scripts/auto-deploy.sh status                        # Check webhook service status
./scripts/auto-deploy.sh webhook                       # Show webhook configuration
./scripts/auto-deploy.sh logs                          # View deployment logs

# Database management
ansible-playbook playbooks/database-management.yml -e op=list -e app=myapp
ansible-playbook playbooks/database-management.yml -e op=backup -e app=myapp

# Check app status
ansible digitalocean -m shell -a "cd /opt/myapp/current && docker compose ps"

# View deployment logs
ansible digitalocean -m shell -a "tail -f /opt/myapp/shared/logs/deploy_*.log"
```

## Support

- **Documentation**: [Wiki Documentation](documents/Home.md)
- **Issues**: [GitHub Issues](https://github.com/roborew/robo-ansible/issues)
- **Discussions**: [GitHub Discussions](https://github.com/roborew/robo-ansible/discussions)

## Contributing

We welcome contributions! For production users, we recommend a **dual-repository setup**:

- **Private repo**: Your production deployments with real credentials
- **Public repo**: Community contributions with sanitized code

```bash
# Sync improvements to public repository
./scripts/sync-to-public.sh
```

See our [Dual Repository Setup](documents/Dual-Repository-Setup.md) and [Contributing Guide](documents/Contributing.md) for complete details.

## License

This project is licensed under the MIT License - see the [LICENSE](LICENSE) file for details.

---

**[📚 View Complete Documentation](documents/Home.md)** | **[🚀 Quick Start Guide](documents/Quick-Start.md)** | **[🛠️ Troubleshooting](documents/Troubleshooting.md)**
