# BP-001: Tenant Provisioning Process

**Version:** 1.0
**Effective Date:** 2026-01-18
**Process Owner:** Platform Operations
**Last Review:** 2026-01-18

---

## 1. Process Overview

### 1.1 Purpose
This document describes the end-to-end business process for provisioning a new tenant after a successful payment transaction on the Big Beard Web Solutions Site Builder platform.

### 1.2 Scope
- Triggered after successful PayFast payment confirmation
- Creates tenant record in DynamoDB
- Associates user with tenant
- Sets up tenant limits based on purchased plan
- Enables user access to Site Builder application

### 1.3 Process Inputs
| Input | Source | Required |
|-------|--------|----------|
| Transaction ID | PayFast ITN callback | Yes |
| Invoice Number | Payment system | Yes |
| User Email | Checkout form | Yes |
| Selected Plan | Checkout selection | Yes |
| Customer Details | Checkout form | Yes |

### 1.4 Process Outputs
| Output | Destination | Format |
|--------|-------------|--------|
| Tenant ID | DynamoDB `tenants` table | UUID |
| User Record | DynamoDB `users` table | JSON |
| Cognito User | AWS Cognito User Pool | User entity |
| Welcome Email | Customer email | HTML email |

---

## 2. Process Flow Diagram

```
┌──────────────────────────────────────────────────────────────────────────┐
│                      TENANT PROVISIONING PROCESS                          │
│                              BP-001                                       │
└──────────────────────────────────────────────────────────────────────────┘

    ┌─────────────┐
    │   START     │
    │  PayFast    │
    │  ITN        │
    │  Received   │
    └──────┬──────┘
           │
           ▼
    ┌─────────────┐     ┌─────────────────────────────────────────────┐
    │  Validate   │     │ Validation Checks:                          │
    │  Payment    │────▶│ • PayFast signature valid                   │
    │  (Lambda)   │     │ • Transaction not already processed         │
    │             │     │ • Amount matches plan price                 │
    └──────┬──────┘     └─────────────────────────────────────────────┘
           │
           │ Valid
           ▼
    ┌─────────────┐
    │  Check if   │
    │  User       │
    │  Exists     │
    └──────┬──────┘
           │
     ┌─────┴─────┐
     │           │
     ▼           ▼
┌─────────┐ ┌─────────┐
│  NEW    │ │EXISTING │
│  USER   │ │  USER   │
└────┬────┘ └────┬────┘
     │           │
     ▼           │
┌─────────────┐  │
│  Create     │  │
│  Cognito    │  │
│  User       │  │
└──────┬──────┘  │
       │         │
       ▼         │
┌─────────────┐  │
│  Send       │  │
│  Temp       │  │
│  Password   │  │
└──────┬──────┘  │
       │         │
       └────┬────┘
            │
            ▼
    ┌─────────────┐
    │  Generate   │
    │  Tenant ID  │
    │  (UUID)     │
    └──────┬──────┘
           │
           ▼
    ┌─────────────┐     ┌─────────────────────────────────────────────┐
    │  Create     │     │ Tenant Record Contains:                     │
    │  Tenant     │────▶│ • tenant_id (PK)                            │
    │  Record     │     │ • owner_user_id                             │
    │  (DynamoDB) │     │ • plan: professional/enterprise             │
    └──────┬──────┘     │ • limits: {max_sites, max_generations...}   │
           │            │ • storage_prefix: tenants/{tenant_id}       │
           │            │ • transaction_id, invoice_number            │
           │            │ • status: active                            │
           │            │ • created_at, updated_at                    │
           │            └─────────────────────────────────────────────┘
           ▼
    ┌─────────────┐     ┌─────────────────────────────────────────────┐
    │  Create     │     │ User Record Contains:                       │
    │  User       │────▶│ • user_id (PK)                              │
    │  Record     │     │ • tenant_id                                 │
    │  (DynamoDB) │     │ • email                                     │
    └──────┬──────┘     │ • role: tenant_admin                        │
           │            │ • cognito_sub                               │
           │            │ • created_at                                │
           │            └─────────────────────────────────────────────┘
           ▼
    ┌─────────────┐
    │  Update     │
    │  Order      │
    │  Status     │
    │  → COMPLETE │
    └──────┬──────┘
           │
           ▼
    ┌─────────────┐     ┌─────────────────────────────────────────────┐
    │  Send       │     │ Email Contains:                             │
    │  Welcome    │────▶│ • Welcome message                           │
    │  Email      │     │ • Login credentials (if new user)           │
    └──────┬──────┘     │ • Transaction/Invoice numbers               │
           │            │ • Link to Site Builder                      │
           │            │ • Getting started guide                     │
           │            └─────────────────────────────────────────────┘
           ▼
    ┌─────────────┐
    │    END      │
    │  Tenant     │
    │  Ready      │
    └─────────────┘
```

