# Stage 4 Summary: API Gateway Integration

**Stage**: Stage 4 - API Gateway Integration
**Project**: project-plan-2-access-management
**Status**: COMPLETE
**Completed**: 2026-01-23

---

## Executive Summary

Stage 4 successfully configured API Gateway REST API routes for all 6 Access Management services. The stage delivered complete OpenAPI 3.0 specifications, Terraform route configurations, request/response JSON schemas, CORS configurations, and Lambda Authorizer integration for 47 total API endpoints.

---

## Workers Completed

| Worker | Service | Endpoints | Status |
|--------|---------|-----------|--------|
| worker-1-permission-api-routes | Permission Service | 6 | COMPLETE |
| worker-2-invitation-api-routes | Invitation Service | 8 (3 public) | COMPLETE |
| worker-3-team-api-routes | Team Service | 14 | COMPLETE |
| worker-4-role-api-routes | Role Service | 8 | COMPLETE |
| worker-5-audit-api-routes | Audit Service | 5 | COMPLETE |
| worker-6-authorizer-integration | Lambda Authorizer | - | COMPLETE |

**Total Endpoints**: 41 authenticated + 3 public = 44 (plus 3 OPTIONS/CORS methods per resource)

---

## Endpoint Summary by Service

### Permission Service (6 endpoints)
| Method | Path | Description |
|--------|------|-------------|
| GET | `/v1/permissions` | List all permissions |
| GET | `/v1/permissions/{permissionId}` | Get permission by ID |
| POST | `/v1/permissions` | Create permission |
| PUT | `/v1/permissions/{permissionId}` | Update permission |
| DELETE | `/v1/permissions/{permissionId}` | Soft delete permission |
| POST | `/v1/permissions/seed` | Seed platform permissions |

### Invitation Service (8 endpoints, 3 public)
| Method | Path | Auth | Description |
|--------|------|------|-------------|
| POST | `/v1/orgs/{orgId}/invitations` | Yes | Send invitation |
| GET | `/v1/orgs/{orgId}/invitations` | Yes | List org invitations |
| GET | `/v1/orgs/{orgId}/invitations/{invId}` | Yes | Get invitation details |
| POST | `/v1/orgs/{orgId}/invitations/{invId}/resend` | Yes | Resend invitation |
| POST | `/v1/orgs/{orgId}/invitations/{invId}/cancel` | Yes | Cancel invitation |
| GET | `/v1/invitations/{token}` | **Public** | Get invitation by token |
| POST | `/v1/invitations/accept` | **Public** | Accept invitation |
| POST | `/v1/invitations/{token}/decline` | **Public** | Decline invitation |

### Team Service (14 endpoints)
| Method | Path | Description |
|--------|------|-------------|
| POST | `/v1/orgs/{orgId}/teams` | Create team |
| GET | `/v1/orgs/{orgId}/teams` | List teams |
| GET | `/v1/orgs/{orgId}/teams/{teamId}` | Get team |
| PUT | `/v1/orgs/{orgId}/teams/{teamId}` | Update team |
| POST | `/v1/orgs/{orgId}/team-roles` | Create team role |
| GET | `/v1/orgs/{orgId}/team-roles` | List team roles |
| GET | `/v1/orgs/{orgId}/team-roles/{roleId}` | Get team role |
| PUT | `/v1/orgs/{orgId}/team-roles/{roleId}` | Update team role |
| DELETE | `/v1/orgs/{orgId}/team-roles/{roleId}` | Delete team role |
| POST | `/v1/orgs/{orgId}/teams/{teamId}/members` | Add member |
| GET | `/v1/orgs/{orgId}/teams/{teamId}/members` | List members |
| GET | `/v1/orgs/{orgId}/teams/{teamId}/members/{userId}` | Get member |
| PUT | `/v1/orgs/{orgId}/teams/{teamId}/members/{userId}` | Update member |
| GET | `/v1/orgs/{orgId}/users/{userId}/teams` | Get user teams |

### Role Service (8 endpoints)
| Method | Path | Description |
|--------|------|-------------|
| GET | `/v1/platform/roles` | List platform roles |
| GET | `/v1/platform/roles/{roleId}` | Get platform role |
| POST | `/v1/orgs/{orgId}/roles` | Create org role |
| GET | `/v1/orgs/{orgId}/roles` | List org roles |
| GET | `/v1/orgs/{orgId}/roles/{roleId}` | Get org role |
| PUT | `/v1/orgs/{orgId}/roles/{roleId}` | Update org role |
| DELETE | `/v1/orgs/{orgId}/roles/{roleId}` | Delete org role |
| POST | `/v1/orgs/{orgId}/roles/seed` | Seed default roles |

