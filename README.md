# Ansible DigitalOcean Deployment

This Ansible project automates the provisioning and configuration of DigitalOcean droplets with Docker, tmux, and security configurations. It includes an advanced **Capistrano-style deployment system** with automatic reverse proxy, TLS certificate management, zero-downtime deployments, and rollback capabilities.

## Features

- 🚀 **Automated Droplet Provisioning**: Create DigitalOcean droplets with custom configurations
- 🐳 **Docker Installation**: Automatically installs and configures Docker CE
- 🎯 **Capistrano-Style Deployments**: Zero-downtime deployments with releases, rollbacks, and branch deployments
- 🔄 **Release Management**: Keeps deployment history with instant rollback capability
- 🌿 **Branch Deployments**: Deploy any branch as separate staging environment
- 🌐 **Reverse Proxy**: Caddy Docker Proxy with automatic TLS certificates
- 🔒 **Security Setup**: Configures UFW firewall with specified rules
- 👤 **User Management**: Creates a non-root user with Docker access
- 🔑 **SSH Key Management**: Supports 1Password SSH keys and traditional SSH keys
- 🖥️ **Tmux Configuration**: Sets up tmux with the gpakosz configuration
- 🔐 **Vault Support**: Encrypted configuration for production secrets
- 🌍 **Cross-Platform**: Works on macOS (with Homebrew) and Ubuntu (with pip)

## Prerequisites

### Required

- DigitalOcean account with API token
- SSH key (either in 1Password or traditional ~/.ssh/ keys)

### Platform-Specific

- **macOS**: Homebrew (for Ansible installation)
- **Ubuntu**: Python 3 and pip3 (for Ansible installation)
  \

## Quick Start

### **🚀 New User Setup**

1. **Bootstrap** (one-time setup):

   ```bash
   git clone https://github.com/roborew/robo-ansible.git
   cd robo-ansible
   ./scripts/bootstrap.sh
   ```

2. **Configure** (edit your settings):

   ```bash
   nano .env                    # Add DigitalOcean API token & SSH keys
   nano group_vars/prod.yml     # Add your applications
   ```

3. **Setup Environment Files** (for your applications):

   ```bash
   # Generate deploy keys for private repositories (run after step 2)
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

4. **Deploy** (with automatic validation & encryption):

   ```bash
   # Works for both public and private repositories
   ansible-playbook playbooks/provision-and-configure.yml
   ansible-playbook playbooks/deploy-stack.yml

   # SSH keys for private repos are automatically deployed and detected
   # No manual parameters needed!
   ```

### **🔄 Returning User Workflow**

```bash
ansible-playbook playbooks/deploy-stack.yml
```

**✨ All playbooks now include automatic pre-deployment validation:**

- Environment variables are loaded from `.env` file
- Configuration files are validated and encrypted automatically
- App environment files are checked and validated
- SSH keys and DigitalOcean API are tested before deployment
- System readiness is verified before any deployment tasks run

## 🎯 **Capistrano-Style Deployment System**

This project includes a complete **Capistrano-style deployment system** that provides zero-downtime deployments, release management, rollbacks, and branch deployments for your applications.

### **📁 Directory Structure**

Each application is deployed using the following Capistrano-style structure:

```
/opt/your-app/
├── current -> releases/1640995200/     # Symlink to active release
├── releases/                           # All deployments (keeps last 5)
│   ├── 1640995200/                    # Release 1 (timestamp-based)
│   ├── 1640995300/                    # Release 2
│   └── 1640995400/                    # Release 3 (current)
├── shared/                            # Persistent files across deployments
│   ├── config/
│   │   ├── .env                       # Environment variables (decrypted)
│   │   └── .env.vault                 # Environment variables (encrypted)
│   ├── logs/                          # Deployment and application logs
│   │   ├── build_1640995400.log       # Build log for each release
│   │   └── deploy_1640995400.log      # Deploy log for each release
│   └── data/                          # Persistent application data
├── repo/                              # Git repository cache
└── backups/                           # Database backups (future feature)
```

### **🚀 Deployment Commands**

#### **Initial Setup & Main Deployments**

```bash
# Initial setup (creates Capistrano structure + deploys main branch)
ansible-playbook playbooks/deploy-stack.yml

