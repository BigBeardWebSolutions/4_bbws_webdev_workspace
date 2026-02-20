# Invitation Service LLD Review Output

**Worker ID**: worker-2-invitation-service-review
**Stage**: Stage 1 - LLD Review & Analysis
**Project**: project-plan-2-access-management
**LLD Reference**: 2.8.2_LLD_Invitation_Service.md
**Review Date**: 2026-01-23
**Status**: COMPLETE

---

## 1. Lambda Function Checklist

| # | Function Name | Handler | Method | Endpoint | Auth | Priority |
|---|--------------|---------|--------|----------|------|----------|
| 1 | create_invitation | admin/create_invitation.lambda_handler | POST | /v1/organisations/{orgId}/invitations | Org Admin (invitation:create) | HIGH |
| 2 | list_invitations | admin/list_invitations.lambda_handler | GET | /v1/organisations/{orgId}/invitations | Org Admin | HIGH |
| 3 | get_invitation_admin | admin/get_invitation.lambda_handler | GET | /v1/organisations/{orgId}/invitations/{invId} | Org Admin | MEDIUM |
| 4 | resend_invitation | admin/resend_invitation.lambda_handler | POST | /v1/organisations/{orgId}/invitations/{invId}/resend | Org Admin (invitation:resend) | MEDIUM |
| 5 | revoke_invitation | admin/revoke_invitation.lambda_handler | PUT | /v1/organisations/{orgId}/invitations/{invId} | Org Admin (invitation:revoke) | MEDIUM |
| 6 | get_invitation_public | public/get_invitation_by_token.lambda_handler | GET | /v1/invitations/{token} | Public (No Auth) | HIGH |
| 7 | accept_invitation | public/accept_invitation.lambda_handler | POST | /v1/invitations/{token}/accept | Public/User | HIGH |
| 8 | decline_invitation | public/decline_invitation.lambda_handler | POST | /v1/invitations/{token}/decline | Public | MEDIUM |

### Lambda Configuration

| Property | Value |
|----------|-------|
| Repository | `2_bbws_access_invitation_lambda` |
| Runtime | Python 3.12 |
| Memory | 256MB |
| Timeout | 30s |
| Architecture | arm64 |
| Layer | aws-lambda-powertools |

---

## 2. API Contract Summary

### 2.1 POST /v1/organisations/{orgId}/invitations

**Purpose**: Create and send invitation
**Authentication**: Org Admin with `invitation:create` permission

**Path Parameters**:
| Parameter | Type | Required | Description |
|-----------|------|----------|-------------|
| orgId | string | Yes | Organisation UUID |

**Request Body**:
```json
{
  "email": "newuser@example.com",
  "roleId": "role-team-lead",
  "teamId": "team-engineering",
  "message": "Welcome to our team!"
}
```

| Field | Type | Required | Constraints |
|-------|------|----------|-------------|
| email | string (email) | Yes | Valid email format |
| roleId | string | Yes | Must exist in organisation |
| teamId | string | No | Must exist in organisation if provided |
| message | string | No | Max 500 characters |

**Response 201 Created**:
```json
{
  "id": "inv-660e8400-e29b-41d4-a716-446655440002",
  "email": "newuser@example.com",
  "organisationId": "org-550e8400-e29b-41d4-a716-446655440000",
  "organisationName": "Acme Corporation",
  "roleId": "role-team-lead",
  "roleName": "Team Lead",
  "teamId": "team-engineering",
  "teamName": "Engineering Team",
  "message": "Welcome to our team!",
  "status": "PENDING",
  "expiresAt": "2026-01-30T10:30:00Z",
  "resendCount": 0,
  "active": true,
  "dateCreated": "2026-01-23T10:30:00Z",
  "createdBy": "admin@example.com",
  "_links": {
    "self": { "href": "/v1/organisations/{orgId}/invitations/{invId}" },
    "organisation": { "href": "/v1/organisations/{orgId}" },
    "team": { "href": "/v1/organisations/{orgId}/teams/{teamId}" },
    "role": { "href": "/v1/organisations/{orgId}/roles/{roleId}" },
    "resend": { "href": "/v1/organisations/{orgId}/invitations/{invId}/resend", "method": "POST" },
    "revoke": { "href": "/v1/organisations/{orgId}/invitations/{invId}", "method": "PUT", "body": { "active": false } }
  }
}
```