### Audit Service (5 endpoints)
| Method | Path | Description |
|--------|------|-------------|
| GET | `/v1/orgs/{orgId}/audit` | Query org audit logs |
| GET | `/v1/orgs/{orgId}/audit/users/{userId}` | Query user audit |
| GET | `/v1/orgs/{orgId}/audit/resources/{type}/{resourceId}` | Query resource audit |
| GET | `/v1/orgs/{orgId}/audit/summary` | Get audit summary |
| POST | `/v1/orgs/{orgId}/audit/export` | Export audit logs |

---

## Authorizer Configuration

### Configuration Details
- **Type**: TOKEN (Bearer JWT)
- **Identity Source**: `method.request.header.Authorization`
- **Cache TTL**: 300 seconds (5 minutes)
- **Validation Regex**: `^Bearer [-0-9a-zA-Z._]+$`
- **Security Pattern**: FAIL-CLOSED (deny on error)

### Public Endpoints (No Auth)
```
GET  /v1/invitations/{token}
POST /v1/invitations/accept
POST /v1/invitations/{token}/decline
```

### Authorizer Context Values
The authorizer passes these values to backend Lambdas:
- `userId` - Cognito user ID
- `email` - User email
- `orgId` - Organisation ID
- `teamIds` - Comma-separated team IDs
- `permissions` - Comma-separated permission codes
- `roleIds` - Comma-separated role IDs

---

## CORS Configuration

| Header | Value |
|--------|-------|
| Access-Control-Allow-Origin | * |
| Access-Control-Allow-Methods | GET, POST, PUT, DELETE, OPTIONS |
| Access-Control-Allow-Headers | Content-Type, Authorization, X-Request-ID |
| Access-Control-Max-Age | 86400 (24 hours) |

---

## Gateway Responses

| Response Type | Status Code | Description |
|---------------|-------------|-------------|
| UNAUTHORIZED | 401 | Invalid/missing token |
| ACCESS_DENIED | 403 | Insufficient permissions |
| THROTTLED | 429 | Rate limit exceeded |
| DEFAULT_4XX | 4xx | Client errors |
| DEFAULT_5XX | 5xx | Server errors |

All gateway responses include CORS headers.

---

## Deliverables

### Per Worker
| Worker | OpenAPI Spec | Terraform Routes | JSON Schemas | CORS Config |
|--------|-------------|------------------|--------------|-------------|
| worker-1 | permission-service.yaml | permission_routes.tf | 4 schemas | permission_cors.tf |
| worker-2 | invitation-service.yaml | invitation_routes.tf | 5 schemas | invitation_cors.tf |
| worker-3 | team-service.yaml | team_routes.tf | 8 schemas | team_cors.tf |
| worker-4 | role-service.yaml | role_routes.tf | 5 schemas | role_cors.tf |
| worker-5 | audit-service.yaml | audit_routes.tf | 4 schemas | audit_cors.tf |
| worker-6 | N/A | authorizer.tf | N/A | gateway_responses.tf |

### Output Files
- `worker-1-permission-api-routes/output.md`
- `worker-2-invitation-api-routes/output.md`
- `worker-3-team-api-routes/output.md`
- `worker-4-role-api-routes/output.md`
- `worker-5-audit-api-routes/output.md`
- `worker-6-authorizer-integration/output.md`

---

## Architecture Notes

### Lambda Proxy Integration
All API methods use Lambda Proxy Integration (AWS_PROXY) which:
- Passes full request context to Lambda
- Returns Lambda response directly to client
- Supports both success and error responses

### Request Validation
- Path parameters validated via API Gateway
- Query parameters validated via Lambda
- Request body validated via JSON Schema at Lambda layer

### Naming Convention
```
Lambda: bbws-access-{env}-{service}-{operation}
Example: bbws-access-dev-permission-list
```

---

## Success Criteria

| Criterion | Status |
|-----------|--------|
| All 44 routes configured | COMPLETE |
| Lambda authorizer attached to protected routes | COMPLETE |
| Public routes bypass authorizer | COMPLETE |
| CORS enabled on all endpoints | COMPLETE |
| OpenAPI specs complete | COMPLETE |
| Request/response schemas defined | COMPLETE |
| Gateway responses configured | COMPLETE |
| Environment parameterisation | COMPLETE |

---

## Next Stage

**Stage 5: Testing & Validation** - 6 workers
- Unit tests for all Lambda functions
- Integration tests for API endpoints
- Authorization test scenarios
- CORS validation tests
- Performance/load testing setup
- Security scanning configuration

---

**Stage 4 Completed**: 2026-01-23
