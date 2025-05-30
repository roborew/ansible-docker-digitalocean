# Ansible DigitalOcean Deployment - Documentation

Welcome to the complete documentation for the Ansible DigitalOcean Deployment system! This wiki provides comprehensive guides for all aspects of the deployment system.

## 🚀 Getting Started

- **[Quick Start Guide](Quick-Start.md)** - Get up and running in minutes
- **[Configuration Guide](Quick-Start.md#configuration)** - Configure your deployment environment

## 🎯 Deployment System

- **[Capistrano-Style Deployments](Deployment-System.md)** - Zero-downtime deployments, releases, and rollbacks
- **[Environment Management](Environment-Management.md)** - Secure .env file handling with encryption
- **[Private Repositories](Private-Repositories.md)** - Deploy from private GitHub repositories

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
- 🔒 **Security Setup** - Configures UFW firewall with specified rules
- 👤 **User Management** - Creates a non-root user with Docker access
- 🔑 **SSH Key Management** - Supports 1Password SSH keys and traditional SSH keys
- 🖥️ **Tmux Configuration** - Sets up tmux with the gpakosz configuration
- 🔐 **Vault Support** - Encrypted configuration for production secrets
- 🌍 **Cross-Platform** - Works on macOS (with Homebrew) and Ubuntu (with pip)

## Quick Links

### Most Common Tasks

- [Deploy to production](Deployment-System.md#deployments)
- [Deploy a feature branch](Deployment-System.md#branch-deployments)
- [Rollback a deployment](Deployment-System.md#rollbacks)
- [Add a new app](Quick-Start.md#adding-applications)
- [Troubleshoot build issues](Deployment-System.md#docker-troubleshooting)

### Emergency Procedures

- [Emergency rollback](Deployment-System.md#emergency-rollback)
- [Docker cleanup](Deployment-System.md#docker-troubleshooting)
- [SSH connection issues](Quick-Start.md#troubleshooting)
- [Build failure recovery](Deployment-System.md#docker-troubleshooting)