**Error Responses**:
| Status | Error Code | Description |
|--------|------------|-------------|
| 400 | INVALID_ROLE | Role does not exist in organisation |
| 400 | INVALID_TEAM | Team does not exist in organisation |
| 403 | FORBIDDEN | Insufficient permissions |
| 409 | USER_ALREADY_MEMBER | User is already a member of the organisation |
| 409 | DUPLICATE_INVITATION | Pending invitation already exists for this email |

---

### 2.2 GET /v1/organisations/{orgId}/invitations

**Purpose**: List organisation invitations with filtering
**Authentication**: Org Admin

**Path Parameters**:
| Parameter | Type | Required | Description |
|-----------|------|----------|-------------|
| orgId | string | Yes | Organisation UUID |

**Query Parameters**:
| Parameter | Type | Required | Default | Description |
|-----------|------|----------|---------|-------------|
| status | string | No | - | Filter by status (PENDING, ACCEPTED, DECLINED, EXPIRED, REVOKED) |
| email | string | No | - | Filter by email |
| teamId | string | No | - | Filter by team |
| pageSize | integer | No | 50 | Max 100 |
| startAt | string | No | - | Pagination cursor |

**Response 200 OK**:
```json
{
  "items": [
    {
      "id": "inv-660e8400...",
      "email": "user@example.com",
      "status": "PENDING",
      "expiresAt": "2026-01-30T10:30:00Z",
      "_links": { ... }
    }
  ],
  "startAt": "next-cursor",
  "moreAvailable": true,
  "count": 50,
  "_links": {
    "self": { "href": "/v1/organisations/{orgId}/invitations?pageSize=50" },
    "next": { "href": "/v1/organisations/{orgId}/invitations?pageSize=50&startAt=..." }
  }
}
```

---

### 2.3 GET /v1/organisations/{orgId}/invitations/{invId}

**Purpose**: Get invitation details (admin view)
**Authentication**: Org Admin

**Path Parameters**:
| Parameter | Type | Required | Description |
|-----------|------|----------|-------------|
| orgId | string | Yes | Organisation UUID |
| invId | string | Yes | Invitation UUID |

**Response 200 OK**: Full InvitationResponse (see 2.1)

**Error Responses**:
| Status | Error Code | Description |
|--------|------------|-------------|
| 404 | NOT_FOUND | Invitation not found |

---

### 2.4 POST /v1/organisations/{orgId}/invitations/{invId}/resend

**Purpose**: Resend invitation email with new token and extended expiry
**Authentication**: Org Admin with `invitation:resend` permission

**Path Parameters**:
| Parameter | Type | Required | Description |
|-----------|------|----------|-------------|
| orgId | string | Yes | Organisation UUID |
| invId | string | Yes | Invitation UUID |

**Response 200 OK**:
```json
{
  "message": "Invitation resent successfully",
  "newExpiresAt": "2026-01-30T10:30:00Z"
}
```

**Error Responses**:
| Status | Error Code | Description |
|--------|------------|-------------|
| 400 | INVALID_STATE | Can only resend pending invitations |
| 400 | RESEND_LIMIT_EXCEEDED | Maximum 3 resends reached |
| 404 | NOT_FOUND | Invitation not found |

---

### 2.5 PUT /v1/organisations/{orgId}/invitations/{invId}

**Purpose**: Revoke invitation (soft delete)
**Authentication**: Org Admin with `invitation:revoke` permission

**Path Parameters**:
| Parameter | Type | Required | Description |
|-----------|------|----------|-------------|
| orgId | string | Yes | Organisation UUID |
| invId | string | Yes | Invitation UUID |

**Request Body**:
```json
{
  "active": false
}
```

**Response 200 OK**: Full InvitationResponse with status=REVOKED

**Error Responses**:
| Status | Error Code | Description |
|--------|------------|-------------|
| 400 | INVALID_STATE | Can only revoke pending invitations |
| 404 | NOT_FOUND | Invitation not found |

---

