# Maintenance Mode

The maintenance mode feature allows you to temporarily replace your applications with a professional "Under Construction" page while performing updates, deployments, or maintenance tasks.

## 🚧 Quick Start

### Enable Maintenance (All Apps)

```bash
# Using the convenience script
./scripts/maintenance-mode.sh enable

# Using Ansible directly
ansible-playbook playbooks/maintenance-mode.yml -e action=enable
```

### Enable Maintenance (Specific App)

```bash
# Using the convenience script
./scripts/maintenance-mode.sh enable -a myapp

# Using Ansible directly
ansible-playbook playbooks/maintenance-mode.yml -e action=enable -e app_name=myapp
```

### Disable Maintenance

```bash
# Using the convenience script
./scripts/maintenance-mode.sh disable

# Using Ansible directly
ansible-playbook playbooks/maintenance-mode.yml -e action=disable
```

### Check Status

```bash
# Using the convenience script
./scripts/maintenance-mode.sh status

# Using Ansible directly
ansible-playbook playbooks/maintenance-mode.yml -e action=status
```

## 🎨 Customization Options

### Custom Maintenance Message

```bash
./scripts/maintenance-mode.sh enable \
  -t "MyApp Upgrade" \
  -r "Upgrading to version 2.0 with exciting new features" \
  -c "2024-01-01 15:00 UTC" \
  -e "support@myapp.com"
```

### Available Options

| Option             | Description          | Example                     |
| ------------------ | -------------------- | --------------------------- |
| `-a, --app`        | Target specific app  | `-a myapp`                  |
| `-t, --title`      | Custom page title    | `-t "System Upgrade"`       |
| `-r, --reason`     | Maintenance reason   | `-r "Database migration"`   |
| `-c, --completion` | Estimated completion | `-c "2024-01-01 15:00 UTC"` |
| `-e, --email`      | Contact email        | `-e "support@example.com"`  |
| `-y, --yes`        | Skip confirmation    | `-y` (for scripts)          |

## 🔧 How It Works

### Architecture

1. **Container-Based**: Uses nginx:alpine container to serve static HTML
2. **Caddy Integration**: Works with existing Caddy Docker Proxy using labels
3. **Traffic Redirection**: Stops app containers and starts maintenance container
4. **Status Tracking**: Maintains JSON status files for monitoring

### Behind the Scenes

When maintenance mode is enabled:

1. **Generate HTML**: Creates a responsive maintenance page from template
2. **Stop Apps**: Gracefully stops application containers
3. **Start Maintenance**: Deploys nginx container with Caddy labels
4. **Update Routes**: Caddy automatically routes traffic to maintenance page
5. **Track Status**: Creates status files for monitoring and management

When maintenance mode is disabled:

1. **Stop Maintenance**: Removes maintenance container
2. **Restart Apps**: Brings application containers back online
3. **Restore Routes**: Caddy automatically restores normal routing
4. **Update Status**: Records maintenance session history

### File Structure

```
/opt/maintenance/
├── index.html              # Generated maintenance page
├── docker-compose.yml      # Maintenance container config
├── status.json            # Current status (when enabled)
└── last_status.json       # Previous maintenance session
```

## 🎯 Use Cases

### Planned Maintenance

```bash
# Before deployment
./scripts/maintenance-mode.sh enable \
  -r "Deploying new features and security updates" \
  -c "$(date -d '+1 hour' '+%Y-%m-%d %H:%M UTC')"

# Perform deployment
ansible-playbook playbooks/deploy.yml

# After deployment
./scripts/maintenance-mode.sh disable
```

### Database Migration

```bash
# Enable with custom message
./scripts/maintenance-mode.sh enable \
  -t "Database Upgrade" \
  -r "Migrating to new database schema for improved performance" \
  -c "2024-01-01 14:00 UTC"

# Run migration
ansible-playbook playbooks/database-management.yml -e op=migrate

# Disable maintenance
./scripts/maintenance-mode.sh disable
```

### Rollback Safety

```bash
# Enable maintenance before risky deployment
./scripts/maintenance-mode.sh enable -r "Testing new release"

# Deploy and test
ansible-playbook playbooks/deploy.yml -e branch=v2.0

# If issues, rollback is safer with maintenance page active
ansible-playbook playbooks/deploy.yml -e mode=rollback

# Disable when confident
./scripts/maintenance-mode.sh disable
```

### App-Specific Maintenance

