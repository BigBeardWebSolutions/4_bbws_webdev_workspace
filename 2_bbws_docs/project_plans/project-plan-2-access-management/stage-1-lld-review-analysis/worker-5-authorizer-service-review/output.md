# Worker 5 Output: Authorizer Service LLD Review

**Worker ID**: worker-5-authorizer-service-review
**Stage**: Stage 1 - LLD Review & Analysis
**Project**: project-plan-2-access-management
**Status**: COMPLETE
**Date**: 2026-01-23

---

## Executive Summary

The Authorizer Service (LLD 2.8.5) is the **critical security component** of the BBWS Access Management system. It implements a Lambda Authorizer for API Gateway that validates JWT tokens, resolves user permissions and team memberships, and generates IAM policies for request authorization. This is a **fail-closed** security design that denies access on any validation error.

---

## 1. Lambda Authorizer Function Specification

### 1.1 Function Overview

| Attribute | Value |
|-----------|-------|
| **Function Name** | `authorize` |
| **Repository** | `2_bbws_access_authorizer_lambda` |
| **Runtime** | Python 3.12 |
| **Architecture** | arm64 |
| **Memory** | 512MB |
| **Timeout** | 10 seconds |
| **Trigger** | API Gateway Token Authorizer |
| **Auth Type** | Token Authorizer (REQUEST type) |
| **Lambda Layer** | aws-lambda-powertools, PyJWT |

### 1.2 Environment Variables

| Variable | Description | Example |
|----------|-------------|---------|
| `COGNITO_USER_POOL_ID` | Cognito User Pool ID | `eu-west-1_abc123` |
| `COGNITO_REGION` | Cognito region | `eu-west-1` |
| `DYNAMODB_TABLE` | Access management table | `bbws-aipagebuilder-dev-ddb-access-management` |
| `LOG_LEVEL` | Logging level | `INFO` |
| `POLICY_CACHE_TTL` | API Gateway cache TTL (seconds) | `300` |

### 1.3 API Gateway Configuration

```yaml
Authorizer:
  Type: TOKEN
  AuthorizerUri: !Sub arn:aws:apigateway:${AWS::Region}:lambda:path/2015-03-31/functions/${AuthorizerLambda.Arn}/invocations
  IdentitySource: method.request.header.Authorization
  AuthorizerResultTtlInSeconds: 300  # 5 minute cache
```

---

## 2. Authorization Flow (Step by Step)

### 2.1 Complete Authorization Flow Diagram