# Deploy main branch (subsequent deployments)
ansible-playbook playbooks/deploy.yml

# Deploy with verbose build output
ansible-playbook playbooks/deploy.yml -e verbose=true

# Deploy specific app only
ansible-playbook playbooks/deploy.yml -e app=myapp
```

#### **Branch Deployments (Testing & Staging)**

```bash
# Deploy any branch as separate staging environment
ansible-playbook playbooks/deploy.yml -e mode=branch -e branch=feature-auth

# Deploy specific app branch
ansible-playbook playbooks/deploy.yml -e mode=branch -e branch=hotfix-123 -e app=myapp

# Deploy branch with unique subdomain (automatic)
# Creates: feature-auth-456789.yourdomain.com
```

#### **Rollback Commands**

```bash
# Rollback to previous release (instant)
ansible-playbook playbooks/deploy.yml -e mode=rollback

# Rollback to specific release
ansible-playbook playbooks/deploy.yml -e mode=rollback -e release=1640995200

# Rollback specific app only
ansible-playbook playbooks/deploy.yml -e mode=rollback -e app=myapp
```

#### **System Testing & Monitoring**

```bash
# Test the entire deployment system
ansible-playbook playbooks/test-deployment.yml

# Quick status check
ansible digitalocean -m shell -a "cd /opt/myapp/current && docker compose ps"

# View recent deployment logs
ansible digitalocean -m shell -a "ls -la /opt/myapp/shared/logs/"

# Check available releases
ansible digitalocean -m shell -a "ls -la /opt/myapp/releases/"
```

#### **🔐 Private Repository Support**

This deployment system supports both public and private GitHub repositories with **automatic SSH key management**.

#### **Deploy Key Setup (for private repositories)**

```bash
# Generate deploy keys for your configured apps (after step 2)
./scripts/setup-deploy-keys.sh

# The script will display public keys for each app
# Add each public key to the corresponding GitHub repository:
# 1. Go to: github.com/username/repo-name
# 2. Settings → Deploy keys → Add deploy key
# 3. Paste the public key and give it a descriptive title
# 4. ✅ Check "Allow write access" (optional, for push capability)
```

#### **Deployment with Private Repositories**

```bash
# SSH keys are automatically deployed and detected
# Same commands work for both public and private repositories!

# Initial deployment
ansible-playbook playbooks/deploy-stack.yml

# Subsequent deployments
ansible-playbook playbooks/deploy.yml

# Branch deployments
ansible-playbook playbooks/deploy.yml -e mode=branch -e branch=feature-name

# Rollbacks (no special parameters needed)
ansible-playbook playbooks/deploy.yml -e mode=rollback
```

#### **How Automatic Detection Works**

✅ **SSH keys deployed once** - During `deploy-stack.yml`  
✅ **Automatic per-app detection** - Each app checks for its own key  
✅ **Smart URL conversion** - HTTPS URLs automatically converted to SSH when keys exist  
✅ **Zero configuration** - No manual parameters or configuration needed  
✅ **Multiple repos supported** - All private repos work simultaneously

#### **Security Best Practices**

✅ **Deploy keys are app-specific** - Each app has its own key  
✅ **Read-only by default** - Deploy keys don't have push access unless enabled  
✅ **Easy to revoke** - Remove from GitHub repo settings if compromised  
✅ **Stored securely** - Private keys never committed to git (`.gitignore` protected)  
✅ **Proper permissions** - Keys deployed with 600 permissions on server

**Note**: The system automatically falls back to HTTPS for repositories without deploy keys.

### **🔐 Environment File Management**

Environment files are managed securely with encryption and proper deployment:

#### **📍 Environment File Locations**

| Location                              | Purpose                   | Security       |
| ------------------------------------- | ------------------------- | -------------- |
| `env_files/myapp.env`                 | Local editing (temporary) | ⚠️ Unencrypted |
| `env_files/myapp.env.vault`           | Local storage             | ✅ Encrypted   |
| `/opt/myapp/shared/config/.env.vault` | Server storage            | ✅ Encrypted   |
| `/opt/myapp/shared/config/.env`       | Server runtime            | ⚠️ Decrypted   |
| `/opt/myapp/current/.env`             | Application access        | 🔗 Symlink     |

#### **🔧 Environment Management Commands**

```bash
# Create new .env template
ansible-playbook playbooks/manage-env.yml -e action=create -e app_name=myapp

