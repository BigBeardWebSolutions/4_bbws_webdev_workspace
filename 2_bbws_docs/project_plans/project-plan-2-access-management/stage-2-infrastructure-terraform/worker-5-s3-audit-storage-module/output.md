# Worker 5 Output: S3 Audit Storage Terraform Module

**Worker ID**: worker-5-s3-audit-storage-module
**Stage**: Stage 2 - Infrastructure Terraform
**Project**: project-plan-2-access-management
**Created**: 2026-01-23
**Status**: COMPLETE

---

## Module Overview

This Terraform module creates S3 buckets for audit log storage with:
- Public access blocked (mandatory for all environments)
- SSE-KMS encryption
- Versioning enabled
- Lifecycle policies (Warm to Cold transition)
- Cross-region replication (PROD only: af-south-1 to eu-west-1)
- 7-year retention for compliance

---

## Module Structure

```
terraform/modules/s3-audit-storage/
├── main.tf           # Bucket definitions with public access block
├── lifecycle.tf      # Lifecycle policies (Warm → Cold)
├── replication.tf    # Cross-region replication (PROD only)
├── encryption.tf     # KMS encryption configuration
├── policy.tf         # Bucket policy
├── variables.tf      # Input variables
└── outputs.tf        # Module outputs
```

---

## 1. main.tf - S3 Bucket Definition

```hcl
###############################################################################
# S3 Audit Storage Module - Main Bucket Definition
#
# Purpose: Create S3 bucket for audit log archive storage
# Bucket Name: bbws-access-{env}-s3-audit-archive
#
# Features:
# - Public access blocked (mandatory)
# - Versioning enabled
# - Object ownership enforced
###############################################################################

terraform {
  required_version = ">= 1.0"

  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = ">= 5.0"
    }
  }
}

# -----------------------------------------------------------------------------
# Data Sources
# -----------------------------------------------------------------------------

data "aws_caller_identity" "current" {}

data "aws_region" "current" {}

# -----------------------------------------------------------------------------
# Primary Audit Archive Bucket
# -----------------------------------------------------------------------------

resource "aws_s3_bucket" "audit_archive" {
  bucket = "bbws-access-${var.environment}-s3-audit-archive"

  # Prevent accidental deletion in production
  force_destroy = var.environment == "dev" ? true : false

  tags = merge(var.tags, {
    Name        = "bbws-access-${var.environment}-s3-audit-archive"
    Component   = "AuditService"
    Purpose     = "AuditLogArchive"
    Environment = var.environment
    ManagedBy   = "Terraform"
    Project     = "BBWS"
    CostCenter  = "BBWS-ACCESS"
  })
}

# -----------------------------------------------------------------------------
# Block ALL Public Access (Mandatory)
# -----------------------------------------------------------------------------

resource "aws_s3_bucket_public_access_block" "audit_archive" {
  bucket = aws_s3_bucket.audit_archive.id

  # Block ALL public access - MANDATORY for all environments
  block_public_acls       = true
  block_public_policy     = true
  ignore_public_acls      = true
  restrict_public_buckets = true
}

# -----------------------------------------------------------------------------
# Bucket Versioning (Required for Replication and Compliance)
# -----------------------------------------------------------------------------

resource "aws_s3_bucket_versioning" "audit_archive" {
  bucket = aws_s3_bucket.audit_archive.id

  versioning_configuration {
    status = "Enabled"
  }
}

# -----------------------------------------------------------------------------
# Bucket Ownership Controls
# -----------------------------------------------------------------------------

resource "aws_s3_bucket_ownership_controls" "audit_archive" {
  bucket = aws_s3_bucket.audit_archive.id

  rule {
    object_ownership = "BucketOwnerEnforced"
  }
}

# -----------------------------------------------------------------------------
# Replica Bucket (PROD Only - in DR Region)
# -----------------------------------------------------------------------------

resource "aws_s3_bucket" "audit_archive_replica" {
  count    = var.enable_replication ? 1 : 0
  provider = aws.replica

  bucket = "bbws-access-${var.environment}-s3-audit-archive-replica"

  force_destroy = false

  tags = merge(var.tags, {
    Name        = "bbws-access-${var.environment}-s3-audit-archive-replica"
    Component   = "AuditService"
    Purpose     = "AuditLogArchiveReplica"
    Environment = var.environment
    ManagedBy   = "Terraform"
    Project     = "BBWS"
    CostCenter  = "BBWS-ACCESS"
    ReplicaOf   = "bbws-access-${var.environment}-s3-audit-archive"
  })
}

# Block ALL Public Access on Replica Bucket
resource "aws_s3_bucket_public_access_block" "audit_archive_replica" {
  count    = var.enable_replication ? 1 : 0
  provider = aws.replica

  bucket = aws_s3_bucket.audit_archive_replica[0].id

  block_public_acls       = true
  block_public_policy     = true
  ignore_public_acls      = true
  restrict_public_buckets = true
}

# Enable Versioning on Replica Bucket (Required for Replication)
resource "aws_s3_bucket_versioning" "audit_archive_replica" {
  count    = var.enable_replication ? 1 : 0
  provider = aws.replica

  bucket = aws_s3_bucket.audit_archive_replica[0].id

  versioning_configuration {
    status = "Enabled"
  }
}

# Ownership Controls on Replica Bucket
resource "aws_s3_bucket_ownership_controls" "audit_archive_replica" {
  count    = var.enable_replication ? 1 : 0
  provider = aws.replica

  bucket = aws_s3_bucket.audit_archive_replica[0].id

  rule {
    object_ownership = "BucketOwnerEnforced"
  }
}
```