```
┌─────────────────────────────────────────────────────────────────────────────┐
│                      AUTHORIZER SERVICE FLOW                                 │
├─────────────────────────────────────────────────────────────────────────────┤
│                                                                             │
│  Step 1: REQUEST ARRIVES                                                    │
│  ┌─────────────────────────────────────────────────────────────────────┐   │
│  │  GET /v1/organisations/{orgId}/teams/{teamId}/sites                 │   │
│  │  Authorization: Bearer eyJhbGciOiJSUzI1NiIs...                     │   │
│  └─────────────────────────────────────────────────────────────────────┘   │
│                              │                                              │
│                              ▼                                              │
│  Step 2: EXTRACT TOKEN                                                      │
│  ┌─────────────────────────────────────────────────────────────────────┐   │
│  │  - Extract Authorization header                                     │   │
│  │  - Remove "Bearer " prefix                                          │   │
│  │  - Handle missing token → TOKEN_MISSING error                       │   │
│  └─────────────────────────────────────────────────────────────────────┘   │
│                              │                                              │
│                              ▼                                              │
│  Step 3: VALIDATE JWT (Cognito JWKS)                                       │
│  ┌─────────────────────────────────────────────────────────────────────┐   │
│  │  a) Get JWKS from Cognito (cached 1 hour)                          │   │
│  │  b) Verify RS256 signature using Cognito public key                │   │
│  │  c) Validate issuer (iss) matches Cognito URL                      │   │
│  │  d) Validate token_use claim (access or id)                        │   │
│  │  e) Validate expiry (exp > now)                                    │   │
│  │  - Failures → TOKEN_INVALID, TOKEN_EXPIRED, TOKEN_SIGNATURE_INVALID│   │
│  └─────────────────────────────────────────────────────────────────────┘   │
│                              │                                              │
│                              ▼                                              │
│  Step 4: EXTRACT USER CLAIMS                                               │
│  ┌─────────────────────────────────────────────────────────────────────┐   │
│  │  - sub (User ID / Cognito subject)                                 │   │
│  │  - email (User email address)                                       │   │
│  │  - custom:organisation_id (User's org)                             │   │
│  │  - cognito:username                                                 │   │
│  └─────────────────────────────────────────────────────────────────────┘   │
│                              │                                              │
│                              ▼                                              │
│  Step 5: VALIDATE ORGANISATION ACCESS                                      │
│  ┌─────────────────────────────────────────────────────────────────────┐   │
│  │  - Extract orgId from URL path (/organisations/{orgId}/...)        │   │
│  │  - Compare with token's custom:organisation_id                     │   │
│  │  - If mismatch → ORG_ACCESS_DENIED error                           │   │
│  └─────────────────────────────────────────────────────────────────────┘   │
│                              │                                              │
│                              ▼                                              │
│  Step 6: RESOLVE USER PERMISSIONS                                          │
│  ┌─────────────────────────────────────────────────────────────────────┐   │
│  │  - Query DynamoDB for user's roles                                 │   │
│  │  - Query DynamoDB for role permissions                             │   │
│  │  - Expand all roles to permissions                                 │   │
│  │  - Deduplicate permission set                                      │   │
│  │  - Support wildcard permissions (e.g., site:*)                     │   │
│  └─────────────────────────────────────────────────────────────────────┘   │
│                              │                                              │
│                              ▼                                              │
│  Step 7: RESOLVE TEAM MEMBERSHIPS                                          │
│  ┌─────────────────────────────────────────────────────────────────────┐   │
│  │  - Query DynamoDB GSI1 for user's team memberships                 │   │
│  │  - Filter active memberships only                                  │   │
│  │  - Build teamIds array                                             │   │
│  └─────────────────────────────────────────────────────────────────────┘   │
│                              │                                              │
│                              ▼                                              │
│  Step 8: CHECK REQUIRED PERMISSION                                         │
│  ┌─────────────────────────────────────────────────────────────────────┐   │
│  │  - Map HTTP method + path to required permission                   │   │
│  │  - Check if required permission in user permissions                │   │
│  │  - Check wildcard permissions (e.g., site:* covers site:read)      │   │
│  │  - If missing → PERMISSION_DENIED error                            │   │
│  └─────────────────────────────────────────────────────────────────────┘   │
│                              │                                              │
│                              ▼                                              │
│  Step 9: BUILD IAM POLICY                                                  │
│  ┌─────────────────────────────────────────────────────────────────────┐   │
│  │  - principalId = user sub                                          │   │
│  │  - policyDocument = Allow/Deny execute-api:Invoke                  │   │
│  │  - context = userId, email, orgId, teamIds, permissions, roleIds   │   │
│  └─────────────────────────────────────────────────────────────────────┘   │
│                              │                                              │
│                              ▼                                              │
│  Step 10: AUDIT LOGGING                                                    │
│  ┌─────────────────────────────────────────────────────────────────────┐   │
│  │  - Log authorization decision (ALLOW or DENY)                      │   │
│  │  - Include userId, orgId, method, path, required permission        │   │
│  │  - Write to DynamoDB audit table                                   │   │
│  └─────────────────────────────────────────────────────────────────────┘   │
│                              │                                              │
│                              ▼                                              │
│  Step 11: RETURN POLICY TO API GATEWAY                                     │
│  ┌─────────────────────────────────────────────────────────────────────┐   │
│  │  - API Gateway caches policy (5 minute TTL)                        │   │
│  │  - Cache key: Authorization header (token)                         │   │
│  │  - Backend Lambda receives context via requestContext              │   │
│  └─────────────────────────────────────────────────────────────────────┘   │
│                                                                             │
└─────────────────────────────────────────────────────────────────────────────┘
```

### 2.2 Flow Steps Summary

| Step | Action | Success | Failure |
|------|--------|---------|---------|
| 1 | Request arrives at API Gateway | Continue | - |
| 2 | Extract JWT from Authorization header | Continue | TOKEN_MISSING → 401 |
| 3 | Validate JWT signature (JWKS) | Continue | TOKEN_INVALID/EXPIRED → 401 |
| 4 | Extract user claims (sub, email, orgId) | Continue | TOKEN_INVALID → 401 |
| 5 | Validate org access (path org vs token org) | Continue | ORG_ACCESS_DENIED → 403 |
| 6 | Resolve user permissions from roles | Continue | USER_NOT_FOUND → 403 |
| 7 | Resolve team memberships | Continue | Continue (empty teams OK) |
| 8 | Check required permission for endpoint | Continue | PERMISSION_DENIED → 403 |
| 9 | Build IAM policy with context | Continue | INTERNAL_ERROR → Deny |
| 10 | Log authorization decision | Continue | Continue (best effort) |
| 11 | Return policy to API Gateway | Complete | - |

---

## 3. JWT Validation

### 3.1 JWKS Caching Strategy

| Setting | Value | Description |
|---------|-------|-------------|
| **JWKS URL** | `https://cognito-idp.{region}.amazonaws.com/{userPoolId}/.well-known/jwks.json` | Cognito public keys endpoint |
| **Cache TTL** | 1 hour | Duration to cache JWKS in memory |
| **Cache Location** | Lambda memory (in-process) | Persists across warm invocations |
| **Refresh Strategy** | On expiry or key not found | Re-fetch if cached TTL exceeded |

```python
# JWKS Caching Implementation
class JwtValidator:
    def __init__(self, user_pool_id: str, region: str):
        self.issuer = f"https://cognito-idp.{region}.amazonaws.com/{user_pool_id}"
        self.jwks_url = f"{self.issuer}/.well-known/jwks.json"
        self._jwks_cache = None
        self._jwks_cache_time = None
        self._jwks_cache_ttl = timedelta(hours=1)  # 1 hour cache
```

### 3.2 Token Expiry Validation

| Claim | Validation |
|-------|------------|
| `exp` | Token expiration timestamp must be > current time |
| `iat` | Token issued-at timestamp (informational) |
| `nbf` | Not-before timestamp (if present, must be < current time) |

