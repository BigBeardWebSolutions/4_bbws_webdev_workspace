# Worker Instructions: Audit Compliance Tests

**Worker ID**: worker-5-audit-compliance-tests
**Stage**: Stage 5 - Testing & Validation
**Project**: project-plan-2-access-management

---

## Task

Create compliance tests verifying audit log completeness, retention policies, immutability, and export functionality.

---

## Scope

### Audit Compliance Requirements
1. **Event Capture** - All auditable events logged
2. **Completeness** - Required fields present
3. **Retention** - 7-year retention enforced
4. **Immutability** - Records cannot be modified
5. **Export** - Export functionality works
6. **Privacy** - Sensitive data handling

---

## Deliverables

Create `output.md` with:

### 1. Test Directory Structure
```
tests/compliance/
├── conftest.py
├── test_audit_event_capture.py
├── test_audit_completeness.py
├── test_audit_retention.py
├── test_audit_immutability.py
├── test_audit_export.py
├── test_audit_privacy.py
└── fixtures/
    └── audit_fixtures.py
```

### 2. Auditable Events Matrix

| Service | Event Type | Must Capture |
|---------|------------|--------------|
| Permission | CREATE | Yes |
| Permission | UPDATE | Yes |
| Permission | DELETE | Yes |
| Invitation | SEND | Yes |
| Invitation | ACCEPT | Yes |
| Invitation | DECLINE | Yes |
| Invitation | CANCEL | Yes |
| Team | CREATE | Yes |
| Team | UPDATE | Yes |
| Team | MEMBER_ADD | Yes |
| Team | MEMBER_REMOVE | Yes |
| Role | CREATE | Yes |
| Role | UPDATE | Yes |
| Role | DELETE | Yes |
| Role | ASSIGN | Yes |
| Role | REVOKE | Yes |
| Auth | LOGIN | Yes |
| Auth | LOGOUT | Yes |
| Auth | TOKEN_REFRESH | Yes |
| Auth | PERMISSION_DENIED | Yes |

### 3. Audit Record Schema Validation
```json
{
  "eventId": "required, UUID",
  "eventType": "required, enum",
  "timestamp": "required, ISO8601",
  "userId": "required, UUID",
  "userEmail": "required, email",
  "organisationId": "required, UUID",
  "teamId": "optional, UUID",
  "resourceType": "required, string",
  "resourceId": "required, string",
  "action": "required, CREATE|READ|UPDATE|DELETE",
  "outcome": "required, SUCCESS|FAILURE",
  "ipAddress": "optional, IP",
  "userAgent": "optional, string",
  "before": "optional, object",
  "after": "optional, object"
}
```

### 4. Test Scenarios

#### Scenario 1: Event Capture
```python
def test_team_create_generates_audit_event():
    # Create team
    # Query audit logs
    # Verify event captured with all fields
```

#### Scenario 2: Completeness
```python
def test_audit_record_has_required_fields():
    # Verify eventId, timestamp, userId, etc.
```

#### Scenario 3: Retention
```python
def test_audit_records_have_7_year_ttl():
    # Verify TTL set correctly
    # Verify S3 lifecycle policy
```

#### Scenario 4: Immutability
```python
def test_audit_records_cannot_be_modified():
    # Attempt to modify audit record
    # Verify operation fails
```

### 5. Sample Test Implementation
Complete test file for audit event capture.

### 6. Compliance Report Template
```markdown
## Audit Compliance Report

### Event Capture Coverage
- Total auditable events: 20
- Events tested: 20
- Coverage: 100%

### Field Completeness
- Required fields: 12
- Always present: 12
- Coverage: 100%

### Retention Verification
- DynamoDB TTL: 7 years ✓
- S3 Lifecycle: Configured ✓

### Immutability Verification
- DynamoDB: IAM prevents writes ✓
- S3: Object Lock enabled ✓
```

---

## Success Criteria

- [ ] All 20+ event types tested
- [ ] All required fields validated
- [ ] Retention policy verified
- [ ] Immutability enforced
- [ ] Export functionality tested
- [ ] Privacy handling verified
- [ ] Compliance report generated

---

**Status**: PENDING
**Created**: 2026-01-23
