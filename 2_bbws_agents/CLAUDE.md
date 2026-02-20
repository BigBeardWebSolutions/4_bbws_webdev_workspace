# BBWS Agents - Project Instructions

## Project Purpose

AI agent definitions and utility scripts for the BBWS Multi-Tenant WordPress Hosting Platform.

## Critical Safety Rules

- **NEVER** run database modification scripts against PROD
- **ALWAYS** verify target environment before execution
- **NEVER** hardcode credentials - use environment variables
- **ALWAYS** test scripts in DEV first
- **REQUIRE** approval for PROD operations

## Environments

| Environment | AWS Account | Region | Profile |
|-------------|-------------|--------|---------|
| DEV | 536580886816 | eu-west-1 | Tebogo-dev |
| SIT | 815856636111 | eu-west-1 | Tebogo-sit |
| PROD | 093646564004 | af-south-1 | Tebogo-prod |

## Agent Definitions

### Platform Management Agents

| Agent | Purpose |
|-------|---------|
| `ecs_cluster_manager.md` | ECS cluster lifecycle management |
| `tenant_manager.md` | Tenant provisioning and management |
| `content_manager.md` | WordPress content operations |
| `DevOps_agent.md` | CI/CD and deployment automation |

### Operations Agents

| Agent | Purpose |
|-------|---------|
| `backup_manager_agent.md` | Backup and restore operations |
| `dr_manager_agent.md` | Disaster recovery procedures |
| `monitoring_agent.md` | Infrastructure monitoring |
| `cost_monitoring_agent.md` | Cost tracking and optimization |

### Agent Loading

```bash
# Load an agent definition into context
cat agents/tenant_manager.md
```

## Utility Scripts

Located in `utils/` directory.

### Database Scripts

| Script | Purpose | Risk Level |
|--------|---------|------------|
| `list_databases.sh` | Read-only database listing | Low |
| `query_database.sh` | Execute SQL queries | Medium |
| `create_tenant_database.sh` | Create tenant database | High |
| `get_tenant_credentials.sh` | Get credentials | Low |
| `verify_tenant_isolation.sh` | Verify isolation | Low |

### Cognito Scripts

| Script | Purpose | Risk Level |
|--------|---------|------------|
| `list_cognito_pools.sh` | List pools | Low |
| `get_cognito_credentials.sh` | Get credentials | Low |
| `verify_cognito_setup.sh` | Verify setup | Low |
| `delete_cognito_pool.sh` | Delete pool | High |

## Usage Pattern

```bash
# Set environment (default: dev)
export ENVIRONMENT=dev
export AWS_PROFILE=bbws-dev

# Run script
./utils/list_databases.sh
```

## Related Repositories

- `2_bbws_ecs_terraform` - Infrastructure as Code
- `2_bbws_tenant_provisioner` - Tenant management CLI
- `2_bbws_wordpress_container` - WordPress Docker image
- `2_bbws_ecs_tests` - Integration tests
- `2_bbws_ecs_operations` - Dashboards, alerts, runbooks

## Root Workflow Inheritance

This project inherits TBT mechanism and all workflow standards from the parent CLAUDE.md:

{{include:../CLAUDE.md}}