```python
# Expiry validation is automatic with PyJWT
claims = jwt.decode(
    token,
    public_key,
    algorithms=["RS256"],
    issuer=self.issuer,
    options={"verify_exp": True}  # Enabled by default
)
```

### 3.3 Issuer Validation

| Validation | Expected Value |
|------------|----------------|
| `iss` claim | `https://cognito-idp.{region}.amazonaws.com/{userPoolId}` |
| Algorithm | RS256 (RSA Signature with SHA-256) |

### 3.4 Audience Validation

| Setting | Value |
|---------|-------|
| Audience (`aud`) verification | Disabled for Cognito access tokens |
| Reason | Cognito does not always set `aud` in access tokens |
| Alternative | `token_use` claim validation instead |

### 3.5 Token Use Validation

| Token Type | `token_use` Claim | Valid |
|------------|-------------------|-------|
| Access Token | `access` | Yes |
| ID Token | `id` | Yes |
| Refresh Token | N/A | No (not supported) |

### 3.6 JWT Claims Extracted

```python
class TokenClaims(BaseModel):
    sub: str                    # User ID (Cognito subject)
    email: str                  # User email
    cognito_username: str       # Cognito username
    org_id: str                 # custom:organisation_id
    exp: int                    # Expiration timestamp
    iat: int                    # Issued at timestamp
    token_use: str              # "access" or "id"
    iss: str                    # Issuer (Cognito URL)
    aud: Optional[str] = None   # Audience (optional)
```

---

## 4. Permission Resolution Mechanism

### 4.1 Permission Resolution Flow

```
┌─────────────────────────────────────────────────────────────────────────────┐
│                      PERMISSION RESOLUTION FLOW                              │
├─────────────────────────────────────────────────────────────────────────────┤
│                                                                             │
│  Step 1: GET USER ROLES                                                     │
│  ┌─────────────────────────────────────────────────────────────────────┐   │
│  │  Query: PK = USER#{userId}#ORG#{orgId}, SK begins_with ROLE#       │   │
│  │  Result: List of roleIds assigned to user                          │   │
│  └─────────────────────────────────────────────────────────────────────┘   │
│                              │                                              │
│                              ▼                                              │
│  Step 2: EXPAND ROLE PERMISSIONS                                           │
│  ┌─────────────────────────────────────────────────────────────────────┐   │
│  │  For each roleId:                                                   │   │
│  │    Query: PK = ROLE#{roleId}, SK begins_with PERM#                 │   │
│  │    Result: List of permissions for that role                       │   │
│  └─────────────────────────────────────────────────────────────────────┘   │
│                              │                                              │
│                              ▼                                              │
│  Step 3: AGGREGATE PERMISSIONS                                             │
│  ┌─────────────────────────────────────────────────────────────────────┐   │
│  │  - Union all permissions from all roles                            │   │
│  │  - Deduplicate permission set                                      │   │
│  │  - Example: [site:read, site:update, team:read]                    │   │
│  └─────────────────────────────────────────────────────────────────────┘   │
│                              │                                              │
│                              ▼                                              │
│  Step 4: CHECK REQUIRED PERMISSION                                         │
│  ┌─────────────────────────────────────────────────────────────────────┐   │
│  │  - Get required permission from endpoint mapping                   │   │
│  │  - Check exact match: "site:read" in permissions                   │   │
│  │  - Check wildcard: "site:*" covers "site:read"                     │   │
│  └─────────────────────────────────────────────────────────────────────┘   │
│                                                                             │
└─────────────────────────────────────────────────────────────────────────────┘
```

### 4.2 Permission Resolution Logic

```
User → Roles → Permissions (Additive Union)

Example:
  User "john@example.com" has roles:
    - Team Lead → [site:read, site:update, team:member:add, team:member:remove]
    - Operator → [site:read, site:update, site:publish]

  Effective permissions (union):
    [site:read, site:update, site:publish, team:member:add, team:member:remove]
```

### 4.3 Wildcard Permission Support

| Wildcard Pattern | Covers |
|------------------|--------|
| `site:*` | `site:read`, `site:create`, `site:update`, `site:delete`, `site:publish` |
| `team:*` | `team:read`, `team:update`, `team:member:add`, `team:member:remove` |
| `*:read` | All read permissions (if supported) |

```python
def check_permission(required: str, user_permissions: List[str]) -> bool:
    # Exact match
    if required in user_permissions:
        return True

    # Wildcard match (resource:*)
    resource = required.split(":")[0]
    if f"{resource}:*" in user_permissions:
        return True

    return False
```

### 4.4 DynamoDB Access Patterns for Permissions

| Pattern | Query |
|---------|-------|
| Get user roles | `PK = USER#{userId}#ORG#{orgId}`, `SK begins_with ROLE#` |
| Get role permissions | `PK = ROLE#{roleId}`, `SK begins_with PERM#` |
| Alternative (GSI1) | `GSI1PK = ORG#{orgId}`, `GSI1SK begins_with ROLE#` |

---

## 5. Team Resolution Mechanism

### 5.1 Team Membership Resolution Flow

