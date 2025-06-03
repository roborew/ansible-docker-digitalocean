# Database Management

Comprehensive guide to database handling, backups, and rollbacks in the deployment system.

## 🎯 Philosophy

The deployment system follows a **clear separation of concerns**:

- **Your Application**: Handles migrations, schema changes, and database logic
- **Ansible System**: Handles backups, restores, and infrastructure safety

This approach works with any application framework (Rails, Django, Next.js with Drizzle, etc.).

## 🗄️ Database Lifecycle

### **During Normal Deployments**

```bash
# Automatic flow:
1. 💾 Backup current database → /opt/APP/backups/db_backup_TIMESTAMP.sql
2. 🛑 Stop application containers (database volume persists)
3. 🚀 Deploy new application code
4. ▶️  Start new containers
5. 🔄 Application runs migrations during startup (your app's responsibility)
6. ✅ New version running with updated schema
```

### **During Rollbacks**

**Code-Only Rollback** (Default behavior):

```bash
ansible-playbook playbooks/deploy.yml -e mode=rollback -e app=myapp

# What happens:
1. 🛑 Stop current containers
2. 🔄 Switch symlink to previous release
3. ▶️  Start old application version
4. ⚠️  Old code runs against current database schema
```

**Code + Database Rollback** (Complete rollback):

```bash
ansible-playbook playbooks/deploy.yml -e mode=rollback -e app=myapp -e restore_database=true

# What happens:
1. 🛑 Stop current containers
2. 🔄 Switch symlink to previous release
3. 💾 Restore database backup from that release
4. ▶️  Start old application version
5. ✅ Complete rollback to previous state
```

## 💾 Backup Management

### **Automatic Backups**

Created automatically before every deployment:

- **Naming**: `db_backup_TIMESTAMP.sql`
- **Location**: `/opt/APP_NAME/backups/`
- **Format**: PostgreSQL dump (pg_dump)
- **Retention**: Last 5 backups kept automatically

### **Manual Backup Operations**

```bash
# Create manual backup
ansible-playbook playbooks/database-management.yml -e op=backup -e app=myapp

# Create named backup (for major releases)
ansible-playbook playbooks/database-management.yml -e op=backup -e app=myapp -e backup=v2.0.0

# List all available backups
ansible-playbook playbooks/database-management.yml -e op=list -e app=myapp
```

### **Backup File Structure**

```
/opt/myapp/
├── backups/
│   ├── db_backup_1748602032.sql      # Automatic deployment backup
│   ├── db_backup_1748601800.sql      # Previous deployment backup
│   ├── db_backup_manual_1748599000.sql # Manual backup
│   └── db_backup_v2.0.0.sql          # Named release backup
├── current -> releases/1748602032     # Current release symlink
└── releases/
    ├── 1748602032/                    # Latest release
    └── 1748601800/                    # Previous release
```

## 🔄 Restore Operations

### **Manual Database Restore**

```bash
# Restore specific backup
ansible-playbook playbooks/database-management.yml \
  -e op=restore \
  -e app=myapp \
  -e file=db_backup_1748601800.sql

# Restore named backup
ansible-playbook playbooks/database-management.yml \
  -e op=restore \
  -e app=myapp \
  -e file=db_backup_v2.0.0.sql
```

### **Emergency Database Recovery**

If you need to manually restore without Ansible:

```bash
# Connect to server
ssh user@your-server

# Navigate to app directory
cd /opt/myapp/current

# List available backups
ls -la ../backups/

# Restore specific backup
docker compose exec -T postgres psql -U postgres -d myapp < ../backups/db_backup_TIMESTAMP.sql
```

## 🚨 Best Practices

### **Before Major Deployments**

1. **Create a named backup**:

   ```bash
   ansible-playbook playbooks/database-management.yml -e op=backup -e app=myapp -e backup=pre-v3.0
   ```

2. **Test in staging first** with same migration scripts

3. **Plan rollback strategy** - know which backup to restore if needed

### **Schema Migration Guidelines**

Since your application handles migrations:

1. **Make migrations backwards compatible** when possible
2. **Use feature flags** for breaking changes
3. **Test rollback scenarios** in staging
4. **Deploy schema changes separately** from data changes when needed

### **Monitoring After Deployment**

```bash
# Check application logs for migration errors
ansible digitalocean -m shell -a "cd /opt/myapp/current && docker compose logs app"

# Check database connectivity
ansible digitalocean -m shell -a "cd /opt/myapp/current && docker compose exec -T postgres pg_isready -U postgres"

# Monitor application health
curl -I https://your-app.com/health
```

## 🛠️ Troubleshooting

### **Migration Failures**

If application startup fails due to migration issues:

1. **Check application logs**:

   ```bash
   ansible digitalocean -m shell -a "cd /opt/myapp/current && docker compose logs app"
   ```

2. **Manual migration** (if needed):

   ```bash
   # Connect to app container
   ansible digitalocean -m shell -a "cd /opt/myapp/current && docker compose exec app bash"

   # Run migrations manually
   npm run db:migrate  # or rails db:migrate, etc.
   ```

3. **Rollback if critical**:
   ```bash
   ansible-playbook playbooks/deploy.yml -e mode=rollback -e app=myapp -e restore_database=true
   ```

### **Backup/Restore Failures**

**Backup fails during deployment**:

- Deployment continues (non-critical)
- Check database connectivity
- Manually create backup after deployment

**Restore fails**:

- Check backup file exists and is readable
- Verify database is running
- Check PostgreSQL logs for specific errors

### **Schema Incompatibility After Rollback**

If old application fails with new database schema:

1. **Check application logs** for specific errors
2. **Use code + database rollback**:
   ```bash
   ansible-playbook playbooks/deploy.yml -e mode=rollback -e app=myapp -e restore_database=true
   ```
3. **Or restore specific backup**:
   ```bash
   ansible-playbook playbooks/database-management.yml -e op=restore -e app=myapp -e file=BACKUP_FILE
   ```

## 📚 Integration Examples

### **Rails Application**

Your Rails app would handle migrations in `config/database.yml` and:

```ruby
# In deployment process (handled by Rails)
rails db:migrate RAILS_ENV=production
```

### **Next.js with Drizzle**

Your app would handle migrations in startup or build:

```javascript
// In your app startup
import { migrate } from "drizzle-orm/postgres-js/migrator";
await migrate(db, { migrationsFolder: "./migrations" });
```

### **Django Application**

Django handles migrations automatically:

```python
# In your Docker entrypoint or startup
python manage.py migrate
```

The deployment system just ensures you can safely rollback if any of these fail.

---

**[🚀 Back to Home](Home.md)** | **[📚 Deployment System](Deployment-System.md)**
