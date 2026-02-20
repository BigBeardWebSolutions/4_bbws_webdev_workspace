# Tenant Configuration Documents

This folder contains auto-generated tenant configuration files created after successful deployments.

## Folder Structure

```
config/
├── dev/
│   ├── goldencrust.json
│   ├── sunsetbistro.json
│   └── ... (all tenants)
├── sit/
│   ├── goldencrust.json
│   └── ...
└── prod/
    ├── goldencrust.json
    └── ...
```

## Configuration File Format

Each JSON file contains:
- Tenant metadata (name, environment, deployment date)
- Infrastructure details (ECS service, task definition, ALB)
- Database information (name, secret ARN, RDS endpoint)
- Storage details (EFS ID, access point)
- Networking (domain, URL, CloudFront, Route53)
- Terraform state location (workspace, bucket, key)

## Example

```json
{
  "tenant_name": "goldencrust",
  "environment": "sit",
  "deployment_date": "2025-12-23T10:30:00Z",
  "deployed_by": "github-actions",
  "url": "https://goldencrust.wpsit.kimmyai.io",
  "infrastructure": { ... },
  "database": { ... },
  "terraform": { ... }
}
```

## Usage

- **Generated automatically** by GitHub Actions post-deployment
- **Committed to Git** for version control
- **Backed up to S3** at `s3://bbws-tenant-configs/{env}/{tenant}-config.json`
- **Used by** monitoring, migration, and troubleshooting tools

## Do Not Manually Edit

These files are auto-generated. Manual edits will be overwritten on next deployment.
To update configuration, modify the source Terraform files and re-deploy.
