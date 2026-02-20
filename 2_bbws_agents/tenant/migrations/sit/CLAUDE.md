# SIT Promotion Toolkit - Project Instructions

## Project Purpose

Toolkit for promoting WordPress tenants from DEV to SIT using the **warm tenant** strategy. Pre-provisions SIT infrastructure so promotion only requires data import (DB + files), cutting the 8-step process roughly in half.

## Key Concepts

### Cross-Account ECR
- SIT pulls the WordPress container image directly from DEV ECR (`536580886816.dkr.ecr.eu-west-1.amazonaws.com/dev-wordpress`)
- This ensures what runs in SIT is identical to what was tested in DEV
- Terraform resources: `ecr_cross_account_policy.tf` (DEV), `sit_ecr_pull_policy.tf` (SIT)

### Warm Tenants
- SIT infrastructure is pre-provisioned before the actual promotion
- A warm tenant has: ECS service running, ALB target group, Secrets Manager secret, EFS access point, empty database
- Promotion then only requires: export DEV data, import to SIT, redeploy

## Scripts

| Script | Purpose | Steps |
|--------|---------|-------|
| `warm_tenant_provision.sh` | Create warm SIT tenant | Generate TF, apply, init DB, validate |
| `quick_promote.sh` | Promote to warm tenant | Validate warm, export DEV, import SIT, redeploy |
| `validate_warm_tenant.sh` | Check warm tenant health | 6 checks: ECS, ALB, HTTP, Secrets, EFS, DB |
| `list_warm_tenants.sh` | List warm tenants | Show status: WARM, PROMOTED, STOPPED |

## Usage

```bash
# 1. Pre-provision a warm tenant in SIT
./scripts/warm_tenant_provision.sh cliplok --alb-priority 150

# 2. Later, quickly promote DEV data
./scripts/quick_promote.sh cliplok

# 3. Check warm tenant status
./scripts/list_warm_tenants.sh
```

## Environments

| Environment | AWS Account | Region | Profile |
|-------------|-------------|--------|---------|
| DEV | 536580886816 | eu-west-1 | dev |
| SIT | 815856636111 | eu-west-1 | sit |

## Mandatory Constraints

- **SSM only** — No SSH keys exist on bastions
- **Bastion-only DB operations** — Never inline SQL via SSM
- **Size-based transfer**: <500MB direct bastion, >=500MB S3 staging
- **Never target PROD** — Production requires separate process

## Root Workflow Inheritance

This project inherits TBT mechanism and all workflow standards from the parent CLAUDE.md:

{{include:../../../CLAUDE.md}}