---

## 2. lifecycle.tf - Lifecycle Policy

```hcl
###############################################################################
# S3 Audit Storage Module - Lifecycle Policy
#
# Storage Tiers:
# - Hot (DynamoDB): 0-30 days (handled by DynamoDB TTL)
# - Warm (S3 Standard): 31-90 days (initial storage class)
# - Cold (S3 Glacier): 91 days - 7 years (transition after 90 days)
#
# Retention: 7 years (2555 days) for compliance
###############################################################################

# -----------------------------------------------------------------------------
# Primary Bucket Lifecycle Configuration
# -----------------------------------------------------------------------------

resource "aws_s3_bucket_lifecycle_configuration" "audit_archive" {
  bucket = aws_s3_bucket.audit_archive.id

  # Must wait for versioning to be enabled
  depends_on = [aws_s3_bucket_versioning.audit_archive]

  # -------------------------------------------------------------------------
  # Rule 1: Archive Objects Lifecycle
  # Archives transition to Glacier after 90 days, expire after 7 years
  # -------------------------------------------------------------------------
  rule {
    id     = "audit-archive-lifecycle"
    status = "Enabled"

    filter {
      prefix = "archive/"
    }

    # Transition to Glacier after 90 days (Warm → Cold)
    transition {
      days          = 90
      storage_class = "GLACIER"
    }

    # Expire after 7 years (2555 days)
    expiration {
      days = 2555
    }

    # Clean up old versions after 30 days
    noncurrent_version_transition {
      noncurrent_days = 30
      storage_class   = "GLACIER"
    }

    # Delete old versions after 90 days
    noncurrent_version_expiration {
      noncurrent_days = 90
    }
  }

  # -------------------------------------------------------------------------
  # Rule 2: Exports Lifecycle
  # Exports are temporary, expire after 30 days
  # -------------------------------------------------------------------------
  rule {
    id     = "audit-exports-lifecycle"
    status = "Enabled"

    filter {
      prefix = "exports/"
    }

    # Exports expire after 30 days (temporary files)
    expiration {
      days = 30
    }

    # Clean up incomplete multipart uploads
    abort_incomplete_multipart_upload {
      days_after_initiation = 7
    }
  }

  # -------------------------------------------------------------------------
  # Rule 3: Cleanup Incomplete Multipart Uploads (Global)
  # -------------------------------------------------------------------------
  rule {
    id     = "cleanup-incomplete-uploads"
    status = "Enabled"

    filter {
      prefix = ""
    }

    abort_incomplete_multipart_upload {
      days_after_initiation = 7
    }
  }

  # -------------------------------------------------------------------------
  # Rule 4: Delete Expired Object Delete Markers
  # -------------------------------------------------------------------------
  rule {
    id     = "cleanup-delete-markers"
    status = "Enabled"

    filter {
      prefix = ""
    }

    expiration {
      expired_object_delete_marker = true
    }
  }
}

# -----------------------------------------------------------------------------
# Replica Bucket Lifecycle Configuration (PROD Only)
# -----------------------------------------------------------------------------

resource "aws_s3_bucket_lifecycle_configuration" "audit_archive_replica" {
  count    = var.enable_replication ? 1 : 0
  provider = aws.replica

  bucket = aws_s3_bucket.audit_archive_replica[0].id

  depends_on = [aws_s3_bucket_versioning.audit_archive_replica]

  # Archive Lifecycle Rule
  rule {
    id     = "audit-archive-lifecycle-replica"
    status = "Enabled"

    filter {
      prefix = "archive/"
    }

    transition {
      days          = 90
      storage_class = "GLACIER"
    }

    expiration {
      days = 2555
    }

    noncurrent_version_transition {
      noncurrent_days = 30
      storage_class   = "GLACIER"
    }

    noncurrent_version_expiration {
      noncurrent_days = 90
    }
  }

  # Exports Lifecycle Rule
  rule {
    id     = "audit-exports-lifecycle-replica"
    status = "Enabled"

    filter {
      prefix = "exports/"
    }

    expiration {
      days = 30
    }

    abort_incomplete_multipart_upload {
      days_after_initiation = 7
    }
  }

  # Cleanup Rule
  rule {
    id     = "cleanup-incomplete-uploads-replica"
    status = "Enabled"

    filter {
      prefix = ""
    }

    abort_incomplete_multipart_upload {
      days_after_initiation = 7
    }
  }
}
```

