# AWS Region Specification Skill

## Purpose

This skill ensures correct AWS region selection for each environment to prevent deployment errors and support the multi-region disaster recovery architecture.

## Environment-Region Mapping

**CRITICAL**: Always verify the correct region before any AWS operation.

| Environment | AWS Account | Primary Region | DR Region | Status |
|-------------|-------------|----------------|-----------|---------|
| **DEV** | 536580886816 | **eu-west-1** | N/A | Active |
| **SIT** | 815856636111 | **eu-west-1** | N/A | Active |
| **PROD** | 093646564004 | **af-south-1** | eu-west-1 | Active (Primary)<br>Passive (DR) |

## Region Strategy

### Development & Testing (DEV/SIT)
- **Region**: eu-west-1 (Ireland)
- **Rationale**:
  - Lower latency for European development team
  - Cost optimization (eu-west-1 typically has lower costs than af-south-1)
  - Faster iteration cycles
  - EU data residency for test data

### Production (PROD)
- **Primary Region**: af-south-1 (Cape Town, South Africa)
- **DR Region**: eu-west-1 (Ireland)
- **Rationale**:
  - Primary users in South Africa (lowest latency)
  - Compliance with South African data residency requirements
  - Active/Passive DR setup with hourly DynamoDB backups
  - Cross-region replication for S3 and DynamoDB
  - Route 53 health check based failover

## Multi-Region Architecture

### PROD Primary (af-south-1)
```
┌─────────────────────────────────────┐
│     af-south-1 (Primary PROD)      │
├─────────────────────────────────────┤
│ • ECS Cluster: prod-cluster         │
│ • RDS: prod-mysql                   │
│ • ALB: prod-alb                     │
│ • DynamoDB: Global Tables (source)  │
│ • S3: Cross-region replication ON   │
│ • Route 53: Primary health check    │
└─────────────────────────────────────┘
            │
            │ Hourly Backup & Replication
            ▼
┌─────────────────────────────────────┐
│      eu-west-1 (DR Standby)         │
├─────────────────────────────────────┤
│ • DynamoDB: Global Tables (replica) │
│ • S3: Cross-region replica          │
│ • RDS: Snapshot restore ready       │
│ • ECS: Infrastructure ready         │
│ • Route 53: Failover endpoint       │
└─────────────────────────────────────┘
```

### DEV/SIT (eu-west-1)
```
┌─────────────────────────────────────┐
│       eu-west-1 (DEV/SIT)           │
├─────────────────────────────────────┤
│ DEV Account (536580886816)          │
│ • ECS Cluster: dev-cluster          │
│ • RDS: dev-mysql                    │
│ • ALBs: dev-alb, Dev-BBWS-ALB       │
│ • 13 tenants                        │
├─────────────────────────────────────┤
│ SIT Account (815856636111)          │
│ • ECS Cluster: sit-cluster          │
│ • RDS: sit-mysql                    │
│ • ALB: sit-alb                      │
│ • 13 tenants (mirrors DEV)          │
└─────────────────────────────────────┘
```

## Helper Commands

### Get Correct Region for Environment

```bash
# Get region for specific environment
get_aws_region() {
  local env=$1
  case $env in
    dev|DEV)
      echo "eu-west-1"
      ;;
    sit|SIT)
      echo "eu-west-1"
      ;;
    prod|PROD)
      echo "af-south-1"
      ;;
    prod-dr|PROD-DR)
      echo "eu-west-1"
      ;;
    *)
      echo "ERROR: Unknown environment: $env" >&2
      return 1
      ;;
  esac
}

# Usage
REGION=$(get_aws_region dev)
aws ecs list-clusters --region $REGION
```

### Validate Region Before Operation

```bash
# Validate region matches environment
validate_region() {
  local env=$1
  local region=$2
  local expected_region=$(get_aws_region $env)

  if [ "$region" != "$expected_region" ]; then
    echo "ERROR: Region mismatch!" >&2
    echo "  Environment: $env" >&2
    echo "  Expected: $expected_region" >&2
    echo "  Got: $region" >&2
    return 1
  fi

  echo "✓ Region validated: $region for $env"
  return 0
}

# Usage
validate_region dev eu-west-1 || exit 1
```

### Query AWS with Automatic Region Selection

```bash
# Automatically select correct region
aws_query() {
  local env=$1
  shift  # Remove first argument

  local region=$(get_aws_region $env)
  local profile="Tebogo-$env"

  echo "Querying $env in region $region..."
  AWS_PROFILE=$profile aws --region $region "$@"
}

# Usage
aws_query dev ecs list-clusters
aws_query sit rds describe-db-instances
aws_query prod elbv2 describe-load-balancers
```

### List All Resources Across Environments

