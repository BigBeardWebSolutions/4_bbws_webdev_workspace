# Custom GitHub Actions

This directory contains reusable composite actions for tenant deployment workflows.

## Available Actions

### 1. validate-inputs ✅

**Purpose:** Validates tenant deployment inputs and generates environment-specific configuration.

**Location:** `.github/actions/validate-inputs/action.yml`

**Inputs:**
- `tenant_name` - Tenant identifier (lowercase alphanumeric)
- `environment` - Target environment (dev, sit, prod)
- `alb_priority` - ALB listener rule priority (1-50000)

**Outputs:**
- `domain_name` - Generated domain name (e.g., `goldencrust.wpsit.kimmyai.io`)
- `aws_profile` - AWS CLI profile for the environment
- `domain_suffix` - Environment domain suffix

**Validation Rules:**
- Tenant name must be lowercase alphanumeric only
- Environment must be dev, sit, or prod
- ALB priority must be 1-50000

---

### 2. check-priority-conflict ✅

**Purpose:** Checks if the specified ALB priority conflicts with existing listener rules.

**Location:** `.github/actions/check-priority-conflict/action.yml`

**Inputs:**
- `tenant_name` - Tenant identifier
- `environment` - Target environment
- `alb_priority` - ALB listener rule priority to check
- `aws_region` - AWS region

**Outputs:**
- `conflict_found` - Boolean indicating if conflict was found
- `existing_tenant` - Tenant name using the priority (if conflict found)

**AWS Permissions Required:**
- `elasticloadbalancing:DescribeListeners`
- `elasticloadbalancing:DescribeRules`
- `elasticloadbalancing:DescribeTags`

---

### 3. generate-tenant-config ✅

**Purpose:** Generates a JSON configuration file documenting the deployed tenant infrastructure.

**Location:** `.github/actions/generate-tenant-config/action.yml`

**Inputs:**
- `tenant_name` - Tenant identifier
- `environment` - Target environment
- `domain_name` - Tenant domain name
- `alb_priority` - ALB listener rule priority
- `workflow_run_id` - GitHub workflow run ID
- `aws_region` - AWS region

**Outputs:**
- `config_file` - Path to generated config (e.g., `config/sit/goldencrust.json`)

**AWS Permissions Required:**
- `ecs:DescribeServices`
- `elasticloadbalancing:DescribeTargetGroups`
- `elasticfilesystem:DescribeAccessPoints`
- `secretsmanager:ListSecrets`
- `rds:DescribeDBInstances`

---

## Usage Examples

### Validate Inputs

```yaml
- uses: ./.github/actions/validate-inputs
  id: validate
  with:
    tenant_name: 'goldencrust'
    environment: 'sit'
    alb_priority: 140

- name: Use Outputs
  run: |
    echo "Domain: ${{ steps.validate.outputs.domain_name }}"
```

### Check Priority Conflict

```yaml
- uses: ./.github/actions/check-priority-conflict
  id: check
  with:
    tenant_name: 'goldencrust'
    environment: 'sit'
    alb_priority: 140
    aws_region: 'eu-west-1'

- name: Handle Conflict
  if: steps.check.outputs.conflict_found == 'true'
  run: exit 1
```

### Generate Configuration

```yaml
- uses: ./.github/actions/generate-tenant-config
  id: generate
  with:
    tenant_name: 'goldencrust'
    environment: 'sit'
    domain_name: 'goldencrust.wpsit.kimmyai.io'
    alb_priority: 140
    workflow_run_id: ${{ github.run_id }}
    aws_region: 'eu-west-1'

- name: Commit Configuration
  run: |
    git add ${{ steps.generate.outputs.config_file }}
    git commit -m "Update tenant config"
```

---

## Related Documentation

- [Reusable Workflow](../workflows/deploy-tenant.yml)
- [Tenant Workflows](../workflows/)
- [Pipeline Design](../../devops/design/TENANT_DEPLOYMENT_PIPELINE_DESIGN.md)
