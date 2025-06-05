# Capistrano-Style Deployment System

This project includes a complete **Capistrano-style deployment system** that provides zero-downtime deployments, release management, rollbacks, and branch deployments for your applications.

## 📁 Directory Structure

Each application is deployed using the following Capistrano-style structure:

```
/opt/your-app/
├── current -> releases/1640995200/     # Symlink to active release
├── releases/                           # All deployments (keeps last 5)
│   ├── 1640995200/                    # Release 1 (timestamp-based)
│   ├── 1640995300/                    # Release 2
│   └── 1640995400/                    # Release 3 (current)
├── shared/                            # Persistent files across deployments
│   ├── config/
│   │   ├── .env                       # Environment variables (decrypted)
│   │   └── .env.vault                 # Environment variables (encrypted)
│   ├── logs/                          # Deployment and application logs
│   │   ├── build_1640995400.log       # Build log for each release
│   │   └── deploy_1640995400.log      # Deploy log for each release
│   └── data/                          # Persistent application data
├── repo/                              # Git repository cache
└── backups/                           # Database backups (future feature)
```

## 🚀 Deployment Commands

### Selective App Deployment (New!)

```bash
# Deploy specific apps (comma-separated) - handles SSH keys automatically
ansible-playbook playbooks/deploy.yml -e apps_to_deploy="rekalled,blocshed"

# Deploy single NEW app (perfect for adding new sites)
ansible-playbook playbooks/deploy.yml -e apps_to_deploy="blocshed" -e deploy_mode="new-only"

# Deploy only NEW apps (skips existing deployments, handles SSH keys)
ansible-playbook playbooks/deploy.yml -e deploy_mode="new-only"

# Deploy ALL apps (redeploy existing + deploy new, handles SSH keys)
ansible-playbook playbooks/deploy.yml -e deploy_mode="all"

# Deploy specific app with custom branch (handles SSH keys)
ansible-playbook playbooks/deploy.yml -e apps_to_deploy="rekalled" -e branch="feature-branch"

# Skip SSH key setup if not needed (faster for existing apps)
ansible-playbook playbooks/deploy.yml -e apps_to_deploy="rekalled" --skip-tags ssh_keys
```

### Traditional Deployment Commands

```bash
# Initial setup (creates Capistrano structure + deploys all apps)
ansible-playbook playbooks/deploy.yml -e infrastructure_setup=true

# Deploy all apps (default behavior)
ansible-playbook playbooks/deploy.yml

# Deploy with verbose build output
ansible-playbook playbooks/deploy.yml -e verbose=true

# Legacy single app deployment (deprecated - use apps_to_deploy instead)
ansible-playbook playbooks/deploy.yml -e app=myapp
```

### Rollback Commands (Enhanced)

```bash
# Rollback specific apps
ansible-playbook playbooks/deploy.yml -e mode=rollback -e apps_to_deploy="rekalled,blocshed"

# Rollback single app
ansible-playbook playbooks/deploy.yml -e mode=rollback -e apps_to_deploy="rekalled"

# Rollback with database restore
ansible-playbook playbooks/deploy.yml -e mode=rollback -e apps_to_deploy="rekalled" -e restore_database=true

# Rollback all apps
ansible-playbook playbooks/deploy.yml -e mode=rollback -e deploy_mode="all"
```

### Branch Deployment Examples

```bash
# Deploy feature branch for specific app
ansible-playbook playbooks/deploy.yml -e apps_to_deploy="rekalled" -e mode=branch -e branch=new-feature

# Deploy multiple apps with different branches (not supported yet - deploy separately)
ansible-playbook playbooks/deploy.yml -e apps_to_deploy="rekalled" -e branch=feature-a
ansible-playbook playbooks/deploy.yml -e apps_to_deploy="blocshed" -e branch=feature-b
```

### What Happens During Deployment

1. **Validation Phase**

   - Environment variables loaded
   - SSH keys verified
   - Server connectivity tested
   - Required directories created

2. **Code Checkout**

   - Git repository cloned/updated in `/opt/app/repo`
   - New release directory created with timestamp
   - Code copied to new release directory

