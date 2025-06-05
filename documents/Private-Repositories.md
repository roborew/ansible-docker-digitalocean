# Private Repository Support

This deployment system supports both public and private GitHub repositories with **automatic SSH key management**.

## 🔑 Deploy Key Setup (for private repositories)

### Generate Deploy Keys

```bash
# Generate deploy keys for your configured apps (after configuring apps in group_vars/prod.yml)
./scripts/setup-deploy-keys.sh
```

The script will:

- Generate unique SSH key pairs for each configured app
- Display public keys for you to add to GitHub
- Store private keys securely in `files/ssh_keys/` (gitignored)
- Create keys with proper naming: `appname_deploy_key` and `appname_deploy_key.pub`

### Add Keys to GitHub

For each app, add the public key to your repository:

1. Go to: `github.com/username/repo-name`
2. Settings → Deploy keys → Add deploy key
3. Paste the public key and give it a descriptive title (e.g., "Production Deploy Key")
4. ✅ Check "Allow write access" (optional, only if you need push capability)

## 🚀 Deployment with Private Repositories

### Same Commands for All Repositories

```bash
# SSH keys are automatically deployed and detected
# Same commands work for both public and private repositories!

# Initial deployment
ansible-playbook playbooks/deploy.yml -e infrastructure_setup=true

# Subsequent deployments
ansible-playbook playbooks/deploy.yml

# Branch deployments
ansible-playbook playbooks/deploy.yml -e mode=branch -e branch=feature-name

# Rollbacks (no special parameters needed)
ansible-playbook playbooks/deploy.yml -e mode=rollback
```

## ⚡ How Automatic Detection Works

✅ **SSH keys deployed once** - During initial deployment  
✅ **Automatic per-app detection** - Each app checks for its own key  
✅ **Smart URL conversion** - HTTPS URLs automatically converted to SSH when keys exist  
✅ **Zero configuration** - No manual parameters or configuration needed  
✅ **Multiple repos supported** - All private repos work simultaneously

### Technical Details

1. **Key Deployment**: SSH keys are deployed to `/home/username/.ssh/` during initial setup
2. **SSH Config**: Automatic SSH configuration for each app repository
3. **URL Detection**: The system detects when an SSH key exists for a repository
4. **Automatic Conversion**: HTTPS URLs are converted to SSH format when keys are available
5. **Fallback**: Repositories without keys automatically use HTTPS

## 🔒 Security Best Practices

✅ **Deploy keys are app-specific** - Each app has its own key  
✅ **Read-only by default** - Deploy keys don't have push access unless enabled  
✅ **Easy to revoke** - Remove from GitHub repo settings if compromised  
✅ **Stored securely** - Private keys never committed to git (`.gitignore` protected)  
✅ **Proper permissions** - Keys deployed with 600 permissions on server

### Security Features

- **Isolation**: Each app has its own deploy key, limiting access scope
- **Revocation**: Individual keys can be revoked without affecting other apps
- **Audit Trail**: GitHub tracks all deploy key usage
- **Least Privilege**: Keys are read-only by default

## 📁 File Structure

```
files/ssh_keys/
├── README.md                    # Documentation
├── myapp_deploy_key             # Private key (GITIGNORED)
├── myapp_deploy_key.pub         # Public key (GITIGNORED)
├── otherapp_deploy_key          # Another app's private key
└── otherapp_deploy_key.pub      # Another app's public key
```

**Important**: All SSH private keys are automatically ignored by git via `.gitignore`.

## 🔄 SSH Key Lifecycle

### Initial Setup

1. Configure apps in `group_vars/prod.yml`
2. Run `./scripts/setup-deploy-keys.sh`
3. Add public keys to GitHub repositories
4. Deploy with `ansible-playbook playbooks/deploy.yml -e infrastructure_setup=true`

### Key Rotation

```bash
# Generate new keys
./scripts/setup-deploy-keys.sh

# Update keys on GitHub (replace old keys)
# Deploy updated keys
ansible-playbook playbooks/deploy.yml --tags ssh_keys
```

### Emergency Key Revocation

```bash
# On GitHub: Remove deploy key from repository settings
# On server: Remove key files (optional, as they'll be inactive)
ansible digitalocean -m shell -a "rm -f ~/.ssh/appname_deploy_key*"
```

## 🛠️ Troubleshooting

### Key Not Working

```bash
# Check if key exists on server
ansible digitalocean -m shell -a "ls -la ~/.ssh/*deploy_key*"

# Test SSH connection manually
ansible digitalocean -m shell -a "ssh -T git@github.com"

# Check SSH config
ansible digitalocean -m shell -a "cat ~/.ssh/config"
```

### Permission Issues

```bash
# Fix key permissions
ansible digitalocean -m shell -a "chmod 600 ~/.ssh/*deploy_key"
ansible digitalocean -m shell -a "chmod 644 ~/.ssh/*deploy_key.pub"
```

### Repository Access Issues

1. **Verify public key is added to GitHub**
2. **Check repository permissions** - Ensure key has access to the specific repo
3. **Test SSH connection** - Use `ssh -T git@github.com` to test
4. **Verify key format** - Ensure public key was copied completely

### Debug SSH Connection

```bash
# Test SSH connection with verbose output
ansible digitalocean -m shell -a "ssh -vT git@github.com"

# Check SSH agent
ansible digitalocean -m shell -a "ssh-add -l"
```

## 🔗 Related Documentation

- **[Quick Start Guide](Quick-Start.md)** - Initial setup including private repos
- **[Deployment System](Deployment-System.md)** - How deployments work
- **[SSH Key Management](SSH-Keys.md)** - Detailed SSH key setup
- **[Troubleshooting](Troubleshooting.md)** - Common SSH issues
- **[Security Guide](Security.md)** - Security considerations

## 📝 Notes

**Automatic Fallback**: The system automatically falls back to HTTPS for repositories without deploy keys, making it seamless to mix public and private repositories in the same deployment.
