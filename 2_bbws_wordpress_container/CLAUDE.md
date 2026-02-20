# BBWS WordPress Container - Project Instructions

## Project Purpose

Custom WordPress Docker image for the BBWS Multi-Tenant WordPress Hosting Platform on ECS Fargate.

## Critical Safety Rules

- **ALWAYS** test image locally before pushing to ECR
- **NEVER** include secrets in the Docker image
- **ALWAYS** use multi-stage builds for smaller images
- **SCAN** for vulnerabilities before deployment

## Build Commands

```bash
# Build locally
docker build -t bbws-wordpress:latest docker/

# Test locally
docker run -p 8080:80 bbws-wordpress:latest

# Push to ECR (requires AWS credentials)
./scripts/build_and_push.sh <env>
```

## Image Layers

1. Base WordPress image
2. WP-CLI installation
3. MySQL client tools
4. Custom entrypoint
5. Custom wp-config

## Environment Configuration

The container expects these environment variables at runtime:
- `WORDPRESS_DB_HOST` - RDS endpoint
- `WORDPRESS_DB_NAME` - Tenant database
- `WORDPRESS_DB_USER` - Tenant user
- `WORDPRESS_DB_PASSWORD` - From Secrets Manager

## Security

- No secrets in image
- Run as non-root where possible
- Regular security scans with Trivy
- Keep base image updated

## Related Repositories

- `2_bbws_ecs_terraform` - Infrastructure as Code
- `2_bbws_tenant_provisioner` - Tenant management CLI
- `2_bbws_ecs_tests` - Integration tests
- `2_bbws_agents` - AI agents and utilities
- `2_bbws_ecs_operations` - Dashboards, alerts, runbooks
- `2_bbws_docs` - Documentation (HLDs, LLDs)

## Root Workflow Inheritance

This project inherits TBT mechanism and all workflow standards from the parent CLAUDE.md:

{{include:../CLAUDE.md}}