3. **Build Phase**

   - Docker images built with full logging
   - Build logs saved to `shared/logs/build_TIMESTAMP.log`
   - Environment files symlinked from shared directory

4. **Deployment Phase**

   - Docker containers stopped gracefully
   - `current` symlink atomically updated to new release
   - Docker containers started from new release
   - Health checks performed

5. **Cleanup Phase**
   - Old releases cleaned up (keeps last 5 by default)
   - Database backups cleaned up (keeps last 5 by default)
   - Deployment logs saved
   - Success/failure status recorded

## ⚙️ Retention Configuration

You can customize how many releases and database backups to keep:

### Via Configuration File

In `group_vars/prod.yml`:

```yaml
# Cleanup and retention settings (optional)
releases_to_keep: 10 # Number of old releases to keep (default: 5)
backups_to_keep: 10 # Number of database backups to keep (default: 5)
```

### Via Command Line

```bash
# Keep more releases and backups
ansible-playbook playbooks/deploy.yml -e releases_to_keep=10 -e backups_to_keep=15

# Keep fewer releases (minimum 1)
ansible-playbook playbooks/deploy.yml -e releases_to_keep=3 -e backups_to_keep=3
```

### Storage Considerations

- **Each release** = Full copy of your application code
- **Each backup** = Full database dump
- **Disk usage** = `(releases_to_keep × app_size) + (backups_to_keep × db_size)`

Example storage impact:

- App size: 100MB, DB size: 500MB
- Default (5 each): ~3GB total
- Conservative (3 each): ~1.8GB total
- Aggressive (10 each): ~6GB total

## 🌟 Key Features

✅ **Zero-downtime deployments** - Atomic symlink swaps  
✅ **Release management** - Keeps last 5 releases automatically  
✅ **Instant rollbacks** - Rollback to any previous release in seconds  
✅ **Branch deployments** - Deploy any branch as separate app with unique subdomain  
✅ **Environment encryption** - .env files encrypted with ansible-vault  
✅ **Shared file management** - Logs, data, config persist across deployments  
✅ **Deployment metadata** - Track who deployed what when  
✅ **Comprehensive logging** - Build and deploy logs for each release  
✅ **Health checks** - Verify containers are running after deployment  
✅ **Automatic cleanup** - Old releases cleaned up automatically

## 📊 Monitoring & Status

```bash
# View deployment system status
ansible-playbook playbooks/test-deployment.yml

# Check specific app status
ansible digitalocean -m shell -a "cd /opt/myapp/current && docker compose ps"

# View deployment logs
ansible digitalocean -m shell -a "tail -f /opt/myapp/shared/logs/deploy_*.log"

# Check release history
ansible digitalocean -m shell -a "ls -lat /opt/myapp/releases/"

# View application logs
ansible digitalocean -m shell -a "cd /opt/myapp/current && docker compose logs --tail=50"
```

## 🔧 Application Requirements

Each application repository must include a `docker-compose.yml` file with:

### 1. Proxy network connection

```yaml
networks:
  - proxy
```

### 2. Caddy labels

```yaml
labels:
  caddy: "${CADDY_HOSTNAME:-myapp.example.com}"
  caddy.reverse_proxy: "{{upstreams ${CADDY_PORT:-3000}}}"
```

### 3. External proxy network

```yaml
networks:
  proxy:
    external: true
    name: ${PROXY_NETWORK:-proxy}
```

### Complete Example

```yaml
version: "3.8"

services:
  app:
    build: .
    ports:
      - "${CADDY_PORT:-3000}:3000"
    environment:
      - NODE_ENV=production
    volumes:
      - ../shared/data:/app/data
    networks:
      - proxy
    labels:
      caddy: "${CADDY_HOSTNAME:-myapp.example.com}"
      caddy.reverse_proxy: "{{upstreams ${CADDY_PORT:-3000}}}"
    restart: unless-stopped

networks:
  proxy:
    external: true
    name: ${PROXY_NETWORK:-proxy}
```

See `templates/docker-compose.example.yml` for a complete template.

## 🔄 Typical Workflow

### 1. Initial Setup (one-time)

