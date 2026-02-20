# Worker 6 Output: Audit Service LLD Review

**Worker ID**: worker-6-audit-service-review
**Stage**: Stage 1 - LLD Review & Analysis
**Project**: project-plan-2-access-management
**Source Document**: /Users/tebogotseka/Documents/agentic_work/2_bbws_docs/LLDs/2.8.6_LLD_Audit_Service.md
**Created**: 2026-01-23
**Status**: COMPLETE

---

## 1. Lambda Function Checklist (5 Functions)

| # | Function Name | Method | Endpoint/Trigger | Auth | Description |
|---|--------------|--------|------------------|------|-------------|
| 1 | get_access_logs | GET | `/v1/audit/access` | Security Officer | Query authorization audit logs |
| 2 | get_permission_logs | GET | `/v1/audit/permissions` | Security Officer | Query permission change logs |
| 3 | get_org_audit | GET | `/v1/audit/organisations/{orgId}` | Org Admin | Query org-scoped audit logs |
| 4 | get_audit_summary | GET | `/v1/audit/summary` | Security Officer | Get audit statistics |
| 5 | export_audit | POST | `/v1/audit/export` | Security Officer | Export audit logs to S3 |
| 6 | archive_expired | - | EventBridge (scheduled) | System | Archive expired events (daily at 2 AM) |

**Note**: The LLD describes 5 API-triggered functions plus 1 scheduled archive function (6 total).

### Lambda Configuration

| Attribute | Value |
|-----------|-------|
| Repository | `2_bbws_access_audit_lambda` |
| Runtime | Python 3.12 |
| Memory | 512MB |
| Timeout | 30s |
| Architecture | arm64 |
| Layer | aws-lambda-powertools |

---

## 2. API Contract Summary (5 Query Endpoints)

### 2.1 GET /v1/audit/access - Query Access Logs

**Authorization**: Security Officer role required (`audit:read`)

**Query Parameters**:
| Parameter | Type | Required | Description |
|-----------|------|----------|-------------|
| userId | string | No | Filter by acting user |
| outcome | enum | No | SUCCESS, FAILURE, DENIED |
| startDate | datetime | Yes | Start of date range (ISO 8601) |
| endDate | datetime | Yes | End of date range (ISO 8601) |
| pageSize | integer | No | Default: 50 |
| startAt | string | No | Pagination cursor |

**Response**: `AuditListResponse` (200 OK)
**Error**: 403 Forbidden (Security officer role required)

---

### 2.2 GET /v1/audit/permissions - Query Permission Change Logs

**Authorization**: Security Officer role required (`audit:read`)

**Query Parameters**:
| Parameter | Type | Required | Description |
|-----------|------|----------|-------------|
| userId | string | No | Filter by acting user |
| roleId | string | No | Filter by role |
| startDate | datetime | Yes | Start of date range (ISO 8601) |
| endDate | datetime | Yes | End of date range (ISO 8601) |
| pageSize | integer | No | Default: 50 |
| startAt | string | No | Pagination cursor |

**Response**: `AuditListResponse` (200 OK)

---

### 2.3 GET /v1/audit/organisations/{orgId} - Query Organisation Audit Logs

**Authorization**: Org Admin role required (must match path orgId)

**Path Parameters**:
| Parameter | Type | Required | Description |
|-----------|------|----------|-------------|
| orgId | string | Yes | Organisation UUID |

**Query Parameters**:
| Parameter | Type | Required | Description |
|-----------|------|----------|-------------|
| eventType | enum | No | AUTHORIZATION, PERMISSION_CHANGE, USER_MANAGEMENT, TEAM_MEMBERSHIP, ROLE_CHANGE, INVITATION, CONFIGURATION |
| userId | string | No | Filter by acting user |
| resourceType | string | No | Filter by resource type |
| startDate | datetime | Yes | Start of date range (ISO 8601) |
| endDate | datetime | Yes | End of date range (ISO 8601) |
| pageSize | integer | No | Default: 50 |
| startAt | string | No | Pagination cursor |

