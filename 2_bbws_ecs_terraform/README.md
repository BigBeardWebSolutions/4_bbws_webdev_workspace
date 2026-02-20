# BBWS ECS Terraform Infrastructure

Infrastructure-as-Code for the BBWS Multi-Tenant WordPress Hosting Platform on AWS ECS Fargate.

## Overview

This repository contains Terraform modules for deploying and managing:
- VPC and networking (public/private subnets, NAT Gateway)
- ECS Fargate cluster for WordPress containers
- RDS MySQL with multi-tenant database isolation (bridge model)
- EFS with per-tenant access points
- Application Load Balancer with path-based routing
- CloudFront distributions
- Security groups and IAM roles

## Directory Structure

```
terraform/
├── main.tf              # Provider configuration, backend
├── variables.tf         # Input variables (parameterized per environment)
├── outputs.tf           # Output values
├── vpc.tf               # VPC, subnets, NAT Gateway, route tables
├── security.tf          # Security groups, IAM roles and policies
├── ecs.tf               # ECS cluster, task definitions, services
├── rds.tf               # RDS MySQL instance, parameter groups
├── efs.tf               # EFS filesystem, mount targets, access points
├── alb.tf               # ALB, target groups, listener rules
├── cloudfront.tf        # CloudFront distributions
├── ecr.tf               # ECR repository for WordPress image
├── db_init.tf           # Database initialization resources
├── db_init_task.tf      # ECS task for DB initialization
├── bbwstrustedservice.tf # Cross-account IAM trust relationships
├── tenant2.tf           # Example second tenant resources
└── environments/        # Environment-specific tfvars
    ├── dev.tfvars
    ├── sit.tfvars
    └── prod.tfvars
```

## Environments

| Environment | AWS Account | Region | Domain | Purpose |
|-------------|-------------|--------|--------|---------|
| DEV | 536580886816 | eu-west-1 | *.wpdev.kimmyai.io | Development and testing |
| SIT | 815856636111 | eu-west-1 | *.wpsit.kimmyai.io | System integration testing |
| PROD | 093646564004 | af-south-1 | *.wp.kimmyai.io | Production |

### DNS Architecture

- **DEV**: wpdev.kimmyai.io delegated hosted zone (NS records in PROD kimmyai.io)
- **SIT**: wpsit.kimmyai.io delegated hosted zone (NS records in PROD kimmyai.io)
- **PROD**: wp.kimmyai.io direct subdomain in kimmyai.io primary zone
- **SSL**: ACM wildcard certificates (*.wpdev, *.wpsit, *.wp) in us-east-1 for CloudFront
- **CDN**: CloudFront distributions with custom domain CNAMEs per environment

### Tenant URL Format

Each tenant gets a dedicated subdomain:
- **DEV**: https://tenant1.wpdev.kimmyai.io
- **SIT**: https://tenant1.wpsit.kimmyai.io
- **PROD**: https://tenant1.wp.kimmyai.io

All sites served via CloudFront with HTTPS (TLS 1.2+) and optional Basic Authentication.

## Usage

### Initialize

```bash
cd terraform
terraform init -backend-config=environments/dev.hcl
```

### Plan

```bash
terraform plan -var-file=environments/dev.tfvars
```

### Apply

```bash
terraform apply -var-file=environments/dev.tfvars
```

## Key Features

- **Multi-Account Support**: Safe cross-account deployment with account validation
- **Environment Parameterization**: All values parameterized for dev/sit/prod
- **Tenant Isolation**: Per-tenant database, EFS access point, and container
- **No Hardcoded Credentials**: All secrets via AWS Secrets Manager
- **On-Demand Capacity**: DynamoDB tables use on-demand capacity mode

## Deployed Tenants

### DEV Environment (13 active tenants)

All tenants accessible via https://{tenant}.wpdev.kimmyai.io:

1. **tenant1** - Demo tenant
2. **tenant2** - Demo tenant
3. **goldencrust** - Bakery site (pilot migration)
4. **sunsetbistro** - Restaurant site
5. **sterlinglaw** - Law firm site
6. **ironpeak** - Fitness/outdoor site
7. **premierprop** - Real estate site
8. **lenslight** - Photography site
9. **nexgentech** - Technology company site
10. **serenity** - Wellness/spa site
11. **bloompetal** - Florist site
12. **precisionauto** - Auto repair site
13. **bbwstrustedservice** - Platform service tenant

All tenants migrated from nip.io wildcard DNS to wpdev.kimmyai.io (December 2024).

## Recent Updates

### December 2024: DNS Migration to wpdev.kimmyai.io

Successfully migrated all 13 DEV tenants from nip.io wildcard DNS to proper wpdev.kimmyai.io subdomains:
- DNS delegation configured from PROD account
- ACM wildcard certificate (*.wpdev.kimmyai.io) provisioned
- CloudFront distributions configured with custom domains
- All ALB listener rules updated to host-based routing
- Zero downtime migration with automated rollback capability

See [PLAN_DEV_MIGRATION_TO_WPDEV.md](PLAN_DEV_MIGRATION_TO_WPDEV.md) for migration details.

## Scripts

### Tenant Management

- **migrate_tenant_to_wpdev.py**: Automated tenant migration script with rollback support
- Located in `scripts/` directory

## Related Documents

- [BBWS ECS WordPress HLD](../0_playpen/agents/Agentic_Architect/HLDs/BBWS_ECS_WordPress_HLD.md)
- [DevOps Agent Specification](../0_playpen/agents/Agentic_Architect/HLDs/investigation/Phase_2/agents/DevOps_agent.md)
- [Migration Plan: DEV to wpdev.kimmyai.io](PLAN_DEV_MIGRATION_TO_WPDEV.md)

## License

Proprietary - Big Beard Web Solutions
