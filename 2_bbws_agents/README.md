# BBWS Agents

AI agent definitions and utility scripts for the BBWS Multi-Tenant WordPress Hosting Platform.

## Overview

This repository contains:
- **Agent Definitions**: Specialized AI agents for platform operations (each in its own folder)
- **Shared Skills**: Common skills used across agents
- **Utility Scripts**: Shell scripts for database, Cognito, and tenant management

## Directory Structure

```
2_bbws_agents/
├── ecs_cluster/           # ECS Cluster Manager Agent
│   ├── README.md
│   ├── agent.md
│   ├── agent_spec.md
│   └── skills/
├── tenant/                # Tenant Manager Agent
│   ├── README.md
│   ├── agent.md
│   ├── agent_spec.md
│   └── skills/
├── content/               # Content Manager Agent
│   ├── README.md
│   ├── agent.md
│   ├── agent_spec.md
│   └── skills/
├── backup/                # Backup Manager Agent
│   ├── README.md
│   ├── agent.md
│   └── skills/
├── dr/                    # DR Manager Agent
│   ├── README.md
│   ├── agent.md
│   └── skills/
├── monitoring/            # Monitoring Agent
│   ├── README.md
│   ├── agent.md
│   └── skills/
├── cost/                  # Cost Manager Agent
│   ├── README.md
│   ├── agent.md
│   └── skills/
├── devops/                # DevOps Agent
│   ├── README.md
│   ├── agent.md
│   ├── agent_spec.md
│   └── skills/
├── skills/                # Shared skills
├── utils/                 # Shared utility scripts
├── logs/                  # TBT session logs
├── .claude/               # Claude Code configuration
├── CLAUDE.md              # Project instructions
└── README.md              # This file
```

## Agents

### Platform Management Agents

| Agent | Folder | Purpose |
|-------|--------|---------|
| ECS Cluster Manager | `ecs_cluster/` | ECS cluster lifecycle management |
| Tenant Manager | `tenant/` | Tenant provisioning and management |
| Content Manager | `content/` | WordPress content operations |
| DevOps Agent | `devops/` | CI/CD and deployment automation |

### Operations Agents

| Agent | Folder | Purpose |
|-------|--------|---------|
| Backup Manager | `backup/` | Backup and restore operations |
| DR Manager | `dr/` | Disaster recovery procedures |
| Monitoring Agent | `monitoring/` | Infrastructure monitoring |
| Cost Manager | `cost/` | Cost tracking and optimization |

## Using Agents

```bash
# Load an agent definition
cat ecs_cluster/agent.md

# Load agent specification
cat tenant/agent_spec.md
```

## Utility Scripts

Located in `utils/` directory.

### Tenant Management

| Script | Purpose |
|--------|---------|
| `get_tenant_urls.sh` | Get tenant access URLs for any environment (dev/sit/prod) |
| `tenant_migration.py` | General-purpose tenant migration utility with rollback support |

**get_tenant_urls.sh Usage:**
```bash
# DEV environment (default)
./utils/get_tenant_urls.sh

# SIT environment
./utils/get_tenant_urls.sh sit

# PROD environment
./utils/get_tenant_urls.sh prod
```

**Output:**
- Lists all active tenants in the specified environment
- Displays WordPress and admin URLs
- Shows service health status (running/desired task counts)

**tenant_migration.py Usage:**
```bash
# Migrate single tenant
python3 utils/tenant_migration.py migrate \
  --tenant goldencrust \
  --from-config old.json \
  --to-config new.json

# Dry run (test without changes)
python3 utils/tenant_migration.py migrate \
  --tenant goldencrust \
  --from-config old.json \
  --to-config new.json \
  --dry-run

# Migrate multiple tenants
python3 utils/tenant_migration.py migrate-batch \
  --tenants tenant1,tenant2,tenant3 \
  --from-config old.json \
  --to-config new.json

# Rollback migration
python3 utils/tenant_migration.py rollback \
  --migration-id migration-goldencrust-abc12345
```

**Features:**
- Multi-step migration with validation
- Automatic rollback on failure
- State tracking and logging
- Batch migration support
- Environment-agnostic (dev/sit/prod)

See [Tenant Migration Guide](utils/TENANT_MIGRATION_GUIDE.md) for detailed documentation.

### Database Management

| Script | Purpose |
|--------|---------|
| `list_databases.sh` | List all databases, users, and sizes |
| `query_database.sh` | Execute SQL queries via ECS task |
| `create_tenant_database.sh` | Create new tenant database/user |
| `get_tenant_credentials.sh` | Get tenant DB credentials |
| `verify_tenant_isolation.sh` | Verify tenant isolation |

### Cognito Management

| Script | Purpose |
|--------|---------|
| `list_cognito_pools.sh` | List all Cognito user pools |
| `get_cognito_credentials.sh` | Get Cognito credentials |
| `verify_cognito_setup.sh` | Verify Cognito setup |
| `delete_cognito_pool.sh` | Delete Cognito pool |

### Usage Examples

```bash
# Make scripts executable
chmod +x utils/*.sh

# Get all tenant URLs (DEV)
./utils/get_tenant_urls.sh

# Get all tenant URLs (PROD)
./utils/get_tenant_urls.sh prod

# List all databases
./utils/list_databases.sh

# Get tenant credentials
./utils/get_tenant_credentials.sh 1
```

## Environments

| Environment | AWS Account | Region | Domain | Profile |
|-------------|-------------|--------|--------|---------|
| DEV | 536580886816 | eu-west-1 | *.wpdev.kimmyai.io | Tebogo-dev |
| SIT | 815856636111 | eu-west-1 | *.wpsit.kimmyai.io | Tebogo-sit |
| PROD | 093646564004 | af-south-1 | *.wp.kimmyai.io | Tebogo-prod |

### DNS Architecture

- **DEV**: wpdev.kimmyai.io delegated hosted zone (NS records in PROD)
- **SIT**: wpsit.kimmyai.io delegated hosted zone (NS records in PROD)
- **PROD**: wp.kimmyai.io direct subdomain in kimmyai.io
- **SSL**: ACM wildcard certificates managed per environment
- **CDN**: CloudFront distributions with custom domains

### Tenant URL Format

- **DEV**: https://tenant.wpdev.kimmyai.io
- **SIT**: https://tenant.wpsit.kimmyai.io
- **PROD**: https://tenant.wp.kimmyai.io

## Related Repositories

- `2_bbws_ecs_terraform` - Infrastructure as Code
- `2_bbws_tenant_provisioner` - Tenant management CLI
- `2_bbws_wordpress_container` - WordPress Docker image
- `2_bbws_ecs_tests` - Integration tests
- `2_bbws_ecs_operations` - Dashboards, alerts, runbooks
- `2_bbws_docs` - Documentation (HLDs, LLDs)

## License

Proprietary - Big Beard Web Solutions