# Edit .env file locally (quick helper)
./scripts/manage-env.sh edit myapp

# Encrypt .env file for security
ansible-playbook playbooks/manage-env.yml -e action=encrypt -e app_name=myapp

# Deploy encrypted .env to server
ansible-playbook playbooks/manage-env.yml -e action=deploy -e app_name=myapp

# List all managed .env files
ansible-playbook playbooks/manage-env.yml -e action=list

# Get help
ansible-playbook playbooks/manage-env.yml
```

#### **🔄 Environment Workflow**

1. **Create**: Generate .env template with secure defaults
2. **Edit**: Modify values for your application needs
3. **Encrypt**: Secure the file with ansible-vault
4. **Deploy**: Upload encrypted file to server
5. **Auto-Decrypt**: File is automatically decrypted during deployment and symlinked

### **🌟 Key Features**

✅ **Zero-downtime deployments** - Atomic symlink swaps  
✅ **Release management** - Keeps last 5 releases automatically  
✅ **Instant rollbacks** - Rollback to any previous release in seconds  
✅ **Branch deployments** - Deploy any branch as separate app with unique subdomain  
✅ **Environment encryption** - .env files encrypted with ansible-vault  
✅ **Shared file management** - Logs, data, config persist across deployments  
✅ **Deployment metadata** - Track who deployed what when  
✅ **Comprehensive logging** - Build and deploy logs for each release  
✅ **Health checks** - Verify containers are running after deployment  
✅ **Automatic cleanup** - Old releases cleaned up automatically

### **📊 Monitoring & Status**

```bash
# View deployment system status
ansible-playbook playbooks/test-deployment.yml

# Check specific app status
ansible digitalocean -m shell -a "cd /opt/myapp/current && docker compose ps"

# View deployment logs
ansible digitalocean -m shell -a "tail -f /opt/myapp/shared/logs/deploy_*.log"

# Check release history
ansible digitalocean -m shell -a "ls -lat /opt/myapp/releases/"

# View application logs
ansible digitalocean -m shell -a "cd /opt/myapp/current && docker compose logs --tail=50"
```

### **🔄 Typical Workflow**

1. **Initial Setup** (one-time, follows Quick Start guide):

   ```bash
   # Bootstrap project (includes environment file setup)
   ./scripts/bootstrap.sh

   # Configure settings and create environment files
   nano .env && nano group_vars/prod.yml

   # Create and encrypt app environment files
   ansible-playbook playbooks/manage-env.yml -e action=create -e app_name=myapp
   ./scripts/manage-env.sh edit myapp
   ansible-playbook playbooks/manage-env.yml -e action=encrypt -e app_name=myapp

   # Deploy everything
   ansible-playbook playbooks/deploy-stack.yml
   ```

2. **Regular Deployments**:

   ```bash
   ansible-playbook playbooks/deploy.yml
   ```

3. **Feature Branch Testing**:

   ```bash
   ansible-playbook playbooks/deploy.yml -e mode=branch -e branch=new-feature
   ```

4. **Emergency Rollback**:
   ```bash
   ansible-playbook playbooks/deploy.yml -e mode=rollback
   ```

### **🔑 Vault Password Management**

Since both `group_vars/prod.yml` and `inventory/hosts.yml` are encrypted, this project uses a vault password file for seamless automation.

**Initial Setup (Handled by Bootstrap)**
The `bootstrap.sh` script automatically prompts you to create the vault password file during initial setup. If you need to create or update it manually:

```bash
# Create vault password file (keep this secure!)
echo "your-vault-password" > .vault_pass
chmod 600 .vault_pass

