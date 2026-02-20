# Worker Instructions: Invitation Service LLD Review

**Worker ID**: worker-2-invitation-service-review
**Stage**: Stage 1 - LLD Review & Analysis
**Project**: project-plan-2-access-management

---

## Task

Review the Invitation Service LLD (2.8.2) and extract implementation-ready specifications including Lambda function signatures, API contracts, DynamoDB schema, email templates, and integration points.

---

## Inputs

**Primary Input**:
- `/Users/tebogotseka/Documents/agentic_work/2_bbws_docs/LLDs/2.8.2_LLD_Invitation_Service.md`

**Supporting Inputs**:
- `/Users/tebogotseka/Documents/agentic_work/2_bbws_docs/HLDs/2.8_HLD_Access_Management.md`

---

## Deliverables

Create `output.md` with the following sections:

### 1. Lambda Function Checklist

| # | Function Name | Handler | Method | Endpoint | Priority |
|---|--------------|---------|--------|----------|----------|
| 1 | invitation_create | create_handler.lambda_handler | POST | /orgs/{orgId}/invitations | HIGH |
| 2 | invitation_list | list_handler.lambda_handler | GET | /orgs/{orgId}/invitations | HIGH |
| ... | ... | ... | ... | ... | ... |

### 2. API Contract Summary

Document all 7 endpoints with:
- Request/response schemas
- Path parameters
- Query parameters
- Error responses

### 3. DynamoDB Schema

- Table structure
- Invitation entity attributes
- TTL configuration for expiry
- GSI for email lookup

### 4. Email Templates Required

| Template | Purpose | Variables |
|----------|---------|-----------|
| invitation_email.html | New invitation | org_name, inviter_name, accept_url |
| reminder_email.html | Resend invitation | ... |

### 5. Invitation State Machine

Document the invitation lifecycle:
- PENDING → ACCEPTED
- PENDING → EXPIRED
- PENDING → CANCELLED

### 6. Integration Points

| Integration | Service | Direction | Purpose |
|-------------|---------|-----------|---------|
| SES | Email | Outbound | Send invitations |
| Team Service | Team | Outbound | Add to team on accept |
| ... | ... | ... | ... |

### 7. Risk Assessment

Document implementation risks and mitigations.

---

## Expected Output Format

```markdown
# Invitation Service LLD Review Output

## Lambda Function Checklist

| # | Function Name | Handler | Method | Endpoint | Priority |
|---|--------------|---------|--------|----------|----------|
| 1 | invitation_create | create_handler.lambda_handler | POST | /v1/orgs/{orgId}/invitations | HIGH |
| 2 | invitation_list | list_handler.lambda_handler | GET | /v1/orgs/{orgId}/invitations | HIGH |
| 3 | invitation_get | get_handler.lambda_handler | GET | /v1/orgs/{orgId}/invitations/{id} | MEDIUM |
| 4 | invitation_cancel | cancel_handler.lambda_handler | DELETE | /v1/orgs/{orgId}/invitations/{id} | MEDIUM |
| 5 | invitation_resend | resend_handler.lambda_handler | POST | /v1/orgs/{orgId}/invitations/{id}/resend | MEDIUM |
| 6 | invitation_accept | accept_handler.lambda_handler | POST | /v1/invitations/accept | HIGH |
| 7 | invitation_cleanup | cleanup_handler.lambda_handler | (scheduled) | - | LOW |

## API Contract Summary

### POST /v1/orgs/{orgId}/invitations
**Purpose**: Create new invitation
**Path Parameters**:
- orgId (string, required)
**Request Body**:
```json
{
  "email": "user@example.com",
  "teamId": "team-123",
  "roleId": "role-456",
  "message": "Welcome to our team!"
}
```
**Response 201**:
```json
{
  "id": "inv-789",
  "status": "PENDING",
  "expiresAt": "2026-02-23T00:00:00Z"
}
```

(Continue for all endpoints...)

## DynamoDB Schema

**Table**: bbws-access-{env}-ddb-invitations

| Entity | PK | SK | Attributes |
|--------|----|----|------------|
| Invitation | ORG#{orgId} | INVITATION#{id} | email, teamId, roleId, status, token, expiresAt, ... |

**GSI-1**: InvitationByEmailIndex
- PK: email
- SK: createdAt

**GSI-2**: InvitationByTokenIndex
- PK: token

**TTL**: expiresAt (auto-expire after 7 days)

## Email Templates Required

| Template | Purpose | Variables |
|----------|---------|-----------|
| invitation_email.html | New invitation | org_name, inviter_name, accept_url, expiry_date |
| reminder_email.html | Resend invitation | org_name, inviter_name, accept_url, expiry_date |

## Invitation State Machine

```
                    ┌─────────────┐
                    │   PENDING   │
                    └──────┬──────┘
           ┌───────────────┼───────────────┐
           ↓               ↓               ↓
    ┌──────────┐    ┌──────────┐    ┌──────────┐
    │ ACCEPTED │    │ EXPIRED  │    │ CANCELLED│
    └──────────┘    └──────────┘    └──────────┘
```

## Integration Points

| Integration | Service | Direction | Purpose |
|-------------|---------|-----------|---------|
| SES | Email | Outbound | Send invitation emails |
| Team Service | Team | Outbound | Add user to team on accept |
| Role Service | Role | Inbound | Validate role exists |
| Audit Service | Audit | Outbound | Log invitation events |
| Cognito | Auth | Inbound | Get inviter details |

## Risk Assessment

| Risk | Impact | Mitigation |
|------|--------|------------|
| Email delivery failure | HIGH | SES bounce handling, retry logic |
| Token guessing | HIGH | Secure random token, rate limiting |
| Duplicate invitations | MEDIUM | Check existing pending |
```

---

## Success Criteria

- [ ] All 7 Lambda functions documented
- [ ] All API endpoints fully specified
- [ ] DynamoDB schema with TTL documented
- [ ] Email templates identified
- [ ] State machine documented
- [ ] Integration points identified
- [ ] Risks assessed with mitigations

---

## Execution Steps

1. Read LLD 2.8.2 completely
2. Extract Lambda function specifications
3. Document API contracts
4. Extract DynamoDB schema
5. Identify email templates needed
6. Document invitation state machine
7. Identify integration points
8. Assess implementation risks
9. Create output.md
10. Update work.state to COMPLETE

---

**Status**: PENDING
**Created**: 2026-01-23