```
┌─────────────────────────────────────────────────────────────────────────────┐
│                      TEAM RESOLUTION FLOW                                    │
├─────────────────────────────────────────────────────────────────────────────┤
│                                                                             │
│  Step 1: QUERY USER TEAM MEMBERSHIPS                                        │
│  ┌─────────────────────────────────────────────────────────────────────┐   │
│  │  Query GSI1:                                                        │   │
│  │    GSI1PK = USER#{userId}                                          │   │
│  │    GSI1SK begins_with TEAM#                                         │   │
│  │  Filter: active = true                                              │   │
│  └─────────────────────────────────────────────────────────────────────┘   │
│                              │                                              │
│                              ▼                                              │
│  Step 2: FILTER ACTIVE MEMBERSHIPS                                         │
│  ┌─────────────────────────────────────────────────────────────────────┐   │
│  │  - Only include memberships where active = true                    │   │
│  │  - Filter by organisation if needed (path orgId)                   │   │
│  └─────────────────────────────────────────────────────────────────────┘   │
│                              │                                              │
│                              ▼                                              │
│  Step 3: BUILD TEAM IDS ARRAY                                              │
│  ┌─────────────────────────────────────────────────────────────────────┐   │
│  │  teamIds = [team-001, team-002, team-003]                          │   │
│  │  Convert to comma-separated string for context                     │   │
│  │  context.teamIds = "team-001,team-002,team-003"                    │   │
│  └─────────────────────────────────────────────────────────────────────┘   │
│                                                                             │
└─────────────────────────────────────────────────────────────────────────────┘
```

### 5.2 Team Membership Data Model

| Attribute | Type | Description |
|-----------|------|-------------|
| `teamId` | String | Team UUID |
| `userId` | String | User UUID |
| `role` | String | User's role in team (Team Lead, Member, etc.) |
| `organisationId` | String | Organisation UUID |
| `joinedAt` | String | ISO 8601 timestamp |
| `addedBy` | String | Who added the user |
| `active` | Boolean | Active membership status |

### 5.3 DynamoDB Access Patterns for Teams

| Pattern | Query | Index |
|---------|-------|-------|
| List team members | `PK = TEAM#{teamId}`, `SK begins_with USER#` | Table |
| List user's teams | `GSI1PK = USER#{userId}`, `GSI1SK begins_with TEAM#` | GSI1 |
| User in specific team | `PK = TEAM#{teamId}`, `SK = USER#{userId}` | Table |

### 5.4 Team Context for Backend

The resolved team IDs are passed to backend Lambdas via the `requestContext.authorizer` object:

```python
# Backend Lambda can access team context
def handler(event, context):
    authorizer_context = event["requestContext"]["authorizer"]
    team_ids = authorizer_context["teamIds"].split(",")

    # Filter data by user's teams for data isolation
    sites = query_sites_by_teams(team_ids)
```

---

## 6. IAM Policy Builder Structure

### 6.1 Allow Policy Structure

```json
{
  "principalId": "user-770e8400-e29b-41d4-a716-446655440003",
  "policyDocument": {
    "Version": "2012-10-17",
    "Statement": [
      {
        "Action": "execute-api:Invoke",
        "Effect": "Allow",
        "Resource": "arn:aws:execute-api:eu-west-1:123456789012:api-id/prod/*"
      }
    ]
  },
  "context": {
    "userId": "user-770e8400-e29b-41d4-a716-446655440003",
    "email": "john.doe@example.com",
    "orgId": "org-550e8400-e29b-41d4-a716-446655440000",
    "teamIds": "team-001,team-002,team-003",
    "permissions": "site:read,site:update,team:read",
    "roleIds": "role-team-lead,role-operator"
  }
}
```

### 6.2 Deny Policy Structure

```json
{
  "principalId": "anonymous",
  "policyDocument": {
    "Version": "2012-10-17",
    "Statement": [
      {
        "Action": "execute-api:Invoke",
        "Effect": "Deny",
        "Resource": "arn:aws:execute-api:eu-west-1:123456789012:api-id/prod/*"
      }
    ]
  }
}
```

### 6.3 Context Fields

| Field | Type | Description | Max Length |
|-------|------|-------------|------------|
| `userId` | String | User's Cognito sub | 36 chars (UUID) |
| `email` | String | User's email address | 254 chars |
| `orgId` | String | Organisation UUID | 36 chars (UUID) |
| `teamIds` | String | Comma-separated team UUIDs | Variable |
| `permissions` | String | Comma-separated permissions | Variable |
| `roleIds` | String | Comma-separated role UUIDs | Variable |

### 6.4 Policy Builder Implementation