Follow the [Quick Start Guide](Quick-Start.md) for initial setup.

### 2. Regular Deployments

```bash
# Deploy latest main branch
ansible-playbook playbooks/deploy.yml

# Deploy with verbose output
ansible-playbook playbooks/deploy.yml -e verbose=true
```

### 3. Feature Branch Testing

```bash
# Deploy feature branch as separate environment
ansible-playbook playbooks/deploy.yml -e mode=branch -e branch=new-feature
```

See [Branch Deployments](Branch-Deployments.md) for details.

### 4. Emergency Rollback

```bash
# Rollback to previous release
ansible-playbook playbooks/deploy.yml -e mode=rollback
```

See [Rollback System](Rollback-System.md) for details.

## 🔐 Security Features

- **Environment encryption** - All .env files encrypted with ansible-vault
- **SSH key management** - Automatic deploy key handling for private repos
- **Secure file permissions** - Proper ownership and permissions on all files
- **Network isolation** - Apps run in isolated Docker networks
- **TLS termination** - Automatic HTTPS with Let's Encrypt certificates

## 📈 Performance Features

- **Docker layer caching** - Efficient builds with layer reuse
- **Git repository caching** - Fast deployments with local git cache
- **Parallel operations** - Multiple apps deployed simultaneously
- **Resource monitoring** - Track CPU, memory, and disk usage

## 🔗 Related Documentation

- **[Branch Deployments](Branch-Deployments.md)** - Deploy feature branches
- **[Rollback System](Rollback-System.md)** - Rollback procedures
- **[Environment Management](Environment-Management.md)** - .env file handling
- **[Private Repositories](Private-Repositories.md)** - Private repo deployment
- **[Monitoring](Monitoring.md)** - Deployment monitoring and logging

## 🎯 Overview

This system provides **zero-downtime deployments** with:

- **Atomic releases** using symlink swapping
- **Automatic rollback** capability
- **Database backup/restore** management
- **Reverse proxy auto-configuration** with Caddy
- **Environment encryption** with Ansible Vault

## 🗄️ Database Strategy

### **Application Responsibility**

Your applications (Rails, Next.js with Drizzle, etc.) handle their own:

- **Database migrations** during startup or build process
- **Schema management** and versioning
- **Migration timing** decisions

### **Ansible Responsibility**

The deployment system handles:

- **Automatic database backups** before each deployment
- **Backup retention** (keeps last 5 backups automatically)
- **Rollback options** with optional database restore
- **Manual backup/restore** operations

### **Deployment Flow with Database**

```bash
# Normal Deployment:
1. 💾 Create automatic database backup (db_backup_TIMESTAMP.sql)
2. 🛑 Stop current application containers
3. 🚀 Deploy new application code to new release
4. ▶️  Start containers (app handles migrations during startup)
5. ✅ Application running with updated schema

# Code-Only Rollback (Safe):
ansible-playbook playbooks/deploy.yml -e mode=rollback -e app=myapp

# Code + Database Rollback (Complete):
ansible-playbook playbooks/deploy.yml -e mode=rollback -e app=myapp -e restore_database=true
```

### **Database Management Commands**

```bash
# List available backups
ansible-playbook playbooks/database-management.yml -e op=list -e app=myapp

# Create manual backup before risky operations
ansible-playbook playbooks/database-management.yml -e op=backup -e app=myapp

# Restore specific backup
ansible-playbook playbooks/database-management.yml -e op=restore -e app=myapp -e file=db_backup_1748602032.sql
```

### **Backup Storage**

- **Location**: `/opt/APP_NAME/backups/`
- **Format**: `db_backup_TIMESTAMP.sql` (PostgreSQL dump)
- **Retention**: Last 5 backups kept automatically
- **Access**: Available for manual restore or rollback operations

### **Rollback Safety**

**Code-Only Rollback** (Default):

- ✅ Safe for compatible schema changes
- ✅ Fast rollback (no data loss)
- ⚠️ May fail if schema is incompatible

**Code + Database Rollback**:

- ✅ Complete rollback to known state
- ⚠️ Loses any data created after backup
- ⚠️ Use only for critical issues

## �� Deployment Modes
