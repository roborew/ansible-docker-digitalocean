# Ansible DigitalOcean Deployment

This Ansible project automates the provisioning and configuration of DigitalOcean droplets with Docker, tmux, and security configurations. It includes an advanced application deployment system with automatic reverse proxy and TLS certificate management.

## Features

- 🚀 **Automated Droplet Provisioning**: Create DigitalOcean droplets with custom configurations
- 🐳 **Docker Installation**: Automatically installs and configures Docker CE
- 🔄 **Application Deployment**: Git-based deployment system with automatic updates
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

3. **Deploy** (with automatic validation & encryption):
   ```bash
   ansible-playbook playbooks/provision-and-configure.yml
   ansible-playbook playbooks/deploy-stack.yml
   ```

### **🔄 Returning User Workflow**

```bash
ansible-playbook playbooks/deploy-stack.yml
```

**✨ All playbooks now include automatic pre-deployment validation:**

- Environment variables are loaded from `.env` file
- Configuration files are validated and encrypted automatically
- SSH keys and DigitalOcean API are tested before deployment
- System readiness is verified before any deployment tasks run

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

| Script            | Purpose                                                             | When to Use                 |
| ----------------- | ------------------------------------------------------------------- | --------------------------- |
| `bootstrap.sh`    | Install Ansible, collections, initialize project files              | **Once** (first time)       |
| `encrypt-prod.sh` | Manual vault encryption (auto-encryption also built into playbooks) | **Manual vault operations** |

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

8. **Inventory File Issues**:

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

## File Structure

```
robo-ansible/
├── ansible.cfg                    # Ansible configuration
├── requirements.txt               # Python dependencies
├── README.md                      # This file
├── .env.example                   # Environment variables template
├── group_vars/
│   ├── all.yml                   # Global variables
│   └── prod.yml                  # Production config (encrypted)
├── inventory/
│   ├── hosts.yml                 # Inventory configuration (encrypted)
│   ├── hosts.yml.example        # Inventory template
│   ├── production.yml           # Production hosts template
│   └── backups/                 # Inventory backup directory
├── playbooks/
│   ├── provision-and-configure.yml # Complete server setup
│   ├── provision-droplet.yml     # Droplet provisioning
│   ├── configure-server.yml      # Server configuration
│   ├── deploy-stack.yml          # Application deployment
│   ├── destroy-droplet.yml       # Droplet destruction
│   └── includes/
│       └── validate_environment.yml # Shared validation tasks (auto-imported)
├── roles/
│   ├── caddy_proxy/              # Caddy proxy setup
│   └── deploy_apps/              # Application deployment
├── scripts/
│   ├── bootstrap.sh               # One-time setup (Ansible + project init)
│   ├── encrypt-prod.sh            # Vault management
│   ├── get-ssh-key-ids.sh         # SSH key lookup
│   └── update-inventory.sh        # Inventory management
├── templates/
│   └── docker-compose.example.yml # App template
```

## Security Considerations

- SSH keys are never stored in the repository
- Production configuration is encrypted with ansible-vault
- UFW firewall is configured with deny-by-default
- Only necessary ports are opened (22, 80, 443)
- Non-root user is created for daily operations
- Docker socket access is limited to docker group
- TLS certificates are automatically managed by Caddy

## Example Application Setup

For a complete example, see how to set up the [rekalled](https://github.com/roborew/rekalled) application:

1. **Configure in prod.yml**:

   ```yaml
   apps:
     - name: "rekalled"
       repo: "https://github.com/roborew/rekalled.git"
       branch: "main"
       hostname: "rekalled.com"
       port: "3000"
   ```

2. **App's docker-compose.yml should include**:

   ```yaml
   services:
     app:
       # your app configuration
       networks:
         - proxy
       labels:
         caddy: "${CADDY_HOSTNAME:-rekalled.com}"
         caddy.reverse_proxy: "{{upstreams ${CADDY_PORT:-3000}}}"

   networks:
     proxy:
       external: true
       name: ${PROXY_NETWORK:-proxy}
   ```

3. **Deploy**:
   ```bash
   ansible-playbook playbooks/deploy-stack.yml
   ```

The app will be automatically available at `https://rekalled.com` with a valid TLS certificate!

## Contributing

1. Fork the repository
2. Create a feature branch
3. Make your changes
4. Test with a development droplet
5. Submit a pull request

## License

This project is licensed under the MIT License - see the LICENSE file for details.
