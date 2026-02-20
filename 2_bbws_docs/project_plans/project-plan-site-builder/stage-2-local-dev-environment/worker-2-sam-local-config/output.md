# Worker 2: SAM Local Config - Output

**Worker**: worker-2-sam-local-config
**Stage**: Stage 2 - Local Development Environment
**Status**: COMPLETE
**Completed**: 2026-01-16

---

## Deliverables Created

### SAM Configuration Files

| File | Path | Purpose |
|------|------|---------|
| template.yaml | `local-dev/sam/template.yaml` | SAM template with all Lambda functions |
| samconfig.toml | `local-dev/sam/samconfig.toml` | SAM CLI configuration for local/dev/sit/prod |

### Lambda Service Handlers

| Service | Path | Endpoints |
|---------|------|-----------|
| tenant_service | `api/tenant_service/handler.py` | GET/POST /tenants, GET/PUT /tenants/{id} |
| user_service | `api/user_service/handler.py` | GET/POST /users, GET /users/{id} |
| site_service | `api/site_service/handler.py` | CRUD /sites, DELETE /sites/{id} |
| generation_service | `api/generation_service/handler.py` | POST /generate, GET /generations |
| agent_service | `api/agent_service/handler.py` | POST /agents/{type}/invoke |
| validation_service | `api/validation_service/handler.py` | POST /validate, GET /validation |
| deployment_service | `api/deployment_service/handler.py` | POST /deploy, GET /deployments |
| partner_service | `api/partner_service/handler.py` | Full Epic 9 partner APIs |

---

## API Endpoints Configured

### Core Services
- `GET/POST /v1/tenants` - Tenant management
- `GET/POST /v1/tenants/{tenantId}/users` - User management
- `GET/POST/PUT/DELETE /v1/sites` - Site CRUD
- `POST /v1/sites/{siteId}/generate` - Page generation
- `GET /v1/generations/{generationId}` - Generation status

### Agent Services (Epic 6)
- `POST /v1/agents/outliner/invoke`
- `POST /v1/agents/theme-selector/invoke`
- `POST /v1/agents/layout/invoke`
- `POST /v1/agents/logo-creator/invoke`
- `POST /v1/agents/background-image/invoke`
- `POST /v1/agents/blogger/invoke`

### Partner Services (Epic 9)
- `GET/POST /v1/partners` - Partner CRUD
- `GET/PUT /v1/partners/{partnerId}/branding` - Branding config
- `GET /v1/partners/{partnerId}/tenants` - Sub-tenant management
- `GET /v1/partners/{partnerId}/subscription` - Subscription info
- `GET /v1/partners/{partnerId}/billing` - Billing/metering data

---

## Environment Configuration

```bash
# Local development
ENVIRONMENT=local
AWS_ENDPOINT_URL=http://host.docker.internal:4566
AGENT_MOCK_URL=http://host.docker.internal:3002

# DynamoDB Tables
DYNAMODB_TENANTS_TABLE=bbws-site-builder-tenants-dev
DYNAMODB_USERS_TABLE=bbws-site-builder-users-dev
DYNAMODB_SITES_TABLE=bbws-site-builder-sites-dev
DYNAMODB_GENERATIONS_TABLE=bbws-site-builder-generations-dev
DYNAMODB_DEPLOYMENTS_TABLE=bbws-site-builder-deployments-dev
DYNAMODB_PARTNERS_TABLE=bbws-site-builder-partners-dev
```

---

## Verification Commands

```bash
# Start SAM Local API
cd local-dev/sam
sam local start-api --port 3001 --docker-network bbws-local-network

# Test tenant endpoint
curl http://localhost:3001/local/v1/tenants

# Test site creation
curl -X POST http://localhost:3001/local/v1/sites \
  -H "Content-Type: application/json" \
  -H "X-Tenant-ID: test-tenant" \
  -d '{"name": "My Site"}'
```

---

## Success Criteria Met

- [x] SAM template defines all 8 Lambda services
- [x] samconfig.toml supports local/dev/sit/prod environments
- [x] All API endpoints match LLD specification
- [x] Environment variables configured for LocalStack
- [x] CORS configured for localhost:5173
- [x] HATEOAS _links included in responses
- [x] In-memory stores for local development

---

**Output Location**: `/Users/tebogotseka/Documents/agentic_work/0_playpen/bbws-site-builder-local/`
