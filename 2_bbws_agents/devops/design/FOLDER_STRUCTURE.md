# DevOps Pipeline Folder Structure
## Organized Repository Layout for Tenant Deployment

**Version:** 1.0
**Date:** 2025-12-23

---

## Overview

The tenant deployment pipeline spans multiple repositories with clear separation of concerns:

1. **2_bbws_agents** - GitHub workflows, scripts, documentation
2. **2_bbws_ecs_terraform** - Terraform infrastructure code
3. **2_bbws_tenant_provisioner** - Python provisioning utilities (existing)

---

## Complete Folder Structure

```
┌─────────────────────────────────────────────────────────────────┐
│ REPOSITORY: 2_bbws_agents                                       │
│ Purpose: CI/CD workflows, scripts, configs, documentation       │
└─────────────────────────────────────────────────────────────────┘

2_bbws_agents/
├── .github/
│   ├── workflows/                           # GitHub Actions workflows
│   │   ├── deploy-tenant.yml               # Reusable deployment workflow
│   │   ├── tenant-goldencrust.yml          # Tenant-specific trigger
│   │   ├── tenant-sunsetbistro.yml
│   │   ├── tenant-sterlinglaw.yml
│   │   ├── tenant-ironpeak.yml
│   │   ├── tenant-premierprop.yml
│   │   ├── tenant-lenslight.yml
│   │   ├── tenant-nexgentech.yml
│   │   ├── tenant-serenity.yml
│   │   ├── tenant-bloompetal.yml
│   │   ├── tenant-precisionauto.yml
│   │   └── tenant-bbwstrustedservice.yml
│   │
│   └── actions/                             # Custom GitHub Actions
│       ├── validate-inputs/
│       │   ├── action.yml
│       │   └── index.js
│       ├── check-priority-conflict/
│       │   ├── action.yml
│       │   └── check.sh
│       └── generate-tenant-config/
│           ├── action.yml
│           └── generate.py
│
├── devops/                                  # DevOps documentation
│   ├── design/                              # Design documents
│   │   ├── TENANT_DEPLOYMENT_PIPELINE_DESIGN.md
│   │   ├── FOLDER_STRUCTURE.md             # This file
│   │   └── ARCHITECTURE_DIAGRAMS.md
│   │
│   ├── runbooks/                            # Operational runbooks
│   │   ├── SIT_TENANT_DEPLOYMENT_RUNBOOK.md
│   │   └── PRODUCTION_DEPLOYMENT_RUNBOOK.md
│   │
│   ├── scripts/                             # DevOps utility scripts
│   │   ├── validate_alb_priority.sh
│   │   ├── check_terraform_state.sh
│   │   └── cleanup_failed_deployment.sh
│   │
│   ├── TENANT_LIFECYCLE_GUIDE.md
│   └── README.md
│
├── utils/                                   # Utility scripts (existing)
│   ├── tenant_migration.py                 # Existing
│   ├── deploy_tenant.sh                    # Existing
│   ├── generate_tenant_tf.sh               # Existing
│   ├── create_database.sh                  # Existing
│   ├── create_iam_policy.sh                # Existing
│   ├── verify_deployment.sh                # Existing
│   └── health_check_sit.sh                 # Existing
│
├── config/                                  # Tenant configuration documents
│   ├── dev/
│   │   ├── goldencrust.json
│   │   ├── sunsetbistro.json
│   │   └── ... (13 tenants)
│   ├── sit/
│   │   ├── goldencrust.json
│   │   └── ...
│   └── prod/
│       ├── goldencrust.json
│       └── ...
│
└── cost/                                    # Cost analysis scripts (existing)
    ├── analyze_costs.py
    ├── service_breakdown.py
    └── lambda_cost_reporter.py


┌─────────────────────────────────────────────────────────────────┐
│ REPOSITORY: 2_bbws_ecs_terraform                               │
│ Purpose: Terraform infrastructure as code                       │
└─────────────────────────────────────────────────────────────────┘

2_bbws_ecs_terraform/
├── terraform/
│   ├── modules/                             # Reusable Terraform modules
│   │   ├── tenant-infrastructure/           # Main tenant module (Phase 1-3)
│   │   │   ├── main.tf
│   │   │   ├── variables.tf
│   │   │   ├── outputs.tf
│   │   │   ├── versions.tf
│   │   │   └── README.md
│   │   │
│   │   ├── ecs-tenant/                      # Phase 1: ECS infrastructure
│   │   │   ├── main.tf
│   │   │   ├── efs.tf                       # EFS access point
│   │   │   ├── ecs.tf                       # Task definition + service
│   │   │   ├── alb.tf                       # Target group + listener rule
│   │   │   ├── variables.tf
│   │   │   ├── outputs.tf
│   │   │   ├── versions.tf
│   │   │   └── README.md
│   │   │
│   │   ├── database/                        # Phase 2: Database creation
│   │   │   ├── main.tf                      # Null resource wrapper
│   │   │   ├── secrets.tf                   # Secrets Manager
│   │   │   ├── iam.tf                       # IAM policies
│   │   │   ├── scripts/
│   │   │   │   ├── create_database.sh       # Bash wrapper
│   │   │   │   └── init_db.py               # Symlink to 2_bbws_agents/utils/init_tenant_db.py
│   │   │   ├── variables.tf
│   │   │   ├── outputs.tf
│   │   │   └── README.md
│   │   │
│   │   ├── dns-cloudfront/                  # Phase 3: DNS + CloudFront
│   │   │   ├── main.tf
│   │   │   ├── route53.tf                   # Route53 records
│   │   │   ├── cloudfront.tf                # CloudFront (if needed)
│   │   │   ├── variables.tf
│   │   │   ├── outputs.tf
│   │   │   └── README.md
│   │   │
│   │   └── shared/                          # Shared infrastructure modules
│   │       ├── vpc/
│   │       ├── ecs-cluster/
│   │       ├── rds/
│   │       ├── efs/
│   │       ├── alb/
│   │       └── cloudfront/
│   │
│   ├── tenants/                             # Per-tenant Terraform configs
│   │   ├── goldencrust/
│   │   │   ├── main.tf                      # Calls modules
│   │   │   ├── backend.tf                   # S3 backend config
│   │   │   ├── providers.tf                 # AWS provider config
│   │   │   ├── variables.tf                 # Tenant-specific vars
│   │   │   ├── dev.tfvars                   # DEV environment values
│   │   │   ├── sit.tfvars                   # SIT environment values
│   │   │   ├── prod.tfvars                  # PROD environment values
│   │   │   └── README.md
│   │   │
│   │   ├── sunsetbistro/
│   │   │   └── ... (same structure)
│   │   │
│   │   ├── sterlinglaw/
│   │   │   └── ...
│   │   │
│   │   └── ... (13 tenant folders total)
│   │
│   ├── environments/                        # Environment-specific configs
│   │   ├── dev/
│   │   │   ├── backend-dev.hcl              # S3 backend config
│   │   │   ├── dev.tfvars                   # Common DEV variables
│   │   │   └── README.md
│   │   ├── sit/
│   │   │   ├── backend-sit.hcl
│   │   │   ├── sit.tfvars
│   │   │   └── README.md
│   │   └── prod/
│   │       ├── backend-prod.hcl
│   │       ├── prod.tfvars
│   │       └── README.md
│   │
│   └── scripts/                             # Terraform helper scripts
│       ├── migrate_tenant_to_wpdev.py       # Existing
│       ├── init_tenant.sh                   # Initialize new tenant
│       ├── validate_tenant_config.sh        # Validate tfvars
│       └── destroy_tenant.sh                # Safe tenant destruction
│
└── README.md


┌─────────────────────────────────────────────────────────────────┐
│ REPOSITORY: 2_bbws_tenant_provisioner (Existing)               │
│ Purpose: Python-based tenant provisioning utilities             │
└─────────────────────────────────────────────────────────────────┘

2_bbws_tenant_provisioner/
├── src/
│   └── provisioner/
│       ├── provision_tenant.py              # Single tenant provisioner
│       ├── provision_tenants.py             # Batch provisioner
│       ├── export_tenant.py                 # Tenant export
│       ├── import_tenant.py                 # Tenant import
│       ├── init_tenant_db.py                # Database initialization
│       └── tenant_configs.py                # Tenant registry
└── README.md


┌─────────────────────────────────────────────────────────────────┐
│ AWS S3 STRUCTURE                                                │
│ Purpose: Terraform state storage and tenant configs             │
└─────────────────────────────────────────────────────────────────┘

S3 Buckets:
├── bbws-terraform-state-dev/
│   ├── tenants/
│   │   ├── goldencrust/
│   │   │   └── terraform.tfstate
│   │   ├── sunsetbistro/
│   │   │   └── terraform.tfstate
│   │   └── ... (13 tenants)
│   └── shared/
│       ├── vpc/terraform.tfstate
│       ├── ecs-cluster/terraform.tfstate
│       └── ...
│
├── bbws-terraform-state-sit/
│   └── ... (same structure)
│
├── bbws-terraform-state-prod/
│   └── ... (same structure)
│
└── bbws-tenant-configs/                     # Tenant configuration backups
    ├── dev/
    │   ├── goldencrust-config.json
    │   └── ...
    ├── sit/
    │   └── ...
    └── prod/
        └── ...
```

