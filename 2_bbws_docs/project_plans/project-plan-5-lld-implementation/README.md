# Project Plan 5: LLD 2.5, 2.6, 2.7 Implementation

## Quick Start

This project implements three Low-Level Design documents:
- **LLD 2.5** - Tenant Management
- **LLD 2.6** - WordPress Site Management
- **LLD 2.7** - WordPress Instance Management

## Portal Mapping Summary

```
┌─────────────────────────────────────────────────────────────────┐
│                 CUSTOMER SELF-SERVICE PORTAL                     │
├─────────────────────────────────────────────────────────────────┤
│  LLD 2.5 (Partial)     │  LLD 2.6 (Primary)                     │
│  - View tenant         │  - Site CRUD, clone, promote           │
│  - Manage users        │  - Browse/apply templates              │
│  - Invitations         │  - Install/manage plugins              │
│  - View hierarchy      │  - View site health                    │
└─────────────────────────────────────────────────────────────────┘

┌─────────────────────────────────────────────────────────────────┐
│                        ADMIN PORTAL                              │
├─────────────────────────────────────────────────────────────────┤
│  LLD 2.5 (Full)        │  LLD 2.6 (Partial)  │  LLD 2.7 (Full)  │
│  - Create tenants      │  - Template CRUD    │  - ECS Services   │
│  - Park/Unpark         │  - Plugin catalog   │  - EFS, RDS, ALB  │
│  - Deprovision         │  - Cross-tenant     │  - Cognito Pools  │
│  - Cross-tenant ops    │                     │  - Scale/Stop     │
└─────────────────────────────────────────────────────────────────┘
```

## Project Structure

```
project-plan-5-lld-implementation/
├── README.md                          ← You are here
├── project_plan.md                    ← Main project plan
├── WORKER_INSTRUCTIONS_TEMPLATE.md    ← Worker template
├── stage-1-analysis/                  ← API mapping & analysis
│   └── plan.md
├── stage-2-lambda-customer-portal/    ← Customer Portal Lambdas
│   └── plan.md
├── stage-3-lambda-admin-portal/       ← Admin Portal Lambdas
│   └── plan.md
├── stage-4-cicd-pipeline/             ← GitHub Actions workflows
│   └── plan.md
├── stage-5-integration-testing/       ← Integration tests
│   └── plan.md
└── stage-6-documentation-runbooks/    ← Docs & runbooks
    └── plan.md
```

## Repositories to Create

| Repository | LLD | Purpose |
|------------|-----|---------|
| `2_bbws_tenant_lambda` | 2.5 | Tenant Management APIs |
| `2_bbws_wordpress_site_management_lambda` | 2.6 | Site, Template, Plugin APIs |
| `2_bbws_tenants_instances_lambda` | 2.7 | Instance Management APIs |
| `2_bbws_tenants_instances_dev` | 2.7 | GitOps Terraform configs |
| `2_bbws_tenants_event_handler` | 2.7 | ECS EventBridge handler |

## Key Standards

- **TDD**: Write tests first (pytest, moto)
- **OOP**: Follow class structures in LLDs
- **80% Coverage**: Minimum test coverage
- **HATEOAS**: REST APIs with hypermedia links
- **DynamoDB**: On-demand, single-table design
- **Environments**: DEV → SIT → PROD

## Getting Started

1. Review `project_plan.md` for full details
2. Start with Stage 1 Analysis
3. Execute workers in parallel within each stage
4. Obtain gate approval before proceeding

## Status

| Stage | Progress |
|-------|----------|
| Stage 1: Analysis | PENDING |
| Stage 2: Customer Portal | PENDING |
| Stage 3: Admin Portal | PENDING |
| Stage 4: CI/CD | PENDING |
| Stage 5: Testing | PENDING |
| Stage 6: Documentation | PENDING |

**Total Workers**: 40
**Completed**: 0/40 (0%)

---

**Created**: 2026-01-24
**Project Manager**: Agentic Project Manager
