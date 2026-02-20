# Worker Instructions: Authorizer Service LLD Review

**Worker ID**: worker-5-authorizer-service-review
**Stage**: Stage 1 - LLD Review & Analysis
**Project**: project-plan-2-access-management

---

## Task

Review the Authorizer Service LLD (2.8.5) and extract implementation-ready specifications. This is a critical security component - the Lambda Authorizer that validates JWTs and resolves permissions/teams for every API request.

---

## Inputs

**Primary Input**:
- `/Users/tebogotseka/Documents/agentic_work/2_bbws_docs/LLDs/2.8.5_LLD_Authorizer_Service.md`

**Supporting Inputs**:
- `/Users/tebogotseka/Documents/agentic_work/2_bbws_docs/HLDs/2.8_HLD_Access_Management.md`

---

## Deliverables

Create `output.md` with the following sections:

### 1. Lambda Function Specification

| Function | Type | Trigger |
|----------|------|---------|
| authorizer | Lambda Authorizer | API Gateway REQUEST |

### 2. Authorization Flow

Document the complete flow:
1. Extract JWT from Authorization header
2. Validate JWT signature (Cognito JWKS)
3. Extract user claims (userId, orgId)
4. Resolve user permissions from roles
5. Resolve team memberships
6. Build IAM policy
7. Return policy with context

### 3. JWT Validation

- JWKS caching strategy
- Token expiry validation
- Issuer validation
- Audience validation

### 4. Permission Resolution

Document how permissions are resolved:
```
User → Roles → Permissions
        ↓
      Union of all permissions
```

### 5. Team Resolution

Document team membership resolution:
- Get all teams user belongs to
- Include team-level permissions
- Build teamIds array for context

### 6. Policy Builder

Document the IAM policy structure:
```json
{
  "principalId": "user-123",
  "policyDocument": {
    "Version": "2012-10-17",
    "Statement": [...]
  },
  "context": {
    "userId": "...",
    "orgId": "...",
    "teamIds": "[...]",
    "permissions": "[...]"
  }
}
```

### 7. Caching Strategy

| Cache | TTL | Purpose |
|-------|-----|---------|
| JWKS | 1 hour | Public keys |
| Permission | 5 min | User permissions |
| Policy | API GW TTL | Full policy |

### 8. Endpoint Permission Mapping

Document required permissions per endpoint:
| Endpoint Pattern | Required Permission |
|-----------------|---------------------|
| GET /teams | READ:TEAM |
| POST /teams | WRITE:TEAM |
| ... | ... |

### 9. Error Handling

- Invalid token → 401 Unauthorized
- Expired token → 401 Unauthorized
- Insufficient permissions → 403 Forbidden

### 10. Integration Points

- Cognito (JWKS endpoint)
- Permission Service (permission data)
- Role Service (role data)
- Team Service (membership data)

### 11. Risk Assessment

- Token replay attacks
- Permission cache staleness
- Performance bottleneck

---

## Success Criteria

- [ ] Authorizer function specified
- [ ] Authorization flow documented
- [ ] JWT validation rules documented
- [ ] Permission resolution explained
- [ ] Team resolution explained
- [ ] Policy structure defined
- [ ] Caching strategy documented
- [ ] Endpoint permissions mapped
- [ ] Error handling defined
- [ ] Risks assessed

---

## Execution Steps

1. Read LLD 2.8.5 completely
2. Document authorizer function spec
3. Draw authorization flow diagram
4. Document JWT validation
5. Explain permission resolution
6. Explain team resolution
7. Define policy structure
8. Document caching strategy
9. Map endpoint permissions
10. Define error handling
11. Identify integration points
12. Assess risks
13. Create output.md
14. Update work.state to COMPLETE

---

**Status**: PENDING
**Created**: 2026-01-23
