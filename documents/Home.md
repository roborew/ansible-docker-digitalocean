# Ansible DigitalOcean Deployment - Documentation

Welcome to the complete documentation for the Ansible DigitalOcean Deployment system! This wiki provides comprehensive guides for all aspects of the deployment system.

## 🚀 Getting Started

- **[Quick Start Guide](Quick-Start.md)** - Get up and running in minutes
- **[Configuration Guide](Quick-Start.md#configuration)** - Configure your deployment environment

## 🎯 Deployment System

- **[Capistrano-Style Deployments](Deployment-System.md)** - Zero-downtime deployments, releases, and rollbacks
- **[Environment Management](Environment-Management.md)** - Secure .env file handling with encryption
- **[Private Repositories](Private-Repositories.md)** - Deploy from private GitHub repositories
- **[Maintenance Mode](Maintenance-Mode.md)** - Professional "Under Construction" pages during updates

## 🔧 Advanced Topics

- **[Branch Deployments](Deployment-System.md#branch-deployments)** - Deploy feature branches for testing
- **[Rollback System](Deployment-System.md#rollbacks)** - Instant rollbacks to previous releases

## 🔒 Security & Best Practices

- **[Security Guide](Private-Repositories.md#security-considerations)** - Security considerations and best practices
- **[Vault Management](Environment-Management.md#encryption)** - Encrypt sensitive configuration files

## 🛠️ Troubleshooting

- **[Common Issues](Quick-Start.md#troubleshooting)** - Solutions to common problems
- **[Docker Troubleshooting](Deployment-System.md#docker-troubleshooting)** - Docker build and runtime issues
- **[SSH Key Management](Private-Repositories.md)** - 1Password and traditional SSH key setup

## 📚 Reference

- **[Architecture Overview](Deployment-System.md#architecture)** - How the system works
- **[File Structure](Deployment-System.md#file-structure)** - Project organization
- **[Playbook Reference](Deployment-System.md#playbooks)** - All available playbooks
- **[Script Reference](Deployment-System.md#scripts)** - Helper scripts and utilities

## 🤝 Contributing

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
- 🚧 **Maintenance Mode** - Professional "Under Construction" pages during updates and deployments
- 🔒 **Security Setup** - Configures UFW firewall with specified rules
- 👤 **User Management** - Creates a non-root user with Docker access
- 🔑 **SSH Key Management** - Supports 1Password SSH keys and traditional SSH keys
- 🖥️ **Tmux Configuration** - Sets up tmux with the gpakosz configuration
- 🔐 **Vault Support** - Encrypted configuration for production secrets
- 🌍 **Cross-Platform** - Works on macOS (with Homebrew) and Ubuntu (with pip)

## 🚀 Quick Links

**First Time Setup:**

- [📦 Quick Start Guide](Quick-Start.md) - Get up and running in 15 minutes
- [⚙️ Configuration](Configuration.md) - Configure your apps and servers
- [🔑 SSH Key Management](SSH-Keys.md) - Setup 1Password or traditional SSH keys

**Daily Operations:**

- [🚀 Deploy Applications](Deployment-System.md#deployment-commands) - Deploy main or feature branches
- [🤖 Auto-Deployment](Auto-Deployment.md) - Setup automatic deployments
- [🔄 Rollback System](Rollback-System.md) - Emergency rollbacks
- [🚧 Maintenance Mode](Maintenance-Mode.md) - Put sites in maintenance mode
- [💾 Database Management](Database-Management.md) - Backups and restores

## 📚 Documentation

### Getting Started

- **[Quick Start Guide](Quick-Start.md)** - Get up and running in 15 minutes
- **[Environment Management](Environment-Management.md)** - Manage environment variables and secrets

### Core Features

- **[Capistrano-Style Deployments](Deployment-System.md)** - Zero-downtime deployments with release management
- **[Branch Deployments](Branch-Deployments.md)** - Deploy feature branches for testing
- **[Auto-Deployment](Auto-Deployment.md)** - Automatic deployments when pushing to configured branches
- **[Rollback System](Rollback-System.md)** - Instant rollbacks to any previous release
- **[Database Management](Database-Management.md)** - Automatic backups and restore
- **[Environment Management](Environment-Management.md)** - Secure .env file handling with encryption
- **[Maintenance Mode](Maintenance-Mode.md)** - Professional "Under Construction" pages
- **[Private Repositories](Private-Repositories.md)** - Deploy from private GitHub repos with SSH keys

### Advanced Topics

- **[Contributing](Contributing.md)** - How to contribute to the project
