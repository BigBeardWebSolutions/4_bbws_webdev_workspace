# yourfinancialflow Tenant - Terraform Backend Configuration
terraform {
  backend "s3" {
    # Backend configuration provided via -backend-config during terraform init
    # DEV: terraform init -backend-config="../../environments/dev/backend-dev.hcl" -backend-config="key=tenants/yourfinancialflow/terraform.tfstate"
  }
}