---

## 3. encryption.tf - SSE-KMS Encryption

```hcl
###############################################################################
# S3 Audit Storage Module - KMS Encryption
#
# Purpose: Configure server-side encryption using AWS KMS
# - Primary bucket uses primary region KMS key
# - Replica bucket uses DR region KMS key
###############################################################################

# -----------------------------------------------------------------------------
# KMS Key for Primary Bucket Encryption
# -----------------------------------------------------------------------------

resource "aws_kms_key" "audit_archive" {
  description             = "KMS key for audit archive S3 bucket encryption"
  deletion_window_in_days = 30
  enable_key_rotation     = true

  # Multi-region key for replication support
  multi_region = var.enable_replication

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Sid    = "Enable IAM User Permissions"
        Effect = "Allow"
        Principal = {
          AWS = "arn:aws:iam::${data.aws_caller_identity.current.account_id}:root"
        }
        Action   = "kms:*"
        Resource = "*"
      },
      {
        Sid    = "Allow S3 Service"
        Effect = "Allow"
        Principal = {
          Service = "s3.amazonaws.com"
        }
        Action = [
          "kms:GenerateDataKey*",
          "kms:Decrypt"
        ]
        Resource = "*"
      },
      {
        Sid    = "Allow Audit Service Lambda Role"
        Effect = "Allow"
        Principal = {
          AWS = var.audit_service_role_arn
        }
        Action = [
          "kms:GenerateDataKey*",
          "kms:Decrypt",
          "kms:Encrypt"
        ]
        Resource = "*"
        Condition = {
          StringEquals = {
            "kms:ViaService" = "s3.${data.aws_region.current.name}.amazonaws.com"
          }
        }
      }
    ]
  })

  tags = merge(var.tags, {
    Name        = "bbws-access-${var.environment}-kms-audit-archive"
    Component   = "AuditService"
    Purpose     = "S3Encryption"
    Environment = var.environment
    ManagedBy   = "Terraform"
    Project     = "BBWS"
  })
}

resource "aws_kms_alias" "audit_archive" {
  name          = "alias/bbws-access-${var.environment}-audit-archive"
  target_key_id = aws_kms_key.audit_archive.key_id
}

# -----------------------------------------------------------------------------
# Primary Bucket Encryption Configuration
# -----------------------------------------------------------------------------

resource "aws_s3_bucket_server_side_encryption_configuration" "audit_archive" {
  bucket = aws_s3_bucket.audit_archive.id

  rule {
    apply_server_side_encryption_by_default {
      kms_master_key_id = aws_kms_key.audit_archive.arn
      sse_algorithm     = "aws:kms"
    }
    bucket_key_enabled = true
  }
}

# -----------------------------------------------------------------------------
# KMS Key for Replica Bucket (PROD Only - DR Region)
# -----------------------------------------------------------------------------

resource "aws_kms_replica_key" "audit_archive_replica" {
  count    = var.enable_replication ? 1 : 0
  provider = aws.replica

  description             = "Replica KMS key for audit archive S3 bucket encryption"
  primary_key_arn         = aws_kms_key.audit_archive.arn
  deletion_window_in_days = 30

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Sid    = "Enable IAM User Permissions"
        Effect = "Allow"
        Principal = {
          AWS = "arn:aws:iam::${data.aws_caller_identity.current.account_id}:root"
        }
        Action   = "kms:*"
        Resource = "*"
      },
      {
        Sid    = "Allow S3 Service"
        Effect = "Allow"
        Principal = {
          Service = "s3.amazonaws.com"
        }
        Action = [
          "kms:GenerateDataKey*",
          "kms:Decrypt"
        ]
        Resource = "*"
      }
    ]
  })

  tags = merge(var.tags, {
    Name        = "bbws-access-${var.environment}-kms-audit-archive-replica"
    Component   = "AuditService"
    Purpose     = "S3EncryptionReplica"
    Environment = var.environment
    ManagedBy   = "Terraform"
    Project     = "BBWS"
  })
}

resource "aws_kms_alias" "audit_archive_replica" {
  count    = var.enable_replication ? 1 : 0
  provider = aws.replica

  name          = "alias/bbws-access-${var.environment}-audit-archive-replica"
  target_key_id = aws_kms_replica_key.audit_archive_replica[0].key_id
}

# -----------------------------------------------------------------------------
# Replica Bucket Encryption Configuration (PROD Only)
# -----------------------------------------------------------------------------

resource "aws_s3_bucket_server_side_encryption_configuration" "audit_archive_replica" {
  count    = var.enable_replication ? 1 : 0
  provider = aws.replica

  bucket = aws_s3_bucket.audit_archive_replica[0].id

  rule {
    apply_server_side_encryption_by_default {
      kms_master_key_id = aws_kms_replica_key.audit_archive_replica[0].arn
      sse_algorithm     = "aws:kms"
    }
    bucket_key_enabled = true
  }
}
```

