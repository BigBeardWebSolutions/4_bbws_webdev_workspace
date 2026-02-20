# GitHub Actions Workflow Path Reference
## Correct Repository Paths for Multi-Repo Setup

**Version:** 1.0
**Date:** 2025-12-23

---

## Overview

The tenant deployment pipeline spans two repositories:
1. **2_bbws_agents** - Workflows, scripts, configs
2. **2_bbws_ecs_terraform** - Terraform infrastructure code

This document provides correct path references for GitHub Actions workflows.

---

## Repository Checkout Pattern

### In All Workflow Jobs

```yaml
steps:
  # Checkout 2_bbws_agents (contains workflows and scripts)
  - name: Checkout 2_bbws_agents
    uses: actions/checkout@v4
    with:
      path: 2_bbws_agents

  # Checkout 2_bbws_ecs_terraform (contains Terraform code)
  - name: Checkout 2_bbws_ecs_terraform
    uses: actions/checkout@v4
    with:
      repository: ${{ github.repository_owner }}/2_bbws_ecs_terraform
      path: 2_bbws_ecs_terraform
      token: ${{ secrets.GITHUB_TOKEN }}
```

---

## Correct Working Directory Paths

### Phase 1: ECS Infrastructure (Terraform)

```yaml
- name: Terraform Init
  working-directory: 2_bbws_ecs_terraform/terraform/tenants/${{ inputs.tenant_name }}
  run: |
    terraform init \
      -backend-config="../../environments/${{ inputs.environment }}/backend-${{ inputs.environment }}.hcl"

- name: Terraform Plan - ECS Module
  working-directory: 2_bbws_ecs_terraform/terraform/tenants/${{ inputs.tenant_name }}
  run: |
    terraform plan \
      -var-file=${{ inputs.environment }}.tfvars \
      -var="alb_priority=${{ inputs.alb_priority }}" \
      -target=module.ecs_tenant \
      -out=ecs-plan.tfplan

- name: Terraform Apply - ECS Module
  working-directory: 2_bbws_ecs_terraform/terraform/tenants/${{ inputs.tenant_name }}
  run: terraform apply -auto-approve ecs-plan.tfplan
```

### Phase 2: Database Creation (Python)

```yaml
- name: Install dependencies
  run: pip install boto3 pymysql

- name: Create Database
  run: |
    python3 2_bbws_agents/utils/init_tenant_db.py \
      '${{ steps.rds-creds.outputs.master_creds }}' \
      '{"database":"${{ inputs.tenant_name }}_db",...}'

- name: Create IAM Policy
  run: |
    bash 2_bbws_agents/utils/create_iam_policy.sh \
      ${{ inputs.tenant_name }} \
      ${{ inputs.environment }}
```

### Phase 3: Testing

```yaml
- name: Run Deployment Verification
  run: |
    bash 2_bbws_agents/utils/verify_deployment.sh \
      ${{ inputs.tenant_name }} \
      ${{ inputs.environment }}
```

### Phase 3: DNS + CloudFront

```yaml
- name: Terraform Apply - DNS Module
  working-directory: 2_bbws_ecs_terraform/terraform/tenants/${{ inputs.tenant_name }}
  run: |
    terraform apply \
      -var-file=${{ inputs.environment }}.tfvars \
      -target=module.dns_cloudfront \
      -auto-approve
```

---

## Script Path Reference

### From 2_bbws_agents Repository

| Script | Full Path in Workflow |
|--------|----------------------|
| init_tenant_db.py | `2_bbws_agents/utils/init_tenant_db.py` |
| verify_deployment.sh | `2_bbws_agents/utils/verify_deployment.sh` |
| create_iam_policy.sh | `2_bbws_agents/utils/create_iam_policy.sh` |
| deploy_tenant.sh | `2_bbws_agents/utils/deploy_tenant.sh` |
| create_database.sh | `2_bbws_agents/utils/create_database.sh` |

### From 2_bbws_ecs_terraform Repository

| Resource | Full Path in Workflow |
|----------|----------------------|
| Tenant main.tf | `2_bbws_ecs_terraform/terraform/tenants/{tenant}/main.tf` |
| Backend config | `2_bbws_ecs_terraform/terraform/environments/{env}/backend-{env}.hcl` |
| Environment tfvars | `2_bbws_ecs_terraform/terraform/tenants/{tenant}/{env}.tfvars` |
| ECS module | `2_bbws_ecs_terraform/terraform/modules/ecs-tenant/` |
| Database module | `2_bbws_ecs_terraform/terraform/modules/database/` |
| DNS module | `2_bbws_ecs_terraform/terraform/modules/dns-cloudfront/` |

---

## Configuration File Paths

### Generated Tenant Configs

```yaml
- name: Generate Tenant Configuration
  run: |
    mkdir -p 2_bbws_agents/config/${{ inputs.environment }}
    cat > 2_bbws_agents/config/${{ inputs.environment }}/${{ inputs.tenant_name }}.json <<EOF
    {...}
    EOF

- name: Commit Configuration
  run: |
    cd 2_bbws_agents
    git config user.name "GitHub Actions Bot"
    git config user.email "actions@github.com"
    git add config/${{ inputs.environment }}/${{ inputs.tenant_name }}.json
    git commit -m "Add tenant config: ${{ inputs.tenant_name }} (${{ inputs.environment }})"
    git push
```

---

## Terraform Backend Configuration

### Backend HCL Files

