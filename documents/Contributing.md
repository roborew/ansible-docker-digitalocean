# Contributing Guidelines

Thank you for your interest in contributing to the Ansible DigitalOcean Deployment project! This guide will help you get started with contributing.

## 🤝 How to Contribute

### 1. Fork the Repository

```bash
# Fork this repository to your GitHub account
# Then clone your fork
git clone git@github.com:yourusername/robo-ansible.git
cd robo-ansible

# Add upstream remote
git remote add upstream https://github.com/roborew/robo-ansible.git
```

### 2. Set Up Development Environment

```bash
# Run bootstrap to set up development environment
./scripts/bootstrap.sh

# Copy example configurations
cp .env.example .env
# Edit .env with test/development values

# Set up test vault password
echo "test-password-123" > .vault_pass
```

### 3. Create Feature Branch

```bash
# Create and checkout a new branch
git checkout -b feature/your-feature-name

# Make your changes
# ... edit files ...

# Test your changes
./scripts/test-changes.sh  # If available
```

### 4. Submit Pull Request

```bash
# Commit your changes
git add .
git commit -m "Add feature: description of your changes"

# Push to your fork
git push origin feature/your-feature-name

# Create pull request on GitHub
```

## 📝 Development Guidelines

### Code Style

- **Ansible YAML**: Follow standard YAML formatting (2 spaces, no tabs)
- **Shell Scripts**: Use bash with error handling (`set -e`)
- **Documentation**: Update documentation for any new features
- **Comments**: Comment complex logic and non-obvious decisions

### Ansible Best Practices

```yaml
# Use descriptive task names
- name: "Install Docker CE and configure daemon"
  apt:
    name: docker-ce
    state: present

# Always use when conditions for clarity
- name: "Create application directories"
  file:
    path: "/opt/{{ app.name }}"
    state: directory
  when: app.name is defined

# Use proper variable scoping
vars:
  app_name: "{{ app.name | default('unknown') }}"
```

### Documentation Standards

- **Wiki-style**: All detailed docs go in `documents/` folder
- **Clear headings**: Use consistent emoji and heading structure
- **Code examples**: Include working code examples
- **Cross-references**: Link to related documentation pages

## 🧪 Testing

### Local Testing

```bash
# Test with a development droplet
cp .env.example .env.dev
# Edit .env.dev with test credentials

# Test provisioning
ansible-playbook playbooks/provision-droplet.yml -e @.env.dev

# Test deployment
ansible-playbook playbooks/deploy-stack.yml -e @.env.dev

# Clean up test resources
ansible-playbook playbooks/destroy-droplet.yml -e @.env.dev
```

### Validation Checklist

Before submitting a PR, ensure:

- [ ] All playbooks run without errors
- [ ] Documentation is updated
- [ ] No sensitive data in commits
- [ ] Vault files are properly encrypted
- [ ] Scripts have proper permissions
- [ ] Code follows established patterns

## 📂 Project Structure

Understanding the project structure helps with contributions:

```
robo-ansible/
├── ansible.cfg              # Ansible configuration
├── .env.example             # Environment template
├── playbooks/               # Main playbooks
│   ├── provision-*.yml      # Server provisioning
│   ├── configure-*.yml      # Server configuration
│   ├── deploy-*.yml         # Application deployment
│   └── manage-*.yml         # Management tasks
├── roles/                   # Ansible roles
│   ├── caddy_proxy/         # Reverse proxy setup
│   ├── deploy_apps/         # Application deployment
│   └── deploy_ssh_keys/     # SSH key management
├── scripts/                 # Helper scripts
├── templates/               # Configuration templates
├── group_vars/              # Variable files
├── inventory/               # Server inventories
├── documents/               # Wiki documentation
└── files/                   # Static files and keys
```

## 🎯 Contribution Areas

### High Priority

- **Improved error handling** - Better error messages and recovery
- **Additional cloud providers** - Support for AWS, GCP, etc.
- **Database management** - Automated database backups and migrations
- **Monitoring integration** - Prometheus, Grafana, or similar
- **CI/CD integration** - GitHub Actions, GitLab CI templates

### Medium Priority

- **Additional deployment strategies** - Blue-green, canary deployments
- **Container registry support** - Private Docker registries
- **Load balancing** - Multi-server deployments
- **Security hardening** - Additional security measures
- **Performance optimization** - Faster deployments, caching

### Documentation

- **Video tutorials** - Walkthrough videos for complex setups
- **Use case examples** - Real-world deployment examples
- **Troubleshooting guides** - Common issues and solutions
- **Architecture diagrams** - Visual system documentation
- **Best practices** - Production deployment guidelines

## 🐛 Bug Reports

### Before Reporting

1. **Check existing issues** - Search for similar issues
2. **Test with clean environment** - Reproduce with fresh setup
3. **Check documentation** - Ensure it's not a configuration issue

### Bug Report Format

```markdown
## Bug Description

Brief description of the issue

## Environment

- OS: macOS/Ubuntu/etc
- Ansible version: X.X.X
- Python version: X.X.X

## Steps to Reproduce

1. Step one
2. Step two
3. Step three

## Expected Behavior

What should happen

## Actual Behavior

What actually happens

## Logs/Output
```

Paste relevant error messages or logs

```

## Additional Context
Any other relevant information
```

## 🚀 Feature Requests

### Feature Request Format

```markdown
## Feature Description

Clear description of the proposed feature

## Use Case

Why is this feature needed? What problem does it solve?

## Proposed Implementation

How should this feature work?

## Alternatives Considered

Other approaches that were considered

## Additional Context

Any other relevant information
```

## 📋 Release Process

### Version Management

- **Semantic versioning** - MAJOR.MINOR.PATCH
- **Git tags** - Tag releases with version numbers
- **Changelog** - Update CHANGELOG.md with each release

### Release Checklist

- [ ] All tests pass
- [ ] Documentation updated
- [ ] Version bumped
- [ ] Changelog updated
- [ ] Git tag created
- [ ] Release notes written

## 💬 Community

### Communication Channels

- **GitHub Issues** - Bug reports and feature requests
- **GitHub Discussions** - General questions and community chat
- **Pull Requests** - Code contributions and reviews

### Code of Conduct

- **Be respectful** - Treat all community members with respect
- **Be constructive** - Provide helpful feedback and suggestions
- **Be patient** - Remember that maintainers are volunteers
- **Be inclusive** - Welcome newcomers and different perspectives

## 🙏 Recognition

Contributors will be recognized in:

- **README credits** - Listed in the main README
- **Release notes** - Mentioned in release announcements
- **GitHub contributors** - Shown in repository statistics

Thank you for contributing to make this project better for everyone! 🎉
