# Worker Instructions: Audit Service Lambdas

**Worker ID**: worker-6-audit-service-lambdas
**Stage**: Stage 3 - Lambda Services Development
**Project**: project-plan-2-access-management

---

## Task

Implement 6 Lambda functions for the Audit Service handling audit event logging, querying, export, and archival.

---

## Inputs

**From Stage 1**:
- `/stage-1-lld-review-analysis/worker-6-audit-service-review/output.md`

**From Stage 2**:
- S3 audit storage configuration

**LLD Reference**:
- `/2_bbws_docs/LLDs/2.8.6_LLD_Audit_Service.md`

---

## Lambda Functions (6)

| # | Function | Method | Endpoint/Trigger |
|---|----------|--------|------------------|
| 1 | query_org_audit | GET | /v1/orgs/{orgId}/audit |
| 2 | query_user_audit | GET | /v1/orgs/{orgId}/audit/users/{userId} |
| 3 | query_resource_audit | GET | /v1/orgs/{orgId}/audit/resources/{type}/{id} |
| 4 | get_audit_summary | GET | /v1/orgs/{orgId}/audit/summary |
| 5 | export_audit | POST | /v1/orgs/{orgId}/audit/export |
| 6 | archive_audit | - | EventBridge (scheduled) |

---

## Deliverables

### 1. Project Structure
```
lambda/audit_service/
├── __init__.py
├── handlers/
│   ├── __init__.py
│   ├── query_org_handler.py
│   ├── query_user_handler.py
│   ├── query_resource_handler.py
│   ├── summary_handler.py
│   ├── export_handler.py
│   └── archive_handler.py
├── models/
│   ├── __init__.py
│   ├── audit_event.py
│   └── requests.py
├── services/
│   ├── __init__.py
│   ├── audit_query_service.py
│   ├── audit_export_service.py
│   └── audit_archive_service.py
├── repositories/
│   ├── __init__.py
│   ├── audit_repository.py
│   └── s3_repository.py
└── tests/
```

### 2. Audit Event Types

```python
class AuditEventType(str, Enum):
    AUTHORIZATION = "AUTHORIZATION"
    PERMISSION_CHANGE = "PERMISSION_CHANGE"
    USER_MANAGEMENT = "USER_MANAGEMENT"
    TEAM_MEMBERSHIP = "TEAM_MEMBERSHIP"
    ROLE_CHANGE = "ROLE_CHANGE"
    INVITATION = "INVITATION"
    CONFIGURATION = "CONFIGURATION"

class AuditEvent(BaseModel):
    event_id: str
    event_type: AuditEventType
    timestamp: datetime
    org_id: str
    actor_id: str
    actor_type: str  # USER, SYSTEM
    action: str
    resource_type: str
    resource_id: str
    details: dict
    outcome: str  # SUCCESS, FAILURE
    ip_address: Optional[str]
    user_agent: Optional[str]
```

### 3. Storage Tiers

```python
class StorageTier(str, Enum):
    HOT = "HOT"      # DynamoDB, 0-30 days
    WARM = "WARM"    # S3 Standard, 31-90 days
    COLD = "COLD"    # S3 Glacier, 91+ days

HOT_RETENTION_DAYS = 30
WARM_RETENTION_DAYS = 90
COLD_RETENTION_YEARS = 7
```

### 4. Audit Logger (for other services)

```python
class AuditLogger:
    """Utility class for other services to log audit events."""

    def __init__(self, dynamodb_table):
        self.table = dynamodb_table

    def log(
        self,
        event_type: AuditEventType,
        org_id: str,
        actor_id: str,
        action: str,
        resource_type: str,
        resource_id: str,
        details: dict,
        outcome: str = "SUCCESS"
    ) -> str:
        event = AuditEvent(
            event_id=str(uuid.uuid4()),
            event_type=event_type,
            timestamp=datetime.utcnow(),
            org_id=org_id,
            actor_id=actor_id,
            actor_type="USER",
            action=action,
            resource_type=resource_type,
            resource_id=resource_id,
            details=details,
            outcome=outcome
        )
        self._write_to_dynamodb(event)
        return event.event_id
```

### 5. Archive Handler

```python
def archive_handler(event: dict, context):
    """
    Scheduled Lambda to archive old events:
    1. Query events older than HOT_RETENTION_DAYS
    2. Export to S3 as compressed JSON
    3. Delete from DynamoDB
    4. S3 lifecycle handles Warm→Cold transition
    """
    cutoff = datetime.utcnow() - timedelta(days=HOT_RETENTION_DAYS)

    # Get events to archive
    events = query_events_before(cutoff)

    # Group by org and date
    grouped = group_events_by_org_date(events)

    for (org_id, date), org_events in grouped.items():
        # Write to S3
        s3_key = f"year={date.year}/month={date.month:02d}/day={date.day:02d}/org-{org_id}/events.json.gz"
        write_to_s3(org_events, s3_key)

        # Delete from DynamoDB
        delete_events(org_events)
```

### 6. Export Handler

```python
def export_handler(event: dict, context):
    """
    Export audit logs to S3 with presigned URL:
    1. Query events with filters
    2. Write to S3 exports folder
    3. Generate presigned URL (24h expiry)
    4. Return URL to caller
    """
    request = parse_export_request(event)

    events = query_events(
        org_id=request.org_id,
        start_date=request.start_date,
        end_date=request.end_date,
        event_types=request.event_types
    )

    export_key = f"exports/org-{request.org_id}/export-{uuid.uuid4()}.json.gz"
    write_to_s3(events, export_key)

    presigned_url = generate_presigned_url(export_key, expiry=86400)

    return {
        "export_id": export_key,
        "download_url": presigned_url,
        "expires_at": (datetime.utcnow() + timedelta(days=1)).isoformat(),
        "event_count": len(events)
    }
```

---

## Success Criteria

- [ ] All 6 Lambda handlers implemented
- [ ] Audit event logging utility
- [ ] Query by org, user, resource
- [ ] Summary statistics
- [ ] Export with presigned URLs
- [ ] Archive scheduled handler
- [ ] Compressed JSON storage
- [ ] TTL for DynamoDB (30 days)
- [ ] Tests with moto (DynamoDB + S3)
- [ ] > 80% code coverage

---

## Execution Steps

1. Read Stage 1 audit review output
2. Create audit event models
3. Implement audit logger utility
4. Implement query handlers (TDD)
5. Implement summary handler
6. Implement export handler with S3
7. Implement archive handler
8. Ensure all tests pass
9. Create output.md
10. Update work.state to COMPLETE

---

**Status**: PENDING
**Created**: 2026-01-23
