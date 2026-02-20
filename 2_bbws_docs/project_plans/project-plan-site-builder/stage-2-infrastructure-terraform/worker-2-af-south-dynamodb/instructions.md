# Worker Instructions: DynamoDB Terraform Module

**Worker ID**: worker-2-af-south-dynamodb
**Stage**: Stage 2 - Infrastructure (Terraform)
**Project**: project-plan-site-builder

---

## Task

Create Terraform module for all DynamoDB tables in af-south-1, including GSIs, PITR configuration, and proper access patterns.

---

## Inputs

**Reference Documents**:
- `/Users/tebogotseka/Documents/agentic_work/2_bbws_docs/LLDs/3.1.2_LLD_Site_Builder_Generation_API.md` (Section 6: DynamoDB Tables)
- `/Users/tebogotseka/Documents/agentic_work/2_bbws_docs/HLDs/BBSW_Site_Builder_HLD_v3.md` (Section 8: Data Storage)

---

## Deliverables

Create the following DynamoDB tables:

### 1. Tenants Table

| Attribute | Type | Key |
|-----------|------|-----|
| PK | S | HASH (TENANT#{id}) |
| SK | S | RANGE (METADATA) |
| email | S | GSI-1 |
| organizationName | S | - |
| status | S | - |
| subscription | M | - |
| branding | M | - |
| createdAt | S | - |
| active | BOOL | - |

**GSI-1**: email-index (email, PK)

### 2. Users Table

| Attribute | Type | Key |
|-----------|------|-----|
| PK | S | HASH (USER#{id}) |
| SK | S | RANGE (METADATA) |
| tenantId | S | GSI-1 |
| email | S | GSI-2 |
| role | S | - |
| teams | L | - |
| invitedBy | S | - |
| status | S | - |
| active | BOOL | - |

**GSI-1**: tenant-index (tenantId, SK)
**GSI-2**: email-index (email, PK)

### 3. Sites Table

| Attribute | Type | Key |
|-----------|------|-----|
| PK | S | HASH (SITE#{id}) |
| SK | S | RANGE (VERSION#{version}) |
| tenantId | S | GSI-1 |
| name | S | - |
| status | S | - |
| html | S | - |
| css | S | - |
| brandScore | N | - |
| deployedUrl | S | - |
| createdBy | S | - |
| active | BOOL | - |

**GSI-1**: tenant-index (tenantId, SK)

### 4. Generations Table

| Attribute | Type | Key |
|-----------|------|-----|
| PK | S | HASH (GEN#{id}) |
| SK | S | RANGE (METADATA) |
| tenantId | S | GSI-1 |
| siteId | S | GSI-2 |
| status | S | - |
| prompt | S | - |
| agentSessionId | S | - |
| tokens | M | - |
| createdAt | S | - |

**GSI-1**: tenant-index (tenantId, createdAt)
**GSI-2**: site-index (siteId, createdAt)

### 5. Templates Table

| Attribute | Type | Key |
|-----------|------|-----|
| PK | S | HASH (TPL#{id}) |
| SK | S | RANGE (METADATA) |
| tenantId | S | GSI-1 (null = global) |
| name | S | - |
| category | S | - |
| thumbnail | S | - |
| html | S | - |
| active | BOOL | - |

**GSI-1**: tenant-index (tenantId, SK)

### 6. Partners Table

| Attribute | Type | Key |
|-----------|------|-----|
| PK | S | HASH (PARTNER#{id}) |
| SK | S | RANGE (METADATA) |
| name | S | - |
| status | S | - |
| subscription | M | - |
| branding | M | - |
| customDomain | S | GSI-1 |
| marketplaceId | S | - |
| active | BOOL | - |

**GSI-1**: domain-index (customDomain)

---

## Files to Create

### 1. main.tf
```hcl
resource "aws_dynamodb_table" "tenants" {
  name         = "bbws-tenants-${var.environment}"
  billing_mode = "PAY_PER_REQUEST"

  hash_key  = "PK"
  range_key = "SK"

  attribute {
    name = "PK"
    type = "S"
  }

  attribute {
    name = "SK"
    type = "S"
  }

  attribute {
    name = "email"
    type = "S"
  }

  global_secondary_index {
    name            = "email-index"
    hash_key        = "email"
    range_key       = "PK"
    projection_type = "ALL"
  }

  point_in_time_recovery {
    enabled = true
  }

  tags = merge(var.tags, {
    Name = "bbws-tenants-${var.environment}"
  })
}

# ... similar for other tables
```

### 2. variables.tf
```hcl
variable "environment" {
  description = "Environment name (dev, sit, prod)"
  type        = string
}

variable "region" {
  description = "AWS region"
  type        = string
  default     = "af-south-1"
}

variable "tags" {
  description = "Resource tags"
  type        = map(string)
  default     = {}
}
```

### 3. outputs.tf
```hcl
output "tenants_table_name" {
  value = aws_dynamodb_table.tenants.name
}

output "tenants_table_arn" {
  value = aws_dynamodb_table.tenants.arn
}

# ... similar for other tables
```

### 4. iam.tf
```hcl
# IAM policies for Lambda access to DynamoDB
data "aws_iam_policy_document" "dynamodb_access" {
  statement {
    effect = "Allow"
    actions = [
      "dynamodb:GetItem",
      "dynamodb:PutItem",
      "dynamodb:UpdateItem",
      "dynamodb:DeleteItem",
      "dynamodb:Query",
      "dynamodb:Scan"
    ]
    resources = [
      aws_dynamodb_table.tenants.arn,
      "${aws_dynamodb_table.tenants.arn}/index/*",
      # ... other tables
    ]
  }
}
```

---

## Success Criteria

- [ ] All 6 tables created with correct schema
- [ ] All GSIs configured
- [ ] On-demand capacity mode for all tables
- [ ] PITR enabled for all tables
- [ ] Proper tagging on all resources
- [ ] IAM policy for Lambda access
- [ ] `terraform validate` passes
- [ ] `terraform plan` produces no errors

---

## Execution Steps

1. Read API LLD Section 6 for schema
2. Create main.tf with all tables
3. Create variables.tf
4. Create outputs.tf
5. Create IAM policy
6. Run `terraform validate`
7. Update work.state to COMPLETE

---

**Status**: PENDING
**Created**: 2026-01-16
