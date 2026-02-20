# PP-001: Site Builder DEV Environment Integration Plan

**Project**: BBWS Site Builder - DEV Environment Integration
**Version**: 1.0
**Created**: 2026-01-18
**Last Updated**: 2026-01-18
**Status**: IN_PROGRESS
**Environment**: DEV (eu-west-1)

---

## Executive Summary

This plan tracks the remaining tasks to complete the Site Builder DEV environment integration, connecting the payment flow (PayFast) with the Site Builder application through proper authentication and provisioning.

### Current State
- API deployed at: `https://api.dev.kimmyai.io/site_builder/health` (working)
- Frontend exists at: `http://localhost:5177/` (needs deployment)
- PayFast sandbox: Integrated (working)
- Authentication: Not configured
- Provisioning: Not implemented

### Target State
- Complete user journey: `/buy` → PayFast → `/success` → Login → Site Builder
- Authenticated users can generate AI landing pages
- Tenant provisioning on first login after purchase

---

## Task State Legend

| State | Symbol | Description |
|-------|--------|-------------|
| TODO | `[ ]` | Not started |
| IN_PROGRESS | `[~]` | Currently being worked on |
| DONE | `[x]` | Completed |
| BLOCKED | `[!]` | Blocked by dependency or issue |
| SKIPPED | `[-]` | Not applicable or deferred |

---

## Phase 1: API Route Alignment ✅ COMPLETE

**Objective**: Align Lambda handler routes with API Gateway configuration

### Tasks

| ID | Task | State | Dependencies | Owner | Notes |
|----|------|-------|--------------|-------|-------|
| 1.1 | Audit API Gateway routes in Terraform | `[x]` | - | Claude | Checked `modules/api_gateway/main.tf` |
| 1.2 | Audit Lambda handler routes | `[x]` | - | Claude | Checked `generation_service/handler.py`, `validation_service/handler.py` |
| 1.3 | Create route mapping document | `[x]` | 1.1, 1.2 | Claude | Found mismatch: API GW used old routes, Lambdas expected RESTful |
| 1.4 | Update API Gateway to match Lambda handlers | `[x]` | 1.3 | Claude | Updated `main.tf` with 25+ RESTful routes |
| 1.5 | Test all API endpoints | `[x]` | 1.4 | Claude | Health ✅, Generation ✅, Validation needs DynamoDB table |
| 1.6 | Update OpenAPI spec if needed | `[-]` | 1.5 | Claude | Skipped - routes defined in Terraform |

### Deployed Routes (Updated 2026-01-18)

**Generation Service (page-generator Lambda)**
| Endpoint | Method | Purpose |
|----------|--------|---------|
| `/v1/sites/{siteId}/generate` | POST | Create new generation |
| `/v1/sites/{siteId}/generations` | GET | List generations for site |
| `/v1/sites/{siteId}/refine` | POST | Create refinement |
| `/v1/generations/{generationId}` | GET | Get generation details |
| `/v1/generations/{generationId}/stream` | GET | SSE streaming endpoint |
| `/v1/generations/{generationId}/start` | POST | Start generation |
| `/v1/generations/{generationId}/complete` | POST | Mark complete |
| `/v1/generations/{generationId}/fail` | POST | Mark failed |
| `/v1/generations/{generationId}/cancel` | POST | Cancel generation |
| `/v1/generations/{generationId}/steps/{stepName}` | POST | Update step |
| `/v1/generations/{generationId}/agents/{agentName}/invoke` | POST | Invoke agent |

**Validation Service (brand-validator Lambda)**
| Endpoint | Method | Purpose |
|----------|--------|---------|
| `/v1/sites/{siteId}/validate` | POST | Create and run validation |
| `/v1/sites/{siteId}/validation` | GET | Get latest validation |
| `/v1/sites/{siteId}/validations` | GET | List validations |
| `/v1/sites/{siteId}/auto-fix` | POST | Auto-fix issues |
| `/v1/validations/{validationId}` | GET | Get validation details |
| `/v1/validations/{validationId}/report` | GET | Get report |
| `/v1/validations/{validationId}/start` | POST | Start validation |
| `/v1/validations/{validationId}/run` | POST | Run checks |
| `/v1/validations/{validationId}/checks/{ruleName}` | POST | Update check |
| `/v1/validations/{validationId}/fail` | POST | Mark failed |

