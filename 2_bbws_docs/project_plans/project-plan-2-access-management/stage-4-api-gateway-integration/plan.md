# Stage 4: API Gateway Integration

**Stage ID**: stage-4-api-gateway-integration
**Project**: project-plan-2-access-management
**Status**: PENDING
**Workers**: 6 (parallel execution)

---

## Stage Objective

Configure API Gateway routes for all Access Management endpoints. Integrate Lambda Authorizer for authentication and authorization. Enable CORS and configure request/response mappings.

---

## Stage Workers

| Worker | Task | Endpoints | Status |
|--------|------|-----------|--------|
| worker-1-permission-api-routes | Configure Permission API routes | 6 | PENDING |
| worker-2-invitation-api-routes | Configure Invitation API routes | 6 | PENDING |
| worker-3-team-api-routes | Configure Team API routes | 14 | PENDING |
| worker-4-role-api-routes | Configure Role API routes | 8 | PENDING |
| worker-5-audit-api-routes | Configure Audit API routes | 4 | PENDING |
| worker-6-authorizer-integration | Integrate Lambda Authorizer | 1 | PENDING |

**Total**: 38 API Endpoints + 1 Authorizer

---

## Stage Inputs

**From Stage 2**:
- API Gateway Terraform module
- Lambda function ARNs

**From Stage 3**:
- Lambda function deployments
- OpenAPI specifications from LLDs

**LLD References**:
- OpenAPI specs from each LLD
- Authorizer configuration from LLD 2.8.5

---

## API Route Summary

### Permission Service Routes
```
GET    /v1/permissions                    → permission_list
GET    /v1/permissions/{permissionId}     → permission_get
POST   /v1/permissions                    → permission_create
PUT    /v1/permissions/{permissionId}     → permission_update
DELETE /v1/permissions/{permissionId}     → permission_delete
POST   /v1/permissions/seed               → permission_seed
```

### Invitation Service Routes
```
POST   /v1/orgs/{orgId}/invitations                      → invitation_create
GET    /v1/orgs/{orgId}/invitations                      → invitation_list
GET    /v1/orgs/{orgId}/invitations/{invitationId}       → invitation_get
DELETE /v1/orgs/{orgId}/invitations/{invitationId}       → invitation_cancel
POST   /v1/orgs/{orgId}/invitations/{invitationId}/resend → invitation_resend
POST   /v1/invitations/accept                            → invitation_accept
```

### Team Service Routes
```
POST   /v1/orgs/{orgId}/teams                                        → team_create
GET    /v1/orgs/{orgId}/teams                                        → team_list
GET    /v1/orgs/{orgId}/teams/{teamId}                               → team_get
PUT    /v1/orgs/{orgId}/teams/{teamId}                               → team_update
DELETE /v1/orgs/{orgId}/teams/{teamId}                               → team_delete
POST   /v1/orgs/{orgId}/teams/{teamId}/members                       → team_member_add
GET    /v1/orgs/{orgId}/teams/{teamId}/members                       → team_member_list
DELETE /v1/orgs/{orgId}/teams/{teamId}/members/{userId}              → team_member_remove
PUT    /v1/orgs/{orgId}/teams/{teamId}/members/{userId}/role         → team_member_update_role
POST   /v1/orgs/{orgId}/team-roles                                   → team_role_create
GET    /v1/orgs/{orgId}/team-roles                                   → team_role_list
GET    /v1/orgs/{orgId}/team-roles/{teamRoleId}                      → team_role_get
PUT    /v1/orgs/{orgId}/team-roles/{teamRoleId}                      → team_role_update
DELETE /v1/orgs/{orgId}/team-roles/{teamRoleId}                      → team_role_delete
```

### Role Service Routes
```
GET    /v1/platform/roles                        → platform_role_list
GET    /v1/platform/roles/{roleId}               → platform_role_get
POST   /v1/orgs/{orgId}/roles                    → org_role_create
GET    /v1/orgs/{orgId}/roles                    → org_role_list
GET    /v1/orgs/{orgId}/roles/{roleId}           → org_role_get
PUT    /v1/orgs/{orgId}/roles/{roleId}           → org_role_update
DELETE /v1/orgs/{orgId}/roles/{roleId}           → org_role_delete
POST   /v1/orgs/{orgId}/roles/seed               → org_role_seed
```

### Audit Service Routes
```
GET    /v1/orgs/{orgId}/audit                             → audit_query_org
GET    /v1/orgs/{orgId}/audit/users/{userId}              → audit_query_user
GET    /v1/orgs/{orgId}/audit/resources/{type}/{id}       → audit_query_resource
POST   /v1/orgs/{orgId}/audit/export                      → audit_export
```

---

## Stage Outputs

### OpenAPI Specification Files
```
api-specs/
├── permission-service.yaml
├── invitation-service.yaml
├── team-service.yaml
├── role-service.yaml
└── audit-service.yaml
```

### Terraform Route Configurations
```
terraform/modules/api-gateway/
├── routes/
│   ├── permission_routes.tf
│   ├── invitation_routes.tf
│   ├── team_routes.tf
│   ├── role_routes.tf
│   └── audit_routes.tf
└── authorizer.tf
```

---

## CORS Configuration

All endpoints must support:
```
Access-Control-Allow-Origin: *
Access-Control-Allow-Methods: GET, POST, PUT, DELETE, OPTIONS
Access-Control-Allow-Headers: Content-Type, Authorization, X-Request-ID
```

---

## Authorizer Configuration

| Setting | Value |
|---------|-------|
| Type | REQUEST |
| Identity Source | method.request.header.Authorization |
| TTL | 300 seconds |
| Lambda ARN | bbws-access-{env}-lambda-authorizer |

### Authorizer Context Variables
```json
{
  "userId": "user-123",
  "orgId": "org-456",
  "teamIds": "[\"team-1\",\"team-2\"]",
  "permissions": "[\"READ:TEAM\",\"WRITE:TEAM\"]"
}
```

---

## Success Criteria

- [ ] All 38 routes configured
- [ ] Lambda Authorizer integrated
- [ ] CORS enabled on all endpoints
- [ ] Request validation enabled
- [ ] Response mappings configured
- [ ] API documentation generated
- [ ] All endpoints tested in DEV
- [ ] All 6 workers completed
- [ ] Stage summary created

---

## Dependencies

**Depends On**: Stage 3 (Lambda Services Development)

**Blocks**: Stage 5 (Testing & Validation)

---

## Request Validation

Enable request validation for:
- Required path parameters
- Required query parameters
- Request body JSON schema

---

**Created**: 2026-01-23