```bash
# List resources in all environments
list_all_clusters() {
  echo "=== DEV (eu-west-1) ==="
  AWS_PROFILE=Tebogo-dev aws ecs list-clusters --region eu-west-1

  echo "=== SIT (eu-west-1) ==="
  AWS_PROFILE=Tebogo-sit aws ecs list-clusters --region eu-west-1

  echo "=== PROD (af-south-1) ==="
  AWS_PROFILE=Tebogo-prod aws ecs list-clusters --region af-south-1
}
```

## Common Errors & Solutions

### Error: No Resources Found

**Symptom**: AWS CLI returns empty results or "No clusters/databases found"

**Cause**: Querying wrong region

**Solution**:
```bash
# Wrong ❌
AWS_PROFILE=Tebogo-dev aws ecs list-clusters --region af-south-1

# Correct ✅
AWS_PROFILE=Tebogo-dev aws ecs list-clusters --region eu-west-1
```

### Error: Access Denied

**Symptom**: "You are not authorized to perform this operation"

**Cause**: Using wrong AWS profile or region combination

**Solution**:
```bash
# Verify you're in the right account and region
aws sts get-caller-identity --profile Tebogo-dev
aws configure list-profiles | grep Tebogo

# Use correct profile-region mapping
AWS_PROFILE=Tebogo-dev aws ecs list-clusters --region eu-west-1
```

### Error: Cluster Not Found

**Symptom**: "Cluster 'poc-cluster' not found"

**Cause**:
1. Wrong region (poc-cluster is af-south-1, dev-cluster is eu-west-1)
2. Old cluster name (poc-cluster deprecated, use dev-cluster)

**Solution**:
```bash
# DEV uses dev-cluster in eu-west-1
AWS_PROFILE=Tebogo-dev aws ecs list-services \
  --cluster dev-cluster \
  --region eu-west-1

# PROD uses prod-cluster in af-south-1
AWS_PROFILE=Tebogo-prod aws ecs list-services \
  --cluster prod-cluster \
  --region af-south-1
```

## Safety Checks

### Pre-Deployment Region Validation

```bash
#!/bin/bash
# pre_deploy_check.sh

ENV=$1
REGION=$2

# Validate inputs
if [ -z "$ENV" ] || [ -z "$REGION" ]; then
  echo "Usage: $0 <env> <region>"
  exit 1
fi

# Expected regions
declare -A EXPECTED_REGIONS=(
  [dev]="eu-west-1"
  [sit]="eu-west-1"
  [prod]="af-south-1"
)

# Validate
EXPECTED="${EXPECTED_REGIONS[$ENV]}"
if [ "$REGION" != "$EXPECTED" ]; then
  echo "❌ DEPLOYMENT BLOCKED"
  echo "Region mismatch for $ENV:"
  echo "  Expected: $EXPECTED"
  echo "  Provided: $REGION"
  exit 1
fi

echo "✅ Region validated: $REGION for $ENV"
exit 0
```

### Terraform Region Validation

```hcl
# terraform/variables.tf

variable "environment" {
  type        = string
  description = "Environment name (dev, sit, prod)"

  validation {
    condition = contains(["dev", "sit", "prod"], var.environment)
    error_message = "Environment must be dev, sit, or prod."
  }
}

variable "aws_region" {
  type        = string
  description = "AWS region for deployment"

  validation {
    condition = (
      (var.environment == "dev" && var.aws_region == "eu-west-1") ||
      (var.environment == "sit" && var.aws_region == "eu-west-1") ||
      (var.environment == "prod" && var.aws_region == "af-south-1")
    )
    error_message = "Invalid region for environment. DEV/SIT must use eu-west-1, PROD must use af-south-1."
  }
}
```

## Disaster Recovery Procedures

### Failover from af-south-1 to eu-west-1

When PROD primary region (af-south-1) fails:

```bash
# 1. Verify primary region is down
aws cloudwatch get-metric-statistics \
  --region af-south-1 \
  --namespace AWS/ApplicationELB \
  --metric-name HealthyHostCount \
  --start-time $(date -u -d '5 minutes ago' +%Y-%m-%dT%H:%M:%S) \
  --end-time $(date -u +%Y-%m-%dT%H:%M:%S) \
  --period 300 \
  --statistics Average

# 2. Activate DR in eu-west-1
cd terraform/environments/prod-dr
terraform init
terraform apply -var="activate_dr=true"

# 3. Update Route 53 to point to eu-west-1
aws route53 change-resource-record-sets \
  --hosted-zone-id Z1234567890ABC \
  --change-batch file://failover-to-dr.json

# 4. Verify DR is serving traffic
curl -I https://bbwstrustedservice.co.za
```

