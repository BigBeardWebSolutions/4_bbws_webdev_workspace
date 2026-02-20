# WordPress & Tenant Management SDLC Process

**Process Type**: AI-Generated WordPress Sites with Multi-Tenant Management
**Version**: 1.0
**Status**: Standalone Process

---

## Overview

This is a **standalone SDLC process** for developing AI-powered WordPress sites with multi-tenant management. It covers theme development, AI content generation using AWS Bedrock, static site deployment, and organizational tenant management with RBAC.

## Process Files

| File | Description |
|------|-------------|
| [main-plan.md](./main-plan.md) | Master orchestration plan |
| [process-definition.md](./process-definition.md) | Machine-readable process definition |

## Tracks & Stages

### WordPress Track (Sites)

| # | Stage | Description | Workers |
|---|-------|-------------|---------|
| W1 | [Theme Development](./stage-w1-theme-dev.md) | WordPress theme structure, templates, styles | 3 |
| W2 | [AI Site Generation](./stage-w2-ai-generation.md) | Claude content + Stable Diffusion images | 4 |
| W3 | [Deployment](./stage-w3-deployment.md) | S3/CloudFront infrastructure | 3 |
| W4 | [Testing](./stage-w4-testing.md) | Functional, accessibility, performance | 3 |

### Tenant Track (Management)

| # | Stage | Description | Workers |
|---|-------|-------------|---------|
| T1 | [Tenant API](./stage-t1-tenant-api.md) | Organization CRUD, DynamoDB | 4 |
| T2 | [User Hierarchy](./stage-t2-user-hierarchy.md) | Division/Group/Team/User structure | 4 |
| T3 | [Access Control](./stage-t3-access-control.md) | RBAC, tenant isolation | 5 |

**Total**: 7 stages, 26 workers, 2 approval gates

## Technology Stack

### WordPress/AI Generation
| Category | Technology |
|----------|------------|
| Theme Engine | WordPress/PHP templates |
| AI Content | AWS Bedrock - Claude Sonnet 3.5 |
| AI Images | AWS Bedrock - Stable Diffusion XL |
| Output | Static HTML/CSS/JS |
| Hosting | S3 + CloudFront |
| CI/CD | GitHub Actions with OIDC |

### Tenant Management
| Category | Technology |
|----------|------------|
| Runtime | Python 3.12 |
| Framework | AWS Lambda |
| Database | DynamoDB (Single Table) |
| API | API Gateway REST |
| Auth | Custom RBAC |
| Email | AWS SES (invitations) |

## Estimated Duration

| Mode | Duration |
|------|----------|
| Agentic | 9 hours |
| Manual | 38 hours |

**Note**: WordPress and Tenant tracks can run in parallel.

## Quick Start

```bash
# 1. Create new WordPress/Tenant project
PROJECT_NAME="MyOrg"
mkdir ${PROJECT_NAME}_wordpress && cd ${PROJECT_NAME}_wordpress

# 2. Copy process files
mkdir -p .claude/plans
cp -r path/to/process/wordpress-site/*.md .claude/plans/

# 3. Initialize state files
cd .claude/plans
for stage in stage-*.md; do
  touch "${stage%.md}.state.PENDING"
done

# 4. Start PM orchestration
# PM reads main-plan.md and executes parallel tracks
```

## Approval Gates

| Gate | After Stage | Approvers |
|------|-------------|-----------|
| W1 | W4 (Testing) | Tech Lead, Content Lead |
| T1 | T3 (RBAC) | Tech Lead, Security Lead |

## Environment Configuration

### WordPress Sites
| Environment | Domain Pattern |
|-------------|----------------|
| DEV | `{tenant}.sites.dev.kimmyai.io` |
| SIT | `{tenant}.sites.sit.kimmyai.io` |
| PROD | `{tenant}.sites.kimmyai.io` |

### Tenant Management API
| Environment | API Endpoint |
|-------------|--------------|
| DEV | `api.dev.kimmyai.io/v1.0/tenants` |
| SIT | `api.sit.kimmyai.io/v1.0/tenants` |
| PROD | `api.kimmyai.io/v1.0/tenants` |

## Multi-Tenant Data Model

```
Organization (Tenant)
├── tenant_id, organization_name, admin_email
├── config: destination_email, max_sites, max_users
├── Hierarchy: Division → Group → Team → User
├── Sites: WordPress static sites
└── Roles: org_admin, team_admin, team_lead, member
```

## Use Cases

- Multi-tenant SaaS platforms
- Agency client management
- White-label website builders
- Enterprise site portfolios
- Franchise website systems

---

**Start Here**: [main-plan.md](./main-plan.md)
