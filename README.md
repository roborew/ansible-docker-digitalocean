# Ansible DigitalOcean Deployment

This Ansible project automates the provisioning and configuration of DigitalOcean droplets with Docker, tmux, and security configurations. It replicates your manual server setup process in an automated, repeatable way.

## Features

- 🚀 **Automated Droplet Provisioning**: Create DigitalOcean droplets with custom configurations
- 🐳 **Docker Installation**: Automatically installs and configures Docker CE
- 🖥️ **Tmux Configuration**: Sets up tmux with the gpakosz configuration
- 🔒 **Security Setup**: Configures UFW firewall with specified rules
- 👤 **User Management**: Creates a non-root user with Docker access
- 🔑 **SSH Key Management**: Supports 1Password SSH keys and traditional SSH keys
- 🌍 **Cross-Platform**: Works on macOS (with Homebrew) and Ubuntu (with pip)

## Prerequisites

### Required

- DigitalOcean account with API token
- SSH key (either in 1Password or traditional ~/.ssh/ keys)

### Platform-Specific

- **macOS**: Homebrew (for Ansible installation)
- **Ubuntu**: Python 3 and pip3 (for Ansible installation)

## Quick Start

1. **Clone and setup**:

   ```bash
   git clone <your-repo>
   cd robo-ansible
   chmod +x scripts/setup.sh
   ./scripts/setup.sh
   ```

2. **Configure DigitalOcean**:

   ```bash
   export DO_API_TOKEN="your_digitalocean_api_token"
   ```

3. **Update configuration** (edit `group_vars/all.yml`):

   - Add your SSH key IDs from DigitalOcean
   - Adjust droplet size, region, and other preferences

4. **Deploy**:
   ```bash
   ansible-playbook playbooks/site.yml
   ```

## Configuration

### DigitalOcean Settings (`group_vars/all.yml`)

```yaml
# DigitalOcean Configuration
do_region: "nyc3" # Change to your preferred region
do_size: "s-1vcpu-1gb" # Change to your preferred size
do_image: "ubuntu-22-04-x64"
do_ssh_keys: [] # Add your SSH key IDs here
```

To get your SSH key IDs:

1. Go to [DigitalOcean SSH Keys](https://cloud.digitalocean.com/account/security)
2. Add your public key if not already added
3. Note the key ID (visible in the URL or API)

### Server Configuration

```yaml
server_user: "robodeploy" # Non-root user to create
server_packages: # Additional packages to install
  - apt-transport-https
  - ca-certificates
  - curl
  - software-properties-common
  - tmux
  - git
  - nano

ufw_rules: # Firewall rules
  - { port: "80", proto: "tcp" }
  - { port: "443", proto: "tcp" }
  - { port: "22", proto: "tcp" }
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
   - Note the key ID for `group_vars/all.yml`

### Traditional SSH Keys

If you prefer traditional SSH keys, the setup script will detect existing keys or help you generate new ones.

## Playbooks

### Main Playbooks

- **`playbooks/site.yml`**: Main playbook that runs provisioning and configuration
- **`playbooks/provision-droplet.yml`**: Creates DigitalOcean droplets
- **`playbooks/configure-server.yml`**: Configures servers with Docker, tmux, etc.
- **`playbooks/destroy-droplet.yml`**: Safely destroys droplets

### Usage Examples

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

## Server Configuration Details

The automated setup replicates your manual process:

1. **System Updates**: Updates apt cache and installs required packages
2. **Docker Installation**:
   - Adds Docker GPG key
   - Adds Docker repository
   - Installs Docker CE
   - Starts and enables Docker service
3. **User Setup**:
   - Creates `robodeploy` user
   - Adds user to docker group
   - Sets up SSH key access
4. **Firewall Configuration**:
   - Installs and configures UFW
   - Opens ports 22, 80, 443
   - Enables firewall with deny-by-default policy
5. **Tmux Configuration**:
   - Clones gpakosz tmux configuration
   - Sets up symlinks and local config
   - Configures for the server user

## Troubleshooting

### Common Issues

1. **SSH Key Not Found**:

   - Ensure your SSH key is added to DigitalOcean
   - Check that the key ID is in `group_vars/all.yml`
   - Verify 1Password SSH agent is configured correctly

2. **Permission Denied**:

   - Check that your SSH key has the correct permissions
   - Ensure the key is loaded in your SSH agent

3. **Droplet Creation Fails**:

   - Verify your DO_API_TOKEN is correct
   - Check that you have sufficient DigitalOcean credits
   - Ensure the region and size are valid

4. **Ansible Not Found**:
   - Run the setup script: `./scripts/setup.sh`
   - Manually install Ansible for your platform

### Debug Mode

Run playbooks with verbose output:

```bash
ansible-playbook -vvv playbooks/site.yml
```

## File Structure

```
robo-ansible/
├── ansible.cfg                 # Ansible configuration
├── requirements.txt            # Python dependencies
├── README.md                   # This file
├── group_vars/
│   └── all.yml                # Global variables
├── inventory/
│   └── hosts.yml              # Inventory configuration
├── playbooks/
│   ├── site.yml               # Main playbook
│   ├── provision-droplet.yml  # Droplet provisioning
│   ├── configure-server.yml   # Server configuration
│   └── destroy-droplet.yml    # Droplet destruction
└── scripts/
    └── setup.sh               # Environment setup script
```

## Security Considerations

- SSH keys are never stored in the repository
- UFW firewall is configured with deny-by-default
- Only necessary ports are opened
- Non-root user is created for daily operations
- SSH host key checking is disabled only for initial setup

## Contributing

1. Fork the repository
2. Create a feature branch
3. Make your changes
4. Test with a development droplet
5. Submit a pull request

## License

This project is licensed under the MIT License - see the LICENSE file for details.
