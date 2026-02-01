# Terraform Backend Configuration - SANDBOX Environment
# AWS Account: 417589271098
# Region: eu-west-1
# Profile: sandbox

bucket         = "bbws-terraform-state-sandbox"
region         = "eu-west-1"
dynamodb_table = "bbws-terraform-locks-sandbox"
encrypt        = true
profile        = "sandbox"

# Note: The 'key' parameter must be provided via -backend-config during terraform init
# Example:
#   terraform init \
#     -backend-config="../../4_bbws_webdev_workspace/terraform/environments/sandbox/backend-sandbox.hcl" \
#     -backend-config="key=infrastructure/terraform.tfstate"
