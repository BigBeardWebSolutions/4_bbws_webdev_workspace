# BBWS WordPress Container

Custom WordPress Docker image for the BBWS Multi-Tenant WordPress Hosting Platform on ECS Fargate.

## Overview

This repository contains the Docker configuration for building an optimized WordPress container with:
- WP-CLI for automation
- Custom entrypoint for multi-tenant configuration
- Custom wp-config snippets
- Must-use plugins (mu-plugins) support

## Directory Structure

```
docker/
├── Dockerfile                    # Multi-layer WordPress image
├── docker-entrypoint-wrapper.sh  # Custom entrypoint script
└── wp-config-custom.php          # WordPress configuration snippets
```

## Building the Image

### Local Build

```bash
cd docker
docker build -t bbws-wordpress:latest .
```

### Build and Push to ECR

```bash
# Login to ECR
aws ecr get-login-password --region af-south-1 | docker login --username AWS --password-stdin <account_id>.dkr.ecr.af-south-1.amazonaws.com

# Build
docker build -t bbws-wordpress:latest docker/

# Tag
docker tag bbws-wordpress:latest <account_id>.dkr.ecr.af-south-1.amazonaws.com/bbws-wordpress:latest

# Push
docker push <account_id>.dkr.ecr.af-south-1.amazonaws.com/bbws-wordpress:latest
```

## Image Features

- **Base Image**: Official WordPress image (PHP 8.x + Apache)
- **WP-CLI**: Included for WordPress automation
- **MySQL Client**: For database operations
- **Custom Entrypoint**: Initializes multi-tenant configuration
- **mu-plugins Support**: Loads must-use plugins automatically

## Environment Variables

| Variable | Description |
|----------|-------------|
| `WORDPRESS_DB_HOST` | RDS MySQL endpoint |
| `WORDPRESS_DB_NAME` | Tenant-specific database name |
| `WORDPRESS_DB_USER` | Tenant-specific database user |
| `WORDPRESS_DB_PASSWORD` | Retrieved from Secrets Manager |
| `WORDPRESS_TABLE_PREFIX` | Default: `wp_` |

## Related Repositories

- `2_bbws_ecs_terraform` - Infrastructure as Code
- `2_bbws_tenant_provisioner` - Tenant management CLI
- `2_bbws_ecs_tests` - Integration tests

## License

Proprietary - Big Beard Web Solutions
