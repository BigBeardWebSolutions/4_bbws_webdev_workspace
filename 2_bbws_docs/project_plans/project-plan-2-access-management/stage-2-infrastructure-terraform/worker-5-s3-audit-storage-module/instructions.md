# Worker Instructions: S3 Audit Storage Module

**Worker ID**: worker-5-s3-audit-storage-module
**Stage**: Stage 2 - Infrastructure Terraform
**Project**: project-plan-2-access-management

---

## Task

Create Terraform module for S3 buckets supporting audit log storage with lifecycle policies for hot/warm/cold tiers and cross-region replication for PROD.

---

## Inputs

**From Stage 1**:
- worker-6-audit-service-review/output.md (Audit storage specs)

**LLD Reference**:
- LLD 2.8.6 Audit Service

---

## Deliverables

Create Terraform module in `output.md`:

### 1. Module Structure

```
terraform/modules/s3-audit-storage/
├── main.tf           # Bucket definitions
├── lifecycle.tf      # Lifecycle policies
├── replication.tf    # Cross-region replication
├── encryption.tf     # KMS encryption
├── variables.tf
└── outputs.tf
```

### 2. S3 Buckets

**Primary Bucket**: `bbws-access-{env}-s3-audit-archive`
**Replication Bucket** (PROD only): `bbws-access-{env}-s3-audit-archive-replica`

### 3. Lifecycle Policy (Hot/Warm/Cold)

| Tier | Storage Class | Days | Purpose |
|------|---------------|------|---------|
| Hot | (DynamoDB) | 0-30 | Real-time queries |
| Warm | S3 Standard | 31-90 | Recent archive |
| Cold | S3 Glacier | 91-2555 | 7-year compliance |

```hcl
lifecycle_rule {
  id      = "audit-archive-lifecycle"
  enabled = true

  transition {
    days          = 90
    storage_class = "GLACIER"
  }

  expiration {
    days = 2555  # 7 years
  }
}
```

### 4. Bucket Structure

```
bbws-access-{env}-s3-audit-archive/
├── year=YYYY/
│   └── month=MM/
│       └── day=DD/
│           └── org-{orgId}/
│               └── events-YYYY-MM-DD-HH.json.gz
└── exports/
    └── org-{orgId}/
        └── export-{exportId}.json.gz
```

### 5. Security Configuration

- **Public Access**: Blocked (all settings)
- **Encryption**: SSE-KMS (AWS managed key)
- **Versioning**: Enabled
- **Object Lock**: Compliance mode (for audit immutability)

### 6. Cross-Region Replication (PROD Only)

**Source**: af-south-1
**Destination**: eu-west-1

```hcl
replication_configuration {
  role = aws_iam_role.replication.arn

  rules {
    id       = "audit-replication"
    status   = "Enabled"
    priority = 1

    destination {
      bucket        = aws_s3_bucket.replica.arn
      storage_class = "STANDARD_IA"
    }
  }
}
```

### 7. Bucket Policy

- Allow audit service role to write
- Deny public access
- Require HTTPS

---

## Success Criteria

- [ ] Audit bucket created
- [ ] Public access blocked
- [ ] Encryption enabled
- [ ] Versioning enabled
- [ ] Lifecycle policy configured
- [ ] Cross-region replication (PROD only)
- [ ] Bucket policy restricts access
- [ ] Environment parameterized
- [ ] 7-year retention configured

---

## Execution Steps

1. Read Audit service review output
2. Create bucket definitions
3. Configure public access block
4. Enable encryption
5. Enable versioning
6. Create lifecycle policy
7. Configure replication (conditional for PROD)
8. Create bucket policy
9. Create variables and outputs
10. Create output.md
11. Update work.state to COMPLETE

---

**Status**: PENDING
**Created**: 2026-01-23
