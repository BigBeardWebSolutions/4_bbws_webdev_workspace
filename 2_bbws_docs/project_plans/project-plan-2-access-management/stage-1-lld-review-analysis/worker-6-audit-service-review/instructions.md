# Worker Instructions: Audit Service LLD Review

**Worker ID**: worker-6-audit-service-review
**Stage**: Stage 1 - LLD Review & Analysis
**Project**: project-plan-2-access-management

---

## Task

Review the Audit Service LLD (2.8.6) and extract implementation-ready specifications. This service provides compliance-ready audit logging with multi-tier storage (hot/warm/cold) and 7-year retention.

---

## Inputs

**Primary Input**:
- `/Users/tebogotseka/Documents/agentic_work/2_bbws_docs/LLDs/2.8.6_LLD_Audit_Service.md`

**Supporting Inputs**:
- `/Users/tebogotseka/Documents/agentic_work/2_bbws_docs/HLDs/2.8_HLD_Access_Management.md`

---

## Deliverables

Create `output.md` with the following sections:

### 1. Lambda Function Checklist (5 functions)

| # | Function Name | Method | Endpoint/Trigger |
|---|--------------|--------|------------------|
| 1 | audit_query_org | GET | /orgs/{orgId}/audit |
| 2 | audit_query_user | GET | /orgs/{orgId}/audit/users/{userId} |
| 3 | audit_query_resource | GET | /orgs/{orgId}/audit/resources/{type}/{id} |
| 4 | audit_export | POST | /orgs/{orgId}/audit/export |
| 5 | audit_archive | - | EventBridge (scheduled) |

### 2. API Contract Summary

Document all 4 query endpoints with filtering and pagination.

### 3. Audit Event Types

| Event Type | Description | Example |
|------------|-------------|---------|
| AUTHORIZATION | Auth decisions | Login, access denied |
| PERMISSION_CHANGE | Permission modifications | Added permission |
| USER_MANAGEMENT | User operations | User created |
| TEAM_MEMBERSHIP | Team changes | Added to team |
| ROLE_CHANGE | Role modifications | Role assigned |
| INVITATION | Invitation events | Invite sent |
| CONFIGURATION | Config changes | Setting updated |

### 4. Audit Event Schema

```json
{
  "eventId": "uuid",
  "eventType": "TEAM_MEMBERSHIP",
  "timestamp": "ISO8601",
  "orgId": "org-123",
  "actorId": "user-456",
  "actorType": "USER",
  "action": "ADD_MEMBER",
  "resourceType": "TEAM",
  "resourceId": "team-789",
  "details": {...},
  "outcome": "SUCCESS"
}
```

### 5. Storage Tiers

| Tier | Storage | Retention | Purpose |
|------|---------|-----------|---------|
| Hot | DynamoDB | 30 days | Active queries |
| Warm | S3 Standard | 90 days | Recent archive |
| Cold | S3 Glacier | 7 years | Compliance |

### 6. Archive Flow

Document the scheduled archive process:
1. Query events older than 30 days
2. Export to S3 (JSON)
3. Delete from DynamoDB
4. Transition to Glacier after 90 days

### 7. Export Functionality

- Export format: JSON
- Delivery: S3 presigned URL
- Filters: date range, event type, actor

### 8. DynamoDB Schema

**Table**: bbws-access-{env}-ddb-audit

| Entity | PK | SK | Attributes |
|--------|----|----|------------|
| AuditEvent | ORG#{orgId} | EVENT#{timestamp}#{eventId} | ... |

**GSI-1**: AuditByActorIndex
**GSI-2**: AuditByResourceIndex
**GSI-3**: AuditByTypeIndex

### 9. S3 Bucket Structure

```
bbws-access-{env}-s3-audit-archive/
├── year=2026/
│   ├── month=01/
│   │   ├── day=23/
│   │   │   ├── org-123/
│   │   │   │   └── events-2026-01-23.json.gz
```

### 10. Integration Points

- All services (event publishing)
- EventBridge (scheduled archive)
- S3 (storage)
- CloudWatch (metrics)

### 11. Risk Assessment

- Data loss during archive
- Query performance on large datasets
- Export timeout for large exports

---

## Success Criteria

- [ ] All 5 Lambda functions documented
- [ ] Event types listed
- [ ] Event schema defined
- [ ] Storage tiers documented
- [ ] Archive flow explained
- [ ] Export functionality specified
- [ ] DynamoDB schema complete
- [ ] S3 structure defined
- [ ] Integration points identified
- [ ] Risks assessed

---

## Execution Steps

1. Read LLD 2.8.6 completely
2. Extract Lambda specifications
3. Document API contracts
4. List all event types
5. Define event schema
6. Document storage tiers
7. Explain archive flow
8. Specify export functionality
9. Extract DynamoDB schema
10. Define S3 structure
11. Identify integration points
12. Assess risks
13. Create output.md
14. Update work.state to COMPLETE

---

**Status**: PENDING
**Created**: 2026-01-23