**Logo Creator & Theme Selector**
| Endpoint | Method | Purpose |
|----------|--------|---------|
| `/v1/sites/{siteId}/logo` | POST | Create logo |
| `/v1/logos/{logoId}` | GET | Get logo |
| `/v1/sites/{siteId}/theme` | POST | Select theme |
| `/v1/sites/{siteId}/theme/suggestions` | POST | Get suggestions |
| `/health` | GET | Health check |

---

## Phase 2: Authentication Setup (Cognito) ✅ COMPLETE

**Objective**: Configure AWS Cognito for user authentication with JWT

### Tasks

| ID | Task | State | Dependencies | Owner | Notes |
|----|------|-------|--------------|-------|-------|
| 2.1 | Check existing Cognito User Pool in DEV | `[x]` | - | Claude | Found `bbws-tenant-admin-dev` (internal admins) |
| 2.2 | Document Cognito configuration requirements | `[x]` | - | Claude | Custom attributes documented |
| 2.3 | Create/Update Cognito User Pool Terraform | `[x]` | 2.1, 2.2 | Claude | Created `modules/cognito/` |
| 2.4 | Configure Cognito App Client | `[x]` | 2.3 | Claude | Frontend + Backend clients created |
| 2.5 | Add JWT Authorizer to API Gateway | `[x]` | 2.3 | Claude | Added to `api_gateway/main.tf` (disabled by default) |
| 2.6 | Apply Terraform changes | `[x]` | 2.5 | Claude | Deployed to DEV |
| 2.7 | Test authentication flow | `[ ]` | 2.6 | Claude | Pending frontend integration |

### Deployed Cognito Resources

| Resource | ID | Notes |
|----------|-----|-------|
| User Pool | `eu-west-1_7lTiUAQXe` | Self-registration enabled |
| User Pool Domain | `site-builder-dev-536580886816` | Cognito hosted UI |
| Frontend Client | `5groa6q12cdi65a7535rumkvfk` | No client secret |
| Backend Client | `3ahftdio0ofbk809g9ai0tt1ev` | With client secret |
| JWT Issuer | `https://cognito-idp.eu-west-1.amazonaws.com/eu-west-1_7lTiUAQXe` | |
| JWKS URI | `https://cognito-idp.eu-west-1.amazonaws.com/eu-west-1_7lTiUAQXe/.well-known/jwks.json` | |

### Cognito Custom Attributes

| Attribute | Type | Purpose |
|-----------|------|---------|
| `custom:tenant_id` | String | Link user to tenant |
| `custom:role` | String | User permissions (tenant_admin, site_admin, viewer) |
| `custom:plan` | String | Subscription plan |

### Frontend Integration

**Replaced AWS Amplify with amazon-cognito-identity-js** (first principles approach):
- Removed 178 packages from bundle
- Created `cognitoService.ts` with direct Cognito API calls
- Updated `AuthContext.tsx` to use new service
- Maintains mock auth for local development

**Environment Variables** (`.env.dev`):
```bash
VITE_COGNITO_USER_POOL_ID=eu-west-1_7lTiUAQXe
VITE_COGNITO_CLIENT_ID=5groa6q12cdi65a7535rumkvfk
VITE_AWS_REGION=eu-west-1
```

---

## Phase 3: Tenant Provisioning

**Objective**: Create Lambda function to provision new tenants after payment

### Tasks