---

## 4. replication.tf - Cross-Region Replication (PROD Only)

```hcl
###############################################################################
# S3 Audit Storage Module - Cross-Region Replication
#
# Purpose: Configure cross-region replication for disaster recovery
# Source Region: af-south-1 (Cape Town - Primary)
# Destination Region: eu-west-1 (Ireland - DR)
#
# Note: Only enabled for PROD environment (enable_replication = true)
###############################################################################

# -----------------------------------------------------------------------------
# IAM Role for S3 Replication
# -----------------------------------------------------------------------------

resource "aws_iam_role" "replication" {
  count = var.enable_replication ? 1 : 0

  name = "bbws-access-${var.environment}-s3-replication-role"

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect = "Allow"
        Principal = {
          Service = "s3.amazonaws.com"
        }
        Action = "sts:AssumeRole"
      }
    ]
  })

  tags = merge(var.tags, {
    Name        = "bbws-access-${var.environment}-s3-replication-role"
    Component   = "AuditService"
    Purpose     = "S3Replication"
    Environment = var.environment
    ManagedBy   = "Terraform"
    Project     = "BBWS"
  })
}

# -----------------------------------------------------------------------------
# IAM Policy for S3 Replication
# -----------------------------------------------------------------------------

resource "aws_iam_policy" "replication" {
  count = var.enable_replication ? 1 : 0

  name        = "bbws-access-${var.environment}-s3-replication-policy"
  description = "Policy for S3 cross-region replication of audit archive"

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Sid    = "SourceBucketPermissions"
        Effect = "Allow"
        Action = [
          "s3:GetReplicationConfiguration",
          "s3:ListBucket"
        ]
        Resource = aws_s3_bucket.audit_archive.arn
      },
      {
        Sid    = "SourceObjectPermissions"
        Effect = "Allow"
        Action = [
          "s3:GetObjectVersionForReplication",
          "s3:GetObjectVersionAcl",
          "s3:GetObjectVersionTagging"
        ]
        Resource = "${aws_s3_bucket.audit_archive.arn}/*"
      },
      {
        Sid    = "DestinationBucketPermissions"
        Effect = "Allow"
        Action = [
          "s3:ReplicateObject",
          "s3:ReplicateDelete",
          "s3:ReplicateTags"
        ]
        Resource = "${aws_s3_bucket.audit_archive_replica[0].arn}/*"
      },
      {
        Sid    = "SourceKMSDecrypt"
        Effect = "Allow"
        Action = [
          "kms:Decrypt"
        ]
        Resource = aws_kms_key.audit_archive.arn
        Condition = {
          StringLike = {
            "kms:ViaService"    = "s3.${data.aws_region.current.name}.amazonaws.com"
            "kms:EncryptionContext:aws:s3:arn" = "${aws_s3_bucket.audit_archive.arn}/*"
          }
        }
      },
      {
        Sid    = "DestinationKMSEncrypt"
        Effect = "Allow"
        Action = [
          "kms:Encrypt"
        ]
        Resource = aws_kms_replica_key.audit_archive_replica[0].arn
        Condition = {
          StringLike = {
            "kms:ViaService"    = "s3.${var.replica_region}.amazonaws.com"
            "kms:EncryptionContext:aws:s3:arn" = "${aws_s3_bucket.audit_archive_replica[0].arn}/*"
          }
        }
      }
    ]
  })

  tags = merge(var.tags, {
    Name        = "bbws-access-${var.environment}-s3-replication-policy"
    Component   = "AuditService"
    Environment = var.environment
    ManagedBy   = "Terraform"
    Project     = "BBWS"
  })
}

# Attach Policy to Role
resource "aws_iam_role_policy_attachment" "replication" {
  count = var.enable_replication ? 1 : 0

  role       = aws_iam_role.replication[0].name
  policy_arn = aws_iam_policy.replication[0].arn
}

# -----------------------------------------------------------------------------
# S3 Bucket Replication Configuration
# -----------------------------------------------------------------------------

resource "aws_s3_bucket_replication_configuration" "audit_archive" {
  count = var.enable_replication ? 1 : 0

  # Must have versioning enabled first
  depends_on = [
    aws_s3_bucket_versioning.audit_archive,
    aws_s3_bucket_versioning.audit_archive_replica
  ]

  bucket = aws_s3_bucket.audit_archive.id
  role   = aws_iam_role.replication[0].arn

  rule {
    id       = "audit-archive-replication"
    status   = "Enabled"
    priority = 1

    # Replicate all objects
    filter {
      prefix = ""
    }

    # Delete marker replication
    delete_marker_replication {
      status = "Enabled"
    }

    # Destination configuration
    destination {
      bucket        = aws_s3_bucket.audit_archive_replica[0].arn
      storage_class = "STANDARD_IA"

      # Encryption configuration for replica
      encryption_configuration {
        replica_kms_key_id = aws_kms_replica_key.audit_archive_replica[0].arn
      }

      # Replication time control (RTC) for compliance
      replication_time {
        status = "Enabled"
        time {
          minutes = 15
        }
      }

      # Metrics and events
      metrics {
        status = "Enabled"
        event_threshold {
          minutes = 15
        }
      }
    }

    # Source selection criteria
    source_selection_criteria {
      # Replicate objects encrypted with KMS
      sse_kms_encrypted_objects {
        status = "Enabled"
      }

      # Replica modifications sync
      replica_modifications {
        status = "Enabled"
      }
    }
  }
}
```