**Response**: `AuditListResponse` (200 OK)
**Error**: 403 Forbidden (Org admin role required for this org)

---

### 2.4 GET /v1/audit/summary - Get Audit Summary Statistics

**Authorization**: Security Officer role required

**Query Parameters**:
| Parameter | Type | Required | Description |
|-----------|------|----------|-------------|
| orgId | string | No | Filter by organisation |
| startDate | datetime | Yes | Start of date range (ISO 8601) |
| endDate | datetime | Yes | End of date range (ISO 8601) |

**Response**: `AuditSummary` (200 OK)

---

### 2.5 POST /v1/audit/export - Export Audit Logs to S3

**Authorization**: Security Officer role required (`audit:export`)

**Request Body**:
```json
{
  "orgId": "string (required)",
  "eventType": "string (optional)",
  "dateRange": {
    "startDate": "datetime (required)",
    "endDate": "datetime (required)"
  },
  "format": "csv | json (default: csv)"
}
```

**Response**: `ExportResult` (202 Accepted)
```json
{
  "exportId": "string",
  "s3Key": "string",
  "downloadUrl": "presigned URL (expires in 24h)",
  "expiresAt": "datetime",
  "recordCount": "integer"
}
```

---

## 3. Audit Event Types (7 Types)

| # | Event Type | Description | Example Actions | Retention |
|---|------------|-------------|-----------------|-----------|
| 1 | AUTHORIZATION | Access decision (allow/deny) | Login, API access, access denied | 90 days hot, 7 years cold |
| 2 | PERMISSION_CHANGE | Role/permission modifications | Add permission, remove permission | 90 days hot, 7 years cold |
| 3 | USER_MANAGEMENT | User create/update/deactivate | User created, user updated, user deactivated | 90 days hot, 7 years cold |
| 4 | TEAM_MEMBERSHIP | Team member add/remove/transfer | Add member, remove member, transfer | 90 days hot, 7 years cold |
| 5 | ROLE_CHANGE | Role assignment/revocation | Role assigned, role revoked | 90 days hot, 7 years cold |
| 6 | INVITATION | Invitation sent/accepted/declined | Invite sent, invite accepted, invite declined | 90 days hot, 7 years cold |
| 7 | CONFIGURATION | System configuration changes | Setting updated, config changed | 90 days hot, 7 years cold |

---

## 4. Audit Event Schema

### 4.1 Full Audit Event Schema

```json
{
  "eventId": "uuid (auto-generated)",
  "eventType": "AUTHORIZATION | PERMISSION_CHANGE | USER_MANAGEMENT | TEAM_MEMBERSHIP | ROLE_CHANGE | INVITATION | CONFIGURATION",
  "timestamp": "ISO 8601 with milliseconds (auto-generated)",
  "userId": "string (acting user ID)",
  "userEmail": "string (acting user email)",
  "organisationId": "string (organisation UUID)",
  "resourceType": "string (optional) - role, permission, user, team, site",
  "resourceId": "string (optional) - resource UUID",
  "action": "string - create, read, update, delete, assign, etc.",
  "outcome": "SUCCESS | FAILURE | DENIED",
  "details": {
    "// event-specific details (before/after state)": {}
  },
  "ipAddress": "string (optional) - client IP",
  "userAgent": "string (optional) - client user agent",
  "requestId": "string (optional) - API Gateway request ID",
  "ttl": "number (optional) - Unix timestamp for DynamoDB TTL (30 days)"
}
```

### 4.2 Authorization Event Example

```json
{
  "eventId": "evt-123",
  "eventType": "AUTHORIZATION",
  "timestamp": "2026-01-23T14:30:00.123Z",
  "userId": "user-456",
  "userEmail": "john@example.com",
  "organisationId": "org-789",
  "action": "access",
  "outcome": "SUCCESS",
  "details": {
    "method": "GET",
    "path": "/v1/organisations/org-789/sites",
    "requiredPermission": "site:read",
    "userPermissions": ["site:read", "site:update"]
  },
  "ipAddress": "192.168.1.100",
  "requestId": "req-abc"
}
```

### 4.3 Permission Change Event Example