### 2.6 GET /v1/invitations/{token}

**Purpose**: Get invitation by token (public view - limited info)
**Authentication**: None (Public)

**Path Parameters**:
| Parameter | Type | Required | Description |
|-----------|------|----------|-------------|
| token | string | Yes | 64-char secure token |

**Response 200 OK**:
```json
{
  "organisationName": "Acme Corporation",
  "roleName": "Team Lead",
  "teamName": "Engineering Team",
  "inviterName": "John Admin",
  "message": "Welcome to our team!",
  "expiresAt": "2026-01-30T10:30:00Z",
  "isExpired": false,
  "requiresPassword": true,
  "_links": {
    "accept": { "href": "/v1/invitations/{token}/accept", "method": "POST" },
    "decline": { "href": "/v1/invitations/{token}/decline", "method": "POST" }
  }
}
```

**Error Responses**:
| Status | Error Code | Description |
|--------|------------|-------------|
| 404 | NOT_FOUND | Invitation not found |
| 410 | EXPIRED | Invitation has expired |
| 400 | ALREADY_USED | Invitation already accepted/declined/revoked |

---

### 2.7 POST /v1/invitations/{token}/accept

**Purpose**: Accept invitation and join organisation
**Authentication**: Public/User (optional for existing users)

**Path Parameters**:
| Parameter | Type | Required | Description |
|-----------|------|----------|-------------|
| token | string | Yes | 64-char secure token |

**Request Body** (required for new users):
```json
{
  "firstName": "John",
  "lastName": "Doe",
  "password": "SecureP@ssword123!"
}
```

| Field | Type | Required | Constraints |
|-------|------|----------|-------------|
| firstName | string | For new users | 1-50 characters |
| lastName | string | For new users | 1-50 characters |
| password | string | For new users | 8-128 chars, uppercase, lowercase, digit, special char |

**Response 200 OK**:
```json
{
  "userId": "user-770e8400-e29b-41d4-a716-446655440003",
  "organisationId": "org-550e8400-e29b-41d4-a716-446655440000",
  "organisationName": "Acme Corporation",
  "roleId": "role-team-lead",
  "roleName": "Team Lead",
  "teamId": "team-engineering",
  "teamName": "Engineering Team",
  "permissions": ["site:create", "site:read", "site:update", "team:member:add"],
  "isNewUser": true,
  "_links": {
    "organisation": { "href": "/v1/organisations/{orgId}" },
    "team": { "href": "/v1/organisations/{orgId}/teams/{teamId}" },
    "dashboard": { "href": "/dashboard" },
    "profile": { "href": "/v1/users/{userId}" }
  }
}
```

**Error Responses**:
| Status | Error Code | Description |
|--------|------------|-------------|
| 400 | ALREADY_USED | Invitation already accepted |
| 400 | PASSWORD_REQUIRED | Password required for new user |
| 400 | INVALID_PASSWORD | Password does not meet requirements |
| 404 | NOT_FOUND | Invitation not found |
| 410 | EXPIRED | Invitation has expired |

---

### 2.8 POST /v1/invitations/{token}/decline

**Purpose**: Decline invitation
**Authentication**: None (Public)

**Path Parameters**:
| Parameter | Type | Required | Description |
|-----------|------|----------|-------------|
| token | string | Yes | 64-char secure token |

**Request Body** (optional):
```json
{
  "reason": "Not interested at this time"
}
```

**Response 200 OK**:
```json
{
  "message": "Invitation declined"
}
```

**Error Responses**:
| Status | Error Code | Description |
|--------|------------|-------------|
| 400 | ALREADY_USED | Invitation already used |
| 404 | NOT_FOUND | Invitation not found |

---

## 3. DynamoDB Schema

### 3.1 Table Configuration

**Table Name**: `bbws-aipagebuilder-{env}-ddb-access-management`
**Capacity Mode**: On-demand (as per requirements)

### 3.2 Invitation Entity