---

## Detailed Module Structure

### 1. ECS Tenant Module

**Location:** `2_bbws_ecs_terraform/terraform/modules/ecs-tenant/`

```
ecs-tenant/
├── main.tf                     # Main orchestration
├── efs.tf                      # EFS access point resource
│   └── aws_efs_access_point.tenant
│
├── ecs.tf                      # ECS resources
│   ├── aws_ecs_task_definition.tenant
│   └── aws_ecs_service.tenant
│
├── alb.tf                      # ALB resources
│   ├── aws_lb_target_group.tenant
│   └── aws_lb_listener_rule.tenant
│
├── iam.tf                      # IAM resources (if needed)
│   └── aws_iam_role_policy.ecs_efs_access
│
├── variables.tf                # Input variables
│   ├── var.tenant_name
│   ├── var.environment
│   ├── var.alb_priority
│   ├── var.efs_id
│   ├── var.cluster_name
│   └── ...
│
├── outputs.tf                  # Output values
│   ├── output.ecs_service_arn
│   ├── output.ecs_service_name
│   ├── output.target_group_arn
│   ├── output.access_point_id
│   └── ...
│
├── versions.tf                 # Terraform version constraints
│   └── terraform { required_version = ">= 1.6.0" }
│
└── README.md                   # Module documentation
```

