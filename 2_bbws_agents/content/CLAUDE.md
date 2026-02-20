# Content Manager Agent - Project Instructions

## Project Purpose

WordPress content management and site administration agent for the BBWS Multi-Tenant WordPress Hosting Platform.

## Agent Overview

The Content Management Agent is a WordPress subject matter expert specializing in:
- WordPress plugin configuration and management (13 standard plugins)
- Theme installation and customization
- Complete site lifecycle operations (import/export/backup)
- Content operations (pages, posts, media, forms)
- Performance optimization and security hardening
- Expert troubleshooting for WordPress issues

## Directory Structure

```
content/
├── agent.md              # Agent definition and workflows
├── agent_spec.md         # Detailed technical specification
├── skills/               # Agent-specific skill definitions
├── .claude/              # TBT mechanism
│   ├── logs/             # Operation history logs
│   ├── plans/            # Execution plans
│   └── screenshots/      # Visual documentation
└── CLAUDE.md             # This file
```

## Agent Files

| File | Purpose |
|------|---------|
| `agent.md` | Core agent definition, capabilities, workflows |
| `agent_spec.md` | Technical specification and implementation details |
| `skills/` | Specialized skill definitions for WordPress operations |

## Supported Environments

Operates across all BBWS platform environments:

| Environment | AWS Account | Region | Profile |
|-------------|-------------|--------|---------|
| DEV | 536580886816 | af-south-1 | bbws-dev |
| SIT | 815856636111 | af-south-1 | bbws-sit |
| PROD | 093646564004 | af-south-1 | bbws-prod |

## WordPress Plugin Expertise

### Standard BBWS Plugins (13)
1. **Yoast SEO** - Search engine optimization
2. **Gravity Forms** - Advanced form builder
3. **Wordfence Security** - Security and firewall
4. **W3 Total Cache** - Performance optimization
5. **Really Simple SSL** - SSL/TLS management
6. **WP Mail SMTP** - Email configuration
7. **Akismet Anti-Spam** - Spam protection
8. **Classic Editor** - Content editing
9. **CookieYes GDPR** - Cookie consent management
10. **Hustle** - Marketing and engagement
11. **WP Headers And Footers** - Code injection
12. **Yoast Duplicate Post** - Content duplication
13. **Custom Theme** - BBWS client branding

## Core Workflows

### Site Import Workflow
1. Verify source WordPress site accessibility
2. Export content, database, and media from source
3. Connect to target tenant container
4. Import database and verify structure
5. Import media files to wp-content/uploads
6. Configure plugins and permalinks
7. Verify site functionality

### Site Export Workflow
1. Connect to tenant container
2. Create database backup using WP-CLI
3. Export wp-content directory (themes, plugins, uploads)
4. Package for migration or archival
5. Verify backup integrity

### Plugin Configuration Workflow
1. Connect to tenant container
2. Activate/install required plugins
3. Apply standard BBWS configuration
4. Test plugin functionality
5. Document custom settings

### Troubleshooting Workflow
1. Identify issue symptoms
2. Review WordPress debug logs
3. Check plugin conflicts
4. Verify database integrity
5. Test with minimal configuration
6. Apply fix and verify resolution

## Safety Rules

- **NEVER** perform destructive operations in PROD without approval
- **ALWAYS** create database backups before major changes
- **ALWAYS** verify target environment and tenant before operations
- **NEVER** disable security plugins without justification
- **ALWAYS** test plugin changes in DEV first
- **REQUIRE** explicit approval for site imports to PROD

## Related Agents

| Agent | Relationship |
|-------|-------------|
| Tenant Manager | Provides tenant infrastructure and credentials |
| Backup Manager | Handles automated backup operations |
| Monitoring Agent | Tracks WordPress site health metrics |
| DevOps Agent | Manages deployment and container updates |

## Usage Pattern

```bash
# Set environment
export ENVIRONMENT=dev
export AWS_PROFILE=bbws-dev

# Get tenant credentials
./utils/get_tenant_credentials.sh tenant-001

# Connect to tenant container
aws ecs execute-command --cluster bbws-dev \
  --task <task-arn> \
  --container wordpress \
  --command "/bin/bash" \
  --interactive

# Use WP-CLI
wp plugin list
wp theme list
wp db export backup.sql
```

## Agent Activation

Load the agent definition into context:

```bash
cat agent.md
```

## Root Workflow Inheritance

This agent inherits TBT mechanism and all workflow standards from the parent CLAUDE.md:

{{include:../CLAUDE.md}}