| ID | Task | State | Dependencies | Owner | Notes |
|----|------|-------|--------------|-------|-------|
| 3.1 | Design provisioning Lambda | `[ ]` | - | Claude | Input: payment data, Output: tenant record |
| 3.2 | Create DynamoDB tables Terraform | `[ ]` | - | Claude | tenants, users tables |
| 3.3 | Create provisioning Lambda code | `[ ]` | 3.1 | Claude | `/api/provisioning_service/` |
| 3.4 | Add provisioning Lambda to Terraform | `[ ]` | 3.2, 3.3 | Claude | IAM, environment vars |
| 3.5 | Configure SNS trigger from PayFast ITN | `[ ]` | 3.4 | Claude | Or API Gateway endpoint |
| 3.6 | Apply Terraform | `[ ]` | 3.5 | Claude | Deploy to DEV |
| 3.7 | Test provisioning flow | `[ ]` | 3.6 | Claude | Mock payment → tenant created |
| 3.8 | Integrate with Cognito user creation | `[ ]` | 2.3, 3.6 | Claude | Create Cognito user with tenant_id |

### Provisioning Lambda Responsibilities

1. Receive PayFast ITN or payment confirmation
2. Validate payment
3. Create tenant record in DynamoDB
4. Create Cognito user (or link existing)
5. Set user attributes (tenant_id, roles)
6. Send welcome email (optional)
7. Return success/redirect URL

---

## Phase 4: Frontend Deployment

**Objective**: Deploy Site Builder frontend to DEV environment

### Existing Frontend Info (Confirmed)
- **Local URL**: `http://localhost:5177/`
- **Source Location**: `/Users/tebogotseka/Documents/agentic_work/3_bbws-site-builder-local/frontend/`
- **Framework**: React 19 + TailwindCSS
- **Auth Library**: AWS Amplify (Cognito integration)
- **API Client**: React Query (@tanstack/react-query)
- **Build Command**: `npm run build` (outputs to `dist/`)
- **Port Config**: Vite default (5173) - running on 5177 via custom config

### Environment Variables Required
```bash
# DEV Environment (.env.production or .env.dev)
VITE_API_URL=https://api.dev.kimmyai.io/site_builder
VITE_SSE_URL=https://api.dev.kimmyai.io/site_builder
VITE_COGNITO_USER_POOL_ID=eu-west-1_XXXXXXXXX  # From Phase 2
VITE_COGNITO_CLIENT_ID=XXXXXXXXXXXXXXXXXX       # From Phase 2
VITE_AWS_REGION=eu-west-1
VITE_APP_ENV=dev
```

### Tasks

| ID | Task | State | Dependencies | Owner | Notes |
|----|------|-------|--------------|-------|-------|
| 4.1 | Locate frontend source code | `[x]` | - | Claude | `/3_bbws-site-builder-local/frontend/` |
| 4.2 | Review frontend configuration | `[x]` | 4.1 | Claude | Uses AWS Amplify, env vars documented |
| 4.3 | Create S3 bucket for frontend (Terraform) | `[ ]` | - | Claude | `site-builder-frontend-dev` |
| 4.4 | Create CloudFront distribution (Terraform) | `[ ]` | 4.3 | Claude | OAC, custom error pages |
| 4.5 | Create .env.dev with DEV API URLs | `[ ]` | 4.2 | Claude | Point to api.dev.kimmyai.io |
| 4.6 | Update frontend auth config | `[ ]` | 2.4, 4.5 | Claude | Cognito pool ID, client ID |
| 4.7 | Build frontend for DEV | `[ ]` | 4.6 | Claude | `npm run build` |
| 4.8 | Deploy to S3 | `[ ]` | 4.7 | Claude | `aws s3 sync dist/ s3://bucket/` |
| 4.9 | Configure DNS (Route 53) | `[ ]` | 4.4 | Claude | `app.dev.kimmyai.io` |
| 4.10 | Test frontend in DEV | `[ ]` | 4.9 | Claude | Login, generate page |

---

## Phase 5: Payment Integration

**Objective**: Connect PayFast success flow to Site Builder

### Existing Integration
- PayFast sandbox is integrated on `/buy` page
- Success page exists at `/success`
- Need: Redirect from `/success` to Site Builder (with auth)

### Tasks

