# Worker Instructions: API Gateway Module

**Worker ID**: worker-3-api-gateway-module
**Stage**: Stage 2 - Infrastructure Terraform
**Project**: project-plan-2-access-management

---

## Task

Create Terraform module for API Gateway REST API supporting all Access Management endpoints. Include stage configuration for DEV, SIT, PROD.

---

## Inputs

**From Stage 1**:
- API contract summaries from all workers
- Endpoint mappings

**Reference**:
- Stage 4 plan for route details

---

## Deliverables

Create Terraform module in `output.md`:

### 1. Module Structure

```
terraform/modules/api-gateway-access-management/
├── main.tf           # API definition
├── resources.tf      # Resource paths
├── methods.tf        # HTTP methods
├── integrations.tf   # Lambda integrations
├── responses.tf      # Response templates
├── cors.tf           # CORS configuration
├── stage.tf          # Stage configuration
├── variables.tf
└── outputs.tf
```

### 2. API Configuration

**API Name**: `bbws-access-{env}-apigw`
**Type**: REST API
**Endpoint Type**: REGIONAL

### 3. Resource Paths

```
/v1
├── /permissions
│   ├── GET (list)
│   ├── POST (create)
│   ├── /{permissionId}
│   │   ├── GET (get)
│   │   ├── PUT (update)
│   │   └── DELETE (delete)
│   └── /seed
│       └── POST (seed)
├── /platform
│   └── /roles
│       ├── GET (list)
│       └── /{roleId}
│           └── GET (get)
├── /orgs/{orgId}
│   ├── /invitations
│   │   ├── GET, POST
│   │   └── /{invitationId}
│   │       ├── GET, DELETE
│   │       └── /resend POST
│   ├── /teams
│   │   ├── GET, POST
│   │   └── /{teamId}
│   │       ├── GET, PUT, DELETE
│   │       └── /members
│   │           ├── GET, POST
│   │           └── /{userId}
│   │               ├── DELETE
│   │               └── /role PUT
│   ├── /team-roles
│   │   ├── GET, POST
│   │   └── /{teamRoleId}
│   │       ├── GET, PUT, DELETE
│   ├── /roles
│   │   ├── GET, POST
│   │   └── /{roleId}
│   │       ├── GET, PUT, DELETE
│   │   └── /seed POST
│   └── /audit
│       ├── GET
│       ├── /users/{userId} GET
│       ├── /resources/{type}/{id} GET
│       └── /export POST
└── /invitations
    └── /accept POST
```

### 4. CORS Configuration

```hcl
Access-Control-Allow-Origin: *
Access-Control-Allow-Methods: GET, POST, PUT, DELETE, OPTIONS
Access-Control-Allow-Headers: Content-Type, Authorization, X-Request-ID
```

### 5. Stage Variables

| Variable | DEV | SIT | PROD |
|----------|-----|-----|------|
| log_level | DEBUG | INFO | WARN |
| throttle_rate | 100 | 500 | 1000 |
| throttle_burst | 50 | 200 | 500 |

---

## Success Criteria

- [ ] All 38+ endpoints configured
- [ ] CORS enabled on all endpoints
- [ ] OPTIONS method for preflight
- [ ] Lambda proxy integration
- [ ] Request validation enabled
- [ ] Stage variables defined
- [ ] CloudWatch logging enabled
- [ ] Environment parameterized

---

## Execution Steps

1. Read Stage 1 API contract summaries
2. Create API definition
3. Create resource hierarchy
4. Configure methods and integrations
5. Add CORS configuration
6. Configure stages
7. Enable logging
8. Create variables and outputs
9. Create output.md
10. Update work.state to COMPLETE

---

**Status**: PENDING
**Created**: 2026-01-23