```json
{
  "eventId": "evt-456",
  "eventType": "PERMISSION_CHANGE",
  "timestamp": "2026-01-23T14:35:00.456Z",
  "userId": "admin-001",
  "userEmail": "admin@example.com",
  "organisationId": "org-789",
  "resourceType": "role",
  "resourceId": "role-123",
  "action": "update_permissions",
  "outcome": "SUCCESS",
  "details": {
    "roleName": "SITE_EDITOR",
    "before": ["site:read", "site:update"],
    "after": ["site:read", "site:update", "site:publish"],
    "added": ["site:publish"],
    "removed": []
  },
  "ipAddress": "192.168.1.101",
  "requestId": "req-def"
}
```

### 4.4 Audit Outcome Enum

| Outcome | Description |
|---------|-------------|
| SUCCESS | Action completed successfully |
| FAILURE | Action failed (system/validation error) |
| DENIED | Action denied (authorization failure) |

---

## 5. Storage Tiers (Hot/Warm/Cold)

| Tier | Storage | Retention Period | Access Pattern | Cost Profile | Purpose |
|------|---------|-----------------|----------------|--------------|---------|
| Hot | DynamoDB | 0-30 days | Real-time queries | Higher | Active queries, immediate access |
| Warm | S3 Standard | 31-90 days | Batch queries | Medium | Recent archive, batch processing |
| Cold | S3 Glacier | 91 days - 7 years | Compliance retrieval | Lower | Long-term compliance storage |

### S3 Lifecycle Policy

```yaml
Rules:
  - Id: audit-archive-lifecycle
    Status: Enabled
    Transitions:
      - Days: 90
        StorageClass: GLACIER
    Expiration:
      Days: 2555  # 7 years (365 * 7)
```

### DynamoDB TTL

- Events have TTL attribute set to 30 days after creation
- When TTL expires:
  1. DynamoDB deletes the item (async)
  2. DynamoDB Streams captures the deletion
  3. Archive Lambda processes expired items to S3

---

## 6. Archive Flow (Scheduled Lambda)

### Archive Lambda Trigger

- **Trigger**: EventBridge scheduled rule
- **Schedule**: `cron(0 2 * * ? *)` - Daily at 2 AM UTC
- **Function**: `archive_expired`

### Archive Process Flow

```
1. EventBridge triggers Archive Lambda (daily at 2 AM)
   |
2. Query events with TTL between 30-31 days ago
   |
3. If events found:
   |
   ├── 4. Group events by organisation and date
   |
   ├── 5. For each org/date batch:
   |       ├── Compress events (GZIP JSON)
   |       ├── Upload to S3 archive bucket
   |       └── Log archive completion
   |
   └── 6. Return archive result
```

### S3 Archive Key Pattern

```
archive/{orgId}/{year}/{month}/{date}.json.gz
```

**Example**: `archive/org-789/2026/01/23.json.gz`

### Archive Components

| Component | Class | Responsibility |
|-----------|-------|----------------|
| ArchiveLambda | Handler | Scheduled trigger entry point |
| AuditArchiver | Service | Archive orchestration |
| S3Client | Client | Upload compressed archives |

---

## 7. Export Functionality

### Export Request Schema

```json
{
  "orgId": "string (required)",
  "eventType": "string (optional)",
  "dateRange": {
    "startDate": "datetime (required)",
    "endDate": "datetime (required)"
  },
  "format": "csv | json (default: csv)"
}
```

### Export Formats

| Format | Extension | MIME Type |
|--------|-----------|-----------|
| CSV | .csv | text/csv |
| JSON | .json | application/json |

### Export Process Flow

```
1. POST /v1/audit/export with request body
   |
2. Validate JWT + audit:export permission
   |
3. Parse ExportRequest
   |
4. Query all matching events (paginate through all results)
   |
5. Generate export file (CSV or JSON)
   |
6. Generate S3 key: exports/{orgId}/{date}/{exportId}.{format}
   |
7. Upload to S3
   |
8. Generate presigned URL (24h expiry)
   |
9. Return ExportResult (202 Accepted)
```