| ID | Task | State | Dependencies | Owner | Notes |
|----|------|-------|--------------|-------|-------|
| 5.1 | Review current /success page logic | `[ ]` | - | Claude | Find source |
| 5.2 | Design redirect flow | `[ ]` | 2.4, 3.8 | Claude | After payment confirmed |
| 5.3 | Implement redirect to login/register | `[ ]` | 5.2 | Claude | Pass payment reference |
| 5.4 | Handle first-time user registration | `[ ]` | 5.3 | Claude | Cognito sign-up flow |
| 5.5 | Handle returning user login | `[ ]` | 5.3 | Claude | Cognito sign-in |
| 5.6 | Redirect authenticated user to Site Builder | `[ ]` | 5.4, 5.5 | Claude | With valid JWT |
| 5.7 | Test complete payment → Site Builder flow | `[ ]` | 5.6 | Claude | E2E test |

### Flow Diagram

```
[/buy] → [PayFast Checkout] → [PayFast ITN] → [Provisioning Lambda]
                                    ↓                    ↓
                            [/success page]      [Create Tenant]
                                    ↓                    ↓
                            [/login or /register] ← [Create User]
                                    ↓
                            [Cognito Auth]
                                    ↓
                            [Site Builder App]
```

---

## Phase 6: End-to-End Testing

**Objective**: Verify complete user journey works

### Tasks

| ID | Task | State | Dependencies | Owner | Notes |
|----|------|-------|--------------|-------|-------|
| 6.1 | Create E2E test scenarios | `[ ]` | All phases | Claude | Document test cases |
| 6.2 | Test: New user purchase flow | `[ ]` | 6.1 | Claude | Buy → Provision → Login |
| 6.3 | Test: Returning user purchase flow | `[ ]` | 6.1 | Claude | Buy → Link to existing tenant |
| 6.4 | Test: Generate landing page | `[ ]` | 6.1 | Claude | Prompt → AI → Preview |
| 6.5 | Test: Brand validation | `[ ]` | 6.1 | Claude | Score ≥ 8.0 |
| 6.6 | Test: Deploy to staging | `[ ]` | 6.1 | Claude | S3 deployment |
| 6.7 | Document issues found | `[ ]` | 6.2-6.6 | Claude | Track bugs |
| 6.8 | Fix issues | `[ ]` | 6.7 | Claude | Iterate |
| 6.9 | Sign off DEV environment | `[ ]` | 6.8 | User | Ready for SIT promotion |

### Test Scenarios

| ID | Scenario | Expected Result |
|----|----------|-----------------|
| TC-001 | New user completes purchase with PayFast sandbox | Tenant created, welcome email received |
| TC-002 | User logs in after purchase | JWT issued, redirected to Site Builder |
| TC-003 | User generates landing page with prompt | AI generates HTML, preview displayed |
| TC-004 | Generated page passes brand validation | Score ≥ 8.0, deploy eligible |
| TC-005 | User deploys page to staging | Page accessible via S3 URL |
| TC-006 | User cannot exceed plan limits | 429 error with clear message |
| TC-007 | Invalid/expired JWT rejected | 401 error, redirect to login |

---

## Dependencies Matrix

| Task | Depends On |
|------|------------|
| Phase 2 (Auth) | Phase 1 (API Routes) - partial |
| Phase 3 (Provisioning) | Phase 2 (Cognito) |
| Phase 4 (Frontend) | Phase 2 (Cognito) |
| Phase 5 (Payment) | Phase 3, Phase 4 |
| Phase 6 (E2E) | All phases |

---

## Risks and Mitigations

| Risk | Impact | Probability | Mitigation |
|------|--------|-------------|------------|
| Cognito already exists with different config | Medium | Medium | Audit existing, migrate carefully |
| Frontend uses different auth library | Medium | Low | Adapt to existing implementation |
| PayFast ITN timing issues | High | Low | Implement retry logic, dead letter queue |
| API Gateway route conflicts | Low | Medium | Careful Terraform planning |

---

## Progress Tracking

### Completed This Session
- [x] DEV API deployment completed
- [x] Custom domain configured (api.dev.kimmyai.io/site_builder)
- [x] Health endpoint working
- [x] Business process documents created (BP-001 to BP-006)
- [x] Runbooks created (RB-001, RB-002)
- [x] SOPs created (SOP-001 to SOP-003)
- [x] BRS updated with Epic 10
- [x] **Phase 1 Complete**: API route alignment (25+ RESTful routes deployed)
- [x] **Phase 2 Complete**: Cognito authentication setup
- [x] Frontend auth refactored (Amplify → amazon-cognito-identity-js)