```python
class PolicyBuilder:
    @staticmethod
    def build_allow_policy(
        principal_id: str,
        resource: str,
        context: AuthContext
    ) -> dict:
        return {
            "principalId": principal_id,
            "policyDocument": {
                "Version": "2012-10-17",
                "Statement": [{
                    "Action": "execute-api:Invoke",
                    "Effect": "Allow",
                    "Resource": PolicyBuilder._build_resource_arn(resource)
                }]
            },
            "context": {
                "userId": context.user_id,
                "email": context.email,
                "orgId": context.org_id,
                "teamIds": context.team_ids,
                "permissions": context.permissions,
                "roleIds": context.role_ids
            }
        }

    @staticmethod
    def build_deny_policy(principal_id: str, resource: str) -> dict:
        return {
            "principalId": principal_id,
            "policyDocument": {
                "Version": "2012-10-17",
                "Statement": [{
                    "Action": "execute-api:Invoke",
                    "Effect": "Deny",
                    "Resource": PolicyBuilder._build_resource_arn(resource)
                }]
            }
        }

    @staticmethod
    def _build_resource_arn(method_arn: str) -> str:
        """Build wildcard resource ARN for policy caching."""
        # methodArn: arn:aws:execute-api:region:account:api-id/stage/method/path
        parts = method_arn.split("/")
        # Return wildcard for all methods/paths on this API stage
        return "/".join(parts[:2]) + "/*"
```

---

## 7. Caching Strategy

### 7.1 Cache Layers

| Cache | Location | TTL | Purpose |
|-------|----------|-----|---------|
| **JWKS Cache** | Lambda memory (in-process) | 1 hour | Cognito public keys for JWT verification |
| **Policy Cache** | API Gateway | 5 minutes | Full IAM policy response |
| **Permission Cache** | Not implemented (Phase 1) | N/A | Future: User permissions cache |

### 7.2 JWKS Cache Details

| Setting | Value |
|---------|-------|
| **Location** | Lambda warm instance memory |
| **TTL** | 1 hour (3600 seconds) |
| **Cache Key** | Single cache (one JWKS per user pool) |
| **Refresh Trigger** | TTL expiry OR key not found in cache |
| **Persistence** | Lost on cold start, persists across warm invocations |

### 7.3 API Gateway Policy Cache Details

| Setting | Value |
|---------|-------|
| **Location** | API Gateway |
| **TTL** | 300 seconds (5 minutes) |
| **Cache Key** | Authorization header value (JWT token) |
| **Impact** | Reduces Lambda invocations for repeated requests |
| **Configuration** | `AuthorizerResultTtlInSeconds: 300` |

### 7.4 Cache Invalidation Strategy

| Scenario | Handling |
|----------|----------|
| **User permissions change** | Wait for policy cache expiry (5 min max) |
| **User removed from team** | Wait for policy cache expiry (5 min max) |
| **Role permissions updated** | Wait for policy cache expiry (5 min max) |
| **JWKS rotation (Cognito)** | Automatic refresh on key not found |
| **Emergency invalidation** | Redeploy API Gateway stage |

### 7.5 Cache-Related Risks

| Risk | Mitigation |
|------|------------|
| **Stale permissions** | Short TTL (5 min), audit logging for tracking |
| **Revoked user still accessing** | Short TTL (5 min), token expiry (1 hour) |
| **JWKS fetch failure** | Cache allows 1-hour grace period |

---

## 8. Endpoint Permission Mapping

### 8.1 Permission Map Definition

```python
ENDPOINT_PERMISSION_MAP = {
    # Sites
    ("GET", "/organisations/{orgId}/sites"): "site:read",
    ("GET", "/organisations/{orgId}/sites/{siteId}"): "site:read",
    ("POST", "/organisations/{orgId}/sites"): "site:create",
    ("PUT", "/organisations/{orgId}/sites/{siteId}"): "site:update",
    ("DELETE", "/organisations/{orgId}/sites/{siteId}"): "site:delete",
    ("POST", "/organisations/{orgId}/sites/{siteId}/publish"): "site:publish",

    # Teams
    ("GET", "/organisations/{orgId}/teams"): "team:read",
    ("GET", "/organisations/{orgId}/teams/{teamId}"): "team:read",
    ("POST", "/organisations/{orgId}/teams"): "team:create",
    ("PUT", "/organisations/{orgId}/teams/{teamId}"): "team:update",
    ("POST", "/organisations/{orgId}/teams/{teamId}/members"): "team:update",

    # Users
    ("GET", "/organisations/{orgId}/users"): "user:read",
    ("GET", "/organisations/{orgId}/users/{userId}"): "user:read",

    # Roles
    ("GET", "/organisations/{orgId}/roles"): "role:read",
    ("POST", "/organisations/{orgId}/roles"): "role:create",
    ("PUT", "/organisations/{orgId}/roles/{roleId}"): "role:update",

    # Invitations
    ("GET", "/organisations/{orgId}/invitations"): "invitation:read",
    ("POST", "/organisations/{orgId}/invitations"): "invitation:create",
    ("PUT", "/organisations/{orgId}/invitations/{invId}"): "invitation:revoke",

    # Platform (read-only for all authenticated)
    ("GET", "/platform/permissions"): None,  # No specific permission required
    ("GET", "/platform/roles"): None,
}
```

### 8.2 Complete Endpoint Permission Table