---

## 5. policy.tf - Bucket Policy

```hcl
###############################################################################
# S3 Audit Storage Module - Bucket Policy
#
# Purpose: Define access control policies for the audit archive bucket
#
# Policies:
# - Deny all public access
# - Require HTTPS (TLS)
# - Allow audit service role to read/write
# - Deny unencrypted uploads
###############################################################################

# -----------------------------------------------------------------------------
# Primary Bucket Policy
# -----------------------------------------------------------------------------

resource "aws_s3_bucket_policy" "audit_archive" {
  bucket = aws_s3_bucket.audit_archive.id

  # Ensure public access block is applied first
  depends_on = [aws_s3_bucket_public_access_block.audit_archive]

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      # -----------------------------------------------------------------------
      # Statement 1: Deny HTTP (Require HTTPS/TLS)
      # -----------------------------------------------------------------------
      {
        Sid       = "DenyInsecureTransport"
        Effect    = "Deny"
        Principal = "*"
        Action    = "s3:*"
        Resource = [
          aws_s3_bucket.audit_archive.arn,
          "${aws_s3_bucket.audit_archive.arn}/*"
        ]
        Condition = {
          Bool = {
            "aws:SecureTransport" = "false"
          }
        }
      },
      # -----------------------------------------------------------------------
      # Statement 2: Deny Unencrypted Uploads
      # -----------------------------------------------------------------------
      {
        Sid       = "DenyUnencryptedUploads"
        Effect    = "Deny"
        Principal = "*"
        Action    = "s3:PutObject"
        Resource  = "${aws_s3_bucket.audit_archive.arn}/*"
        Condition = {
          StringNotEquals = {
            "s3:x-amz-server-side-encryption" = "aws:kms"
          }
        }
      },
      # -----------------------------------------------------------------------
      # Statement 3: Deny Wrong KMS Key
      # -----------------------------------------------------------------------
      {
        Sid       = "DenyWrongKMSKey"
        Effect    = "Deny"
        Principal = "*"
        Action    = "s3:PutObject"
        Resource  = "${aws_s3_bucket.audit_archive.arn}/*"
        Condition = {
          StringNotEquals = {
            "s3:x-amz-server-side-encryption-aws-kms-key-id" = aws_kms_key.audit_archive.arn
          }
        }
      },
      # -----------------------------------------------------------------------
      # Statement 4: Allow Audit Service Role - Archive Operations
      # -----------------------------------------------------------------------
      {
        Sid    = "AllowAuditServiceArchive"
        Effect = "Allow"
        Principal = {
          AWS = var.audit_service_role_arn
        }
        Action = [
          "s3:PutObject",
          "s3:GetObject",
          "s3:ListBucket"
        ]
        Resource = [
          aws_s3_bucket.audit_archive.arn,
          "${aws_s3_bucket.audit_archive.arn}/archive/*"
        ]
      },
      # -----------------------------------------------------------------------
      # Statement 5: Allow Audit Service Role - Export Operations
      # -----------------------------------------------------------------------
      {
        Sid    = "AllowAuditServiceExport"
        Effect = "Allow"
        Principal = {
          AWS = var.audit_service_role_arn
        }
        Action = [
          "s3:PutObject",
          "s3:GetObject",
          "s3:DeleteObject"
        ]
        Resource = "${aws_s3_bucket.audit_archive.arn}/exports/*"
      },
      # -----------------------------------------------------------------------
      # Statement 6: Deny Public Access (Explicit)
      # -----------------------------------------------------------------------
      {
        Sid       = "DenyPublicAccess"
        Effect    = "Deny"
        Principal = "*"
        Action    = "s3:*"
        Resource = [
          aws_s3_bucket.audit_archive.arn,
          "${aws_s3_bucket.audit_archive.arn}/*"
        ]
        Condition = {
          Bool = {
            "aws:PrincipalIsAWSService" = "false"
          }
          StringNotEquals = {
            "aws:PrincipalAccount" = data.aws_caller_identity.current.account_id
          }
        }
      }
    ]
  })
}

# -----------------------------------------------------------------------------
# Replica Bucket Policy (PROD Only)
# -----------------------------------------------------------------------------

resource "aws_s3_bucket_policy" "audit_archive_replica" {
  count    = var.enable_replication ? 1 : 0
  provider = aws.replica

  bucket = aws_s3_bucket.audit_archive_replica[0].id

  depends_on = [aws_s3_bucket_public_access_block.audit_archive_replica]

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      # Deny HTTP (Require HTTPS)
      {
        Sid       = "DenyInsecureTransport"
        Effect    = "Deny"
        Principal = "*"
        Action    = "s3:*"
        Resource = [
          aws_s3_bucket.audit_archive_replica[0].arn,
          "${aws_s3_bucket.audit_archive_replica[0].arn}/*"
        ]
        Condition = {
          Bool = {
            "aws:SecureTransport" = "false"
          }
        }
      },
      # Deny Unencrypted Uploads
      {
        Sid       = "DenyUnencryptedUploads"
        Effect    = "Deny"
        Principal = "*"
        Action    = "s3:PutObject"
        Resource  = "${aws_s3_bucket.audit_archive_replica[0].arn}/*"
        Condition = {
          StringNotEquals = {
            "s3:x-amz-server-side-encryption" = "aws:kms"
          }
        }
      },
      # Allow Replication from Primary
      {
        Sid    = "AllowReplicationFromPrimary"
        Effect = "Allow"
        Principal = {
          AWS = aws_iam_role.replication[0].arn
        }
        Action = [
          "s3:ReplicateObject",
          "s3:ReplicateDelete",
          "s3:ReplicateTags",
          "s3:ObjectOwnerOverrideToBucketOwner"
        ]
        Resource = "${aws_s3_bucket.audit_archive_replica[0].arn}/*"
      },
      # Deny Public Access
      {
        Sid       = "DenyPublicAccess"
        Effect    = "Deny"
        Principal = "*"
        Action    = "s3:*"
        Resource = [
          aws_s3_bucket.audit_archive_replica[0].arn,
          "${aws_s3_bucket.audit_archive_replica[0].arn}/*"
        ]
        Condition = {
          Bool = {
            "aws:PrincipalIsAWSService" = "false"
          }
          StringNotEquals = {
            "aws:PrincipalAccount" = data.aws_caller_identity.current.account_id
          }
        }
      }
    ]
  })
}
```