---

## 3. Process Steps

### Step 1: Payment Validation
| Attribute | Value |
|-----------|-------|
| Actor | ITN Handler Lambda |
| Trigger | PayFast ITN webhook |
| Duration | < 1 second |
| Failure Action | Log error, do not provision |

**Validation Rules:**
1. Verify PayFast signature matches
2. Confirm payment status = "COMPLETE"
3. Verify transaction not already processed (idempotency)
4. Confirm amount matches selected plan

### Step 2: User Account Check/Creation
| Attribute | Value |
|-----------|-------|
| Actor | Provisioning Lambda |
| System | AWS Cognito |
| Duration | 1-3 seconds |

**Logic:**
```
IF user email exists in Cognito:
    Retrieve existing user_id
    Skip password generation
ELSE:
    Create new Cognito user
    Generate temporary password
    Send password via email
    Set FORCE_CHANGE_PASSWORD status
```

### Step 3: Tenant Record Creation
| Attribute | Value |
|-----------|-------|
| Actor | Provisioning Lambda |
| System | DynamoDB `tenants` table |
| Duration | < 500ms |

**Plan Limits:**

| Plan | Max Sites | Generations/Month | Storage | Custom Domain |
|------|-----------|-------------------|---------|---------------|
| Basic | 1 | 20 | 100 MB | No |
| Professional | 5 | 100 | 500 MB | Yes |
| Enterprise | 10 | 500 | 2 GB | Yes |

### Step 4: User Record Creation
| Attribute | Value |
|-----------|-------|
| Actor | Provisioning Lambda |
| System | DynamoDB `users` table |
| Duration | < 500ms |

### Step 5: Welcome Email
| Attribute | Value |
|-----------|-------|
| Actor | SES / Email Service |
| Template | tenant-welcome |
| Duration | < 2 seconds |

---

## 4. Data Model

### 4.1 Tenant Table Schema
```json
{
  "tenant_id": "uuid",           // Partition Key
  "owner_user_id": "uuid",
  "name": "string",
  "plan": "basic|professional|enterprise",
  "status": "active|suspended|cancelled",
  "limits": {
    "max_sites": 5,
    "max_generations_per_month": 100,
    "max_storage_mb": 500,
    "custom_domain_allowed": true
  },
  "usage": {
    "sites_count": 0,
    "generations_this_month": 0,
    "storage_used_mb": 0
  },
  "storage_prefix": "tenants/{tenant_id}",
  "billing": {
    "transaction_id": "TXN-123456",
    "invoice_number": "INV-123456",
    "plan_start_date": "2026-01-18",
    "plan_end_date": "2027-01-18"
  },
  "created_at": "ISO8601",
  "updated_at": "ISO8601"
}
```

### 4.2 User Table Schema
```json
{
  "user_id": "uuid",             // Partition Key
  "tenant_id": "uuid",           // GSI
  "email": "string",             // GSI
  "cognito_sub": "string",
  "role": "tenant_admin|editor|viewer",
  "status": "active|suspended",
  "last_login": "ISO8601",
  "created_at": "ISO8601"
}
```

---

## 5. Error Handling

| Error Scenario | Response | Recovery Action |
|----------------|----------|-----------------|
| Duplicate transaction | Skip provisioning | Log, return success to PayFast |
| Cognito user creation fails | Rollback | Retry 3x, then alert support |
| DynamoDB write fails | Rollback | Retry with exponential backoff |
| Email send fails | Continue | Queue for retry, log warning |

---

## 6. Monitoring & Alerts

### 6.1 Key Metrics
| Metric | Threshold | Alert |
|--------|-----------|-------|
| Provisioning Duration | > 10 seconds | Warning |
| Provisioning Failures | > 1% | Critical |
| Email Delivery Failures | > 5% | Warning |

### 6.2 CloudWatch Alarms
- `tenant-provisioning-errors` - Errors in provisioning Lambda
- `tenant-provisioning-duration` - P95 latency
- `cognito-user-creation-failures` - Cognito API errors

---

## 7. Related Documents

| Document | Type | Location |
|----------|------|----------|
| RB-001 | Runbook | /runbooks/RB-001_Tenant_Provisioning.md |
| SOP-001 | SOP | /SOPs/SOP-001_New_Tenant_Onboarding.md |
| LLD | Technical | /LLDs/3.1.2_LLD_Site_Builder_Generation_API.md |

---

## 8. Revision History

| Version | Date | Author | Changes |
|---------|------|--------|---------|
| 1.0 | 2026-01-18 | Platform Team | Initial version |