### 2. Database Module

**Location:** `2_bbws_ecs_terraform/terraform/modules/database/`

```
database/
├── main.tf                     # Null resource for Python script
│   └── resource "null_resource" "create_database"
│
├── secrets.tf                  # Secrets Manager resources
│   └── aws_secretsmanager_secret.tenant_db_credentials
│
├── iam.tf                      # IAM policies
│   └── aws_iam_role_policy.secret_access
│
├── scripts/
│   ├── create_database.sh      # Wrapper script
│   └── init_db.py              # Symlink to actual script
│
├── variables.tf                # Input variables
│   ├── var.tenant_name
│   ├── var.environment
│   ├── var.rds_master_secret_arn
│   └── ...
│
├── outputs.tf                  # Output values
│   ├── output.database_name
│   ├── output.secret_arn
│   └── output.secret_name
│
└── README.md
```

### 3. DNS CloudFront Module

**Location:** `2_bbws_ecs_terraform/terraform/modules/dns-cloudfront/`

```
dns-cloudfront/
├── main.tf                     # Main orchestration
├── route53.tf                  # Route53 resources
│   └── aws_route53_record.tenant
│
├── cloudfront.tf               # CloudFront (if needed)
│   └── aws_cloudfront_distribution.tenant
│
├── variables.tf                # Input variables
│   ├── var.tenant_name
│   ├── var.environment
│   ├── var.route53_zone_id
│   └── ...
│
├── outputs.tf                  # Output values
│   ├── output.dns_name
│   └── output.cloudfront_domain
│
└── README.md
```