# The ansible.cfg is already configured to use this file
# vault_password_file = .vault_pass
```

**Benefits**:

- ✅ No need to type password multiple times
- ✅ Seamless access to both encrypted files
- ✅ Fully automated deployments
- ✅ No `--ask-vault-pass` flags needed

**Alternative: Manual Password Entry**

```bash
# If you prefer not to use a password file, comment out the line in ansible.cfg:
# vault_password_file = .vault_pass

# Then use --ask-vault-pass with commands:
ansible-playbook playbooks/deploy-stack.yml --ask-vault-pass
```

**⚠️ Security Note**: Never commit `.vault_pass` to git. It's already in `.gitignore`.

### **🛠️ Script Overview**

| Script                 | Purpose                                                             | When to Use                 |
| ---------------------- | ------------------------------------------------------------------- | --------------------------- |
| `bootstrap.sh`         | Install Ansible, collections, initialize project files              | **Once** (first time)       |
| `setup-deploy-keys.sh` | Generate SSH deploy keys for private repositories                   | **After configuring apps**  |
| `encrypt-prod.sh`      | Manual vault encryption (auto-encryption also built into playbooks) | **Manual vault operations** |

**🎯 Pure Ansible Workflow:**

```bash
# All validation and encryption happens automatically inside playbooks
ansible-playbook playbooks/provision-and-configure.yml  # Validates once, then provisions & configures
ansible-playbook playbooks/deploy-stack.yml             # Validates, then deploys
```

**Built-in automation:**

- ✅ Environment variables loaded from `.env`
- ✅ Configuration files validated
- ✅ Vault files auto-encrypted if needed
- ✅ DigitalOcean API tested
- ✅ SSH keys verified
- ✅ No separate preparation scripts needed

## Repository Strategy

This project is designed to work with both public and private repositories:

### **Public Repository (Template)**

- Contains generic templates and examples
- No sensitive data or real configurations
- Safe to share and contribute to
- Use `.example` files for templates

### **Private Fork (Your Deployment)**

- Fork this repository privately
- Contains your encrypted production configurations
- Real environment variables and host details
- Your actual application deployments

### **Recommended Workflow**

1. **Fork this repository** to your private GitHub/GitLab
2. **Clone your private fork** for actual deployments
3. **Keep public repo** as upstream for updates
4. **Use branches** for different environments (staging, production)

```bash
# Set up your private deployment repo
git clone git@github.com:yourusername/your-private-ansible-repo.git
cd your-private-ansible-repo

# Add public repo as upstream for updates
git remote add upstream https://github.com/original/robo-ansible.git

# Initialize your configuration
./scripts/init-project.sh

# Create deployment branch
git checkout -b deployment
git add .
git commit -m "Initialize deployment configuration"
git push origin deployment
```

## Configuration

### Environment Variables (.env file)

The recommended way to configure sensitive settings is using a `.env` file:

```bash
# Copy the example file
cp .env.example .env

# Edit with your settings
nano .env
```

**Example .env file**:

```bash
# DigitalOcean Configuration
DO_API_TOKEN=do_example_token_123456789abcdef  # Replace with your actual token

# SSH Key Names from DigitalOcean (comma-separated)
# Use friendly names like they appear in your DO account
DO_SSH_KEYS=example-mac-key,example-laptop-key

# Server Security
ROOT_PASSWORD=example_secure_password_123  # Replace with your secure password
SERVER_USERNAME=exampleUser  # Must match server_user in group_vars/all.yml

# Optional: Caddy email for Let's Encrypt
CADDY_EMAIL=admin@example.com  # Replace with your actual email
```

**Important Security Notes**:

- ✅ Never use default usernames or passwords
- ✅ Always set unique, secure values for each environment
- ✅ Keep sensitive data out of git
- ✅ Use environment-specific configurations
- ✅ Never hardcode credentials in scripts or templates

### SSH Key Name Lookup

Instead of hunting for SSH key ID numbers, you can use the friendly names from your DigitalOcean account:

```bash
# List all your SSH keys
./scripts/get-ssh-key-ids.sh

