# E2E Implementation Plan: Customer Portal + Sites API in DEV

**Created**: 2026-01-25
**Updated**: 2026-01-25
**Status**: IN PROGRESS - Stage 3 Complete
**Goal**: Deploy and test Customer Portal Frontend + Sites API E2E in DEV environment

---

## Current State Analysis

### Frontend (Customer Self-Service Portal)
| Item | Status | Details |
|------|--------|---------|
| Location | EXISTS | `/2_1_bbws_web_public/customer_self_service/` |
| Framework | React 18 + TypeScript + Vite | Port 3001 (vite.config.ts) |
| Pages | IMPLEMENTED | Dashboard, Sites, Billing, Support, Organisation |
| Auth | IMPLEMENTED | Cognito integration (af-south-1) |
| API Service | IMPLEMENTED | `apiService.ts` with retry logic |
| Build | NOT TESTED | Needs verification |
| Deployment | NOT DEPLOYED | Needs S3 + CloudFront |

### Backend (Sites API)
| Item | Status | Details |
|------|--------|---------|
| Lambda | DEPLOYED | `dev-bbws-sites-service` (eu-west-1) |
| API Gateway | DEPLOYED | `https://en6tdna9z4.execute-api.eu-west-1.amazonaws.com/v1` |
| Endpoints | VERIFIED | All 5 CRUD endpoints working |
| Auth | ENABLED | Cognito authorizer `dev-bbws-authorizer` (af-south-1_6r46cbkIR) |
| DynamoDB | DEPLOYED | `dev-bbws-sites` table |

---

## Gap Analysis

### Critical Gaps

| # | Gap | Impact | Resolution | Status |
|---|-----|--------|------------|--------|
| 1 | **API Path Mismatch** | Frontend can't call backend | Update frontend to use `/v1.0/tenants/{tenantId}/sites` | ✅ RESOLVED |
| 2 | **API Base URL** | Frontend points to wrong API | Update `.env.development` with correct API Gateway URL | ✅ RESOLVED |
| 3 | **No API Gateway Domain** | No `api.dev.kimmyai.io` configured | Using direct API Gateway URL | ✅ RESOLVED |
| 4 | **Auth Disabled** | No JWT validation | Enable Cognito authorizer in API Gateway | ✅ RESOLVED |
| 5 | **Frontend Not Deployed** | No DEV hosting | Deploy to S3 + CloudFront | ✅ RESOLVED |
| 6 | **CORS** | Cross-origin blocked | Configure CORS in API Gateway | ✅ RESOLVED

### API Path Mapping Required

| Frontend Expects | Backend Has | Action |
|------------------|-------------|--------|
| `GET /portal/sites?orgId=X` | `GET /v1/v1.0/tenants/{tenantId}/sites` | Update frontend |
| `GET /portal/sites/{siteId}` | `GET /v1/v1.0/tenants/{tenantId}/sites/{siteId}` | Update frontend |
| `POST /portal/sites` | `POST /v1/v1.0/tenants/{tenantId}/sites` | Update frontend |
| `PUT /portal/sites/{siteId}` | `PUT /v1/v1.0/tenants/{tenantId}/sites/{siteId}` | Update frontend |
| `DELETE /portal/sites/{siteId}` | `DELETE /v1/v1.0/tenants/{tenantId}/sites/{siteId}` | Update frontend |

---

## Implementation Plan

### Stage 1: Frontend API Integration Fix (Day 1)

#### Worker 1.1: Update Sites API Service
**File**: `src/services/apiService.ts`

Update the `sites` namespace to match the backend API paths:

```typescript
sites: {
  list: (tenantId: string, pageSize?: number) =>
    get<PaginatedResponse<Site>>(`/v1/v1.0/tenants/${tenantId}/sites?pageSize=${pageSize || 20}`),
  get: (tenantId: string, siteId: string) =>
    get<PortalApiResponse<Site>>(`/v1/v1.0/tenants/${tenantId}/sites/${siteId}`),
  create: (tenantId: string, data: CreateSiteRequest) =>
    post<PortalApiResponse<Site>>(`/v1/v1.0/tenants/${tenantId}/sites`, data),
  update: (tenantId: string, siteId: string, data: UpdateSiteRequest) =>
    put<PortalApiResponse<Site>>(`/v1/v1.0/tenants/${tenantId}/sites/${siteId}`, data),
  delete: (tenantId: string, siteId: string) =>
    del<void>(`/v1/v1.0/tenants/${tenantId}/sites/${siteId}`),
},
```

#### Worker 1.2: Update Environment Configuration
**File**: `.env.development`

```bash
# Update API Base URL to point to deployed API Gateway
VITE_API_BASE_URL=https://en6tdna9z4.execute-api.eu-west-1.amazonaws.com

# Sites API (WordPress Site Management)
VITE_SITES_API_BASE_URL=https://en6tdna9z4.execute-api.eu-west-1.amazonaws.com/v1
```

#### Worker 1.3: Update Pages to Use Tenant Context
**Files**: `SitesList.tsx`, `CreateSite.tsx`, `SiteDetails.tsx`

Ensure pages get `tenantId` from TenantContext and pass to API calls.

---

### Stage 2: Enable API Gateway Authentication (Day 1)

#### Worker 2.1: Configure Cognito Authorizer
**File**: `terraform/environments/dev/dev.tfvars`

```hcl
api_enable_authorizer = true
jwt_audience = ["4aumtdc4i01mcmik118shulgjb"]  # From frontend .env
jwt_issuer   = "https://cognito-idp.af-south-1.amazonaws.com/af-south-1_6r46cbkIR"
```

