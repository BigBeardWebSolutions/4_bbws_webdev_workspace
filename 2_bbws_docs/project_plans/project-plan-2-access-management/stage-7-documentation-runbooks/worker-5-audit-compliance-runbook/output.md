# Access Management - Audit & Compliance Runbook

**Document ID**: RUNBOOK-ACCESS-AUDIT-001
**Version**: 1.0
**Last Updated**: 2026-01-25
**Owner**: Security Team
**Review Frequency**: Annually

---

## 1. Overview

### 1.1 Purpose
This runbook provides procedures for audit log management, compliance verification, and regulatory reporting for the Access Management system.

### 1.2 Scope
- Audit log requirements
- Data retention policies
- Export procedures
- Compliance verification
- Regulatory considerations

### 1.3 Compliance Standards

| Standard | Requirement | Implementation |
|----------|-------------|----------------|
| POPIA | Data access logging | All access events logged |
| SOC 2 | Access controls audit trail | 7-year retention |
| Internal | Segregation of duties | Role-based access, multi-org isolation |

---

## 2. Audit Event Types

### 2.1 Event Categories

| Event Type | Description | Examples |
|------------|-------------|----------|
| AUTHENTICATION | User login/logout | Token issued, session ended |
| AUTHORIZATION | Permission checks | Access granted, access denied |
| DATA_ACCESS | Data read operations | View permission, list teams |
| DATA_MODIFICATION | Data write operations | Create role, update team |
| ADMIN_ACTION | Administrative operations | Seed permissions, bulk update |
| SECURITY_EVENT | Security-related | Failed auth, suspicious activity |
| SYSTEM_EVENT | System operations | Archive completed, export done |

### 2.2 Event Schema

```json
{
  "event_id": "evt_abc123",
  "event_type": "DATA_MODIFICATION",
  "action": "ROLE_CREATED",
  "timestamp": "2026-01-25T12:00:00.000Z",
  "actor": {
    "user_id": "user_123",
    "email": "admin@example.com",
    "ip_address": "192.168.1.1",
    "user_agent": "Mozilla/5.0..."
  },
  "organisation": {
    "org_id": "org_456",
    "name": "Example Corp"
  },
  "resource": {
    "type": "ROLE",
    "id": "role_789",
    "name": "Site Admin"
  },
  "details": {
    "permissions_assigned": ["site:create", "site:update"],
    "previous_state": null,
    "new_state": { ... }
  },
  "outcome": "SUCCESS",
  "request_id": "req_xyz789"
}
```

### 2.3 Required Events (Mandatory Logging)

| Event | When | Retention |
|-------|------|-----------|
| User login | Every authentication | 7 years |
| Permission denied | Every 403 response | 7 years |
| Role assignment | Role added/removed | 7 years |
| Team membership change | Member added/removed | 7 years |
| Admin actions | Any admin operation | 7 years |
| Data export | Export requested/completed | 7 years |

---

## 3. Data Retention Policy

### 3.1 Retention Tiers

| Tier | Storage | Duration | Cost |
|------|---------|----------|------|
| Hot | DynamoDB | 30 days | $$$ |
| Warm | S3 Standard | 90 days | $$ |
| Cold | S3 Glacier | 7 years | $ |

### 3.2 Lifecycle Transitions

```
Day 0-30:    DynamoDB (Hot)     - Full query capability
Day 31-90:   S3 Standard (Warm) - Fast retrieval
Day 91-2555: S3 Glacier (Cold)  - Archival storage
Day 2555+:   Deleted            - Automatic expiry
```

### 3.3 Retention by Environment

| Environment | Hot | Warm | Cold |
|-------------|-----|------|------|
| DEV | 7 days | 30 days | None |
| SIT | 14 days | 60 days | None |
| PROD | 30 days | 90 days | 7 years |

---

## 4. Audit Log Access

### 4.1 Query Audit Logs (Hot Storage)

