# BBWS DevOps Documentation

## Quick Start

### Deploy a New Tenant (Automated)

```bash
cd /path/to/2_bbws_agents/utils

# Single command deployment
./deploy_tenant.sh myclient sit 190

# This will:
# 1. Generate Terraform config
# 2. Create database and user
# 3. Create IAM policies
# 4. Deploy infrastructure
# 5. Verify deployment
```

### Individual Steps (Manual Process)

```bash
# 1. Generate Terraform configuration
./generate_tenant_tf.sh myclient 190 sit

# 2. Create database
./create_database.sh myclient sit

# 3. Create IAM policy
./create_iam_policy.sh myclient sit

# 4. Deploy with Terraform
cd ../2_bbws_ecs_terraform/terraform
terraform init -backend-config=environments/sit/backend-sit.hcl
terraform workspace select sit
terraform apply -var-file=environments/sit/sit.tfvars \
  -target=aws_ecs_service.sit_myclient

# 5. Verify
cd ../../2_bbws_agents/utils
./verify_deployment.sh myclient sit
```

## Documentation

| Document | Description |
|----------|-------------|
| **[TENANT_LIFECYCLE_GUIDE.md](./TENANT_LIFECYCLE_GUIDE.md)** | **COMPLETE LIFECYCLE DOCUMENTATION** - Everything you need |
| [SIT_TENANT_DEPLOYMENT_RUNBOOK.md](./runbooks/SIT_TENANT_DEPLOYMENT_RUNBOOK.md) | Batch deployment runbook |

## Available Scripts (NEW!)

### Bash Scripts

| Script | Purpose | Usage |
|--------|---------|-------|
| **`deploy_tenant.sh`** | **🎯 Master deployment script** | `./deploy_tenant.sh <tenant> <env> <priority>` |
| `generate_tenant_tf.sh` | Generate Terraform config | `./generate_tenant_tf.sh <tenant> <priority> <env>` |
| `create_database.sh` | Create DB and secret | `./create_database.sh <tenant> <env>` |
| `create_iam_policy.sh` | Create IAM policies | `./create_iam_policy.sh <tenant> <env>` |
| `verify_deployment.sh` | Verify deployment | `./verify_deployment.sh <tenant> <env>` |
| `health_check_sit.sh` | Health check all tenants | `./health_check_sit.sh` |

### Python Utilities

| Script | Purpose | Usage |
|--------|---------|-------|
| `tenant_migration.py` | Migrate tenants with rollback | `python3 tenant_migration.py migrate --tenant <name> --from-config <file> --to-config <file>` |
| `analyze_costs.py` | Multi-env cost analysis | `python3 cost/analyze_costs.py` |
| `service_breakdown.py` | Service cost breakdown | `python3 cost/service_breakdown.py` |
| `lambda_cost_reporter.py` | Lambda cost reporter | Deploy as Lambda function |

See [TENANT_LIFECYCLE_GUIDE.md](./TENANT_LIFECYCLE_GUIDE.md#python-utilities) for detailed Python documentation.

## Current Status (2025-12-21)

### DEV Environment
- **Status:** ✅ Fully operational
- **Tenants:** 13 deployed
- **URL:** `https://{tenant}.wpdev.kimmyai.io`

### SIT Environment
- **Status:** ⚠️ Partially deployed (2 working, 2 issues, 9 pending)
- **Tenants:** 4/13 deployed
- **URL:** `https://{tenant}.wpsit.kimmyai.io`
- **Auth:** bbws-sit / (see secrets manager)

**Working:**
- ✅ goldencrust: HTTP 200, fully operational
- ✅ sunsetbistro: HTTP 200, fully operational

**Issues:**
- ⚠️ sterlinglaw: HTTP 500 (database connection)
- ⏳ tenant1: Task starting (IAM policy fixed)

**Pending:** tenant2, ironpeak, premierprop, lenslight, nexgentech, serenity, bloompetal, precisionauto, bbwstrustedservice

### PROD Environment
- **Status:** 🚧 Infrastructure deployed, no tenants
- **Region:** af-south-1 (Primary), eu-west-1 (DR)

## Critical Pitfalls & Lessons Learned

⚠️ **READ THIS BEFORE DEPLOYING**

1. **Resource Naming:** MUST prefix with environment (`sit_`, `prod_`)
2. **Secrets:** Create manually FIRST, import to Terraform after
3. **IAM Policies:** Required for EACH tenant's secret access
4. **WordPress Image:** Use `wordpress:latest`, NOT custom ECR
5. **Database Names:** Use underscores (`tenant_db`), not dashes
6. **Terraform State:** Import existing resources to avoid conflicts
7. **ALB Priority:** MUST be unique (10-260), check before deploying
8. **Secret ARN Changes:** Terraform may recreate secrets with new ARNs

See [TENANT_LIFECYCLE_GUIDE.md](./TENANT_LIFECYCLE_GUIDE.md) for complete details.

## Architecture

```
CloudFront (CDN + Basic Auth)
    ↓
ALB (Host-based routing)
    ↓
ECS Fargate (WordPress containers)
    ├─→ RDS MySQL (shared instance, per-tenant DBs)
    └─→ EFS (per-tenant access points)
```

## Promotion Workflow (Planned)

```
DEV → SIT (Manual) → PROD (Manual + Approval)
```

**Current:** Manual using scripts above
**Future:** GitHub Actions automation

## What Works vs What Doesn't

### ✅ What Works
- Base infrastructure (ECS, RDS, ALB, EFS, CloudFront)
- Single tenant deployment via scripts
- Database creation via ECS tasks
- Secret management
- Basic Auth on CloudFront
- Health checks and monitoring

### ❌ What Doesn't Work
- Terraform secret creation (conflicts with manual creation)
- GitHub Actions workflows (not implemented)
- Content migration DEV→SIT (not automated)
- Batch deployment automation
- Terraform applies may need multiple retries due to state issues

### 🚧 Partially Working
- Batch tenant deployment (manual process documented)
- Resource naming consistency (needs cleanup)
- Error handling in scripts (basic coverage)

## Improvements Needed

### High Priority
1. Fix Terraform state management (remove secret creation)
2. Complete SIT deployment (9 pending tenants)
3. Implement content migration scripts
4. Create GitHub Actions workflows

### Medium Priority
5. Better error handling in scripts
6. Automated testing in SIT
7. Performance monitoring dashboards
8. Cost optimization review

### Low Priority
9. Self-service tenant portal
10. Auto-scaling configuration
11. Advanced caching strategies

## Support & Troubleshooting

**Documentation:** See TENANT_LIFECYCLE_GUIDE.md sections:
- Troubleshooting Guide
- Common Error Resolutions
- Quick Diagnostics

**Logs:**
```bash
# SIT logs
aws logs tail /ecs/sit --filter-pattern '{tenant}' --follow --profile Tebogo-sit

# DEV logs
aws logs tail /ecs/dev --filter-pattern '{tenant}' --follow --profile Tebogo-dev
```

**Health Checks:**
```bash
./health_check_sit.sh
./verify_deployment.sh {tenant} sit
```

## Related Agents

- ECS Cluster Manager - Infrastructure provisioning
- Tenant Manager - Tenant lifecycle management
- Backup Manager - Pre-deployment backups
- Monitoring Agent - Deployment monitoring

---

**Last Updated:** 2025-12-21
**Documentation Status:** Complete with automation scripts