#### Worker 2.2: Apply Terraform Changes
```bash
cd terraform/environments/dev
terraform plan -var-file=dev.tfvars
terraform apply -var-file=dev.tfvars
```

#### Worker 2.3: Configure CORS in API Gateway
Add CORS headers to allow frontend domain:
- `Access-Control-Allow-Origin: https://dev.portal.kimmyai.io`
- `Access-Control-Allow-Headers: Authorization, Content-Type`
- `Access-Control-Allow-Methods: GET, POST, PUT, DELETE, OPTIONS`

---

### Stage 3: Deploy Frontend to DEV (Day 2)

#### Worker 3.1: Build Frontend
```bash
cd /2_1_bbws_web_public/customer_self_service
npm install
npm run build:dev
```

#### Worker 3.2: Create S3 Bucket + CloudFront (Terraform)
**Resources needed**:
- S3 bucket: `dev-bbws-customer-portal`
- CloudFront distribution
- Route53 record: `dev.portal.kimmyai.io`

#### Worker 3.3: Deploy to S3
```bash
aws s3 sync dist/ s3://dev-bbws-customer-portal/portal/ --delete
aws cloudfront create-invalidation --distribution-id <ID> --paths "/portal/*"
```

---

### Stage 4: E2E Testing (Day 2-3)

#### Worker 4.1: Auth Flow Testing
| Test | Steps | Expected |
|------|-------|----------|
| Login | Navigate to /portal/login, enter credentials | Redirect to /portal/dashboard |
| Register | Navigate to /portal/register, complete form | Email verification sent |
| Logout | Click logout | Redirect to /portal/login |

#### Worker 4.2: Sites CRUD Testing
| Test | Steps | Expected |
|------|-------|----------|
| List Sites | Navigate to /portal/sites | Empty list (no sites yet) |
| Create Site | Click "New Site", fill form, submit | Site created, redirect to list |
| View Site | Click on site card | Site details displayed |
| Update Site | Edit site name, save | Site updated |
| Delete Site | Click delete, confirm | Site removed from list |

#### Worker 4.3: Integration Testing
| Test | Steps | Expected |
|------|-------|----------|
| Auth + API | Login, then list sites | 200 OK with JWT |
| Error Handling | Invalid site ID | 404 error displayed |
| Validation | Create site with missing fields | Validation errors shown |

---

## Technical Decisions

### Option A: Use Existing API Gateway URL (Recommended)
- Update frontend to use `https://en6tdna9z4.execute-api.eu-west-1.amazonaws.com/v1`
- Faster to implement
- No custom domain needed

### Option B: Configure Custom Domain
- Set up `api.dev.kimmyai.io` pointing to API Gateway
- Requires Route53 + ACM certificate
- Better for production-like testing

**Decision**: Start with Option A, configure custom domain in Stage 5.

---

## Dependencies

| Component | Required By | Status |
|-----------|-------------|--------|
| Cognito User Pool (af-south-1) | Frontend Auth | EXISTS |
| API Gateway (eu-west-1) | Sites API | DEPLOYED |
| DynamoDB (eu-west-1) | Sites Storage | DEPLOYED |
| S3 Bucket | Frontend Hosting | TO CREATE |
| CloudFront | CDN | TO CREATE |
| Route53 | DNS | EXISTS |

---

## Risk Assessment

| Risk | Impact | Mitigation |
|------|--------|------------|
| Cognito region mismatch (af-south-1 vs eu-west-1) | Auth may fail | Test cross-region JWT validation |
| CORS issues | API calls blocked | Configure CORS before testing |
| Cold start latency | Slow first requests | Accept for DEV, add provisioned concurrency later |

---

## Success Criteria

- [ ] Frontend builds successfully
- [ ] Frontend deployed to S3/CloudFront
- [ ] User can login via Cognito
- [ ] Sites list page loads (empty list OK)
- [ ] Can create a new site
- [ ] Can view site details
- [ ] Can update site name
- [ ] Can delete site
- [ ] All API calls return proper HATEOAS responses
- [ ] Error handling works (404, 400 scenarios)

---

## Estimated Timeline

| Stage | Duration | Dependencies |
|-------|----------|--------------|
| Stage 1: Frontend API Fix | 2-3 hours | None |
| Stage 2: API Auth Config | 1-2 hours | Stage 1 |
| Stage 3: Frontend Deploy | 2-3 hours | Stage 1, 2 |
| Stage 4: E2E Testing | 2-4 hours | Stage 3 |

**Total**: 1-2 days

---

## Files to Modify

### Frontend
1. `src/services/apiService.ts` - Update sites API paths
2. `src/pages/SitesList.tsx` - Use tenant context for API calls
3. `src/pages/CreateSite.tsx` - Use tenant context for API calls
4. `src/pages/SiteDetails.tsx` - Use tenant context for API calls
5. `.env.development` - Update API base URL
6. `vite.config.ts` - Verify port and base path

### Backend (Terraform)
1. `terraform/environments/dev/dev.tfvars` - Enable authorizer
2. `terraform/modules/api_gateway/main.tf` - Add CORS configuration

### Infrastructure (New)
1. Create S3 bucket for frontend
2. Create CloudFront distribution
3. Create Route53 record

---

## Next Steps

1. **Approve this plan** - Confirm approach
2. **Start Stage 1** - Fix frontend API integration
3. **Test locally** - Verify frontend calls correct API
4. **Continue stages** - Auth, Deploy, E2E test

---

**Status**: READY FOR APPROVAL