```bash
# Query by organisation
curl -X GET "$API_URL/audit/events?org_id=org_123&start_date=2026-01-01&end_date=2026-01-25" \
  -H "Authorization: Bearer $TOKEN" | jq .

# Query by user
curl -X GET "$API_URL/audit/events?user_id=user_456&limit=100" \
  -H "Authorization: Bearer $TOKEN" | jq .

# Query by resource
curl -X GET "$API_URL/audit/events?resource_type=ROLE&resource_id=role_789" \
  -H "Authorization: Bearer $TOKEN" | jq .

# Query by event type
curl -X GET "$API_URL/audit/events?event_type=SECURITY_EVENT&outcome=FAILURE" \
  -H "Authorization: Bearer $TOKEN" | jq .
```

### 4.2 Query via DynamoDB (Direct Access)

```bash
# Query by organisation and date range
aws dynamodb query \
  --table-name bbws-access-$ENV-ddb-access-management \
  --index-name GSI-Audit-Org \
  --key-condition-expression "GSI1PK = :pk AND GSI1SK BETWEEN :start AND :end" \
  --expression-attribute-values '{
    ":pk": {"S": "AUDIT#ORG#org_123"},
    ":start": {"S": "2026-01-01T00:00:00Z"},
    ":end": {"S": "2026-01-25T23:59:59Z"}
  }' \
  --query 'Items[*]'
```

### 4.3 Access Warm/Cold Storage

```bash
# List archived audit files
aws s3 ls s3://bbws-access-$ENV-s3-audit-archive/audits/ --recursive

# Restore from Glacier (takes 3-5 hours for standard retrieval)
aws s3api restore-object \
  --bucket bbws-access-$ENV-s3-audit-archive \
  --key audits/2026/01/audit-20260101.json.gz \
  --restore-request '{"Days":7,"GlacierJobParameters":{"Tier":"Standard"}}'

# Check restore status
aws s3api head-object \
  --bucket bbws-access-$ENV-s3-audit-archive \
  --key audits/2026/01/audit-20260101.json.gz \
  --query 'Restore'
```

---

## 5. Audit Export Procedures

### 5.1 On-Demand Export

```bash
# Request export via API
curl -X POST "$API_URL/audit/export" \
  -H "Authorization: Bearer $TOKEN" \
  -H "Content-Type: application/json" \
  -d '{
    "org_id": "org_123",
    "start_date": "2026-01-01",
    "end_date": "2026-01-31",
    "format": "json",
    "include_details": true
  }' | jq .

# Response includes presigned URL
# {
#   "export_id": "exp_abc123",
#   "status": "PROCESSING",
#   "estimated_completion": "2026-01-25T12:30:00Z"
# }

# Check export status
curl -X GET "$API_URL/audit/export/exp_abc123" \
  -H "Authorization: Bearer $TOKEN" | jq .

# Download when complete
# {
#   "export_id": "exp_abc123",
#   "status": "COMPLETE",
#   "download_url": "https://s3.../presigned-url",
#   "expires_at": "2026-01-26T12:00:00Z",
#   "record_count": 15234
# }
```

### 5.2 Bulk Export (Large Data Sets)

```bash
# For exports > 1 million records, use async export
curl -X POST "$API_URL/audit/export/async" \
  -H "Authorization: Bearer $TOKEN" \
  -H "Content-Type: application/json" \
  -d '{
    "org_id": "org_123",
    "start_date": "2025-01-01",
    "end_date": "2025-12-31",
    "format": "parquet",
    "delivery": {
      "method": "s3",
      "bucket": "customer-audit-exports",
      "prefix": "bbws/2025/"
    }
  }'

# Export will be delivered to specified S3 bucket
# Customer will be notified via email when complete
```

### 5.3 Scheduled Reports

Automated monthly reports are generated and stored:

```bash
# Monthly reports location
s3://bbws-access-$ENV-s3-audit-archive/reports/monthly/

# Report contents
# - Summary statistics
# - Security events
# - Access patterns
# - Compliance status
```

---

## 6. Compliance Verification

### 6.1 Daily Compliance Checks

