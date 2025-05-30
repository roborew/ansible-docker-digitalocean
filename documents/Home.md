# Ansible DigitalOcean Deployment - Documentation

Welcome to the complete documentation for the Ansible DigitalOcean Deployment system! This wiki provides comprehensive guides for all aspects of the deployment system.

## 🚀 Getting Started

- **[Quick Start Guide](Quick-Start.md)** - Get up and running in minutes
- **[Installation](Installation.md)** - Detailed installation instructions
- **[Configuration](Configuration.md)** - Configure your deployment environment

## 🎯 Deployment System

- **[Capistrano-Style Deployments](Deployment-System.md)** - Zero-downtime deployments, releases, and rollbacks
- **[Environment Management](Environment-Management.md)** - Secure .env file handling with encryption
- **[Private Repositories](Private-Repositories.md)** - Deploy from private GitHub repositories

## 🔧 Advanced Topics

- **[Branch Deployments](Branch-Deployments.md)** - Deploy feature branches for testing
- **[Rollback System](Rollback-System.md)** - Instant rollbacks to previous releases
- **[Monitoring & Logging](Monitoring.md)** - Track deployments and troubleshoot issues

## 🔒 Security & Best Practices

- **[Security Guide](Security.md)** - Security considerations and best practices
- **[Vault Management](Vault-Management.md)** - Encrypt sensitive configuration files

## 🛠️ Troubleshooting

- **[Common Issues](Troubleshooting.md)** - Solutions to common problems
- **[Docker Troubleshooting](Docker-Troubleshooting.md)** - Docker build and runtime issues
- **[SSH Key Management](SSH-Keys.md)** - 1Password and traditional SSH key setup

## 📚 Reference

- **[Architecture Overview](Architecture.md)** - How the system works
- **[File Structure](File-Structure.md)** - Project organization
- **[Playbook Reference](Playbook-Reference.md)** - All available playbooks
- **[Script Reference](Script-Reference.md)** - Helper scripts and utilities

## 🤝 Contributing

- **[Development Setup](Development.md)** - Set up development environment
- **[Contributing Guidelines](Contributing.md)** - How to contribute to the project

---

## Features Overview

This Ansible project automates the provisioning and configuration of DigitalOcean droplets with:

- 🚀 **Automated Droplet Provisioning** - Create DigitalOcean droplets with custom configurations
- 🐳 **Docker Installation** - Automatically installs and configures Docker CE
- 🎯 **Capistrano-Style Deployments** - Zero-downtime deployments with releases, rollbacks, and branch deployments
- 🔄 **Release Management** - Keeps deployment history with instant rollback capability
- 🌿 **Branch Deployments** - Deploy any branch as separate staging environment
- 🌐 **Reverse Proxy** - Caddy Docker Proxy with automatic TLS certificates
- 🔒 **Security Setup** - Configures UFW firewall with specified rules
- 👤 **User Management** - Creates a non-root user with Docker access
- 🔑 **SSH Key Management** - Supports 1Password SSH keys and traditional SSH keys
- 🖥️ **Tmux Configuration** - Sets up tmux with the gpakosz configuration
- 🔐 **Vault Support** - Encrypted configuration for production secrets
- 🌍 **Cross-Platform** - Works on macOS (with Homebrew) and Ubuntu (with pip)

## Quick Links

### Most Common Tasks

- [Deploy to production](Deployment-System.md#main-deployments)
- [Deploy a feature branch](Branch-Deployments.md#feature-branch-testing)
- [Rollback a deployment](Rollback-System.md#emergency-rollback)
- [Add a new app](Configuration.md#adding-new-applications)
- [Troubleshoot build issues](Docker-Troubleshooting.md)

### Emergency Procedures

- [Emergency rollback](Rollback-System.md#emergency-rollback)
- [Docker cleanup](Docker-Troubleshooting.md#cleanup-failed-builds)
- [SSH connection issues](Troubleshooting.md#ssh-connection-issues)
- [Build failure recovery](Docker-Troubleshooting.md#recovery-options)
