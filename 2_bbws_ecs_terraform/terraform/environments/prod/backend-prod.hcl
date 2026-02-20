# Terraform Backend Configuration - PROD Environment
# Region: af-south-1
# AWS Profile: Tebogo-prod

bucket         = "bbws-terraform-state-prod"
region         = "af-south-1"
dynamodb_table = "bbws-terraform-locks"
encrypt        = true

# Note: The 'key' parameter must be provided via -backend-config during terraform init
# Example:
#   terraform init \
#     -backend-config="../../environments/prod/backend-prod.hcl" \
#     -backend-config="key=tenants/goldencrust/terraform.tfstate"