# Look up specific keys by name
./scripts/get-ssh-key-ids.sh "example-mac-key,example-laptop-key"

# Partial matching works too
./scripts/get-ssh-key-ids.sh "mac,laptop"
```

The script will show you the exact line to add to your `.env` file.

### Production Configuration (Encrypted)

Production settings are stored in an encrypted file:

```bash
# Edit production configuration
./scripts/encrypt-prod.sh edit

# View current configuration
./scripts/encrypt-prod.sh view

# Encrypt/decrypt manually
./scripts/encrypt-prod.sh encrypt
./scripts/encrypt-prod.sh decrypt
```

## Playbooks

### Main Playbooks

- **`playbooks/provision-and-configure.yml`**: Main playbook that provisions and configures droplets in one go
- **`playbooks/provision-droplet.yml`**: Creates DigitalOcean droplets only
- **`playbooks/configure-server.yml`**: Configures servers with Docker, tmux, etc.
- **`playbooks/deploy-stack.yml`**: Deploys Caddy proxy and applications
- **`playbooks/troubleshoot-apps.yml`**: Docker troubleshooting & management
- **`playbooks/destroy-droplet.yml`**: Safely destroys droplets

### Application Deployment System

This project includes an automated application deployment system using [Caddy Docker Proxy](https://github.com/lucaslorentz/caddy-docker-proxy) for automatic reverse proxy and TLS certificate management.

#### How it works:

1. **Caddy Proxy**: Runs a single Caddy container that watches Docker labels
2. **Automatic TLS**: Issues Let's Encrypt certificates automatically
3. **Git-based Deployment**: Apps are deployed from Git repositories
4. **Zero-config Routing**: Apps just need proper Docker labels
5. **Vault Security**: Production app list is encrypted with ansible-vault

#### Deployment Commands

```bash
# Deploy both proxy and all applications
ansible-playbook playbooks/deploy-stack.yml

# Deploy only the Caddy proxy
ansible-playbook playbooks/deploy-stack.yml --tags caddy_proxy

# Deploy only applications (update apps)
ansible-playbook playbooks/deploy-stack.yml --tags deploy_apps

# Deploy to specific hosts
ansible-playbook playbooks/deploy-stack.yml -l production
```

**Note**: All commands include automatic pre-deployment validation built into the playbooks. Both encrypted files are automatically decrypted:

- `group_vars/prod.yml` (application configurations)
- `inventory/hosts.yml` (server details)

#### Adding New Applications

1. **Edit encrypted configuration**:

   ```bash
   ./scripts/encrypt-prod.sh edit
   ```

2. **Add your app to the list**:

   ```yaml
   apps:
     - name: "my-new-app"
       repo: "https://github.com/myorg/my-app.git"
       branch: "main"
       hostname: "myapp.example.com"
       port: "3000"
   ```

3. **Deploy the new app**:
   ```bash
   ansible-playbook playbooks/deploy-stack.yml --tags deploy_apps
   ```

#### Application Requirements

Each application repository must include a `docker-compose.yml` file with:

1. **Proxy network connection**:

   ```yaml
   networks:
     - proxy
   ```

2. **Caddy labels**:

   ```yaml
   labels:
     caddy: "${CADDY_HOSTNAME:-myapp.example.com}"
     caddy.reverse_proxy: "{{upstreams ${CADDY_PORT:-3000}}}"
   ```

3. **External proxy network**:
   ```yaml
   networks:
     proxy:
       external: true
       name: ${PROXY_NETWORK:-proxy}
   ```

See `templates/docker-compose.example.yml` for a complete example.

### Inventory Management

The inventory system is designed to be secure and maintainable:

1. **Automatic Updates**: When you create new droplets using `provision-droplet.yml`, they are automatically added to `inventory/hosts.yml`
2. **Encrypted Storage**: The inventory file is automatically encrypted with ansible-vault for security
3. **Server User**: Uses the `server_user` from `group_vars/all.yml` instead of root
4. **Manual Management**: You can manually add other servers to the inventory if needed
5. **Group Organization**: Servers are organized into groups:
   - `digitalocean`: Automatically managed droplets
   - `production`: Manually added production servers
   - `staging`: Manually added staging servers

To manually add a server to the inventory:

```bash
# Decrypt the inventory
ansible-vault decrypt inventory/hosts.yml

