# Environment File Management

Environment files are managed securely with encryption and proper deployment across your applications.

## 📍 Environment File Locations

| Location                              | Purpose                   | Security       |
| ------------------------------------- | ------------------------- | -------------- |
| `env_files/myapp.env`                 | Local editing (temporary) | ⚠️ Unencrypted |
| `env_files/myapp.env.vault`           | Local storage             | ✅ Encrypted   |
| `/opt/myapp/shared/config/.env.vault` | Server storage            | ✅ Encrypted   |
| `/opt/myapp/shared/config/.env`       | Server runtime            | ⚠️ Decrypted   |
| `/opt/myapp/current/.env`             | Application access        | 🔗 Symlink     |

## 🔧 Environment Management Commands

### Create New Environment File

```bash
# Create new .env template for an app
ansible-playbook playbooks/manage-env.yml -e action=create -e app_name=myapp
```

This creates a template with common environment variables based on your app configuration.

### Edit Environment Files

```bash
# Edit .env file locally (quick helper script)
./scripts/manage-env.sh edit myapp
```

This script:

- Decrypts the vault file if it exists
- Opens the file in your editor
- Provides instructions for encrypting when done

### Encrypt Environment Files

```bash
# Encrypt .env file for security
ansible-playbook playbooks/manage-env.yml -e action=encrypt -e app_name=myapp
```

### Deploy Environment Files

```bash
# Deploy encrypted .env to server
ansible-playbook playbooks/manage-env.yml -e action=deploy -e app_name=myapp

# Deploy all environment files
ansible-playbook playbooks/manage-env.yml -e action=deploy
```

### List Managed Files

```bash
# List all managed .env files
ansible-playbook playbooks/manage-env.yml -e action=list
```

### Get Help

```bash
# Display available actions and usage
ansible-playbook playbooks/manage-env.yml
```

## 🔄 Environment Workflow

### 1. Create Template

```bash
ansible-playbook playbooks/manage-env.yml -e action=create -e app_name=myapp
```

### 2. Edit Values

```bash
./scripts/manage-env.sh edit myapp
```

### 3. Encrypt for Security

```bash
ansible-playbook playbooks/manage-env.yml -e action=encrypt -e app_name=myapp
```

### 4. Deploy to Server

```bash
ansible-playbook playbooks/manage-env.yml -e action=deploy -e app_name=myapp
```

### 5. Verify Deployment

```bash
ansible digitalocean -m shell -a "ls -la /opt/myapp/shared/config/"
```

## 🔒 Security Features

### Local Security

- **Unencrypted files are temporary** - Only exist during editing
- **Vault encryption** - All stored files are encrypted with ansible-vault
- **Git protection** - Unencrypted files are gitignored

### Server Security

- **Encrypted storage** - Files stored encrypted on server
- **Runtime decryption** - Decrypted only when needed for deployment
- **Secure permissions** - Files have proper ownership (600 permissions)
- **Automatic cleanup** - Temporary decrypted files are cleaned up

### Network Security

- **SSH transfer** - Files transferred securely via SSH
- **No plain text transmission** - Files are encrypted during transfer
- **Local decryption** - Decryption happens locally, then transferred securely

## 📝 Environment File Templates

When you create a new environment file, it includes common variables:

```bash
# Application Configuration
CADDY_HOSTNAME=myapp.yourdomain.com
CADDY_PORT=3000
PROXY_NETWORK=proxy

# Database (if applicable)
DATABASE_URL=postgresql://user:pass@host:5432/dbname
REDIS_URL=redis://localhost:6379/0

# External Services
API_KEY=your_api_key_here
SECRET_KEY=your_secret_key_here

# Application Settings
NODE_ENV=production
DEBUG=false
LOG_LEVEL=info
```

## 🛠️ Troubleshooting

### File Not Found

```bash
# Check if environment file exists
ls -la env_files/myapp.env*

# Create if missing
ansible-playbook playbooks/manage-env.yml -e action=create -e app_name=myapp
```

### Encryption Issues

```bash
# Check vault password
ansible-vault view env_files/myapp.env.vault

# Re-encrypt if needed
ansible-playbook playbooks/manage-env.yml -e action=encrypt -e app_name=myapp
```

### Deployment Issues

```bash
# Check server file status
ansible digitalocean -m shell -a "ls -la /opt/myapp/shared/config/"

# Redeploy environment file
ansible-playbook playbooks/manage-env.yml -e action=deploy -e app_name=myapp
```

### Permission Issues

```bash
# Fix file permissions on server
ansible digitalocean -m shell -a "chmod 600 /opt/myapp/shared/config/.env*"
ansible digitalocean -m shell -a "chown $(whoami):$(whoami) /opt/myapp/shared/config/.env*"
```

## 🔗 Related Documentation

- **[Quick Start Guide](Quick-Start.md)** - Initial environment setup
- **[Deployment System](Deployment-System.md)** - How environment files are used
- **[Vault Management](Vault-Management.md)** - Vault encryption details
- **[Security Guide](Security.md)** - Security best practices
- **[Troubleshooting](Troubleshooting.md)** - Common issues and solutions

## 💡 Best Practices

1. **Always encrypt** - Never commit unencrypted environment files
2. **Use descriptive names** - Name files clearly (e.g., `myapp-production.env`)
3. **Regular rotation** - Rotate secrets regularly
4. **Minimal permissions** - Only include necessary environment variables
5. **Documentation** - Document what each variable does
6. **Backup encrypted files** - Keep backups of your encrypted vault files