| HTTP Method | Endpoint Pattern | Required Permission | Notes |
|-------------|-----------------|---------------------|-------|
| **Sites** | | | |
| GET | `/organisations/{orgId}/sites` | `site:read` | List sites |
| GET | `/organisations/{orgId}/sites/{siteId}` | `site:read` | Get site details |
| POST | `/organisations/{orgId}/sites` | `site:create` | Create site |
| PUT | `/organisations/{orgId}/sites/{siteId}` | `site:update` | Update site |
| DELETE | `/organisations/{orgId}/sites/{siteId}` | `site:delete` | Delete site |
| POST | `/organisations/{orgId}/sites/{siteId}/publish` | `site:publish` | Publish site |
| **Teams** | | | |
| GET | `/organisations/{orgId}/teams` | `team:read` | List teams |
| GET | `/organisations/{orgId}/teams/{teamId}` | `team:read` | Get team details |
| POST | `/organisations/{orgId}/teams` | `team:create` | Create team |
| PUT | `/organisations/{orgId}/teams/{teamId}` | `team:update` | Update team |
| POST | `/organisations/{orgId}/teams/{teamId}/members` | `team:update` | Add team member |
| PUT | `/organisations/{orgId}/teams/{teamId}/members/{userId}` | `team:update` | Update/remove member |
| **Users** | | | |
| GET | `/organisations/{orgId}/users` | `user:read` | List users |
| GET | `/organisations/{orgId}/users/{userId}` | `user:read` | Get user details |
| **Roles** | | | |
| GET | `/organisations/{orgId}/roles` | `role:read` | List roles |
| POST | `/organisations/{orgId}/roles` | `role:create` | Create role |
| PUT | `/organisations/{orgId}/roles/{roleId}` | `role:update` | Update role |
| **Invitations** | | | |
| GET | `/organisations/{orgId}/invitations` | `invitation:read` | List invitations |
| POST | `/organisations/{orgId}/invitations` | `invitation:create` | Create invitation |
| PUT | `/organisations/{orgId}/invitations/{invId}` | `invitation:revoke` | Revoke invitation |
| POST | `/organisations/{orgId}/invitations/{invId}/resend` | `invitation:create` | Resend invitation |
| **Platform** | | | |
| GET | `/platform/permissions` | `None` | Public for authenticated |
| GET | `/platform/roles` | `None` | Public for authenticated |
| **Public (No Auth)** | | | |
| GET | `/invitations/{token}` | `None` | Public endpoint |
| POST | `/invitations/{token}/accept` | `None` | Public endpoint |
| POST | `/invitations/{token}/decline` | `None` | Public endpoint |

---

## 9. Error Handling

### 9.1 Error Codes and HTTP Responses

| Error Code | HTTP Status | Description | Policy Action |
|------------|-------------|-------------|---------------|
| `TOKEN_MISSING` | 401 Unauthorized | No Authorization header | Deny |
| `TOKEN_INVALID` | 401 Unauthorized | JWT format or structure invalid | Deny |
| `TOKEN_EXPIRED` | 401 Unauthorized | JWT exp claim exceeded | Deny |
| `TOKEN_SIGNATURE_INVALID` | 401 Unauthorized | JWT signature verification failed | Deny |
| `ORG_ACCESS_DENIED` | 403 Forbidden | User accessing different org | Deny |
| `PERMISSION_DENIED` | 403 Forbidden | User lacks required permission | Deny |
| `USER_NOT_FOUND` | 403 Forbidden | User not in DynamoDB | Deny |
| `USER_INACTIVE` | 403 Forbidden | User account deactivated | Deny |
| `INTERNAL_ERROR` | 500 Internal Error | Unexpected error (fail-closed) | Deny |

### 9.2 Exception Classes

```python
class AuthorizationException(Exception):
    """Base exception for authorization errors."""
    def __init__(self, message: str, reason: DenyReason):
        self.message = message
        self.reason = reason

class TokenMissingException(AuthorizationException):
    """No authorization token provided."""
    def __init__(self):
        super().__init__("No authorization token provided", DenyReason.TOKEN_MISSING)

class TokenExpiredException(AuthorizationException):
    """Token has expired."""
    def __init__(self):
        super().__init__("Token has expired", DenyReason.TOKEN_EXPIRED)

class TokenInvalidException(AuthorizationException):
    """Token is invalid."""
    def __init__(self, detail: str = ""):
        super().__init__(f"Token invalid: {detail}", DenyReason.TOKEN_INVALID)

class PermissionDeniedException(AuthorizationException):
    """User lacks required permission."""
    def __init__(self, required_permission: str):
        super().__init__(
            f"Permission denied: requires {required_permission}",
            DenyReason.PERMISSION_DENIED
        )
        self.required_permission = required_permission

class OrgAccessDeniedException(AuthorizationException):
    """User attempting to access different organisation."""
    def __init__(self, requested_org: str, user_org: str):
        super().__init__(
            f"Organisation access denied: requested {requested_org}, user belongs to {user_org}",
            DenyReason.ORG_ACCESS_DENIED
        )
        self.requested_org = requested_org
        self.user_org = user_org
```

### 9.3 Error Handling Flow