### Failback from eu-west-1 to af-south-1

When PROD primary region (af-south-1) is restored:

```bash
# 1. Sync data from DR to Primary
aws dynamodb update-global-table \
  --global-table-name prod-tenants \
  --replica-updates Action=CREATE,RegionName=af-south-1

# 2. Restore infrastructure in af-south-1
cd terraform/environments/prod
terraform apply

# 3. Update Route 53 to point back to af-south-1
aws route53 change-resource-record-sets \
  --hosted-zone-id Z1234567890ABC \
  --change-batch file://failback-to-primary.json

# 4. Deactivate DR in eu-west-1
cd terraform/environments/prod-dr
terraform apply -var="activate_dr=false"
```

## Integration with Other Tools

### GitHub Actions

```yaml
# .github/workflows/deploy.yml
name: Deploy to AWS

on:
  workflow_dispatch:
    inputs:
      environment:
        required: true
        type: choice
        options:
          - dev
          - sit
          - prod

jobs:
  deploy:
    runs-on: ubuntu-latest
    steps:
      - name: Set AWS Region
        id: region
        run: |
          case "${{ inputs.environment }}" in
            dev|sit)
              echo "region=eu-west-1" >> $GITHUB_OUTPUT
              ;;
            prod)
              echo "region=af-south-1" >> $GITHUB_OUTPUT
              ;;
          esac

      - name: Configure AWS Credentials
        uses: aws-actions/configure-aws-credentials@v4
        with:
          role-to-assume: arn:aws:iam::${{ vars.AWS_ACCOUNT_ID }}:role/github-actions
          aws-region: ${{ steps.region.outputs.region }}

      - name: Deploy
        run: |
          echo "Deploying to ${{ inputs.environment }} in ${{ steps.region.outputs.region }}"
          terraform apply -auto-approve
```

### Python Boto3

```python
# utils/aws_helper.py

REGION_MAP = {
    'dev': 'eu-west-1',
    'sit': 'eu-west-1',
    'prod': 'af-south-1',
    'prod-dr': 'eu-west-1'
}

def get_region_for_env(environment: str) -> str:
    """Get the correct AWS region for an environment."""
    region = REGION_MAP.get(environment.lower())
    if not region:
        raise ValueError(f"Unknown environment: {environment}")
    return region

def get_aws_client(service: str, environment: str):
    """Get boto3 client with correct region."""
    import boto3
    region = get_region_for_env(environment)
    profile = f"Tebogo-{environment}"

    session = boto3.Session(profile_name=profile, region_name=region)
    return session.client(service)

# Usage
ecs_client = get_aws_client('ecs', 'dev')
clusters = ecs_client.list_clusters()
```

## Quick Reference Card

```
┌─────────────────────────────────────────────────────────┐
│         BBWS AWS Region Quick Reference                 │
├──────────┬─────────────────┬───────────────────────────┤
│   ENV    │     REGION      │         CLUSTER           │
├──────────┼─────────────────┼───────────────────────────┤
│   DEV    │   eu-west-1     │      dev-cluster          │
│   SIT    │   eu-west-1     │      sit-cluster          │
│   PROD   │   af-south-1    │      prod-cluster         │
│  PROD-DR │   eu-west-1     │      prod-dr-cluster      │
└──────────┴─────────────────┴───────────────────────────┘

Commands:
  DEV:  AWS_PROFILE=Tebogo-dev aws <service> <command> --region eu-west-1
  SIT:  AWS_PROFILE=Tebogo-sit aws <service> <command> --region eu-west-1
  PROD: AWS_PROFILE=Tebogo-prod aws <service> <command> --region af-south-1

Common Mistakes:
  ❌ Using af-south-1 for DEV/SIT
  ❌ Using eu-west-1 for PROD (unless DR)
  ❌ Forgetting --region flag (defaults to us-east-1)
  ❌ Using old cluster names (poc-cluster instead of dev-cluster)
```

## Best Practices

1. **Always Specify Region Explicitly**: Never rely on AWS CLI defaults
2. **Use Environment Variables**: Set AWS_DEFAULT_REGION in scripts
3. **Validate Before Execution**: Check region matches environment
4. **Document Deviations**: If using non-standard region, document why
5. **Test Region Selection**: Include region validation in CI/CD
6. **Monitor Cross-Region Costs**: Track data transfer between regions
7. **Keep DR Updated**: Regularly test failover to eu-west-1 for PROD

## Related Skills

- **Skill 6: terraform_manage** - Terraform region configuration
- **Skill 8: deploy** - Deployment with correct region selection
- **Skill 12: monitor_deployment** - Cross-region monitoring

---

**Last Updated**: 2025-12-21
**Maintained By**: DevOps Agent
**Version**: 1.0