### 4. Tenant Configuration Files

**Location:** `2_bbws_ecs_terraform/terraform/tenants/goldencrust/`

```
goldencrust/
├── main.tf                     # Module calls
│   ├── module "ecs_tenant" { source = "../../modules/ecs-tenant" }
│   ├── module "database" { source = "../../modules/database" }
│   └── module "dns_cloudfront" { source = "../../modules/dns-cloudfront" }
│
├── backend.tf                  # S3 backend configuration
│   └── terraform {
│         backend "s3" {
│           # Configured via -backend-config
│         }
│       }
│
├── providers.tf                # AWS provider
│   └── provider "aws" {
│         region = var.region
│         profile = var.aws_profile
│       }
│
├── variables.tf                # Variable declarations
│   ├── variable "environment" {}
│   ├── variable "alb_priority" {}
│   ├── variable "region" {}
│   └── ...
│
├── dev.tfvars                  # DEV environment values
│   └── environment = "dev"
│       alb_priority = 40
│       region = "eu-west-1"
│       aws_profile = "Tebogo-dev"
│
├── sit.tfvars                  # SIT environment values
│   └── environment = "sit"
│       alb_priority = 140
│       region = "eu-west-1"
│       aws_profile = "Tebogo-sit"
│
├── prod.tfvars                 # PROD environment values
│   └── environment = "prod"
│       alb_priority = 240
│       region = "af-south-1"
│       aws_profile = "Tebogo-prod"
│
└── README.md                   # Tenant-specific documentation
```

---

## File Naming Conventions

### Terraform Files
- **Main logic:** `main.tf`
- **Resource-specific:** `{resource}.tf` (e.g., `efs.tf`, `ecs.tf`, `alb.tf`)
- **Variables:** `variables.tf`
- **Outputs:** `outputs.tf`
- **Backend:** `backend.tf`
- **Providers:** `providers.tf`
- **Versions:** `versions.tf`

### Environment Files
- **Variable files:** `{env}.tfvars` (e.g., `dev.tfvars`, `sit.tfvars`)
- **Backend configs:** `backend-{env}.hcl`

### Scripts
- **Bash scripts:** `{action}_{resource}.sh` (e.g., `create_database.sh`)
- **Python scripts:** `{action}_{resource}.py` (e.g., `init_tenant_db.py`)

### Configuration Files
- **Tenant configs:** `{tenant_name}.json`
- **Stored in:** `config/{env}/{tenant_name}.json`

---

## Cross-Repository References

### GitHub Actions References Terraform

**In:** `2_bbws_agents/.github/workflows/deploy-tenant.yml`

```yaml
- name: Terraform Init
  working-directory: ../2_bbws_ecs_terraform/terraform/tenants/${{ inputs.tenant_name }}
  run: terraform init
```

**Solution:** Use relative paths or clone both repos in workflow:

```yaml
steps:
  - name: Checkout 2_bbws_agents
    uses: actions/checkout@v4
    with:
      path: 2_bbws_agents

  - name: Checkout 2_bbws_ecs_terraform
    uses: actions/checkout@v4
    with:
      repository: owner/2_bbws_ecs_terraform
      path: 2_bbws_ecs_terraform
      token: ${{ secrets.GITHUB_TOKEN }}

  - name: Terraform Init
    working-directory: 2_bbws_ecs_terraform/terraform/tenants/${{ inputs.tenant_name }}
    run: terraform init
```

