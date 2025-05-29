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

3. **Initialize for testing** (optional):

   ```bash
   ./scripts/init-project.sh
   ```

4. **Create a feature branch**:
   ```bash
   git checkout -b feature/your-feature-name
   ```

## 📋 Development Guidelines

### Code Standards

- **Shell Scripts**: Use `#!/bin/bash` and `set -e`
- **Ansible**: Follow Ansible best practices and use YAML formatting
- **Documentation**: Update README.md for any new features
- **Security**: Never commit real credentials or sensitive data

### File Structure

```
robo-ansible/
├── .env.example              # Template for environment variables
├── group_vars/
│   ├── all.yml              # Global configuration
│   └── prod.yml.example     # Template for production config
├── inventory/
│   ├── hosts.yml.example    # Template for inventory
│   └── production.yml       # Template for production hosts
├── roles/                   # Ansible roles
├── playbooks/              # Ansible playbooks
├── scripts/                # Helper scripts
└── templates/              # Application templates
```

### What to Include

✅ **Safe to commit:**

- Template files (`.example` suffix)
- Generic configurations
- Documentation
- Scripts and playbooks
- Role definitions

❌ **Never commit:**

- Real environment variables (`.env`)
- Unencrypted production configs
- SSH keys or certificates
- Real IP addresses or hostnames
- API tokens or passwords

## 🧪 Testing

### Local Testing

1. **Test with example configurations**:

   ```bash
   # Check playbook syntax
   ansible-playbook --syntax-check playbooks/provision-and-configure.yml

   # Test with example inventory
   ansible-inventory --list -i inventory/hosts.yml.example
   ```
