# Phase 3: Admin Tools

**Status**: Not Started (Phase 3a blocked by Phase 1a, Phase 3b blocked by Phase 2)

---

## Overview

Phase 3 delivers the internal administrative tools for BBWS staff to manage the platform, including the Admin App for operations and the Admin Portal for support and campaigns.

---

## Releases in This Phase

| Release | Name | BRS | Status | Progress |
|---------|------|-----|--------|----------|
| R2.1 | Admin App | 2.3 | Not Started | 0% |
| R2.2 | Admin Portal | 2.4 | Not Started | 0% |

---

## Dependencies

```
Phase 3 (Admin Tools)
├── Phase 3a: Admin App
│   └── R2.1 Admin App (BRS 2.3)
│       ├── Depends on: R1.0 Tenant API ✅
│       ├── Depends on: R1.1 Instance API ✅
│       └── Internal tool - can start after Phase 1a
│
└── Phase 3b: Admin Portal
    └── R2.2 Admin Portal (BRS 2.4)
        ├── Depends on: R1.0 Tenant API ✅
        ├── Depends on: R2.0 Customer Portal ⏳
        └── Requires: Customer Portal patterns
```

---

## Key Deliverables

### R2.1 - Admin App (Phase 3a)
- Admin authentication with MFA
- Tenant provisioning wizard
- Instance management across environments
- Cross-account operations (DEV/SIT/PROD)
- Monitoring dashboards
- Environment promotion workflows

### R2.2 - Admin Portal (Phase 3b)
- Campaign management module
- Support ticket queue and assignment
- SLA monitoring dashboard
- Cross-tenant visibility
- Revenue analytics
- Audit logging and reporting

---

## Parallel Execution Strategy

```
Phase 3a (Admin App)     ├── Can start after Phase 1a ──────►
Phase 3b (Admin Portal)  └── Must wait for Phase 2 ─────────►
```

Phase 3a can run in parallel with Phase 2 since it only depends on the Instance API, not the Customer Portal.

---

## Security Requirements

| Requirement | Phase 3a | Phase 3b |
|-------------|----------|----------|
| MFA Enforcement | Required | Required |
| Role-Based Access | Required | Required |
| Audit Logging | Required | Required |
| Cross-Account IAM | Required | Not Required |
| Staff Permissions | Required | Required |

---

## Downstream Impact

No releases depend on Phase 3. These are the final deliverables in the BBWS Platform release plan.

---

## Release Plans

- [R2.1_Admin_App.md](./R2.1_Admin_App.md)
- [R2.2_Admin_Portal.md](./R2.2_Admin_Portal.md)

---

*Phase 3a can start once Phase 1a is complete. Phase 3b must wait for Phase 2.*