### Next Actions
1. Phase 3: Tenant provisioning Lambda + DynamoDB tables
2. Phase 4: Frontend deployment to S3/CloudFront
3. Phase 5: Payment integration with Site Builder

---

## Session Notes

### 2026-01-18 - Session 1
- DEV deployment completed after fixing:
  - Lambda S3 bucket region (af-south-1 → eu-west-1)
  - API Gateway Connection header restriction
  - Lambda handler paths
  - HTTP API v2 event format support
  - Health check endpoint
- Custom domain configured with existing ACM certificate
- Documentation created for all business processes
- This project plan created

### 2026-01-18 - Session 2 (Continued)
- Frontend confirmed at `/3_bbws-site-builder-local/frontend/`
- Screenshot reviewed showing Site Builder dashboard at localhost:5177
- Frontend tech stack confirmed:
  - React 19 + TailwindCSS
  - AWS Amplify for Cognito auth
  - React Query for API state
  - MSW for local mocking
- Environment variables documented for DEV deployment
- Phase 4 tasks 4.1, 4.2 marked complete

### 2026-01-18 - Session 3 (Auth Refactor + Cognito)
- **Replaced AWS Amplify with amazon-cognito-identity-js** (first principles approach)
  - Removed 178 packages from bundle
  - Created new `cognitoService.ts` with direct Cognito API calls
  - Updated `AuthContext.tsx` to use new service
  - Maintains mock auth for local development
- **Created Cognito Terraform module** at `modules/cognito/`
  - User Pool: `site-builder-dev` (eu-west-1_7lTiUAQXe)
  - Frontend Client: `5groa6q12cdi65a7535rumkvfk`
  - Backend Client: `3ahftdio0ofbk809g9ai0tt1ev`
  - Custom attributes: tenant_id, role, plan
  - Self-registration enabled
- **Created `.env.dev`** with Cognito configuration
- Phase 2 (Authentication) substantially complete

### 2026-01-18 - Session 4 (API Route Alignment)
- **Completed Phase 1: API Route Alignment**
  - Audited API Gateway routes (old: `/generate/page`, `/validate/brand`)
  - Audited Lambda handler routes (expected: `/v1/sites/{siteId}/generate`, etc.)
  - Found major mismatch between API Gateway and Lambda expectations
- **Updated API Gateway Terraform** (`modules/api_gateway/main.tf`)
  - Changed from flat routes to RESTful resource-based routes
  - Added 25+ routes for generation, validation, logo, and theme services
  - Updated `outputs.tf` to reference new route resources
- **Deployed Route Changes**
  - 23 routes created
  - 5 routes destroyed (old flat routes)
  - Imported existing custom domain to Terraform state
- **Tested Endpoints**
  - Health check: ✅ Working
  - Generation POST: ✅ Working (returns generation_id, HATEOAS links)
  - Validation: ⚠️ Needs `validations` DynamoDB table + IAM permissions
- **Identified Next Task**: Create `validations` DynamoDB table in Terraform

---

## Document Control

| Version | Date | Author | Changes |
|---------|------|--------|---------|
| 1.0 | 2026-01-18 | Claude | Initial plan creation |
| 1.1 | 2026-01-18 | Claude | Phase 1 & 2 completed, route alignment & Cognito |

---

## Related Documents

| Document | Path |
|----------|------|
| BP-001 Tenant Provisioning | /business_process/BP-001_Tenant_Provisioning.md |
| BP-002 Site Generation | /business_process/BP-002_Site_Generation.md |
| BP-006 Payment Handoff | /business_process/BP-006_Payment_to_SiteBuilder_Handoff.md |
| RB-001 Tenant Provisioning | /runbooks/RB-001_Tenant_Provisioning.md |
| SOP-001 Onboarding | /SOPs/SOP-001_New_Tenant_Onboarding.md |
| BRS v1.2 | /BRS/BBWS_Site_Builder_BRS_v1.md |