---

## 6. variables.tf - Input Variables

```hcl
###############################################################################
# S3 Audit Storage Module - Variables
#
# Purpose: Define input variables for the S3 audit storage module
###############################################################################

# -----------------------------------------------------------------------------
# Required Variables
# -----------------------------------------------------------------------------

variable "environment" {
  description = "Environment name (dev, sit, prod)"
  type        = string

  validation {
    condition     = contains(["dev", "sit", "prod"], var.environment)
    error_message = "Environment must be one of: dev, sit, prod."
  }
}

variable "audit_service_role_arn" {
  description = "ARN of the IAM role used by the Audit Service Lambda functions"
  type        = string

  validation {
    condition     = can(regex("^arn:aws:iam::[0-9]{12}:role/", var.audit_service_role_arn))
    error_message = "Must be a valid IAM role ARN."
  }
}

# -----------------------------------------------------------------------------
# Optional Variables
# -----------------------------------------------------------------------------

variable "enable_replication" {
  description = "Enable cross-region replication (set true for PROD only)"
  type        = bool
  default     = false
}

variable "replica_region" {
  description = "AWS region for replica bucket (DR region)"
  type        = string
  default     = "eu-west-1"
}

variable "tags" {
  description = "Additional tags to apply to all resources"
  type        = map(string)
  default     = {}
}

# -----------------------------------------------------------------------------
# Lifecycle Policy Variables
# -----------------------------------------------------------------------------

variable "archive_transition_days" {
  description = "Number of days before transitioning archive objects to Glacier"
  type        = number
  default     = 90

  validation {
    condition     = var.archive_transition_days >= 30
    error_message = "Archive transition must be at least 30 days."
  }
}

variable "archive_expiration_days" {
  description = "Number of days before archive objects expire (7 years = 2555 days)"
  type        = number
  default     = 2555

  validation {
    condition     = var.archive_expiration_days >= 365
    error_message = "Archive expiration must be at least 1 year for compliance."
  }
}

variable "export_expiration_days" {
  description = "Number of days before export files expire"
  type        = number
  default     = 30

  validation {
    condition     = var.export_expiration_days >= 1 && var.export_expiration_days <= 90
    error_message = "Export expiration must be between 1 and 90 days."
  }
}

# -----------------------------------------------------------------------------
# KMS Variables
# -----------------------------------------------------------------------------

variable "kms_key_deletion_window" {
  description = "KMS key deletion window in days"
  type        = number
  default     = 30

  validation {
    condition     = var.kms_key_deletion_window >= 7 && var.kms_key_deletion_window <= 30
    error_message = "KMS deletion window must be between 7 and 30 days."
  }
}
```

