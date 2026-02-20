# Terraform Backend Configuration - DEV Environment
# Region: eu-west-1
# AWS Profile: Tebogo-dev

bucket         = "bbws-terraform-state-dev"
region         = "eu-west-1"
dynamodb_table = "bbws-terraform-locks"
encrypt        = true
profile        = "Tebogo-dev"

# Note: The 'key' parameter must be provided via -backend-config during terraform init
# Example:
#   terraform init \
#     -backend-config="../../environments/dev/backend-dev.hcl" \
#     -backend-config="key=tenants/goldencrust/terraform.tfstate"
