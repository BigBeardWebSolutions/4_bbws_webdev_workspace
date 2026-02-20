# Worker Instructions: Authorizer Integration

**Worker ID**: worker-6-authorizer-integration
**Stage**: Stage 4 - API Gateway Integration
**Project**: project-plan-2-access-management

---

## Task

Configure the Lambda Authorizer integration with API Gateway and create the endpoint-permission mapping configuration.

---

## Deliverables

Create `output.md` with:

### 1. Authorizer Configuration
```hcl
resource "aws_api_gateway_authorizer" "access_management" {
  name                   = "access-management-authorizer"
  rest_api_id            = var.api_gateway_id
  authorizer_uri         = var.authorizer_lambda_invoke_arn
  type                   = "TOKEN"
  identity_source        = "method.request.header.Authorization"
  authorizer_result_ttl_in_seconds = 300
}
```

### 2. Endpoint Permission Mapping
Complete mapping of endpoints to required permissions:

| Endpoint Pattern | Required Permission |
|-----------------|---------------------|
| GET /permissions | permission:read |
| POST /permissions | permission:write |
| GET /orgs/{orgId}/teams | team:read |
| POST /orgs/{orgId}/teams | team:write |
| ... | ... |

### 3. Public Endpoints (No Auth)
- GET /v1/invitations/{token}
- POST /v1/invitations/accept
- POST /v1/invitations/{token}/decline

### 4. Authorizer Response Caching
- Cache TTL: 300 seconds
- Cache key: Authorization header

### 5. Error Responses
- 401 Unauthorized (invalid/missing token)
- 403 Forbidden (insufficient permissions)

---

## Success Criteria

- [ ] Authorizer attached to all protected routes
- [ ] Public routes excluded from authorizer
- [ ] Permission mapping documented
- [ ] Cache TTL configured
- [ ] Error responses configured

---

**Status**: PENDING
**Created**: 2026-01-23