| Attribute | Type | Key | Description |
|-----------|------|-----|-------------|
| PK | String | Partition Key | `ORG#{organisationId}` |
| SK | String | Sort Key | `INV#{invitationId}` |
| invitationId | String | - | UUID |
| token | String | - | 64-char secure token (SHA-256 hash) |
| email | String | - | Invitee email address |
| organisationId | String | - | Target organisation UUID |
| organisationName | String | - | Organisation display name |
| roleId | String | - | Role to assign on acceptance |
| roleName | String | - | Role display name |
| teamId | String | - | Optional team UUID |
| teamName | String | - | Team display name (if teamId set) |
| message | String | - | Optional personal message (max 500 chars) |
| status | String | - | PENDING, ACCEPTED, DECLINED, EXPIRED, REVOKED |
| expiresAt | String | - | ISO 8601 timestamp (7 days from creation) |
| resendCount | Number | - | Number of times resent (max 3) |
| lastResentAt | String | - | Last resend timestamp |
| acceptedAt | String | - | Acceptance timestamp |
| acceptedByUserId | String | - | User ID who accepted |
| declinedAt | String | - | Decline timestamp |
| declineReason | String | - | Optional decline reason |
| active | Boolean | - | Soft delete flag (default: true) |
| dateCreated | String | - | ISO 8601 timestamp |
| dateLastUpdated | String | - | ISO 8601 timestamp |
| createdBy | String | - | Admin email who created |
| lastUpdatedBy | String | - | Last updater email |
| GSI1PK | String | GSI1 PK | `ORG#{organisationId}#STATUS#{status}` |
| GSI1SK | String | GSI1 SK | `{expiresAt}#{invitationId}` |
| GSI2PK | String | GSI2 PK | `EMAIL#{email}` |
| GSI2SK | String | GSI2 SK | `ORG#{organisationId}#{dateCreated}` |

### 3.3 Invitation Token Lookup Entity

| Attribute | Type | Key | Description |
|-----------|------|-----|-------------|
| PK | String | Partition Key | `INVTOKEN#{token}` |
| SK | String | Sort Key | `METADATA` |
| invitationId | String | - | Reference to invitation |
| organisationId | String | - | Organisation ID |
| expiresAt | String | - | Token expiry |
| ttl | Number | - | DynamoDB TTL (epoch seconds) |

### 3.4 GSI Definitions

| GSI Name | PK | SK | Purpose |
|----------|----|----|---------|
| GSI1 | GSI1PK | GSI1SK | List invitations by org + status, sorted by expiry |
| GSI2 | GSI2PK | GSI2SK | Find invitations by email across orgs |

### 3.5 TTL Configuration

**Token Lookup TTL**:
- Field: `ttl` (epoch seconds)
- Auto-delete token lookup records after invitation expires
- Set to expiresAt + 24 hours buffer

### 3.6 Access Patterns

| Pattern | Query | Index |
|---------|-------|-------|
| Get invitation by ID | PK=ORG#{orgId}, SK=INV#{invId} | Table |
| Get invitation by token | PK=INVTOKEN#{token}, SK=METADATA | Table |
| List org invitations | PK=ORG#{orgId}, SK begins_with INV# | Table |
| List pending invitations by org | GSI1PK=ORG#{orgId}#STATUS#PENDING | GSI1 |
| List accepted invitations by org | GSI1PK=ORG#{orgId}#STATUS#ACCEPTED | GSI1 |
| Find by email | GSI2PK=EMAIL#{email} | GSI2 |
| Find by email + org | GSI2PK=EMAIL#{email}, GSI2SK begins_with ORG#{orgId} | GSI2 |
| Check duplicate pending | GSI2PK=EMAIL#{email} + filter status=PENDING + orgId | GSI2 |

---

## 4. Email Templates Required

| # | Template Name | Purpose | Send Trigger |
|---|--------------|---------|--------------|
| 1 | invitation_email.html | New invitation notification | invitation_create, resend_invitation |
| 2 | invitation_accepted.html | Admin notification on accept | accept_invitation |
| 3 | invitation_declined.html | Admin notification on decline | decline_invitation |

### 4.1 invitation_email.html

**Subject**: `You've been invited to join {organisationName} on BBWS`

