# GitHub Actions Workflows

This folder contains GitHub Actions workflow definitions for the BBWS tenant deployment pipeline.

## Workflow Files

### Reusable Workflows
- **deploy-tenant.yml** - Main reusable workflow for tenant deployment (all 3 phases)

### Tenant-Specific Triggers
- **tenant-{name}.yml** - Per-tenant workflow triggers (13 files)
  - tenant-goldencrust.yml
  - tenant-sunsetbistro.yml
  - tenant-sterlinglaw.yml
  - tenant-ironpeak.yml
  - tenant-premierprop.yml
  - tenant-lenslight.yml
  - tenant-nexgentech.yml
  - tenant-serenity.yml
  - tenant-bloompetal.yml
  - tenant-precisionauto.yml
  - tenant-bbwstrustedservice.yml

## Workflow Structure

Each tenant workflow:
1. Accepts manual input (environment, ALB priority)
2. Calls the reusable `deploy-tenant.yml` workflow
3. Passes tenant-specific parameters

## Usage

1. Go to GitHub Actions tab
2. Select tenant workflow (e.g., "Deploy Tenant - goldencrust")
3. Click "Run workflow"
4. Fill in inputs:
   - Environment: dev/sit/prod
   - ALB Priority: unique number (10-260)
5. Click "Run workflow"

## Related Documentation
- [Pipeline Design](../../devops/design/TENANT_DEPLOYMENT_PIPELINE_DESIGN.md)
- [Folder Structure](../../devops/design/FOLDER_STRUCTURE.md)
- [Path Reference](../../devops/design/WORKFLOW_PATH_REFERENCE.md)