**Location:** `2_bbws_ecs_terraform/terraform/environments/{env}/backend-{env}.hcl`

**Example:** `backend-sit.hcl`
```hcl
bucket         = "bbws-terraform-state-sit"
key            = "tenants/TENANT_NAME/terraform.tfstate"
region         = "eu-west-1"
dynamodb_table = "bbws-terraform-locks-sit"
encrypt        = true
```

**Usage in Workflow:**
```yaml
terraform init \
  -backend-config="../../environments/${{ inputs.environment }}/backend-${{ inputs.environment }}.hcl" \
  -backend-config="key=tenants/${{ inputs.tenant_name }}/terraform.tfstate"
```

---

## Module Source Paths

### In Tenant main.tf

**File:** `2_bbws_ecs_terraform/terraform/tenants/goldencrust/main.tf`

```hcl
# Correct relative paths from tenant folder to modules
module "ecs_tenant" {
  source = "../../modules/ecs-tenant"
  # ...
}

module "database" {
  source = "../../modules/database"
  # ...
}

module "dns_cloudfront" {
  source = "../../modules/dns-cloudfront"
  # ...
}
```

---

## Artifact Paths

### Upload Test Reports

```yaml
- name: Upload Test Report
  uses: actions/upload-artifact@v4
  with:
    name: test-report-${{ inputs.tenant_name }}-${{ inputs.environment }}
    path: |
      /tmp/verify_*.log
      2_bbws_agents/config/${{ inputs.environment }}/${{ inputs.tenant_name }}.json
```

---

## Environment Variables

### Set in Workflow

```yaml
env:
  TERRAFORM_DIR: 2_bbws_ecs_terraform/terraform/tenants/${{ inputs.tenant_name }}
  SCRIPTS_DIR: 2_bbws_agents/utils
  CONFIG_DIR: 2_bbws_agents/config/${{ inputs.environment }}

steps:
  - name: Run Terraform
    working-directory: ${{ env.TERRAFORM_DIR }}
    run: terraform apply

  - name: Run Verification
    run: bash ${{ env.SCRIPTS_DIR }}/verify_deployment.sh
```

---

## Common Mistakes to Avoid

### ❌ Wrong: Single Checkout

```yaml
# This only checks out 2_bbws_agents
- name: Checkout
  uses: actions/checkout@v4

# Terraform files won't be available!
- name: Terraform Init
  working-directory: terraform/tenants/goldencrust  # WRONG PATH
```

### ✅ Correct: Dual Checkout

```yaml
# Checkout both repositories
- name: Checkout 2_bbws_agents
  uses: actions/checkout@v4
  with:
    path: 2_bbws_agents

- name: Checkout 2_bbws_ecs_terraform
  uses: actions/checkout@v4
  with:
    repository: owner/2_bbws_ecs_terraform
    path: 2_bbws_ecs_terraform

# Now both are available
- name: Terraform Init
  working-directory: 2_bbws_ecs_terraform/terraform/tenants/goldencrust
```

### ❌ Wrong: Absolute Paths

```yaml
# Don't use absolute paths
- name: Run Script
  run: /Users/tebogotseka/Documents/.../script.sh
```

### ✅ Correct: Relative Paths

```yaml
# Use repository-relative paths
- name: Run Script
  run: bash 2_bbws_agents/utils/script.sh
```

---

## Quick Reference Cheat Sheet

```bash
# Repository roots (after checkout)
2_bbws_agents/                  → Workflows, scripts, configs
2_bbws_ecs_terraform/          → Terraform infrastructure

# Terraform working directory
2_bbws_ecs_terraform/terraform/tenants/{TENANT}/

# Scripts
2_bbws_agents/utils/{SCRIPT}

# Configs
2_bbws_agents/config/{ENV}/{TENANT}.json

# Modules
2_bbws_ecs_terraform/terraform/modules/{MODULE}/

# Backend configs
2_bbws_ecs_terraform/terraform/environments/{ENV}/backend-{ENV}.hcl
```

---

## Testing Path References

### Local Testing

```bash
# Simulate GitHub Actions workspace structure
mkdir -p /tmp/gh-workspace
cd /tmp/gh-workspace

# Clone repos
git clone https://github.com/owner/2_bbws_agents.git
git clone https://github.com/owner/2_bbws_ecs_terraform.git

# Test paths
cd 2_bbws_ecs_terraform/terraform/tenants/goldencrust
terraform init -backend-config=../../environments/dev/backend-dev.hcl

cd /tmp/gh-workspace
python3 2_bbws_agents/utils/init_tenant_db.py
```

---

## Path Summary Table

| Resource Type | Repository | Path from Workflow Root |
|--------------|------------|------------------------|
| GitHub Workflow | 2_bbws_agents | `.github/workflows/deploy-tenant.yml` |
| Tenant Terraform | 2_bbws_ecs_terraform | `terraform/tenants/{tenant}/main.tf` |
| Terraform Module | 2_bbws_ecs_terraform | `terraform/modules/{module}/` |
| Python Script | 2_bbws_agents | `utils/{script}.py` |
| Bash Script | 2_bbws_agents | `utils/{script}.sh` |
| Tenant Config | 2_bbws_agents | `config/{env}/{tenant}.json` |
| Backend Config | 2_bbws_ecs_terraform | `terraform/environments/{env}/backend-{env}.hcl` |
| Design Docs | 2_bbws_agents | `devops/design/{doc}.md` |

---

**Document Version:** 1.0
**Last Updated:** 2025-12-23