**Variables**:
| Variable | Type | Description |
|----------|------|-------------|
| inviterName | string | Name of admin who sent invitation |
| organisationName | string | Organisation display name |
| roleName | string | Role being assigned |
| teamName | string | Team name (optional) |
| message | string | Personal message from inviter (optional) |
| acceptUrl | string | Full URL to accept invitation |
| declineUrl | string | Full URL to decline invitation |
| expiresAt | string | Human-readable expiry date |

### 4.2 invitation_accepted.html

**Subject**: `{userName} accepted your invitation to {organisationName}`

**Variables**:
| Variable | Type | Description |
|----------|------|-------------|
| userName | string | Name of user who accepted |
| userEmail | string | Email of user who accepted |
| organisationName | string | Organisation display name |
| roleName | string | Role assigned |
| teamName | string | Team name (optional) |
| acceptedAt | string | Human-readable acceptance timestamp |

### 4.3 invitation_declined.html

**Subject**: `{userEmail} declined your invitation to {organisationName}`

**Variables**:
| Variable | Type | Description |
|----------|------|-------------|
| userEmail | string | Email that declined |
| organisationName | string | Organisation display name |
| declineReason | string | Reason provided (optional) |
| declinedAt | string | Human-readable decline timestamp |

---

## 5. Invitation State Machine

### 5.1 States

| State | Description | Terminal |
|-------|-------------|----------|
| PENDING | Invitation sent, awaiting response | No |
| ACCEPTED | User accepted invitation | Yes |
| DECLINED | User declined invitation | Yes |
| EXPIRED | Invitation expired (7 days) | Yes |
| REVOKED | Admin revoked invitation | Yes |

### 5.2 State Transitions

```
                                    +-------------+
                                    |   PENDING   |
                                    +------+------+
                                           |
              +----------------------------+----------------------------+
              |                            |                            |
              v                            v                            v
       +-------------+              +-------------+              +-------------+
       |  ACCEPTED   |              |  DECLINED   |              |   REVOKED   |
       |  (terminal) |              |  (terminal) |              |  (terminal) |
       +-------------+              +-------------+              +-------------+

                                           |
                                           | (auto - TTL/check based)
                                           v
                                    +-------------+
                                    |   EXPIRED   |
                                    |  (terminal) |
                                    +-------------+
```

### 5.3 Valid Transitions

| From | To | Trigger | Actor |
|------|----|---------|-------|
| PENDING | ACCEPTED | User accepts via token | Invitee |
| PENDING | DECLINED | User declines via token | Invitee |
| PENDING | REVOKED | Admin revokes invitation | Org Admin |
| PENDING | EXPIRED | expiresAt < now (auto) | System |

### 5.4 Transition Rules

1. **All terminal states are final** - once invitation leaves PENDING, it cannot change
2. **Expiry check on all operations** - validate expiresAt before any token-based action
3. **Auto-expiry on access** - if invitation is accessed after expiry, update status to EXPIRED
4. **Resend resets expiry** - generates new token, extends expiresAt by 7 days

---

## 6. Integration Points

| # | Integration | Service | Direction | Purpose | Protocol |
|---|-------------|---------|-----------|---------|----------|
| 1 | SES | AWS SES | Outbound | Send invitation/notification emails | AWS SDK |
| 2 | RoleService | Permission Service | Outbound | Validate roleId exists, get role permissions | Lambda invoke / HTTP |
| 3 | TeamService | Team Service | Outbound | Validate teamId exists, add member on accept | Lambda invoke / HTTP |
| 4 | UserService | User Service | Outbound | Check if user exists, create user on accept | Lambda invoke / HTTP |
| 5 | Cognito | AWS Cognito | Outbound | Create user, update attributes | AWS SDK |
| 6 | AuditService | Audit Service | Outbound | Log invitation events | Lambda invoke / HTTP |
| 7 | DynamoDB | AWS DynamoDB | Bidirectional | Invitation persistence | AWS SDK |
| 8 | API Gateway | AWS API Gateway | Inbound | HTTP requests from clients | REST API |
| 9 | Lambda Authorizer | Auth Service | Inbound | JWT validation, permission checks | Lambda invoke |

### 6.1 Integration Flow - Create Invitation