### Export Result Schema

```json
{
  "exportId": "string",
  "s3Key": "string",
  "downloadUrl": "string (presigned URL)",
  "expiresAt": "datetime (24h from creation)",
  "recordCount": "integer"
}
```

### Export Security

- Presigned URLs expire after 24 hours
- Rate limiting applied to prevent abuse
- Size limits enforced for large exports

---

## 8. DynamoDB Schema and GSIs

### Table Name

`bbws-aipagebuilder-{env}-ddb-access-management`

### Audit Event Entity

| Attribute | Type | Description |
|-----------|------|-------------|
| PK | String | `ORG#{organisationId}#DATE#{YYYY-MM-DD}` |
| SK | String | `EVENT#{timestamp}#{eventId}` |
| eventId | String | UUID |
| eventType | String | AUTHORIZATION, PERMISSION_CHANGE, etc. |
| timestamp | String | ISO 8601 with milliseconds |
| userId | String | Acting user ID |
| userEmail | String | Acting user email |
| organisationId | String | Organisation UUID |
| resourceType | String | role, permission, user, team, site |
| resourceId | String | Resource UUID |
| action | String | create, read, update, delete, assign, etc. |
| outcome | String | SUCCESS, FAILURE, DENIED |
| details | Map | Event-specific details (before/after state) |
| ipAddress | String | Client IP |
| userAgent | String | Client user agent |
| requestId | String | API Gateway request ID |
| ttl | Number | Unix timestamp for DynamoDB TTL (30 days) |
| GSI1PK | String | `USER#{userId}` |
| GSI1SK | String | `{timestamp}#{eventId}` |
| GSI2PK | String | `ORG#{organisationId}#TYPE#{eventType}` |
| GSI2SK | String | `{timestamp}#{eventId}` |

### GSI Definitions

| GSI Name | Partition Key (PK) | Sort Key (SK) | Purpose |
|----------|-------------------|---------------|---------|
| GSI1 | GSI1PK (`USER#{userId}`) | GSI1SK (`{timestamp}#{eventId}`) | Query by user |
| GSI2 | GSI2PK (`ORG#{orgId}#TYPE#{type}`) | GSI2SK (`{timestamp}#{eventId}`) | Query by event type |

### Access Patterns

| Pattern | Query | Index |
|---------|-------|-------|
| Events by org and date | PK=ORG#{orgId}#DATE#{date} | Table |
| Events by user | GSI1PK=USER#{userId}, GSI1SK between dates | GSI1 |
| Events by type | GSI2PK=ORG#{orgId}#TYPE#{type}, GSI2SK between dates | GSI2 |
| Recent events for org | PK=ORG#{orgId}#DATE#{today}, SK descending | Table |

---

## 9. S3 Bucket Structure

### Archive Bucket

**Bucket Name**: `bbws-aipagebuilder-{env}-s3-audit-archive`

```
bbws-aipagebuilder-{env}-s3-audit-archive/
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

### Example Structure

```
bbws-aipagebuilder-dev-s3-audit-archive/
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

### S3 Configuration Requirements

- **Block public access**: Required (all buckets must block public access)
- **Versioning**: Enabled
- **Encryption**: SSE-S3 or SSE-KMS
- **Lifecycle policy**: Transition to Glacier after 90 days
- **Cross-region replication**: PROD only (af-south-1 to eu-west-1)
- **Object Lock**: Enabled for compliance (immutable audit logs)

---

## 10. Integration Points

### Event Sources (Inbound)

All Access Management services publish audit events to the Audit Service:

| Source Service | Event Types Published |
|----------------|----------------------|
| Authorization Service | AUTHORIZATION |
| Permission Service | PERMISSION_CHANGE |
| User Service | USER_MANAGEMENT |
| Team Service | TEAM_MEMBERSHIP |
| Role Service | ROLE_CHANGE |
| Invitation Service | INVITATION |
| Configuration Service | CONFIGURATION |

### Dependencies (Outbound)