```bash
# Run compliance check script
./scripts/compliance-check.sh $ENV

# Script verifies:
# - All required events are being logged
# - Retention policies are active
# - No gaps in audit trail
# - Encryption is enabled
```

### 6.2 Monthly Compliance Report

```bash
# Generate monthly compliance report
curl -X POST "$API_URL/audit/compliance/report" \
  -H "Authorization: Bearer $TOKEN" \
  -H "Content-Type: application/json" \
  -d '{
    "month": "2026-01",
    "include_sections": [
      "access_summary",
      "security_events",
      "retention_verification",
      "encryption_status"
    ]
  }'
```

### 6.3 Compliance Checklist

| Requirement | Verification | Frequency |
|-------------|--------------|-----------|
| All access logged | Query for gaps | Daily |
| Retention policy active | Check S3 lifecycle | Weekly |
| Encryption at rest | Verify SSE-KMS | Monthly |
| Encryption in transit | TLS certificate | Monthly |
| Access controls | IAM review | Quarterly |
| Data isolation | Cross-org test | Quarterly |

---

## 7. Security Event Monitoring

### 7.1 Security Event Types

| Event | Severity | Alert |
|-------|----------|-------|
| Multiple auth failures | High | Immediate |
| Privilege escalation attempt | Critical | Immediate |
| Cross-org access attempt | Critical | Immediate |
| Unusual access pattern | Medium | Daily digest |
| Admin action outside hours | Medium | Next business day |

### 7.2 Security Event Query

```bash
# Find failed authentication attempts
curl -X GET "$API_URL/audit/events?event_type=AUTHENTICATION&outcome=FAILURE&limit=100" \
  -H "Authorization: Bearer $TOKEN" | jq '.events | group_by(.actor.user_id) | map({user: .[0].actor.user_id, count: length})'

# Find permission denied events by user
curl -X GET "$API_URL/audit/events?event_type=AUTHORIZATION&outcome=FAILURE&user_id=user_456" \
  -H "Authorization: Bearer $TOKEN" | jq .
```

### 7.3 Suspicious Activity Investigation

```bash
# 1. Identify suspicious user
USER_ID="user_suspect"

# 2. Get all activity for user
aws dynamodb query \
  --table-name bbws-access-$ENV-ddb-access-management \
  --index-name GSI-Audit-User \
  --key-condition-expression "GSI2PK = :pk" \
  --expression-attribute-values '{":pk": {"S": "AUDIT#USER#'$USER_ID'"}}' \
  --query 'Items[*]' > user_audit.json

# 3. Analyze access patterns
cat user_audit.json | jq 'group_by(.event_type) | map({type: .[0].event_type, count: length})'

# 4. Check for cross-org access
cat user_audit.json | jq '[.[] | .organisation.org_id] | unique'
```

---

## 8. Data Retention Management

### 8.1 Archive Process

Archives run automatically via scheduled Lambda:

```bash
# Manual archive trigger (if needed)
aws lambda invoke \
  --function-name bbws-access-$ENV-lambda-audit-archive \
  --payload '{"date": "2026-01-24"}' \
  response.json

# Verify archive created
aws s3 ls s3://bbws-access-$ENV-s3-audit-archive/audits/2026/01/
```

### 8.2 Verify Retention Policy

```bash
# Check S3 lifecycle rules
aws s3api get-bucket-lifecycle-configuration \
  --bucket bbws-access-$ENV-s3-audit-archive \
  --query 'Rules[*].[ID,Status,Transitions]'

# Expected rules:
# - Transition to Glacier after 90 days
# - Expire after 2555 days (7 years)
```

### 8.3 Legal Hold (If Required)

For legal/regulatory holds:

```bash
# Enable object lock on specific files
aws s3api put-object-legal-hold \
  --bucket bbws-access-$ENV-s3-audit-archive \
  --key audits/2026/01/audit-20260115.json.gz \
  --legal-hold Status=ON

# Remove hold when no longer required
aws s3api put-object-legal-hold \
  --bucket bbws-access-$ENV-s3-audit-archive \
  --key audits/2026/01/audit-20260115.json.gz \
  --legal-hold Status=OFF
```