```
Client -> API Gateway -> Lambda Authorizer (validate JWT, check invitation:create)
       -> create_invitation Lambda
          -> RoleService.validateRoleExists(orgId, roleId)
          -> TeamService.validateTeamExists(orgId, teamId) [if provided]
          -> UserService.checkNotAlreadyMember(orgId, email)
          -> InvitationRepository.findPendingByEmail(orgId, email)
          -> InvitationRepository.save(invitation)
          -> InvitationRepository.createTokenLookup(token, invId)
          -> EmailService.sendInvitationEmail(invitation)
          -> AuditService.logInvitationCreated(...)
       <- Response
```

### 6.2 Integration Flow - Accept Invitation

```
Client -> API Gateway -> accept_invitation Lambda (no auth required)
          -> InvitationRepository.findByToken(token)
          -> validateInvitation(invitation)
          -> UserService.findByEmail(email)
          [If new user]:
            -> UserService.createUser(email, firstName, lastName, password)
               -> Cognito.admin_create_user(...)
               -> DynamoDB.put_item(user record)
          -> UserService.addToOrganisation(userId, orgId, roleId)
          -> RoleService.getRolePermissions(roleId)
          -> UserService.updateCognitoAttributes(userId, {organisation_id: orgId})
          [If teamId provided]:
            -> TeamService.addMember(orgId, teamId, userId, roleName)
          -> InvitationRepository.update(invitation) // status=ACCEPTED
          -> EmailService.sendAcceptedNotification(invitation, adminEmail)
          -> AuditService.logInvitationAccepted(...)
       <- AcceptResult
```

---

## 7. Risk Assessment

| # | Risk | Impact | Likelihood | Mitigation |
|---|------|--------|------------|------------|
| 1 | Token guessing attack | HIGH | LOW | 64-char cryptographically secure tokens (SHA-256), rate limiting (5 attempts/min/IP) |
| 2 | Token replay attack | HIGH | LOW | Single-use tokens (status changes to terminal state on accept/decline) |
| 3 | Email spoofing | MEDIUM | LOW | SPF/DKIM/DMARC configured on SES domain |
| 4 | Expired token usage | LOW | MEDIUM | Check expiry on all operations, auto-update status to EXPIRED |
| 5 | Brute force resend | LOW | MEDIUM | Max 3 resends per invitation |
| 6 | Mass invitation spam | MEDIUM | LOW | Rate limiting: 10 invitations per minute per org |
| 7 | Cross-org invitation access | HIGH | LOW | Validate orgId from auth context matches path parameter |
| 8 | Email delivery failure | MEDIUM | MEDIUM | SES bounce/complaint handling, retry with exponential backoff, dead-letter queue |
| 9 | Cognito user creation failure | MEDIUM | LOW | Check Cognito user pool limits, handle quota errors gracefully |
| 10 | Duplicate invitations | MEDIUM | MEDIUM | Check for existing pending invitation before create (GSI2 query) |
| 11 | Password complexity bypass | MEDIUM | LOW | Server-side validation of password strength requirements |
| 12 | Stale invitation data | LOW | MEDIUM | Use optimistic locking (version attribute) for concurrent updates |

### 7.1 Security Controls Summary

| Control | Implementation |
|---------|----------------|
| Token Security | 64-char SHA-256 hash, single-use, 7-day expiry with TTL cleanup |
| Authentication | Admin endpoints: JWT from Cognito; Public endpoints: token-based |
| Authorization | invitation:create, invitation:resend, invitation:revoke permissions |
| Rate Limiting | Create: 10/min/org; Accept/decline: 5/min/IP; Resend: Max 3 total |
| Data Protection | Encryption at rest (DynamoDB); TLS 1.3 in transit; Passwords never stored (Cognito only) |

---

## 8. Non-Functional Requirements

| Metric | Target |
|--------|--------|
| Create invitation latency (p95) | < 1000ms |
| Get invitation (public) latency (p95) | < 200ms |
| Accept invitation latency (p95) | < 2000ms |
| List invitations latency (p95) | < 300ms |
| Email delivery time | < 30s |
| Lambda cold start | < 2s |
| Error rate | < 0.1% |

---

## 9. Project Structure

