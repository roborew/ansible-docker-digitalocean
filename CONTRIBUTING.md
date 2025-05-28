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
   # Test playbook syntax
   ansible-playbook --syntax-check playbooks/site.yml

   # Test with example inventory
   ansible-inventory --list -i inventory/hosts.yml.example
   ```

2. **Test scripts**:

   ```bash
   # Test initialization
   ./scripts/init-project.sh

   # Test environment setup (with .env configured)
   source scripts/setup-env.sh
   ```

### Integration Testing

- Test with a development DigitalOcean account
- Use small droplet sizes for cost efficiency
- Clean up test resources after testing

## 📝 Pull Request Process

1. **Update documentation** if you're adding features
2. **Test your changes** thoroughly
3. **Follow commit message conventions**:

   ```
   feat: add new deployment role
   fix: resolve inventory update issue
   docs: update README with new examples
   ```

4. **Submit pull request** with:
   - Clear description of changes
   - Testing steps performed
   - Any breaking changes noted

## 🔒 Security Considerations

### For Public Repository

- All example files should use placeholder values
- No real infrastructure details in templates
- Generic hostnames like `example.com`
- Placeholder API tokens like `your_token_here`

### For Private Forks

- Use ansible-vault for sensitive data
- Keep vault passwords secure
- Use separate branches for different environments
- Regular security audits of configurations

## 🌟 Feature Ideas

We welcome contributions in these areas:

- **New Cloud Providers**: AWS, GCP, Azure support
- **Additional Applications**: More example app configurations
- **Monitoring**: Integration with monitoring solutions
- **Backup**: Automated backup strategies
- **CI/CD**: GitHub Actions workflows
- **Documentation**: Tutorials and guides

## 🐛 Bug Reports

When reporting bugs, please include:

- Operating system and version
- Ansible version
- Error messages and logs
- Steps to reproduce
- Expected vs actual behavior

## 💬 Questions and Support

- **Issues**: Use GitHub Issues for bugs and feature requests
- **Discussions**: Use GitHub Discussions for questions
- **Security**: Email security issues privately

## 📄 License

By contributing, you agree that your contributions will be licensed under the same license as the project (MIT License).

## 🙏 Recognition

Contributors will be recognized in the README.md file. Thank you for helping make this project better!