---

## 7. outputs.tf - Module Outputs

```hcl
###############################################################################
# S3 Audit Storage Module - Outputs
#
# Purpose: Export resource identifiers for use by other modules
###############################################################################

# -----------------------------------------------------------------------------
# Primary Bucket Outputs
# -----------------------------------------------------------------------------

output "bucket_name" {
  description = "Name of the audit archive S3 bucket"
  value       = aws_s3_bucket.audit_archive.id
}

output "bucket_arn" {
  description = "ARN of the audit archive S3 bucket"
  value       = aws_s3_bucket.audit_archive.arn
}

output "bucket_domain_name" {
  description = "Domain name of the audit archive S3 bucket"
  value       = aws_s3_bucket.audit_archive.bucket_domain_name
}

output "bucket_regional_domain_name" {
  description = "Regional domain name of the audit archive S3 bucket"
  value       = aws_s3_bucket.audit_archive.bucket_regional_domain_name
}

# -----------------------------------------------------------------------------
# KMS Key Outputs
# -----------------------------------------------------------------------------

output "kms_key_arn" {
  description = "ARN of the KMS key used for bucket encryption"
  value       = aws_kms_key.audit_archive.arn
}

output "kms_key_id" {
  description = "ID of the KMS key used for bucket encryption"
  value       = aws_kms_key.audit_archive.key_id
}

output "kms_key_alias" {
  description = "Alias of the KMS key"
  value       = aws_kms_alias.audit_archive.name
}

# -----------------------------------------------------------------------------
# Replica Bucket Outputs (PROD Only)
# -----------------------------------------------------------------------------

output "replica_bucket_name" {
  description = "Name of the replica audit archive S3 bucket (PROD only)"
  value       = var.enable_replication ? aws_s3_bucket.audit_archive_replica[0].id : null
}

output "replica_bucket_arn" {
  description = "ARN of the replica audit archive S3 bucket (PROD only)"
  value       = var.enable_replication ? aws_s3_bucket.audit_archive_replica[0].arn : null
}

output "replica_kms_key_arn" {
  description = "ARN of the replica KMS key (PROD only)"
  value       = var.enable_replication ? aws_kms_replica_key.audit_archive_replica[0].arn : null
}

# -----------------------------------------------------------------------------
# Replication Role Output (PROD Only)
# -----------------------------------------------------------------------------

output "replication_role_arn" {
  description = "ARN of the IAM role for S3 replication (PROD only)"
  value       = var.enable_replication ? aws_iam_role.replication[0].arn : null
}

# -----------------------------------------------------------------------------
# S3 Path Outputs (for Lambda configuration)
# -----------------------------------------------------------------------------

output "archive_prefix" {
  description = "S3 prefix for archived audit logs"
  value       = "archive/"
}

output "exports_prefix" {
  description = "S3 prefix for exported audit files"
  value       = "exports/"
}
```

---

## 8. Provider Configuration (providers.tf)

```hcl
###############################################################################
# S3 Audit Storage Module - Provider Configuration
#
# Purpose: Configure AWS providers for primary and replica regions
#
# Note: This file should be in the calling module, not the S3 module itself.
#       Included here as a reference for how to configure providers.
###############################################################################

# -----------------------------------------------------------------------------
# Provider Configuration Example (for calling module)
# -----------------------------------------------------------------------------

# Primary region provider (af-south-1 for PROD)
provider "aws" {
  region = var.primary_region

  default_tags {
    tags = {
      Project     = "BBWS"
      ManagedBy   = "Terraform"
      Environment = var.environment
    }
  }
}

# Replica region provider (eu-west-1 for DR)
provider "aws" {
  alias  = "replica"
  region = var.replica_region

  default_tags {
    tags = {
      Project     = "BBWS"
      ManagedBy   = "Terraform"
      Environment = var.environment
    }
  }
}

# -----------------------------------------------------------------------------
# Module Call Example
# -----------------------------------------------------------------------------

# Example of how to call the S3 audit storage module:

/*
module "s3_audit_storage" {
  source = "./modules/s3-audit-storage"

  environment            = var.environment
  audit_service_role_arn = module.audit_service.lambda_role_arn
  enable_replication     = var.environment == "prod" ? true : false
  replica_region         = "eu-west-1"

  tags = {
    CostCenter = "BBWS-ACCESS"
    Owner      = "AuditTeam"
  }

  providers = {
    aws         = aws
    aws.replica = aws.replica
  }
}
*/
```

