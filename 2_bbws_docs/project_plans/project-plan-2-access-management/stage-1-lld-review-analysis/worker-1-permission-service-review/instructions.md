# Worker Instructions: Permission Service LLD Review

**Worker ID**: worker-1-permission-service-review
**Stage**: Stage 1 - LLD Review & Analysis
**Project**: project-plan-2-access-management

---

## Task

Review the Permission Service LLD (2.8.1) and extract implementation-ready specifications including Lambda function signatures, API contracts, DynamoDB schema, and integration points.

---

## Inputs

**Primary Input**:
- `/Users/tebogotseka/Documents/agentic_work/2_bbws_docs/LLDs/2.8.1_LLD_Permission_Service.md`

**Supporting Inputs**:
- `/Users/tebogotseka/Documents/agentic_work/2_bbws_docs/HLDs/2.8_HLD_Access_Management.md`
- `/Users/tebogotseka/Documents/agentic_work/2_bbws_docs/BRS/2.8_BRS_Access_Management.md`

---

## Deliverables

Create `output.md` with the following sections:

### 1. Lambda Function Checklist

| # | Function Name | Handler | Method | Endpoint | Priority |
|---|--------------|---------|--------|----------|----------|
| 1 | permission_list | list_handler.lambda_handler | GET | /permissions | HIGH |
| ... | ... | ... | ... | ... | ... |

### 2. API Contract Summary

For each endpoint:
- HTTP Method
- Path
- Path Parameters
- Query Parameters
- Request Body Schema
- Response Schema (200, 400, 404, 500)
- Required Permissions

### 3. DynamoDB Schema

- Table Name: `bbws-access-{env}-ddb-permissions`
- Primary Key Pattern
- Sort Key Pattern
- GSI Definitions
- Entity Attributes

### 4. Pydantic Models Required

List all model classes:
- Permission
- PermissionScope
- PermissionAction
- CreatePermissionRequest
- UpdatePermissionRequest
- PaginatedPermissionResponse

### 5. Integration Points

| Integration | Service | Direction | Purpose |
|-------------|---------|-----------|---------|
| Cognito | Authentication | Inbound | JWT validation |
| Audit Service | Audit | Outbound | Log changes |

### 6. Risk Assessment

| Risk | Impact | Mitigation |
|------|--------|------------|
| Circular permission dependencies | HIGH | Validate on create |
| ... | ... | ... |

---

## Expected Output Format

```markdown
# Permission Service LLD Review Output

## Lambda Function Checklist

| # | Function Name | Handler | Method | Endpoint | Priority |
|---|--------------|---------|--------|----------|----------|
| 1 | permission_list | list_handler.lambda_handler | GET | /v1/permissions | HIGH |
| 2 | permission_get | get_handler.lambda_handler | GET | /v1/permissions/{id} | HIGH |
| 3 | permission_create | create_handler.lambda_handler | POST | /v1/permissions | HIGH |
| 4 | permission_update | update_handler.lambda_handler | PUT | /v1/permissions/{id} | MEDIUM |
| 5 | permission_delete | delete_handler.lambda_handler | DELETE | /v1/permissions/{id} | MEDIUM |
| 6 | permission_seed | seed_handler.lambda_handler | POST | /v1/permissions/seed | LOW |

## API Contract Summary

### GET /v1/permissions
**Purpose**: List all permissions with pagination
**Query Parameters**:
- pageSize (int, optional, default: 20)
- startAt (string, optional)
**Response 200**:
```json
{
  "items": [...],
  "pageSize": 20,
  "moreAvailable": true
}
```

(Continue for each endpoint...)

## DynamoDB Schema

**Table**: bbws-access-{env}-ddb-permissions

| Entity | PK | SK | Attributes |
|--------|----|----|------------|
| Permission | PERMISSION#{id} | METADATA | name, scope, action, ... |

**GSI-1**: PermissionByScopeIndex
- PK: scope
- SK: action

## Pydantic Models Required

1. **Permission** - Core entity model
2. **PermissionScope** - Enum (TEAM, SITE, ORGANISATION, PLATFORM)
3. **PermissionAction** - Enum (READ, WRITE, DELETE, ADMIN)
4. **CreatePermissionRequest** - Request body validation
5. **UpdatePermissionRequest** - Request body validation
6. **PaginatedPermissionResponse** - Response model

## Integration Points

| Integration | Service | Direction | Purpose |
|-------------|---------|-----------|---------|
| Cognito | Authentication | Inbound | JWT validation |
| Audit Service | Audit | Outbound | Log permission changes |
| Role Service | Role | Outbound | Permission bundling |

## Risk Assessment

| Risk | Impact | Mitigation |
|------|--------|------------|
| Permission scope mismatch | HIGH | Validate scope on assignment |
| Orphaned permissions | MEDIUM | Cascade validation |

## Implementation Notes

- Platform permissions are seeded, not user-created
- Soft delete pattern (active=false)
- All changes must be audited
```

---

## Success Criteria

- [ ] All 6 Lambda functions documented
- [ ] All API endpoints fully specified
- [ ] DynamoDB schema extracted
- [ ] All Pydantic models listed
- [ ] Integration points identified
- [ ] Risks assessed with mitigations
- [ ] Output follows expected format

---

## Execution Steps

1. Read LLD 2.8.1 completely
2. Extract Lambda function specifications from Section 3
3. Document API contracts from Section 6 (OpenAPI)
4. Extract DynamoDB schema from Section 5
5. List Pydantic models from Section 7
6. Identify integration points
7. Assess implementation risks
8. Create output.md with all sections
9. Update work.state to COMPLETE

---

**Status**: PENDING
**Created**: 2026-01-23
