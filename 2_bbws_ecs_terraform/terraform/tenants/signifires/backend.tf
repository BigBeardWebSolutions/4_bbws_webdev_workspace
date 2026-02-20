# Signifires Tenant - Terraform Backend Configuration
# S3 backend with DynamoDB locking for state management

terraform {
  backend "s3" {
    # Backend configuration is provided via -backend-config during terraform init
    # This allows the same configuration to work across environments

    # Example init commands:
    #
    # DEV:
    #   terraform init \
    #     -backend-config="../../environments/dev/backend-dev.hcl" \
    #     -backend-config="key=tenants/signifires/terraform.tfstate"
    #
    # SIT:
    #   terraform init \
    #     -backend-config="../../environments/sit/backend-sit.hcl" \
    #     -backend-config="key=tenants/signifires/terraform.tfstate"
    #
    # PROD:
    #   terraform init \
    #     -backend-config="../../environments/prod/backend-prod.hcl" \
    #     -backend-config="key=tenants/signifires/terraform.tfstate"
  }
}