---

## 9. Module Usage Examples

### 9.1 Development Environment (DEV)

```hcl
# DEV environment - No replication
module "s3_audit_storage_dev" {
  source = "./modules/s3-audit-storage"

  environment            = "dev"
  audit_service_role_arn = "arn:aws:iam::536580886816:role/bbws-access-dev-audit-service-role"
  enable_replication     = false

  tags = {
    CostCenter = "BBWS-ACCESS"
    Owner      = "AuditTeam"
  }

  providers = {
    aws         = aws
    aws.replica = aws.replica
  }
}
```

### 9.2 SIT Environment

```hcl
# SIT environment - No replication
module "s3_audit_storage_sit" {
  source = "./modules/s3-audit-storage"

  environment            = "sit"
  audit_service_role_arn = "arn:aws:iam::815856636111:role/bbws-access-sit-audit-service-role"
  enable_replication     = false

  tags = {
    CostCenter = "BBWS-ACCESS"
    Owner      = "AuditTeam"
  }

  providers = {
    aws         = aws
    aws.replica = aws.replica
  }
}
```

### 9.3 Production Environment (PROD) with Cross-Region Replication

```hcl
# PROD environment - With cross-region replication for DR
module "s3_audit_storage_prod" {
  source = "./modules/s3-audit-storage"

  environment            = "prod"
  audit_service_role_arn = "arn:aws:iam::093646564004:role/bbws-access-prod-audit-service-role"
  enable_replication     = true
  replica_region         = "eu-west-1"

  tags = {
    CostCenter = "BBWS-ACCESS"
    Owner      = "AuditTeam"
  }

  providers = {
    aws         = aws            # af-south-1
    aws.replica = aws.replica    # eu-west-1
  }
}
```

---

## 10. Bucket Structure

```
bbws-access-{env}-s3-audit-archive/
├── archive/
│   └── {orgId}/
│       └── {year}/
│           └── {month}/
│               └── {date}.json.gz
└── exports/
    └── {orgId}/
        └── {date}/
            └── {exportId}.{format}
```

### Example

```
bbws-access-dev-s3-audit-archive/
├── archive/
│   └── org-789/
│       └── 2026/
│           └── 01/
│               ├── 23.json.gz
│               └── 24.json.gz
└── exports/
    └── org-789/
        └── 2026-01-23/
            ├── exp-001.csv
            └── exp-002.json
```

---

## 11. Storage Tiers Summary

| Tier | Storage Class | Days | Purpose | Cost |
|------|---------------|------|---------|------|
| Hot | DynamoDB | 0-30 | Real-time queries (handled by DynamoDB module) | Higher |
| Warm | S3 Standard | 31-90 | Recent archive, batch queries | Medium |
| Cold | S3 Glacier | 91-2555 | Long-term compliance storage (7 years) | Lower |

---

## 12. Security Features Summary

| Feature | Status | Configuration |
|---------|--------|---------------|
| Public Access Blocked | Enabled | All 4 settings blocked |
| HTTPS Required | Enabled | Bucket policy denies HTTP |
| SSE-KMS Encryption | Enabled | Custom KMS key with rotation |
| Versioning | Enabled | Required for replication |
| Cross-Region Replication | PROD Only | af-south-1 to eu-west-1 |
| Bucket Ownership | Enforced | BucketOwnerEnforced |
| Unencrypted Upload Denied | Enabled | Bucket policy |

---

## 13. Success Criteria Checklist

- [x] Audit bucket created with naming convention `bbws-access-{env}-s3-audit-archive`
- [x] Public access blocked (all 4 settings)
- [x] SSE-KMS encryption enabled with custom key
- [x] Versioning enabled
- [x] Lifecycle policy configured (Warm to Cold after 90 days)
- [x] 7-year retention configured (2555 days)
- [x] Cross-region replication for PROD only (af-south-1 to eu-west-1)
- [x] Bucket policy restricts access (HTTPS required, audit service role allowed)
- [x] Environment parameterized (dev, sit, prod)
- [x] enable_replication flag for conditional DR setup

---

## 14. Tagging Strategy

| Tag | Value |
|-----|-------|
| Project | BBWS |
| Component | AuditService |
| Purpose | AuditLogArchive |
| CostCenter | BBWS-ACCESS |
| Environment | {env} |
| ManagedBy | Terraform |

---

**Worker Status**: COMPLETE
**Completion Date**: 2026-01-23
**Output Location**: /Users/tebogotseka/Documents/agentic_work/2_bbws_docs/project_plans/project-plan-2-access-management/stage-2-infrastructure-terraform/worker-5-s3-audit-storage-module/output.md