---

## 9. Regulatory Reporting

### 9.1 POPIA Compliance

For POPIA data subject requests:

```bash
# Find all data for a user
curl -X GET "$API_URL/audit/data-subject/user_email@example.com" \
  -H "Authorization: Bearer $TOKEN" | jq .

# Generate data subject report
curl -X POST "$API_URL/audit/data-subject/report" \
  -H "Authorization: Bearer $TOKEN" \
  -H "Content-Type: application/json" \
  -d '{
    "email": "user_email@example.com",
    "request_type": "ACCESS",
    "reference": "POPIA-2026-001"
  }'
```

### 9.2 Audit Request Response

| Request Type | SLA | Procedure |
|--------------|-----|-----------|
| Internal Audit | 5 business days | Standard export |
| External Audit | 10 business days | Reviewed export |
| Regulatory | As specified | Legal team coordination |

### 9.3 Evidence Package Generation

```bash
# Generate evidence package for audit
curl -X POST "$API_URL/audit/evidence-package" \
  -H "Authorization: Bearer $TOKEN" \
  -H "Content-Type: application/json" \
  -d '{
    "audit_reference": "SOC2-2026-Q1",
    "date_range": {
      "start": "2026-01-01",
      "end": "2026-03-31"
    },
    "include": [
      "access_controls",
      "change_management",
      "security_events",
      "data_retention"
    ]
  }'
```

---

## 10. Troubleshooting

### 10.1 Missing Audit Events

| Symptom | Cause | Resolution |
|---------|-------|------------|
| Events not appearing | Lambda timeout | Check Lambda logs |
| Delayed events | Queue backlog | Check SQS depth |
| Partial events | Missing fields | Check event source |

```bash
# Check audit Lambda errors
aws logs filter-log-events \
  --log-group-name "/aws/lambda/bbws-access-$ENV-lambda-audit-log" \
  --start-time $(date -d '1 hour ago' +%s000) \
  --filter-pattern "ERROR"

# Check DLQ for failed events
aws sqs get-queue-attributes \
  --queue-url https://sqs.$AWS_REGION.amazonaws.com/$ACCOUNT_ID/bbws-access-$ENV-audit-dlq \
  --attribute-names ApproximateNumberOfMessages
```

### 10.2 Export Failures

| Error | Cause | Resolution |
|-------|-------|------------|
| Timeout | Large dataset | Use async export |
| S3 permission denied | IAM issue | Check Lambda role |
| Invalid date range | Future dates | Correct date range |

---

## 11. Contacts

| Role | Contact | Responsibility |
|------|---------|----------------|
| Security Team | security@example.com | Compliance oversight |
| Data Protection Officer | dpo@example.com | POPIA requests |
| Legal Team | legal@example.com | Regulatory matters |
| DevOps | devops@example.com | Technical issues |

---

## 12. Appendix

### A. Audit Event Codes

| Code | Event | Description |
|------|-------|-------------|
| AUTH_001 | Login Success | User authenticated |
| AUTH_002 | Login Failed | Authentication failed |
| AUTHZ_001 | Access Granted | Permission check passed |
| AUTHZ_002 | Access Denied | Permission check failed |
| DATA_001 | Record Created | New resource created |
| DATA_002 | Record Updated | Resource modified |
| DATA_003 | Record Deleted | Resource removed |
| DATA_004 | Record Viewed | Resource accessed |
| ADMIN_001 | Config Changed | System config modified |
| SEC_001 | Suspicious Activity | Potential security issue |

### B. Retention Schedule

| Data Type | DEV | SIT | PROD |
|-----------|-----|-----|------|
| Authentication logs | 7d | 14d | 7y |
| Authorization logs | 7d | 14d | 7y |
| Data access logs | 7d | 14d | 7y |
| Security events | 30d | 90d | 7y |
| System events | 7d | 30d | 1y |

---

**Document Control**

| Version | Date | Author | Changes |
|---------|------|--------|---------|
| 1.0 | 2026-01-25 | Security Team | Initial version |