### Database Module References Python Script

**In:** `2_bbws_ecs_terraform/terraform/modules/database/scripts/create_database.sh`

```bash
# Option 1: Symlink (recommended)
ln -s ../../../../../2_bbws_agents/utils/init_tenant_db.py init_db.py

# Option 2: Copy script during workflow
cp 2_bbws_agents/utils/init_tenant_db.py 2_bbws_ecs_terraform/terraform/modules/database/scripts/

# Option 3: Direct path reference
python3 ../../../../../2_bbws_agents/utils/init_tenant_db.py
```

---

## Migration from Current Structure

### Step 1: Create New Folders

```bash
# In 2_bbws_ecs_terraform
cd /path/to/2_bbws_ecs_terraform
mkdir -p terraform/modules/{ecs-tenant,database,dns-cloudfront}
mkdir -p terraform/tenants
mkdir -p terraform/environments/{dev,sit,prod}

# In 2_bbws_agents
cd /path/to/2_bbws_agents
mkdir -p .github/{workflows,actions}
mkdir -p devops/{design,runbooks,scripts}
mkdir -p config/{dev,sit,prod}
```

### Step 2: Move Existing Files

```bash
# Move existing tenant Terraform files
cd /path/to/2_bbws_ecs_terraform/terraform
mv dev_goldencrust.tf tenants/goldencrust/main.tf
mv sit_goldencrust.tf tenants/goldencrust/sit.tfvars

# Move scripts
cd /path/to/2_bbws_agents
mv devops/*.sh devops/scripts/
```

### Step 3: Create Module Templates

```bash
# Copy existing tenant file as module template
cd /path/to/2_bbws_ecs_terraform/terraform/modules/ecs-tenant
# Extract resources from existing dev_goldencrust.tf into module
```

### Step 4: Update References

- Update workflow files to point to new locations
- Update script paths
- Update documentation

---

## Best Practices

### 1. Module Reusability
- Keep modules generic and parameterized
- No hardcoded values in modules
- All environment-specific values in `.tfvars` files

### 2. State Management
- One state file per tenant per environment
- Use workspaces for environment isolation
- Store in S3 with versioning enabled

### 3. Code Organization
- Group related resources in separate files
- Use consistent naming conventions
- Keep `main.tf` as orchestration only

### 4. Documentation
- README.md in every folder
- Inline comments for complex logic
- Examples in module documentation

### 5. Version Control
- `.gitignore` for sensitive files:
  ```
  *.tfstate
  *.tfstate.backup
  .terraform/
  *.tfvars (exclude from git, use .tfvars.example)
  ```

---

## Folder Ownership

| Folder | Owner | Purpose |
|--------|-------|---------|
| `.github/workflows/` | DevOps Team | CI/CD pipelines |
| `terraform/modules/` | Infrastructure Team | Reusable modules |
| `terraform/tenants/` | DevOps Team | Tenant configs |
| `devops/design/` | Architects | Design docs |
| `devops/runbooks/` | SRE Team | Operations |
| `utils/` | DevOps Team | Utility scripts |
| `config/` | Auto-generated | Tenant configs |

---

## Next Steps

1. ✅ Create folder structure in both repositories
2. ✅ Create Terraform modules (ecs-tenant, database, dns-cloudfront)
3. ✅ Create tenant configuration folders (13 tenants)
4. ✅ Move existing scripts to proper locations
5. ✅ Update GitHub workflows to reference new paths
6. ✅ Create README files for each major folder
7. ✅ Update TENANT_DEPLOYMENT_PIPELINE_DESIGN.md with correct paths

---

**Document Version:** 1.0
**Last Updated:** 2025-12-23
**Next Review:** 2025-12-30