```bash
# Maintain only the API while frontend stays online
./scripts/maintenance-mode.sh enable -a api \
  -r "API maintenance for improved performance"

# Work on API
ansible-playbook playbooks/deploy.yml -e app_name=api

# Restore API
./scripts/maintenance-mode.sh disable -a api
```

## 🛠️ Advanced Usage

### Ansible Playbook Integration

```yaml
# In your deployment playbook
- name: Enable maintenance mode
  include_role:
    name: maintenance_mode
  vars:
    maintenance_mode_action: enable
    app_name: "{{ target_app }}"
    maintenance_reason: "Deploying {{ app_version }}"

# ... deployment tasks ...

- name: Disable maintenance mode
  include_role:
    name: maintenance_mode
  vars:
    maintenance_mode_action: disable
    app_name: "{{ target_app }}"
```

### Custom HTML Template

You can customize the maintenance page by modifying:
`roles/maintenance_mode/templates/maintenance.html.j2`

Variables available in template:

- `site_title`
- `status_text`
- `subtitle`
- `maintenance_reason`
- `estimated_completion`
- `contact_email`
- `maintenance_started`

### Status Monitoring

```bash
# Check if maintenance is active
if ansible-playbook playbooks/maintenance-mode.yml -e action=status | grep -q "ENABLED"; then
    echo "Maintenance mode is active"
fi

# Get maintenance status as JSON
cat /opt/maintenance/status.json
```

## 🔍 Troubleshooting

### Common Issues

**Maintenance page not showing**

```bash
# Check container status
docker ps | grep maintenance

# Check Caddy configuration
docker exec caddy-proxy curl -s http://localhost:2019/config/

# Verify network connectivity
docker exec maintenance-all curl -s http://localhost
```

**Apps not restarting after disable**

```bash
# Check app directories
ls -la /opt/*/current/

# Manually restart if needed
cd /opt/myapp/current && docker compose up -d
```

**Conflicts with existing containers**

```bash
# Check for conflicting containers
docker ps --filter "label=caddy"

# Manual cleanup if needed
docker stop maintenance-all && docker rm maintenance-all
```

### Status File Corruption

```bash
# Remove corrupted status file
sudo rm /opt/maintenance/status.json

# Force disable maintenance
docker stop maintenance-all maintenance-myapp 2>/dev/null || true
docker rm maintenance-all maintenance-myapp 2>/dev/null || true
```

## 🚀 Best Practices

### 1. Always Use Confirmation

- Don't skip confirmation (`-y`) unless in scripts
- Double-check the target app name before enabling
- Verify status after operations

### 2. Provide Clear Communication

```bash
# Good: Clear reason and timeline
./scripts/maintenance-mode.sh enable \
  -r "Security patch deployment - critical vulnerability fix" \
  -c "2024-01-01 14:30 UTC" \
  -e "security@company.com"

# Poor: Vague message
./scripts/maintenance-mode.sh enable -r "Updates"
```

### 3. Test First

```bash
# Test maintenance page before using in production
./scripts/maintenance-mode.sh enable -a test-app
curl -I http://test-app.yourdomain.com
./scripts/maintenance-mode.sh disable -a test-app
```

### 4. Monitor Duration

```bash
# Check how long maintenance has been active
./scripts/maintenance-mode.sh status
```

### 5. Document Maintenance Windows

```bash
# Create maintenance log
echo "$(date): Enabled maintenance for $APP - $REASON" >> /var/log/maintenance.log
```

## 🔗 Integration

### CI/CD Pipeline

```yaml
# GitHub Actions example
- name: Enable Maintenance Mode
  run: |
    ./scripts/maintenance-mode.sh enable -y \
      -r "Automated deployment of ${{ github.sha }}" \
      -c "$(date -d '+30 minutes' '+%Y-%m-%d %H:%M UTC')"

- name: Deploy Application
  run: ansible-playbook playbooks/deploy.yml

- name: Disable Maintenance Mode
  run: ./scripts/maintenance-mode.sh disable -y
```

### Monitoring Integration

```bash
# Send notification when maintenance starts
./scripts/maintenance-mode.sh enable && \
  curl -X POST "https://hooks.slack.com/..." \
    -d '{"text":"🚧 Maintenance mode enabled"}'
```

## 📝 Notes

- Maintenance mode works with the existing Caddy Docker Proxy
- Containers are automatically labeled for easy identification
- Status files preserve maintenance history
- Multiple apps can have independent maintenance modes
- All traffic is gracefully redirected without 5xx errors
- The maintenance page is fully responsive and professional