```python
try:
    # Authorization logic
    ...
    return PolicyBuilder.build_allow_policy(principal_id, method_arn, context)

except TokenExpiredException:
    self._audit_decision_deny(method_arn, DenyReason.TOKEN_EXPIRED)
    return PolicyBuilder.build_deny_policy(principal_id, method_arn)

except TokenInvalidException:
    self._audit_decision_deny(method_arn, DenyReason.TOKEN_INVALID)
    return PolicyBuilder.build_deny_policy(principal_id, method_arn)

except OrgAccessDeniedException:
    self._audit_decision_deny(method_arn, DenyReason.ORG_ACCESS_DENIED)
    return PolicyBuilder.build_deny_policy(principal_id, method_arn)

except PermissionDeniedException:
    self._audit_decision_deny(method_arn, DenyReason.PERMISSION_DENIED)
    return PolicyBuilder.build_deny_policy(principal_id, method_arn)

except Exception as e:
    logger.exception("Unexpected error in authorizer")
    self._audit_decision_deny(method_arn, DenyReason.INTERNAL_ERROR)
    # FAIL-CLOSED: Deny on any unexpected error
    return PolicyBuilder.build_deny_policy(principal_id, method_arn)
```

### 9.4 Fail-Closed Security

**Critical**: The authorizer implements **fail-closed** security:
- Any unexpected error results in DENY
- No access is granted when errors occur
- All exceptions are caught and result in Deny policy
- Audit logging for all deny decisions

---

## 10. Integration Points

### 10.1 External Service Integrations

| Service | Integration Point | Purpose |
|---------|-------------------|---------|
| **AWS Cognito** | JWKS endpoint | JWT signature verification |
| **AWS DynamoDB** | Access management table | Permission & team data |
| **AWS API Gateway** | Authorizer integration | Request authorization |
| **AWS CloudWatch** | Logs & metrics | Monitoring and alerting |

### 10.2 Internal Service Integrations

| Service | Integration | Purpose |
|---------|-------------|---------|
| **Permission Service** | Read permissions | Resolve user permissions from roles |
| **Role Service** | Read roles | Get role-permission mappings |
| **Team Service** | Read memberships | Resolve user's team memberships |
| **Audit Service** | Write audit events | Log authorization decisions |

### 10.3 DynamoDB Table Integration

**Table Name**: `bbws-aipagebuilder-{env}-ddb-access-management`

| Access Pattern | PK | SK | Index |
|----------------|----|----|-------|
| Get user roles | `USER#{userId}#ORG#{orgId}` | begins_with `ROLE#` | Table |
| Get role permissions | `ROLE#{roleId}` | begins_with `PERM#` | Table |
| Get user teams | `USER#{userId}` | begins_with `TEAM#` | GSI1 |
| Write audit event | `AUDIT#{date}` | `{timestamp}#{eventId}` | Table |

### 10.4 Backend Lambda Context Integration

Backend Lambdas access authorization context via `requestContext`:

```python
# Backend Lambda handler
def handler(event, context):
    # Access authorizer context
    auth_context = event["requestContext"]["authorizer"]

    user_id = auth_context["userId"]
    org_id = auth_context["orgId"]
    team_ids = auth_context["teamIds"].split(",")
    permissions = auth_context["permissions"].split(",")

    # Use team_ids for data isolation
    sites = query_sites_by_teams(team_ids)

    # Check specific permissions for actions
    if "site:delete" not in permissions:
        return {"statusCode": 403, "body": "Insufficient permissions"}
```

### 10.5 Cognito Integration

| Configuration | Value |
|---------------|-------|
| **User Pool ID** | Environment variable: `COGNITO_USER_POOL_ID` |
| **Region** | Environment variable: `COGNITO_REGION` |
| **JWKS URL** | `https://cognito-idp.{region}.amazonaws.com/{poolId}/.well-known/jwks.json` |
| **Issuer URL** | `https://cognito-idp.{region}.amazonaws.com/{poolId}` |
| **Custom Claims** | `custom:organisation_id` |

---

## 11. Risk Assessment

### 11.1 Security Risks

| Risk | Impact | Likelihood | Mitigation |
|------|--------|------------|------------|
| **Token Replay Attack** | High | Low | Short token expiry (1 hour), short cache TTL (5 min), HTTPS only |
| **JWKS Compromise** | Critical | Very Low | AWS-managed Cognito keys, automatic rotation |
| **JWT Manipulation** | High | Low | RS256 signature verification, fail-closed validation |
| **Privilege Escalation** | High | Low | Permission checks per request, audit logging |
| **Org Boundary Violation** | High | Low | Org ID comparison at authorizer level |

### 11.2 Performance Risks

| Risk | Impact | Likelihood | Mitigation |
|------|--------|------------|------------|
| **Cold Start Latency** | Medium | Medium | arm64 architecture, 512MB memory, provisioned concurrency (PROD) |
| **DynamoDB Throttling** | High | Low | On-demand capacity, DAX for hot paths (future) |
| **JWKS Fetch Failure** | Medium | Low | 1-hour cache TTL provides grace period |
| **Policy Cache Miss** | Low | Medium | 5-minute TTL is acceptable trade-off |
| **Authorizer Timeout** | High | Low | 10-second timeout, optimized queries |

### 11.3 Operational Risks

| Risk | Impact | Likelihood | Mitigation |
|------|--------|------------|------------|
| **Permission Cache Staleness** | Medium | Medium | Short TTL (5 min), audit logging for tracking |
| **User Access After Revocation** | Medium | Medium | Cache TTL (5 min max), token expiry (1 hour max) |
| **Audit Log Loss** | Low | Low | Best-effort logging, CloudWatch backup |
| **Configuration Drift** | Medium | Low | Terraform IaC, environment variables |

