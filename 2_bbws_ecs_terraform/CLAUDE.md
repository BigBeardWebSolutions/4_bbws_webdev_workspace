# BBWS ECS Terraform - Project Instructions

## Project Purpose

This repository contains Terraform infrastructure-as-code for the BBWS Multi-Tenant WordPress Hosting Platform on AWS ECS Fargate.

## Critical Safety Rules

- **ALWAYS** validate AWS account ID before any terraform operation
- **NEVER** run terraform apply without reviewing the plan first
- **NEVER** hardcode credentials - use AWS Secrets Manager
- **BLOCK** terraform destroy in PROD (requires manual intervention)
- **REQUIRE** Business Owner approval for PROD deployments

## Environments

| Environment | AWS Account | Region | Profile |
|-------------|-------------|--------|---------|
| DEV | 536580886816 | af-south-1 | bbws-dev |
| SIT | 815856636111 | eu-west-1 | Tebogo-sit |
| PROD | 093646564004 | af-south-1 | bbws-prod |

## Workflow

### Development Flow

1. Make changes in DEV
2. Test and validate in DEV
3. Promote to SIT (requires Dev Lead approval)
4. Test and validate in SIT
5. Promote to PROD (requires BO + Tech Lead approval)

### Terraform Commands

```bash
# Initialize for environment
cd terraform
terraform init -backend-config=environments/{env}.hcl

# Plan changes
terraform plan -var-file=environments/{env}.tfvars -out=plan.tfplan

# Apply (only after plan review)
terraform apply plan.tfplan

# Destroy (DEV/SIT only, never PROD)
terraform destroy -var-file=environments/{env}.tfvars
```

## Module Dependencies

- VPC must be created before ECS, RDS, EFS
- Security groups must be created before ECS services
- RDS must be available before tenant databases can be initialized
- EFS must be available before tenant access points can be created

## State Management

- State stored in S3: `bbws-terraform-state-{env}`
- Locking via DynamoDB: `bbws-terraform-locks-{env}`
- Region: Matches environment region (DEV/PROD: af-south-1, SIT: eu-west-1)
- Encryption: Enabled

## Related Repositories

- `2_bbws_tenant_provisioner` - Python CLI for tenant operations
- `2_bbws_wordpress_container` - WordPress Docker image
- `2_bbws_ecs_tests` - Integration tests
- `2_bbws_agents` - AI agents and utilities
- `2_bbws_ecs_operations` - Dashboards, alerts, runbooks
- `2_bbws_docs` - Documentation (HLDs, LLDs)

## Root Workflow Inheritance

This project inherits TBT mechanism and all workflow standards from the parent CLAUDE.md:

{{include:../CLAUDE.md}}
