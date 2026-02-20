# Phase 0: Foundation Layer

**Status**: ✅ DEV DEPLOYED (100% Complete)
**Last Updated**: 2026-01-25

---

## Overview

Phase 0 establishes the foundational backend APIs that all other phases depend upon. This phase must be completed before any frontend development can begin.

---

## Releases in This Phase

| Release | Name | BRS | Status | Progress |
|---------|------|-----|--------|----------|
| R1.0 | Tenant Management API | 2.5 | ✅ DEV Deployed | 100% |
| R1.0.1 | Access Management | 2.8 | ✅ DEV Deployed | 100% |

---

## DEV Environment URLs

| Component | URL | Status |
|-----------|-----|--------|
| Access Management API | `https://rfls9533a1.execute-api.eu-west-1.amazonaws.com/dev` | ✅ Live |
| Health Check | `/v1/health` | ✅ Passing |

---

## Dependencies

```
Phase 0 (Foundation) ✅ COMPLETE
├── R1.0 Tenant Management API (BRS 2.5) ✅ DEV DEPLOYED
│   └── R1.0.1 Access Management (BRS 2.8) ✅ DEV DEPLOYED
└── Infrastructure Prerequisites
    ├── AWS Account Setup (DEV) ✅
    ├── Cognito User Pools ✅
    ├── DynamoDB Tables ✅
    ├── GitHub Repository ✅
    └── GitHub OIDC Role ✅
```

---

## Key Deliverables

### R1.0 - Tenant Management API
- Organisation and tenant hierarchy ✅
- User management within organisations ✅
- Role-based access control (RBAC) ✅
- Subscription data management ✅
- Support ticket management ✅

### R1.0.1 - Access Management (DEV Deployed 2026-01-25)
- Permission service ✅
- Role service ✅
- Team hierarchy service ✅
- Invitation service ✅
- Lambda authorizer ✅
- Audit service ✅

#### Access Management Resources Created
| Resource | Count |
|----------|-------|
| Lambda Functions | 13 |
| IAM Roles | 6 |
| DynamoDB Table | 1 (+ 5 GSIs) |
| S3 Bucket | 1 |
| API Gateway | 1 |
| SNS Topics | 4 |
| CloudWatch Alarms | 2 |
| CloudWatch Log Groups | 42 |
| **Total** | **119** |

---

## Downstream Impact

All subsequent phases depend on Phase 0:

| Phase | Releases Waiting | Dependency Type | Status |
|-------|------------------|-----------------|--------|
| Phase 1a | R1.1 Instance API | Tenant context | ✅ Unblocked |
| Phase 1b | R1.2 Site API | Tenant context | ✅ Unblocked |
| Phase 2 | R2.0 Customer Portal | All Tenant APIs | ✅ Unblocked |
| Phase 3a | R2.1 Admin App | Tenant management | ✅ Unblocked |
| Phase 3b | R2.2 Admin Portal | Tenant management | ✅ Unblocked |

---

## Next Steps

| # | Action | Target |
|---|--------|--------|
| 1 | Complete unit tests (>80% coverage) | ___ |
| 2 | Run integration tests | ___ |
| 3 | Promote to SIT environment | ___ |
| 4 | SIT testing and validation | ___ |
| 5 | Promote to PROD | ___ |

---

## Release Plans

- [R1.0_Tenant_Management_API.md](./R1.0_Tenant_Management_API.md)
- [R1.0.1_Access_Management.md](./R1.0.1_Access_Management.md)

---

*Phase 0 is CRITICAL PATH - ✅ DEV deployment complete, ready for SIT promotion.*
