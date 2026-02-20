# Stage 1: Analysis & API Mapping - Summary

**Stage ID**: stage-1-analysis
**Project**: project-plan-5-lld-implementation
**Status**: COMPLETE
**Completed**: 2026-01-24

---

## Executive Summary

Stage 1 analysis completed successfully. All three LLDs (2.5, 2.6, 2.7) have been analyzed, APIs extracted and mapped to portals, integration points identified, and repository structures designed.

---

## Worker Completion Status

| Worker | Task | Status | Key Outputs |
|--------|------|--------|-------------|
| worker-1 | LLD 2.5 API Analysis | COMPLETE | 28 endpoints, 8 Lambdas, 4 GSIs |
| worker-2 | LLD 2.6 API Analysis | COMPLETE | 35 endpoints, 31 Lambdas, 4 SQS queues |
| worker-3 | LLD 2.7 API Analysis | COMPLETE | 8 endpoints, 9 Lambdas, GitOps workflow |
| worker-4 | Cross-LLD Integration | COMPLETE | 10 events, 8 API calls, dependency matrix |
| worker-5 | Repository Structure | COMPLETE | 5 repo designs with full folder trees |

---

## API Count Summary

| LLD | Total Endpoints | Customer Portal | Admin Portal | Lambdas |
|-----|-----------------|-----------------|--------------|---------|
| **2.5 Tenant Management** | 28 | 12 (partial) | 28 (full) | 8 |
| **2.6 WordPress Site Management** | 35 | 27 (primary) | 35 (full) | 31 |
| **2.7 WordPress Instance Management** | 8 | 0 | 8 (full) | 9 |
| **Total** | **71** | **39** | **71** | **48** |

---

## Portal Mapping Summary

### Customer Portal APIs (39 endpoints)

**LLD 2.5 - Tenant Management (12 endpoints)**
- GET /tenants (own assigned only)
- GET /tenants/{id} (own tenant only)
- GET /tenants/{id}/divisions, groups, teams (own tenant)
- GET/POST /tenants/{id}/users (own tenant)
- GET/POST /tenants/{id}/invitations (own tenant)
- GET /users/{id}/tenants (self only)

**LLD 2.6 - Site Management (27 endpoints)**
- All Sites CRUD (except backup/restore)
- All Templates read/apply
- All Plugins install/manage
- All Operations tracking

