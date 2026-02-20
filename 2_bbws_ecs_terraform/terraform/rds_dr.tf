# Cross-Region RDS Disaster Recovery Configuration
# Automated backups replicated to eu-west-1 for SIT and PROD
# Part of multi-site active/active DR strategy

#------------------------------------------------------------------------------
# DR Region Provider (eu-west-1)
#------------------------------------------------------------------------------
provider "aws" {
  alias  = "dr_region"
  region = "eu-west-1"

  # Cross-account deployment support via assume_role
  dynamic "assume_role" {
    for_each = var.assume_role_arn != "" ? [1] : []
    content {
      role_arn     = var.assume_role_arn
      session_name = "terraform-${var.environment}-dr"
    }
  }

  default_tags {
    tags = {
      Project     = "BBWS-ECS-WordPress-DR"
      Environment = "${var.environment}-dr"
      ManagedBy   = "Terraform"
      AccountId   = var.aws_account_id
      Region      = "eu-west-1"
    }
  }
}

#------------------------------------------------------------------------------
# RDS Automated Backup Replication to DR Region
# Creates read replicas of automated backups in eu-west-1
# Enabled for SIT and PROD environments only
#------------------------------------------------------------------------------
resource "aws_db_instance_automated_backups_replication" "dr" {
  count = var.environment == "prod" || var.environment == "sit" ? 1 : 0

  source_db_instance_arn = aws_db_instance.main.arn
  kms_key_id             = aws_kms_key.dr_backup[0].arn

  provider = aws.dr_region
}

#------------------------------------------------------------------------------
# KMS Key for DR Backup Encryption
# Required for cross-region backup replication
#------------------------------------------------------------------------------
resource "aws_kms_key" "dr_backup" {
  count = var.environment == "prod" || var.environment == "sit" ? 1 : 0

  description             = "${var.environment} RDS DR Backup Encryption Key"
  deletion_window_in_days = 10
  enable_key_rotation     = true

  provider = aws.dr_region

  tags = {
    Name        = "${var.environment}-rds-dr-backup-key"
    Environment = var.environment
    Purpose     = "DR Backup Encryption"
  }
}

resource "aws_kms_alias" "dr_backup" {
  count = var.environment == "prod" || var.environment == "sit" ? 1 : 0

  name          = "alias/${var.environment}-rds-dr-backup"
  target_key_id = aws_kms_key.dr_backup[0].key_id

  provider = aws.dr_region
}