```
2_bbws_access_invitation_lambda/
+-- src/
|   +-- handlers/
|   |   +-- __init__.py
|   |   +-- admin/
|   |   |   +-- __init__.py
|   |   |   +-- create_invitation.py      # POST /orgs/{orgId}/invitations
|   |   |   +-- list_invitations.py       # GET /orgs/{orgId}/invitations
|   |   |   +-- get_invitation.py         # GET /orgs/{orgId}/invitations/{invId}
|   |   |   +-- resend_invitation.py      # POST /orgs/{orgId}/invitations/{invId}/resend
|   |   |   +-- revoke_invitation.py      # PUT /orgs/{orgId}/invitations/{invId}
|   |   +-- public/
|   |       +-- __init__.py
|   |       +-- get_invitation_by_token.py  # GET /invitations/{token}
|   |       +-- accept_invitation.py        # POST /invitations/{token}/accept
|   |       +-- decline_invitation.py       # POST /invitations/{token}/decline
|   +-- services/
|   |   +-- __init__.py
|   |   +-- invitation_service.py
|   |   +-- email_service.py
|   |   +-- user_service.py
|   +-- repositories/
|   |   +-- __init__.py
|   |   +-- invitation_repository.py
|   +-- models/
|   |   +-- __init__.py
|   |   +-- invitation.py
|   |   +-- requests.py
|   +-- exceptions/
|   |   +-- __init__.py
|   |   +-- invitation_exceptions.py
|   +-- utils/
|       +-- __init__.py
|       +-- response_builder.py
|       +-- validators.py
|       +-- token_generator.py
|       +-- hateoas.py
+-- templates/
|   +-- invitation_email.html
|   +-- invitation_accepted.html
|   +-- invitation_declined.html
+-- tests/
|   +-- unit/
|   |   +-- test_handlers/
|   |   +-- test_services/
|   |   +-- test_repositories/
|   +-- integration/
|       +-- test_api.py
+-- terraform/
|   +-- main.tf
|   +-- api_gateway.tf
|   +-- lambda.tf
|   +-- iam.tf
|   +-- ses.tf
|   +-- variables.tf
|   +-- outputs.tf
+-- openapi/
|   +-- invitation-service-api.yaml
+-- requirements.txt
+-- pytest.ini
+-- README.md
```

---

## 10. User Stories Reference

| ID | Epic | User Story | Test Scenario |
|----|------|------------|---------------|
| US-INV-001 | Create | Admin invites user with role | Valid email + roleId -> email sent with token |
| US-INV-002 | Create | Admin invites user to team | Valid teamId -> team assignment stored |
| US-INV-003 | Create | Cannot invite existing members | Existing member email -> 409 Conflict |
| US-INV-004 | Create | Cannot create duplicate pending | Pending exists -> 409 Conflict |
| US-INV-005 | List | List all org invitations | Authenticated admin -> paginated list |
| US-INV-006 | List | Filter by status | status=PENDING -> only pending |
| US-INV-007 | Resend | Resend invitation email | Pending invitation -> email resent |
| US-INV-008 | Revoke | Revoke pending invitation | Pending invitation -> status=REVOKED |
| US-INV-009 | View | View invitation details (public) | Valid token -> org and role shown |
| US-INV-010 | Accept | New user accepts | Valid token -> user created, role assigned |
| US-INV-011 | Accept | Existing user accepts | Valid token -> added to org with role |
| US-INV-012 | Decline | User declines | Valid token -> status=DECLINED |
| US-INV-013 | Expiry | Expired token error | Expired token -> 410 Gone |
| US-INV-014 | Security | Cannot accept used invitation | ACCEPTED invitation -> 400 |

---

## 11. Success Criteria

- [x] All 8 Lambda functions documented
- [x] All API endpoints fully specified (8 endpoints)
- [x] DynamoDB schema with TTL documented
- [x] Email templates identified (3 templates)
- [x] State machine documented (5 states, 4 transitions)
- [x] Integration points identified (9 integrations)
- [x] Risks assessed with mitigations (12 risks)
- [x] NFRs documented
- [x] Project structure documented
- [x] User stories referenced

---

**Review Completed**: 2026-01-23
**Reviewer**: worker-2-invitation-service-review
**Next Stage**: Stage 2 - Infrastructure Terraform