# Edit the inventory
nano inventory/hosts.yml

# Re-encrypt the inventory
ansible-vault encrypt inventory/hosts.yml
```

Example inventory structure:

```yaml
all:
  children:
    digitalocean:
      hosts:
        # Auto-managed droplets appear here
        my-droplet:
          ansible_host: 1.2.3.4
          ansible_user: exampleUser # Will be set from server_user in all.yml
          droplet_id: 123456789
          droplet_region: nyc1
          droplet_size: s-1vcpu-1gb
          droplet_status: active
    production:
      hosts:
        my-production-server:
          ansible_host: 192.168.1.10
          ansible_user: exampleUser # Will be set from server_user in all.yml
    staging:
      hosts:
        my-staging-server:
          ansible_host: 192.168.1.20
          ansible_user: exampleUser # Will be set from server_user in all.yml
```

### Traditional Usage Examples

```bash
# Provision and configure new droplets
ansible-playbook playbooks/provision-and-configure.yml

# Only provision droplets
ansible-playbook playbooks/provision-droplet.yml

# Only configure existing droplets
ansible-playbook playbooks/configure-server.yml

# Deploy applications
ansible-playbook playbooks/deploy-stack.yml

# Destroy droplets
ansible-playbook playbooks/destroy-droplet.yml

# View inventory
ansible-vault view inventory/hosts.yml

# Edit inventory
ansible-vault edit inventory/hosts.yml

