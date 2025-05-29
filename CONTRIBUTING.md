# Contributing to Ansible DigitalOcean Deployment

Thank you for your interest in contributing! This project provides a complete infrastructure-as-code solution for DigitalOcean deployments with automatic application deployment.

## 🚀 Getting Started

### For Contributors

1. **Fork the repository** to your GitHub account
2. **Clone your fork** locally:

   ```bash
   git clone git@github.com:yourusername/robo-ansible.git
   cd robo-ansible
   ```

3. **Bootstrap the project**:

   ```bash
   ./scripts/bootstrap.sh
   ```

4. **Create a feature branch**:
   ```bash
   git checkout -b feature/your-feature-name
   ```

## 📋 Development Guidelines

### Code Standards

- **Shell Scripts**:

  - Use `#!/bin/bash` and `set -e`
  - Include color-coded output for better UX
  - Add clear error messages and status indicators
  - Use consistent backup management
  - Never hardcode credentials or environment-specific values

- **Ansible**:

  - Follow Ansible best practices
  - Use YAML formatting
  - Encrypt sensitive data with ansible-vault
  - Use variables from group_vars/all.yml for consistency

- **Documentation**:

  - Update README.md for any new features
  - Include clear examples using generic values
  - Document security considerations
  - Keep CONTRIBUTING.md up to date

- **Security**:
  - Never commit real credentials or sensitive data
  - Use example values in templates (e.g., exampleUser, example.com)
  - Encrypt all production configurations
  - Maintain proper backup rotation
  - Validate environment variables

### File Structure

```
robo-ansible/
├── .env.example              # Template for environment variables
├── group_vars/
│   ├── all.yml              # Global configuration
│   └── prod.yml.example     # Template for production config
├── inventory/
│   ├── hosts.yml.example    # Template for inventory
│   ├── production.yml       # Template for production hosts
│   └── backups/             # Inventory backup directory
├── roles/                   # Ansible roles
├── playbooks/              # Ansible playbooks
├── scripts/                # Helper scripts
└── templates/              # Application templates
```

### Script Overview

| Script                | Purpose                      | Security Notes                        |
| --------------------- | ---------------------------- | ------------------------------------- |
| `bootstrap.sh`        | Initial project setup        | No hardcoded values                   |
| `update-inventory.sh` | Manages droplet inventory    | Encrypts inventory, maintains backups |
| `get-ssh-key-ids.sh`  | SSH key management           | Uses example values in docs           |
| `encrypt-prod.sh`     | Production config encryption | Manages vault operations              |

**Note**: Environment validation is now built into all playbooks automatically.

### What to Include

✅ **Safe to commit:**

- Template files (`.example` suffix)
- Generic configurations
- Documentation with example values
- Scripts and playbooks
- Role definitions
- Backup management code
- Example inventory files

❌ **Never commit:**

- Real environment variables (`.env`)
- Unencrypted production configs
- SSH keys or certificates
- Real IP addresses or hostnames
- API tokens or passwords
- Hardcoded usernames or credentials
- Real backup files

### Backup Management

- Backups are stored in `inventory/backups/`
- Maintains last 5 backups by default
- Uses timestamp format: `hosts.yml.backup.YYYYMMDD_HHMMSS`
- Automatically rotates old backups
- Never commit backup files to repository

## 🧪 Testing

### Local Testing

1. **Test with example configurations**:

   ```bash
   # Check playbook syntax
   ansible-playbook --syntax-check playbooks/provision-and-configure.yml

   # Test with example inventory
   ansible-inventory --list -i inventory/hosts.yml.example

   # Verify backup management
   ./scripts/update-inventory.sh --no-encrypt
   ls -l inventory/backups/
   ```

2. **Security Testing**:

   ```bash
   # Verify no hardcoded credentials
   grep -r "exampleUser\|example.com" --include="*.sh" --include="*.yml" .

   # Check for proper encryption
   ansible-vault view inventory/hosts.yml

   # Test built-in validation (runs automatically in playbooks)
   ansible-playbook --check playbooks/provision-and-configure.yml
   ```

### Pull Request Guidelines

1. **Before submitting**:

   - Run all tests
   - Update documentation
   - Check for hardcoded values
   - Verify backup functionality
   - Ensure proper encryption

2. **In your PR**:

   - Describe the changes
   - Reference any issues
   - Include testing steps
   - Note security implications
   - Update relevant documentation

3. **Security checklist**:
   - [ ] No hardcoded credentials
   - [ ] Proper use of example values
   - [ ] Encryption for sensitive data
   - [ ] Backup management included
   - [ ] Environment variable validation
   - [ ] Updated documentation
