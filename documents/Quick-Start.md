# Quick Start Guide

This guide will help you get up and running with the Ansible DigitalOcean Deployment system in minutes.

## 🚀 Prerequisites

- **DigitalOcean Account** - With an API token
- **SSH Key** - Either a traditional SSH key or 1Password SSH key
- **macOS** (with Homebrew) or **Ubuntu** (with Python 3)

## 🎯 Quick Start

### 1. Clone and Bootstrap

```bash
# Clone the repository
git clone https://github.com/roborew/robo-ansible.git
cd robo-ansible

# Run the bootstrap script
./scripts/bootstrap.sh
```

### 2. Activate Python Environment

```bash
# Activate the virtual environment (required after bootstrap)
source venv/bin/activate
```

> 💡 **Important**: You must run `source venv/bin/activate` every time you start a new terminal session to use Ansible commands.

### 3. Configure Your Settings

```bash
# Copy the example environment file
cp env.example .env

# Edit the environment file with your settings
nano .env
```

**Required Settings:**

- `DO_API_TOKEN` - Your DigitalOcean API token
- `SSH_KEY_PATH` - Path to your SSH key (or 1Password SSH key)
- `SSH_KEY_PASSPHRASE` (optional) - Passphrase for your SSH key

### 4. Load Environment Variables

```bash
# Load environment variables from .env file
source .env

# Verify your API token is loaded (optional)
echo "DO_API_TOKEN is set: ${DO_API_TOKEN:0:8}..."
```

> 💡 **Important**: You must run `source .env` every time you start a new terminal session to load your DigitalOcean API token and other environment variables.

### 5. Add Your Applications

Edit `group_vars/prod.yml` to add your applications:

```yaml
applications:
  - name: myapp
    repo: https://github.com/yourusername/myapp.git
    branch: main
    hostname: myapp.example.com
    port: 3000
```

### 6. Deploy Everything

```bash
# First, activate environment and load variables
source venv/bin/activate
source .env

# Provision and configure the server
ansible-playbook playbooks/provision-and-configure.yml

# Deploy your applications
ansible-playbook playbooks/deploy.yml -e infrastructure_setup=true
```

## 🔧 Configuration

### Environment Variables

The `.env` file contains all your configuration settings. See [Environment Management](Environment-Management.md) for details.

### Applications

Each application in `group_vars/prod.yml` requires:

- `name` - A unique name for your app
- `repo` - Git repository URL
- `branch` - Branch to deploy (defaults to `main`)
- `hostname` - Domain name for your app
- `port` - Port your app listens on

See [Deployment System](Deployment-System.md) for advanced configuration options.

## 🐳 Docker Support

Your applications should include a `docker-compose.yml` file. The system automatically:

- Builds Docker images
- Runs containers
- Sets up a reverse proxy
- Configures automatic HTTPS
- **Creates database backups** before deployments
- **Handles rollbacks** with optional database restore

### **Database Strategy**

The system follows a **clear separation of concerns**:

- **Your App**: Handles database migrations during startup (Rails, Next.js with Drizzle, etc.)
- **Ansible**: Handles automatic backups and rollback safety

```bash
# Database backups are automatic, but you can also:

# List available backups
ansible-playbook playbooks/database-management.yml -e op=list -e app=myapp

# Create manual backup before risky operations
ansible-playbook playbooks/database-management.yml -e op=backup -e app=myapp

# Rollback with database restore (if needed)
ansible-playbook playbooks/deploy.yml -e mode=rollback -e app=myapp -e restore_database=true
```

Example `docker-compose.yml`:

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

## 🔄 Daily Usage

**Remember**: Always activate your environment and load variables first in each new terminal session:

```bash
# 1. Navigate to project and activate environment
cd robo-ansible
source venv/bin/activate

# 2. Load environment variables
source .env

# 3. Now you can run Ansible commands
```

### Deploy Latest Changes

```bash
# Make sure environment is activated and variables loaded
source venv/bin/activate
source .env

ansible-playbook playbooks/deploy.yml
```

### Deploy Feature Branch

```bash
# Make sure environment is activated and variables loaded
source venv/bin/activate
source .env

ansible-playbook playbooks/deploy.yml -e mode=branch -e branch=new-feature
```

### Emergency Rollback

```bash
# Make sure environment is activated and variables loaded
source venv/bin/activate
source .env

ansible-playbook playbooks/deploy.yml -e mode=rollback
```

## 🛠️ Troubleshooting

### Common Issues

**"ansible: command not found" or "ansible-vault: command not found"**

This means the virtual environment is not activated. Always run:

```bash
source venv/bin/activate
```

You'll know it's working when you see `(venv)` at the start of your terminal prompt.

**"Status code was 401 and not [200]: HTTP Error 401: Unauthorized"**

This means your DigitalOcean API token is not loaded in the environment. Always run:

```bash
source .env
```

After sourcing, you can verify with: `echo "Token loaded: ${DO_API_TOKEN:0:8}..."`

**"No such file or directory: venv/"**

The virtual environment wasn't created. Run bootstrap again:

```bash
./scripts/bootstrap.sh
```

**"No such file or directory: .env"**

The environment file doesn't exist. Create it from the example:

```bash
cp env.example .env
nano .env  # Edit with your settings
```

- **SSH Connection Issues** - See [Private Repositories](Private-Repositories.md) for SSH key setup
- **Docker Build Failures** - See [Deployment System](Deployment-System.md#docker-troubleshooting)
- **Deployment Errors** - Check the deployment logs in `/opt/<app>/shared/logs/`

### Getting Help

- [GitHub Issues](https://github.com/roborew/robo-ansible/issues) - Report bugs or request features
- [GitHub Discussions](https://github.com/roborew/robo-ansible/discussions) - Ask questions or share ideas

## 📚 Next Steps

- [Deployment System](Deployment-System.md) - Learn about the deployment system
- [Database Management](Database-Management.md) - Database backups, rollbacks, and migrations
- [Environment Management](Environment-Management.md) - Manage environment variables
- [Private Repositories](Private-Repositories.md) - Deploy from private GitHub repositories
- [Contributing](Contributing.md) - How to contribute to the project

---

**[🚀 Back to Home](Home.md)** | **[📚 Full Documentation](Home.md)**
