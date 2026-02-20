# Database Module - Main Resources
# Creates tenant-specific database and user in shared RDS instance

#------------------------------------------------------------------------------
# Retrieve Database Credentials from Secrets Manager
#------------------------------------------------------------------------------

data "aws_secretsmanager_secret_version" "tenant_db" {
  secret_id = var.tenant_db_secret_arn
}

locals {
  tenant_db_credentials = jsondecode(data.aws_secretsmanager_secret_version.tenant_db.secret_string)

  db_username = local.tenant_db_credentials.username
  db_password = local.tenant_db_credentials.password
  db_name     = local.tenant_db_credentials.database
  db_host     = local.tenant_db_credentials.host
}

#------------------------------------------------------------------------------
# Database Creation via Python Script
#------------------------------------------------------------------------------

resource "null_resource" "create_database" {
  triggers = {
    tenant_name  = var.tenant_name
    environment  = var.environment
    db_secret_id = var.tenant_db_secret_arn
    timestamp    = timestamp()
  }

  provisioner "local-exec" {
    command = <<-EOT
      python3 ${var.init_db_script_path} \
        --tenant-name ${var.tenant_name} \
        --environment ${var.environment} \
        --secret-arn ${var.tenant_db_secret_arn} \
        --region ${var.aws_region} \
        --profile ${var.aws_profile}
    EOT

    environment = {
      AWS_REGION  = var.aws_region
      AWS_PROFILE = var.aws_profile
    }
  }

  depends_on = [
    data.aws_secretsmanager_secret_version.tenant_db
  ]
}

#------------------------------------------------------------------------------
# Database Verification (Optional Check)
#------------------------------------------------------------------------------

resource "null_resource" "verify_database" {
  count = var.verify_database ? 1 : 0

  triggers = {
    database_created = null_resource.create_database.id
  }

  provisioner "local-exec" {
    command = <<-EOT
      python3 ${var.init_db_script_path} \
        --tenant-name ${var.tenant_name} \
        --environment ${var.environment} \
        --secret-arn ${var.tenant_db_secret_arn} \
        --region ${var.aws_region} \
        --profile ${var.aws_profile} \
        --verify-only
    EOT

    environment = {
      AWS_REGION  = var.aws_region
      AWS_PROFILE = var.aws_profile
    }
  }

  depends_on = [
    null_resource.create_database
  ]
}
