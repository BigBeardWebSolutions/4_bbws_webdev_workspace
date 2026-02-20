# Tenant Terraform Configurations

This folder contains per-tenant Terraform configurations that call the reusable modules.

## Folder Structure

Each tenant has its own folder:
```
tenants/
├── goldencrust/
│   ├── main.tf           # Module calls
│   ├── backend.tf        # S3 backend config
│   ├── providers.tf      # AWS provider
│   ├── variables.tf      # Variable declarations
│   ├── dev.tfvars        # DEV values
│   ├── sit.tfvars        # SIT values
│   ├── prod.tfvars       # PROD values
│   └── README.md         # Tenant-specific docs
└── ... (13 tenant folders total)
```

## Tenant List

1. goldencrust
2. sunsetbistro
3. sterlinglaw
4. ironpeak
5. premierprop
6. lenslight
7. nexgentech
8. serenity
9. bloompetal
10. precisionauto
11. bbwstrustedservice

## Deployment Workflow

### Via GitHub Actions (Recommended)
1. Go to GitHub Actions → tenant workflow
2. Select environment and priority
3. Click "Run workflow"

### Manual Deployment
```bash
cd tenants/goldencrust

# Initialize with environment-specific backend
terraform init \
  -backend-config="../../environments/sit/backend-sit.hcl" \
  -backend-config="key=tenants/goldencrust/terraform.tfstate"

# Select/create workspace
terraform workspace select sit || terraform workspace new sit

# Plan deployment
terraform plan -var-file=sit.tfvars -out=sit.tfplan

# Apply
terraform apply sit.tfplan
```

## Environment Configuration

### DEV
- Region: eu-west-1
- Profile: Tebogo-dev
- Domain: wpdev.kimmyai.io

### SIT
- Region: eu-west-1
- Profile: Tebogo-sit
- Domain: wpsit.kimmyai.io

### PROD
- Region: af-south-1
- Profile: Tebogo-prod
- Domain: wp.kimmyai.io

## Adding New Tenant

1. Create tenant folder: `mkdir tenants/{new-tenant}`
2. Copy template from existing tenant
3. Update `main.tf` with tenant name
4. Create `dev.tfvars`, `sit.tfvars`, `prod.tfvars`
5. Create GitHub workflow: `.github/workflows/tenant-{new-tenant}.yml`
6. Initialize and deploy

## Terraform State

State files are stored in S3:
- **Bucket:** `bbws-terraform-state-{env}`
- **Key:** `tenants/{tenant-name}/terraform.tfstate`
- **Locking:** DynamoDB table `bbws-terraform-locks-{env}`

## Related Documentation
- [Pipeline Design](../../../2_bbws_agents/devops/design/TENANT_DEPLOYMENT_PIPELINE_DESIGN.md)
- [Tenant Lifecycle Guide](../../../2_bbws_agents/devops/TENANT_LIFECYCLE_GUIDE.md)