| Dependency | Purpose | Integration Type |
|------------|---------|------------------|
| DynamoDB | Hot storage (0-30 days) | AWS SDK |
| S3 | Archive storage, exports | AWS SDK |
| EventBridge | Scheduled archive trigger | Scheduled rule |
| CloudWatch | Metrics, logging, alerting | AWS SDK |
| Cognito | JWT validation | Via API Gateway Authorizer |

### API Gateway Integration

- **Authorizer**: Shared Lambda authorizer with other Access Management APIs
- **CORS**: Enabled for frontend access
- **Throttling**: Rate limiting to prevent abuse

### CloudWatch Integration

| Metric Type | Metrics |
|-------------|---------|
| Lambda | Duration, errors, invocations, cold starts |
| DynamoDB | Read/write capacity, throttled requests |
| S3 | Bucket size, object count |
| Custom | Events captured, exports generated, archive size |

---

## 11. Risk Assessment

### Identified Risks and Mitigations

| # | Risk | Impact | Likelihood | Mitigation |
|---|------|--------|------------|------------|
| 1 | High event volume | Medium | Medium | Batch writes, on-demand DynamoDB capacity |
| 2 | Query timeout on large datasets | Medium | Low | Pagination, date range limits, GSIs for efficient queries |
| 3 | Archive data loss | High | Low | S3 versioning, cross-region replication (PROD), Object Lock |
| 4 | Compliance gaps | High | Low | 7-year retention policy, immutable logs (write-only API) |
| 5 | Export abuse/DoS | Medium | Low | Rate limiting, size limits, authentication required |
| 6 | Missing events during capture | High | Low | Retry logic with exponential backoff, dead-letter queues |
| 7 | Unauthorized access to audit logs | High | Low | Role-based access (Security Officer, Org Admin), org isolation |

### Non-Functional Requirements (NFRs)

| Metric | Target |
|--------|--------|
| Query latency (p95) | < 500ms |
| Export latency (1000 records) | < 30s |
| Event capture latency | < 100ms |
| Lambda cold start | < 2s |
| Error rate | < 0.1% |
| Storage cost (per org/month) | < $5 |

### Troubleshooting Playbook

| Issue | Symptoms | Resolution |
|-------|----------|------------|
| Missing events | Events not appearing in queries | Check event capture, DynamoDB writes, verify TTL not expired |
| Slow queries | Query timeout or high latency | Reduce date range, add filters, use appropriate GSI |
| Export failed | No download URL returned | Check S3 permissions, Lambda logs, export size limits |
| Archive gaps | Missing archived data | Check archive Lambda execution, S3 upload logs |

---

## 12. Security Considerations

### Access Control Matrix

| Role | Query Access Logs | Query Permissions | Query Org Audit | Export | Summary |
|------|-------------------|-------------------|-----------------|--------|---------|
| Security Officer | Yes (all) | Yes (all) | Yes (all) | Yes | Yes |
| Org Admin | No | No | Yes (own org only) | No | No |
| Regular User | No | No | No | No | No |

### Data Protection

- **Encryption at rest**: DynamoDB KMS, S3 SSE
- **Encryption in transit**: TLS 1.3
- **Immutability**: Audit events are write-only (no update/delete API)
- **Presigned URLs**: 24-hour expiry for exports
- **Object Lock**: S3 archive uses Object Lock for compliance

### Required Permissions

| Action | Permission |
|--------|------------|
| Query access logs | `audit:read` |
| Query permissions logs | `audit:read` |
| Query org audit | `audit:read:org` (org-scoped) |
| Export audit logs | `audit:export` |
| View summary | `audit:read` |

---

## 13. Project Structure

