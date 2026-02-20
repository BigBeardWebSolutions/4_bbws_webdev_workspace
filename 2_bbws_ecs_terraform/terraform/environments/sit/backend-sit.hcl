# Terraform Backend Configuration - SIT Environment
# Region: eu-west-1
# AWS Profile: Tebogo-sit

bucket         = "bbws-terraform-state-sit"
region         = "eu-west-1"
dynamodb_table = "bbws-terraform-locks-sit"
encrypt        = true

# Note: The 'key' parameter must be provided via -backend-config during terraform init
# Example:
#   terraform init \
#     -backend-config="../../environments/sit/backend-sit.hcl" \
#     -backend-config="key=tenants/goldencrust/terraform.tfstate"
