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

## Quick Start

### **🚀 New User Setup**

1. **Bootstrap** (one-time setup):

   ```bash
   git clone <this-repo>
   cd robo-ansible
   ./scripts/bootstrap.sh
   ```

2. **Configure** (edit your settings):

   ```bash
   nano .env                    # Add DigitalOcean API token & SSH keys
   nano group_vars/prod.yml     # Add your applications
   ./scripts/encrypt-prod.sh encrypt  # Encrypt production config
   ```

3. **Prepare** (load environment & validate):

   ```bash
   source scripts/prepare.sh
   ```

4. **Deploy**:
   ```bash
   ansible-playbook playbooks/site.yml              # Provision & configure
   ansible-playbook playbooks/deploy-stack.yml      # Deploy applications
   ```

### **🔄 Returning User Workflow**

```bash
source scripts/prepare.sh                          # Load environment & validate
ansible-playbook playbooks/deploy-stack.yml        # Deploy applications
```

### **🛠️ Script Overview**

| Script            | Purpose                                                   | When to Use           |
| ----------------- | --------------------------------------------------------- | --------------------- |
| `bootstrap.sh`    | Install Ansible, collections, initialize project files    | **Once** (first time) |
| `prepare.sh`      | Load environment variables + validate everything is ready | **Every deployment**  |
| `encrypt-prod.sh` | Manage vault encryption for production config             | When editing prod.yml |

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
DO_API_TOKEN=your_digitalocean_api_token_here

# SSH Key Names from DigitalOcean (comma-separated)
# Use friendly names like they appear in your DO account
DO_SSH_KEYS=mac-mini-pub-key,mac-book-pro-pub

# Server Security
ROOT_PASSWORD=your_secure_root_password
SERVER_USERNAME=robodeploy

# Optional: Caddy email for Let's Encrypt
CADDY_EMAIL=admin@yourdomain.com
```

**Benefits of using .env**:

- ✅ Keeps sensitive data out of git
- ✅ Easy to manage different environments
- ✅ Automatically loaded by setup script
- ✅ Use friendly SSH key names instead of cryptic IDs

### SSH Key Name Lookup

Instead of hunting for SSH key ID numbers, you can use the friendly names from your DigitalOcean account:

```bash
# List all your SSH keys
./scripts/get-ssh-key-ids.sh

# Look up specific keys by name
./scripts/get-ssh-key-ids.sh "mac-mini-pub-key,mac-book-pro-pub"

# Partial matching works too
./scripts/get-ssh-key-ids.sh "mini,book"
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

- **`playbooks/site.yml`**: Complete server provisioning and configuration
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
ansible-playbook playbooks/deploy-stack.yml --ask-vault-pass

# Deploy only the Caddy proxy
ansible-playbook playbooks/deploy-stack.yml --tags caddy_proxy

# Deploy only applications (update apps)
ansible-playbook playbooks/deploy-stack.yml --tags deploy_apps --ask-vault-pass

# Deploy to specific hosts
ansible-playbook playbooks/deploy-stack.yml -l production --ask-vault-pass
```

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
   ansible-playbook playbooks/deploy-stack.yml --tags deploy_apps --ask-vault-pass
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

### Traditional Usage Examples

```bash
# Provision and configure new droplets
ansible-playbook playbooks/site.yml

# Only provision droplets
ansible-playbook playbooks/provision-droplet.yml

# Only configure existing droplets
ansible-playbook playbooks/configure-server.yml

# Destroy droplets
ansible-playbook playbooks/destroy-droplet.yml
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
   - Creates non-root user (robodeploy by default)
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
   # Use the prepare script to load and validate environment
   source scripts/prepare.sh

   # Check if variables are set
   echo $DO_API_TOKEN
   ```

2. **SSH Key Not Found**:

   - Ensure your SSH key is added to DigitalOcean
   - Use friendly key names in DO_SSH_KEYS
   - Verify 1Password SSH agent is configured correctly

3. **Permission Denied**:

   - Check that your SSH key has the correct permissions
   - Ensure the key is loaded in your SSH agent

4. **Droplet Creation Fails**:

   - Verify your DO_API_TOKEN is correct
   - Check that you have sufficient DigitalOcean credits
   - Ensure the region and size are valid

5. **Application Deployment Issues**:

   - Check that the app repository has a docker-compose.yml
   - Verify Caddy labels are correctly formatted
   - Ensure the proxy network exists

6. **Vault Password Issues**:

   ```bash
   # Create a vault password file (optional)
   echo "your-vault-password" > .vault_pass
   chmod 600 .vault_pass

   # Use in ansible.cfg
   vault_password_file = .vault_pass
   ```

### Debug Mode

Run playbooks with verbose output:

```bash
ansible-playbook -vvv playbooks/site.yml
ansible-playbook -vvv playbooks/deploy-stack.yml --ask-vault-pass
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
│   └── hosts.yml                 # Inventory configuration
├── playbooks/
│   ├── site.yml                  # Complete server setup
│   ├── provision-droplet.yml     # Droplet provisioning
│   ├── configure-server.yml      # Server configuration
│   ├── deploy-stack.yml          # Application deployment
│   └── destroy-droplet.yml       # Droplet destruction
├── roles/
│   ├── caddy_proxy/              # Caddy proxy setup
│   └── deploy_apps/              # Application deployment
├── scripts/
│   ├── bootstrap.sh               # One-time setup (Ansible + project init)
│   ├── prepare.sh                 # Load environment + validation
│   ├── encrypt-prod.sh            # Vault management
│   ├── get-ssh-key-ids.sh         # SSH key lookup
│   └── manage-inventory.sh        # Inventory management
└── templates/
    └── docker-compose.example.yml # App template
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
   ansible-playbook playbooks/deploy-stack.yml --ask-vault-pass
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