### Admin Portal APIs (71 endpoints - Full Access)
All APIs from all three LLDs, including:
- Tenant lifecycle (park/unpark/suspend/resume/deprovision)
- Template CRUD (/admin/templates/*)
- Instance infrastructure (provision/deprovision/scale)

---

## Integration Points Identified

### EventBridge Events (10 events)

| Event | Publisher | Consumer | Purpose |
|-------|-----------|----------|---------|
| TENANT_CREATED | LLD 2.5 | LLD 2.7 | Trigger instance provisioning |
| TENANT_PARKED | LLD 2.5 | LLD 2.7 | Scale ECS to 0 |
| TENANT_UNPARKED | LLD 2.5 | LLD 2.7 | Scale ECS back up |
| TENANT_DEPROVISIONED | LLD 2.5 | LLD 2.7 | Trigger Terraform destroy |
| SERVICE_STEADY_STATE | ECS | LLD 2.7 | Update status to ACTIVE |
| DEPLOYMENT_FAILED | ECS | LLD 2.7 | Update status to FAILED |
| SITE_CREATION_REQUEST | LLD 2.6 | SQS | Queue async creation |
| SITE_CREATION_COMPLETE | LLD 2.6 | SNS | Notify completion |

### Cross-Service Dependencies

| Service | Depends On | Dependency Type |
|---------|-----------|-----------------|
| LLD 2.6 (Sites) | LLD 2.5 (Tenants) | tenantId validation |
| LLD 2.6 (Sites) | LLD 2.7 (Instance) | Instance status check |
| LLD 2.6 (SQS Consumer) | LLD 2.7 (Instance) | WordPress credentials |
| LLD 2.7 (Instance) | LLD 2.5 (Tenants) | TENANT_* events |

---

## Repository Structures Designed

### 1. `2_bbws_tenant_lambda` (LLD 2.5)
- **Handlers**: 8 Lambda functions
- **Services**: TenantService, UserAssignmentService, HierarchyService, CognitoService, EventPublisher
- **DAO**: TenantDao (7 methods)
- **Key Pattern**: `src/handlers/`, `src/services/`, `src/dao/`, `src/models/`

### 2. `2_bbws_wordpress_site_management_lambda` (LLD 2.6)
- **Handlers**: 25 API handlers + 3 SQS consumers = 28 Lambdas
- **Services**: SiteService, TemplateService, PluginService, WordPressClient, NotificationService, SecurityScanner
- **DAOs**: SiteDAO, TemplateDAO, PluginDAO
- **Key Pattern**: `src/handlers/sites/`, `src/handlers/templates/`, `src/handlers/plugins/`, `src/handlers/sqs/`

### 3. `2_bbws_tenants_instances_lambda` (LLD 2.7)
- **Handlers**: 8 API Lambda functions
- **Services**: InstanceService, ProvisioningService, DeprovisioningService, LifecycleService
- **Helpers**: ECS_Helper, TF_Helper, Git_Helper, GH_Actions_Author_Helper, GH_Actions_API_Helper
- **Key Pattern**: `src/helpers/` for GitOps separation of concerns

### 4. `2_bbws_tenants_instances_dev` (GitOps Terraform)
- **Structure**: `tenants/{tenant-id}/` per tenant
- **Modules**: `modules/wordpress-instance/`
- **Templates**: Jinja2 templates for code generation
- **Workflows**: GitHub Actions per tenant

### 5. `2_bbws_tenants_event_handler` (EventBridge Handler)
- **Single Lambda**: tenant-event-handler-lambda
- **Services**: EventProcessor, TagExtractor, StateMapper, DynamoDBUpdater
- **Key Pattern**: Tag-based tenant identification from ECS events

---

## DynamoDB Tables

| Table | LLD | Capacity | Key Pattern |
|-------|-----|----------|-------------|
| `bbws-tenants-{env}` | 2.5 | On-Demand | PK: TENANT#{id}, SK: METADATA/USER#/HIERARCHY#/EVENT# |
| `sites` | 2.6 | On-Demand | PK: TENANT#{id}, SK: SITE#{id}/TEMPLATE#/PLUGIN# |
| `{env}-tenant-resources` | 2.7 | On-Demand | PK: TENANT#{id}, SK: INSTANCE |

---

## SQS Queues (LLD 2.6)

| Queue | Visibility Timeout | Max Receives | Consumer |
|-------|-------------------|--------------|----------|
| bbws-wp-site-creation-{env} | 900s | 3 | site-creator Lambda |
| bbws-wp-site-update-{env} | 600s | 3 | site-updater Lambda |
| bbws-wp-site-deletion-{env} | 600s | 3 | site-deleter Lambda |
| bbws-wp-site-operations-dlq-{env} | N/A | N/A | Manual review |

---

## Key Technical Findings

### 1. ID Flow Pattern
```
tenantId (LLD 2.5) → instanceId (LLD 2.7, same as tenantId) → siteId (LLD 2.6)
```

### 2. Authentication Patterns
- **Customer/Admin APIs**: Cognito JWT tokens
- **WordPress REST API**: HTTP Basic Auth (Application Passwords in Secrets Manager)

### 3. GitOps Workflow (LLD 2.7)
1. Lambda generates Terraform files from Jinja2 templates
2. Lambda commits to environment-specific GitHub repo
3. Lambda triggers GitHub Actions workflow
4. GitHub Actions runs Terraform apply
5. ECS emits state change events to EventBridge
6. EventBridge handler updates DynamoDB status

### 4. WordPress Integration (LLD 2.6)
- All WordPress REST API calls go through Internal ALB (VPC-only)
- Never publicly exposed
- Security via Basic Auth + ALB Security Groups

---

## Recommendations for Stage 2

1. **Start with LLD 2.5 Lambdas** - Foundation for tenant operations
2. **Implement shared utilities first** - ResponseBuilder, decorators, exceptions
3. **TDD approach** - Write tests before handlers
4. **Create conftest.py early** - Shared fixtures for moto mocks

---

## Gate 1 Approval Checklist

- [x] All 3 LLDs analyzed completely
- [x] All API endpoints extracted (71 total)
- [x] Portal mapping completed (Customer vs Admin)
- [x] All EventBridge events identified (10)
- [x] Cross-service dependencies documented
- [x] Repository structures designed (5 repos)
- [x] DynamoDB schemas understood
- [x] SQS queue specifications documented
- [x] No blocking questions remain

---

## Approvers

| Role | Name | Status | Date |
|------|------|--------|------|
| Tech Lead | | PENDING | |
| Solutions Architect | | PENDING | |

---

**Stage 1 Completed**: 2026-01-24
**Next Stage**: Stage 2 - Lambda Implementation (Customer Portal)