```
2_bbws_access_audit_lambda/
├── src/
│   ├── handlers/
│   │   ├── __init__.py
│   │   ├── query/
│   │   │   ├── __init__.py
│   │   │   ├── get_access_logs.py
│   │   │   ├── get_permission_logs.py
│   │   │   ├── get_org_audit.py
│   │   │   └── get_summary.py
│   │   ├── export/
│   │   │   ├── __init__.py
│   │   │   └── export_audit.py
│   │   └── archive/
│   │       ├── __init__.py
│   │       └── archive_expired.py
│   ├── services/
│   │   ├── __init__.py
│   │   ├── audit_service.py
│   │   ├── export_service.py
│   │   └── archive_service.py
│   ├── repositories/
│   │   ├── __init__.py
│   │   └── audit_repository.py
│   ├── models/
│   │   ├── __init__.py
│   │   ├── audit_event.py
│   │   ├── filters.py
│   │   └── requests.py
│   └── utils/
│       ├── __init__.py
│       ├── response_builder.py
│       └── csv_generator.py
├── tests/
│   ├── unit/
│   │   ├── test_handlers/
│   │   ├── test_services/
│   │   └── test_repositories/
│   └── integration/
│       └── test_api.py
├── terraform/
│   ├── main.tf
│   ├── api_gateway.tf
│   ├── lambda.tf
│   ├── s3.tf
│   ├── eventbridge.tf
│   ├── iam.tf
│   ├── variables.tf
│   └── outputs.tf
├── openapi/
│   └── audit-service-api.yaml
├── requirements.txt
├── pytest.ini
└── README.md
```

---

## 14. Tagging Strategy

| Tag | Value |
|-----|-------|
| Project | BBWS |
| Component | AuditService |
| CostCenter | BBWS-ACCESS |
| Environment | {env} |
| ManagedBy | Terraform |

---

## 15. Open Items (TBC)

| # | Item | Status | Notes |
|---|------|--------|-------|
| TBC-001 | Real-time audit streaming (Kinesis) | Open | Future enhancement for real-time dashboards |
| TBC-002 | SIEM integration | Open | Integration with security monitoring tools |
| TBC-003 | Anomaly detection | Open | ML-based suspicious activity detection |

---

## 16. User Stories Summary

| User Story # | Epic | User Story | Test Scenario |
|--------------|------|------------|---------------|
| US-AUDIT-001 | Query | As a security officer, I want to query access logs | Given valid filters, when GET /audit/access, then return filtered logs |
| US-AUDIT-002 | Query | As a security officer, I want to query permission changes | Given date range, when GET /audit/permissions, then return changes |
| US-AUDIT-003 | Query | As an org admin, I want to view my org's audit logs | Given org admin, when GET /audit/org/{id}, then return org logs |
| US-AUDIT-004 | Query | As a security officer, I want audit statistics | Given date range, when GET /audit/summary, then return stats |
| US-AUDIT-005 | Export | As a security officer, I want to export logs | Given export request, when POST /audit/export, then generate S3 file |
| US-AUDIT-006 | Capture | As a system, I capture all authorization decisions | Given any API call, when authorized, then audit event created |
| US-AUDIT-007 | Capture | As a system, I capture all permission changes | Given role update, when saved, then audit event created |
| US-AUDIT-008 | Security | As a user, I cannot access another org's audit | Given user from org A, when access org B audit, then 403 |
| US-AUDIT-009 | Retention | As a system, I archive old audit logs to S3 | Given log > 30 days, when TTL expires, then archived to S3 |
| US-AUDIT-010 | Compliance | As a system, I retain audit logs for 7 years | Given archived log, when 7 years pass, then eligible for deletion |

---

## 17. Success Criteria Checklist

- [x] All 6 Lambda functions documented (5 API + 1 scheduled)
- [x] Event types listed (7 types)
- [x] Event schema defined (full schema with examples)
- [x] Storage tiers documented (Hot/Warm/Cold)
- [x] Archive flow explained (scheduled Lambda process)
- [x] Export functionality specified (formats, delivery, filters)
- [x] DynamoDB schema complete (entity + 2 GSIs)
- [x] S3 structure defined (archive + exports)
- [x] Integration points identified (all services, EventBridge, S3, CloudWatch)
- [x] Risks assessed (7 risks with mitigations)

---

**Worker Status**: COMPLETE
**Completion Date**: 2026-01-23
**Output Location**: /Users/tebogotseka/Documents/agentic_work/2_bbws_docs/project_plans/project-plan-2-access-management/stage-1-lld-review-analysis/worker-6-audit-service-review/output.md