# Test connectivity
ansible digitalocean -m ping
```

## SSH Key Management

### 1Password SSH Keys (Recommended)

If you use 1Password to manage SSH keys:

1. **Install 1Password CLI**:

   ```bash
   # macOS
   brew install --cask 1password-cli

   # Ubuntu
   curl -sS https://downloads.1password.com/linux/keys/1password.asc | sudo gpg --dearmor --output /usr/share/keyrings/1password-archive-keyring.gpg
   echo 'deb [arch=amd64 signed-by=/usr/share/keyrings/1password-archive-keyring.gpg] https://downloads.1password.com/linux/debian/amd64 stable main' | sudo tee /etc/apt/sources.list.d/1password.list
   sudo apt update && sudo apt install 1password-cli
   ```

2. **Enable SSH Agent in 1Password**:

   - Open 1Password
   - Go to Settings → Developer
   - Enable "Use the SSH agent"

3. **Configure SSH to use 1Password**:
   Add to `~/.ssh/config`:

   ```
   Host *
     IdentityAgent "~/Library/Group Containers/2BUA8C4S2C.com.1password/t/agent.sock"
   ```

4. **Add SSH key to DigitalOcean**:
   - Export public key from 1Password
   - Add to DigitalOcean account
   - Use the key name in your `.env` file

### Traditional SSH Keys

If you prefer traditional SSH keys, the setup script will detect existing keys or help you generate new ones.

## Server Configuration Details

The automated setup includes:

1. **System Updates**: Updates apt cache and installs required packages
2. **Docker Installation**:
   - Adds Docker GPG key and repository
   - Installs Docker CE and Docker Compose plugin
   - Starts and enables Docker service
3. **User Setup**:
   - Creates non-root user (configured in group_vars/all.yml)
   - Adds user to docker group
   - Sets up SSH key access
4. **Firewall Configuration**:
   - Installs and configures UFW
   - Opens ports 22, 80, 443
   - Enables firewall with deny-by-default policy
5. **Tmux Configuration**:
   - Clones gpakosz tmux configuration
   - Sets up symlinks and local config
6. **Application Deployment** (optional):
   - Sets up Caddy Docker Proxy
   - Creates proxy network
   - Deploys applications from Git repositories

## Troubleshooting

### Common Issues

1. **Environment Variables Not Loading**:

   ```bash
   # Environment variables are automatically loaded by playbooks from .env file
   # If you need to check manually:
   source .env && echo $DO_API_TOKEN

   # Or verify your .env file exists and has correct content:
   cat .env
   ```

2. **Vault Password Issues**:

   ```bash
   # If you get "Decryption failed" errors, check your .vault_pass file
   cat .vault_pass  # Should contain your vault password

   # If file doesn't exist, create it
   echo "your-vault-password" > .vault_pass
   chmod 600 .vault_pass

   # Test vault access
   ansible-vault view inventory/hosts.yml
   ansible-vault view group_vars/prod.yml

   # If you forgot your vault password, you'll need to recreate encrypted files
   # This requires the old password to decrypt first
   ansible-vault decrypt inventory/hosts.yml --ask-vault-pass  # With old password
   ansible-vault decrypt group_vars/prod.yml --ask-vault-pass   # With old password
   # Edit the files, then re-encrypt with new password
   echo "new-vault-password" > .vault_pass
   ansible-vault encrypt inventory/hosts.yml
   ansible-vault encrypt group_vars/prod.yml

   # If you want to change vault password for existing encrypted files
   ansible-vault rekey inventory/hosts.yml
   ansible-vault rekey group_vars/prod.yml
   ```

3. **SSH Connection Issues**:

   ```bash
   # Test SSH connection manually
   ssh root@your-droplet-ip

   # Check if 1Password SSH agent is working
   ssh-add -l

   # For new droplets, always connect as root first
   ansible-playbook playbooks/configure-server.yml
   ```

4. **SSH Key Not Found**:

   - Ensure your SSH key is added to DigitalOcean
   - Use friendly key names in DO_SSH_KEYS
   - Verify 1Password SSH agent is configured correctly

5. **Permission Denied**:

   - Check that your SSH key has the correct permissions
   - Ensure the key is loaded in your SSH agent

6. **Droplet Creation Fails**:

   - Verify your DO_API_TOKEN is correct
   - Check that you have sufficient DigitalOcean credits
   - Ensure the region and size are valid

7. **Application Deployment Issues**:

   - Check that the app repository has a docker-compose.yml
   - Verify Caddy labels are correctly formatted
   - Ensure the proxy network exists
   - **For Docker build issues, see [Docker Build Visibility & Troubleshooting](#docker-build-visibility--troubleshooting)**

8. **Docker Build Issues**:

   ```bash
   # Quick troubleshooting
   ansible-playbook playbooks/troubleshoot-apps.yml

   # Check build logs
   ssh user@your-server
   cat /tmp/myapp_build.log

   # Manual rebuild with full output
   ./scripts/docker-debug.sh myapp rebuild

   # System cleanup
   ./scripts/docker-debug.sh cleanup
   ```

9. **Inventory File Issues**:

   ```bash
   # If inventory seems corrupted or outdated
   ansible-vault decrypt inventory/hosts.yml
   ./scripts/update-inventory.sh --no-encrypt  # Regenerate
   ansible-vault encrypt inventory/hosts.yml

   # View current inventory
   ansible-vault view inventory/hosts.yml

   # Test inventory parsing
   ansible-inventory --list

   # If you get permission errors on .vault_pass
   chmod 600 .vault_pass

   # Test vault password file is working
   echo "Vault file test:" && ansible-vault view inventory/hosts.yml >/dev/null && echo "✅ Working" || echo "❌ Failed"
   ```

### Debug Mode

Run playbooks with verbose output:

```bash
ansible-playbook -vvv playbooks/provision-and-configure.yml
ansible-playbook -vvv playbooks/deploy-stack.yml
```

## Docker Build Visibility & Troubleshooting

### Enhanced Build Output

By default, Docker builds run quietly. For better visibility during builds and deployments:

#### **🔍 Verbose Deployment Mode**

```bash
# Deploy with full Docker build output visible
ansible-playbook playbooks/deploy-stack.yml -e verbose=true

# Rebuild specific apps with full output
ansible-playbook playbooks/troubleshoot-apps.yml
```
