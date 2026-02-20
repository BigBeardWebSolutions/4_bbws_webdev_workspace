# SIT Promotion Toolkit

Accelerated DEV-to-SIT promotion using warm tenants and cross-account ECR.

## Problem

The standard `promote_dev_to_sit.sh` runs 8 steps end-to-end, including full Terraform provisioning. This means:
- Infrastructure provisioning takes 5-10 minutes per tenant
- SIT rebuilds its own WordPress image independently (may differ from DEV)
- Each promotion is a long, serial process

## Solution

### Cross-Account ECR (Image Consistency)

SIT now pulls the WordPress container image directly from DEV ECR:
```
536580886816.dkr.ecr.eu-west-1.amazonaws.com/dev-wordpress:latest
```

This guarantees SIT runs the exact same image that was tested in DEV.

**Terraform changes:**
- `ecr_cross_account_policy.tf` — DEV grants SIT/PROD read access to ECR
- `sit_ecr_pull_policy.tf` — SIT ECS execution role can pull from DEV ECR
- `sit.tfvars` — `wordpress_image` points to DEV ECR URI

### Warm Tenants (Faster Promotion)

Pre-provision SIT infrastructure **before** the promotion is needed:

```
Standard (8 steps):           Warm Tenant (4 steps):
1. Pre-flight validation      1. Validate warm tenant ✓
2. Terraform provisioning     2. Export DEV data
3. DB export from DEV         3. Import to SIT
4. File export from DEV       4. Redeploy + validate
5. Transfer DEV → SIT
6. DB import to SIT
7. File import + redeploy
8. Post-promotion validation
```

Steps 2-5 of the standard process are eliminated because infrastructure already exists.

## Quick Start

```bash
# Step 1: Provision a warm tenant (can be done days/weeks before promotion)
./scripts/warm_tenant_provision.sh <tenant-name> --alb-priority <num>

# Step 2: When ready to promote, run quick promote
./scripts/quick_promote.sh <tenant-name>

# Utility: List all warm tenants
./scripts/list_warm_tenants.sh

# Utility: Validate a specific warm tenant
./scripts/validate_warm_tenant.sh <tenant-name>
```

## Scripts

### `warm_tenant_provision.sh`
Provisions a warm SIT tenant in 4 steps:
1. Generate `sit_{tenant}.tf` from template
2. Terraform init + plan + apply
3. Initialize database on SIT RDS via SSM bastion
4. Validate warm state

```bash
./scripts/warm_tenant_provision.sh cliplok --alb-priority 150
./scripts/warm_tenant_provision.sh lynfin --alb-priority 160 --dry-run
```

### `quick_promote.sh`
Promotes DEV data to an existing warm SIT tenant in 4 steps:
1. Validate warm tenant exists and is healthy
2. Export data from DEV (DB + files)
3. Import to SIT (URL replacement, DB import, file extract)
4. Force ECS redeploy + post-promotion validation

```bash
./scripts/quick_promote.sh cliplok
./scripts/quick_promote.sh lynfin --skip-export  # Data already staged
```

### `validate_warm_tenant.sh`
Runs 6 health checks on a warm tenant:
1. ECS service ACTIVE with running tasks
2. ALB target group healthy
3. HTTP returns 200/301/302
4. Secrets Manager credentials readable
5. EFS access point exists
6. DB user can connect

### `list_warm_tenants.sh`
Lists all SIT tenants filtered by `WarmTenant=true` tag with status:
- **WARM** — Infrastructure ready, empty database
- **PROMOTED** — Data imported, site live
- **STOPPED** — Desired count = 0

## Terraform Template

`terraform/warm_tenant_template.tf.tpl` is a parameterized template based on `sit_goldencrust.tf` with:
- Placeholders: `__TENANT__`, `__ALB_PRIORITY__`, `__DATE__`
- DEV ECR image hardcoded: `536580886816.dkr.ecr.eu-west-1.amazonaws.com/dev-wordpress:latest`
- `WarmTenant = "true"` tag on all resources

## Prerequisites

- AWS CLI configured with `dev` and `sit` profiles
- Active SSO sessions for both accounts
- DEV bastion running (for data export)
- SIT bastion running (for DB init and data import)
- S3 staging bucket: `wordpress-migration-temp-20250903`