### 11.4 Non-Functional Requirements (NFRs)

| Metric | Target | Monitoring |
|--------|--------|------------|
| Authorization latency (p95) | < 100ms | CloudWatch metrics |
| Authorization latency (p99) | < 200ms | CloudWatch metrics |
| Cold start | < 1s | CloudWatch Insights |
| Error rate | < 0.01% | CloudWatch alarms |
| Cache hit rate | > 90% | API Gateway metrics |
| Availability | 99.99% | CloudWatch alarms |

### 11.5 TBC Items (To Be Confirmed)

| Item | Status | Impact |
|------|--------|--------|
| Rate limiting per user | Open | DoS protection |
| IP-based restrictions | Open | Additional security layer |
| MFA enforcement for sensitive operations | Open | High-security operations |

---

## 12. Project Structure

### 12.1 Repository Structure

```
2_bbws_access_authorizer_lambda/
├── src/
│   ├── handlers/
│   │   ├── __init__.py
│   │   └── authorizer.py              # Lambda handler entry point
│   ├── services/
│   │   ├── __init__.py
│   │   ├── authorizer_service.py      # Main authorization logic
│   │   ├── jwt_validator.py           # JWT validation with JWKS
│   │   ├── permission_resolver.py     # Permission resolution from roles
│   │   └── team_resolver.py           # Team membership resolution
│   ├── models/
│   │   ├── __init__.py
│   │   ├── claims.py                  # TokenClaims model
│   │   ├── context.py                 # AuthContext model
│   │   └── result.py                  # AuthorizationResult model
│   ├── config/
│   │   ├── __init__.py
│   │   └── endpoint_permissions.py    # Endpoint-to-permission mapping
│   ├── exceptions/
│   │   ├── __init__.py
│   │   └── auth_exceptions.py         # Custom exceptions
│   └── utils/
│       ├── __init__.py
│       └── policy_builder.py          # IAM policy construction
├── tests/
│   ├── unit/
│   │   ├── test_jwt_validator.py
│   │   ├── test_permission_resolver.py
│   │   └── test_policy_builder.py
│   └── integration/
│       └── test_authorizer.py
├── terraform/
│   ├── main.tf
│   ├── lambda.tf
│   ├── iam.tf
│   ├── api_gateway_authorizer.tf
│   ├── variables.tf
│   └── outputs.tf
├── requirements.txt
├── pytest.ini
└── README.md
```

### 12.2 Class Diagram Summary

| Class | Responsibility |
|-------|----------------|
| `AuthorizerHandler` | Lambda entry point, orchestrates authorization |
| `AuthorizerService` | Core authorization logic coordination |
| `JwtValidator` | JWT signature and claims validation |
| `UserPermissionResolver` | Resolve permissions from user roles |
| `TeamMembershipResolver` | Resolve user's team memberships |
| `PolicyBuilder` | Build IAM Allow/Deny policies |
| `EndpointPermissionMap` | Static mapping of endpoints to permissions |
| `TokenClaims` | Pydantic model for JWT claims |
| `AuthContext` | Pydantic model for authorization context |
| `AuthorizationResult` | Pydantic model for authorization decision |

---

## 13. Success Criteria Checklist

| Criteria | Status |
|----------|--------|
| Authorizer function specified | COMPLETE |
| Authorization flow documented | COMPLETE |
| JWT validation rules documented | COMPLETE |
| Permission resolution explained | COMPLETE |
| Team resolution explained | COMPLETE |
| Policy structure defined | COMPLETE |
| Caching strategy documented | COMPLETE |
| Endpoint permissions mapped | COMPLETE |
| Error handling defined | COMPLETE |
| Integration points documented | COMPLETE |
| Risks assessed | COMPLETE |

---

## 14. Implementation Priority

### Phase 1: Core Authorization (Week 1-2)

1. **JWT Validator** - JWKS caching, signature verification, claims extraction
2. **Policy Builder** - Allow/Deny policy construction
3. **Authorizer Handler** - Lambda entry point, error handling

### Phase 2: Permission Resolution (Week 2-3)

4. **Permission Resolver** - Role-to-permission expansion
5. **Endpoint Permission Map** - HTTP method/path to permission mapping

### Phase 3: Team Resolution (Week 3)

6. **Team Resolver** - Team membership resolution from DynamoDB

### Phase 4: Integration & Testing (Week 4)

7. **API Gateway Integration** - Authorizer configuration
8. **Audit Logging** - Authorization decision logging
9. **Unit Tests** - 80%+ coverage
10. **Integration Tests** - End-to-end authorization flows

---

## References

- **LLD Document**: `/Users/tebogotseka/Documents/agentic_work/2_bbws_docs/LLDs/2.8.5_LLD_Authorizer_Service.md`
- **HLD Document**: `/Users/tebogotseka/Documents/agentic_work/2_bbws_docs/HLDs/2.8_HLD_Access_Management.md`
- **AWS Lambda Authorizers**: https://docs.aws.amazon.com/apigateway/latest/developerguide/apigateway-use-lambda-authorizer.html
- **Cognito JWKS**: https://docs.aws.amazon.com/cognito/latest/developerguide/amazon-cognito-user-pools-using-tokens-verifying-a-jwt.html

---

**End of Output Document**
