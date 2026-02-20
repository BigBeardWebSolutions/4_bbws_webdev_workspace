# Environment Backend Configurations

This folder contains environment-specific Terraform backend configurations for S3 state storage.

## Files

### dev/backend-dev.hcl
S3 backend configuration for DEV environment:
- Bucket: `bbws-terraform-state-dev`
- Region: `eu-west-1`
- DynamoDB: `bbws-terraform-locks-dev`

### sit/backend-sit.hcl
S3 backend configuration for SIT environment:
- Bucket: `bbws-terraform-state-sit`
- Region: `eu-west-1`
- DynamoDB: `bbws-terraform-locks-sit`

### prod/backend-prod.hcl
S3 backend configuration for PROD environment:
- Bucket: `bbws-terraform-state-prod`
- Region: `af-south-1`
- DynamoDB: `bbws-terraform-locks-prod`

## Usage

Backend configs are passed during `terraform init`:

```bash
terraform init \
  -backend-config="../environments/sit/backend-sit.hcl" \
  -backend-config="key=tenants/goldencrust/terraform.tfstate"
```

## Backend Configuration Format

```hcl
# backend-sit.hcl
bucket         = "bbws-terraform-state-sit"
key            = "tenants/TENANT_NAME/terraform.tfstate"  # Set via -backend-config
region         = "eu-west-1"
dynamodb_table = "bbws-terraform-locks-sit"
encrypt        = true
```

## Prerequisites

### S3 Buckets
Must be created before Terraform init:
```bash
aws s3 mb s3://bbws-terraform-state-dev --region eu-west-1 --profile Tebogo-dev
aws s3 mb s3://bbws-terraform-state-sit --region eu-west-1 --profile Tebogo-sit
aws s3 mb s3://bbws-terraform-state-prod --region af-south-1 --profile Tebogo-prod
```

Enable versioning:
```bash
aws s3api put-bucket-versioning \
  --bucket bbws-terraform-state-sit \
  --versioning-configuration Status=Enabled \
  --profile Tebogo-sit
```

### DynamoDB Tables
Must be created for state locking:
```bash
aws dynamodb create-table \
  --table-name bbws-terraform-locks-sit \
  --attribute-definitions AttributeName=LockID,AttributeType=S \
  --key-schema AttributeName=LockID,KeyType=HASH \
  --billing-mode PAY_PER_REQUEST \
  --region eu-west-1 \
  --profile Tebogo-sit
```

## Related Documentation
- [Pipeline Design](../../../2_bbws_agents/devops/design/TENANT_DEPLOYMENT_PIPELINE_DESIGN.md)
- [Folder Structure](../../../2_bbws_agents/devops/design/FOLDER_STRUCTURE.md)
